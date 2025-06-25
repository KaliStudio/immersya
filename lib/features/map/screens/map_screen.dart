// lib/features/map/screens/map_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:immersya_mobile_app/api/mock_api_service.dart';
import 'package:immersya_mobile_app/features/capture/capture_state.dart';
import 'package:immersya_mobile_app/features/shell/screens/main_shell.dart';
import 'package:immersya_mobile_app/models/zone_model.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:immersya_mobile_app/features/map/state/map_state.dart';
import 'package:immersya_mobile_app/features/map/widgets/map_filter_chips.dart';
import 'package:immersya_mobile_app/models/capture_point_model.dart';
import 'package:immersya_mobile_app/features/map/widgets/heatmap_layer.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

// NOTE: Cet algo simple fonctionne pour les polygones convexes. Pour plus de robustesse, 
// un package comme 'polygon' est recommandé car il gère les cas complexes.
bool isPointInPolygon(LatLng point, List<LatLng> polygon) {
  int intersectCount = 0;
  for (int j = 0; j < polygon.length - 1; j++) {
    final p1 = polygon[j];
    final p2 = polygon[j + 1];

    if (((p1.latitude > point.latitude) != (p2.latitude > point.latitude)) &&
        (point.longitude < (p2.longitude - p1.longitude) * (point.latitude - p1.latitude) / (p2.latitude - p1.latitude) + p1.longitude)) {
      intersectCount++;
    }
  }
  return (intersectCount % 2 == 1);
}

class _MapScreenState extends State<MapScreen> with TickerProviderStateMixin {
  final MapController _mapController = MapController();
  StreamSubscription<Position>? _positionStreamSubscription;
  LatLng? _currentUserPosition;
  
  List<Zone> _zones = [];
  List<Mission> _missions = [];
  List<CapturePoint> _capturePoints = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeMap();
    });
  }

  Future<void> _initializeMap() async {
    if(mounted) setState(() => _isLoading = true);
    await Future.wait([
      _fetchZonesData(),
      _fetchMissionsData(),
      _fetchCapturePointsData(),
    ]);
    await _initializeLocationServices();
    if(mounted) setState(() => _isLoading = false);
  }

  Future<void> _fetchCapturePointsData() async {
    try {
      final apiService = context.read<MockApiService>();
      final loadedPoints = await apiService.fetchCapturePoints();
      if (mounted) setState(() => _capturePoints = loadedPoints);
    } catch (e) {
      debugPrint("Erreur de chargement des points de capture: $e");
    }
  }

  Future<void> _fetchZonesData() async {
    try {
      final apiService = context.read<MockApiService>();
      final loadedZones = await apiService.fetchZones();
      if (mounted) setState(() => _zones = loadedZones);
    } catch (e) {
      debugPrint("Erreur de chargement des zones: $e");
    }
  }

  Future<void> _fetchMissionsData() async {
    try {
      final apiService = context.read<MockApiService>();
      final loadedMissions = await apiService.fetchMissions();
      if (mounted) setState(() => _missions = loadedMissions);
    } catch (e) {
      debugPrint("Erreur de chargement des missions: $e");
    }
  }

  Future<void> _initializeLocationServices() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }
    
    _positionStreamSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, distanceFilter: 10)
    ).listen((Position position) {
      if(mounted) {
        final newPosition = LatLng(position.latitude, position.longitude);
        if(_currentUserPosition == null) {
            _mapController.move(newPosition, 17.0);
        }
        setState(() => _currentUserPosition = newPosition);
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
    final mapState = context.watch<MapState>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Immersya Pathfinder'),
        centerTitle: true,
        actions: [
          if (!_isLoading)
            IconButton(icon: const Icon(Icons.sync), onPressed: _initializeMap),
          if (_isLoading)
            const Padding(padding: EdgeInsets.only(right: 16.0), child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _currentUserPosition ?? const LatLng(45.7597, 4.8422),
              initialZoom: 15.0,
              onTap: (tapPosition, point) {
                if (!mapState.isFilterActive(MapFilter.zones)) return;
                for (final zone in _zones) {
                  if (isPointInPolygon(point, zone.polygon)) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Zone sélectionnée : ${zone.id}')),
                    );
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
              // --- MODIFICATION : Affichage conditionnel de la couche des zones ---
              if (mapState.isFilterActive(MapFilter.zones))
                PolygonLayer(
                  polygons: _zones.map((zone) => Polygon(
                    points: zone.polygon,
                    color: _getColorForStatus(zone.coverageStatus),
                    borderColor: _getColorForStatus(zone.coverageStatus).withOpacity(0.8),
                    borderStrokeWidth: 1.5,
                    isFilled: true,
                  )).toList(),
                ),
              if (mapState.isFilterActive(MapFilter.heatmap))
                HeatmapLayer(points: _capturePoints),
              // --- MODIFICATION : Affichage conditionnel de la couche des missions ---
              if (mapState.isFilterActive(MapFilter.missions))
                MarkerLayer(
                  markers: _missions.map((mission) => Marker(
                    width: 120,
                    height: 80,
                    point: mission.location,
                    child: MissionMarker(mission: mission),
                  )).toList(),
                ),
              // --- MODIFICATION : Affichage conditionnel du joueur ---
              if (_currentUserPosition != null && mapState.isFilterActive(MapFilter.currentUser))
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
          // --- AJOUT : Le widget des filtres superposé à la carte ---
          const MapFilterChips(),
        ],
      ),
    );
  }
}

// --- Les widgets MissionMarker et PlayerMarker restent INCHANGÉS ---
// (Le code de ces widgets est identique à celui que vous avez fourni)
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