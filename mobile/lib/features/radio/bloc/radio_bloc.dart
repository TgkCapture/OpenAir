import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:just_audio/just_audio.dart';
import 'package:openair/features/tv/models/channel_model.dart';
import 'package:openair/features/tv/repository/channel_repository.dart';

part 'radio_event.dart';
part 'radio_state.dart';

class RadioBloc extends Bloc<RadioEvent, RadioState> {
  final ChannelRepository _repo;
  final AudioPlayer _player = AudioPlayer();

  RadioBloc(this._repo) : super(RadioInitial()) {
    on<RadioChannelsLoaded>(_onLoad);
    on<RadioPlayRequested>(_onPlay);
    on<RadioStopped>(_onStop);
  }

  Future<void> _onLoad(RadioChannelsLoaded event, Emitter<RadioState> emit) async {
    emit(RadioLoading());
    try {
      final channels = await _repo.getRadioChannels();
      emit(RadioChannelsSuccess(channels, null));
    } catch (e) {
      emit(RadioError(e.toString()));
    }
  }

  Future<void> _onPlay(RadioPlayRequested event, Emitter<RadioState> emit) async {
    try {
      final streamUrl = await _repo.getStreamUrl(event.channel.id);
      await _player.stop();
      await _player.setUrl(streamUrl.url);
      await _player.play();
      final channels = state is RadioChannelsSuccess
          ? (state as RadioChannelsSuccess).channels
          : <Channel>[];
      emit(RadioChannelsSuccess(channels, event.channel));
    } catch (e) {
      emit(RadioError(e.toString()));
    }
  }

  Future<void> _onStop(RadioStopped event, Emitter<RadioState> emit) async {
    await _player.stop();
    final channels = state is RadioChannelsSuccess
        ? (state as RadioChannelsSuccess).channels
        : <Channel>[];
    emit(RadioChannelsSuccess(channels, null));
  }

  @override
  Future<void> close() {
    _player.dispose();
    return super.close();
  }
}