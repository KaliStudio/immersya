// lib/main.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:immersya_mobile_app/api/mock_api_service.dart';
import 'package:immersya_mobile_app/app.dart';
import 'package:immersya_mobile_app/features/capture/capture_state.dart';
import 'package:immersya_mobile_app/features/map/state/map_state.dart';
import 'package:immersya_mobile_app/features/auth/services/auth_service.dart';
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
        ChangeNotifierProvider<MapState>(
          create: (_) => MapState(),
        ),
        ChangeNotifierProvider<AuthService>(
          create: (_) => AuthService()),
      ],
      child: const ImmersyaPathfinderApp(),
    ),
  );
}