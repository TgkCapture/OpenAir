import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:openair/core/di/injection.dart';
import 'package:openair/features/tv/screens/player_screen.dart';
import 'package:openair/features/vod/bloc/vod_bloc.dart';
import 'package:openair/features/vod/models/vod_model.dart';
import 'package:openair/features/vod/repository/vod_repository.dart';

class LibraryScreen extends StatelessWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => VodBloc(getIt<VodRepository>())..add(VodLoaded()),
      child: const _LibraryView(),
    );
  }
}

class _LibraryView extends StatefulWidget {
  const _LibraryView();

  @override
  State<_LibraryView> createState() => _LibraryViewState();
}

class _LibraryViewState extends State<_LibraryView> {
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Library')),
      body: BlocConsumer<VodBloc, VodState>(
        listener: (context, state) {
          if (state is VodSuccess && state.streamUrl != null) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => PlayerScreen(
                  streamUrl: state.streamUrl!,
                  title: state.streamTitle ?? '',
                ),
              ),
            );
          }
          if (state is VodError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: Colors.red),
            );
          }
        },
        builder: (context, state) {
          if (state is VodLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is VodSuccess) {
            return Column(
              children: [
                // Search bar
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: TextField(
                    controller: _searchCtrl,
                    decoration: InputDecoration(
                      hintText: 'Search videos...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(vertical: 8),
                      suffixIcon: _searchCtrl.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchCtrl.clear();
                                context.read<VodBloc>().add(const VodSearched(''));
                              },
                            )
                          : null,
                    ),
                    onChanged: (v) => context.read<VodBloc>().add(VodSearched(v)),
                  ),
                ),

                // Category tabs
                if (state.categories.length > 1)
                  SizedBox(
                    height: 48,
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      scrollDirection: Axis.horizontal,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemCount: state.categories.length,
                      itemBuilder: (context, i) {
                        final cat = state.categories[i];
                        final selected = cat == state.selectedCategory;
                        return FilterChip(
                          label: Text(cat),
                          selected: selected,
                          onSelected: (_) => context.read<VodBloc>().add(VodCategoryChanged(cat)),
                        );
                      },
                    ),
                  ),

                // VOD grid
                Expanded(
                  child: state.items.isEmpty
                      ? const Center(
                          child: Text('No videos found', style: TextStyle(color: Colors.grey)),
                        )
                      : GridView.builder(
                          padding: const EdgeInsets.all(16),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 0.75,
                          ),
                          itemCount: state.items.length,
                          itemBuilder: (context, index) =>
                              _VodCard(item: state.items[index]),
                        ),
                ),
              ],
            );
          }

          if (state is VodError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 12),
                  Text(state.message),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => context.read<VodBloc>().add(VodLoaded()),
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

class _VodCard extends StatelessWidget {
  final VodItem item;
  const _VodCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: () => context.read<VodBloc>().add(VodStreamRequested(item.id, item.title)),
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
                      ? Image.network(item.thumbnailUrl!, fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _placeholder())
                      : _placeholder(),
                ),
                if (item.isPremium)
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text('PRO',
                          style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                  ),
                if (item.formattedDuration.isNotEmpty)
                  Positioned(
                    bottom: 6,
                    right: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(item.formattedDuration,
                          style: const TextStyle(color: Colors.white, fontSize: 11)),
                    ),
                  ),
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.black.withOpacity(0.15),
                    ),
                    child: const Icon(Icons.play_circle_outline,
                        color: Colors.white, size: 40),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Text(item.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600)),
          if (item.category != null)
            Text(item.category!,
                style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _placeholder() => Container(
        color: Colors.grey[800],
        child: const Icon(Icons.movie, color: Colors.grey, size: 40),
      );
}