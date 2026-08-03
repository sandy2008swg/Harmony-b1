import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_pages.dart';
import '../../../core/services/navigation_service.dart';

class SideMenu extends ConsumerWidget {
  const SideMenu({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final page = ref.watch(navigationProvider);

    return NavigationRail(
      selectedIndex: AppPage.values.indexOf(page),

      onDestinationSelected: (index) {
        ref.read(navigationProvider.notifier).state =
            AppPage.values[index];
      },

      labelType: NavigationRailLabelType.all,

      destinations: const [
        NavigationRailDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home),
          label: Text("Home"),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.search),
          selectedIcon: Icon(Icons.search),
          label: Text("Search"),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.library_music_outlined),
          selectedIcon: Icon(Icons.library_music),
          label: Text("Library"),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.download_outlined),
          selectedIcon: Icon(Icons.download),
          label: Text("Downloads"),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.settings_outlined),
          selectedIcon: Icon(Icons.settings),
          label: Text("Settings"),
        ),
      ],
    );
  }
}