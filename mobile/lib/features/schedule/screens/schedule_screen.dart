import 'package:flutter/material.dart';
import 'package:openair/core/di/injection.dart';
import 'package:openair/features/schedule/models/programme_model.dart';
import 'package:openair/features/schedule/repository/schedule_repository.dart';
import 'package:openair/features/tv/models/channel_model.dart';
import 'package:openair/features/tv/repository/channel_repository.dart';

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen>
    with TickerProviderStateMixin {
  TabController? _tabController;
  List<Channel> _channels = [];
  final Map<String, List<Programme>> _programmes = {};
  bool _loading = true;
  String? _error;
  int _selectedDay = 1; // 0=Yesterday, 1=Today, 2=Tomorrow...

  late final List<String> _days = _buildDays();

  static List<String> _buildDays() {
    final now = DateTime.now();
    final days = <String>[];
    for (int i = -1; i <= 5; i++) {
      final d = now.add(Duration(days: i));
      if (i == -1) {
        days.add('Yesterday');
      } else if (i == 0) {
        days.add('Today');
      } else if (i == 1) {
        days.add('Tomorrow');
      } else {
        const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
        days.add('${weekdays[d.weekday - 1]} ${d.day}');
      }
    }
    return days;
  }

  // _selectedDay=1 means today (offset 0 from now), _selectedDay=0 is yesterday (-1)
  DateTime get _selectedDate {
    final now = DateTime.now();
    return now.add(Duration(days: _selectedDay - 1));
  }

  @override
  void initState() {
    super.initState();
    _loadChannels();
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  Future<void> _loadChannels() async {
    setState(() { _loading = true; _error = null; });
    try {
      final channels = await getIt<ChannelRepository>().getTvChannels();
      if (!mounted) return;

      // Dispose old controller before creating new one
      _tabController?.dispose();

      if (channels.isNotEmpty) {
        _tabController = TabController(length: channels.length, vsync: this);
        _tabController!.addListener(() {
          if (!_tabController!.indexIsChanging) {
            _loadProgrammes(channels[_tabController!.index].id);
          }
        });
      }

      setState(() {
        _channels = channels;
        _loading = false;
      });

      if (channels.isNotEmpty) {
        _loadProgrammes(channels[0].id);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Could not load channels';
      });
    }
  }

  Future<void> _loadProgrammes(String channelId) async {
    final key = '$channelId-$_selectedDay';
    if (_programmes.containsKey(key)) return;
    try {
      final progs = await getIt<ScheduleRepository>()
          .getByChannel(channelId, date: _selectedDate);
      if (!mounted) return;
      setState(() => _programmes[key] = progs);
    } catch (_) {
      if (!mounted) return;
      setState(() => _programmes[key] = []);
    }
  }

  void _onDaySelected(int index) {
    setState(() => _selectedDay = index);
    // Reload programmes for currently visible channel
    final currentIndex = _tabController?.index ?? 0;
    if (_channels.isNotEmpty) {
      // Clear cached entries for new day so they reload
      final channelId = _channels[currentIndex].id;
      final key = '$channelId-$index';
      if (!_programmes.containsKey(key)) {
        _loadProgrammes(channelId);
      } else {
        setState(() {}); // trigger rebuild to show cached data
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Loading state
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Schedule')),
        body: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }

    // Error state
    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Schedule')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.grey),
              const SizedBox(height: 12),
              Text(_error!, style: const TextStyle(color: Colors.grey)),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _loadChannels,
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    // Empty channels state
    if (_channels.isEmpty || _tabController == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Schedule')),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.calendar_today, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text('No TV channels available',
                  style: TextStyle(color: Colors.grey)),
            ],
          ),
        ),
      );
    }

    // Main view — _tabController is guaranteed non-null here
    final ctrl = _tabController!;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Schedule'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: TabBar(
            controller: ctrl,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: _channels.map((c) => Tab(text: c.name)).toList(),
            onTap: (i) {
              final key = '${_channels[i].id}-$_selectedDay';
              if (!_programmes.containsKey(key)) {
                _loadProgrammes(_channels[i].id);
              }
            },
          ),
        ),
      ),
      body: Column(
        children: [
          // ── Day selector
          SizedBox(
            height: 52,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              scrollDirection: Axis.horizontal,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemCount: _days.length,
              itemBuilder: (context, i) {
                final selected = i == _selectedDay;
                return GestureDetector(
                  onTap: () => _onDaySelected(i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    curve: Curves.easeOut,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                    decoration: BoxDecoration(
                      color: selected
                          ? theme.colorScheme.primary
                          : theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: selected
                            ? theme.colorScheme.primary
                            : theme.dividerColor,
                      ),
                    ),
                    child: Text(
                      _days[i],
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: selected
                            ? Colors.white
                            : theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          const Divider(height: 1),

          // ── Programme list per channel tab
          Expanded(
            child: TabBarView(
              controller: ctrl,
              children: _channels.map((channel) {
                final key = '${channel.id}-$_selectedDay';
                final progs = _programmes[key];

                // Still loading for this channel/day
                if (progs == null) {
                  return const Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  );
                }

                // No programmes
                if (progs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.event_busy,
                          size: 48,
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.25),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'No programmes scheduled',
                          style: TextStyle(color: Colors.grey),
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: () {
                            // Force reload by clearing cache
                            setState(() => _programmes.remove(key));
                            _loadProgrammes(channel.id);
                          },
                          child: const Text('Refresh'),
                        ),
                      ],
                    ),
                  );
                }

                // Programme list
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: progs.length,
                  itemBuilder: (context, i) =>
                      _ProgrammeTile(programme: progs[i]),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Programme tile
class _ProgrammeTile extends StatelessWidget {
  final Programme programme;
  const _ProgrammeTile({required this.programme});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLive = programme.isLive;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: isLive
            ? theme.colorScheme.primary.withValues(alpha: 0.08)
            : theme.cardTheme.color,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isLive
              ? theme.colorScheme.primary.withValues(alpha: 0.3)
              : theme.dividerColor.withValues(alpha: 0.3),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Time + progress
            SizedBox(
              width: 90,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    programme.timeRange,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isLive ? theme.colorScheme.primary : Colors.grey,
                    ),
                  ),
                  if (isLive) ...[
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: LinearProgressIndicator(
                        value: programme.progress,
                        minHeight: 3,
                        backgroundColor:
                            theme.colorScheme.primary.withValues(alpha: 0.2),
                        valueColor: AlwaysStoppedAnimation<Color>(
                            theme.colorScheme.primary),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 12),
            // ── Title + description
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (isLive) ...[
                        Container(
                          margin: const EdgeInsets.only(right: 6, top: 1),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 5, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text('LIVE',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.5)),
                        ),
                      ],
                      Expanded(
                        child: Text(
                          programme.title,
                          style: TextStyle(
                            fontWeight:
                                isLive ? FontWeight.w700 : FontWeight.w500,
                            fontSize: 14,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  if (programme.description != null &&
                      programme.description!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      programme.description!,
                      style: TextStyle(
                          fontSize: 12,
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.5)),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}