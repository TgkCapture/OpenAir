import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:openair/features/vod/models/vod_model.dart';
import 'package:openair/features/vod/repository/vod_repository.dart';

part 'vod_event.dart';
part 'vod_state.dart';

class VodBloc extends Bloc<VodEvent, VodState> {
  final VodRepository _repo;

  VodBloc(this._repo) : super(VodInitial()) {
    on<VodLoaded>(_onLoad);
    on<VodCategoryChanged>(_onCategory);
    on<VodSearched>(_onSearch);
    on<VodStreamRequested>(_onStream);
  }

  Future<void> _onLoad(VodLoaded event, Emitter<VodState> emit) async {
    emit(VodLoading());
    try {
      final results = await Future.wait([
        _repo.getVod(),
        _repo.getCategories(),
      ]);
      emit(VodSuccess(
        items: results[0] as List<VodItem>,
        categories: results[1] as List<String>,
        selectedCategory: 'All',
      ));
    } catch (e) {
      emit(VodError(e.toString()));
    }
  }

  Future<void> _onCategory(VodCategoryChanged event, Emitter<VodState> emit) async {
    if (state is! VodSuccess) return;
    final current = state as VodSuccess;
    emit(VodLoading());
    try {
      final items = await _repo.getVod(category: event.category);
      emit(current.copyWith(items: items, selectedCategory: event.category));
    } catch (e) {
      emit(VodError(e.toString()));
    }
  }

  Future<void> _onSearch(VodSearched event, Emitter<VodState> emit) async {
    if (state is! VodSuccess) return;
    try {
      final items = await _repo.getVod(search: event.query);
      // Copy from the state as it is now, not as it was before the request,
      // so a play request made in the meantime is not overwritten.
      final latest = state;
      if (latest is VodSuccess) emit(latest.copyWith(items: items));
    } catch (e) {
      emit(VodError(e.toString()));
    }
  }

  Future<void> _onStream(VodStreamRequested event, Emitter<VodState> emit) async {
    if (state is! VodSuccess) return;
    try {
      final url = await _repo.getStreamUrl(event.itemId);
      final latest = state;
      if (latest is! VodSuccess) return;
      emit(latest.copyWith(
        streamUrl: url,
        streamTitle: event.title,
        playRequest: latest.playRequest + 1,
      ));
    } catch (e) {
      emit(VodError(e.toString()));
    }
  }
}