import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';

/// What the shared audio player is playing right now.
class NowPlaying extends Equatable {
  /// Identifies the item, for example `radio:<channel id>` or
  /// `episode:<episode id>`, so screens can tell whether it is theirs.
  final String id;
  final String title;
  final String? subtitle;
  final String? artUrl;

  /// Live streams (radio) cannot be paused and resumed where they left off.
  final bool isLive;
  final bool isPlaying;
  final bool isLoading;

  const NowPlaying({
    required this.id,
    required this.title,
    this.subtitle,
    this.artUrl,
    required this.isLive,
    this.isPlaying = false,
    this.isLoading = false,
  });

  NowPlaying copyWith({bool? isPlaying, bool? isLoading}) => NowPlaying(
        id: id,
        title: title,
        subtitle: subtitle,
        artUrl: artUrl,
        isLive: isLive,
        isPlaying: isPlaying ?? this.isPlaying,
        isLoading: isLoading ?? this.isLoading,
      );

  @override
  List<Object?> get props =>
      [id, title, subtitle, artUrl, isLive, isPlaying, isLoading];
}

/// The app's single audio player. Radio and podcasts both play through it, so
/// only one thing is ever audible, playback continues when the user changes
/// tab or leaves the app, and the mini player can show it everywhere.
///
/// The state is null when nothing is loaded.
class AudioController extends Cubit<NowPlaying?> {
  final AudioPlayer _player;
  late final StreamSubscription<PlayerState> _stateSub;
  final _errors = StreamController<String>.broadcast();

  /// Counts play requests, so a slow request that is overtaken by a newer one
  /// can tell it is stale and leave the state alone.
  int _request = 0;

  /// [player] can be supplied in tests; the app uses its own.
  AudioController({AudioPlayer? player})
      : _player = player ?? AudioPlayer(),
        super(null) {
    _stateSub = _player.playerStateStream.listen(_onPlayerState);
  }

  /// Messages to show the user when a stream cannot be played.
  Stream<String> get errors => _errors.stream;

  static String radioId(String channelId) => 'radio:$channelId';
  static String episodeId(String episodeId) => 'episode:$episodeId';

  /// Stops whatever is playing and starts [url].
  Future<void> play({
    required String id,
    required String url,
    required String title,
    String? subtitle,
    String? artUrl,
    required bool isLive,
  }) async {
    final request = ++_request;
    emit(NowPlaying(
      id: id,
      title: title,
      subtitle: subtitle,
      artUrl: artUrl,
      isLive: isLive,
      isLoading: true,
    ));

    try {
      await _player.stop();
      await _player.setAudioSource(AudioSource.uri(
        Uri.parse(url),
        // Shown on the lock screen and in the notification.
        tag: MediaItem(
          id: id,
          title: title,
          album: subtitle,
          artUri: artUrl != null ? Uri.tryParse(artUrl) : null,
        ),
      ));
      if (request != _request) return;
      // play() only completes when playback ends, so it is not awaited.
      unawaited(_player.play().catchError((_) {}));
    } catch (_) {
      if (request != _request) return;
      emit(null);
      _errors.add('Could not play $title');
    }
  }

  /// Pauses or resumes. A paused live stream restarts from the live point.
  Future<void> toggle() async {
    final current = state;
    if (current == null) return;
    if (_player.playing) {
      await _player.pause();
    } else {
      if (current.isLive) await _player.seek(null);
      unawaited(_player.play().catchError((_) {}));
    }
  }

  Future<void> stop() async {
    _request++;
    emit(null);
    await _player.stop();
  }

  void _onPlayerState(PlayerState playerState) {
    final current = state;
    if (current == null) return;

    final processing = playerState.processingState;
    if (processing == ProcessingState.completed) {
      // An episode finished.
      emit(current.copyWith(isPlaying: false, isLoading: false));
      return;
    }
    emit(current.copyWith(
      isPlaying: playerState.playing && processing == ProcessingState.ready,
      isLoading: processing == ProcessingState.loading ||
          processing == ProcessingState.buffering,
    ));
  }

  @override
  Future<void> close() async {
    await _stateSub.cancel();
    await _errors.close();
    await _player.dispose();
    return super.close();
  }
}
