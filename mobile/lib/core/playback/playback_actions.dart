import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:openair/core/audio/audio_controller.dart';
import 'package:openair/core/di/injection.dart';
import 'package:openair/features/tv/models/channel_model.dart';
import 'package:openair/features/tv/repository/channel_repository.dart';
import 'package:openair/features/tv/screens/player_screen.dart';
import 'package:openair/features/vod/models/vod_model.dart';
import 'package:openair/features/vod/repository/vod_repository.dart';

/// Starting playback from any screen: fetch the stream, then open the video
/// player or hand audio to the shared player. Failures are shown as a snackbar.
abstract final class PlaybackActions {
  /// Opens a TV channel in the video player.
  static Future<void> watchChannel(BuildContext context, Channel channel) {
    return _run(context, () async {
      final stream = await getIt<ChannelRepository>().getStreamUrl(channel.id);
      if (!context.mounted) return;
      _openPlayer(context, stream.url, channel.name);
    });
  }

  /// Opens a video in the video player.
  static Future<void> watchVideo(BuildContext context, VodItem video) {
    return _run(context, () async {
      final url = await getIt<VodRepository>().getStreamUrl(video.id);
      if (!context.mounted) return;
      _openPlayer(context, url, video.title);
    });
  }

  /// Plays a radio channel in the shared audio player. Tapping the channel
  /// that is already playing stops it.
  static Future<void> toggleRadio(BuildContext context, Channel channel) {
    return _run(context, () async {
      final audio = getIt<AudioController>();
      final id = AudioController.radioId(channel.id);
      if (audio.state?.id == id) {
        await audio.stop();
        return;
      }
      final stream = await getIt<ChannelRepository>().getStreamUrl(channel.id);
      await audio.play(
        id: id,
        url: stream.url,
        title: channel.name,
        subtitle: 'Live radio',
        artUrl: channel.logoUrl,
        isLive: true,
      );
    });
  }

  static void _openPlayer(BuildContext context, String url, String title) {
    Navigator.of(context, rootNavigator: true).push(MaterialPageRoute(
      builder: (_) => PlayerScreen(streamUrl: url, title: title),
    ));
  }

  static Future<void> _run(BuildContext context, Future<void> Function() action) async {
    try {
      await action();
    } on DioException catch (e) {
      if (!context.mounted) return;
      _showError(context, _message(e));
    } catch (_) {
      if (!context.mounted) return;
      _showError(context, 'Could not start playback. Please try again.');
    }
  }

  static String _message(DioException e) {
    final data = e.response?.data;
    if (data is Map && data['error'] is Map) {
      if (data['error']['code'] == 'PREMIUM_REQUIRED') {
        return 'This needs a subscription.';
      }
    }
    if (e.response == null) {
      return 'Cannot reach the server. Check your connection and try again.';
    }
    return 'Could not start playback. Please try again.';
  }

  static void _showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}
