class Channel {
  final String id;
  final String name;
  final String type;
  final String streamUrl;
  final String? logoUrl;
  final String? description;
  final bool isPremium;
  final bool isActive;
  final int sortOrder;

  const Channel({
    required this.id,
    required this.name,
    required this.type,
    required this.streamUrl,
    this.logoUrl,
    this.description,
    required this.isPremium,
    required this.isActive,
    required this.sortOrder,
  });

  factory Channel.fromJson(Map<String, dynamic> json) => Channel(
        id: json['id'],
        name: json['name'],
        type: json['type'],
        streamUrl: json['stream_url'],
        logoUrl: json['logo_url'],
        description: json['description'],
        isPremium: json['is_premium'] ?? false,
        isActive: json['is_active'] ?? true,
        sortOrder: json['sort_order'] ?? 0,
      );
}

class StreamUrlResponse {
  final String url;
  final int expiresAt;

  const StreamUrlResponse({required this.url, required this.expiresAt});

  factory StreamUrlResponse.fromJson(Map<String, dynamic> json) =>
      StreamUrlResponse(
        url: json['url'],
        expiresAt: json['expires_at'] ?? 0,
      );
}