// lib/models/capture_point_model.dart

import 'package:latlong2/latlong.dart';

class CapturePoint {
  final LatLng location;
  // On pourrait ajouter un 'poids' plus tard (ex: une photo LiDAR vaut plus)
  // final double weight; 

  CapturePoint({required this.location});
}