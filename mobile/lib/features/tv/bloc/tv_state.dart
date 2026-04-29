part of 'tv_bloc.dart';

abstract class TvState extends Equatable {
  const TvState();
  @override List<Object?> get props => [];
}

class TvInitial extends TvState {}
class TvLoading extends TvState {}

class TvChannelsSuccess extends TvState {
  final List<Channel> channels;
  const TvChannelsSuccess(this.channels);
  @override List<Object?> get props => [channels];
}

class TvStreamReady extends TvState {
  final String streamUrl;
  final String channelName;
  const TvStreamReady(this.streamUrl, this.channelName);
  @override List<Object?> get props => [streamUrl, channelName];
}

class TvError extends TvState {
  final String message;
  const TvError(this.message);
  @override List<Object?> get props => [message];
}