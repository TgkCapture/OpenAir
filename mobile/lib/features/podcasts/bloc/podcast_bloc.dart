import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:just_audio/just_audio.dart';
import 'package:openair/features/podcasts/models/podcast_model.dart';
import 'package:openair/features/podcasts/repository/podcast_repository.dart';

part 'podcast_event.dart';
part 'podcast_state.dart';

class PodcastBloc extends Bloc<PodcastEvent, PodcastState> {
  final PodcastRepository _repo;
  final AudioPlayer _player = AudioPlayer();

  PodcastBloc(this._repo) : super(PodcastInitial()) {
    on<PodcastsLoaded>(_onLoad);
    on<EpisodesLoaded>(_onEpisodes);
    on<EpisodePlayRequested>(_onPlay);
    on<EpisodePaused>(_onPause);
    on<EpisodeStopped>(_onStop);
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
      emit(EpisodeListSuccess(event.podcast, episodes, null, false));
    } catch (e) {
      emit(PodcastError(e.toString()));
    }
  }

  Future<void> _onPlay(EpisodePlayRequested event, Emitter<PodcastState> emit) async {
    if (state is! EpisodeListSuccess) return;
    final current = state as EpisodeListSuccess;
    try {
      final url = await _repo.getEpisodeStreamUrl(
          event.episode.podcastId, event.episode.id);
      await _player.stop();
      await _player.setUrl(url);
      await _player.play();
      emit(current.copyWith(nowPlaying: event.episode, isPlaying: true));
    } catch (e) {
      emit(PodcastError(e.toString()));
    }
  }

  Future<void> _onPause(EpisodePaused event, Emitter<PodcastState> emit) async {
    if (state is! EpisodeListSuccess) return;
    final current = state as EpisodeListSuccess;
    if (_player.playing) {
      await _player.pause();
      emit(current.copyWith(isPlaying: false));
    } else {
      await _player.play();
      emit(current.copyWith(isPlaying: true));
    }
  }

  Future<void> _onStop(EpisodeStopped event, Emitter<PodcastState> emit) async {
    await _player.stop();
    if (state is EpisodeListSuccess) {
      final current = state as EpisodeListSuccess;
      emit(current.copyWith(nowPlaying: null, isPlaying: false));
    }
  }

  @override
  Future<void> close() {
    _player.dispose();
    return super.close();
  }
}