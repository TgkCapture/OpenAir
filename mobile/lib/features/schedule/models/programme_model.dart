class Programme {
  final String id;
  final String channelId;
  final String? channelName;
  final String title;
  final String? description;
  final DateTime startsAt;
  final DateTime endsAt;

  const Programme({
    required this.id,
    required this.channelId,
    this.channelName,
    required this.title,
    this.description,
    required this.startsAt,
    required this.endsAt,
  });

  factory Programme.fromJson(Map<String, dynamic> json) => Programme(
        id: json['id'],
        channelId: json['channel_id'],
        channelName: json['channel_name'],
        title: json['title'],
        description: json['description'],
        startsAt: DateTime.parse(json['starts_at']).toLocal(),
        endsAt: DateTime.parse(json['ends_at']).toLocal(),
      );

  bool get isLive {
    final now = DateTime.now();
    return now.isAfter(startsAt) && now.isBefore(endsAt);
  }

  String get timeRange {
    String fmt(DateTime dt) =>
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    return '${fmt(startsAt)} – ${fmt(endsAt)}';
  }

  double get progress {
    final now = DateTime.now();
    if (!isLive) return 0;
    final total = endsAt.difference(startsAt).inSeconds;
    final elapsed = now.difference(startsAt).inSeconds;
    return (elapsed / total).clamp(0.0, 1.0);
  }
}

class NowAndNext {
  final String channelId;
  final Programme? now;
  final Programme? next;

  const NowAndNext({
    required this.channelId,
    this.now,
    this.next,
  });

  factory NowAndNext.fromJson(Map<String, dynamic> json) => NowAndNext(
        channelId: json['channel_id'],
        now: json['now'] != null ? Programme.fromJson(json['now']) : null,
        next: json['next'] != null ? Programme.fromJson(json['next']) : null,
      );
}