import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:openair/features/tv/bloc/tv_bloc.dart';
import 'package:openair/features/tv/models/channel_model.dart';
import 'package:openair/features/tv/screens/player_screen.dart';
import 'package:openair/core/di/injection.dart';
import 'package:openair/features/tv/repository/channel_repository.dart';

class TvScreen extends StatelessWidget {
  const TvScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => TvBloc(getIt<ChannelRepository>())..add(TvChannelsLoaded()),
      child: const _TvView(),
    );
  }
}

class _TvView extends StatelessWidget {
  const _TvView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Live TV')),
      body: BlocConsumer<TvBloc, TvState>(
        listener: (context, state) {
          if (state is TvStreamReady) {
            Navigator.push(context, MaterialPageRoute(
              builder: (_) => PlayerScreen(
                streamUrl: state.streamUrl,
                title: state.channelName,
              ),
            ));
          }
          if (state is TvError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: Colors.red),
            );
          }
        },
        builder: (context, state) {
          if (state is TvLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is TvChannelsSuccess) {
            if (state.channels.isEmpty) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.tv_off, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text('No channels available', style: TextStyle(color: Colors.grey)),
                  ],
                ),
              );
            }

            return GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.4,
              ),
              itemCount: state.channels.length,
              itemBuilder: (context, index) {
                return _ChannelCard(channel: state.channels[index]);
              },
            );
          }

          if (state is TvError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 12),
                  Text(state.message, textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => context.read<TvBloc>().add(TvChannelsLoaded()),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }
}

class _ChannelCard extends StatelessWidget {
  final Channel channel;
  const _ChannelCard({required this.channel});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: () => context.read<TvBloc>().add(
            TvStreamRequested(channel.id, channel.name),
          ),
      child: Container(
        decoration: BoxDecoration(
          color: theme.cardTheme.color,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: theme.dividerColor.withOpacity(0.3)),
        ),
        child: Stack(
          children: [
            Center(
              child: channel.logoUrl != null
                  ? Image.network(channel.logoUrl!, height: 48, errorBuilder: (_, __, ___) => _fallbackIcon())
                  : _fallbackIcon(),
            ),
            Positioned(
              bottom: 8,
              left: 8,
              right: 8,
              child: Text(
                channel.name,
                style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (channel.isPremium)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text('PRO', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
              ),
            Positioned(
              top: 8,
              left: 8,
              child: Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _fallbackIcon() => const Icon(Icons.tv, size: 36, color: Colors.grey);
}