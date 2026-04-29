import 'package:openair/core/services/api_service.dart';
import 'package:openair/features/vod/models/vod_model.dart';

class VodRepository {
  final ApiService _api;
  VodRepository(this._api);

  Future<List<VodItem>> getVod({
    String? category,
    String? search,
    int page = 1,
  }) async {
    final res = await _api.dio.get('/vod', queryParameters: {
      'type': 'vod',
      if (category != null && category != 'All') 'category': category,
      if (search != null && search.isNotEmpty) 'q': search,
      'page': page,
      'per_page': 20,
    });
    final List data = res.data['data'] ?? [];
    return data.map((e) => VodItem.fromJson(e)).toList();
  }

  Future<List<String>> getCategories() async {
    final res = await _api.dio.get('/vod/categories');
    final List data = res.data['data'] ?? [];
    return ['All', ...data.cast<String>()];
  }

  Future<String> getStreamUrl(String id) async {
    final res = await _api.dio.get('/vod/$id/stream');
    return res.data['data']['url'];
  }

  Future<List<VodItem>> getWatchHistory() async {
    final res = await _api.dio.get('/watch-history');
    final List data = res.data['data'] ?? [];
    return data.map((e) => VodItem.fromJson(e)).toList();
  }

  Future<void> saveProgress(String contentId, int progressSecs) async {
    await _api.dio.post('/watch-history', data: {
      'content_id': contentId,
      'progress_secs': progressSecs,
    });
  }
}