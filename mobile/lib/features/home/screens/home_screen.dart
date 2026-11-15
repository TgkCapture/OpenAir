import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
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
import 'package:openair/features/settings/bloc/settings_bloc.dart';
import 'package:openair/features/tv/models/channel_model.dart';
import 'package:openair/features/tv/repository/channel_repository.dart';
import 'package:openair/features/vod/models/vod_model.dart';
import 'package:openair/features/vod/repository/vod_repository.dart';

/// The app's front page: what is on now, live radio and the newest videos.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Channel> _tv = const [];
  List<Channel> _radio = const [];
  List<VodItem> _videos = const [];

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
        getIt<VodRepository>().getVod(),
        // The guide is a nice-to-have here: Home still works without it.
        getIt<ScheduleRepository>()
            .getAllNowAndNext()
            .catchError((_) => <NowAndNext>[]),
      ]);
      if (!mounted) return;
      setState(() {
        _tv = results[0] as List<Channel>;
        _radio = results[1] as List<Channel>;
        _videos = results[2] as List<VodItem>;
        _onNow = {
          for (final entry in results[3] as List<NowAndNext>)
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
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const _Header(),
            Expanded(child: _body(context)),
          ],
        ),
      ),
    );
  }

  Widget _body(BuildContext context) {
    if (_loading) return const _HomeSkeleton();
    if (_failed) return ErrorState(onRetry: _load);
    if (_tv.isEmpty && _radio.isEmpty && _videos.isEmpty) {
      return const EmptyState(
        icon: Icons.live_tv_rounded,
        title: 'Nothing here yet',
        message: 'Channels and videos will show up here once they are added.',
      );
    }

    // Marks the radio channel that is playing in the shared player.
    final playingId = context.watch<AudioController>().state?.id;

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.only(top: AppSpacing.xs, bottom: AppSpacing.xl),
        children: [
          if (_tv.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screen),
              child: _OnNowHero(
                channel: _tv.first,
                programme: _onNow[_tv.first.id],
                onWatch: () => PlaybackActions.watchChannel(context, _tv.first),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
          if (_radio.isNotEmpty) ...[
            SectionHeader(
              title: 'Live radio',
              onSeeAll: () => context.go('/live'),
            ),
            SizedBox(
              height: 172,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screen),
                separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.md),
                itemCount: _radio.length,
                itemBuilder: (context, i) {
                  final channel = _radio[i];
                  final playing = playingId == AudioController.radioId(channel.id);
                  return MediaCard(
                    width: 116,
                    aspectRatio: 1,
                    icon: Icons.radio_rounded,
                    title: channel.name,
                    subtitle: _onNow[channel.id]?.title ?? 'Live radio',
                    imageUrl: channel.logoUrl,
                    isPremium: channel.isPremium,
                    overlayLabel: playing ? 'Playing' : null,
                    onTap: () => PlaybackActions.toggleRadio(context, channel),
                  );
                },
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
          if (_videos.isNotEmpty) ...[
            SectionHeader(
              title: 'New videos',
              onSeeAll: () => context.go('/library'),
            ),
            SizedBox(
              height: 152,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screen),
                separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.md),
                itemCount: _videos.length,
                itemBuilder: (context, i) {
                  final video = _videos[i];
                  return MediaCard(
                    width: 168,
                    title: video.title,
                    subtitle: video.category,
                    imageUrl: video.thumbnailUrl,
                    isPremium: video.isPremium,
                    overlayLabel: video.formattedDuration.isEmpty
                        ? null
                        : video.formattedDuration,
                    onTap: () => PlaybackActions.watchVideo(context, video),
                  );
                },
              ),
            ),
          ],
          if (_tv.length > 1) ...[
            const SizedBox(height: AppSpacing.sm),
            SectionHeader(
              title: 'More channels',
              onSeeAll: () => context.go('/live'),
            ),
            SizedBox(
              height: 152,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screen),
                separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.md),
                itemCount: _tv.length - 1,
                itemBuilder: (context, i) {
                  final channel = _tv[i + 1];
                  return MediaCard(
                    width: 168,
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
            ),
          ],
        ],
      ),
    );
  }
}

/// The station name with search and profile buttons.
class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    final brandName =
        context.select<SettingsBloc, String>((bloc) => bloc.state.brandName);
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.screen, AppSpacing.sm, AppSpacing.xs, AppSpacing.xs),
      child: Row(
        children: [
          Expanded(
            child: Text(
              brandName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ),
          IconButton(
            tooltip: 'Search',
            icon: const Icon(Icons.search_rounded),
            onPressed: () => context.push('/search'),
          ),
          IconButton(
            tooltip: 'Profile',
            icon: const Icon(Icons.person_outline_rounded),
            onPressed: () => context.push('/profile'),
          ),
        ],
      ),
    );
  }
}

/// The large card at the top of Home for the main TV channel.
class _OnNowHero extends StatelessWidget {
  final Channel channel;
  final Programme? programme;
  final VoidCallback onWatch;

  const _OnNowHero({
    required this.channel,
    required this.programme,
    required this.onWatch,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.colors;
    final programme = this.programme;

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.xl),
      child: ColoredBox(
        color: colors.artwork,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const LiveBadge(),
                  const Spacer(),
                  if (channel.isPremium) const PremiumBadge(),
                  if (channel.logoUrl != null) ...[
                    const SizedBox(width: AppSpacing.sm),
                    Artwork(
                      url: channel.logoUrl,
                      width: 40,
                      height: 40,
                      radius: AppRadius.sm,
                      icon: Icons.live_tv_rounded,
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 72),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          programme?.title ?? channel.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.headlineMedium,
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          programme == null
                              ? 'Live now'
                              : '${channel.name} · ${programme.timeRange}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  FilledButton.icon(
                    onPressed: onWatch,
                    style: FilledButton.styleFrom(
                      backgroundColor: colors.emphasis,
                      foregroundColor: colors.onEmphasis,
                      shape: const StadiumBorder(),
                      minimumSize: const Size(0, 44),
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                    ),
                    icon: const Icon(Icons.play_arrow_rounded, size: 20),
                    label: const Text('Watch'),
                  ),
                ],
              ),
              if (programme != null) ...[
                const SizedBox(height: AppSpacing.md),
                ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: programme.progress,
                    minHeight: 4,
                    color: colors.text,
                    backgroundColor: colors.text.withValues(alpha: 0.25),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// The shape of Home while it loads.
class _HomeSkeleton extends StatelessWidget {
  const _HomeSkeleton();

  @override
  Widget build(BuildContext context) {
    Widget rail(double width, double height) => SizedBox(
          height: height,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screen),
            separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.md),
            itemCount: 4,
            itemBuilder: (_, __) =>
                Skeleton(width: width, height: height, radius: AppRadius.lg),
          ),
        );

    return ListView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.only(top: AppSpacing.xs),
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.screen),
          child: Skeleton(height: 232, radius: AppRadius.xl),
        ),
        const SizedBox(height: AppSpacing.xl),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.screen),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Skeleton(width: 120, height: 20, radius: AppRadius.sm),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        rail(116, 116),
        const SizedBox(height: AppSpacing.xl),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.screen),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Skeleton(width: 120, height: 20, radius: AppRadius.sm),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        rail(168, 94),
      ],
    );
  }
}
