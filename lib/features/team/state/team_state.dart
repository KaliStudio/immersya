// lib/features/team/state/team_state.dart

import 'package:flutter/foundation.dart';
import 'package:immersya_mobile_app/api/mock_api_service.dart';
import 'package:immersya_mobile_app/features/auth/services/auth_service.dart';
import 'package:immersya_mobile_app/models/team_model.dart';

class TeamState with ChangeNotifier {
  // =============================================================
  // DÉPENDANCES ET ÉTAT
  // =============================================================
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
  
  // =============================================================
  // INITIALISATION ET NETTOYAGE
  // =============================================================
  void init(MockApiService apiService, AuthService authService) {
    _apiService = apiService;
    _authService = authService;
    _authService?.addListener(_onAuthChanged);
    // On charge les données initiales au cas où l'utilisateur serait déjà connecté.
    _onAuthChanged();
  }

  @override
  void dispose() {
    _authService?.removeListener(_onAuthChanged);
    super.dispose();
  }

  // =============================================================
  // LOGIQUE DE SYNCHRONISATION
  // =============================================================

  /// Réagit aux changements de l'état de connexion de l'utilisateur.
// dans lib/features/team/state/team_state.dart

  /// Réagit aux changements de l'état de connexion de l'utilisateur.
  Future<void> _onAuthChanged() async {
    final user = _authService?.currentUser;

    // Cas 1 : L'utilisateur n'est pas connecté ou n'a pas d'équipe.
    if (user == null || user.teamId == null) {
      // On ne change l'état que si l'utilisateur *avait* une équipe avant.
      if (_currentTeam != null) {
        _currentTeam = null;
        _members = [];
        notifyListeners(); // Notifie SEULEMENT s'il y a un vrai changement.
      }
      return;
    }
    
    // Cas 2 : L'utilisateur a une équipe.
    // On ne recharge les données que si l'ID de l'équipe a changé.
    if (_currentTeam?.id != user.teamId) {
      await fetchTeamDetails(user.teamId!);
    }
  }

  // =============================================================
  // ACTIONS UTILISATEUR
  // =============================================================

  /// Récupère les détails de l'équipe et de ses membres depuis l'API.
  Future<void> fetchTeamDetails(String teamId) async {
    if (_apiService == null) return;
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

  /// Fait quitter l'équipe à l'utilisateur actuel.
Future<void> leaveTeam() async {
    final userId = _authService?.currentUser?.id;
    // On vérifie que les dépendances sont là.
    if (userId == null || _apiService == null || _authService == null) return;
    
    // On ne gère plus isLoading ici. On délègue TOUT au AuthService.
    // L'UI peut écouter authService.isLoading pour afficher un spinner.
    
    // 1. On appelle l'API pour quitter l'équipe.
    await _apiService!.leaveTeam(userId);
    
    // 2. On demande au AuthService de se rafraîchir. C'est LUI qui va notifier
    //    toute l'application du changement d'état (utilisateur sans équipe)
    //    et gérer son propre état de chargement.
    await _authService!.refreshCurrentUser();

    // On ne fait RIEN d'autre. Pas de `notifyListeners` ici.
  }

  /// Crée une nouvelle équipe et y fait adhérer l'utilisateur actuel.
  Future<bool> createTeam(String name, String tag) async {
    final userId = _authService?.currentUser?.id;
    if (userId == null || _apiService == null || _authService == null) return false;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final newTeam = await _apiService!.createTeam(name, tag, userId);
      if (newTeam != null) {
        // Le créateur rejoint automatiquement. On rafraîchit son profil.
        await _authService!.refreshCurrentUser();
        return true;
      }
      return false;
    } catch (e) {
      _error = "Erreur lors de la création de l'équipe : $e";
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Fait rejoindre une équipe existante à l'utilisateur actuel.
  Future<void> joinTeam(String teamId) async {
    final userId = _authService?.currentUser?.id;
    if (userId == null || _apiService == null || _authService == null) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _apiService!.joinTeam(userId, teamId);
      await _authService!.refreshCurrentUser();
    } catch (e) {
      _error = "Erreur pour rejoindre l'équipe : $e";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Exclut un membre d'une équipe (action réservée au créateur).
  Future<void> excludeMember(String memberId) async {
    if (_currentTeam == null || _apiService == null) return;
    
    // On pourrait ajouter une vérification ici pour s'assurer que l'utilisateur actuel est bien le créateur.
    final isCreator = _authService?.currentUser?.id == _currentTeam!.creatorId;
    if (!isCreator) {
      _error = "Seul le créateur peut exclure un membre.";
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _apiService!.excludeMember(memberId, _currentTeam!.id);
      // Après l'exclusion, on rafraîchit simplement les détails de l'équipe pour voir la liste des membres à jour.
      await fetchTeamDetails(_currentTeam!.id);
    } catch (e) {
      _error = "Erreur lors de l'exclusion du membre: $e";
      // `fetchTeamDetails` gère la fin du chargement, donc pas de `finally` ici.
    }
  }

    Future<bool> updateTeamDetails(String newName, String newDescription) async {
    if (_currentTeam == null || _apiService == null) return false;

    // On pourrait ajouter une vérification pour s'assurer que l'utilisateur est le créateur
    final isCreator = _authService?.currentUser?.id == _currentTeam!.creatorId;
    if (!isCreator) {
      _error = "Seul le créateur peut modifier l'équipe.";
      notifyListeners();
      return false;
    }

    _isLoading = true;
    notifyListeners();

    try {
      final updatedTeam = await _apiService!.updateTeamDetails(_currentTeam!.id, newName, newDescription);
      if (updatedTeam != null) {
        // On met à jour directement l'état local pour une réactivité parfaite
        _currentTeam = updatedTeam;
        _isLoading = false;
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _error = "Erreur de mise à jour: $e";
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}