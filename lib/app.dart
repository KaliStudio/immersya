// lib/app.dart
import 'package:flutter/material.dart';
import 'package:immersya_pathfinder/features/shell/screens/main_shell.dart';
import 'package:immersya_pathfinder/utils/app_theme.dart';

class ImmersyaPathfinderApp extends StatelessWidget {
  const ImmersyaPathfinderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Immersya',
      theme: AppTheme.darkTheme,
      debugShowCheckedModeBanner: false,
      //home: const MainShell(),
      home: MainShell(key: mainShellNavigatorKey),
    );
  }
}