import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:openair/core/di/injection.dart';
import 'package:openair/core/services/api_service.dart';
import 'package:openair/features/tv/models/channel_model.dart';
import 'package:openair/features/tv/screens/player_screen.dart';
import 'package:openair/features/vod/models/vod_model.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Channel> _tvChannels = [];
  List<Channel> _radioChannels = [];
  List<VodItem> _featuredVod = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() { _loading = true; _error = null; });
    try {
      final api = getIt<ApiService>();
      final results = await Future.wait([
        api.dio.get('/channels', queryParameters: {'type': 'tv'}),
        api.dio.get('/channels', queryParameters: {'type': 'radio'}),
        api.dio.get('/vod', queryParameters: {'type': 'vod', 'per_page': 6}),
      ]);

      setState(() {
        _tvChannels = (results[0].data['data'] as List? ?? [])
            .map((e) => Channel.fromJson(e)).toList();
        _radioChannels = (results[1].data['data'] as List? ?? [])
            .map((e) => Channel.fromJson(e)).toList();
        _featuredVod = (results[2].data['data'] as List? ?? [])
            .map((e) => VodItem.fromJson(e)).toList();
        _loading = false;
      });
    } on DioException catch (e) {
      setState(() {
        _error = e.message ?? 'Failed to load content';
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _playChannel(Channel channel) async {
    try {
      final api = getIt<ApiService>();
      final res = await api.dio.get('/channels/${channel.id}/stream');
      final url = res.data['data']['url'];
      if (!mounted) return;
      Navigator.push(context, MaterialPageRoute(
        builder: (_) => PlayerScreen(streamUrl: url, title: channel.name),
      ));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not load stream: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _playVod(VodItem item) async {
    try {
      final api = getIt<ApiService>();
      final res = await api.dio.get('/vod/${item.id}/stream');
      final url = res.data['data']['url'];
      if (!mounted) return;
      Navigator.push(context, MaterialPageRoute(
        builder: (_) => PlayerScreen(streamUrl: url, title: item.title),
      ));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not load video: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.radio, color: theme.colorScheme.primary, size: 22),
            const SizedBox(width: 8),
            const Text('OpenAir', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.wifi_off, size: 64, color: Colors.grey),
                      const SizedBox(height: 16),
                      Text(_error!, textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.grey)),
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        onPressed: _loadData,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadData,
                  child: ListView(
                    children: [
                      // Live TV section
                      if (_tvChannels.isNotEmpty) ...[
                        _SectionHeader(
                          title: 'Live TV',
                          icon: Icons.tv,
                          onSeeAll: () {},
                        ),
                        SizedBox(
                          height: 110,
                          child: ListView.separated(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            scrollDirection: Axis.horizontal,
                            separatorBuilder: (_, __) => const SizedBox(width: 12),
                            itemCount: _tvChannels.length,
                            itemBuilder: (context, i) =>
                                _LiveChannelChip(
                                  channel: _tvChannels[i],
                                  onTap: () => _playChannel(_tvChannels[i]),
                                ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Live Radio section
                      if (_radioChannels.isNotEmpty) ...[
                        _SectionHeader(
                          title: 'Live Radio',
                          icon: Icons.radio,
                          onSeeAll: () {},
                        ),
                        SizedBox(
                          height: 80,
                          child: ListView.separated(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            scrollDirection: Axis.horizontal,
                            separatorBuilder: (_, __) => const SizedBox(width: 12),
                            itemCount: _radioChannels.length,
                            itemBuilder: (context, i) =>
                                _RadioChip(channel: _radioChannels[i]),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Featured VOD section
                      if (_featuredVod.isNotEmpty) ...[
                        _SectionHeader(
                          title: 'Featured Videos',
                          icon: Icons.video_library_outlined,
                          onSeeAll: () {},
                        ),
                        SizedBox(
                          height: 180,
                          child: ListView.separated(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            scrollDirection: Axis.horizontal,
                            separatorBuilder: (_, __) => const SizedBox(width: 12),
                            itemCount: _featuredVod.length,
                            itemBuilder: (context, i) =>
                                _VodCard(
                                  item: _featuredVod[i],
                                  onTap: () => _playVod(_featuredVod[i]),
                                ),
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],

                      // Empty state
                      if (_tvChannels.isEmpty &&
                          _radioChannels.isEmpty &&
                          _featuredVod.isEmpty)
                        Padding(
                          padding: const EdgeInsets.all(48),
                          child: Column(
                            children: [
                              Icon(Icons.live_tv,
                                  size: 80,
                                  color: theme.colorScheme.primary.withOpacity(0.4)),
                              const SizedBox(height: 16),
                              const Text('No content available yet',
                                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 8),
                              const Text(
                                'Content will appear here once channels and videos are added.',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onSeeAll;

  const _SectionHeader({
    required this.title,
    required this.icon,
    required this.onSeeAll,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 8, 12),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 8),
          Text(title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const Spacer(),
          TextButton(onPressed: onSeeAll, child: const Text('See all')),
        ],
      ),
    );
  }
}

class _LiveChannelChip extends StatelessWidget {
  final Channel channel;
  final VoidCallback onTap;

  const _LiveChannelChip({required this.channel, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 120,
        decoration: BoxDecoration(
          color: theme.cardTheme.color,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: theme.dividerColor.withOpacity(0.3)),
        ),
        child: Stack(
          children: [
            Center(
              child: channel.logoUrl != null
                  ? Image.network(channel.logoUrl!,
                      height: 40,
                      errorBuilder: (_, __, ___) =>
                          const Icon(Icons.tv, size: 36, color: Colors.grey))
                  : const Icon(Icons.tv, size: 36, color: Colors.grey),
            ),
            Positioned(
              bottom: 8,
              left: 8,
              right: 8,
              child: Text(
                channel.name,
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
            Positioned(
              top: 8,
              left: 8,
              child: Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Text('LIVE',
                      style: TextStyle(
                          color: Colors.red,
                          fontSize: 9,
                          fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            if (channel.isPremium)
              Positioned(
                top: 6,
                right: 6,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: const Text('PRO',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.bold)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _RadioChip extends StatelessWidget {
  final Channel channel;
  const _RadioChip({required this.channel});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: 150,
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: theme.dividerColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const SizedBox(width: 12),
          CircleAvatar(
            radius: 18,
            backgroundColor: theme.colorScheme.primaryContainer,
            child: Icon(Icons.radio, size: 18, color: theme.colorScheme.primary),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              channel.name,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
    );
  }
}

class _VodCard extends StatelessWidget {
  final VodItem item;
  final VoidCallback onTap;

  const _VodCard({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 150,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: item.thumbnailUrl != null
                        ? Image.network(item.thumbnailUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _placeholder())
                        : _placeholder(),
                  ),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      color: Colors.black.withOpacity(0.2),
                      child: const Icon(Icons.play_circle_outline,
                          color: Colors.white, size: 36),
                    ),
                  ),
                  if (item.isPremium)
                    Positioned(
                      top: 6,
                      right: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text('PRO',
                            style: TextStyle(color: Colors.white, fontSize: 9)),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            Text(item.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _placeholder() => Container(
      color: Colors.grey[800],
      child: const Icon(Icons.movie, color: Colors.grey, size: 32));
}