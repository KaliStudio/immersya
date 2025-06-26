// lib/app.dart
import 'package:flutter/material.dart';
//import 'package:immersya_mobile_app/features/shell/screens/main_shell.dart';
import 'package:immersya_mobile_app/utils/app_theme.dart';
import 'package:immersya_mobile_app/features/auth/screens/auth_wrapper.dart';

class ImmersyaPathfinderApp extends StatelessWidget {
  const ImmersyaPathfinderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Immersya',
      theme: AppTheme.darkTheme,
      debugShowCheckedModeBanner: false,
      //home: const MainShell(),
      //home: MainShell(key: mainShellNavigatorKey),
      home: const AuthWrapper(), 
    );
  }
}