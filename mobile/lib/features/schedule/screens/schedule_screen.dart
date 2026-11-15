import 'package:flutter/material.dart';
import 'package:openair/app/theme.dart';
import 'package:openair/core/di/injection.dart';
import 'package:openair/core/playback/playback_actions.dart';
import 'package:openair/core/ui/badges.dart';
import 'package:openair/core/ui/state_views.dart';
import 'package:openair/features/schedule/models/programme_model.dart';
import 'package:openair/features/schedule/repository/schedule_repository.dart';
import 'package:openair/features/tv/models/channel_model.dart';
import 'package:openair/features/tv/repository/channel_repository.dart';

/// The programme guide: pick a channel and a day, see what is on.
class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  /// Days offered, as offsets from today: yesterday to five days ahead.
  static const _dayOffsets = [-1, 0, 1, 2, 3, 4, 5];

  List<Channel> _channels = const [];
  bool _loadingChannels = true;
  bool _channelsFailed = false;

  int _channelIndex = 0;
  int _dayOffset = 0;

  /// Loaded days, keyed by channel and day. A null value means that day
  /// failed to load.
  final Map<String, List<Programme>?> _days = {};
  final Set<String> _loadingDays = {};

  Channel? get _channel => _channels.isEmpty ? null : _channels[_channelIndex];
  String _key(Channel channel, int dayOffset) => '${channel.id}/$dayOffset';

  @override
  void initState() {
    super.initState();
    _loadChannels();
  }

  Future<void> _loadChannels() async {
    setState(() {
      _loadingChannels = true;
      _channelsFailed = false;
    });
    try {
      final repo = getIt<ChannelRepository>();
      final results = await Future.wait([repo.getTvChannels(), repo.getRadioChannels()]);
      if (!mounted) return;
      setState(() {
        _channels = [...results[0], ...results[1]];
        _channelIndex = 0;
        _loadingChannels = false;
      });
      _loadDay();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loadingChannels = false;
        _channelsFailed = true;
      });
    }
  }

  /// Loads the selected channel and day unless it is already loaded.
  Future<void> _loadDay({bool force = false}) async {
    final channel = _channel;
    if (channel == null) return;
    final key = _key(channel, _dayOffset);
    if (_loadingDays.contains(key)) return;
    if (!force && _days[key] != null) return;

    setState(() => _loadingDays.add(key));
    List<Programme>? programmes;
    try {
      programmes = await getIt<ScheduleRepository>().getByChannel(
        channel.id,
        date: DateTime.now().add(Duration(days: _dayOffset)),
      );
    } catch (_) {
      programmes = null;
    }
    if (!mounted) return;
    setState(() {
      _days[key] = programmes;
      _loadingDays.remove(key);
    });
  }

  void _selectChannel(int index) {
    setState(() => _channelIndex = index);
    _loadDay();
  }

  void _selectDay(int offset) {
    setState(() => _dayOffset = offset);
    _loadDay();
  }

  String _dayLabel(int offset) {
    if (offset == -1) return 'Yesterday';
    if (offset == 0) return 'Today';
    if (offset == 1) return 'Tomorrow';
    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final date = DateTime.now().add(Duration(days: offset));
    return '${weekdays[date.weekday - 1]} ${date.day}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Guide')),
      body: _body(context),
    );
  }

  Widget _body(BuildContext context) {
    if (_loadingChannels) return const _GuideSkeleton();
    if (_channelsFailed) return ErrorState(onRetry: _loadChannels);
    if (_channels.isEmpty) {
      return const EmptyState(
        icon: Icons.calendar_today_rounded,
        title: 'No channels yet',
        message: 'The guide will show up here once channels are added.',
      );
    }

    return Column(
      children: [
        _ChannelChips(
          channels: _channels,
          selected: _channelIndex,
          onSelected: _selectChannel,
        ),
        _DayTabs(
          offsets: _dayOffsets,
          selected: _dayOffset,
          labelFor: _dayLabel,
          onSelected: _selectDay,
        ),
        Expanded(child: _programmeList(context)),
      ],
    );
  }

  Widget _programmeList(BuildContext context) {
    final channel = _channel!;
    final key = _key(channel, _dayOffset);

    if (_loadingDays.contains(key) || !_days.containsKey(key)) {
      return const _ProgrammeSkeleton();
    }
    final programmes = _days[key];
    if (programmes == null) {
      return ErrorState(onRetry: () => _loadDay(force: true));
    }
    if (programmes.isEmpty) {
      return EmptyState(
        icon: Icons.event_busy_rounded,
        title: 'Nothing scheduled',
        message: 'No programmes are listed for ${channel.name} on this day.',
      );
    }

    final now = DateTime.now();
    return RefreshIndicator(
      onRefresh: () => _loadDay(force: true),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.screen, AppSpacing.sm, AppSpacing.screen, AppSpacing.xl),
        itemCount: programmes.length,
        itemBuilder: (context, i) {
          final programme = programmes[i];
          if (programme.isLive) {
            return _LiveProgramme(
              programme: programme,
              onTap: () => channel.type == 'radio'
                  ? PlaybackActions.toggleRadio(context, channel)
                  : PlaybackActions.watchChannel(context, channel),
            );
          }
          return _ProgrammeRow(
            programme: programme,
            isPast: programme.endsAt.isBefore(now),
          );
        },
      ),
    );
  }
}

