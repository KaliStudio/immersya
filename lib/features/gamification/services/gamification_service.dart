// lib/features/gamification/services/gamification_service.dart
import 'package:immersya_mobile_app/api/mock_api_service.dart';
import 'package:immersya_mobile_app/features/gamification/models/badge_model.dart' as gamification_models;

class GamificationService {
  final MockApiService _apiService;

  GamificationService(this._apiService);

  // --- MODIFICATION : La signature de la méthode utilise l'alias ---
  Future<List<gamification_models.Badge>> getUnlockedBadges(UserProfile userProfile) async {
    // 1. Récupérer tous les badges possibles. La liste sera de type `List<gamification_models.Badge>`
    final allBadges = await _apiService.fetchAllBadges();
    
    // --- MODIFICATION : Logique de filtrage plus explicite pour éviter l'erreur de type ---
    // On crée une liste vide du bon type...
    final List<gamification_models.Badge> unlockedBadges = [];

    // ...et on la remplit avec une boucle `for` classique, ce qui est sans ambiguïté pour le compilateur.
    for (final badge in allBadges) {
      if (badge.unlockCondition(userProfile)) {
        unlockedBadges.add(badge);
      }
    }
    return unlockedBadges;
  }
}