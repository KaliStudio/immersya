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
      await openAppSettings();
    } else {
      _cameraStatus = await Permission.camera.request();
    }
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

  Future<void> openDeviceSettings() async {
    await openAppSettings();
  }

  /// ✅ Demande combinée, avec gestion des refus définitifs
  Future<bool> requestEssentialPermissions() async {
    _cameraStatus = await Permission.camera.status;
    _locationStatus = await Permission.location.status;

    debugPrint("📷 Caméra: $_cameraStatus | 📍 Localisation: $_locationStatus");

    if (_cameraStatus.isPermanentlyDenied || _locationStatus.isPermanentlyDenied) {
      notifyListeners();
      return false;
    }

    _cameraStatus = await Permission.camera.request();
    _locationStatus = await Permission.location.request();

    debugPrint("🆕 Résultat: caméra=$_cameraStatus / localisation=$_locationStatus");

    notifyListeners();
    return _cameraStatus.isGranted && _locationStatus.isGranted;
  }
}
