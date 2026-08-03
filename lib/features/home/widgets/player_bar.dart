import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:media_kit/media_kit.dart' as mk;

import '../../../core/providers/providers.dart';
import '../../../core/widgets/favorite_button.dart';

class PlayerBar extends ConsumerWidget {
  const PlayerBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentTrack = ref.watch(currentTrackProvider);
    final controller = ref.read(playerControllerProvider);
    final player = ref.watch(mediaPlayerProvider);
    final isShuffle = ref.watch(isShuffleProvider);
    final repeatMode = ref.watch(repeatModeProvider);

    return Container(
      height: 90,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: const BoxDecoration(
        color: Color(0xFF181818),
        border: Border(top: BorderSide(color: Colors.white12)),
      ),
      child: Row(
        children: [
          // ЛІВА ЧАСТИНА
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: 50,
                  height: 50,
                  child: currentTrack?.coverUrl != null
                      ? CachedNetworkImage(
                          imageUrl: currentTrack!.coverUrl!,
                          fit: BoxFit.cover,
                          errorWidget: (context, url, error) => Container(
                            color: Colors.grey.shade800,
                            child: const Icon(Icons.music_note, size: 24),
                          ),
                        )
                      : Container(
                          color: Colors.grey.shade800,
                          child: const Icon(Icons.music_note, size: 24),
                        ),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 140,
                    child: Text(
                      currentTrack?.title ?? "Nothing playing",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  SizedBox(
                    width: 140,
                    child: Text(
                      currentTrack?.artist ?? "Обери трек у пошуку",
                      style: const TextStyle(
                        color: Colors.white60,
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              if (currentTrack != null) ...[
                const SizedBox(width: 8),
                FavoriteButton(track: currentTrack, iconSize: 22),
              ],
            ],
          ),

          // ЦЕНТР
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        onPressed: controller.toggleShuffle,
                        icon: Icon(
                          Icons.shuffle,
                          size: 20,
                          color: isShuffle ? const Color(0xFF1DB954) : Colors.white60,
                        ),
                        padding: const EdgeInsets.all(4),
                        constraints: const BoxConstraints(),
                      ),
                      const SizedBox(width: 12),
                      IconButton(
                        onPressed: controller.previousTrack,
                        icon: const Icon(Icons.skip_previous, size: 24),
                        padding: const EdgeInsets.all(4),
                        constraints: const BoxConstraints(),
                      ),
                      const SizedBox(width: 12),
                      _PlayPauseButton(player: player, controller: controller),
                      const SizedBox(width: 12),
                      IconButton(
                        onPressed: controller.nextTrack,
                        icon: const Icon(Icons.skip_next, size: 24),
                        padding: const EdgeInsets.all(4),
                        constraints: const BoxConstraints(),
                      ),
                      const SizedBox(width: 12),
                      IconButton(
                        onPressed: controller.toggleRepeat,
                        icon: Icon(
                          repeatMode == RepeatMode.one ? Icons.repeat_one : Icons.repeat,
                          size: 20,
                          color: repeatMode != RepeatMode.none ? const Color(0xFF1DB954) : Colors.white60,
                        ),
                        padding: const EdgeInsets.all(4),
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  
                  // Прогрес-бар
                  StreamBuilder<Duration>(
                    stream: player.stream.position,
                    builder: (context, positionSnapshot) {
                      final position = positionSnapshot.data ?? Duration.zero;
                      final duration = player.state.duration;
                      
                      return Row(
                        children: [
                          Text(
                            _formatDuration(position),
                            style: const TextStyle(
                              color: Colors.white60,
                              fontSize: 11,
                            ),
                          ),
                          Expanded(
                            child: SliderTheme(
                              data: SliderTheme.of(context).copyWith(
                                trackHeight: 3,
                                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                                overlayShape: const RoundSliderOverlayShape(overlayRadius: 10),
                              ),
                              child: Slider(
                                min: 0,
                                max: duration.inMilliseconds.toDouble().clamp(1, double.infinity),
                                value: position.inMilliseconds
                                    .toDouble()
                                    .clamp(0, duration.inMilliseconds.toDouble().clamp(1, double.infinity)),
                                onChanged: currentTrack == null
                                    ? null
                                    : (value) {
                                        controller.seek(
                                          Duration(milliseconds: value.toInt()),
                                        );
                                      },
                              ),
                            ),
                          ),
                          Text(
                            _formatDuration(duration),
                            style: const TextStyle(
                              color: Colors.white60,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),

          // ПРАВА ЧАСТИНА
          Row(
            children: [
              const Icon(Icons.volume_down, size: 22),
              SizedBox(
                width: 120,
                child: StreamBuilder<double>(
                  stream: player.stream.volume,
                  initialData: 100.0,
                  builder: (context, snapshot) {
                    return Slider(
                      min: 0,
                      max: 100,
                      value: snapshot.data ?? 100.0,
                      onChanged: (value) => controller.setVolume(value / 100),
                    );
                  },
                ),
              ),
              const Icon(Icons.volume_up, size: 22),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }
}

class _PlayPauseButton extends StatelessWidget {
  final mk.Player player;
  final PlayerController controller;

  const _PlayPauseButton({
    required this.player,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<bool>(
      stream: player.stream.playing,
      builder: (context, snapshot) {
        final isPlaying = snapshot.data ?? false;
        
        return Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: 0.1),
          ),
          child: IconButton(
            onPressed: controller.togglePlay,
            icon: Icon(
              isPlaying ? Icons.pause : Icons.play_arrow,
              size: 32,
              color: Colors.white,
            ),
          ),
        );
      },
    );
  }
}
