// lib/main.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// VOS IMPORTS EXISTANTS
import 'package:immersya_mobile_app/api/mock_api_service.dart';
import 'package:immersya_mobile_app/app.dart';
import 'package:immersya_mobile_app/features/capture/capture_state.dart';
import 'package:immersya_mobile_app/features/map/state/map_state.dart';
import 'package:immersya_mobile_app/features/auth/services/auth_service.dart';
import 'package:immersya_mobile_app/features/profile/state/profile_state.dart';
import 'package:immersya_mobile_app/features/team/state/team_state.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  
  runApp(
    MultiProvider(
      providers: [
        Provider<MockApiService>(
          create: (_) => MockApiService(),
          dispose: (_, service) => service.dispose(),
        ),
        ChangeNotifierProvider<AuthService>(
          create: (context) => AuthService()..init(
            Provider.of<MockApiService>(context, listen: false)
          ),
        ),
        ChangeNotifierProvider<CaptureState>(
          create: (_) => CaptureState(),
        ),
        ChangeNotifierProvider<ProfileState>(
          create: (context) => ProfileState()..init(
            Provider.of<MockApiService>(context, listen: false),
            Provider.of<AuthService>(context, listen: false)
          ),
        ),
        // TeamState doit être avant MapState car MapState en dépend.
        ChangeNotifierProvider<TeamState>(
          create: (context) => TeamState()..init(
            Provider.of<MockApiService>(context, listen: false),
            Provider.of<AuthService>(context, listen: false)
          ),
        ),
        // MapState vient en dernier.
        ChangeNotifierProvider<MapState>(
          create: (context) => MapState()..init(
            Provider.of<MockApiService>(context, listen: false),
            Provider.of<AuthService>(context, listen: false),
            Provider.of<TeamState>(context, listen: false), // On lui passe sa dépendance.
          ),
        ),
      ],
      child: const ImmersyaPathfinderApp(),
    ),
  );
}