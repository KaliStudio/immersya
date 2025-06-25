// lib/features/capture/capture_state.dart
import 'package:flutter/material.dart';
import 'package:immersya_mobile_app/api/mock_api_service.dart';

enum CaptureMode { idle, mission, freeScan }
enum FreeScanType { interior, object, avatar, none }

class CaptureState with ChangeNotifier {
  CaptureMode _mode = CaptureMode.idle;
  Mission? _activeMission;
  FreeScanType _freeScanType = FreeScanType.none;
  
  bool _isUploading = false;
  double _uploadProgress = 0.0;
  
  // NOUVEAU
  int _lastGainedPoints = 0;

  CaptureMode get mode => _mode;
  Mission? get activeMission => _activeMission;
  FreeScanType get freeScanType => _freeScanType;
  bool get isUploading => _isUploading;
  double get uploadProgress => _uploadProgress;
  int get lastGainedPoints => _lastGainedPoints;

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

  Future<String> completeAndUploadScan(int photoCount) async {
    if (_mode == CaptureMode.idle) return "";

    _isUploading = true;
    _uploadProgress = 0.0;
    _lastGainedPoints = 0; // Réinitialiser avant l'upload
    notifyListeners();

    for (int i = 0; i <= photoCount; i++) {
      await Future.delayed(const Duration(milliseconds: 250));
      _uploadProgress = i / photoCount;
      notifyListeners();
    }
    
    await Future.delayed(const Duration(milliseconds: 500));
    
    String successMessage = "";
    if (_mode == CaptureMode.mission) {
      _lastGainedPoints = _activeMission!.rewardPoints; // Stocker les points
      successMessage = 'Mission "${_activeMission!.title}" terminée ! +$_lastGainedPoints points !';
    } else if (_mode == CaptureMode.freeScan) {
      successMessage = 'Scan libre de type "$_freeScanType" uploadé avec succès !';
    }
    
    _isUploading = false;
    cancelCapture(); // Notifie les listeners et réinitialise l'état

    return successMessage;
  }
}