// lib/features/permissions/screens/permission_wrapper.dart

import 'package:flutter/material.dart';
import 'package:immersya_mobile_app/features/permissions/permission_service.dart';
import 'package:immersya_mobile_app/features/shell/screens/main_shell.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

class PermissionWrapper extends StatefulWidget {
  const PermissionWrapper({super.key});

  @override
  State<PermissionWrapper> createState() => _PermissionWrapperState();
}

class _PermissionWrapperState extends State<PermissionWrapper> {
  // Un Future pour gérer l'état de la demande de permission
  Future<bool>? _permissionsFuture;

  @override
  void initState() {
    super.initState();
    // On lance la demande de permissions dès que le widget est créé
    _permissionsFuture = context.read<PermissionService>().requestEssentialPermissions();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _permissionsFuture,
      builder: (context, snapshot) {
        // Cas 1: La demande est en cours
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Cas 2: La demande est terminée
        if (snapshot.hasData) {
          final bool allGranted = snapshot.data!;
          // Si toutes les permissions sont accordées, on affiche l'application principale
          if (allGranted) {
            return const MainShell();
          }
          // Sinon, on affiche un écran expliquant pourquoi les permissions sont nécessaires
          else {
            return _buildPermissionDeniedScreen();
          }
        }

        // Cas 3: Erreur (peu probable mais à gérer)
        if (snapshot.hasError) {
          return Scaffold(body: Center(child: Text("Erreur de permissions: ${snapshot.error}")));
        }

        // Cas par défaut
        return const Scaffold(body: Center(child: Text("Initialisation...")));
      },
    );
  }

  // Écran à afficher si l'utilisateur refuse les permissions
  Widget _buildPermissionDeniedScreen() {
    final permissionService = context.read<PermissionService>();
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 60),
            const SizedBox(height: 16),
            const Text(
              "Permissions Requises",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            const Text(
              "Immersya a besoin de l'accès à la caméra et à la localisation pour fonctionner.\n\nVeuillez autoriser ces permissions dans les réglages de votre appareil.",
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () async {
                // Ouvre les paramètres de l'application
                await openAppSettings();
              },
              child: const Text("Ouvrir les Réglages"),
            ),
          ],
        ),
      ),
    );
  }
}