import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:openair/app/theme.dart';
import 'package:openair/core/audio/audio_controller.dart';
import 'package:openair/core/di/injection.dart';
import 'package:openair/core/ui/artwork.dart';
import 'package:openair/core/ui/badges.dart';
import 'package:openair/core/ui/media_card.dart';
import 'package:openair/core/ui/state_views.dart';
import 'package:openair/features/podcasts/bloc/podcast_bloc.dart';
import 'package:openair/features/podcasts/models/podcast_model.dart';
import 'package:openair/features/podcasts/repository/podcast_repository.dart';
import 'package:openair/features/tv/screens/player_screen.dart';
import 'package:openair/features/vod/bloc/vod_bloc.dart';
import 'package:openair/features/vod/models/vod_model.dart';
import 'package:openair/features/vod/repository/vod_repository.dart';

/// On-demand content: videos and podcasts.
class LibraryScreen extends StatelessWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = Theme.of(context).textTheme;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Library'),
          bottom: TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            labelColor: colors.text,
            unselectedLabelColor: colors.textMuted,
            labelStyle: text.labelLarge,
            unselectedLabelStyle: text.labelLarge?.copyWith(fontWeight: FontWeight.w500),
            indicatorColor: colors.text,
            indicatorSize: TabBarIndicatorSize.label,
            dividerColor: colors.border,
            tabs: const [Tab(text: 'Videos'), Tab(text: 'Podcasts')],
          ),
        ),
        body: TabBarView(
          children: [
            BlocProvider(
              create: (_) => VodBloc(getIt<VodRepository>())..add(VodLoaded()),
              child: const _VideosTab(),
            ),
            BlocProvider(
              create: (_) => PodcastBloc(getIt<PodcastRepository>(), getIt<AudioController>())
                ..add(PodcastsLoaded()),
              child: const _PodcastsTab(),
            ),
          ],
        ),
      ),
    );
  }
}

/// Lays out [itemCount] cards in two columns, sized to the available width.
class _TwoColumnGrid extends StatelessWidget {
  final int itemCount;

  /// Width divided by height of each card's artwork.
  final double aspectRatio;
  final Widget Function(BuildContext context, int index, double cardWidth) itemBuilder;

  const _TwoColumnGrid({
    required this.itemCount,
    required this.aspectRatio,
    required this.itemBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = AppSpacing.md;
        final cardWidth = (constraints.maxWidth - AppSpacing.screen * 2 - gap) / 2;
        return GridView.builder(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.screen, AppSpacing.md, AppSpacing.screen, AppSpacing.xl),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: gap,
            mainAxisSpacing: AppSpacing.lg,
            // Artwork plus two lines of text.
            mainAxisExtent: cardWidth / aspectRatio + 52,
          ),
          itemCount: itemCount,
          itemBuilder: (context, i) => itemBuilder(context, i, cardWidth),
        );
      },
    );
  }
}

class _GridSkeleton extends StatelessWidget {
  final double aspectRatio;
  const _GridSkeleton({required this.aspectRatio});

  @override
  Widget build(BuildContext context) {
    return _TwoColumnGrid(
      itemCount: 6,
      aspectRatio: aspectRatio,
      itemBuilder: (_, __, width) => Align(
        alignment: Alignment.topCenter,
        child: Skeleton(width: width, height: width / aspectRatio, radius: AppRadius.lg),
      ),
    );
  }
}

class _VideosTab extends StatefulWidget {
  const _VideosTab();

  @override
  State<_VideosTab> createState() => _VideosTabState();
}

