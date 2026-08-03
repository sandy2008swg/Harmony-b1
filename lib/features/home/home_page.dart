import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_pages.dart';
import '../../core/services/navigation_service.dart';

import '../downloads/downloads_page.dart';
import '../library/favorites_page.dart';
import '../library/library_page.dart';
import '../search/search_page.dart';
import '../settings/settings_page.dart';

import 'widgets/album_card.dart';
import 'widgets/header.dart';
import 'widgets/player_bar.dart';
import 'widgets/side_menu.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  Widget _buildPage(BuildContext context, AppPage page) {
    switch (page) {
      case AppPage.home:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 25),

            const Header(),

            const SizedBox(height: 15),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const FavoritesPage()),
                  );
                },
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFE91E63), Color(0xFF9C27B0)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.pink.withValues(alpha: 0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: const BoxDecoration(
                          color: Colors.white24,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.favorite, color: Colors.white, size: 28),
                      ),
                      const SizedBox(width: 16),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Улюблені пісні",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            "Твоя колекція збережених треків",
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      const Icon(Icons.arrow_forward_ios, color: Colors.white70, size: 18),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.all(24),
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  crossAxisSpacing: 20,
                  mainAxisSpacing: 20,
                ),
                itemCount: 8,
                itemBuilder: (context, index) {
                  return AlbumCard(
                    title: "Album ${index + 1}",
                    artist: "Unknown Artist",
                  );
                },
              ),
            ),
          ],
        );

      case AppPage.search:
        return const SearchPage();

      case AppPage.library:
        return const LibraryPage();

      case AppPage.downloads:
        return const DownloadsPage();

      case AppPage.settings:
        return const SettingsPage();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentPage = ref.watch(navigationProvider);

    return Scaffold(
      body: Row(
        children: [
          const SideMenu(),

          const VerticalDivider(width: 1),

          Expanded(
            child: Column(
              children: [
                Expanded(
                  child: _buildPage(context, currentPage),
                ),

                const PlayerBar(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}