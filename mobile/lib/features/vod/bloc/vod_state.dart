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
  final String? streamUrl;
  final String? streamTitle;

  const VodSuccess({
    required this.items,
    required this.categories,
    required this.selectedCategory,
    this.streamUrl,
    this.streamTitle,
  });

  VodSuccess copyWith({
    List<VodItem>? items,
    List<String>? categories,
    String? selectedCategory,
    String? streamUrl,
    String? streamTitle,
  }) =>
      VodSuccess(
        items: items ?? this.items,
        categories: categories ?? this.categories,
        selectedCategory: selectedCategory ?? this.selectedCategory,
        streamUrl: streamUrl ?? this.streamUrl,
        streamTitle: streamTitle ?? this.streamTitle,
      );

  @override
  List<Object?> get props => [items, categories, selectedCategory, streamUrl];
}

class VodError extends VodState {
  final String message;
  const VodError(this.message);
  @override List<Object?> get props => [message];
}