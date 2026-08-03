import 'package:flutter/material.dart';

class AlbumCard extends StatelessWidget {
  final String title;
  final String artist;

  const AlbumCard({
    super.key,
    required this.title,
    required this.artist,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () {},
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                width: double.infinity,
                color: Colors.green.shade700,
                child: const Icon(
                  Icons.music_note,
                  size: 80,
                  color: Colors.white,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 17,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Text(
                artist,
                style: const TextStyle(
                  color: Colors.white70,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}