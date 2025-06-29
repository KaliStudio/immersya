// lib/features/map/state/map_state.dart

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:immersya_mobile_app/api/mock_api_service.dart';
import 'package:immersya_mobile_app/features/auth/services/auth_service.dart';
import 'package:immersya_mobile_app/features/team/state/team_state.dart';
import 'package:immersya_mobile_app/models/capture_point_model.dart';
import 'package:immersya_mobile_app/models/ghost_trace_model.dart';
import 'package:immersya_mobile_app/models/zone_model.dart';
import 'package:latlong2/latlong.dart';

enum MapFilter {
  zones, missions, currentUser, heatmap, ghostTraces, teammates,
  teamHeatmap, // Filtre pour la heatmap d'équipe
}

class MapState with ChangeNotifier {
  MockApiService? _apiService;
  AuthService? _authService;
  TeamState? _teamState;
  StreamSubscription? _teammateLocationSubscription;

  List<Zone> zones = [];
  List<Mission> missions = [];
  List<CapturePoint> capturePoints = [];
  List<GhostTrace> ghostTraces = [];
  List<CapturePoint> teamCapturePoints = []; // Pour la heatmap d'équipe
  List<UserProfile> teammates = [];
  LatLng? currentUserPosition;

  bool isLoading = false;
  String? error;

  final Map<MapFilter, bool> _activeFilters = {
    MapFilter.zones: true, MapFilter.missions: true, MapFilter.currentUser: true,
    MapFilter.heatmap: true, MapFilter.ghostTraces: true, MapFilter.teammates: true,
    MapFilter.teamHeatmap: true,
  };

  bool isFilterActive(MapFilter filter) => _activeFilters[filter] ?? false;

  void init(MockApiService apiService, AuthService authService, TeamState teamState) {
    _apiService = apiService;
    _authService = authService;
    _teamState = teamState;
    _teamState?.addListener(_onTeamChanged);
    _onTeamChanged();
  }

  @override
  void dispose() {
    _teamState?.removeListener(_onTeamChanged);
    unsubscribeFromTeammateLocations();
    super.dispose();
  }

  Future<void> loadAllMapData() async {
    if (isLoading || _apiService == null) return;
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      final results = await Future.wait([
        _apiService!.fetchZones(),
        _apiService!.fetchMissions(),
        _apiService!.fetchCapturePoints(),
        _apiService!.fetchGhostTraces(),
      ]);
      zones = results[0] as List<Zone>;
      missions = results[1] as List<Mission>;
      capturePoints = results[2] as List<CapturePoint>;
      ghostTraces = results[3] as List<GhostTrace>;
    } catch (e) {
      error = "Erreur de chargement des données de la carte: $e";
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
  
  void _onTeamChanged() {
    final currentTeam = _teamState?.currentTeam;
    if (currentTeam == null) {
      unsubscribeFromTeammateLocations();
      if (teamCapturePoints.isNotEmpty) {
        teamCapturePoints = [];
        notifyListeners();
      }
    } else {
      subscribeToTeammateLocations(currentTeam.id);
      loadTeamCaptureHistory(currentTeam.id);
    }
  }

  Future<void> loadTeamCaptureHistory(String teamId) async {
    if (_apiService == null) return;
    try {
      final records = await _apiService!.fetchTeamCaptureHistory(teamId);
      teamCapturePoints = records.map((r) => CapturePoint(location: r.location)).toList();
      notifyListeners();
    } catch (e) {
      // Gérer l'erreur si nécessaire
    }
  }

  Future<void> startTeamCaptureOnZone(String zoneId) async {
    if (_apiService == null) return;
    await _apiService!.startTeamCaptureOnZone(zoneId);
    // On force le rafraîchissement de la liste des zones pour voir le changement d'état
    await loadAllMapData();
  }

  Future<void> stopTeamCaptureOnZone(String zoneId) async {
    if (_apiService == null) return;
    await _apiService!.stopTeamCaptureOnZone(zoneId);
    await loadAllMapData();
  }
  
  void updateCurrentUserPosition(LatLng position) {
    currentUserPosition = position;
  }

  void toggleFilter(MapFilter filter) {
    _activeFilters[filter] = !isFilterActive(filter);
    notifyListeners();
  }

  void subscribeToTeammateLocations(String teamId) {
    unsubscribeFromTeammateLocations();
    _teammateLocationSubscription = _apiService?.teammateLocationStream.listen((updatedTeammates) {
      final currentUserId = _authService?.currentUser?.id;
      teammates = updatedTeammates.where((user) => user.id != currentUserId).toList();
      notifyListeners();
    });
    _apiService?.startTeamLocationSimulation(teamId);
  }

  void unsubscribeFromTeammateLocations() {
    if (_teammateLocationSubscription != null) {
      _teammateLocationSubscription!.cancel();
      _teammateLocationSubscription = null;
      _apiService?.stopTeamLocationSimulation();
      if (teammates.isNotEmpty) {
        teammates = [];
        notifyListeners();
      }
    }
  }
}