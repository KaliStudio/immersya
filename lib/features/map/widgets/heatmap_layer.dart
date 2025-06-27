// lib/features/map/widgets/heatmap_layer.dart

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:immersya_mobile_app/models/capture_point_model.dart';

class HeatmapLayer extends StatelessWidget {
  final List<CapturePoint> points;
  // --- MODIFICATION : On attend un MapController ---
  final MapController controller;

  const HeatmapLayer({
    super.key, 
    required this.points,
    required this.controller, // Ajout au constructeur
  });

  @override
  Widget build(BuildContext context) {
    // --- MODIFICATION : On utilise le contrôleur pour obtenir la caméra ---
    final camera = controller.camera;
    final mapSizePoint = camera.size;
    final mapSize = Size(mapSizePoint.x, mapSizePoint.y);

    return CustomPaint(
      // On passe la caméra directement au peintre
      painter: _HeatmapPainter(points: points, camera: camera),
      size: mapSize,
    );
  }
}

class _HeatmapPainter extends CustomPainter {
  final List<CapturePoint> points;
  // Le peintre attend maintenant directement un objet MapCamera
  final MapCamera camera;

  _HeatmapPainter({required this.points, required this.camera});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    
    for (final point in points) {
      if (!camera.visibleBounds.contains(point.location)) {
        continue;
      }

      final pointOnScreen = camera.project(point.location);
      final offset = Offset(pointOnScreen.x, pointOnScreen.y);

      final gradient = RadialGradient(
        colors: [
          Colors.red.withAlpha(77),
          Colors.red.withAlpha(0),
        ],
        stops: const [0.0, 1.0],
      );

      paint.shader = gradient.createShader(
        Rect.fromCircle(center: offset, radius: 35),
      );
      
      canvas.drawCircle(offset, 35, paint);
    }
  }

  // La condition de repaint est maintenant plus claire et plus fiable.
  @override
  bool shouldRepaint(covariant _HeatmapPainter oldDelegate) {
    return oldDelegate.camera != camera;
  }
}