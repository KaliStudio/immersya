// lib/features/auth/screens/auth_wrapper.dart

import 'package:flutter/material.dart';
import 'package:immersya_mobile_app/features/auth/services/auth_service.dart';
import 'package:immersya_mobile_app/features/shell/screens/main_shell.dart';
import 'package:provider/provider.dart';
import 'login_screen.dart'; 

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = context.watch<AuthService>();

    if (authService.isAuthenticated) {
      // Si l'utilisateur est connecté, on affiche l'application principale.
      return const MainShell();
    } else {
      // Sinon, on affiche l'écran de connexion.
     return const LoginScreen();
    }
  }
}