// lib/features/capture/capture_state.dart

import 'package:flutter/material.dart';
import 'package:immersya_mobile_app/api/mock_api_service.dart';
import 'package:latlong2/latlong.dart';

enum CaptureMode { idle, mission, freeScan }
enum FreeScanType { interior, object, avatar, none }

class CaptureState with ChangeNotifier {
  CaptureMode _mode = CaptureMode.idle;
  Mission? _activeMission;
  FreeScanType _freeScanType = FreeScanType.none;
  
  // Ces deux propriétés deviennent les informations clés que les autres parties de l'app vont écouter.
  // Elles sont publiques pour être lues facilement.
  int lastGainedPoints = 0;
  LatLng? lastCaptureLocation;
  
  // L'état de l'upload reste privé et géré par des getters.
  bool _isUploading = false;
  double _uploadProgress = 0.0;

  // --- GETTERS (INCHANGÉS) ---
  CaptureMode get mode => _mode;
  Mission? get activeMission => _activeMission;
  FreeScanType get freeScanType => _freeScanType;
  bool get isUploading => _isUploading;
  double get uploadProgress => _uploadProgress;

  // --- MÉTHODES DE GESTION D'ÉTAT (INCHANGÉES) ---
  void startMission(Mission mission) {
    _mode = CaptureMode.mission;
    _activeMission = mission;
    notifyListeners();
  }
  
  void startFreeScan(FreeScanType type) {
    _mode = CaptureMode.freeScan;
    _freeScanType = type;
    notifyListeners();
  }

  void cancelCapture() {
    _mode = CaptureMode.idle;
    _activeMission = null;
    _freeScanType = FreeScanType.none;
    notifyListeners();
  }

  // --- MÉTHODE PRINCIPALE MODIFIÉE ---
  // Renommée pour plus de clarté et prend maintenant une `location`.
  // Elle ne retourne plus de `String`, sa seule responsabilité est de changer l'état.
  Future<void> completeCapture({required int photoCount, required LatLng location}) async {
    if (_mode == CaptureMode.idle) return;

    _isUploading = true;
    _uploadProgress = 0.0;
    notifyListeners();

    // Simuler l'upload de manière plus rapide pour la démo
    for (int i = 0; i <= photoCount; i++) {
      await Future.delayed(const Duration(milliseconds: 20));
      _uploadProgress = i / photoCount;
      notifyListeners();
    }
    
    await Future.delayed(const Duration(milliseconds: 200));
    
    // 1. Déterminer les points gagnés
    if (_mode == CaptureMode.mission) {
      lastGainedPoints = _activeMission!.rewardPoints;
    } else {
      lastGainedPoints = 50; // Points par défaut pour un scan libre
    }
    
    // 2. Enregistrer la localisation de la capture
    lastCaptureLocation = location;
    
    _isUploading = false;
    
    // 3. Notifier les listeners (comme ProfileScreen) qu'une capture est finie
    //    C'est l'étape la plus importante. Les listeners vont lire `lastGainedPoints` et `lastCaptureLocation`.
    notifyListeners();

    // 4. Réinitialiser l'état de la capture après que la notification a été envoyée.
    cancelCapture();
  }
}