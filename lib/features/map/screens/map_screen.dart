// lib/features/map/screens/map_screen.dart
import 'dart:async'; // Import pour le StreamSubscription
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart'; // Import pour la géolocalisation
import 'package:immersya_pathfinder/api/mock_api_service.dart';
import 'package:immersya_pathfinder/models/zone_model.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> with TickerProviderStateMixin { // Ajout de TickerProviderStateMixin pour les animations
  // --- NOUVEAUTÉS ---
  final MapController _mapController = MapController(); // Contrôleur pour manipuler la carte
  StreamSubscription<Position>? _positionStreamSubscription; // Pour écouter le GPS
  LatLng? _currentUserPosition; // Position actuelle de l'utilisateur

  // --- ANCIENNES PROPRIÉTÉS ---
  List<Zone> _zones = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeMap();
  }
  
  // Fonction d'initialisation principale
  Future<void> _initializeMap() async {
    await _fetchZonesData(); // Charger les polygones
    await _initializeLocationServices(); // Démarrer le suivi GPS
  }

  // Fonction pour charger les données de notre API
  Future<void> _fetchZonesData() async {
    setState(() => _isLoading = true);
    try {
      final apiService = context.read<MockApiService>();
      _zones = await apiService.fetchZones();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e')));
      }
    } finally {
      if(mounted) setState(() => _isLoading = false);
    }
  }

  // --- NOUVEAU : GESTION DU GPS ---
  Future<void> _initializeLocationServices() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Gérer le cas où la localisation est désactivée
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // Gérer le refus de permission
        return;
      }
    }
    
    // Écouter le flux de positions GPS
    _positionStreamSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, distanceFilter: 10)
    ).listen((Position position) {
      if(mounted) {
        setState(() {
          _currentUserPosition = LatLng(position.latitude, position.longitude);
        });
        // Centrer la carte sur la nouvelle position de l'utilisateur
        _animatedMapMove(_currentUserPosition!, 17.0);
      }
    });
  }

  // Fonction pour un déplacement animé de la carte
  void _animatedMapMove(LatLng destLocation, double destZoom) {
    final latTween = Tween<double>(begin: _mapController.camera.center.latitude, end: destLocation.latitude);
    final lngTween = Tween<double>(begin: _mapController.camera.center.longitude, end: destLocation.longitude);
    final zoomTween = Tween<double>(begin: _mapController.camera.zoom, end: destZoom);

    final controller = AnimationController(duration: const Duration(milliseconds: 500), vsync: this);
    final animation = CurvedAnimation(parent: controller, curve: Curves.fastOutSlowIn);

    controller.addListener(() {
      _mapController.move(
        LatLng(latTween.evaluate(animation), lngTween.evaluate(animation)),
        zoomTween.evaluate(animation),
      );
    });

    animation.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        controller.dispose();
      } else if (status == AnimationStatus.dismissed) {
        controller.dispose();
      }
    });

    controller.forward();
  }

  @override
  void dispose() {
    _positionStreamSubscription?.cancel(); // Très important de couper l'écoute GPS
    super.dispose();
  }

  // ... (La fonction _getColorForStatus ne change pas)
  Color _getColorForStatus(CoverageStatus status) {
    switch (status) {
      case CoverageStatus.modele: return Colors.green.withOpacity(0.5);
      case CoverageStatus.partiel: return Colors.yellow.withOpacity(0.5);
      case CoverageStatus.en_cours: return Colors.orange.withOpacity(0.5);
      case CoverageStatus.non_couvert: return Colors.red.withOpacity(0.5);
      default: return Colors.grey.withOpacity(0.5);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Immersya'),
        centerTitle: true,
        actions: [
          if (!_isLoading)
            IconButton(
              icon: const Icon(Icons.sync),
              onPressed: _fetchZonesData,
            ),
          if (_isLoading)
            const Padding(padding: EdgeInsets.only(right: 16.0), child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))),
        ],
      ),
      body: FlutterMap(
        mapController: _mapController, // Lier le contrôleur à la carte
        options: MapOptions(
          initialCenter: _currentUserPosition ?? const LatLng(45.7597, 4.8422), // Centre initial sur le GPS ou Lyon
          initialZoom: _currentUserPosition != null ? 17.0 : 15.0,
        ),
        children: [
          // --- NOUVEAU : STYLE DE CARTE SOMBRE ---
          TileLayer(
            // Utiliser le fond de carte "Dark" de CartoDB pour le style
            urlTemplate: 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png',
            subdomains: const ['a', 'b', 'c', 'd'],
            retinaMode: true,
          ),
          
          PolygonLayer(
            polygons: _zones.map((zone) {
              return Polygon(
                points: zone.polygon,
                color: _getColorForStatus(zone.coverageStatus),
                borderColor: _getColorForStatus(zone.coverageStatus).withOpacity(0.8),
                borderStrokeWidth: 1.5,
                isFilled: true,
              );
            }).toList(),
          ),

          // --- NOUVEAU : MARQUEUR DU JOUEUR ---
          if (_currentUserPosition != null)
            MarkerLayer(
              markers: [
                Marker(
                  width: 80.0,
                  height: 80.0,
                  point: _currentUserPosition!,
                  child: PlayerMarker(), // Utiliser notre widget personnalisé
                ),
              ],
            ),
        ],
      ),
    );
  }
}

// --- NOUVEAU : WIDGET POUR LE MARQUEUR DU JOUEUR ---
class PlayerMarker extends StatefulWidget {
  const PlayerMarker({super.key});

  @override
  _PlayerMarkerState createState() => _PlayerMarkerState();
}

class _PlayerMarkerState extends State<PlayerMarker> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            // Onde de pulsation externe
            Container(
              width: 24 * (1 + _animationController.value),
              height: 24 * (1 + _animationController.value),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.blue.withOpacity(0.5 * (1 - _animationController.value)),
              ),
            ),
            // Point central
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.blue[300],
                border: Border.all(color: Colors.white, width: 2),
              ),
            ),
          ],
        );
      },
    );
  }
}