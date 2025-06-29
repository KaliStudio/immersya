// lib/features/auth/services/auth_service.dart

import 'package:flutter/foundation.dart';
import 'package:immersya_mobile_app/api/mock_api_service.dart';

class AuthService with ChangeNotifier {
  MockApiService? _apiService;

  UserProfile? _currentUser;
  UserProfile? get currentUser => _currentUser;

  bool get isAuthenticated => _currentUser != null;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  void init(MockApiService apiService) {
    _apiService = apiService;
  }

  Future<bool> login(String emailOrUsername, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final user = await _apiService!.login(emailOrUsername, password);
      if (user == null) {
        throw Exception("Nom d'utilisateur ou mot de passe incorrect.");
      }
      
      // On récupère le profil complet (même si login le fait déjà dans notre mock)
      _currentUser = await _apiService!.fetchUserProfile(userId: user.id);
      
      _isLoading = false;
      notifyListeners();
      return true;

    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
  
  Future<bool> register(String email, String username, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      // Dans une vraie app, l'API utiliserait ces 3 informations pour créer un nouvel utilisateur.
      // Ici, on va simuler la création.
      // Le MockApiService n'a pas de méthode register, on va la simuler ici.
      // Il faudrait ajouter une logique dans le mock pour vraiment créer l'utilisateur,
      // mais pour l'instant on se contente de logger et de connecter.
      
      debugPrint("Simulation d'inscription pour: $email, $username");

      // Simuler une attente réseau pour l'inscription
      await Future.delayed(const Duration(seconds: 1));
      
      // Après l'inscription, on connecte directement l'utilisateur.
      // On se connecte avec le username, comme le fait notre méthode login.
      return await login(username, password);

    } catch (e) {
      _error = "Erreur lors de l'inscription: $e";
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
  
  Future<void> refreshCurrentUser() async {
    if (_currentUser == null) return;
    _currentUser = await _apiService!.fetchUserProfile(userId: _currentUser!.id);
    notifyListeners();
  }

  Future<void> logout() async {
    _currentUser = null;
    notifyListeners();
  }
}