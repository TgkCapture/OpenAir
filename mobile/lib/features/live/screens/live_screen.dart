import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:openair/app/theme.dart';
import 'package:openair/core/audio/audio_controller.dart';
import 'package:openair/core/di/injection.dart';
import 'package:openair/core/playback/playback_actions.dart';
import 'package:openair/core/ui/artwork.dart';
import 'package:openair/core/ui/badges.dart';
import 'package:openair/core/ui/media_card.dart';
import 'package:openair/core/ui/section_header.dart';
import 'package:openair/core/ui/state_views.dart';
import 'package:openair/features/schedule/models/programme_model.dart';
import 'package:openair/features/schedule/repository/schedule_repository.dart';
import 'package:openair/features/tv/models/channel_model.dart';
import 'package:openair/features/tv/repository/channel_repository.dart';

/// Every live channel in one place: TV as a grid, radio as a list.
class LiveScreen extends StatefulWidget {
  const LiveScreen({super.key});

  @override
  State<LiveScreen> createState() => _LiveScreenState();
}

class _LiveScreenState extends State<LiveScreen> {
  List<Channel> _tv = const [];
  List<Channel> _radio = const [];

  /// What each channel is showing now, keyed by channel id.
  Map<String, Programme> _onNow = const {};
  bool _loading = true;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _failed = false;
    });
    try {
      final channels = getIt<ChannelRepository>();
      final results = await Future.wait([
        channels.getTvChannels(),
        channels.getRadioChannels(),
        getIt<ScheduleRepository>()
            .getAllNowAndNext()
            .catchError((_) => <NowAndNext>[]),
      ]);
      if (!mounted) return;
      setState(() {
        _tv = results[0] as List<Channel>;
        _radio = results[1] as List<Channel>;
        _onNow = {
          for (final entry in results[2] as List<NowAndNext>)
            if (entry.now != null) entry.channelId: entry.now!,
        };
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _failed = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Live')),
      body: _body(context),
    );
  }

  Widget _body(BuildContext context) {
    if (_loading) return const _LiveSkeleton();
    if (_failed) return ErrorState(onRetry: _load);
    if (_tv.isEmpty && _radio.isEmpty) {
      return const EmptyState(
        icon: Icons.live_tv_rounded,
        title: 'No live channels yet',
        message: 'TV and radio channels will show up here once they are added.',
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: CustomScrollView(
        slivers: [
          if (_tv.isNotEmpty) ...[
            const SliverToBoxAdapter(child: SectionHeader(title: 'TV')),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screen),
              sliver: SliverLayoutBuilder(
                builder: (context, constraints) {
                  const gap = AppSpacing.md;
                  final cardWidth = (constraints.crossAxisExtent - gap) / 2;
                  return SliverGrid(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: gap,
                      mainAxisSpacing: AppSpacing.lg,
                      // Artwork at 16:9 plus two lines of text.
                      mainAxisExtent: cardWidth * 9 / 16 + 52,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      childCount: _tv.length,
                      (context, i) {
                        final channel = _tv[i];
                        return MediaCard(
                          width: cardWidth,
                          icon: Icons.live_tv_rounded,
                          title: channel.name,
                          subtitle: _onNow[channel.id]?.title ?? 'Live TV',
                          imageUrl: channel.logoUrl,
                          isLive: true,
                          isPremium: channel.isPremium,
                          onTap: () => PlaybackActions.watchChannel(context, channel),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.lg)),
          ],
          if (_radio.isNotEmpty) ...[
            const SliverToBoxAdapter(child: SectionHeader(title: 'Radio')),
            SliverList.builder(
              itemCount: _radio.length,
              itemBuilder: (context, i) => _RadioRow(
                channel: _radio[i],
                programme: _onNow[_radio[i].id],
              ),
            ),
          ],
          const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xl)),
        ],
      ),
    );
  }
}

class _RadioRow extends StatelessWidget {
  final Channel channel;
  final Programme? programme;

  const _RadioRow({required this.channel, required this.programme});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.colors;
    final nowPlaying = context.watch<AudioController>().state;
    final isThis = nowPlaying?.id == AudioController.radioId(channel.id);
    final isLoading = isThis && nowPlaying!.isLoading;

    return InkWell(
      onTap: () => PlaybackActions.toggleRadio(context, channel),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.screen,
          vertical: AppSpacing.sm,
        ),
        child: Row(
          children: [
            Artwork(
              url: channel.logoUrl,
              width: 52,
              height: 52,
              radius: AppRadius.md,
              icon: Icons.radio_rounded,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          channel.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleSmall,
                        ),
                      ),
                      if (channel.isPremium) ...[
                        const SizedBox(width: AppSpacing.sm),
                        const PremiumBadge(),
                      ],
                    ],
                  ),
                  Text(
                    isThis ? 'Playing' : (programme?.title ?? 'Live radio'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            // Decorative: the whole row is the button.
            ExcludeSemantics(
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: isThis ? colors.brand : colors.surfaceHigh,
                  shape: BoxShape.circle,
                ),
                child: isLoading
                    ? Padding(
                        padding: const EdgeInsets.all(12),
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: colors.onBrand,
                        ),
                      )
                    : Icon(
                        isThis ? Icons.stop_rounded : Icons.play_arrow_rounded,
                        color: isThis ? colors.onBrand : colors.text,
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The shape of the Live screen while it loads.
class _LiveSkeleton extends StatelessWidget {
  const _LiveSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(AppSpacing.screen),
      children: [
        const Align(
          alignment: Alignment.centerLeft,
          child: Skeleton(width: 60, height: 20, radius: AppRadius.sm),
        ),
        const SizedBox(height: AppSpacing.md),
        const Row(
          children: [
            Expanded(child: Skeleton(height: 100, radius: AppRadius.lg)),
            SizedBox(width: AppSpacing.md),
            Expanded(child: Skeleton(height: 100, radius: AppRadius.lg)),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),
        const Align(
          alignment: Alignment.centerLeft,
          child: Skeleton(width: 80, height: 20, radius: AppRadius.sm),
        ),
        for (var i = 0; i < 4; i++) ...[
          const SizedBox(height: AppSpacing.md),
          const Skeleton(height: 52, radius: AppRadius.md),
        ],
      ],
    );
  }
}
