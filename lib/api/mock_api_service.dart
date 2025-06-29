// lib/api/mock_api_service.dart

import 'dart:async'; // Ajout nécessaire pour StreamController et Timer
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:immersya_mobile_app/features/gamification/models/badge_model.dart' as gamification_models;
import 'package:immersya_mobile_app/models/capture_point_model.dart';
import 'package:immersya_mobile_app/models/ghost_trace_model.dart';
import 'package:immersya_mobile_app/models/team_model.dart';
import 'package:immersya_mobile_app/models/zone_model.dart';
import 'package:latlong2/latlong.dart';

// ===================================================================
// DÉFINITION DES MODÈLES (INCHANGÉ)
// ===================================================================

enum MissionPriority { low, medium, high }

class Mission {
  final String id, title, description;
  final int rewardPoints;
  final MissionPriority priority;
  final LatLng location;
  Mission({required this.id, required this.title, required this.description, required this.rewardPoints, required this.priority, required this.location});
}

class UserProfile {
  final String id;
  final String username, rank;
  final String? email;
  final int immersyaPoints, scansValidated;
  final double areaCoveredKm2;
  final String? country, region, city, teamId;
  LatLng? lastKnownPosition;
  bool isCapturing;
  double captureRadius;

  UserProfile({
    required this.id, required this.username, required this.rank, this.email, required this.immersyaPoints,
    required this.areaCoveredKm2, required this.scansValidated,
    this.country, this.region, this.city, this.teamId, this.lastKnownPosition,
    this.isCapturing = false,
    this.captureRadius = 25.0,
  });

  UserProfile copyWith({
    String? id, String? username, String? rank, int? immersyaPoints, double? areaCoveredKm2,
    int? scansValidated, String? country, String? region, String? city,
    ValueGetter<String?>? teamId, ValueGetter<LatLng?>? lastKnownPosition,
    bool? isCapturing,
    double? captureRadius,
  }) => UserProfile(
      id: id ?? this.id,
      username: username ?? this.username, rank: rank ?? this.rank,
      immersyaPoints: immersyaPoints ?? this.immersyaPoints,
      areaCoveredKm2: areaCoveredKm2 ?? this.areaCoveredKm2,
      scansValidated: scansValidated ?? this.scansValidated,
      country: country ?? this.country, region: region ?? this.region, city: city ?? this.city,
      teamId: teamId != null ? teamId() : this.teamId,
      lastKnownPosition: lastKnownPosition != null ? lastKnownPosition() : this.lastKnownPosition,
      isCapturing: isCapturing ?? this.isCapturing,
      captureRadius: captureRadius ?? this.captureRadius,
  );
}

class CaptureRecord {
  final String userId; final LatLng location; final DateTime timestamp;
  CaptureRecord({required this.userId, required this.location, required this.timestamp});
}

enum ContributionStatus { pending, processing, failed, completed }
class ContributionComment {
  final String username, comment;
  final DateTime date;
  ContributionComment({required this.username, required this.comment, required this.date});
}
class Contribution {
  final String id, title, type;
  final DateTime date; final ContributionStatus status; final int photoCount;
  final String? thumbnailUrl, model3DUrl;
  final double qualityScore;
  final List<ContributionComment> comments;
  Contribution({required this.id, required this.title, required this.date, required this.type, required this.status, required this.photoCount, this.thumbnailUrl, required this.qualityScore, required this.comments, this.model3DUrl});
}

// ===================================================================
// CLASSE DU SERVICE API MOCKÉ
// ===================================================================

class MockApiService {
  MockApiService() {
    // Le constructeur est un bon endroit pour initialiser des choses si nécessaire.
  }

  final _random = Random();

