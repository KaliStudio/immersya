// lib/features/map/state/map_state.dart

import 'dart:async';
import 'package:flutter/foundation.dart';

// Imports nécessaires
import 'package:immersya_mobile_app/api/mock_api_service.dart';
import 'package:immersya_mobile_app/features/auth/services/auth_service.dart';
import 'package:immersya_mobile_app/features/team/state/team_state.dart';
import 'package:immersya_mobile_app/models/capture_point_model.dart';
import 'package:immersya_mobile_app/models/ghost_trace_model.dart';
import 'package:immersya_mobile_app/models/zone_model.dart';
import 'package:latlong2/latlong.dart';

// Enum pour les filtres de la carte
enum MapFilter {
  zones,
  missions,
  currentUser,
  heatmap,
  ghostTraces,
  teammates, // Filtre pour les coéquipiers
}

class MapState with ChangeNotifier {
  // =============================================================
  // DÉPENDANCES ET ÉTAT
  // =============================================================
  MockApiService? _apiService;
  AuthService? _authService;
  TeamState? _teamState;
  StreamSubscription? _teammateLocationSubscription;

  // État des données de la carte
  List<Zone> zones = [];
  List<Mission> missions = [];
  List<CapturePoint> capturePoints = [];
  List<GhostTrace> ghostTraces = [];
  List<UserProfile> teammates = [];
  LatLng? currentUserPosition;

  // État de l'UI
  bool isLoading = false;
  String? error;

  // État des filtres
  final Map<MapFilter, bool> _activeFilters = {
    MapFilter.zones: true,
    MapFilter.missions: true,
    MapFilter.currentUser: true,
    MapFilter.heatmap: false,
    MapFilter.ghostTraces: true,
    MapFilter.teammates: true,
  };

  // =============================================================
  // GETTERS PUBLICS
  // =============================================================
  bool isFilterActive(MapFilter filter) => _activeFilters[filter] ?? false;

  // =============================================================
  // INITIALISATION
  // =============================================================
  void init(MockApiService apiService, AuthService authService, TeamState teamState) {
    _apiService = apiService;
    _authService = authService;
    _teamState = teamState;
    
    // On écoute les changements dans TeamState pour gérer la simulation.
    _teamState?.addListener(_onTeamChanged);
    // On déclenche une première fois pour synchroniser l'état initial.
    _onTeamChanged();
  }

  @override
  void dispose() {
    _teamState?.removeListener(_onTeamChanged);
    unsubscribeFromTeammateLocations();
    super.dispose();
  }
  
  // =============================================================
  // LOGIQUE MÉTIER
  // =============================================================

  /// Charge toutes les données statiques de la carte (zones, missions, etc.).
  Future<void> loadAllMapData() async {
    if (isLoading) return;
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

  /// Méthode pour que l'UI notifie le State de la position de l'utilisateur.
  void updateCurrentUserPosition(LatLng position) {
    currentUserPosition = position;
  }

  /// Active ou désactive un filtre.
  void toggleFilter(MapFilter filter) {
    _activeFilters[filter] = !isFilterActive(filter);
    notifyListeners();
  }

  // =============================================================
  // GESTION DES COÉQUIPIERS EN TEMPS RÉEL
  // =============================================================

  /// Est appelée quand l'utilisateur rejoint ou quitte une équipe.
  void _onTeamChanged() {
    final currentTeam = _teamState?.currentTeam;
    if (currentTeam == null) {
      unsubscribeFromTeammateLocations();
    } else {
      subscribeToTeammateLocations(currentTeam.id);
    }
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