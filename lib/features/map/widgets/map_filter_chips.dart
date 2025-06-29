// lib/features/map/widgets/map_filter_chips.dart

import 'package:flutter/material.dart';
import 'package:immersya_mobile_app/features/map/state/map_state.dart';
import 'package:provider/provider.dart';

class MapFilterChips extends StatelessWidget {
  const MapFilterChips({super.key});

  @override
  Widget build(BuildContext context) {
    // On écoute les changements de MapState pour reconstruire les puces.
    final mapState = context.watch<MapState>();

    return Positioned(
      top: 10,
      left: 10,
      right: 10,
      child: Container(
        alignment: Alignment.center,
        child: Wrap(
          spacing: 8.0,
          runSpacing: 4.0,
          children: MapFilter.values.map((filter) {
            return FilterChip(
              label: Text(_getLabelForFilter(filter)),
              // L'état sélectionné vient directement de notre MapState.
              selected: mapState.isFilterActive(filter),
              onSelected: (isSelected) {
                // Quand on clique, on appelle la méthode de notre MapState.
                // On utilise context.read car on est dans un callback, on ne veut pas écouter ici.
                context.read<MapState>().toggleFilter(filter);
              },
              backgroundColor: Colors.black.withAlpha(153),
              labelStyle: const TextStyle(color: Colors.white),
              selectedColor: Theme.of(context).colorScheme.primary,
              checkmarkColor: Colors.white,
            );
          }).toList(),
        ),
      ),
    );
  }

  // Petite fonction utilitaire pour avoir des noms propres pour l'UI.
  String _getLabelForFilter(MapFilter filter) {
    switch (filter) {
      case MapFilter.zones:
        return 'Zones';
      case MapFilter.missions:
        return 'Missions';
      case MapFilter.currentUser:
        return 'Ma Position';
      case MapFilter.heatmap:
        return 'Heatmap';
      case MapFilter.ghostTraces:
        return 'Traces';
      case MapFilter.teammates:
        return 'Coéquipiers';
    }
  }
}