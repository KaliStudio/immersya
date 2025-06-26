// lib/features/map/state/map_state.dart

import 'package:flutter/foundation.dart';

// Un enum pour définir clairement les types de filtres disponibles.
// C'est beaucoup plus propre et sûr que d'utiliser des chaînes de caractères.
enum MapFilter {
  zones,
  missions,
  currentUser,
  heatmap,
  ghostTraces,
}

class MapState with ChangeNotifier {
  final Map<MapFilter, bool> _activeFilters = {
    MapFilter.zones: true,
    MapFilter.missions: true,
    MapFilter.currentUser: true,
    MapFilter.heatmap: false, // On la désactive par défaut pour ne pas surcharger la vue
    MapFilter.ghostTraces: true, // On l'active par défaut pour la démo
  };

  // Un getter public pour que l'UI puisse vérifier si un filtre est actif.
  bool isFilterActive(MapFilter filter) => _activeFilters[filter] ?? false;

  // La méthode pour activer ou désactiver un filtre.
  void toggleFilter(MapFilter filter) {
    // On inverse la valeur actuelle du filtre.
    _activeFilters[filter] = !isFilterActive(filter);
    
    // On notifie tous les widgets qui écoutent ce provider qu'un changement a eu lieu,
    // afin qu'ils se reconstruisent. C'est le cœur de `ChangeNotifier`.
    notifyListeners();
  }
}