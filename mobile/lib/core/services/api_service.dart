import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiService {
  static const _storage = FlutterSecureStorage();
  static const int _port = 8000;

  static const _accessKey = 'access_token';
  static const _refreshKey = 'refresh_token';
  static const _userKey = 'user';
  static const _retriedFlag = 'retried_after_refresh';

  late final Dio _dio;

  /// Bare client used only to call `/auth/refresh`, so a failed refresh can
  /// never trigger another refresh.
  late final Dio _refreshDio;
  late final String baseUrl;

  final _sessionExpired = StreamController<void>.broadcast();
  Future<bool>? _refreshing;

  /// Fires when the server rejects the stored refresh token, meaning the user
  /// has to sign in again.
  Stream<void> get onSessionExpired => _sessionExpired.stream;

  ApiService._internal(this.baseUrl) {
    final options = BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {'Content-Type': 'application/json'},
    );
    _dio = Dio(options);
    _refreshDio = Dio(options);

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _storage.read(key: _accessKey);
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onError: (error, handler) async {
        final request = error.requestOptions;
        final canRetry = error.response?.statusCode == 401 &&
            !request.path.startsWith('/auth/') &&
            request.extra[_retriedFlag] != true;
        if (!canRetry || !await _refreshTokens()) {
          return handler.next(error);
        }

        // The access token was renewed: replay the request once.
        try {
          request.extra[_retriedFlag] = true;
          return handler.resolve(await _dio.fetch(request));
        } on DioException catch (retryError) {
          return handler.next(retryError);
        }
      },
    ));
  }

  /// Renews the access token. Requests that fail at the same moment share one
  /// refresh call, because a refresh token only works once.
  Future<bool> _refreshTokens() {
    return _refreshing ??= _doRefresh().whenComplete(() => _refreshing = null);
  }

  Future<bool> _doRefresh() async {
    final refreshToken = await _storage.read(key: _refreshKey);
    if (refreshToken == null) return false; // Guest: nothing to renew.

    try {
      final res = await _refreshDio.post(
        '/auth/refresh',
        data: {'refresh_token': refreshToken},
      );
      final data = res.data['data'];
      await saveTokens(data['access_token'], data['refresh_token']);
      return true;
    } on DioException catch (e) {
      // Only a rejected token ends the session. A network failure keeps the
      // tokens so the next request can try again.
      if (e.response?.statusCode == 401) {
        await clearTokens();
        _sessionExpired.add(null);
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  static Future<ApiService> create() async {
    final url = await _resolveBaseUrl();
    debugPrint('OpenAir API URL: $url');
    return ApiService._internal(url);
  }

  static Future<String> _resolveBaseUrl() async {
    if (kReleaseMode) {
      return 'https://api.openair.stream/api/v1';
    }

    if (defaultTargetPlatform == TargetPlatform.android) {
      try {
        final interfaces = await NetworkInterface.list(
          type: InternetAddressType.IPv4,
          includeLinkLocal: false,
        );

        final candidates = <String>[];

        for (final iface in interfaces) {
          for (final addr in iface.addresses) {
            final ip = addr.address;
            if (ip.startsWith('127.') || ip.startsWith('10.0.2.')) continue;

            final parts = ip.split('.');
            if (parts.length == 4) {
              // Try .1 through .20 and common dev machine endings on same subnet
              for (int i = 1; i <= 20; i++) {
                candidates.add('${parts[0]}.${parts[1]}.${parts[2]}.$i');
              }
              // Also try higher numbers common for PCs
              for (int i = 60; i <= 120; i++) {
                candidates.add('${parts[0]}.${parts[1]}.${parts[2]}.$i');
              }
            }
          }
        }

        // Try all candidates in parallel for speed
        final futures = candidates.map((ip) async {
          final reachable = await _isReachable(ip, _port);
          return reachable ? ip : null;
        });

        final results = await Future.wait(futures);
        final found = results.firstWhere((r) => r != null, orElse: () => null);

        if (found != null) {
          return 'http://$found:$_port/api/v1';
        }
      } catch (e) {
        debugPrint('IP detection error: $e');
      }

      return 'http://10.0.2.2:$_port/api/v1';
    }

    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return 'http://localhost:$_port/api/v1';
    }

    return 'http://localhost:$_port/api/v1';
  }

  static Future<bool> _isReachable(String host, int port) async {
    try {
      final socket = await Socket.connect(
        host,
        port,
        timeout: const Duration(seconds: 2),
      );
      socket.destroy();
      return true;
    } catch (_) {
      return false;
    }
  }

  // static Future<List<String>> _gatewayCandidates() async {
  //   final candidates = <String>[];
  //   try {
  //     final interfaces = await NetworkInterface.list(
  //       type: InternetAddressType.IPv4,
  //       includeLinkLocal: false,
  //     );
  //     for (final iface in interfaces) {
  //       for (final addr in iface.addresses) {
  //         final parts = addr.address.split('.');
  //         if (parts.length == 4) {
  //           // Try .1 and .2 of the same subnet (typical gateway/host IPs)
  //           candidates.add('${parts[0]}.${parts[1]}.${parts[2]}.1');
  //           candidates.add('${parts[0]}.${parts[1]}.${parts[2]}.2');
  //         }
  //       }
  //     }
  //   } catch (_) {}
  //   return candidates;
  // }

  Dio get dio => _dio;

  Future<void> saveTokens(String accessToken, String refreshToken) async {
    await _storage.write(key: _accessKey, value: accessToken);
    await _storage.write(key: _refreshKey, value: refreshToken);
  }

  /// Removes the tokens and the cached user.
  Future<void> clearTokens() async {
    await _storage.deleteAll();
  }

  Future<String?> readRefreshToken() => _storage.read(key: _refreshKey);

  /// The signed-in user is cached so the app can open signed in while offline.
  Future<void> saveUserJson(String json) =>
      _storage.write(key: _userKey, value: json);

  Future<String?> readUserJson() => _storage.read(key: _userKey);
}