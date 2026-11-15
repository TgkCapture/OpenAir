import 'package:flutter/material.dart';
import 'package:openair/app/theme.dart';

/// Marks something that is on air right now.
class LiveBadge extends StatelessWidget {
  const LiveBadge({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: colors.brand,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        'LIVE',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(color: colors.onBrand),
      ),
    );
  }
}

/// Marks content that needs a subscription.
class PremiumBadge extends StatelessWidget {
  const PremiumBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        // White on every theme: it sits on top of artwork.
        color: Colors.white,
        borderRadius: BorderRadius.circular(5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.lock_rounded, size: 11, color: Color(0xFF111318)),
          const SizedBox(width: 3),
          Text(
            'Premium',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: const Color(0xFF111318),
                  letterSpacing: 0,
                ),
          ),
        ],
      ),
    );
  }
}

/// A small dark label on top of artwork, for example a video's length.
class OverlayLabel extends StatelessWidget {
  final String text;
  const OverlayLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFF0B0B0D),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(
        text,
        style: Theme.of(context)
            .textTheme
            .labelSmall
            ?.copyWith(color: Colors.white, letterSpacing: 0),
      ),
    );
  }
}
