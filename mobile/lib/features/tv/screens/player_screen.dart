import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:openair/app/theme.dart';
import 'package:openair/core/audio/audio_controller.dart';
import 'package:openair/core/di/injection.dart';
import 'package:video_player/video_player.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

/// Full-screen video player for live TV and videos.
///
/// Uses the phone's own player (ExoPlayer on Android, AVPlayer on iOS), which
/// plays HLS streams and MP4 files without bundling a video engine.
class PlayerScreen extends StatefulWidget {
  final String streamUrl;
  final String title;

  const PlayerScreen({
    super.key,
    required this.streamUrl,
    required this.title,
  });

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  // The player is always dark, whatever the app theme.
  static const _background = Colors.black;
  static const _foreground = Colors.white;
  static const _muted = Color(0xFFB4B4BE);

  VideoPlayerController? _controller;
  bool _failed = false;
  bool _controlsVisible = true;
  bool _fullscreen = false;
  Timer? _hideTimer;

  @override
  void initState() {
    super.initState();
    // Video takes over from radio or a podcast.
    getIt<AudioController>().stop();
    WakelockPlus.enable();
    _open();
  }

  Future<void> _open() async {
    setState(() => _failed = false);
    final old = _controller;
    _controller = null;
    await old?.dispose();

    final controller = VideoPlayerController.networkUrl(Uri.parse(widget.streamUrl));
    _controller = controller;
    controller.addListener(_onPlayerChanged);
    try {
      await controller.initialize();
      if (!mounted || _controller != controller) return;
      await controller.play();
      _scheduleHide();
    } catch (_) {
      if (!mounted || _controller != controller) return;
      setState(() => _failed = true);
    }
  }

  void _onPlayerChanged() {
    if (!mounted) return;
    if (_controller?.value.hasError ?? false) {
      setState(() => _failed = true);
      return;
    }
    setState(() {});
  }

