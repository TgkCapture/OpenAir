import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiService {
  static const _storage = FlutterSecureStorage();
  static const int _port = 8000;

  late final Dio _dio;
  late final String baseUrl;

  ApiService._internal(this.baseUrl) {
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {'Content-Type': 'application/json'},
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _storage.read(key: 'access_token');
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onError: (error, handler) async {
        if (error.response?.statusCode == 401) {
          await _storage.deleteAll();
        }
        return handler.next(error);
      },
    ));
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

  static Future<List<String>> _gatewayCandidates() async {
    final candidates = <String>[];
    try {
      final interfaces = await NetworkInterface.list(
        type: InternetAddressType.IPv4,
        includeLinkLocal: false,
      );
      for (final iface in interfaces) {
        for (final addr in iface.addresses) {
          final parts = addr.address.split('.');
          if (parts.length == 4) {
            // Try .1 and .2 of the same subnet (typical gateway/host IPs)
            candidates.add('${parts[0]}.${parts[1]}.${parts[2]}.1');
            candidates.add('${parts[0]}.${parts[1]}.${parts[2]}.2');
          }
        }
      }
    } catch (_) {}
    return candidates;
  }

  Dio get dio => _dio;

  Future<void> saveTokens(String accessToken, String refreshToken) async {
    await _storage.write(key: 'access_token', value: accessToken);
    await _storage.write(key: 'refresh_token', value: refreshToken);
  }

  Future<void> clearTokens() async {
    await _storage.deleteAll();
  }

  Future<bool> hasToken() async {
    final token = await _storage.read(key: 'access_token');
    return token != null;
  }
}