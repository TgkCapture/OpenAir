import 'package:flutter/material.dart';
import 'package:openair/app/theme.dart';
import 'package:openair/core/ui/artwork.dart';
import 'package:openair/core/ui/badges.dart';

/// A tappable card for a video, channel or podcast: artwork with a title and
/// an optional subtitle underneath. Used in horizontal rails and grids.
class MediaCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? imageUrl;
  final double width;

  /// Width divided by height of the artwork: 16/9 for video, 1 for audio.
  final double aspectRatio;
  final IconData icon;
  final bool isPremium;
  final bool isLive;

  /// A short label on the artwork, for example the video length.
  final String? overlayLabel;
  final VoidCallback? onTap;

  const MediaCard({
    super.key,
    required this.title,
    this.subtitle,
    this.imageUrl,
    required this.width,
    this.aspectRatio = 16 / 9,
    this.icon = Icons.play_circle_outline_rounded,
    this.isPremium = false,
    this.isLive = false,
    this.overlayLabel,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Semantics(
      button: onTap != null,
      label: [
        title,
        if (subtitle != null) subtitle!,
        if (isLive) 'live',
        if (isPremium) 'premium',
      ].join(', '),
      excludeSemantics: true,
      child: SizedBox(
        width: width,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              AspectRatio(
                aspectRatio: aspectRatio,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Artwork(url: imageUrl, icon: icon),
                    if (isLive)
                      const Positioned(
                        top: AppSpacing.sm,
                        left: AppSpacing.sm,
                        child: LiveBadge(),
                      ),
                    if (isPremium)
                      const Positioned(
                        bottom: AppSpacing.sm,
                        left: AppSpacing.sm,
                        child: PremiumBadge(),
                      ),
                    if (overlayLabel != null)
                      Positioned(
                        bottom: AppSpacing.sm,
                        right: AppSpacing.sm,
                        child: OverlayLabel(overlayLabel!),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleSmall,
              ),
              if (subtitle != null)
                Text(
                  subtitle!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
