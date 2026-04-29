import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:openair/features/tv/models/channel_model.dart';
import 'package:openair/features/tv/repository/channel_repository.dart';

part 'tv_event.dart';
part 'tv_state.dart';

class TvBloc extends Bloc<TvEvent, TvState> {
  final ChannelRepository _repo;

  TvBloc(this._repo) : super(TvInitial()) {
    on<TvChannelsLoaded>(_onLoad);
    on<TvStreamRequested>(_onStream);
  }

  Future<void> _onLoad(TvChannelsLoaded event, Emitter<TvState> emit) async {
    emit(TvLoading());
    try {
      final channels = await _repo.getTvChannels();
      emit(TvChannelsSuccess(channels));
    } catch (e) {
      emit(TvError(e.toString()));
    }
  }

  Future<void> _onStream(TvStreamRequested event, Emitter<TvState> emit) async {
    try {
      final streamUrl = await _repo.getStreamUrl(event.channelId);
      emit(TvStreamReady(streamUrl.url, event.channelName));
    } catch (e) {
      emit(TvError(e.toString()));
    }
  }
}