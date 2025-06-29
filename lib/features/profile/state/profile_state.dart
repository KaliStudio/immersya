// lib/features/profile/state/profile_state.dart

import 'package:flutter/foundation.dart';
import 'package:immersya_mobile_app/api/mock_api_service.dart';
import 'package:immersya_mobile_app/features/auth/services/auth_service.dart';
import 'package:immersya_mobile_app/features/gamification/models/badge_model.dart' as gamification_models;

class ProfileState with ChangeNotifier {
  MockApiService? _apiService;
  AuthService? _authService;

  UserProfile? _userProfile;
  UserProfile? get userProfile => _userProfile;

  List<gamification_models.Badge> _unlockedBadges = [];
  List<gamification_models.Badge> get unlockedBadges => _unlockedBadges;
  
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;
  
  // La méthode d'initialisation appelée depuis main.dart
  void init(MockApiService apiService, AuthService authService) {
    _apiService = apiService;
    _authService = authService;

    // On écoute les changements dans AuthService pour savoir quand charger/décharger le profil.
    _authService?.addListener(_onAuthChanged);

    // On appelle une première fois au cas où un utilisateur serait déjà connecté au démarrage.
    _onAuthChanged();
  }

  @override
  void dispose() {
    _authService?.removeListener(_onAuthChanged);
    super.dispose();
  }

  // Est appelée à chaque fois que l'utilisateur se connecte ou se déconnecte.
  void _onAuthChanged() {
    final currentUser = _authService?.currentUser;
    // On met simplement à jour le profil local avec celui de AuthService.
    // AuthService est maintenant notre "source de vérité" pour le profil de l'utilisateur connecté.
    if (_userProfile?.id != currentUser?.id) {
       _userProfile = currentUser;
       
       if (_userProfile != null) {
         // Si un utilisateur est connecté, on charge ses badges.
         _loadUnlockedBadges();
       } else {
         // Sinon, on vide la liste des badges.
         _unlockedBadges = [];
       }
       notifyListeners();
    }
  }

  // Charge les badges et vérifie lesquels sont débloqués par l'utilisateur.
  Future<void> _loadUnlockedBadges() async {
    if (_userProfile == null || _apiService == null) return;
    
    _isLoading = true;
    notifyListeners();

    try {
      final allBadges = await _apiService!.fetchAllBadges();
      // On filtre la liste pour ne garder que les badges dont la condition est remplie par le profil de l'utilisateur.
      _unlockedBadges = allBadges.where((badge) => badge.unlockCondition(_userProfile!)).toList();
    } catch (e) {
      _error = "Erreur lors du chargement des badges: $e";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}