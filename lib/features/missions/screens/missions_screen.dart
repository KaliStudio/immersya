// lib/features/missions/screens/missions_screen.dart

import 'package:flutter/material.dart';
import 'package:immersya_mobile_app/api/mock_api_service.dart';
import 'package:immersya_mobile_app/features/capture/capture_state.dart';
import 'package:immersya_mobile_app/features/missions/state/mission_state.dart';
import 'package:immersya_mobile_app/features/shell/screens/main_shell.dart';
import 'package:provider/provider.dart';

class MissionsScreen extends StatelessWidget {
  const MissionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Missions'),
          centerTitle: true,
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Disponibles'),
              Tab(text: 'Mon Journal'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _AvailableMissionsView(),
            _AcceptedMissionsView(),
          ],
        ),
      ),
    );
  }
}

// --- VUE POUR LES MISSIONS DISPONIBLES ---
class _AvailableMissionsView extends StatelessWidget {
  const _AvailableMissionsView();
  @override
  Widget build(BuildContext context) {
    final missionState = context.watch<MissionState>();
    if (missionState.isLoading) return const Center(child: CircularProgressIndicator());
    if (missionState.availableMissions.isEmpty) return const Center(child: Text('Aucune mission disponible pour le moment.'));

    return RefreshIndicator(
      onRefresh: () => context.read<MissionState>().fetchAvailableMissions(),
      child: ListView.builder(
        padding: const EdgeInsets.all(8.0),
        itemCount: missionState.availableMissions.length,
        itemBuilder: (context, index) {
          final mission = missionState.availableMissions[index];
          final isAccepted = missionState.isMissionAccepted(mission.id);
          return _MissionCard(
            mission: mission,
            buttonLabel: isAccepted ? 'Acceptée' : 'Accepter',
            onButtonPressed: isAccepted ? null : () {
              context.read<MissionState>().acceptMission(mission);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Mission "${mission.title}" ajoutée au journal !')));
            },
          );
        },
      ),
    );
  }
}

// --- VUE POUR LES MISSIONS ACCEPTÉES ---
class _AcceptedMissionsView extends StatelessWidget {
  const _AcceptedMissionsView();
  @override
  Widget build(BuildContext context) {
    final missionState = context.watch<MissionState>();
    final acceptedMissions = missionState.acceptedMissions;
    if (acceptedMissions.isEmpty) return const Center(child: Text('Aucune mission dans votre journal.\nAcceptez-en depuis l\'onglet "Disponibles" !', textAlign: TextAlign.center));

    return ListView.builder(
      padding: const EdgeInsets.all(8.0),
      itemCount: acceptedMissions.length,
      itemBuilder: (context, index) {
        final mission = acceptedMissions[index];
        return _MissionCard(
          mission: mission,
          buttonLabel: 'Lancer',
          buttonColor: Colors.green,
          onButtonPressed: () {
            context.read<CaptureState>().startMission(mission);
            mainShellNavigatorKey.currentState?.goToTab(1);
          },
          // AJOUT : On passe une action d'annulation
          onCancel: () {
            context.read<MissionState>().cancelAcceptedMission(mission.id);
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Mission "${mission.title}" abandonnée.'), backgroundColor: Colors.red));
          },
        );
      },
    );
  }
}

// --- WIDGET DE CARTE DE MISSION RÉUTILISABLE ---
class _MissionCard extends StatelessWidget {
  final Mission mission;
  final String buttonLabel;
  final Color? buttonColor;
  final VoidCallback? onButtonPressed;
  final VoidCallback? onCancel; // AJOUT : Callback pour l'annulation

  const _MissionCard({
    required this.mission,
    required this.buttonLabel,
    this.buttonColor,
    this.onButtonPressed,
    this.onCancel, // AJOUT
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
      color: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(side: BorderSide(color: _getPriorityColor(mission.priority), width: 2), borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(mission.title, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(mission.description, style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey[400])),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Chip(label: Text('${mission.rewardPoints} Points'), backgroundColor: Colors.amber.withAlpha(51), labelStyle: const TextStyle(color: Colors.amber), padding: const EdgeInsets.symmetric(horizontal: 8)),
              Row(
                children: [
                  // AJOUT : Affiche le bouton d'annulation s'il est fourni
                  if (onCancel != null)
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Colors.redAccent),
                      tooltip: "Abandonner la mission",
                      onPressed: onCancel,
                    ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: buttonColor),
                    onPressed: onButtonPressed,
                    child: Text(buttonLabel),
                  ),
                ],
              )
            ],
          )
        ]),
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