  // --- BASES DE DONNÉES FICTIVES (INCHANGÉES) ---
   final Map<String, Team> _teams = {
    'team_alpha': Team(id: 'team_alpha', name: 'Alpha Scanners', tag: '[ALPHA]', description: 'Pionniers de la capture 3D.', bannerUrl: 'https://i.imgur.com/example_banner_1.png', creatorId: '1'),
    'team_delta': Team(id: 'team_delta', name: 'Delta Force 3D', tag: '[DELTA]', description: 'Précision et efficacité.', bannerUrl: 'https://i.imgur.com/example_banner_2.png', creatorId: '2'),
  };
  final Map<String, UserProfile> _userProfiles = {
    'demo-user': UserProfile(id: 'demo-user', username: "demo_user", email: "demo@immersya.com", rank: "Testeur", immersyaPoints: 100, areaCoveredKm2: 0, scansValidated: 1, teamId: null),
    '1': UserProfile(id: '1', username: "MagicArtistes", rank: "Cartographe de Bronze", immersyaPoints: 12540, areaCoveredKm2: 2.5, scansValidated: 87, country: "France", region: "Normandie", city: "Le Havre", teamId: 'team_alpha', lastKnownPosition: const LatLng(49.49, 0.10)),
    '2': UserProfile(id: '2', username: "GeoNinja", rank: "Maître des Données", immersyaPoints: 56200, areaCoveredKm2: 12.1, scansValidated: 312, country: "Japon", region: "Kantō", city: "Tokyo", teamId: 'team_delta'),
    '3': UserProfile(id: '3', username: "PixelPioneer", rank: "Architecte Virtuel", immersyaPoints: 31050, areaCoveredKm2: 7.8, scansValidated: 154, country: "France", region: "Normandie", city: "Le Havre", teamId: 'team_alpha', lastKnownPosition: const LatLng(49.50, 0.12)),
    '4': UserProfile(id: '4', username: "SkyScanner", rank: "Explorateur d'Argent", immersyaPoints: 21800, areaCoveredKm2: 4.2, scansValidated: 99, country: "France", region: "Auvergne-Rhône-Alpes", city: "Lyon", lastKnownPosition: const LatLng(45.76, 4.83)),
    '5': UserProfile(id: '5', username: "NewbieMapper", rank: "Recrue", immersyaPoints: 500, areaCoveredKm2: 0.1, scansValidated: 5, country: "France", region: "Île-de-France", city: "Paris", teamId: 'team_alpha', lastKnownPosition: const LatLng(48.85, 2.35)),
  };
  final List<CaptureRecord> _captureHistory = [
    CaptureRecord(userId: '1', location: const LatLng(49.491, 0.105), timestamp: DateTime.now()),
    CaptureRecord(userId: '1', location: const LatLng(49.492, 0.106), timestamp: DateTime.now()),
    CaptureRecord(userId: '3', location: const LatLng(49.501, 0.121), timestamp: DateTime.now()),
    CaptureRecord(userId: '3', location: const LatLng(49.502, 0.122), timestamp: DateTime.now()),
    CaptureRecord(userId: '2', location: const LatLng(48.861, 2.338), timestamp: DateTime.now()),
  ];

  List<Zone>? _zonesCache;

  Future<List<CaptureRecord>> fetchTeamCaptureHistory(String teamId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final team = _teams[teamId];
    if (team == null) return [];
    final memberIds = _userProfiles.values.where((p) => p.teamId == teamId).map((p) => p.id).toSet();
    return _captureHistory.where((record) => memberIds.contains(record.userId)).toList();
  }

  Future<UserProfile?> login(String emailOrUsername, String password) async {
    await Future.delayed(const Duration(seconds: 1));
    try {
      // Cherche un utilisateur dont le username OU l'email correspond.
      return _userProfiles.values.firstWhere(
        (user) => user.username.toLowerCase() == emailOrUsername.toLowerCase() || 
                (user.email != null && user.email!.toLowerCase() == emailOrUsername.toLowerCase())
      );
    } catch (e) {
      return null;
    }
  }

  // ===================================================================
  // NOUVELLE SECTION : LOGIQUE DE SIMULATION EN TEMPS RÉEL
  // ===================================================================

  // Un StreamController pour diffuser les mises à jour de profils utilisateurs (qui contiendront les nouvelles positions)
  final _teammateLocationController = StreamController<List<UserProfile>>.broadcast();
  Timer? _simulationTimer;

  // Un getter public pour que les Providers puissent s'abonner au flux.
  Stream<List<UserProfile>> get teammateLocationStream => _teammateLocationController.stream;

