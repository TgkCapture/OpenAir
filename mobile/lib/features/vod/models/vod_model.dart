class VodItem {
  final String id;
  final String title;
  final String? description;
  final String type;
  final String fileUrl;
  final String? thumbnailUrl;
  final String? category;
  final int? durationSecs;
  final bool isPremium;
  final int viewCount;

  const VodItem({
    required this.id,
    required this.title,
    this.description,
    required this.type,
    required this.fileUrl,
    this.thumbnailUrl,
    this.category,
    this.durationSecs,
    required this.isPremium,
    required this.viewCount,
  });

  factory VodItem.fromJson(Map<String, dynamic> json) => VodItem(
        id: json['id'],
        title: json['title'],
        description: json['description'],
        type: json['type'],
        fileUrl: json['file_url'],
        thumbnailUrl: json['thumbnail_url'],
        category: json['category'],
        durationSecs: json['duration_secs'],
        isPremium: json['is_premium'] ?? false,
        viewCount: json['view_count'] ?? 0,
      );

  String get formattedDuration {
    if (durationSecs == null) return '';
    final m = durationSecs! ~/ 60;
    final s = durationSecs! % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }
}