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
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Channel> _channels = [];
  final Map<String, List<Programme>> _programmes = {};
  bool _loading = true;
  int _selectedDay = 0;

  final List<String> _days = _buildDays();

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
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadChannels() async {
    try {
      final channels = await getIt<ChannelRepository>().getTvChannels();
      _tabController = TabController(length: channels.length, vsync: this);
      _tabController.addListener(() {
        if (!_tabController.indexIsChanging) {
          _loadProgrammes(channels[_tabController.index].id);
        }
      });
      setState(() {
        _channels = channels;
        _loading = false;
      });
      if (channels.isNotEmpty) {
        _loadProgrammes(channels[0].id);
      }
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  Future<void> _loadProgrammes(String channelId) async {
    final key = '$channelId-$_selectedDay';
    if (_programmes.containsKey(key)) return;
    try {
      final progs = await getIt<ScheduleRepository>()
          .getByChannel(channelId, date: _selectedDate);
      setState(() => _programmes[key] = progs);
    } catch (_) {
      setState(() => _programmes[key] = []);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_channels.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Schedule')),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.calendar_today, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text('No channels available', style: TextStyle(color: Colors.grey)),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Schedule'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: _channels.map((c) => Tab(text: c.name)).toList(),
          onTap: (i) => _loadProgrammes(_channels[i].id),
        ),
      ),
      body: Column(
        children: [
          // Day selector
          SizedBox(
            height: 48,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              scrollDirection: Axis.horizontal,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemCount: _days.length,
              itemBuilder: (context, i) {
                final selected = i == _selectedDay;
                return GestureDetector(
                  onTap: () {
                    setState(() => _selectedDay = i);
                    final channelId = _channels[_tabController.index].id;
                    _loadProgrammes(channelId);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
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
                        color: selected ? Colors.white : null,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          const Divider(height: 1),

          // Programme list
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: _channels.map((channel) {
                final key = '${channel.id}-$_selectedDay';
                final progs = _programmes[key];

                if (progs == null) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (progs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.event_busy,
                            size: 48,
                            color: theme.colorScheme.onSurface.withOpacity(0.3)),
                        const SizedBox(height: 12),
                        const Text('No programmes scheduled',
                            style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  );
                }

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
            ? theme.colorScheme.primary.withOpacity(0.08)
            : theme.cardTheme.color,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isLive
              ? theme.colorScheme.primary.withOpacity(0.3)
              : theme.dividerColor.withOpacity(0.3),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Time column
            SizedBox(
              width: 88,
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
                            theme.colorScheme.primary.withOpacity(0.2),
                        valueColor: AlwaysStoppedAnimation<Color>(
                            theme.colorScheme.primary),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 12),
            // Content column
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (isLive) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text('LIVE',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(width: 6),
                      ],
                      Expanded(
                        child: Text(
                          programme.title,
                          style: TextStyle(
                            fontWeight: isLive
                                ? FontWeight.bold
                                : FontWeight.w500,
                            fontSize: 14,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  if (programme.description != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      programme.description!,
                      style: const TextStyle(
                          fontSize: 12, color: Colors.grey),
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