import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:openair/core/audio/audio_controller.dart';
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
      if (!mounted) return;
      setState(() {
        _tvChannels = (results[0].data['data'] as List? ?? [])
            .map((e) => Channel.fromJson(e)).toList();
        _radioChannels = (results[1].data['data'] as List? ?? [])
            .map((e) => Channel.fromJson(e)).toList();
        _featuredVod = (results[2].data['data'] as List? ?? [])
            .map((e) => VodItem.fromJson(e)).toList();
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = 'Could not load content'; _loading = false; });
    }
  }

  Future<void> _playTvChannel(Channel channel) async {
    try {
      final api = getIt<ApiService>();
      final res = await api.dio.get('/channels/${channel.id}/stream');
      final url = res.data['data']['url'] as String;
      if (!mounted) return;
      Navigator.push(context, MaterialPageRoute(
        builder: (_) => PlayerScreen(streamUrl: url, title: channel.name),
      ));
    } on DioException catch (e) {
      if (!mounted) return;
      final msg = e.response?.data?['error']?['message'] ?? 'Could not load stream';
      _showError(msg);
    }
  }

  Future<void> _playRadio(Channel channel) async {
    try {
      final audio = getIt<AudioController>();
      final id = AudioController.radioId(channel.id);
      // Tapping the channel that is already playing stops it.
      if (audio.state?.id == id) {
        await audio.stop();
        return;
      }
      final api = getIt<ApiService>();
      final res = await api.dio.get('/channels/${channel.id}/stream');
      final url = res.data['data']['url'] as String;
      await audio.play(
        id: id,
        url: url,
        title: channel.name,
        subtitle: 'Live radio',
        artUrl: channel.logoUrl,
        isLive: true,
      );
    } on DioException catch (e) {
      if (!mounted) return;
      final msg = e.response?.data?['error']?['message'] ?? 'Could not load stream';
      _showError(msg);
    }
  }

  Future<void> _playVod(VodItem item) async {
    try {
      final api = getIt<ApiService>();
      final res = await api.dio.get('/vod/${item.id}/stream');
      final url = res.data['data']['url'] as String;
      if (!mounted) return;
      Navigator.push(context, MaterialPageRoute(
        builder: (_) => PlayerScreen(streamUrl: url, title: item.title),
      ));
    } on DioException catch (e) {
      if (!mounted) return;
      final msg = e.response?.data?['error']?['message'] ?? 'Could not load video';
      _showError(msg);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    // Rebuild when the shared player changes, to mark the playing channel.
    final playingId = context.watch<AudioController>().state?.id;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // ── App bar
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 16, 8),
              child: Row(
                children: [
                  Container(
                    width: 32, height: 32,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.radio, color: Colors.white, size: 18),
                  ),
                  const SizedBox(width: 10),
                  Text('OpenAir',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    )),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.search_rounded),
                    onPressed: () {},
                    style: IconButton.styleFrom(
                      backgroundColor: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.05),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ],
              ),
            ),

            // ── Body
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
                  : _error != null
                      ? _ErrorView(message: _error!, onRetry: _loadData)
                      : RefreshIndicator(
                          onRefresh: _loadData,
                          child: ListView(
                            padding: const EdgeInsets.only(bottom: 24),
                            children: [
                              if (_tvChannels.isNotEmpty) ...[
                                const _SectionHeader(title: 'Live TV', icon: Icons.tv_rounded),
                                SizedBox(
                                  height: 120,
                                  child: ListView.separated(
                                    padding: const EdgeInsets.symmetric(horizontal: 20),
                                    scrollDirection: Axis.horizontal,
                                    separatorBuilder: (_, __) => const SizedBox(width: 10),
                                    itemCount: _tvChannels.length,
                                    itemBuilder: (_, i) => _TvChannelCard(
                                      channel: _tvChannels[i],
                                      onTap: () => _playTvChannel(_tvChannels[i]),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 24),
                              ],
                              if (_radioChannels.isNotEmpty) ...[
                                const _SectionHeader(title: 'Live Radio', icon: Icons.radio_rounded),
                                SizedBox(
                                  height: 72,
                                  child: ListView.separated(
                                    padding: const EdgeInsets.symmetric(horizontal: 20),
                                    scrollDirection: Axis.horizontal,
                                    separatorBuilder: (_, __) => const SizedBox(width: 10),
                                    itemCount: _radioChannels.length,
                                    itemBuilder: (_, i) => _RadioChip(
                                      channel: _radioChannels[i],
                                      isPlaying: playingId == AudioController.radioId(_radioChannels[i].id),
                                      onTap: () => _playRadio(_radioChannels[i]),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 24),
                              ],
                              if (_featuredVod.isNotEmpty) ...[
                                const _SectionHeader(title: 'Featured Videos', icon: Icons.video_library_rounded),
                                SizedBox(
                                  height: 200,
                                  child: ListView.separated(
                                    padding: const EdgeInsets.symmetric(horizontal: 20),
                                    scrollDirection: Axis.horizontal,
                                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                                    itemCount: _featuredVod.length,
                                    itemBuilder: (_, i) => _VodCard(
                                      item: _featuredVod[i],
                                      onTap: () => _playVod(_featuredVod[i]),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 24),
                              ],
                              if (_tvChannels.isEmpty && _radioChannels.isEmpty && _featuredVod.isEmpty)
                                _EmptyHome(),
                            ],
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Section header
class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  const _SectionHeader({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(7),
            ),
            child: Icon(icon, size: 14, color: theme.colorScheme.primary),
          ),
          const SizedBox(width: 8),
          Text(title, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
          const Spacer(),
          Text('See all', style: TextStyle(fontSize: 12, color: theme.colorScheme.primary, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

// ── TV channel card
class _TvChannelCard extends StatelessWidget {
  final Channel channel;
  final VoidCallback onTap;
  const _TvChannelCard({required this.channel, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 130,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.06),
              blurRadius: 8, offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Logo or icon
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Center(
                  child: channel.logoUrl != null
                      ? Image.network(channel.logoUrl!, height: 42, fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => Icon(Icons.tv_rounded, size: 32, color: theme.colorScheme.onSurface.withValues(alpha: 0.3)))
                      : Icon(Icons.tv_rounded, size: 32, color: theme.colorScheme.onSurface.withValues(alpha: 0.3)),
                ),
              ),
            ),
            // Bottom gradient + name
            Positioned(
              bottom: 0, left: 0, right: 0,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black.withValues(alpha: 0.7)],
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(8, 16, 8, 8),
                child: Text(channel.name,
                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
            ),
            // Live badge
            Positioned(
              top: 8, left: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(width: 4, height: 4, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle)),
                    const SizedBox(width: 3),
                    const Text('LIVE', style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
                  ],
                ),
              ),
            ),
            // PRO badge
            if (channel.isPremium)
              Positioned(
                top: 8, right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  decoration: BoxDecoration(color: theme.colorScheme.primary, borderRadius: BorderRadius.circular(4)),
                  child: const Text('PRO', style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w800)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Radio chip — now fully clickable
class _RadioChip extends StatelessWidget {
  final Channel channel;
  final bool isPlaying;
  final VoidCallback onTap;
  const _RadioChip({required this.channel, required this.isPlaying, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 72,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: isPlaying
              ? theme.colorScheme.primary
              : (isDark ? const Color(0xFF1A1A1A) : Colors.white),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: isPlaying
                  ? theme.colorScheme.primary.withValues(alpha: 0.4)
                  : Colors.black.withValues(alpha: isDark ? 0.3 : 0.06),
              blurRadius: isPlaying ? 12 : 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Icon(
                isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                key: ValueKey(isPlaying),
                color: isPlaying ? Colors.white : theme.colorScheme.primary,
                size: 22,
              ),
            ),
            const SizedBox(width: 10),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 120),
              child: Text(channel.name,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isPlaying ? Colors.white : theme.colorScheme.onSurface,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── VOD card
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
        width: 160,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: item.thumbnailUrl != null
                        ? Image.network(item.thumbnailUrl!, fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _placeholder())
                        : _placeholder(),
                  ),
                  // Play overlay
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: onTap,
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [Colors.transparent, Colors.black.withValues(alpha: 0.5)],
                              ),
                            ),
                            child: const Center(
                              child: Icon(Icons.play_circle_filled_rounded, color: Colors.white, size: 40),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Duration
                  if (item.formattedDuration.isNotEmpty)
                    Positioned(
                      bottom: 8, right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                        decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.75), borderRadius: BorderRadius.circular(4)),
                        child: Text(item.formattedDuration, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600)),
                      ),
                    ),
                  // PRO badge
                  if (item.isPremium)
                    Positioned(
                      top: 8, right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                        decoration: BoxDecoration(color: theme.colorScheme.primary, borderRadius: BorderRadius.circular(4)),
                        child: const Text('PRO', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w800)),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(item.title,
              maxLines: 2, overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600, height: 1.3)),
            if (item.category != null)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(item.category!, style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurface.withValues(alpha: 0.45))),
              ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder() => Container(
    decoration: BoxDecoration(color: Colors.grey[850], borderRadius: BorderRadius.circular(12)),
    child: const Icon(Icons.movie_rounded, color: Colors.grey, size: 36),
  );
}

// ── Now playing bar
class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.wifi_off_rounded, size: 56, color: Colors.grey),
            const SizedBox(height: 16),
            Text(message, textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 20),
            FilledButton.icon(onPressed: onRetry, icon: const Icon(Icons.refresh_rounded, size: 16), label: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}

// ── Empty home
class _EmptyHome extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(48),
      child: Column(
        children: [
          Icon(Icons.live_tv_rounded, size: 72, color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3)),
          const SizedBox(height: 16),
          const Text('No content yet', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('Add channels and videos in the admin dashboard.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}