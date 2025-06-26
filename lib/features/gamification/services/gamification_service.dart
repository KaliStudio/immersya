// lib/features/gamification/services/gamification_service.dart

import 'package:collection/collection.dart';
import 'package:geocoding/geocoding.dart';
import 'package:immersya_mobile_app/api/mock_api_service.dart';
import 'package:immersya_mobile_app/features/gamification/models/badge_model.dart' as gamification_models;

class GamificationService {
  final MockApiService _apiService;

  GamificationService(this._apiService);

  // Votre méthode existante pour obtenir les badges. Elle est déjà correcte.
  Future<List<gamification_models.Badge>> getUnlockedBadges(UserProfile userProfile) async {
    final allBadges = await _apiService.fetchAllBadges();
    
    final List<gamification_models.Badge> unlockedBadges = [];
    for (final badge in allBadges) {
      if (badge.unlockCondition(userProfile)) {
        unlockedBadges.add(badge);
      }
    }
    
    return unlockedBadges;
  }

  Future<Map<String, String?>> determinePrimaryLocation(String userId, {int recentDays = 30}) async {
    final history = await _apiService.fetchCaptureHistory(userId);
    final recentHistory = history.where((r) => r.timestamp.isAfter(DateTime.now().subtract(Duration(days: recentDays)))).toList();

    if (recentHistory.isEmpty) return {};

    final List<Placemark> placemarks = [];
    for (final record in recentHistory) {
      try {
        List<Placemark> p = await placemarkFromCoordinates(record.location.latitude, record.location.longitude);
        if (p.isNotEmpty) placemarks.add(p.first);
      } catch (e) { /* ignore */ }
    }

    if (placemarks.isEmpty) return {};

    // Helper pour trouver la valeur la plus fréquente
    String? getMostFrequent(Iterable<String?> items) {
      if (items.isEmpty) return null;
      return groupBy(items, (item) => item).entries.sortedBy<num>((e) => -e.value.length).first.key;
    }

    String? bestRegion(Placemark p) {
      if (p.administrativeArea != null && p.administrativeArea!.isNotEmpty) return p.administrativeArea;
      if (p.subAdministrativeArea != null && p.subAdministrativeArea!.isNotEmpty) return p.subAdministrativeArea;
      return null;
    }

    return {
      'city': getMostFrequent(placemarks.map((p) => p.locality)),
      'region': getMostFrequent(placemarks.map(bestRegion)), // On utilise notre logique
      'country': getMostFrequent(placemarks.map((p) => p.country)),
    };
  }
}