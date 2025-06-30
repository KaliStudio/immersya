// lib/features/capture/capture_state.dart

import 'package:flutter/foundation.dart';
import 'package:immersya_mobile_app/api/mock_api_service.dart';
import 'package:immersya_mobile_app/features/auth/services/auth_service.dart';
import 'package:immersya_mobile_app/features/missions/state/mission_state.dart';
import 'package:latlong2/latlong.dart';

enum CaptureMode { idle, mission, freeScan }
enum FreeScanType { interior, object, avatar, none }

class CaptureState with ChangeNotifier {
  // =============================================================
  // DÉPENDANCES
  // =============================================================
  MockApiService? _apiService;
  AuthService? _authService;
  MissionState? _missionState;

  // =============================================================
  // ÉTAT DE LA CAPTURE
  // =============================================================
  CaptureMode _mode = CaptureMode.idle;
  Mission? _activeMission;
  FreeScanType _freeScanType = FreeScanType.none;
  bool _isCapturing = false;
  int lastGainedPoints = 0;
  LatLng? lastCaptureLocation;
  bool _isUploading = false;
  double _uploadProgress = 0.0;

  // =============================================================
  // GETTERS
  // =============================================================
  CaptureMode get mode => _mode;
  Mission? get activeMission => _activeMission;
  FreeScanType get freeScanType => _freeScanType;
  bool get isUploading => _isUploading;
  double get uploadProgress => _uploadProgress;
  bool get isCapturing => _isCapturing;

  // =============================================================
  // INITIALISATION
  // =============================================================
  // 2. MISE À JOUR DE LA SIGNATURE DE INIT
  void init(MockApiService apiService, AuthService authService, MissionState missionState) {
    _apiService = apiService;
    _authService = authService;
    _missionState = missionState;
  }
  
  // =============================================================
  // ACTIONS UTILISATEUR
  // =============================================================
  void startMission(Mission mission) {
    _startCapture(CaptureMode.mission, mission: mission);
  }
  
  void startFreeScan(FreeScanType type) {
    _startCapture(CaptureMode.freeScan, freeScanType: type);
  }

  void _startCapture(CaptureMode mode, {Mission? mission, FreeScanType freeScanType = FreeScanType.none}) {
    final userId = _authService?.currentUser?.id;
    if (userId == null) return;
    _mode = mode;
    _activeMission = mission;
    _freeScanType = freeScanType;
    _isCapturing = true;
    _apiService?.updateCaptureStatus(userId, true);
    notifyListeners();
  }

  void cancelCapture() {
    _stopCapture(isCancelled: true);
  }

  Future<void> completeCapture({required int photoCount, required LatLng location}) async {
    await _stopCapture(isCancelled: false, photoCount: photoCount, location: location);
  }

  Future<void> _stopCapture({bool isCancelled = false, int photoCount = 0, LatLng? location}) async {
    final userId = _authService?.currentUser?.id;
    if (userId == null) return;
    
    final wasMission = _mode == CaptureMode.mission;
    final completedMission = _activeMission;

    _apiService?.updateCaptureStatus(userId, false);
    _isCapturing = false;

    if (isCancelled || _mode == CaptureMode.idle) {
      _mode = CaptureMode.idle;
      _activeMission = null;
      _freeScanType = FreeScanType.none;
      notifyListeners();
      return;
    }
    
    _isUploading = true;
    _uploadProgress = 0.0;
    notifyListeners();

    for (int i = 0; i <= photoCount; i++) {
      await Future.delayed(const Duration(milliseconds: 20));
      _uploadProgress = i / photoCount;
      notifyListeners();
    }
    await Future.delayed(const Duration(milliseconds: 200));

    lastGainedPoints = (_mode == CaptureMode.mission) ? _activeMission!.rewardPoints : 50;
    lastCaptureLocation = location;
    
    _isUploading = false;
    notifyListeners();
    
    _authService?.refreshCurrentUser();
    
    // --- 3. AJOUT DE LA LOGIQUE DE COMPLÉTION DE MISSION ---
    if (wasMission && completedMission != null) {
      _missionState?.missionWasCompleted(completedMission.id);
    }
    
    _mode = CaptureMode.idle;
    _activeMission = null;
    _freeScanType = FreeScanType.none;
  }
}