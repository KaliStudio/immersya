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
import 'package:immersya_mobile_app/features/map/widgets/heatmap_layer.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> with AutomaticKeepAliveClientMixin {
  final MapController _mapController = MapController();
  Future<Position>? _initialGpsFuture;
  LatLng? _currentUserPosition;
  StreamSubscription<Position>? _positionStreamSubscription;
  
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _initialGpsFuture = _determinePosition();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MapState>().loadAllMapData();
      _startLocationStream();
    });
  }

  @override
  void dispose() {
    _positionStreamSubscription?.cancel();
    _mapController.dispose();
    super.dispose();
  }

  Future<Position> _determinePosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return Future.error('Le service de localisation est désactivé.');
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return Future.error('La permission de localisation est refusée.');
    }
    if (permission == LocationPermission.deniedForever) {
      return Future.error('Permission de localisation refusée de manière permanente.');
    } 
    return await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
  }

  void _startLocationStream() {
    _positionStreamSubscription?.cancel();
    _positionStreamSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, distanceFilter: 10)
    ).listen((Position position) {
      if (mounted) {
        final newPosition = LatLng(position.latitude, position.longitude);
        setState(() => _currentUserPosition = newPosition);
        context.read<MapState>().updateCurrentUserPosition(newPosition);
      }
    });
  }

  void _centerOnUser() {
    if (_currentUserPosition != null) {
      _mapController.move(_currentUserPosition!, 17.0);
    }
  }

  bool isPointInPolygon(LatLng point, List<LatLng> polygon) {
    int intersectCount = 0;
    for (int j = 0; j < polygon.length - 1; j++) {
      final p1 = polygon[j];
      final p2 = polygon[j + 1];
      if (((p1.latitude > point.latitude) != (p2.latitude > point.latitude)) && (point.longitude < (p2.longitude - p1.longitude) * (point.latitude - p1.latitude) / (p2.latitude - p1.latitude) + p1.longitude)) {
        intersectCount++;
      }
    }
    return (intersectCount % 2 == 1);
  }

  Color _getColorForStatus(CoverageStatus status) {
    switch (status) {
      case CoverageStatus.modele: return Colors.green.withAlpha(128);
      case CoverageStatus.partiel: return Colors.yellow.withAlpha(128);
      case CoverageStatus.enCours: return Colors.orange.withAlpha(128);
      case CoverageStatus.nonCouvert: return Colors.red.withAlpha(128);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    
    return Scaffold(
      appBar: AppBar(title: const Text('Immersya Pathfinder')),
      floatingActionButton: FloatingActionButton(onPressed: _centerOnUser, tooltip: 'Centrer sur ma position', child: const Icon(Icons.my_location)),
      body: FutureBuilder<Position>(
        future: _initialGpsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Padding(padding: const EdgeInsets.all(16.0), child: Text("Erreur GPS : ${snapshot.error}", textAlign: TextAlign.center)));
          }
          if (!snapshot.hasData || _currentUserPosition == null) {
             return const Center(child: Text("En attente du signal GPS..."));
          }
          
          final mapState = context.watch<MapState>();

          return Stack(
            children: [
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: _currentUserPosition!,
                  initialZoom: 15.0,
                  onTap: (tapPosition, point) {
                    if (!mapState.isFilterActive(MapFilter.zones)) return;
                    for (final zone in mapState.zones) {
                      if (isPointInPolygon(point, zone.polygon)) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Zone sélectionnée : ${zone.id}')));
                        break;
                      }
                    }
                  },
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png',
                    subdomains: const ['a', 'b', 'c', 'd'],
                    retinaMode: RetinaMode.isHighDensity(context), 
                  ),
                  if (mapState.isFilterActive(MapFilter.ghostTraces)) PolylineLayer(polylines: mapState.ghostTraces.map((trace) => Polyline(points: trace.path, color: Colors.blueAccent.withAlpha(102), strokeWidth: 3.0)).toList()),
                  if (mapState.isFilterActive(MapFilter.zones)) PolygonLayer(polygons: mapState.zones.map((zone) { final color = _getColorForStatus(zone.coverageStatus); return Polygon(points: zone.polygon, color: color, borderColor: color.withAlpha(204), borderStrokeWidth: 1.5, isFilled: true);}).toList()),
                  if (mapState.isFilterActive(MapFilter.heatmap)) HeatmapLayer(points: mapState.capturePoints, controller: _mapController),
                  if (mapState.isFilterActive(MapFilter.missions)) MarkerLayer(markers: mapState.missions.map((mission) => Marker(width: 120, height: 80, point: mission.location, child: MissionMarker(mission: mission))).toList()),
                  
                  if (mapState.isFilterActive(MapFilter.teammates))
                    MarkerLayer(
                      markers: mapState.teammates.where((t) => t.lastKnownPosition != null).map((teammate) {
                        return Marker(
                          width: 80, height: 80,
                          point: teammate.lastKnownPosition!,
                          child: TeammateMarker(username: teammate.username),
                        );
                      }).toList(),
                    ),

                  if (_currentUserPosition != null && mapState.isFilterActive(MapFilter.currentUser))
                    MarkerLayer(markers: [Marker(width: 80.0, height: 80.0, point: _currentUserPosition!, child: const PlayerMarker())]),
                ],
              ),
              const MapFilterChips(),
              if (mapState.isLoading) Container(color: Colors.black.withOpacity(0.3), child: const Center(child: CircularProgressIndicator())),
            ],
          );
        },
      ),
    );
  }
}

// =============================================================
// WIDGETS DE MARQUEURS (INCHANGÉS)
// =============================================================

class TeammateMarker extends StatelessWidget {
  final String username;
  const TeammateMarker({super.key, required this.username});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(color: Colors.black.withOpacity(0.6), borderRadius: BorderRadius.circular(8)),
          child: Text(username, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
        ),
        const SizedBox(height: 2),
        const Icon(Icons.person_pin_circle, color: Colors.greenAccent, size: 30),
      ],
    );
  }
}

class MissionMarker extends StatelessWidget {
  final Mission mission;
  const MissionMarker({super.key, required this.mission});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        showModalBottomSheet(context: context, backgroundColor: Theme.of(context).colorScheme.surface, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))), builder: (ctx) => _buildMissionDetailsSheet(ctx, mission));
      },
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: Colors.black.withAlpha(179), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white, width: 1)), child: Text(mission.title, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis)),
        const SizedBox(height: 2),
        const Icon(Icons.flag, color: Colors.redAccent, size: 30),
      ]),
    );
  }

  Widget _buildMissionDetailsSheet(BuildContext context, Mission mission) {
    return Padding(padding: const EdgeInsets.all(20.0), child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(mission.title, style: Theme.of(context).textTheme.headlineSmall),
      const SizedBox(height: 8),
      Text(mission.description, style: TextStyle(color: Colors.grey[400])),
      const SizedBox(height: 20),
      ElevatedButton(onPressed: () {
        Navigator.pop(context);
        context.read<CaptureState>().startMission(mission);
        mainShellNavigatorKey.currentState?.goToTab(1);
      }, style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)), child: const Text('Accepter et Lancer la Capture')),
    ]));
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
    _animationController = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat();
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
        return Stack(alignment: Alignment.center, children: [
          Container(width: 24 * (1 + _animationController.value), height: 24 * (1 + _animationController.value), decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.blue.withAlpha((255 * 0.5 * (1 - _animationController.value)).round()))),
          Container(width: 18, height: 18, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.blue[300], border: Border.all(color: Colors.white, width: 2))),
        ]);
      },
    );
  }
}