  /// Démarre la simulation de mouvement pour les membres d'une équipe donnée.
  void startTeamLocationSimulation(String teamId) {
    // Arrête toute simulation précédente pour éviter les conflits.
    stopTeamLocationSimulation();

    final team = _teams[teamId];
    if (team == null) {
      debugPrint("[MockApiService] Simulation annulée : équipe $teamId non trouvée.");
      return;
    }
    
    // Récupère la liste des profils des membres de l'équipe
    final teammates = _userProfiles.values.where((p) => p.teamId == teamId).toList();
    
    debugPrint("[MockApiService] Démarrage de la simulation pour l'équipe '${team.name}'.");

    // Démarre un Timer qui s'exécute toutes les 3 secondes.
    _simulationTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      for (var teammate in teammates) {
        // On récupère la position actuelle. Si elle est nulle, on en choisit une par défaut.
        final currentLat = teammate.lastKnownPosition?.latitude ?? 48.858;
        final currentLng = teammate.lastKnownPosition?.longitude ?? 2.34;

        // On modifie directement la propriété `lastKnownPosition` du UserProfile.
        teammate.lastKnownPosition = LatLng(
          currentLat + (_random.nextDouble() - 0.5) * 0.0005,
          currentLng + (_random.nextDouble() - 0.5) * 0.0005,
        );
      }
      
      // On diffuse la liste mise à jour des profils à tous les écouteurs.
      _teammateLocationController.add(List.from(teammates));
    });
  }

  /// Arrête la simulation de mouvement en cours.
  void stopTeamLocationSimulation() {
    if (_simulationTimer?.isActive ?? false) {
      debugPrint("[MockApiService] Arrêt de la simulation de localisation.");
      _simulationTimer!.cancel();
    }
  }

  /// Méthode de nettoyage à appeler pour libérer les ressources.
  void dispose() {
    _teammateLocationController.close();
    stopTeamLocationSimulation();
    debugPrint("[MockApiService] a été disposé.");
  }


  // --- MÉTHODES EXISTANTES (INCHANGÉES) ---

  Future<List<Team>> fetchAllTeams() async {
    await Future.delayed(const Duration(milliseconds: 400));
    return _teams.values.toList();
  }

  Future<Team?> fetchTeamDetails(String teamId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _teams[teamId];
  }

  Future<List<UserProfile>> fetchTeamMembers(String teamId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _userProfiles.values.where((p) => p.teamId == teamId).toList();
  }
  
  // NOTE: Cette méthode est maintenant moins utile car la simulation gère les positions,
  // mais on la garde car elle peut servir à initialiser une position.
  Future<void> updateUserPosition(String userId, LatLng newPosition) async {
    if (_userProfiles.containsKey(userId)) {
      _userProfiles[userId]!.lastKnownPosition = newPosition;
    }
  }

  Future<bool> joinTeam(String userId, String teamId) async {
    await Future.delayed(const Duration(milliseconds: 100));
    if (_userProfiles.containsKey(userId) && _teams.containsKey(teamId)) {
      _userProfiles[userId] = _userProfiles[userId]!.copyWith(teamId: () => teamId);
      debugPrint("API: L'utilisateur $userId a rejoint l'équipe $teamId.");
      return true;
    }
    return false;
  }
  
  Future<void> leaveTeam(String userId) async {
    await Future.delayed(const Duration(milliseconds: 100));
    final userProfile = _userProfiles[userId];
    if (userProfile == null || userProfile.teamId == null) return;
    final teamId = userProfile.teamId!;
    final team = _teams[teamId];
    if (team == null) return;
    if (userId != team.creatorId) {
      _userProfiles[userId] = userProfile.copyWith(teamId: () => null);
      debugPrint("API: Le membre $userId a quitté l'équipe $teamId.");
      return;
    }
    final members = _userProfiles.values.where((p) => p.teamId == teamId).toList();
    if (members.length <= 1) {
      _teams.remove(teamId);
      _userProfiles[userId] = userProfile.copyWith(teamId: () => null);
      debugPrint("API: Le créateur $userId a quitté l'équipe $teamId, qui a été dissoute.");
    } else {
      final otherMembers = _userProfiles.entries.where((entry) => entry.value.teamId == teamId && entry.key != userId).toList();
      final newCreatorEntry = otherMembers.first;
      final newCreatorId = newCreatorEntry.key;
      _teams[teamId] = Team(id: team.id, name: team.name, tag: team.tag, description: team.description, bannerUrl: team.bannerUrl, creatorId: newCreatorId);
      _userProfiles[userId] = userProfile.copyWith(teamId: () => null);
      debugPrint("API: Le créateur $userId a quitté. La propriété de l'équipe $teamId est transférée à $newCreatorId.");
    }
  }
  
  Future<Team?> createTeam(String teamName, String teamTag, String creatorId) async {
    await Future.delayed(const Duration(milliseconds: 500));
    if (_teams.values.any((team) => team.name == teamName || team.tag == teamTag)) {
      return null;
    }
    final newTeamId = 'team_${DateTime.now().millisecondsSinceEpoch}';
    final newTeam = Team(id: newTeamId, name: teamName, tag: '[$teamTag]', description: 'Une nouvelle équipe pleine de potentiel !', bannerUrl: 'https://i.imgur.com/default_banner.png', creatorId: creatorId);
    _teams[newTeamId] = newTeam;
    await joinTeam(creatorId, newTeamId);
    return newTeam;
  }

  Future<bool> excludeMember(String memberId, String teamId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final userProfile = _userProfiles[memberId];
    if (userProfile != null && userProfile.teamId == teamId) {
      _userProfiles[memberId] = userProfile.copyWith(teamId: () => null);
      debugPrint("API: Le membre $memberId a été exclu de l'équipe $teamId.");
      return true;
    }
    debugPrint("API: Échec de l'exclusion du membre $memberId.");
    return false;
  }

  Future<void> logCapture(String userId, LatLng location) async {
    await Future.delayed(const Duration(milliseconds: 100));
    _captureHistory.add(CaptureRecord(userId: userId, location: location, timestamp: DateTime.now()));
  }

  Future<List<CaptureRecord>> fetchCaptureHistory(String userId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _captureHistory.where((record) => record.userId == userId).toList();
  }

  Future<void> updateMockUserLocation(String userId, {String? country, String? region, String? city}) async {
    if (_userProfiles.containsKey(userId)) {
      _userProfiles[userId] = _userProfiles[userId]!.copyWith(country: country, region: region, city: city);
    }
  }

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
      id: userId, username: "Nouvelle Recrue", rank: "Aspirant", immersyaPoints: 0,
      areaCoveredKm2: 0.0, scansValidated: 0
    );
    _userProfiles[userId] = newProfile;
    return newProfile;
  }

  Future<List<Zone>> fetchZones() async {
    if (_zonesCache != null) return _zonesCache!;
    await Future.delayed(const Duration(milliseconds: 500));
    final statuses = [CoverageStatus.modele, CoverageStatus.partiel, CoverageStatus.enCours, CoverageStatus.nonCouvert];
    const center = LatLng(49.4922, 0.1131);
    final List<Zone> zones = [];
    const double size = 0.001;
    for (int i = -2; i < 3; i++) {
      for (int j = -2; j < 3; j++) {
        final zoneCenterLat = center.latitude + i * size;
        final zoneCenterLng = center.longitude + j * size;
        final polygon = [ LatLng(zoneCenterLat - size / 2, zoneCenterLng - size / 2), LatLng(zoneCenterLat - size / 2, zoneCenterLng + size / 2), LatLng(zoneCenterLat + size / 2, zoneCenterLng + size / 2), LatLng(zoneCenterLat + size / 2, zoneCenterLng - size / 2), ];
        zones.add(Zone(id: 'zone_${i}_$j', coverageStatus: statuses[_random.nextInt(statuses.length)], polygon: polygon));
      }
    }
    _zonesCache = zones;
    return zones;
  }

   // NOUVELLES MÉTHODES POUR LES SESSIONS
  Future<void> startTeamCaptureOnZone(String zoneId) async {
    await Future.delayed(const Duration(milliseconds: 100));
    final zones = await fetchZones(); // S'assure que le cache est peuplé
    final zoneIndex = zones.indexWhere((z) => z.id == zoneId);
    if (zoneIndex != -1) {
      // On met à jour l'état de la zone
      zones[zoneIndex].sessionStatus = ZoneSessionStatus.active;
      debugPrint("API: Session de capture démarrée sur la zone $zoneId");
    }
  }

  Future<void> stopTeamCaptureOnZone(String zoneId) async {
    await Future.delayed(const Duration(milliseconds: 100));
    final zones = await fetchZones();
    final zoneIndex = zones.indexWhere((z) => z.id == zoneId);
    if (zoneIndex != -1) {
      zones[zoneIndex].sessionStatus = ZoneSessionStatus.none;
      debugPrint("API: Session de capture arrêtée sur la zone $zoneId");
    }
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

  Future<void> updateCaptureStatus(String userId, bool isCapturing) async {
    if (_userProfiles.containsKey(userId)) {
      // On met à jour le profil de l'utilisateur directement.
      _userProfiles[userId] = _userProfiles[userId]!.copyWith(isCapturing: isCapturing);
      debugPrint("API: Statut de capture de $userId mis à jour à : $isCapturing");
    }
  }

  Future<Team?> updateTeamDetails(String teamId, String newName, String newDescription) async {
    if (!_teams.containsKey(teamId)) return null;

    final oldTeam = _teams[teamId]!;
    // On crée une nouvelle instance car notre modèle est immuable
    final updatedTeam = Team(
      id: oldTeam.id,
      name: newName,
      tag: oldTeam.tag, // On ne modifie pas le tag pour l'instant
      description: newDescription,
      bannerUrl: oldTeam.bannerUrl,
      creatorId: oldTeam.creatorId,
    );

    _teams[teamId] = updatedTeam;
    debugPrint("API: L'équipe $teamId a été mise à jour.");
    return updatedTeam;
  }

   Future<UserProfile?> updateUsername(String userId, String newUsername) async {
    // On pourrait vérifier si le nom est déjà pris
    if (_userProfiles.values.any((p) => p.username == newUsername)) {
      throw Exception("Ce nom d'utilisateur est déjà pris.");
    }

    if (_userProfiles.containsKey(userId)) {
      _userProfiles[userId] = _userProfiles[userId]!.copyWith(username: newUsername);
      debugPrint("API: Username de $userId mis à jour à : $newUsername");
      return _userProfiles[userId];
    }
    return null;
  }
}