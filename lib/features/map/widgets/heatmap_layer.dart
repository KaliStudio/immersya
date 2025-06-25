// lib/features/map/widgets/heatmap_layer.dart

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:immersya_mobile_app/models/capture_point_model.dart';

class HeatmapLayer extends StatelessWidget {
  final List<CapturePoint> points;
  
  const HeatmapLayer({super.key, required this.points});

  @override
  Widget build(BuildContext context) {
    return CircleLayer(
      circles: points.map((point) {
        return CircleMarker(
          point: point.location,
          radius: 12, // Rayon de chaque point de la heatmap
          useRadiusInMeter: false, // Le rayon est en pixels, pas en mètres
          color: Colors.redAccent.withOpacity(0.15), // Couleur très transparente pour l'effet de superposition
          borderColor: Colors.transparent, // Pas de bordure pour un effet lisse
          borderStrokeWidth: 0,
        );
      }).toList(),
    );
  }
}