// lib/features/team/state/team_state.dart

import 'package:flutter/foundation.dart';
import 'package:immersya_mobile_app/api/mock_api_service.dart';
import 'package:immersya_mobile_app/features/auth/services/auth_service.dart';

// NOUVEAUX IMPORTS POUR RÉSOUDRE LES ERREURS
import 'package:immersya_mobile_app/models/team_model.dart';
// NOTE: L'import de UserProfile vient directement de mock_api_service.dart,
// mais si vous le sortez dans son propre fichier, il faudra l'importer aussi.

class TeamState with ChangeNotifier {
  MockApiService? _apiService;
  AuthService? _authService;

  Team? _currentTeam;
  Team? get currentTeam => _currentTeam;

  List<UserProfile> _members = [];
  List<UserProfile> get members => _members;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;
  
  void init(MockApiService apiService, AuthService authService) {
    _apiService = apiService;
    _authService = authService;
    _authService?.addListener(_onAuthChanged);
    _onAuthChanged();
  }

  @override
  void dispose() {
    _authService?.removeListener(_onAuthChanged);
    super.dispose();
  }

  Future<void> _onAuthChanged() async {
    // CORRECTION : On s'assure d'utiliser UserProfile ici.
    final user = _authService?.currentUser;
    if (user == null || user.teamId == null) {
      if (_currentTeam != null || _members.isNotEmpty) {
        _currentTeam = null;
        _members = [];
        notifyListeners();
      }
      return;
    }
    
    // Si l'équipe a changé, on la recharge.
    if (_currentTeam?.id != user.teamId) {
      await fetchTeamDetails(user.teamId!);
    }
  }

  Future<void> fetchTeamDetails(String teamId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        _apiService!.fetchTeamDetails(teamId),
        _apiService!.fetchTeamMembers(teamId),
      ]);
      
      _currentTeam = results[0] as Team?;
      _members = results[1] as List<UserProfile>;

    } catch (e) {
      _error = "Erreur lors de la récupération de l'équipe : $e";
      _currentTeam = null;
      _members = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> leaveTeam() async {
    final userId = _authService?.currentUser?.id;
    if (userId == null) return;
    
    // On met à jour l'UI immédiatement pour une meilleure réactivité
    _isLoading = true;
    notifyListeners();

    await _apiService!.leaveTeam(userId);
    
    // Après avoir quitté, on met à jour l'état d'authentification qui déclenchera _onAuthChanged
    await _authService!.refreshCurrentUser();
    
    _isLoading = false;
    notifyListeners();
  }
}