class _VideosTabState extends State<_VideosTab> with AutomaticKeepAliveClientMixin {
  final _searchController = TextEditingController();

  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return BlocConsumer<VodBloc, VodState>(
      // Open the player only when the user has just asked to play a video.
      listenWhen: (previous, current) =>
          previous is VodSuccess &&
          current is VodSuccess &&
          previous.playRequest != current.playRequest,
      listener: (context, state) {
        if (state is VodSuccess && state.streamUrl != null) {
          Navigator.of(context, rootNavigator: true).push(MaterialPageRoute(
            builder: (_) => PlayerScreen(
              streamUrl: state.streamUrl!,
              title: state.streamTitle ?? '',
            ),
          ));
        }
      },
      builder: (context, state) {
        if (state is VodError) {
          return ErrorState(
            onRetry: () => context.read<VodBloc>().add(VodLoaded()),
          );
        }
        if (state is! VodSuccess) {
          return const _GridSkeleton(aspectRatio: 16 / 9);
        }

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.screen, AppSpacing.md, AppSpacing.screen, 0),
              child: TextField(
                controller: _searchController,
                textInputAction: TextInputAction.search,
                onChanged: (value) {
                  context.read<VodBloc>().add(VodSearched(value));
                  setState(() {}); // Show or hide the clear button.
                },
                decoration: InputDecoration(
                  hintText: 'Search videos',
                  prefixIcon: const Icon(Icons.search_rounded),
                  isDense: true,
                  suffixIcon: _searchController.text.isEmpty
                      ? null
                      : IconButton(
                          tooltip: 'Clear search',
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () {
                            _searchController.clear();
                            context.read<VodBloc>().add(const VodSearched(''));
                            setState(() {});
                          },
                        ),
                ),
              ),
            ),
            if (state.categories.length > 1)
              SizedBox(
                height: 56,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.screen, vertical: AppSpacing.sm),
                  separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
                  itemCount: state.categories.length,
                  itemBuilder: (context, i) {
                    final category = state.categories[i];
                    final selected = category == state.selectedCategory;
                    return ChoiceChip(
                      label: Text(category),
                      selected: selected,
                      labelStyle: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: selected
                                ? context.colors.onEmphasis
                                : context.colors.text,
                          ),
                      onSelected: (_) =>
                          context.read<VodBloc>().add(VodCategoryChanged(category)),
                    );
                  },
                ),
              ),
            Expanded(
              child: state.items.isEmpty
                  ? const EmptyState(
                      icon: Icons.video_library_outlined,
                      title: 'No videos found',
                      message: 'Try a different search or category.',
                    )
                  : _TwoColumnGrid(
                      itemCount: state.items.length,
                      aspectRatio: 16 / 9,
                      itemBuilder: (context, i, width) {
                        final VodItem video = state.items[i];
                        return MediaCard(
                          width: width,
                          title: video.title,
                          subtitle: video.category,
                          imageUrl: video.thumbnailUrl,
                          isPremium: video.isPremium,
                          overlayLabel: video.formattedDuration.isEmpty
                              ? null
                              : video.formattedDuration,
                          onTap: () => context
                              .read<VodBloc>()
                              .add(VodStreamRequested(video.id, video.title)),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }
}

class _PodcastsTab extends StatefulWidget {
  const _PodcastsTab();

  @override
  State<_PodcastsTab> createState() => _PodcastsTabState();
}

class _PodcastsTabState extends State<_PodcastsTab> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return BlocBuilder<PodcastBloc, PodcastState>(
      builder: (context, state) {
        if (state is PodcastError) {
          return ErrorState(
            onRetry: () => context.read<PodcastBloc>().add(PodcastsLoaded()),
          );
        }
        if (state is EpisodeListSuccess) {
          return _EpisodeList(state: state);
        }
        if (state is! PodcastListSuccess) {
          return const _GridSkeleton(aspectRatio: 1);
        }
        if (state.podcasts.isEmpty) {
          return const EmptyState(
            icon: Icons.podcasts_rounded,
            title: 'No podcasts yet',
            message: 'Podcasts will show up here once they are added.',
          );
        }
        return _TwoColumnGrid(
          itemCount: state.podcasts.length,
          aspectRatio: 1,
          itemBuilder: (context, i, width) {
            final Podcast podcast = state.podcasts[i];
            return MediaCard(
              width: width,
              aspectRatio: 1,
              icon: Icons.podcasts_rounded,
              title: podcast.title,
              subtitle: podcast.author,
              imageUrl: podcast.artworkUrl,
              isPremium: podcast.isPremium,
              onTap: () => context
                  .read<PodcastBloc>()
                  .add(EpisodesLoaded(podcast.id, podcast)),
            );
          },
        );
      },
    );
  }
}

/// One podcast's episodes, shown in place of the podcast grid.
class _EpisodeList extends StatelessWidget {
  final EpisodeListSuccess state;
  const _EpisodeList({required this.state});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final podcast = state.podcast;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.xs, AppSpacing.sm, AppSpacing.screen, AppSpacing.sm),
          child: Row(
            children: [
              IconButton(
                tooltip: 'Back to podcasts',
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: () => context.read<PodcastBloc>().add(PodcastsLoaded()),
              ),
              Artwork(
                url: podcast.artworkUrl,
                width: 52,
                height: 52,
                radius: AppRadius.md,
                icon: Icons.podcasts_rounded,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      podcast.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium,
                    ),
                    if (podcast.author != null)
                      Text(
                        podcast.author!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall,
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const Divider(),
        Expanded(
          child: state.episodes.isEmpty
              ? const EmptyState(
                  icon: Icons.podcasts_rounded,
                  title: 'No episodes yet',
                )
              : ListView.builder(
                  padding: const EdgeInsets.only(bottom: AppSpacing.xl),
                  itemCount: state.episodes.length,
                  itemBuilder: (context, i) {
                    final episode = state.episodes[i];
                    final isThis = state.nowPlaying?.id == episode.id;
                    return _EpisodeRow(
                      episode: episode,
                      isLoaded: isThis,
                      isPlaying: isThis && state.isPlaying,
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _EpisodeRow extends StatelessWidget {
  final Episode episode;

  /// This episode is in the shared player (playing or paused).
  final bool isLoaded;
  final bool isPlaying;

  const _EpisodeRow({
    required this.episode,
    required this.isLoaded,
    required this.isPlaying,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.colors;
    final bloc = context.read<PodcastBloc>();

    return InkWell(
      // Tapping the loaded episode pauses or resumes it; any other starts it.
      onTap: () => bloc.add(isLoaded ? EpisodePaused() : EpisodePlayRequested(episode)),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.screen,
          vertical: AppSpacing.md,
        ),
        child: Row(
          children: [
            // Decorative: the whole row is the button.
            ExcludeSemantics(
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: isLoaded ? colors.brand : colors.surfaceHigh,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                  color: isLoaded ? colors.onBrand : colors.text,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    episode.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall,
                  ),
                  if (isLoaded || episode.formattedDuration.isNotEmpty)
                    Text(
                      [
                        if (isLoaded) isPlaying ? 'Playing' : 'Paused',
                        if (episode.formattedDuration.isNotEmpty)
                          episode.formattedDuration,
                      ].join(' · '),
                      style: theme.textTheme.bodySmall,
                    ),
                ],
              ),
            ),
            if (episode.isPremium) ...[
              const SizedBox(width: AppSpacing.sm),
              const PremiumBadge(),
            ],
          ],
        ),
      ),
    );
  }
}
