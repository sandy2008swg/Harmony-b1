import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/track.dart';
import '../providers/providers.dart';

class FavoriteButton extends ConsumerStatefulWidget {
  final Track track;
  final double iconSize;

  const FavoriteButton({
    super.key,
    required this.track,
    this.iconSize = 24,
  });

  @override
  ConsumerState<FavoriteButton> createState() => _FavoriteButtonState();
}

class _FavoriteButtonState extends ConsumerState<FavoriteButton> {
  bool _isFavorite = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _checkFavorite();
  }

  Future<void> _checkFavorite() async {
    try {
      final db = ref.read(databaseServiceProvider);
      final isFav = await db.isFavorite(widget.track.id);
      if (mounted) {
        setState(() {
          _isFavorite = isFav;
          _loading = false;
        });
      }
    } catch (e) {
      debugPrint('❌ Помилка перевірки: $e');
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _toggleFavorite() async {
    if (_loading) return;
    
    if (mounted) {
      setState(() => _loading = true);
    }
    
    try {
      final db = ref.read(databaseServiceProvider);
      if (_isFavorite) {
        await db.removeFromFavorites(widget.track.id);
      } else {
        await db.addToFavorites(widget.track);
      }
      
      if (mounted) {
        setState(() {
          _isFavorite = !_isFavorite;
          _loading = false;
        });
      }
      
      ref.invalidate(favoritesProvider);
    } catch (e) {
      debugPrint('❌ Помилка: $e');
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return SizedBox(
        width: widget.iconSize,
        height: widget.iconSize,
        child: const CircularProgressIndicator(strokeWidth: 2),
      );
    }
    
    return IconButton(
      iconSize: widget.iconSize,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(),
      icon: Icon(
        _isFavorite ? Icons.favorite : Icons.favorite_border,
        color: _isFavorite ? Colors.red : Colors.white60,
      ),
      onPressed: _toggleFavorite,
    );
  }
}
