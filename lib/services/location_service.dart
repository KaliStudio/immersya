// lib/services/location_service.dart

import 'package:geolocator/geolocator.dart';

class LocationService {

  // Récupère la position GPS actuelle de l'appareil.
  // Gère les permissions et l'état du service GPS.
  Future<Position?> getCurrentPosition() async {
    // 1. Vérifier si le service de localisation est activé sur l'appareil.
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Si le service est désactivé, on ne peut rien faire.
      print("Le service de localisation est désactivé.");
      // On pourrait demander à l'utilisateur de l'activer via `Geolocator.openLocationSettings()`
      return null;
    }

    // 2. Vérifier les permissions de l'application.
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      // Si la permission est refusée, on la demande à l'utilisateur.
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // Si l'utilisateur refuse à nouveau, on abandonne.
        print("La permission de localisation a été refusée.");
        return null;
      }
    }
    
    // 3. Gérer le cas où la permission est refusée de manière permanente.
    if (permission == LocationPermission.deniedForever) {
      print("La permission de localisation est refusée de manière permanente. L'application ne peut pas y accéder.");
      // On pourrait ouvrir les paramètres de l'application pour que l'utilisateur change la permission.
      // await Geolocator.openAppSettings();
      return null;
    } 

    // 4. Si les permissions sont accordées, on récupère la position.
    print("Permissions accordées. Récupération de la position GPS...");
    try {
      return await Geolocator.getCurrentPosition(
        // On peut ajuster la précision si besoin.
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (e) {
      print("Erreur lors de la récupération de la position : $e");
      return null;
    }
  }
}