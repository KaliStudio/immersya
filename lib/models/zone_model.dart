// lib/models/zone_model.dart
import 'package:latlong2/latlong.dart';

// Enum pour un code propre et sûr
enum CoverageStatus {
  nonCouvert,
  enCours,
  partiel,
  modele,
}

enum ZoneSessionStatus {
  none,
  active 
}

class Zone {
  final String id;
  final CoverageStatus coverageStatus;
  final List<LatLng> polygon; // La forme géométrique de la zone
  ZoneSessionStatus sessionStatus;

  Zone({
    required this.id,
    required this.coverageStatus,
    required this.polygon,
    this.sessionStatus = ZoneSessionStatus.none,
  });
  }
