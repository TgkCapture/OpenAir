part of 'tv_bloc.dart';

abstract class TvEvent extends Equatable {
  const TvEvent();
  @override List<Object> get props => [];
}

class TvChannelsLoaded extends TvEvent {}

class TvStreamRequested extends TvEvent {
  final String channelId;
  final String channelName;
  const TvStreamRequested(this.channelId, this.channelName);
  @override List<Object> get props => [channelId, channelName];
}