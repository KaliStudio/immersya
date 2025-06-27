// lib/features/missions/screens/missions_screen.dart
import 'package:flutter/material.dart';
import 'package:immersya_mobile_app/api/mock_api_service.dart';
import 'package:immersya_mobile_app/features/capture/capture_state.dart';
import 'package:immersya_mobile_app/features/shell/screens/main_shell.dart';
import 'package:provider/provider.dart';

class MissionsScreen extends StatefulWidget {
  const MissionsScreen({super.key});

  @override
  State<MissionsScreen> createState() => _MissionsScreenState();
}

class _MissionsScreenState extends State<MissionsScreen> with AutomaticKeepAliveClientMixin {
  Future<List<Mission>>? _missionsFuture;

  @override
  void initState() {
    super.initState();
    _loadMissions();
  }

  void _loadMissions() {
    final apiService = context.read<MockApiService>();
    _missionsFuture = apiService.fetchMissions();
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Missions Disponibles'),
        centerTitle: true,
      ),
      body: FutureBuilder<List<Mission>>(
        future: _missionsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Erreur: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Aucune mission disponible.'));
          }

          final missions = snapshot.data!;
          return RefreshIndicator(
            onRefresh: () async {
              setState(() {
                _loadMissions();
              });
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(8.0),
              itemCount: missions.length,
              itemBuilder: (context, index) {
                final mission = missions[index];
                return _buildMissionCard(mission);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildMissionCard(Mission mission) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
      color: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: _getPriorityColor(mission.priority), width: 2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              mission.title,
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              mission.description,
              style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey[400]),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Chip(
                  label: Text('${mission.rewardPoints} Points'),
                  backgroundColor: Colors.amber.withAlpha(51),
                  labelStyle: const TextStyle(color: Colors.amber),
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
                ElevatedButton(
                  onPressed: () {
                  // Utiliser Provider pour accéder à l'état et démarrer la mission
                  context.read<CaptureState>().startMission(mission);
                  
                  // Changer d'onglet pour aller à la Capture
                  mainShellNavigatorKey.currentState?.goToTab(1);
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Mission "${mission.title}" démarrée !')),
                  );
                },
                child: const Text('Accepter'),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Color _getPriorityColor(MissionPriority priority) {
    switch (priority) {
      case MissionPriority.high: return Colors.redAccent;
      case MissionPriority.medium: return Colors.orangeAccent;
      case MissionPriority.low: return Colors.blueAccent;
    }
  }
}