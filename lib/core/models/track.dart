// Модель треку — це "шаблон" для однієї пісні.
// Як картка в бібліотеці: назва, артист, обкладинка, шлях до файлу.

enum SourceType {
  soundcloud,  // Зі SoundCloud
  youtube,     // З YouTube
  local,       // Локальний файл
}

class Track {
  final String id;              // Унікальний ID
  final String title;           // Назва пісні
  final String artist;          // Артист
  final String? album;          // Альбом (може бути null)
  final String? coverUrl;       // URL обкладинки
  final String? localPath;      // Шлях до локального файлу (якщо завантажено)
  final String? streamUrl;      // URL для стрімінгу
  final int? durationMs;        // Тривалість в мілісекундах
  final SourceType source;      // Звідки пісня

  const Track({
    required this.id,
    required this.title,
    required this.artist,
    this.album,
    this.coverUrl,
    this.localPath,
    this.streamUrl,
    this.durationMs,
    this.source = SourceType.soundcloud,
  });

  /// Чи завантажений трек (є локальний файл)?
  bool get isDownloaded => localPath != null;

  /// Що грати: локальний файл або стрім
  String? get playUrl => localPath ?? streamUrl;

  /// Тривалість у форматі "3:45"
  String get durationFormatted {
    if (durationMs == null) return '--:--';
    final seconds = (durationMs! / 1000).round();
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }
}
