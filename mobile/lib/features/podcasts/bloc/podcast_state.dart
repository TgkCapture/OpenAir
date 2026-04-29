part of 'podcast_bloc.dart';

abstract class PodcastState extends Equatable {
  const PodcastState();
  @override List<Object?> get props => [];
}

class PodcastInitial extends PodcastState {}
class PodcastLoading extends PodcastState {}

class PodcastListSuccess extends PodcastState {
  final List<Podcast> podcasts;
  const PodcastListSuccess(this.podcasts);
  @override List<Object?> get props => [podcasts];
}

class EpisodeListSuccess extends PodcastState {
  final Podcast podcast;
  final List<Episode> episodes;
  final Episode? nowPlaying;
  final bool isPlaying;

  const EpisodeListSuccess(this.podcast, this.episodes, this.nowPlaying, this.isPlaying);

  EpisodeListSuccess copyWith({
    List<Episode>? episodes,
    Episode? nowPlaying,
    bool? isPlaying,
  }) =>
      EpisodeListSuccess(
        podcast,
        episodes ?? this.episodes,
        nowPlaying ?? this.nowPlaying,
        isPlaying ?? this.isPlaying,
      );

  @override List<Object?> get props => [podcast.id, episodes, nowPlaying?.id, isPlaying];
}

class PodcastError extends PodcastState {
  final String message;
  const PodcastError(this.message);
  @override List<Object?> get props => [message];
}