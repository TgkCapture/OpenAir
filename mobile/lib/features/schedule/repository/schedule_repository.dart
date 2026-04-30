import 'package:openair/core/services/api_service.dart';
import 'package:openair/features/schedule/models/programme_model.dart';

class ScheduleRepository {
  final ApiService _api;
  ScheduleRepository(this._api);

  Future<List<Programme>> getByChannel(String channelId, {DateTime? date}) async {
    final d = date ?? DateTime.now();
    final dateStr =
        '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
    final res = await _api.dio.get(
      '/schedule/$channelId',
      queryParameters: {'date': dateStr},
    );
    final List data = res.data['data'] ?? [];
    return data.map((e) => Programme.fromJson(e)).toList();
  }

  Future<List<NowAndNext>> getAllNowAndNext() async {
    final res = await _api.dio.get('/schedule/now');
    final List data = res.data['data'] ?? [];
    return data.map((e) => NowAndNext.fromJson(e)).toList();
  }
}