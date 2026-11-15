import 'package:flutter/material.dart';
import 'package:openair/app/theme.dart';
import 'package:shimmer/shimmer.dart';

/// Shown when a screen or list has nothing in it.
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? message;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    return _CenteredMessage(icon: icon, title: title, message: message);
  }
}

/// Shown when content could not be loaded, with a way to try again.
class ErrorState extends StatelessWidget {
  final String title;
  final String? message;
  final VoidCallback onRetry;

  const ErrorState({
    super.key,
    this.title = 'Could not load this',
    this.message = 'Check your connection and try again.',
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return _CenteredMessage(
      icon: Icons.wifi_off_rounded,
      title: title,
      message: message,
      action: OutlinedButton(onPressed: onRetry, child: const Text('Try again')),
    );
  }
}

class _CenteredMessage extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? message;
  final Widget? action;

  const _CenteredMessage({
    required this.icon,
    required this.title,
    this.message,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.colors;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 44, color: colors.textMuted),
            const SizedBox(height: AppSpacing.lg),
            Text(title, style: theme.textTheme.titleMedium, textAlign: TextAlign.center),
            if (message != null) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                message!,
                style: theme.textTheme.bodyMedium?.copyWith(color: colors.textMuted),
                textAlign: TextAlign.center,
              ),
            ],
            if (action != null) ...[
              const SizedBox(height: AppSpacing.xl),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}

/// A grey block that shimmers while content loads. Compose several to sketch
/// the shape of the screen that is coming.
class Skeleton extends StatelessWidget {
  final double? width;
  final double? height;
  final double radius;

  const Skeleton({super.key, this.width, this.height, this.radius = AppRadius.md});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Shimmer.fromColors(
      baseColor: colors.surface,
      highlightColor: colors.surfaceHigh,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(radius),
        ),
      ),
    );
  }
}
