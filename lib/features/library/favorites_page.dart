import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../core/providers/providers.dart';

class FavoritesPage extends ConsumerWidget {
  const FavoritesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favoritesAsync = ref.watch(favoritesProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF181818),
        title: const Text('Улюблене'),
      ),
      body: favoritesAsync.when(
        data: (favorites) {
          if (favorites.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.favorite_border,
                    size: 100,
                    color: Colors.white24,
                  ),
                  SizedBox(height: 24),
                  Text(
                    'Поки що немає улюблених треків',
                    style: TextStyle(
                      color: Colors.white60,
                      fontSize: 18,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Натисніть ❤️ біля треку в пошуку',
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
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: favorites.length,
            itemBuilder: (context, index) {
              final track = favorites[index];
              return ListTile(
                leading: SizedBox(
                  width: 50,
                  height: 50,
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
                title: Text(track.title),
                subtitle: Text(track.artist),
                trailing: const Icon(Icons.play_arrow),
                onTap: () {
                  ref.read(playerControllerProvider).playTrack(track, queue: favorites);
                },
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text('Помилка: $e', style: const TextStyle(color: Colors.red)),
        ),
      ),
    );
  }
}
