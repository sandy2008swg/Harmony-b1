import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/track.dart';
import '../models/playlist.dart';
import '../services/youtube_service.dart';
import '../services/database_service.dart';
export 'player_provider.dart';

/// YouTube сервіс
final youtubeServiceProvider = Provider<YouTubeService>((ref) {
  final service = YouTubeService();
  ref.onDispose(() => service.dispose());
  return service;
});

/// База даних
final databaseServiceProvider = Provider<DatabaseService>((ref) {
  return DatabaseService();
});

/// Пошуковий запит
final searchQueryProvider = StateProvider<String>((ref) => '');

/// Результати пошуку
final searchResultsProvider = FutureProvider<List<Track>>((ref) async {
  final query = ref.watch(searchQueryProvider);
  if (query.isEmpty) return [];

  final service = ref.read(youtubeServiceProvider);
  return service.search(query);
});

/// Поточний трек
final currentTrackProvider = StateProvider<Track?>((ref) => null);

/// Чи грає
final isPlayingProvider = StateProvider<bool>((ref) => false);

/// Улюблені треки
final favoritesProvider = FutureProvider<List<Track>>((ref) async {
  final db = ref.read(databaseServiceProvider);
  return db.getFavorites();
});

/// Плейлисти
final playlistsProvider = FutureProvider<List<Playlist>>((ref) async {
  final db = ref.read(databaseServiceProvider);
  return db.getPlaylists();
});
