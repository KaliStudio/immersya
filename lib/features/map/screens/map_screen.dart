// lib/features/map/screens/map_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:immersya_mobile_app/api/mock_api_service.dart'; // NOM DU PACKAGE CORRIGÉ
import 'package:immersya_mobile_app/features/capture/capture_state.dart'; // NOM DU PACKAGE CORRIGÉ
import 'package:immersya_mobile_app/features/shell/screens/main_shell.dart'; // NOM DU PACKAGE CORRIGÉ
import 'package:immersya_mobile_app/models/zone_model.dart'; // NOM DU PACKAGE CORRIGÉ
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:polygon/polygon.dart' as polygon_helper; // Package pour aider à la détection du clic

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> with TickerProviderStateMixin {
  final MapController _mapController = MapController();
  StreamSubscription<Position>? _positionStreamSubscription;
  LatLng? _currentUserPosition;
  
  List<Zone> _zones = [];
  List<Mission> _missions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // Utiliser addPostFrameCallback pour appeler le Provider après la construction initiale
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeMap();
    });
  }

  Future<void> _initializeMap() async {
    if(mounted) setState(() => _isLoading = true);
    await Future.wait([
      _fetchZonesData(),
      _fetchMissionsData(),
    ]);
    await _initializeLocationServices();
    if(mounted) setState(() => _isLoading = false);
  }

  Future<void> _fetchZonesData() async {
    try {
      final apiService = context.read<MockApiService>();
      if (mounted) {
        final loadedZones = await apiService.fetchZones();
        setState(() => _zones = loadedZones);
      }
    } catch (e) {
      print("Erreur de chargement des zones: $e");
    }
  }

  Future<void> _fetchMissionsData() async {
    try {
      final apiService = context.read<MockApiService>();
      if (mounted) {
        final loadedMissions = await apiService.fetchMissions();
        setState(() => _missions = loadedMissions);
      }
    } catch (e) {
      print("Erreur de chargement des missions: $e");
    }
  }

  Future<void> _initializeLocationServices() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }
    
    _positionStreamSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, distanceFilter: 10)
    ).listen((Position position) {
      if(mounted) {
        if(_currentUserPosition == null) { // Pour le premier centrage
            _mapController.move(LatLng(position.latitude, position.longitude), 17.0);
        }
        setState(() {
          _currentUserPosition = LatLng(position.latitude, position.longitude);
        });
      }
    });
  }

  @override
  void dispose() {
    _positionStreamSubscription?.cancel();
    super.dispose();
  }

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
        title: const Text('Immersya Pathfinder'),
        centerTitle: true,
        actions: [
          if (!_isLoading)
            IconButton(
              icon: const Icon(Icons.sync),
              onPressed: _initializeMap,
            ),
          if (_isLoading)
            const Padding(padding: EdgeInsets.only(right: 16.0), child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))),
        ],
      ),
      body: FlutterMap(
        mapController: _mapController,
        // --- CORRECTION DE LA GESTION DU TAP ICI ---
        options: MapOptions(
          initialCenter: _currentUserPosition ?? const LatLng(45.7597, 4.8422),
          initialZoom: 15.0,
          onTap: (tapPosition, point) {
            // On vérifie chaque polygone pour voir si le clic est dedans
            for (final zone in _zones) {
              final polygon = polygon_helper.Polygon(
                zone.polygon.map((p) => polygon_helper.Point(p.latitude, p.longitude)).toList()
              );
              final isInside = polygon.contains(point.latitude, point.longitude);
              if (isInside) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Vous avez tapé sur la zone : ${zone.id}')),
                );
                // On arrête la boucle dès qu'on a trouvé un polygone
                break;
              }
            }
          },
        ),
        children: [
          TileLayer(
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
            // On a supprimé le 'onTap' d'ici car il n'existe pas
          ),
          MarkerLayer(
            markers: _missions.map((mission) {
              return Marker(
                width: 120,
                height: 80,
                point: mission.location,
                child: MissionMarker(mission: mission),
              );
            }).toList(),
          ),
          if (_currentUserPosition != null)
            MarkerLayer(
              markers: [
                Marker(
                  width: 80.0,
                  height: 80.0,
                  point: _currentUserPosition!,
                  child: const PlayerMarker(),
                ),
              ],
            ),
        ],
      ),
    );
  }
}


// --- Widgets MissionMarker et PlayerMarker (INCHANGÉS) ---

class MissionMarker extends StatelessWidget {
  final Mission mission;
  const MissionMarker({super.key, required this.mission});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        showModalBottomSheet(
          context: context,
          backgroundColor: Theme.of(context).colorScheme.surface,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          builder: (ctx) => _buildMissionDetailsSheet(ctx, mission),
        );
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.7),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white, width: 1),
            ),
            child: Text(
              mission.title,
              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 2),
          const Icon(Icons.flag, color: Colors.redAccent, size: 30),
        ],
      ),
    );
  }

  Widget _buildMissionDetailsSheet(BuildContext context, Mission mission) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(mission.title, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text(mission.description, style: TextStyle(color: Colors.grey[400])),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<CaptureState>().startMission(mission);
              mainShellNavigatorKey.currentState?.goToTab(1);
            },
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 50),
            ),
            child: const Text('Accepter et Lancer la Capture'),
          ),
        ],
      ),
    );
  }
}

class PlayerMarker extends StatefulWidget {
  const PlayerMarker({super.key});

  @override
  State<PlayerMarker> createState() => _PlayerMarkerState();
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
            Container(
              width: 24 * (1 + _animationController.value),
              height: 24 * (1 + _animationController.value),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.blue.withOpacity(0.5 * (1 - _animationController.value)),
              ),
            ),
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