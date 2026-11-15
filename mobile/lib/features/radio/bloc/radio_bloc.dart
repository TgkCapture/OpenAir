import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:openair/core/audio/audio_controller.dart';
import 'package:openair/features/tv/models/channel_model.dart';
import 'package:openair/features/tv/repository/channel_repository.dart';

part 'radio_event.dart';
part 'radio_state.dart';

class RadioBloc extends Bloc<RadioEvent, RadioState> {
  final ChannelRepository _repo;
  final AudioController _audio;
  late final StreamSubscription<NowPlaying?> _audioSub;

  RadioBloc(this._repo, this._audio) : super(RadioInitial()) {
    on<RadioChannelsLoaded>(_onLoad);
    on<RadioPlayRequested>(_onPlay);
    on<RadioStopped>(_onStop);
    on<_RadioAudioChanged>(_onAudioChanged);

    // Playback belongs to the shared player, so follow it: it may be started
    // or stopped from Home, the mini player or the lock screen.
    _audioSub = _audio.stream.listen((_) => add(_RadioAudioChanged()));
  }

  /// The channel the shared player is playing, if it is one of [channels].
  Channel? _nowPlaying(List<Channel> channels) {
    final id = _audio.state?.id;
    if (id == null) return null;
    for (final channel in channels) {
      if (AudioController.radioId(channel.id) == id) return channel;
    }
    return null;
  }

  Future<void> _onLoad(RadioChannelsLoaded event, Emitter<RadioState> emit) async {
    emit(RadioLoading());
    try {
      final channels = await _repo.getRadioChannels();
      emit(RadioChannelsSuccess(channels, _nowPlaying(channels)));
    } catch (e) {
      emit(RadioError(e.toString()));
    }
  }

  Future<void> _onPlay(RadioPlayRequested event, Emitter<RadioState> emit) async {
    // Tapping the channel that is already playing stops it.
    if (_audio.state?.id == AudioController.radioId(event.channel.id)) {
      await _audio.stop();
      return;
    }
    try {
      final streamUrl = await _repo.getStreamUrl(event.channel.id);
      await _audio.play(
        id: AudioController.radioId(event.channel.id),
        url: streamUrl.url,
        title: event.channel.name,
        subtitle: 'Live radio',
        artUrl: event.channel.logoUrl,
        isLive: true,
      );
    } catch (e) {
      emit(RadioError(e.toString()));
    }
  }

  Future<void> _onStop(RadioStopped event, Emitter<RadioState> emit) async {
    await _audio.stop();
  }

  void _onAudioChanged(_RadioAudioChanged event, Emitter<RadioState> emit) {
    final current = state;
    if (current is RadioChannelsSuccess) {
      emit(RadioChannelsSuccess(current.channels, _nowPlaying(current.channels)));
    }
  }

  @override
  Future<void> close() {
    _audioSub.cancel();
    return super.close();
  }
}
