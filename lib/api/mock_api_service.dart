// lib/api/mock_api_service.dart

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:immersya_mobile_app/features/gamification/models/badge_model.dart' as gamification_models;
import 'package:immersya_mobile_app/models/capture_point_model.dart';
import 'package:immersya_mobile_app/models/ghost_trace_model.dart';
import 'package:immersya_mobile_app/models/zone_model.dart';
import 'package:latlong2/latlong.dart';

// ===================================================================
// DÉFINITION DES MODÈLES DE DONNÉES
// ===================================================================

enum MissionPriority { low, medium, high }

class Mission {
  final String id, title, description;
  final int rewardPoints;
  final MissionPriority priority;
  final LatLng location;

  Mission({
    required this.id, required this.title, required this.description,
    required this.rewardPoints, required this.priority, required this.location,
  });
}

// MODIFIÉ : UserProfile stocke maintenant une localisation détaillée (pays, région, ville)
class UserProfile {
  final String username, rank;
  final int immersyaPoints, scansValidated;
  final double areaCoveredKm2;
  final String? country, region, city;

  UserProfile({
    required this.username, required this.rank, required this.immersyaPoints,
    required this.areaCoveredKm2, required this.scansValidated,
    this.country, this.region, this.city,
  });

  // Helper pratique pour créer une copie d'un profil avec des valeurs modifiées.
  UserProfile copyWith({
    String? username, String? rank, int? immersyaPoints, double? areaCoveredKm2,
    int? scansValidated, String? country, String? region, String? city,
  }) {
    return UserProfile(
      username: username ?? this.username,
      rank: rank ?? this.rank,
      immersyaPoints: immersyaPoints ?? this.immersyaPoints,
      areaCoveredKm2: areaCoveredKm2 ?? this.areaCoveredKm2,
      scansValidated: scansValidated ?? this.scansValidated,
      country: country ?? this.country,
      region: region ?? this.region,
      city: city ?? this.city,
    );
  }
}

// NOUVEAU : Modèle pour enregistrer une capture dans l'historique
class CaptureRecord {
  final String userId;
  final LatLng location;
  final DateTime timestamp;
  CaptureRecord({required this.userId, required this.location, required this.timestamp});
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
    required this.id, required this.title, required this.date,
    required this.type, required this.status, required this.photoCount,
    this.thumbnailUrl, required this.qualityScore, required this.comments,
    this.model3DUrl,
  });
}

// ===================================================================
// CLASSE DU SERVICE API MOCKÉ
// ===================================================================

class MockApiService {
  final _random = Random();

  // --- BASES DE DONNÉES FICTIVES ---
  final Map<String, UserProfile> _userProfiles = {
    '1': UserProfile(username: "Pathfinder_Demo", rank: "Cartographe de Bronze", immersyaPoints: 12540, areaCoveredKm2: 2.5, scansValidated: 87, country: "Japon", region: "Kantō", city: "Tokyo"),
    '2': UserProfile(username: "MagicArtistes", rank: "Maître des Données", immersyaPoints: 56200, areaCoveredKm2: 12.1, scansValidated: 312, country: "France", region: "Normandie", city: "Le Havre"),
    '3': UserProfile(username: "PixelPioneer", rank: "Architecte Virtuel", immersyaPoints: 31050, areaCoveredKm2: 7.8, scansValidated: 154, country: "France", region: "Île-de-France", city: "Paris"),
    '4': UserProfile(username: "SkyScanner", rank: "Explorateur d'Argent", immersyaPoints: 21800, areaCoveredKm2: 4.2, scansValidated: 99, country: "France", region: "Auvergne-Rhône-Alpes", city: "Lyon"),
    '5': UserProfile(username: "NewbieMapper", rank: "Recrue", immersyaPoints: 500, areaCoveredKm2: 0.1, scansValidated: 5, country: "France", region: "Île-de-France", city: "Paris"),
  };

  final List<CaptureRecord> _captureHistory = [];

  // --- NOUVELLES MÉTHODES POUR LA STRATÉGIE B ---
  
  Future<void> logCapture(String userId, LatLng location) async {
    await Future.delayed(const Duration(milliseconds: 100));
    _captureHistory.add(CaptureRecord(userId: userId, location: location, timestamp: DateTime.now()));
    //print("API: Capture enregistrée pour l'utilisateur $userId");
  }

  Future<List<CaptureRecord>> fetchCaptureHistory(String userId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _captureHistory.where((record) => record.userId == userId).toList();
  }

  Future<void> updateMockUserLocation(String userId, {String? country, String? region, String? city}) async {
    if (_userProfiles.containsKey(userId)) {
      _userProfiles[userId] = _userProfiles[userId]!.copyWith(country: country, region: region, city: city);
      //print("API: Profil $userId mis à jour -> Pays: $country, Région: $region, Ville: $city");
    }
  }

