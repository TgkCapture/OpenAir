import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:openair/core/audio/audio_controller.dart';
import 'package:openair/features/podcasts/models/podcast_model.dart';
import 'package:openair/features/podcasts/repository/podcast_repository.dart';

part 'podcast_event.dart';
part 'podcast_state.dart';

class PodcastBloc extends Bloc<PodcastEvent, PodcastState> {
  final PodcastRepository _repo;
  final AudioController _audio;
  late final StreamSubscription<NowPlaying?> _audioSub;

  PodcastBloc(this._repo, this._audio) : super(PodcastInitial()) {
    on<PodcastsLoaded>(_onLoad);
    on<EpisodesLoaded>(_onEpisodes);
    on<EpisodePlayRequested>(_onPlay);
    on<EpisodePaused>(_onPause);
    on<EpisodeStopped>(_onStop);
    on<_PodcastAudioChanged>(_onAudioChanged);

    // Playback belongs to the shared player, so follow it: it may be paused
    // or stopped from the mini player or the lock screen.
    _audioSub = _audio.stream.listen((_) => add(_PodcastAudioChanged()));
  }

  /// The episode the shared player has loaded, if it is one of [episodes].
  Episode? _nowPlaying(List<Episode> episodes) {
    final id = _audio.state?.id;
    if (id == null) return null;
    for (final episode in episodes) {
      if (AudioController.episodeId(episode.id) == id) return episode;
    }
    return null;
  }

  EpisodeListSuccess _withPlayback(Podcast podcast, List<Episode> episodes) {
    final nowPlaying = _nowPlaying(episodes);
    final isPlaying = nowPlaying != null && (_audio.state?.isPlaying ?? false);
    return EpisodeListSuccess(podcast, episodes, nowPlaying, isPlaying);
  }

  Future<void> _onLoad(PodcastsLoaded event, Emitter<PodcastState> emit) async {
    emit(PodcastLoading());
    try {
      final podcasts = await _repo.getPodcasts();
      emit(PodcastListSuccess(podcasts));
    } catch (e) {
      emit(PodcastError(e.toString()));
    }
  }

  Future<void> _onEpisodes(EpisodesLoaded event, Emitter<PodcastState> emit) async {
    emit(PodcastLoading());
    try {
      final episodes = await _repo.getEpisodes(event.podcastId);
      emit(_withPlayback(event.podcast, episodes));
    } catch (e) {
      emit(PodcastError(e.toString()));
    }
  }

  Future<void> _onPlay(EpisodePlayRequested event, Emitter<PodcastState> emit) async {
    final current = state;
    if (current is! EpisodeListSuccess) return;
    try {
      final url = await _repo.getEpisodeStreamUrl(
          event.episode.podcastId, event.episode.id);
      await _audio.play(
        id: AudioController.episodeId(event.episode.id),
        url: url,
        title: event.episode.title,
        subtitle: current.podcast.title,
        artUrl: event.episode.thumbnailUrl ?? current.podcast.artworkUrl,
        isLive: false,
      );
    } catch (e) {
      emit(PodcastError(e.toString()));
    }
  }

  Future<void> _onPause(EpisodePaused event, Emitter<PodcastState> emit) async {
    await _audio.toggle();
  }

  Future<void> _onStop(EpisodeStopped event, Emitter<PodcastState> emit) async {
    await _audio.stop();
  }

  void _onAudioChanged(_PodcastAudioChanged event, Emitter<PodcastState> emit) {
    final current = state;
    if (current is EpisodeListSuccess) {
      emit(_withPlayback(current.podcast, current.episodes));
    }
  }

  @override
  Future<void> close() {
    _audioSub.cancel();
    return super.close();
  }
}
