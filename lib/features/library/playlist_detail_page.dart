import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../core/models/playlist.dart';
import '../../core/models/track.dart';
import '../../core/providers/providers.dart';

class PlaylistDetailPage extends ConsumerStatefulWidget {
  final Playlist playlist;
  const PlaylistDetailPage({super.key, required this.playlist});

  @override
  ConsumerState<PlaylistDetailPage> createState() => _PlaylistDetailPageState();
}

class _PlaylistDetailPageState extends ConsumerState<PlaylistDetailPage> {
  late Future<List<Track>> _tracksFuture;

  @override
  void initState() {
    super.initState();
    _loadTracks();
  }

  void _loadTracks() {
    final db = ref.read(databaseServiceProvider);
    _tracksFuture = db.getPlaylistTracks(widget.playlist.id);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: FutureBuilder<List<Track>>(
        future: _tracksFuture,
        builder: (context, snapshot) {
          final tracks = snapshot.data ?? [];
          
          return CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 250,
                pinned: true,
                backgroundColor: const Color(0xFF181818),
                flexibleSpace: FlexibleSpaceBar(
                  title: Text(widget.playlist.name),
                  background: Container(
                    color: Colors.green.shade700,
                    child: const Icon(
                      Icons.queue_music,
                      size: 100,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              
              if (tracks.isEmpty)
                const SliverFillRemaining(
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'Плейлист порожній\nТут поки що немає треків',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white60,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                )
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final track = tracks[index];
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
                        trailing: IconButton(
                          icon: const Icon(Icons.play_arrow),
                          onPressed: () {
                            ref.read(playerControllerProvider).playTrack(track);
                          },
                        ),
                        onTap: () {
                          ref.read(playerControllerProvider).playTrack(track);
                        },
                      );
                    },
                    childCount: tracks.length,
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
