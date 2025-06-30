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
  Future<bool>? _permissionsFuture;

  @override
  void initState() {
    super.initState();
    final perm = context.read<PermissionService>();
    perm.requestCameraPermission();
    perm.requestLocationPermission();
    perm.requestEssentialPermissions();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _permissionsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasData && snapshot.data == true) {
          return const MainShell();
        }

        if (snapshot.hasError) {
          return Scaffold(
            body: Center(child: Text("Erreur de permissions: ${snapshot.error}")),
          );
        }

        return _buildPermissionDeniedScreen();
      },
    );
  }

  Widget _buildPermissionDeniedScreen() {
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
                await openAppSettings();
              },
              child: const Text("Ouvrir les Réglages"),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () async {
                final result = await context.read<PermissionService>().requestEssentialPermissions();
                if (result) {
                  setState(() {
                    _permissionsFuture = Future.value(true);
                  });
                }
              },
              child: const Text("Réessayer"),
            ),
          ],
        ),
      ),
    );
  }
}
