import 'package:flutter/foundation.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../models/track.dart';
import '../models/playlist.dart';
import 'dart:io';

class DatabaseService {
  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    // Для Windows/Linux потрібен sqflite_common_ffi
    if (Platform.isWindows || Platform.isLinux) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    final dir = await getApplicationDocumentsDirectory();
    final path = p.join(dir.path, 'harmony.db');
    
    debugPrint('📂 База даних: $path');
    
    return openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        debugPrint('🔨 Створюю таблиці...');
        await _createTables(db, version);
        debugPrint('✅ Таблиці створено');
      },
    );
  }

  Future<void> _createTables(Database db, int version) async {
    // Улюблені треки
    await db.execute('''
      CREATE TABLE favorites (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        artist TEXT NOT NULL,
        album TEXT,
        cover_url TEXT,
        duration_ms INTEGER,
        source TEXT NOT NULL,
        added_at TEXT NOT NULL
      )
    ''');

    // Плейлисти
    await db.execute('''
      CREATE TABLE playlists (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        description TEXT,
        cover_url TEXT,
        created_at TEXT NOT NULL
      )
    ''');

    // Треки в плейлистах (зв'язок many-to-many)
    await db.execute('''
      CREATE TABLE playlist_tracks (
        playlist_id TEXT NOT NULL,
        track_id TEXT NOT NULL,
        track_title TEXT NOT NULL,
        track_artist TEXT NOT NULL,
        track_cover_url TEXT,
        track_duration_ms INTEGER,
        track_source TEXT NOT NULL,
        position INTEGER NOT NULL,
        PRIMARY KEY (playlist_id, track_id),
        FOREIGN KEY (playlist_id) REFERENCES playlists(id) ON DELETE CASCADE
      )
    ''');
  }

  // ===== УЛЮБЛЕНЕ =====

  Future<void> addToFavorites(Track track) async {
    debugPrint('❤️ Додаю в улюблене: ${track.title}');
    final db = await database;
    await db.insert(
      'favorites',
      {
        'id': track.id,
        'title': track.title,
        'artist': track.artist,
        'album': track.album,
        'cover_url': track.coverUrl,
        'duration_ms': track.durationMs,
        'source': track.source.name,
        'added_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    debugPrint('✅ Додано в улюблене!');
  }

  Future<void> removeFromFavorites(String trackId) async {
    debugPrint('💔 Видаляю з улюбленого: $trackId');
    final db = await database;
    await db.delete('favorites', where: 'id = ?', whereArgs: [trackId]);
    debugPrint('✅ Видалено!');
  }

  Future<List<Track>> getFavorites() async {
    debugPrint('📖 Читаю улюблені...');
    final db = await database;
    final maps = await db.query('favorites', orderBy: 'added_at DESC');
    debugPrint('📖 Знайдено: ${maps.length} треків');
    return maps.map((map) => Track(
      id: map['id'] as String,
      title: map['title'] as String,
      artist: map['artist'] as String,
      album: map['album'] as String?,
      coverUrl: map['cover_url'] as String?,
      durationMs: map['duration_ms'] as int?,
      source: SourceType.values.firstWhere(
        (e) => e.name == map['source'],
        orElse: () => SourceType.youtube,
      ),
    )).toList();
  }

  Future<bool> isFavorite(String trackId) async {
    final db = await database;
    final result = await db.query(
      'favorites',
      where: 'id = ?',
      whereArgs: [trackId],
      limit: 1,
    );
    return result.isNotEmpty;
  }

  // ===== ПЛЕЙЛИСТИ =====

  Future<Playlist> createPlaylist(String name, {String? description}) async {
    debugPrint('📋 Створюю плейлист: $name');
    final db = await database;
    final playlist = Playlist(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      description: description,
      createdAt: DateTime.now(),
    );
    
    await db.insert('playlists', {
      'id': playlist.id,
      'name': playlist.name,
      'description': playlist.description,
      'cover_url': playlist.coverUrl,
      'created_at': playlist.createdAt!.toIso8601String(),
    });
    
    debugPrint('✅ Плейлист створено!');
    return playlist;
  }

  Future<List<Playlist>> getPlaylists() async {
    debugPrint('📖 Читаю плейлисти...');
    final db = await database;
    final maps = await db.query('playlists', orderBy: 'created_at DESC');
    
    final playlists = <Playlist>[];
    for (final map in maps) {
      final id = map['id'] as String;
      final count = Sqflite.firstIntValue(
        await db.rawQuery(
          'SELECT COUNT(*) FROM playlist_tracks WHERE playlist_id = ?',
          [id],
        ),
      ) ?? 0;
      
      playlists.add(Playlist(
        id: id,
        name: map['name'] as String,
        description: map['description'] as String?,
        coverUrl: map['cover_url'] as String?,
        createdAt: DateTime.parse(map['created_at'] as String),
        trackCount: count,
      ));
    }
    
    debugPrint('📖 Знайдено: ${playlists.length} плейлистів');
    return playlists;
  }

  Future<void> deletePlaylist(String playlistId) async {
    debugPrint('🗑️ Видаляю плейлист: $playlistId');
    final db = await database;
    await db.delete('playlists', where: 'id = ?', whereArgs: [playlistId]);
    await db.delete(
      'playlist_tracks',
      where: 'playlist_id = ?',
      whereArgs: [playlistId],
    );
    debugPrint('✅ Видалено!');
  }

  Future<void> addTrackToPlaylist(String playlistId, Track track) async {
    debugPrint('➕ Додаю "${track.title}" в плейлист $playlistId');
    final db = await database;
    
    // Отримуємо поточну позицію
    final count = Sqflite.firstIntValue(
      await db.rawQuery(
        'SELECT COUNT(*) FROM playlist_tracks WHERE playlist_id = ?',
        [playlistId],
      ),
    ) ?? 0;
    
    await db.insert(
      'playlist_tracks',
      {
        'playlist_id': playlistId,
        'track_id': track.id,
        'track_title': track.title,
        'track_artist': track.artist,
        'track_cover_url': track.coverUrl,
        'track_duration_ms': track.durationMs,
        'track_source': track.source.name,
        'position': count,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    debugPrint('✅ Додано!');
  }

  Future<void> removeTrackFromPlaylist(String playlistId, String trackId) async {
    debugPrint('➖ Видаляю трек $trackId з плейлиста $playlistId');
    final db = await database;
    await db.delete(
      'playlist_tracks',
      where: 'playlist_id = ? AND track_id = ?',
      whereArgs: [playlistId, trackId],
    );
    debugPrint('✅ Видалено!');
  }

  Future<List<Track>> getPlaylistTracks(String playlistId) async {
    debugPrint('📖 Читаю треки плейлиста $playlistId...');
    final db = await database;
    final maps = await db.query(
      'playlist_tracks',
      where: 'playlist_id = ?',
      whereArgs: [playlistId],
      orderBy: 'position ASC',
    );
    
    final tracks = maps.map((map) => Track(
      id: map['track_id'] as String,
      title: map['track_title'] as String,
      artist: map['track_artist'] as String,
      coverUrl: map['track_cover_url'] as String?,
      durationMs: map['track_duration_ms'] as int?,
      source: SourceType.values.firstWhere(
        (e) => e.name == map['track_source'],
        orElse: () => SourceType.youtube,
      ),
    )).toList();
    
    debugPrint('📖 Знайдено: ${tracks.length} треків');
    return tracks;
  }
}
