import 'package:flutter/material.dart';
import 'package:openair/app/theme.dart';

/// The title above a row or list of content, with an optional "See all".
class SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onSeeAll;

  const SectionHeader({super.key, required this.title, this.onSeeAll});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(left: AppSpacing.screen, right: AppSpacing.xs),
      child: SizedBox(
        height: 44,
        child: Row(
          children: [
            Expanded(
              child: Text(title, style: theme.textTheme.titleLarge),
            ),
            if (onSeeAll != null)
              TextButton(
                onPressed: onSeeAll,
                style: TextButton.styleFrom(
                  foregroundColor: context.colors.textMuted,
                ),
                child: const Text('See all'),
              ),
          ],
        ),
      ),
    );
  }
}
