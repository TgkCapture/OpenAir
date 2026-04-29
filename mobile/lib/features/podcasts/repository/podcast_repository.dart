import 'package:openair/core/services/api_service.dart';
import 'package:openair/features/podcasts/models/podcast_model.dart';

class PodcastRepository {
  final ApiService _api;
  PodcastRepository(this._api);

  Future<List<Podcast>> getPodcasts() async {
    final res = await _api.dio.get('/podcasts');
    final List data = res.data['data'] ?? [];
    return data.map((e) => Podcast.fromJson(e)).toList();
  }

  Future<List<Episode>> getEpisodes(String podcastId) async {
    final res = await _api.dio.get('/podcasts/$podcastId/episodes');
    final List data = res.data['data'] ?? [];
    return data.map((e) => Episode.fromJson(e)).toList();
  }

  Future<String> getEpisodeStreamUrl(String podcastId, String episodeId) async {
    final res = await _api.dio.get('/podcasts/$podcastId/episodes/$episodeId/stream');
    return res.data['data']['url'];
  }
}