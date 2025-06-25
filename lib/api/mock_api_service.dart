// lib/api/mock_api_service.dart
import 'dart:math';
import 'package:immersya_mobile_app/models/zone_model.dart';
import 'package:latlong2/latlong.dart';

// ===================================================================
// DÉFINITION DES MODÈLES DE DONNÉES
// ===================================================================

enum MissionPriority { low, medium, high }

class Mission {
  final String id;
  final String title;
  final String description;
  final int rewardPoints;
  final MissionPriority priority;
  final LatLng location; // CHAMP AJOUTÉ

  Mission({
    required this.id,
    required this.title,
    required this.description,
    required this.rewardPoints,
    required this.priority,
    required this.location, // CHAMP AJOUTÉ
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

  Future<UserProfile> fetchUserProfile() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return UserProfile(
      username: "Pathfinder_01",
      rank: "Cartographe de Bronze",
      immersyaPoints: 12540,
      areaCoveredKm2: 2.5,
      scansValidated: 87,
    );
  }

  // --- VERSION MODIFIÉE DE fetchMissions ---
  Future<List<Mission>> fetchMissions() async {
    await Future.delayed(const Duration(milliseconds: 600));
    return [
      Mission(
        id: 'mission_001',
        title: 'Scanner la Place Bellecour',
        description: 'Capturez la statue et les façades principales de la place.',
        rewardPoints: 500,
        priority: MissionPriority.high,
        location: const LatLng(45.7578, 4.8324), // Coordonnées ajoutées
      ),
      Mission(
        id: 'mission_002',
        title: 'Documenter le Parc de la Tête d\'Or',
        description: 'Effectuez une capture le long de l\'allée principale.',
        rewardPoints: 350,
        priority: MissionPriority.medium,
        location: const LatLng(45.7797, 4.8536), // Coordonnées ajoutées
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
}