import 'package:openair/core/services/api_service.dart';
import 'package:openair/features/tv/models/channel_model.dart';

class ChannelRepository {
  final ApiService _api;

  ChannelRepository(this._api);

  Future<List<Channel>> getTvChannels() async {
    final res = await _api.dio.get('/channels', queryParameters: {'type': 'tv'});
    final List data = res.data['data'] ?? [];
    return data.map((e) => Channel.fromJson(e)).toList();
  }

  Future<List<Channel>> getRadioChannels() async {
    final res = await _api.dio.get('/channels', queryParameters: {'type': 'radio'});
    final List data = res.data['data'] ?? [];
    return data.map((e) => Channel.fromJson(e)).toList();
  }

  Future<StreamUrlResponse> getStreamUrl(String channelId) async {
    final res = await _api.dio.get('/channels/$channelId/stream');
    return StreamUrlResponse.fromJson(res.data['data']);
  }
}