// lib/models/ghost_trace_model.dart

import 'package:latlong2/latlong.dart';

class GhostTrace {
  final String id;
  final List<LatLng> path;

  GhostTrace({required this.id, required this.path});
}