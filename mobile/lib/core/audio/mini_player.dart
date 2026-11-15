import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:openair/core/audio/audio_controller.dart';

/// A bar showing what the shared audio player is playing, with pause and stop.
/// It takes no space when nothing is loaded.
class MiniPlayer extends StatelessWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AudioController, NowPlaying?>(
      builder: (context, nowPlaying) {
        if (nowPlaying == null) return const SizedBox.shrink();

        final theme = Theme.of(context);
        final audio = context.read<AudioController>();

        return Material(
          color: theme.colorScheme.surface,
          child: Container(
            height: 60,
            padding: const EdgeInsets.only(left: 16, right: 4),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: theme.dividerColor)),
            ),
            child: Row(
              children: [
                Icon(
                  nowPlaying.isLive ? Icons.radio_rounded : Icons.podcasts_rounded,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        nowPlaying.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                      ),
                      if (nowPlaying.subtitle != null)
                        Text(
                          nowPlaying.subtitle!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall,
                        ),
                    ],
                  ),
                ),
                if (nowPlaying.isLoading)
                  const SizedBox(
                    width: 48,
                    height: 48,
                    child: Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  )
                else
                  IconButton(
                    tooltip: nowPlaying.isPlaying ? 'Pause' : 'Play',
                    icon: Icon(nowPlaying.isPlaying
                        ? Icons.pause_rounded
                        : Icons.play_arrow_rounded),
                    iconSize: 28,
                    onPressed: audio.toggle,
                  ),
                IconButton(
                  tooltip: 'Stop',
                  icon: const Icon(Icons.close_rounded),
                  onPressed: audio.stop,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
