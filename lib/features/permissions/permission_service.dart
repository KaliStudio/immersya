// lib/features/permissions/permission_service.dart

import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionService with ChangeNotifier {
  PermissionStatus _cameraStatus = PermissionStatus.denied;
  PermissionStatus _locationStatus = PermissionStatus.denied;

  PermissionStatus get cameraStatus => _cameraStatus;
  PermissionStatus get locationStatus => _locationStatus;

  PermissionService() {
    // Vérifie le statut des permissions au démarrage.
    checkAllPermissions();
  }

  Future<void> checkAllPermissions() async {
    _cameraStatus = await Permission.camera.status;
    _locationStatus = await Permission.location.status;
    notifyListeners();
  }

  Future<void> requestCameraPermission() async {
    // Si la permission est déjà bloquée, on ouvre directement les paramètres.
    if (await Permission.camera.isPermanentlyDenied) {
      await openAppSettings();
      return;
    }
    _cameraStatus = await Permission.camera.request();
    notifyListeners();
  }

  Future<void> requestLocationPermission() async {
    // Si la permission est déjà bloquée, on ouvre directement les paramètres.
    if (await Permission.location.isPermanentlyDenied) {
      await openAppSettings();
      return;
    }
    _locationStatus = await Permission.location.request();
    notifyListeners();
  }

  // Ouvre les paramètres de l'application pour que l'utilisateur puisse changer les permissions manuellement.
  Future<void> openAppSettings() async {
    await openAppSettings();
  }
}