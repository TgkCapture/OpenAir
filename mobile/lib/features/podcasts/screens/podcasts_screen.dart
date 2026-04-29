import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:openair/core/di/injection.dart';
import 'package:openair/features/podcasts/bloc/podcast_bloc.dart';
import 'package:openair/features/podcasts/models/podcast_model.dart';
import 'package:openair/features/podcasts/repository/podcast_repository.dart';

class PodcastsScreen extends StatelessWidget {
  const PodcastsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => PodcastBloc(getIt<PodcastRepository>())..add(PodcastsLoaded()),
      child: const _PodcastsView(),
    );
  }
}

class _PodcastsView extends StatelessWidget {
  const _PodcastsView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Podcasts')),
      body: BlocBuilder<PodcastBloc, PodcastState>(
        builder: (context, state) {
          if (state is PodcastLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is PodcastListSuccess) {
            if (state.podcasts.isEmpty) {
              return const Center(
                child: Text('No podcasts available', style: TextStyle(color: Colors.grey)),
              );
            }
            return GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.85,
              ),
              itemCount: state.podcasts.length,
              itemBuilder: (context, i) => _PodcastCard(podcast: state.podcasts[i]),
            );
          }

          if (state is EpisodeListSuccess) {
            return _EpisodeListView(state: state);
          }

          if (state is PodcastError) {
            return Center(child: Text(state.message));
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }
}

class _PodcastCard extends StatelessWidget {
  final Podcast podcast;
  const _PodcastCard({required this.podcast});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: () => context.read<PodcastBloc>().add(EpisodesLoaded(podcast)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: podcast.artworkUrl != null
                  ? Image.network(podcast.artworkUrl!, fit: BoxFit.cover,
                      width: double.infinity,
                      errorBuilder: (_, __, ___) => _placeholder())
                  : _placeholder(),
            ),
          ),
          const SizedBox(height: 6),
          Text(podcast.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600)),
          if (podcast.author != null)
            Text(podcast.author!,
                style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _placeholder() => Container(
        width: double.infinity,
        color: Colors.grey[800],
        child: const Icon(Icons.podcasts, color: Colors.grey, size: 40),
      );
}

class _EpisodeListView extends StatelessWidget {
  final EpisodeListSuccess state;
  const _EpisodeListView({required this.state});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Podcast header
        Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => context.read<PodcastBloc>().add(PodcastsLoaded()),
              ),
              if (state.podcast.artworkUrl != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Image.network(state.podcast.artworkUrl!,
                      width: 48, height: 48, fit: BoxFit.cover),
                )
              else
                Container(
                  width: 48, height: 48,
                  decoration: BoxDecoration(
                    color: Colors.grey[800],
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(Icons.podcasts, color: Colors.grey),
                ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(state.podcast.title,
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    if (state.podcast.author != null)
                      Text(state.podcast.author!,
                          style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Now playing bar
        if (state.nowPlaying != null)
          Container(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                const Icon(Icons.graphic_eq, color: Colors.red, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(state.nowPlaying!.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                ),
                IconButton(
                  icon: Icon(state.isPlaying ? Icons.pause : Icons.play_arrow),
                  onPressed: () => context.read<PodcastBloc>().add(EpisodePaused()),
                  iconSize: 22,
                ),
                IconButton(
                  icon: const Icon(Icons.stop),
                  onPressed: () => context.read<PodcastBloc>().add(EpisodeStopped()),
                  iconSize: 22,
                  color: Colors.red,
                ),
              ],
            ),
          ),

        // Episodes list
        Expanded(
          child: state.episodes.isEmpty
              ? const Center(child: Text('No episodes yet', style: TextStyle(color: Colors.grey)))
              : ListView.separated(
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemCount: state.episodes.length,
                  itemBuilder: (context, i) {
                    final ep = state.episodes[i];
                    final isPlaying = state.nowPlaying?.id == ep.id;
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: isPlaying
                            ? Theme.of(context).colorScheme.primary
                            : Colors.grey[800],
                        child: Icon(
                          isPlaying
                              ? (state.isPlaying ? Icons.pause : Icons.play_arrow)
                              : Icons.play_arrow,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                      title: Text(ep.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight: isPlaying ? FontWeight.bold : FontWeight.normal,
                            color: isPlaying
                                ? Theme.of(context).colorScheme.primary
                                : null,
                            fontSize: 14,
                          )),
                      subtitle: ep.formattedDuration.isNotEmpty
                          ? Text(ep.formattedDuration,
                              style: const TextStyle(fontSize: 12, color: Colors.grey))
                          : null,
                      trailing: ep.isPremium
                          ? Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primary,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text('PRO',
                                  style: TextStyle(color: Colors.white, fontSize: 10)),
                            )
                          : null,
                      onTap: () => context.read<PodcastBloc>().add(EpisodePlayRequested(ep)),
                    );
                  },
                ),
        ),
      ],
    );
  }
}