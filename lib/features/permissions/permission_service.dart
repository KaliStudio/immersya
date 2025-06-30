// lib/features/permissions/permission_service.dart

import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionService with ChangeNotifier {
  PermissionStatus _cameraStatus = PermissionStatus.denied;
  PermissionStatus _locationStatus = PermissionStatus.denied;

  PermissionStatus get cameraStatus => _cameraStatus;
  PermissionStatus get locationStatus => _locationStatus;

  PermissionService() {
    checkAllPermissions();
  }

  Future<void> checkAllPermissions() async {
    _cameraStatus = await Permission.camera.status;
    _locationStatus = await Permission.location.status;
    notifyListeners();
  }

  Future<void> requestCameraPermission() async {
    if (await Permission.camera.isPermanentlyDenied) {
      // Si c'est bloqué, on ouvre les paramètres
      await openAppSettings();
    } else {
      // Sinon, on demande la permission
      _cameraStatus = await Permission.camera.request();
    }
    // On revérifie le statut final après l'action de l'utilisateur
    await checkAllPermissions();
  }

  Future<void> requestLocationPermission() async {
    if (await Permission.location.isPermanentlyDenied) {
      await openAppSettings();
    } else {
      _locationStatus = await Permission.location.request();
    }
    await checkAllPermissions();
  }

  // CORRECTION : La méthode openAppSettings() du service ne doit pas s'appeler elle-même.
  // Elle doit appeler la fonction du package permission_handler.
  Future<void> openDeviceSettings() async {
    await openAppSettings();
  }

  // Votre méthode requestEssentialPermissions est bonne, on la garde.
  Future<bool> requestEssentialPermissions() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.camera,
      Permission.location,
    ].request();

    _cameraStatus = statuses[Permission.camera] ?? PermissionStatus.denied;
    _locationStatus = statuses[Permission.location] ?? PermissionStatus.denied;
    notifyListeners();

    return _cameraStatus.isGranted && _locationStatus.isGranted;
  }
}