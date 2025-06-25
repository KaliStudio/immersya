// lib/features/capture/capture_state.dart
import 'package:flutter/material.dart';
import 'package:immersya_pathfinder/api/mock_api_service.dart';

// NOUVEAU : Enums pour définir clairement nos états
enum CaptureMode { idle, mission, freeScan }
enum FreeScanType { interior, object, avatar, none }

// L'ancien MissionState, maintenant plus puissant
class CaptureState with ChangeNotifier {
  CaptureMode _mode = CaptureMode.idle;
  Mission? _activeMission;
  FreeScanType _freeScanType = FreeScanType.none;
  
  bool _isUploading = false;
  double _uploadProgress = 0.0;

  // Getters pour que l'UI puisse lire l'état
  CaptureMode get mode => _mode;
  Mission? get activeMission => _activeMission;
  FreeScanType get freeScanType => _freeScanType;
  bool get isUploading => _isUploading;
  double get uploadProgress => _uploadProgress;

  // --- ACTIONS ---

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

  // Annule la capture en cours et revient à l'écran de sélection
  void cancelCapture() {
    _mode = CaptureMode.idle;
    _activeMission = null;
    _freeScanType = FreeScanType.none;
    notifyListeners();
  }

  // Méthode unifiée pour l'upload
    Future<String> completeAndUploadScan(int photoCount) async {
    //if (_mode == CaptureMode.idle) return;

    _isUploading = true;
    _uploadProgress = 0.0;
    notifyListeners();

    // Simuler un upload progressif
    for (int i = 0; i <= photoCount; i++) {
      await Future.delayed(const Duration(milliseconds: 250));
      _uploadProgress = i / photoCount;
      notifyListeners();
    }
    
    await Future.delayed(const Duration(milliseconds: 500));
    
    // Simuler différents appels backend en fonction du mode
    if (_mode == CaptureMode.mission) {
      print('UPLOAD: Mission "${_activeMission!.title}" terminée avec $photoCount photos.');
    } else if (_mode == CaptureMode.freeScan) {
      print('UPLOAD: Scan libre de type "$_freeScanType" terminé avec $photoCount photos.');
    }
    
        String successMessage = "";
    if (_mode == CaptureMode.mission) {
      successMessage = 'Mission "${_activeMission!.title}" terminée ! +${_activeMission!.rewardPoints} points !';
      print('UPLOAD: Mission "${_activeMission!.title}" terminée avec $photoCount photos.');
    } else if (_mode == CaptureMode.freeScan) {
      successMessage = 'Scan libre de type "$_freeScanType" uploadé avec succès !';
      print('UPLOAD: Scan libre de type "$_freeScanType" terminé avec $photoCount photos.');
    }
    
    _isUploading = false;
    cancelCapture(); // Notifie les listeners et réinitialise l'état

    return successMessage; // Utilise notre nouvelle méthode de reset
  }
}