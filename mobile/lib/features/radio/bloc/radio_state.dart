part of 'radio_bloc.dart';

abstract class RadioState extends Equatable {
  const RadioState();
  @override List<Object?> get props => [];
}

class RadioInitial extends RadioState {}
class RadioLoading extends RadioState {}

class RadioChannelsSuccess extends RadioState {
  final List<Channel> channels;
  final Channel? nowPlaying;
  const RadioChannelsSuccess(this.channels, this.nowPlaying);
  @override List<Object?> get props => [channels, nowPlaying?.id];
}

class RadioError extends RadioState {
  final String message;
  const RadioError(this.message);
  @override List<Object?> get props => [message];
}