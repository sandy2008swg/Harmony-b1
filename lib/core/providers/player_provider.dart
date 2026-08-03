import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_kit/media_kit.dart' as mk;
import '../models/track.dart' as model;
import 'providers.dart';

enum RepeatMode { none, all, one }

final isShuffleProvider = StateProvider<bool>((ref) => false);
final repeatModeProvider = StateProvider<RepeatMode>((ref) => RepeatMode.none);
final trackQueueProvider = StateProvider<List<model.Track>>((ref) => []);
final currentTrackIndexProvider = StateProvider<int>((ref) => -1);

/// Медіа-плеєр (media_kit)
final mediaPlayerProvider = Provider<mk.Player>((ref) {
  final player = mk.Player();
  ref.onDispose(() => player.dispose());
  return player;
});

class PlayerController {
  final Ref _ref;
  bool _isListeningCompleted = false;

  PlayerController(this._ref) {
    _initCompletedListener();
  }

  mk.Player get _player => _ref.read(mediaPlayerProvider);

  void _initCompletedListener() {
    if (_isListeningCompleted) return;
    _isListeningCompleted = true;
    _player.stream.completed.listen((completed) {
      if (completed) {
        debugPrint('🎵 Трек завершився, вмикаю наступний...');
        nextTrack();
      }
    });
  }

  void toggleShuffle() {
    final current = _ref.read(isShuffleProvider);
    _ref.read(isShuffleProvider.notifier).state = !current;
    debugPrint('🔀 Shuffle: ${!current}');
  }

  void toggleRepeat() {
    final current = _ref.read(repeatModeProvider);
    final nextMode = switch (current) {
      RepeatMode.none => RepeatMode.all,
      RepeatMode.all => RepeatMode.one,
      RepeatMode.one => RepeatMode.none,
    };
    _ref.read(repeatModeProvider.notifier).state = nextMode;
    debugPrint('🔁 Repeat mode: $nextMode');
  }

  Future<void> playTrack(model.Track track, {List<model.Track>? queue}) async {
    final currentQueue = queue ?? _ref.read(trackQueueProvider);
    List<model.Track> newQueue = currentQueue;
    int index = currentQueue.indexWhere((t) => t.id == track.id);

    if (queue != null || index == -1) {
      if (queue != null) {
        newQueue = queue;
        index = queue.indexWhere((t) => t.id == track.id);
        if (index == -1) {
          newQueue = [track, ...queue];
          index = 0;
        }
      } else {
        newQueue = [track];
        index = 0;
      }
      _ref.read(trackQueueProvider.notifier).state = newQueue;
    }

    _ref.read(currentTrackIndexProvider.notifier).state = index;

    try {
      debugPrint('▶️ Завантажую: ${track.title}');
      
      _ref.read(currentTrackProvider.notifier).state = track;
      _ref.read(isPlayingProvider.notifier).state = false;

      String? playUrl = track.playUrl;

      if (track.localPath != null) {
        playUrl = track.localPath;
        debugPrint('🎵 Граю локальний файл');
      } else {
        debugPrint('🔄 Отримую stream URL...');
        final youtubeService = _ref.read(youtubeServiceProvider);
        final streamUrl = await youtubeService.getStreamUrl(track.id);
        
        if (streamUrl == null) {
          debugPrint('❌ Не вдалося отримати stream URL');
          return;
        }
        playUrl = streamUrl;
      }

      await _player.open(mk.Media(playUrl!));
      await _player.play();
      
      _ref.read(isPlayingProvider.notifier).state = true;
      debugPrint('🎵 Грає: ${track.title}');
    } catch (e) {
      debugPrint('❌ Помилка: $e');
      _ref.read(isPlayingProvider.notifier).state = false;
    }
  }

  Future<void> nextTrack() async {
    final queue = _ref.read(trackQueueProvider);
    if (queue.isEmpty) return;
    final currentIndex = _ref.read(currentTrackIndexProvider);
    final isShuffle = _ref.read(isShuffleProvider);
    final repeatMode = _ref.read(repeatModeProvider);

    if (repeatMode == RepeatMode.one && currentIndex != -1) {
      await playTrack(queue[currentIndex]);
      return;
    }

    if (isShuffle && queue.length > 1) {
      final rand = Random();
      int nextIndex = currentIndex;
      while (nextIndex == currentIndex) {
        nextIndex = rand.nextInt(queue.length);
      }
      await playTrack(queue[nextIndex]);
      return;
    }

    int nextIndex = currentIndex + 1;
    if (nextIndex >= queue.length) {
      if (repeatMode == RepeatMode.all) {
        nextIndex = 0;
      } else {
        return;
      }
    }
    await playTrack(queue[nextIndex]);
  }

  Future<void> previousTrack() async {
    if (_player.state.position.inSeconds > 3) {
      await seek(Duration.zero);
      return;
    }
    final queue = _ref.read(trackQueueProvider);
    if (queue.isEmpty) return;
    final currentIndex = _ref.read(currentTrackIndexProvider);
    final isShuffle = _ref.read(isShuffleProvider);
    final repeatMode = _ref.read(repeatModeProvider);

    if (isShuffle && queue.length > 1) {
      final rand = Random();
      int prevIndex = currentIndex;
      while (prevIndex == currentIndex) {
        prevIndex = rand.nextInt(queue.length);
      }
      await playTrack(queue[prevIndex]);
      return;
    }

    int prevIndex = currentIndex - 1;
    if (prevIndex < 0) {
      if (repeatMode == RepeatMode.all) {
        prevIndex = queue.length - 1;
      } else {
        prevIndex = 0;
      }
    }
    await playTrack(queue[prevIndex]);
  }

  Future<void> togglePlay() async {
    try {
      if (_player.state.playing) {
        await _player.pause();
        _ref.read(isPlayingProvider.notifier).state = false;
      } else {
        await _player.play();
        _ref.read(isPlayingProvider.notifier).state = true;
      }
    } catch (e) {
      debugPrint('❌ togglePlay: $e');
    }
  }

  Future<void> stop() async {
    await _player.stop();
    _ref.read(currentTrackProvider.notifier).state = null;
    _ref.read(isPlayingProvider.notifier).state = false;
  }

  Future<void> seek(Duration position) async {
    await _player.seek(position);
  }

  Future<void> setVolume(double volume) async {
    await _player.setVolume(volume * 100);
  }
}

/// ⬇️ ЦЕЙ РЯДОК МАЄ БУТИ! ⬇️
final playerControllerProvider = Provider<PlayerController>((ref) {
  return PlayerController(ref);
});

class PositionData {
  final Duration position;
  final Duration duration;

  PositionData({required this.position, required this.duration});
}
