// lib/models/zone_model.dart
import 'package:latlong2/latlong.dart';

// Enum pour un code propre et sûr
enum CoverageStatus {
  non_couvert,
  en_cours,
  partiel,
  modele,
}

class Zone {
  final String id;
  final CoverageStatus coverageStatus;
  final List<LatLng> polygon; // La forme géométrique de la zone

  Zone({
    required this.id,
    required this.coverageStatus,
    required this.polygon,
  });
  }
