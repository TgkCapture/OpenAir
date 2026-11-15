import 'dart:async';

import 'package:flutter/material.dart';
import 'package:openair/app/theme.dart';
import 'package:openair/core/di/injection.dart';
import 'package:openair/core/playback/playback_actions.dart';
import 'package:openair/core/ui/artwork.dart';
import 'package:openair/core/ui/badges.dart';
import 'package:openair/core/ui/state_views.dart';
import 'package:openair/features/tv/models/channel_model.dart';
import 'package:openair/features/tv/repository/channel_repository.dart';
import 'package:openair/features/vod/models/vod_model.dart';
import 'package:openair/features/vod/repository/vod_repository.dart';

/// Search across channels and videos.
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _controller = TextEditingController();
  Timer? _debounce;

  /// Channels are few, so they are loaded once and filtered on the device.
  List<Channel> _allChannels = const [];

  String _query = '';
  List<Channel> _channels = const [];
  List<VodItem> _videos = const [];
  bool _searching = false;
  bool _failed = false;

  /// Guards against a slow search overwriting the results of a newer one.
  int _request = 0;

  @override
  void initState() {
    super.initState();
    _loadChannels();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadChannels() async {
    try {
      final repo = getIt<ChannelRepository>();
      final results = await Future.wait([repo.getTvChannels(), repo.getRadioChannels()]);
      if (!mounted) return;
      _allChannels = [...results[0], ...results[1]];
      if (_query.isNotEmpty) _search(_query);
    } catch (_) {
      // Videos can still be searched without the channel list.
    }
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () => _search(value.trim()));
  }

  Future<void> _search(String query) async {
    final request = ++_request;
    if (query.isEmpty) {
      setState(() {
        _query = '';
        _channels = const [];
        _videos = const [];
        _searching = false;
        _failed = false;
      });
      return;
    }

    final needle = query.toLowerCase();
    setState(() {
      _query = query;
      _searching = true;
      _failed = false;
      _channels = _allChannels
          .where((c) => c.name.toLowerCase().contains(needle))
          .toList();
    });

    try {
      final videos = await getIt<VodRepository>().getVod(search: query);
      if (!mounted || request != _request) return;
      setState(() {
        _videos = videos;
        _searching = false;
      });
    } catch (_) {
      if (!mounted || request != _request) return;
      setState(() {
        _videos = const [];
        _searching = false;
        _failed = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Padding(
          padding: const EdgeInsets.only(right: AppSpacing.screen),
          child: TextField(
            controller: _controller,
            autofocus: true,
            textInputAction: TextInputAction.search,
            onChanged: _onChanged,
            onSubmitted: (value) => _search(value.trim()),
            decoration: const InputDecoration(
              hintText: 'Search channels and videos',
              prefixIcon: Icon(Icons.search_rounded),
              isDense: true,
            ),
          ),
        ),
      ),
      body: _body(context),
    );
  }

  Widget _body(BuildContext context) {
    if (_query.isEmpty) {
      return const EmptyState(
        icon: Icons.search_rounded,
        title: 'Find something to watch or listen to',
        message: 'Search by channel name or video title.',
      );
    }
    if (_failed && _channels.isEmpty) {
      return ErrorState(onRetry: () => _search(_query));
    }
    if (!_searching && _channels.isEmpty && _videos.isEmpty) {
      return EmptyState(
        icon: Icons.search_off_rounded,
        title: 'No results for "$_query"',
        message: 'Check the spelling or try a different word.',
      );
    }

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      children: [
        if (_searching) const LinearProgressIndicator(minHeight: 2),
        for (final channel in _channels)
          _ResultRow(
            title: channel.name,
            subtitle: channel.type == 'radio' ? 'Radio channel' : 'TV channel',
            imageUrl: channel.logoUrl,
            icon: channel.type == 'radio' ? Icons.radio_rounded : Icons.live_tv_rounded,
            isPremium: channel.isPremium,
            onTap: () => channel.type == 'radio'
                ? PlaybackActions.toggleRadio(context, channel)
                : PlaybackActions.watchChannel(context, channel),
          ),
        for (final video in _videos)
          _ResultRow(
            title: video.title,
            subtitle: [
              'Video',
              if (video.category != null) video.category!,
              if (video.formattedDuration.isNotEmpty) video.formattedDuration,
            ].join(' · '),
            imageUrl: video.thumbnailUrl,
            icon: Icons.play_circle_outline_rounded,
            isPremium: video.isPremium,
            wide: true,
            onTap: () => PlaybackActions.watchVideo(context, video),
          ),
      ],
    );
  }
}

class _ResultRow extends StatelessWidget {
  final String title;
  final String subtitle;
  final String? imageUrl;
  final IconData icon;
  final bool isPremium;

  /// Video thumbnails are 16:9; channel logos are square.
  final bool wide;
  final VoidCallback onTap;

  const _ResultRow({
    required this.title,
    required this.subtitle,
    required this.imageUrl,
    required this.icon,
    required this.isPremium,
    this.wide = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.screen,
          vertical: AppSpacing.sm,
        ),
        child: Row(
          children: [
            Artwork(
              url: imageUrl,
              width: wide ? 92 : 52,
              height: 52,
              radius: AppRadius.md,
              icon: icon,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall,
                  ),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            if (isPremium) ...[
              const SizedBox(width: AppSpacing.sm),
              const PremiumBadge(),
            ],
          ],
        ),
      ),
    );
  }
}
