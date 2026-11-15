import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:openair/app/theme.dart';
import 'package:openair/core/audio/audio_controller.dart';
import 'package:openair/core/ui/artwork.dart';

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
        final colors = context.colors;
        final audio = context.read<AudioController>();

        return Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.sm, 0, AppSpacing.sm, AppSpacing.sm),
          child: Material(
            color: colors.surfaceHigh,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            child: SizedBox(
              height: 60,
              child: Row(
                children: [
                  const SizedBox(width: AppSpacing.sm),
                  Artwork(
                    url: nowPlaying.artUrl,
                    width: 44,
                    height: 44,
                    radius: AppRadius.sm,
                    icon: nowPlaying.isLive
                        ? Icons.radio_rounded
                        : Icons.podcasts_rounded,
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          nowPlaying.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleSmall,
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
                  IconButton(
                    tooltip: 'Stop',
                    icon: const Icon(Icons.close_rounded),
                    color: colors.textMuted,
                    onPressed: audio.stop,
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: AppSpacing.sm),
                    child: nowPlaying.isLoading
                        ? const SizedBox(
                            width: 44,
                            height: 44,
                            child: Padding(
                              padding: EdgeInsets.all(12),
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        : IconButton.filled(
                            tooltip: nowPlaying.isPlaying ? 'Pause' : 'Play',
                            style: IconButton.styleFrom(
                              backgroundColor: colors.brand,
                              foregroundColor: colors.onBrand,
                              minimumSize: const Size(44, 44),
                            ),
                            icon: Icon(nowPlaying.isPlaying
                                ? Icons.pause_rounded
                                : Icons.play_arrow_rounded),
                            onPressed: audio.toggle,
                          ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
