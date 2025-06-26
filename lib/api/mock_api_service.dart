// lib/api/mock_api_service.dart
import 'dart:math';
import 'package:immersya_mobile_app/models/zone_model.dart';
import 'package:latlong2/latlong.dart';
import 'package:immersya_mobile_app/models/capture_point_model.dart';
import 'package:immersya_mobile_app/models/ghost_trace_model.dart';
import 'package:flutter/material.dart';
import 'package:immersya_mobile_app/features/gamification/models/badge_model.dart' as gamification_models;

// ===================================================================
// DÉFINITION DES MODÈLES DE DONNÉES (INCHANGÉ)
// ===================================================================

enum MissionPriority { low, medium, high }

class Mission {
  final String id;
  final String title;
  final String description;
  final int rewardPoints;
  final MissionPriority priority;
  final LatLng location;

  Mission({
    required this.id,
    required this.title,
    required this.description,
    required this.rewardPoints,
    required this.priority,
    required this.location,
  });
}

class UserProfile {
  final String username;
  final String rank;
  final int immersyaPoints;
  final double areaCoveredKm2;
  final int scansValidated;

  UserProfile({
    required this.username,
    required this.rank,
    required this.immersyaPoints,
    required this.areaCoveredKm2,
    required this.scansValidated,
  });
}

enum ContributionStatus { pending, processing, failed, completed }

class ContributionComment {
  final String username;
  final String comment;
  final DateTime date;

  ContributionComment({
    required this.username,
    required this.comment,
    required this.date,
  });
}

class Contribution {
  final String id;
  final String title;
  final DateTime date;
  final String type;
  final ContributionStatus status;
  final int photoCount;
  final String? thumbnailUrl;
  final double qualityScore;
  final List<ContributionComment> comments;
  final String? model3DUrl;

  Contribution({
    required this.id,
    required this.title,
    required this.date,
    required this.type,
    required this.status,
    required this.photoCount,
    this.thumbnailUrl,
    required this.qualityScore,
    required this.comments,
    this.model3DUrl,
  });
}


// ===================================================================
// CLASSE DU SERVICE API MOCKÉ
// ===================================================================

class MockApiService {
  final _random = Random();

  // --- MODIFICATION : Simulation d'une base de données de profils ---
  // La clé est l'ID de l'utilisateur (fourni par AuthService), la valeur est son profil.
  final Map<String, UserProfile> _userProfiles = {
    // Profil pour l'utilisateur de démo (ID '1' dans AuthService)
    '1': UserProfile(
      username: "Pathfinder_Demo",
      rank: "Cartographe de Bronze",
      immersyaPoints: 12540,
      areaCoveredKm2: 2.5,
      scansValidated: 87,
    ),
    // On pourrait ajouter d'autres profils pour d'autres utilisateurs ici.
  };

   Future<List<gamification_models.Badge>> fetchAllBadges() async {
    await Future.delayed(const Duration(milliseconds: 200));
    
    // --- MODIFICATION : On utilise l'alias pour instancier nos badges ---
    return [
      gamification_models.Badge(
        id: 'badge_001',
        name: 'Premiers Pas',
        description: 'Valider votre premier scan.',
        icon: Icons.adjust,
        color: Colors.green,
        unlockCondition: (profile) => profile.scansValidated >= 1,
      ),
      gamification_models.Badge(
        id: 'badge_002',
        name: 'Collectionneur',
        description: 'Atteindre 10,000 Immersya Points.',
        icon: Icons.star,
        color: Colors.amber,
        unlockCondition: (profile) => profile.immersyaPoints >= 10000,
      ),
      gamification_models.Badge(
        id: 'badge_003',
        name: 'Topographe',
        description: 'Couvrir plus de 2 km².',
        icon: Icons.public,
        color: Colors.blue,
        unlockCondition: (profile) => profile.areaCoveredKm2 >= 2.0,
      ),
      gamification_models.Badge(
        id: 'badge_004',
        name: 'Contributeur Vétéran',
        description: 'Valider 50 scans.',
        icon: Icons.military_tech,
        color: Colors.purple,
        unlockCondition: (profile) => profile.scansValidated >= 50,
      ),
      gamification_models.Badge(
        id: 'badge_005',
        name: 'Millionnaire',
        description: 'Devenir une légende avec 1,000,000 de points.',
        icon: Icons.diamond,
        color: Colors.cyanAccent,
        unlockCondition: (profile) => profile.immersyaPoints >= 1000000,
      ),
    ];
  }

  // --- MODIFICATION : La méthode `fetchUserProfile` prend maintenant un `userId` ---
  Future<UserProfile> fetchUserProfile({required String userId}) async {
    print('API: Recherche du profil pour l\'utilisateur ID: $userId');
    await Future.delayed(const Duration(milliseconds: 300));

    if (_userProfiles.containsKey(userId)) {
      // Si l'utilisateur a déjà un profil, on le retourne.
      return _userProfiles[userId]!;
    } else {
      // Sinon (par exemple, pour un nouvel utilisateur qui vient de s'inscrire),
      // on lui crée et retourne un profil par défaut.
      print('API: Aucun profil trouvé pour l\'ID $userId. Création d\'un profil par défaut.');
      final newProfile = UserProfile(
        username: "Nouvelle Recrue", // Ce nom devrait être synchronisé avec AuthService dans un vrai projet
        rank: "Aspirant",
        immersyaPoints: 0,
        areaCoveredKm2: 0.0,
        scansValidated: 0,
      );
      // On le sauvegarde pour les futurs appels.
      _userProfiles[userId] = newProfile;
      return newProfile;
    }
  }

  // --- LE RESTE DE VOS MÉTHODES D'API EST CONSERVÉ À L'IDENTIQUE ---