String _time(DateTime dt) =>
    '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

class _ChannelChips extends StatelessWidget {
  final List<Channel> channels;
  final int selected;
  final ValueChanged<int> onSelected;

  const _ChannelChips({
    required this.channels,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);

    return SizedBox(
      height: 56,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screen, vertical: 6),
        separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
        itemCount: channels.length,
        itemBuilder: (context, i) {
          final isSelected = i == selected;
          return Semantics(
            button: true,
            selected: isSelected,
            child: Material(
              color: isSelected ? colors.emphasis : colors.surface,
              shape: StadiumBorder(
                side: isSelected || theme.brightness == Brightness.dark
                    ? BorderSide.none
                    : BorderSide(color: colors.border),
              ),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () => onSelected(i),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                  child: Center(
                    child: Text(
                      channels[i].name,
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                        color: isSelected ? colors.onEmphasis : colors.text,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _DayTabs extends StatelessWidget {
  final List<int> offsets;
  final int selected;
  final String Function(int offset) labelFor;
  final ValueChanged<int> onSelected;

  const _DayTabs({
    required this.offsets,
    required this.selected,
    required this.labelFor,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: colors.border)),
      ),
      child: SizedBox(
        height: 44,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
          itemCount: offsets.length,
          itemBuilder: (context, i) {
            final offset = offsets[i];
            final isSelected = offset == selected;
            return Semantics(
              button: true,
              selected: isSelected,
              child: InkWell(
                onTap: () => onSelected(offset),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        width: 2,
                        color: isSelected
                            ? colors.text
                            : colors.text.withValues(alpha: 0),
                      ),
                    ),
                  ),
                  child: Text(
                    labelFor(offset),
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected ? colors.text : colors.textMuted,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// A programme that has finished or has not started yet.
class _ProgrammeRow extends StatelessWidget {
  final Programme programme;
  final bool isPast;

  const _ProgrammeRow({required this.programme, required this.isPast});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.colors;
    final titleColor = isPast ? colors.textMuted : colors.text;
    final description = programme.description;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 56,
            child: Text(
              _time(programme.startsAt),
              style: theme.textTheme.labelMedium?.copyWith(color: titleColor),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  programme.title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: titleColor,
                    fontWeight: isPast ? FontWeight.w500 : FontWeight.w600,
                  ),
                ),
                if (!isPast && description != null && description.isNotEmpty)
                  Text(
                    description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The programme that is on right now: highlighted, with progress, and
/// tappable to start watching or listening.
class _LiveProgramme extends StatelessWidget {
  final Programme programme;
  final VoidCallback onTap;

  const _LiveProgramme({required this.programme, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.colors;
    final description = programme.description;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Material(
        color: colors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          side: theme.brightness == Brightness.dark
              ? BorderSide.none
              : BorderSide(color: colors.border),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 40,
                  child: Text(
                    _time(programme.startsAt),
                    style: theme.textTheme.labelLarge,
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              programme.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          const LiveBadge(),
                        ],
                      ),
                      if (description != null && description.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                      const SizedBox(height: AppSpacing.md),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(2),
                        child: LinearProgressIndicator(
                          value: programme.progress,
                          minHeight: 4,
                          color: colors.brand,
                          backgroundColor: colors.border,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'Until ${_time(programme.endsAt)}',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The shape of the Guide while the channels load.
class _GuideSkeleton extends StatelessWidget {
  const _GuideSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.screen, vertical: 6),
          child: Row(
            children: [
              Skeleton(width: 110, height: 44, radius: AppRadius.pill),
              SizedBox(width: AppSpacing.sm),
              Skeleton(width: 110, height: 44, radius: AppRadius.pill),
              SizedBox(width: AppSpacing.sm),
              Skeleton(width: 90, height: 44, radius: AppRadius.pill),
            ],
          ),
        ),
        SizedBox(height: 44),
        Expanded(child: _ProgrammeSkeleton()),
      ],
    );
  }
}

/// The shape of a day's programmes while they load.
class _ProgrammeSkeleton extends StatelessWidget {
  const _ProgrammeSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(AppSpacing.screen),
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.lg),
      itemCount: 7,
      itemBuilder: (_, __) => const Row(
        children: [
          Skeleton(width: 40, height: 16, radius: AppRadius.sm),
          SizedBox(width: AppSpacing.lg),
          Expanded(child: Skeleton(height: 20, radius: AppRadius.sm)),
        ],
      ),
    );
  }
}
