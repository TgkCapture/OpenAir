import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:openair/app/theme.dart';

/// A rounded image for a channel, programme, video or podcast. Shows a flat
/// placeholder with an icon while loading, when there is no image, and when
/// the image fails to load.
class Artwork extends StatelessWidget {
  final String? url;
  final double? width;
  final double? height;
  final double radius;
  final IconData icon;

  const Artwork({
    super.key,
    required this.url,
    this.width,
    this.height,
    this.radius = AppRadius.lg,
    this.icon = Icons.image_outlined,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    final placeholder = ColoredBox(
      color: colors.artwork,
      child: Center(
        child: Icon(icon, color: colors.text.withValues(alpha: 0.5), size: 28),
      ),
    );

    final url = this.url;
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: SizedBox(
        width: width,
        height: height,
        child: url == null || url.isEmpty
            ? placeholder
            : CachedNetworkImage(
                imageUrl: url,
                fit: BoxFit.cover,
                fadeInDuration: AppMotion.fast,
                placeholder: (_, __) => placeholder,
                errorWidget: (_, __, ___) => placeholder,
              ),
      ),
    );
  }
}
