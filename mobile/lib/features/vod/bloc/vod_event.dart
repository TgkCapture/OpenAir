part of 'vod_bloc.dart';

abstract class VodEvent extends Equatable {
  const VodEvent();
  @override List<Object?> get props => [];
}

class VodLoaded extends VodEvent {}

class VodCategoryChanged extends VodEvent {
  final String category;
  const VodCategoryChanged(this.category);
  @override List<Object?> get props => [category];
}

class VodSearched extends VodEvent {
  final String query;
  const VodSearched(this.query);
  @override List<Object?> get props => [query];
}

class VodStreamRequested extends VodEvent {
  final String itemId;
  final String title;
  const VodStreamRequested(this.itemId, this.title);
  @override List<Object?> get props => [itemId];
}