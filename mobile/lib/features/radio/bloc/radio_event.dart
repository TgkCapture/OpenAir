part of 'radio_bloc.dart';

abstract class RadioEvent extends Equatable {
  const RadioEvent();
  @override List<Object?> get props => [];
}

class RadioChannelsLoaded extends RadioEvent {}

class RadioPlayRequested extends RadioEvent {
  final Channel channel;
  const RadioPlayRequested(this.channel);
  @override List<Object?> get props => [channel.id];
}

class RadioStopped extends RadioEvent {}