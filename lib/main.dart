// lib/main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:immersya_mobile_app/api/mock_api_service.dart';
import 'package:immersya_mobile_app/app.dart';
import 'package:immersya_mobile_app/features/capture/capture_state.dart'; // Importer le nouvel état

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  
  runApp(
    // MultiProvider permet de fournir plusieurs objets
    MultiProvider(
      providers: [
        Provider<MockApiService>(
          create: (_) => MockApiService(),
        ),
        // Notre nouvel état de mission partagé
        ChangeNotifierProvider<CaptureState>(
          create: (_) => CaptureState()),
      ],
      child: const ImmersyaPathfinderApp(),
    ),
  );
}