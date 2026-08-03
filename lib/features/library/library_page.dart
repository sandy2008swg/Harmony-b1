import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/playlist.dart';
import '../../core/providers/providers.dart';
import 'favorites_page.dart';
import 'playlist_detail_page.dart';

class LibraryPage extends ConsumerWidget {
  const LibraryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playlistsAsync = ref.watch(playlistsProvider);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Заголовок
          Row(
            children: [
              const Text(
                'Бібліотека',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: () => _showCreatePlaylistDialog(context, ref),
                icon: const Icon(Icons.add),
                label: const Text('Створити плейлист'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1DB954),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // 🆕 КАРТКА "УЛЮБЛЕНЕ" - ЗАВЖДИ ПЕРША
          _FavoritesCard(),
          
          const SizedBox(height: 24),
          
          // Плейлисти
          const Text(
            'Плейлисти',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          
          const SizedBox(height: 16),
          
          Expanded(
            child: playlistsAsync.when(
              data: (playlists) {
                if (playlists.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.queue_music,
                          size: 80,
                          color: Colors.white24,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Поки що немає плейлистів',
                          style: TextStyle(
                            color: Colors.white60,
                            fontSize: 16,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Натисніть "Створити плейлист"',
                          style: TextStyle(
                            color: Colors.white38,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  );
                }
                
                return GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 20,
                    mainAxisSpacing: 20,
                    childAspectRatio: 1.3,
                  ),
                  itemCount: playlists.length,
                  itemBuilder: (context, index) {
                    final playlist = playlists[index];
                    return _PlaylistCard(playlist: playlist);
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Помилка: $e')),
            ),
          ),
        ],
      ),
    );
  }

  void _showCreatePlaylistDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF282828),
        title: const Text('Новий плейлист'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Назва плейлиста',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Скасувати'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.isNotEmpty) {
                final db = ref.read(databaseServiceProvider);
                await db.createPlaylist(controller.text);
                ref.invalidate(playlistsProvider);
                if (context.mounted) Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1DB954),
            ),
            child: const Text('Створити'),
          ),
        ],
      ),
    );
  }
}

// 🆕 ОКРЕМА КАРТКА ДЛЯ УЛЮБЛЕНОГО
class _FavoritesCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favoritesAsync = ref.watch(favoritesProvider);
    
    return Card(
      color: const Color(0xFF282828),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: Colors.red.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            Icons.favorite,
            color: Colors.red,
            size: 28,
          ),
        ),
        title: const Text(
          'Улюблене',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: favoritesAsync.when(
          data: (favs) => Text('${favs.length} треків'),
          loading: () => const Text('Завантаження...'),
          error: (e, _) => const Text('Помилка'),
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          debugPrint('💚 Відкриваю Улюблене...');
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const FavoritesPage()),
          );
        },
      ),
    );
  }
}

class _PlaylistCard extends ConsumerWidget {
  final Playlist playlist;
  const _PlaylistCard({required this.playlist});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      color: const Color(0xFF282828),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => PlaylistDetailPage(playlist: playlist),
            ),
          );
        },
        onLongPress: () => _showDeleteDialog(context, ref),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.green.shade700,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.queue_music,
                  size: 50,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                playlist.name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                '${playlist.trackCount} треків',
                style: const TextStyle(
                  color: Colors.white60,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF282828),
        title: Text('Видалити "${playlist.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Скасувати'),
          ),
          TextButton(
            onPressed: () async {
              final db = ref.read(databaseServiceProvider);
              await db.deletePlaylist(playlist.id);
              ref.invalidate(playlistsProvider);
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Видалити', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
