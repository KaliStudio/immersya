// lib/services/location_service.dart

import 'dart:convert';
import 'package:flutter/foundation.dart'; // Nécessaire pour détecter la plateforme web (kIsWeb)
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

class LocationService {

  // Cette méthode pour obtenir la position GPS est déjà correcte.
  Future<Position?> getCurrentPosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      debugPrint("LocationService: Le service de localisation est désactivé.");
      return null;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        debugPrint("LocationService: La permission de localisation a été refusée.");
        return null;
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      debugPrint("LocationService: La permission de localisation est refusée de manière permanente.");
      return null;
    } 

    try {
      return await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high)
    );
    } catch (e) {
      debugPrint("LocationService: Erreur lors de la récupération de la position : $e");
      return null;
    }
  }

  // --- MÉTHODE DE GÉOCODAGE ENTIÈREMENT RÉÉCRITE ET ROBUSTE ---
  Future<Placemark?> getPlacemarkFromCoordinates(Position position) async {
    // Si on n'est PAS sur le web, on tente d'abord le plugin natif.
    if (!kIsWeb) {
      try {
        List<Placemark> placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );
        if(placemarks.isNotEmpty) return placemarks.first;
      } catch (e) {
        debugPrint("Le géocodage natif a échoué, tentative via API externe. Erreur: $e");
      }
    }
    
    // --- PLAN B : API NOMINATIM (pour le web et en cas d'échec natif) ---
    debugPrint("Utilisation de l'API de géocodage externe Nominatim.");
    try {
      // 1. Construire l'URL correcte pour l'API Nominatim
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?format=json&lat=${position.latitude}&lon=${position.longitude}&zoom=10&accept-language=fr'
      );

      // 2. Faire la requête HTTP avec un User-Agent personnalisé (requis par Nominatim)
      final response = await http.get(
        url,
        headers: {
          'User-Agent': 'ImmersyaPathfinder/1.0 (contact@immersya.com)', // Très important pour Nominatim
        },
      ).timeout(const Duration(seconds: 10));

      // 3. Parser la réponse
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['address'] != null) {
          final address = data['address'];
          // On reconstruit un objet Placemark avec les données de Nominatim
          return Placemark(
            locality: address['city'] ?? address['town'] ?? address['village'] ?? '',
            administrativeArea: address['state'] ?? address['county'] ?? '', // Région ou Département
            country: address['country'] ?? '',
            isoCountryCode: address['country_code'] ?? '',
            street: address['road'] ?? '',
            postalCode: address['postcode'] ?? '',
            subLocality: '', subAdministrativeArea: '', thoroughfare: '', subThoroughfare: '',
          );
        }
      } else {
        debugPrint("Erreur API Nominatim: ${response.statusCode} - ${response.body}");
      }
    } catch (e) {
      debugPrint("Erreur de géocodage via API externe Nominatim: $e");
    }
    
    return null; // On retourne null si tout a échoué.
  }
}