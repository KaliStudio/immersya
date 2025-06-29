// lib/features/capture/capture_state.dart

import 'package:flutter/foundation.dart';
import 'package:immersya_mobile_app/api/mock_api_service.dart';
import 'package:immersya_mobile_app/features/auth/services/auth_service.dart';
import 'package:latlong2/latlong.dart';

enum CaptureMode { idle, mission, freeScan }
enum FreeScanType { interior, object, avatar, none }

class CaptureState with ChangeNotifier {
  // =============================================================
  // DÉPENDANCES
  // =============================================================
  MockApiService? _apiService;
  AuthService? _authService;

  // =============================================================
  // ÉTAT DE LA CAPTURE
  // =============================================================
  CaptureMode _mode = CaptureMode.idle;
  Mission? _activeMission;
  FreeScanType _freeScanType = FreeScanType.none;
  
  // NOUVEAU : Statut de capture pour la fonctionnalité de groupe.
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
  // NOUVEAU GETTER
  bool get isCapturing => _isCapturing;

  // =============================================================
  // INITIALISATION
  // =============================================================
  void init(MockApiService apiService, AuthService authService) {
    _apiService = apiService;
    _authService = authService;
  }
  
  // =============================================================
  // ACTIONS UTILISATEUR
  // =============================================================

  /// Démarre une session de capture pour une mission.
  void startMission(Mission mission) {
    // Appelle la méthode de capture générique
    _startCapture(CaptureMode.mission, mission: mission);
  }
  
  /// Démarre une session de capture libre.
  void startFreeScan(FreeScanType type) {
    // Appelle la méthode de capture générique
    _startCapture(CaptureMode.freeScan, freeScanType: type);
  }

  /// Logique interne pour démarrer n'importe quel type de capture.
  void _startCapture(CaptureMode mode, {Mission? mission, FreeScanType freeScanType = FreeScanType.none}) {
    final userId = _authService?.currentUser?.id;
    if (userId == null) return;

    _mode = mode;
    _activeMission = mission;
    _freeScanType = freeScanType;
    _isCapturing = true;

    // Notifie l'API que l'utilisateur commence à capturer.
    _apiService?.updateCaptureStatus(userId, true);
    
    notifyListeners();
  }

  /// Annule la capture en cours.
  void cancelCapture() {
    _stopCapture(isCancelled: true);
  }

  /// Complète la capture et traite les résultats.
  Future<void> completeCapture({required int photoCount, required LatLng location}) async {
    await _stopCapture(isCancelled: false, photoCount: photoCount, location: location);
  }

  /// Logique interne pour arrêter une capture (complétée ou annulée).
  Future<void> _stopCapture({bool isCancelled = false, int photoCount = 0, LatLng? location}) async {
    final userId = _authService?.currentUser?.id;
    if (userId == null) return;
    
    // Notifie l'API que l'utilisateur a fini de capturer.
    // On le fait au début pour une meilleure réactivité sur la carte.
    _apiService?.updateCaptureStatus(userId, false);
    _isCapturing = false;

    if (isCancelled || _mode == CaptureMode.idle) {
      _mode = CaptureMode.idle;
      _activeMission = null;
      _freeScanType = FreeScanType.none;
      notifyListeners();
      return;
    }
    
    // --- Logique de complétion de la capture ---
    _isUploading = true;
    _uploadProgress = 0.0;
    notifyListeners();

    // Simuler l'upload
    for (int i = 0; i <= photoCount; i++) {
      await Future.delayed(const Duration(milliseconds: 20));
      _uploadProgress = i / photoCount;
      notifyListeners();
    }
    await Future.delayed(const Duration(milliseconds: 200));

    // Déterminer les points et enregistrer la localisation
    lastGainedPoints = (_mode == CaptureMode.mission) ? _activeMission!.rewardPoints : 50;
    lastCaptureLocation = location;
    
    _isUploading = false;
    
    // Notifier les autres parties de l'app (comme ProfileScreen) du résultat.
    notifyListeners();
    
    // Rafraîchir le profil de l'utilisateur pour mettre à jour ses points/stats.
    _authService?.refreshCurrentUser();

    // Réinitialiser l'état de la capture.
    _mode = CaptureMode.idle;
    _activeMission = null;
    _freeScanType = FreeScanType.none;
    // Pas besoin d'un `notifyListeners` final car `refreshCurrentUser` s'en chargera.
  }
}