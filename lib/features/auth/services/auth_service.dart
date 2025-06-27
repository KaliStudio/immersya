// lib/features/auth/services/auth_service.dart

import 'package:flutter/foundation.dart';
import 'package:immersya_mobile_app/models/user_model.dart';

class AuthService with ChangeNotifier {
  // Une liste "en mémoire" pour simuler notre base de données d'utilisateurs.
  final List<User> _users = [];
  
  // L'utilisateur actuellement connecté. `_` le rend privé.
  User? _currentUser;

  // Un getter public pour que l'UI puisse accéder à l'utilisateur.
  User? get currentUser => _currentUser;
  
  // Un getter pratique pour savoir si on est authentifié.
  bool get isAuthenticated => _currentUser != null;

  AuthService() {
    // On crée un utilisateur de démo au démarrage pour faciliter les tests.
    _users.add(User(id: '1', username: 'Pathfinder_Demo', email: 'demo@immersya.com'));
  }

  // Simule une tentative de connexion.
  Future<bool> login(String email, String password) async {
    // En production, vous feriez un appel API ici.
    // Pour notre simulation, on vérifie juste si l'email existe.
    await Future.delayed(const Duration(seconds: 1)); // Simule une latence réseau
    
    try {
      final user = _users.firstWhere((u) => u.email == email);
      _currentUser = user;
      //print('✅ Utilisateur connecté : ${_currentUser!.username}');
      notifyListeners(); // Notifie tous les écouteurs que l'état a changé !
      return true;
    } catch (e) {
      //print('❌ Échec de la connexion : utilisateur non trouvé.');
      return false;
    }
  }

  // Simule une inscription.
  Future<bool> register(String username, String email, String password) async {
    await Future.delayed(const Duration(seconds: 1));
    
    // On vérifie si l'email n'est pas déjà pris.
    if (_users.any((u) => u.email == email)) {
      //print('❌ Échec de l\'inscription : email déjà utilisé.');
      return false;
    }
    
    // On crée le nouvel utilisateur.
    final newUser = User(
      id: DateTime.now().millisecondsSinceEpoch.toString(), // ID unique simple
      username: username,
      email: email,
    );
    _users.add(newUser);
    
    // On connecte automatiquement l'utilisateur après l'inscription.
    _currentUser = newUser;
    //print('✅ Utilisateur inscrit et connecté : ${_currentUser!.username}');
    notifyListeners();
    return true;
  }
  
  // Déconnexion.
  Future<void> logout() async {
    _currentUser = null;
    //print('🚪 Utilisateur déconnecté.');
    notifyListeners();
  }
}