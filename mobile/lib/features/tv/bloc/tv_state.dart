part of 'tv_bloc.dart';

abstract class TvState extends Equatable {
  const TvState();
  @override List<Object?> get props => [];
}

class TvInitial extends TvState {}
class TvLoading extends TvState {}

class TvChannelsSuccess extends TvState {
  final List<Channel> channels;

  /// The stream to open, set by the latest play request.
  final String? streamUrl;
  final String? streamTitle;

  /// Goes up by one each time the user asks to play a channel. The screen
  /// opens the player when this changes, so the channel list stays in the
  /// state and the same channel can be played again.
  final int playRequest;

  const TvChannelsSuccess(
    this.channels, {
    this.streamUrl,
    this.streamTitle,
    this.playRequest = 0,
  });

  @override List<Object?> get props => [channels, playRequest];
}

class TvError extends TvState {
  final String message;
  const TvError(this.message);
  @override List<Object?> get props => [message];
}