  // --- MÉTHODES EXISTANTES MODIFIÉES OU CONSERVÉES ---

  Future<List<UserProfile>> fetchAllUserProfiles({String? country, String? region, String? city}) async {
    await Future.delayed(const Duration(milliseconds: 700));
    var allProfiles = _userProfiles.values;
    if (city != null) return allProfiles.where((p) => p.city == city).toList();
    if (region != null) return allProfiles.where((p) => p.region == region).toList();
    if (country != null) return allProfiles.where((p) => p.country == country).toList();
    return allProfiles.toList();
  }

  Future<List<gamification_models.Badge>> fetchAllBadges() async {
    await Future.delayed(const Duration(milliseconds: 200));
    return [
      gamification_models.Badge(id: 'badge_001', name: 'Premiers Pas', description: 'Valider votre premier scan.', icon: Icons.adjust, color: Colors.green, unlockCondition: (profile) => profile.scansValidated >= 1),
      gamification_models.Badge(id: 'badge_002', name: 'Collectionneur', description: 'Atteindre 10,000 Immersya Points.', icon: Icons.star, color: Colors.amber, unlockCondition: (profile) => profile.immersyaPoints >= 10000),
      gamification_models.Badge(id: 'badge_003', name: 'Topographe', description: 'Couvrir plus de 2 km².', icon: Icons.public, color: Colors.blue, unlockCondition: (profile) => profile.areaCoveredKm2 >= 2.0),
      gamification_models.Badge(id: 'badge_004', name: 'Contributeur Vétéran', description: 'Valider 50 scans.', icon: Icons.military_tech, color: Colors.purple, unlockCondition: (profile) => profile.scansValidated >= 50),
      gamification_models.Badge(id: 'badge_005', name: 'Millionnaire', description: 'Devenir une légende avec 1,000,000 de points.', icon: Icons.diamond, color: Colors.cyanAccent, unlockCondition: (profile) => profile.immersyaPoints >= 1000000),
    ];
  }

  Future<UserProfile> fetchUserProfile({required String userId}) async {
    await Future.delayed(const Duration(milliseconds: 600));
    if (_userProfiles.containsKey(userId)) return _userProfiles[userId]!;
    
    final newProfile = UserProfile(
      username: "Nouvelle Recrue", 
      rank: "Aspirant", 
      immersyaPoints: 0, 
      areaCoveredKm2: 0.0, 
      scansValidated: 0,
      country: null, region: null, city: null,
    );
    _userProfiles[userId] = newProfile;
    return newProfile;
  }

  Future<List<Zone>> fetchZones() async {
    await Future.delayed(const Duration(milliseconds: 500));
    final statuses = [CoverageStatus.modele, CoverageStatus.partiel, CoverageStatus.enCours, CoverageStatus.nonCouvert];
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
        zones.add(Zone(id: 'zone_${i}_$j', coverageStatus: statuses[_random.nextInt(statuses.length)], polygon: polygon));
      }
    }
    return zones;
  }

  Future<List<Mission>> fetchMissions() async {
    await Future.delayed(const Duration(milliseconds: 600));
    return [
      Mission(id: 'mission_001', title: 'Scanner la Place Bellecour', description: 'Capturez la statue et les façades principales de la place.', rewardPoints: 500, priority: MissionPriority.high, location: const LatLng(45.7578, 4.8324)),
      Mission(id: 'mission_002', title: 'Documenter le Parc de la Tête d\'Or', description: 'Effectuez une capture le long de l\'allée principale.', rewardPoints: 350, priority: MissionPriority.medium, location: const LatLng(45.7797, 4.8536)),
    ];
  }
  
  Future<List<Contribution>> fetchUserContributions() async {
    await Future.delayed(const Duration(milliseconds: 700));
    return [
      Contribution(id: 'scan_001', title: 'Mission: Scanner la Place Bellecour', date: DateTime.now().subtract(const Duration(days: 1)), type: 'Mission', status: ContributionStatus.completed, photoCount: 124, thumbnailUrl: 'https://i.imgur.com/8p3hA4g.jpg', qualityScore: 4.8, comments: [ContributionComment(username: "Admin", comment: "Superbe capture, très nette !", date: DateTime.now()), ContributionComment(username: "JaneDoe", comment: "Impressionnant !", date: DateTime.now())], model3DUrl: 'https://modelviewer.dev/shared-assets/models/Astronaut.glb'),
      Contribution(id: 'scan_002', title: 'Scan Libre: Mon Salon', date: DateTime.now().subtract(const Duration(days: 2)), type: 'Intérieur', status: ContributionStatus.processing, photoCount: 88, thumbnailUrl: 'https://i.imgur.com/uNsfA6m.jpg', qualityScore: 0.0, comments: [], model3DUrl: null),
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
        case CoverageStatus.enCours: pointCount = 15; break;
        case CoverageStatus.nonCouvert: pointCount = 2; break;
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