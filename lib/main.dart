// lib/main.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:immersya_mobile_app/api/mock_api_service.dart';
import 'package:immersya_mobile_app/app.dart';
import 'package:immersya_mobile_app/features/capture/capture_state.dart';
import 'package:immersya_mobile_app/features/map/state/map_state.dart'; // --- AJOUT DE L'IMPORT

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  
  runApp(
    // MultiProvider permet de fournir plusieurs objets d'état ou services
    MultiProvider(
      providers: [
        // Un service qui ne change pas, fourni via Provider.
        Provider<MockApiService>(
          create: (_) => MockApiService(),
        ),
        // Des états qui notifient des changements, fournis via ChangeNotifierProvider.
        ChangeNotifierProvider<CaptureState>(
          create: (_) => CaptureState(),
        ),
        // --- AJOUT DU NOUVEAU PROVIDER POUR LA CARTE ---
        ChangeNotifierProvider<MapState>(
          create: (_) => MapState(),
        ),
      ],
      child: const ImmersyaPathfinderApp(),
    ),
  );
}