  Future<List<Zone>> fetchZones() async {
    await Future.delayed(const Duration(milliseconds: 500));
    final statuses = [
      CoverageStatus.modele,
      CoverageStatus.partiel,
      CoverageStatus.en_cours,
      CoverageStatus.non_couvert,
    ];
    const center = LatLng(49.4922, 0.1131);
    final List<Zone> zones = [];
    const double size = 0.001;

    for (int i = -2; i < 3; i++) {
      for (int j = -2; j < 3; j++) {
        final zoneCenterLat = center.latitude + i * size;
        final zoneCenterLng = center.longitude + j * size;
        final polygon = [
          LatLng(zoneCenterLat - size / 2, zoneCenterLng - size / 2),
          LatLng(zoneCenterLat - size / 2, zoneCenterLng + size / 2),
          LatLng(zoneCenterLat + size / 2, zoneCenterLng + size / 2),
          LatLng(zoneCenterLat + size / 2, zoneCenterLng - size / 2),
        ];
        zones.add(Zone(
          id: 'zone_${i}_$j',
          coverageStatus: statuses[_random.nextInt(statuses.length)],
          polygon: polygon,
        ));
      }
    }
    return zones;
  }

  Future<List<Mission>> fetchMissions() async {
    await Future.delayed(const Duration(milliseconds: 600));
    return [
      Mission(
        id: 'mission_001',
        title: 'Scanner la Place Bellecour',
        description: 'Capturez la statue et les façades principales de la place.',
        rewardPoints: 500,
        priority: MissionPriority.high,
        location: const LatLng(45.7578, 4.8324),
      ),
      Mission(
        id: 'mission_002',
        title: 'Documenter le Parc de la Tête d\'Or',
        description: 'Effectuez une capture le long de l\'allée principale.',
        rewardPoints: 350,
        priority: MissionPriority.medium,
        location: const LatLng(45.7797, 4.8536),
      ),
    ];
  }
  
  Future<List<Contribution>> fetchUserContributions() async {
    await Future.delayed(const Duration(milliseconds: 700));
    return [
      Contribution(
        id: 'scan_001',
        title: 'Mission: Scanner la Place Bellecour',
        date: DateTime.now().subtract(const Duration(days: 1)),
        type: 'Mission',
        status: ContributionStatus.completed,
        photoCount: 124,
        thumbnailUrl: 'https://i.imgur.com/8p3hA4g.jpg',
        qualityScore: 4.8,
        comments: [
          ContributionComment(username: "Admin", comment: "Superbe capture, très nette !", date: DateTime.now()),
          ContributionComment(username: "JaneDoe", comment: "Impressionnant !", date: DateTime.now()),
        ],
        model3DUrl: 'https://modelviewer.dev/shared-assets/models/Astronaut.glb',
      ),
      Contribution(
        id: 'scan_002',
        title: 'Scan Libre: Mon Salon',
        date: DateTime.now().subtract(const Duration(days: 2)),
        type: 'Intérieur',
        status: ContributionStatus.processing,
        photoCount: 88,
        thumbnailUrl: 'https://i.imgur.com/uNsfA6m.jpg',
        qualityScore: 0.0,
        comments: [],
        model3DUrl: null,
      ),
    ];
  }

  Future<List<CapturePoint>> fetchCapturePoints() async {
    await Future.delayed(const Duration(milliseconds: 400));
    final zones = await fetchZones();
    final List<CapturePoint> points = [];
    final random = Random();
    for (final zone in zones) {
      int pointCount = 0;
      switch (zone.coverageStatus) {
        case CoverageStatus.modele: pointCount = 100; break;
        case CoverageStatus.partiel: pointCount = 40; break;
        case CoverageStatus.en_cours: pointCount = 15; break;
        case CoverageStatus.non_couvert: pointCount = 2; break;
      }
      for (int i = 0; i < pointCount; i++) {
        points.add(CapturePoint(location: _generateRandomPointInBounds(zone.polygon, random)));
      }
    }
    return points;
  }

  Future<List<GhostTrace>> fetchGhostTraces() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return [
      _generateWavyTrace("trace_1", const LatLng(45.762, 4.845), 20, 0.001),
      _generateWavyTrace("trace_2", const LatLng(45.758, 4.840), 30, 0.0015),
      _generateWavyTrace("trace_3", const LatLng(45.756, 4.848), 15, 0.0008),
    ];
  }

  // --- VOS FONCTIONS UTILITAIRES SONT CONSERVÉES ---

  LatLng _generateRandomPointInBounds(List<LatLng> polygon, Random random) {
    if (polygon.isEmpty) return const LatLng(0, 0);
    double minLat = polygon.first.latitude;
    double maxLat = polygon.first.latitude;
    double minLng = polygon.first.longitude;
    double maxLng = polygon.first.longitude;
    for (var p in polygon) {
      minLat = min(minLat, p.latitude);
      maxLat = max(maxLat, p.latitude);
      minLng = min(minLng, p.longitude);
      maxLng = max(maxLng, p.longitude);
    }
    final lat = minLat + random.nextDouble() * (maxLat - minLat);
    final lng = minLng + random.nextDouble() * (maxLng - minLng);
    return LatLng(lat, lng);
  }

  GhostTrace _generateWavyTrace(String id, LatLng start, int points, double amplitude) {
    final List<LatLng> path = [];
    for (int i = 0; i < points; i++) {
      final lat = start.latitude + (i * 0.0001);
      final lng = start.longitude + (sin(i * 0.5) * amplitude);
      path.add(LatLng(lat, lng));
    }
    return GhostTrace(id: id, path: path);
  }
}