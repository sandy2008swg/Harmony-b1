import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../core/models/track.dart';
import '../../core/providers/providers.dart';
import '../../core/widgets/favorite_button.dart';

class SearchPage extends ConsumerStatefulWidget {
  const SearchPage({super.key});

  @override
  ConsumerState<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends ConsumerState<SearchPage> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onSearch(String value) {
    if (value.trim().isEmpty) return;
    ref.read(searchQueryProvider.notifier).state = value;
  }

  void _clearSearch() {
    _controller.clear();
    ref.read(searchQueryProvider.notifier).state = '';
  }

  @override
  Widget build(BuildContext context) {
    final searchResults = ref.watch(searchResultsProvider);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Заголовок
          const Text(
            'Пошук',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Поле пошуку
          TextField(
            controller: _controller,
            onSubmitted: _onSearch,
            style: const TextStyle(fontSize: 16),
            decoration: InputDecoration(
              hintText: 'Шукати треки, артистів...',
              prefixIcon: const Icon(Icons.search, size: 28),
              suffixIcon: _controller.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: _clearSearch,
                    )
                  : null,
              filled: true,
              fillColor: const Color(0xFF1F1F1F),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 18,
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Результати
          Expanded(
            child: searchResults.when(
              data: (tracks) {
                if (tracks.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search,
                          size: 100,
                          color: Colors.white.withValues(alpha: 0.2),
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'Введи назву пісні або артиста',
                          style: TextStyle(
                            color: Colors.white60,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Натисни Enter для пошуку',
                          style: TextStyle(
                            color: Colors.white38,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.only(bottom: 16),
                  itemCount: tracks.length,
                  itemBuilder: (context, index) {
                    return _TrackTile(track: tracks[index]);
                  },
                );
              },
              loading: () => const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text(
                      'Шукаю...',
                      style: TextStyle(color: Colors.white60),
                    ),
                  ],
                ),
              ),
              error: (error, _) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 80,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Помилка: $error',
                      style: const TextStyle(color: Colors.white60),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TrackTile extends ConsumerWidget {
  final Track track;
  const _TrackTile({required this.track});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: SizedBox(
          width: 56,
          height: 56,
          child: track.coverUrl != null
              ? CachedNetworkImage(
                  imageUrl: track.coverUrl!,
                  fit: BoxFit.cover,
                  errorWidget: (context, url, error) => Container(
                    color: Colors.grey.shade800,
                    child: const Icon(Icons.music_note, color: Colors.white54),
                  ),
                )
              : Container(
                  color: Colors.grey.shade800,
                  child: const Icon(Icons.music_note, color: Colors.white54),
                ),
        ),
      ),
      title: Text(
        track.title,
        style: const TextStyle(fontWeight: FontWeight.w600),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        track.artist,
        style: const TextStyle(color: Colors.white60),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ❤️ КНОПКА УЛЮБЛЕНЕ
          FavoriteButton(track: track, iconSize: 22),
          const SizedBox(width: 12),
          Text(
            track.durationFormatted,
            style: const TextStyle(color: Colors.white60),
          ),
          const SizedBox(width: 8),
        ],
      ),
      onTap: () async {
        final current = ref.read(currentTrackProvider);
        if (current?.id == track.id) {
          ref.read(playerControllerProvider).togglePlay();
        } else {
          final results = ref.read(searchResultsProvider).asData?.value ?? [track];
          await ref.read(playerControllerProvider).playTrack(track, queue: results);
        }
      },
    );
  }
}
