import 'package:flutter/foundation.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../models/track.dart';

class YouTubeService {
  final YoutubeExplode _yt = YoutubeExplode();

  Future<List<Track>> search(String query) async {
    try {
      debugPrint('🔍 Шукаю: $query');
      final searchList = await _yt.search.search(query);

      return searchList.take(20).map((video) {
        return Track(
          id: video.id.value,
          title: video.title,
          artist: video.author,
          coverUrl: video.thumbnails.highResUrl,
          durationMs: video.duration?.inMilliseconds,
          source: SourceType.youtube,
        );
      }).toList();
    } catch (e) {
      debugPrint('❌ Помилка пошуку: $e');
      return [];
    }
  }

  /// Завантажує аудіо в тимчасовий файл через yt-dlp
  Future<String?> getStreamUrl(String videoId) async {
    try {
      debugPrint('⬇️ Завантажую аудіо через yt-dlp для: $videoId');
      
      final tempDir = await getTemporaryDirectory();
      final filePath = '${tempDir.path}/$videoId.m4a';
      
      // Перевіряємо чи файл вже є
      final file = File(filePath);
      if (await file.exists() && await file.length() > 1000) {
        debugPrint('✅ Файл вже завантажений: ${await file.length()} bytes');
        return filePath;
      }
      
      // Завантажуємо
      final result = await Process.run(
        'yt-dlp',
        [
          '-f', 'bestaudio[ext=m4a]/bestaudio[ext=webm]/bestaudio',
          '-o', filePath,
          '--no-warnings',
          '--no-playlist',
          'https://www.youtube.com/watch?v=$videoId',
        ],
      ).timeout(const Duration(seconds: 60));
      
      if (result.exitCode == 0 && await file.exists()) {
        final size = await file.length();
        debugPrint('✅ Завантажено: ${(size / 1024).toStringAsFixed(1)} KB');
        return filePath;
      }
      
      debugPrint('❌ yt-dlp помилка: ${result.stderr}');
      return null;
    } catch (e) {
      debugPrint('❌ Помилка: $e');
      return null;
    }
  }


  void dispose() {
    _yt.close();
  }
}
