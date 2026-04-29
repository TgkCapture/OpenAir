part of 'podcast_bloc.dart';

abstract class PodcastEvent extends Equatable {
  const PodcastEvent();

  @override
  List<Object?> get props => [];
}

class PodcastsLoaded extends PodcastEvent {}

class EpisodesLoaded extends PodcastEvent {
  final String podcastId;
  final Podcast podcast;

  const EpisodesLoaded(this.podcastId, this.podcast);

  @override
  List<Object?> get props => [podcastId, podcast];
}

class EpisodePlayRequested extends PodcastEvent {
  final Episode episode;

  const EpisodePlayRequested(this.episode);

  @override
  List<Object?> get props => [episode];
}

class EpisodePaused extends PodcastEvent {}

class EpisodeStopped extends PodcastEvent {}