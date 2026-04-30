import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:openair/core/di/injection.dart';
import 'package:openair/features/radio/bloc/radio_bloc.dart';
import 'package:openair/features/tv/models/channel_model.dart';
import 'package:openair/features/tv/repository/channel_repository.dart';

class RadioScreen extends StatelessWidget {
  const RadioScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => RadioBloc(getIt<ChannelRepository>())..add(RadioChannelsLoaded()),
      child: const _RadioView(),
    );
  }
}

class _RadioView extends StatelessWidget {
  const _RadioView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Live Radio')),
      body: BlocBuilder<RadioBloc, RadioState>(
        builder: (context, state) {
          if (state is RadioLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is RadioChannelsSuccess) {
            return Column(
              children: [
                if (state.nowPlaying != null)
                  _NowPlayingBar(
                    channel: state.nowPlaying!,
                    onStop: () => context.read<RadioBloc>().add(RadioStopped()),
                  ),
                Expanded(
                  child: state.channels.isEmpty
                      ? const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.radio, size: 64, color: Colors.grey),
                              SizedBox(height: 16),
                              Text('No radio channels available',
                                  style: TextStyle(color: Colors.grey)),
                            ],
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.all(16),
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemCount: state.channels.length,
                          itemBuilder: (context, index) {
                            final channel = state.channels[index];
                            final isPlaying = state.nowPlaying?.id == channel.id;
                            return _RadioTile(
                              channel: channel,
                              isPlaying: isPlaying,
                              onTap: () => context
                                  .read<RadioBloc>()
                                  .add(RadioPlayRequested(channel)),
                            );
                          },
                        ),
                ),
              ],
            );
          }

          if (state is RadioError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 12),
                  Text(state.message, textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () =>
                        context.read<RadioBloc>().add(RadioChannelsLoaded()),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }
}

class _RadioTile extends StatelessWidget {
  final Channel channel;
  final bool isPlaying;
  final VoidCallback onTap;

  const _RadioTile({
    required this.channel,
    required this.isPlaying,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: isPlaying
            ? theme.colorScheme.primary
            : theme.colorScheme.primaryContainer,
        child: Icon(
          isPlaying ? Icons.graphic_eq : Icons.radio,
          color: isPlaying ? Colors.white : theme.colorScheme.primary,
        ),
      ),
      title: Text(
        channel.name,
        style: TextStyle(
          fontWeight: isPlaying ? FontWeight.bold : FontWeight.normal,
          color: isPlaying ? theme.colorScheme.primary : null,
        ),
      ),
      subtitle: Text(
        channel.isPremium ? 'Premium' : 'Free',
        style: TextStyle(
          color: channel.isPremium ? theme.colorScheme.primary : Colors.grey,
          fontSize: 12,
        ),
      ),
      trailing: isPlaying
          ? Icon(Icons.pause_circle_filled,
              color: theme.colorScheme.primary, size: 32)
          : const Icon(Icons.play_circle_outline, size: 32),
      onTap: onTap,
    );
  }
}

class _NowPlayingBar extends StatelessWidget {
  final Channel channel;
  final VoidCallback onStop;

  const _NowPlayingBar({required this.channel, required this.onStop});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      color: theme.colorScheme.primary.withValues(alpha:0.1),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          const Icon(Icons.graphic_eq, color: Colors.red),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'NOW PLAYING',
                  style: TextStyle(
                    fontSize: 10,
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(channel.name,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.stop_circle_outlined),
            onPressed: onStop,
            color: Colors.red,
          ),
        ],
      ),
    );
  }
}