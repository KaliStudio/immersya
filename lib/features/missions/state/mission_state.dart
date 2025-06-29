// lib/features/missions/state/mission_state.dart

import 'package:flutter/foundation.dart';
import 'package:immersya_mobile_app/api/mock_api_service.dart';

class MissionState with ChangeNotifier {
  final MockApiService _apiService;

  List<Mission> _availableMissions = [];
  List<Mission> get availableMissions => _availableMissions;

  final List<Mission> _acceptedMissions = [];
  List<Mission> get acceptedMissions => _acceptedMissions;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  MissionState(this._apiService) {
    fetchAvailableMissions();
  }

  Future<void> fetchAvailableMissions() async {
    _isLoading = true;
    notifyListeners();
    try {
      _availableMissions = await _apiService.fetchMissions();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  bool isMissionAccepted(String missionId) {
    return _acceptedMissions.any((m) => m.id == missionId);
  }

  void acceptMission(Mission mission) {
    if (!isMissionAccepted(mission.id)) {
      _acceptedMissions.add(mission);
      notifyListeners();
    }
  }

  // NOUVELLE MÉTHODE POUR ANNULER UNE MISSION
  void cancelAcceptedMission(String missionId) {
    _acceptedMissions.removeWhere((m) => m.id == missionId);
    notifyListeners();
  }

  // Renommée pour plus de clarté
  void missionWasCompleted(String missionId) {
    _acceptedMissions.removeWhere((m) => m.id == missionId);
    notifyListeners();
  }
}