  /// Hides the controls a few seconds after the last interaction while playing.
  void _scheduleHide() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 4), () {
      if (mounted && (_controller?.value.isPlaying ?? false)) {
        setState(() => _controlsVisible = false);
      }
    });
  }

  void _toggleControls() {
    setState(() => _controlsVisible = !_controlsVisible);
    if (_controlsVisible) _scheduleHide();
  }

  void _togglePlay() {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;
    controller.value.isPlaying ? controller.pause() : controller.play();
    _scheduleHide();
  }

  void _seekBy(Duration offset) {
    final controller = _controller;
    if (controller == null) return;
    final target = controller.value.position + offset;
    final duration = controller.value.duration;
    controller.seekTo(target < Duration.zero
        ? Duration.zero
        : (target > duration ? duration : target));
    _scheduleHide();
  }

  Future<void> _setFullscreen(bool fullscreen) async {
    setState(() => _fullscreen = fullscreen);
    if (fullscreen) {
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    } else {
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    }
    _scheduleHide();
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _controller?.removeListener(_onPlayerChanged);
    _controller?.dispose();
    WakelockPlus.disable();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final value = _controller?.value;
    final ready = value != null && value.isInitialized;
    // A live stream has no fixed length, so it has no seek bar.
    final isLive = ready && value.duration <= Duration.zero;

    return PopScope(
      // Back leaves full screen first, then the player.
      canPop: !_fullscreen,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _setFullscreen(false);
      },
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: Scaffold(
          backgroundColor: _background,
          body: SafeArea(
            top: !_fullscreen,
            bottom: !_fullscreen,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _toggleControls,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (ready)
                    Center(
                      child: AspectRatio(
                        aspectRatio: value.aspectRatio == 0 ? 16 / 9 : value.aspectRatio,
                        child: VideoPlayer(_controller!),
                      ),
                    ),
                  if (_failed)
                    _PlayerError(onRetry: _open)
                  else if (!ready || value.isBuffering)
                    const Center(
                      child: CircularProgressIndicator(color: _foreground),
                    ),
                  // Controls stay up while loading or failed, so Back is
                  // always reachable.
                  AnimatedOpacity(
                    opacity: _controlsVisible || !ready || _failed ? 1 : 0,
                    duration: AppMotion.fast,
                    child: IgnorePointer(
                      ignoring: !(_controlsVisible || !ready || _failed),
                      child: _controls(context, ready: ready, isLive: isLive),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _controls(BuildContext context, {required bool ready, required bool isLive}) {
    final text = Theme.of(context).textTheme;
    final value = _controller?.value;

    return Column(
      children: [
        // Top bar
        ColoredBox(
          color: const Color(0x99000000),
          child: Row(
            children: [
              IconButton(
                tooltip: 'Back',
                color: _foreground,
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: () =>
                    _fullscreen ? _setFullscreen(false) : Navigator.of(context).maybePop(),
              ),
              Expanded(
                child: Text(
                  widget.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: text.titleMedium?.copyWith(color: _foreground),
                ),
              ),
              if (isLive)
                Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.sm),
                  child: Text('LIVE', style: text.labelSmall?.copyWith(color: _foreground)),
                ),
              IconButton(
                tooltip: _fullscreen ? 'Exit full screen' : 'Full screen',
                color: _foreground,
                icon: Icon(_fullscreen
                    ? Icons.fullscreen_exit_rounded
                    : Icons.fullscreen_rounded),
                onPressed: () => _setFullscreen(!_fullscreen),
              ),
            ],
          ),
        ),

        // Centre transport controls
        Expanded(
          child: ready && !_failed
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (!isLive)
                      IconButton(
                        tooltip: 'Back 10 seconds',
                        color: _foreground,
                        iconSize: 32,
                        icon: const Icon(Icons.replay_10_rounded),
                        onPressed: () => _seekBy(const Duration(seconds: -10)),
                      ),
                    const SizedBox(width: AppSpacing.xl),
                    IconButton.filled(
                      tooltip: value!.isPlaying ? 'Pause' : 'Play',
                      style: IconButton.styleFrom(
                        backgroundColor: _foreground,
                        foregroundColor: _background,
                        minimumSize: const Size(64, 64),
                      ),
                      iconSize: 36,
                      icon: Icon(value.isPlaying
                          ? Icons.pause_rounded
                          : Icons.play_arrow_rounded),
                      onPressed: _togglePlay,
                    ),
                    const SizedBox(width: AppSpacing.xl),
                    if (!isLive)
                      IconButton(
                        tooltip: 'Forward 10 seconds',
                        color: _foreground,
                        iconSize: 32,
                        icon: const Icon(Icons.forward_10_rounded),
                        onPressed: () => _seekBy(const Duration(seconds: 10)),
                      ),
                  ],
                )
              : const SizedBox.shrink(),
        ),

        // Seek bar for videos with a known length
        if (ready && !isLive && !_failed)
          ColoredBox(
            color: const Color(0x99000000),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.md),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  VideoProgressIndicator(
                    _controller!,
                    allowScrubbing: true,
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                    colors: VideoProgressColors(
                      playedColor: context.colors.brand,
                      bufferedColor: const Color(0x66FFFFFF),
                      backgroundColor: const Color(0x33FFFFFF),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(_format(value!.position), style: text.bodySmall?.copyWith(color: _muted)),
                      Text(_format(value.duration), style: text.bodySmall?.copyWith(color: _muted)),
                    ],
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  static String _format(Duration d) {
    final hours = d.inHours;
    final minutes = d.inMinutes.remainder(60);
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return hours > 0
        ? '$hours:${minutes.toString().padLeft(2, '0')}:$seconds'
        : '$minutes:$seconds';
  }
}

class _PlayerError extends StatelessWidget {
  final VoidCallback onRetry;
  const _PlayerError({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded, size: 44, color: Color(0xFFB4B4BE)),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'This video cannot be played',
              textAlign: TextAlign.center,
              style: text.titleMedium?.copyWith(color: Colors.white),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Check your connection and try again.',
              textAlign: TextAlign.center,
              style: text.bodyMedium?.copyWith(color: const Color(0xFFB4B4BE)),
            ),
            const SizedBox(height: AppSpacing.xl),
            OutlinedButton(
              onPressed: onRetry,
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: Color(0x66FFFFFF)),
              ),
              child: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }
}
