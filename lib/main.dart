import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_kit/media_kit.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'dart:io';

import 'core/theme/app_theme.dart';
import 'features/home/home_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  
  if (Platform.isWindows || Platform.isLinux) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }
  
  MediaKit.ensureInitialized();
  
  runApp(
    const ProviderScope(
      child: HarmonyApp(),
    ),
  );
}

class HarmonyApp extends StatelessWidget {
  const HarmonyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Harmony",
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      home: const HomePage(),
    );
  }
}
