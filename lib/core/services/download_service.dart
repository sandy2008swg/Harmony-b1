import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class DownloadService {
  final Dio _dio = Dio();

  /// Завантажує аудіо в тимчасовий файл
  Future<String?> downloadToTempFile(String url, String filename) async {
    try {
      debugPrint('⬇️ Завантажую аудіо...');
      
      final tempDir = await getTemporaryDirectory();
      final filePath = '${tempDir.path}/$filename';
      
      // Перевіряємо чи файл вже є
      final file = File(filePath);
      if (await file.exists() && await file.length() > 1000) {
        debugPrint('✅ Файл вже завантажений');
        return filePath;
      }
      
      // Завантажуємо з правильними headers
      await _dio.download(
        url,
        filePath,
        options: Options(
          headers: {
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
            'Accept': '*/*',
            'Accept-Language': 'en-US,en;q=0.9',
            'Range': 'bytes=0-',
          },
          responseType: ResponseType.bytes,
          followRedirects: true,
          validateStatus: (status) => status != null && status < 500,
        ),
        onReceiveProgress: (received, total) {
          if (total != -1) {
            final progress = (received / total * 100).toStringAsFixed(0);
            debugPrint('📥 $progress%');
          }
        },
      );
      
      final fileSize = await file.length();
      debugPrint('📦 Розмір: ${(fileSize / 1024).toStringAsFixed(1)} KB');
      
      if (fileSize < 1000) {
        debugPrint('❌ Файл замалий');
        await file.delete();
        return null;
      }
      
      // Перевіряємо чи це аудіо
      final firstBytes = await file.openRead(0, 4).first;
      final header = String.fromCharCodes(firstBytes);
      if (header.contains('<') || header.contains('!')) {
        debugPrint('❌ Це HTML, а не аудіо');
        await file.delete();
        return null;
      }
      
      debugPrint('✅ Успішно завантажено');
      return filePath;
    } catch (e) {
      debugPrint('❌ Помилка: $e');
      return null;
    }
  }

  Future<void> deleteTempFile(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) await file.delete();
    } catch (_) {}
  }
}
