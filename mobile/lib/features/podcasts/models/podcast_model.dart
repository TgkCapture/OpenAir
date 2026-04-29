class Podcast {
  final String id;
  final String title;
  final String? description;
  final String? artworkUrl;
  final String? author;
  final String? category;
  final bool isPremium;

  const Podcast({
    required this.id,
    required this.title,
    this.description,
    this.artworkUrl,
    this.author,
    this.category,
    required this.isPremium,
  });

  factory Podcast.fromJson(Map<String, dynamic> json) => Podcast(
        id: json['id'],
        title: json['title'],
        description: json['description'],
        artworkUrl: json['artwork_url'],
        author: json['author'],
        category: json['category'],
        isPremium: json['is_premium'] ?? false,
      );
}

class Episode {
  final String id;
  final String podcastId;
  final String title;
  final String? description;
  final String audioUrl;
  final String? thumbnailUrl;
  final int? durationSecs;
  final int? episodeNumber;
  final bool isPremium;

  const Episode({
    required this.id,
    required this.podcastId,
    required this.title,
    this.description,
    required this.audioUrl,
    this.thumbnailUrl,
    this.durationSecs,
    this.episodeNumber,
    required this.isPremium,
  });

  factory Episode.fromJson(Map<String, dynamic> json) => Episode(
        id: json['id'],
        podcastId: json['podcast_id'],
        title: json['title'],
        description: json['description'],
        audioUrl: json['audio_url'],
        thumbnailUrl: json['thumbnail_url'],
        durationSecs: json['duration_secs'],
        episodeNumber: json['episode_number'],
        isPremium: json['is_premium'] ?? false,
      );

  String get formattedDuration {
    if (durationSecs == null) return '';
    final h = durationSecs! ~/ 3600;
    final m = (durationSecs! % 3600) ~/ 60;
    final s = durationSecs! % 60;
    if (h > 0) return '${h}h ${m}m';
    return '${m}m ${s}s';
  }
}