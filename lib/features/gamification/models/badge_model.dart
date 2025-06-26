// lib/features/gamification/models/badge_model.dart

import 'package:flutter/material.dart';
// Assurez-vous d'importer le modèle UserProfile
import 'package:immersya_mobile_app/api/mock_api_service.dart';

class Badge {
  final String id;
  final String name;
  final String description;
  final IconData icon;
  final Color color;
  // La condition de déblocage : une fonction qui prend le profil de l'utilisateur
  // et retourne `true` si le badge est débloqué.
  final bool Function(UserProfile profile) unlockCondition;

  Badge({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.color,
    required this.unlockCondition,
  });
}