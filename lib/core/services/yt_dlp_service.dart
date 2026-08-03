import 'dart:io';
import 'package:flutter/foundation.dart';

class YtDlpService {
  /// Завантажує аудіо через yt-dlp (потребує встановлений Python + yt-dlp)
  Future<String?> getDirectUrl(String videoId) async {
    try {
      debugPrint('🔄 Отримую URL через yt-dlp...');
      
      // Спочатку перевіряємо чи є yt-dlp
      final checkResult = await Process.run('yt-dlp', ['--version']);
      if (checkResult.exitCode != 0) {
        debugPrint('❌ yt-dlp не встановлений');
        return null;
      }
      
      // Отримуємо прямий URL аудіо
      final result = await Process.run(
        'yt-dlp',
        [
          '-f', 'bestaudio[ext=m4a]/bestaudio',
          '-g',  // тільки URL
          'https://www.youtube.com/watch?v=$videoId',
        ],
      );
      
      if (result.exitCode == 0) {
        final url = (result.stdout as String).trim();
        if (url.isNotEmpty) {
          debugPrint('✅ URL отримано через yt-dlp');
          return url;
        }
      }
      
      debugPrint('❌ Помилка yt-dlp: ${result.stderr}');
      return null;
    } catch (e) {
      debugPrint('❌ Помилка: $e');
      return null;
    }
  }
}

