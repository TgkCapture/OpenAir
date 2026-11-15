part of 'vod_bloc.dart';

abstract class VodState extends Equatable {
  const VodState();
  @override List<Object?> get props => [];
}

class VodInitial extends VodState {}
class VodLoading extends VodState {}

class VodSuccess extends VodState {
  final List<VodItem> items;
  final List<String> categories;
  final String selectedCategory;
  /// The stream to open, set by the latest play request.
  final String? streamUrl;
  final String? streamTitle;

  /// Goes up by one each time the user asks to play a video. The screen opens
  /// the player when this changes, so searching or changing category never
  /// reopens it, and the same video can be played again.
  final int playRequest;

  const VodSuccess({
    required this.items,
    required this.categories,
    required this.selectedCategory,
    this.streamUrl,
    this.streamTitle,
    this.playRequest = 0,
  });

  VodSuccess copyWith({
    List<VodItem>? items,
    List<String>? categories,
    String? selectedCategory,
    String? streamUrl,
    String? streamTitle,
    int? playRequest,
  }) =>
      VodSuccess(
        items: items ?? this.items,
        categories: categories ?? this.categories,
        selectedCategory: selectedCategory ?? this.selectedCategory,
        streamUrl: streamUrl ?? this.streamUrl,
        streamTitle: streamTitle ?? this.streamTitle,
        playRequest: playRequest ?? this.playRequest,
      );

  @override
  List<Object?> get props => [items, categories, selectedCategory, playRequest];
}

class VodError extends VodState {
  final String message;
  const VodError(this.message);
  @override List<Object?> get props => [message];
}