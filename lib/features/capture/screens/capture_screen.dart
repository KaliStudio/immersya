// lib/features/capture/screens/capture_screen.dart
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:immersya_mobile_app/features/capture/capture_state.dart';
import 'package:immersya_mobile_app/features/shell/screens/main_shell.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

class CaptureScreen extends StatefulWidget {
  const CaptureScreen({super.key});

  @override
  State<CaptureScreen> createState() => _CaptureScreenState();
}

class _CaptureScreenState extends State<CaptureScreen> {
  CameraController? _cameraController;
  Future<void>? _initializeControllerFuture;
  int _photoCount = 0;

  @override
  void initState() {
    super.initState();
    _initializeControllerFuture = _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    // ... (le code d'initialisation de la caméra ne change pas)
    final cameraStatus = await Permission.camera.request();
    if (cameraStatus.isGranted) {
      final cameras = await availableCameras();
      final firstCamera = cameras.first;
      _cameraController = CameraController(firstCamera, ResolutionPreset.high);
      return _cameraController!.initialize();
    } else {
      throw Exception("Permissions caméra refusées.");
    }
  }
  
  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Le Consumer écoute maintenant CaptureState
    return Consumer<CaptureState>(
      builder: (context, captureState, child) {
        // Si on est en train d'uploader, on affiche la progression (prioritaire)
        if (captureState.isUploading) {
          return _buildUploadProgressView(captureState);
        }
        
        // On utilise un switch pour gérer les différents modes de capture
        switch (captureState.mode) {
          case CaptureMode.mission:
          case CaptureMode.freeScan:
            return _buildCameraView(captureState);
          case CaptureMode.idle:
          default:
            return _buildIdleSelectionView(); // La nouvelle vue de sélection
        }
      },
    );
  }

  // --- NOUVELLE VUE : L'Écran de Sélection ---
  Widget _buildIdleSelectionView() {
    return Scaffold(
      appBar: AppBar(title: const Text('Lancer une Capture')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Mode Libre', style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 8),
              const Text('Scannez librement votre environnement.', style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 16),
              _buildScanTypeButton(
                context: context,
                icon: Icons.chair_outlined,
                label: 'Scanner un Intérieur / Objet',
                type: FreeScanType.interior,
              ),
              const SizedBox(height: 12),
              _buildScanTypeButton(
                context: context,
                icon: Icons.face_retouching_natural,
                label: 'Scanner un Avatar',
                type: FreeScanType.avatar,
              ),
              const SizedBox(height: 32),
              const Divider(),
              const SizedBox(height: 16),
              Text('Mode Guidé', style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 8),
              const Text('Suivez une mission pour maximiser vos points.', style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                icon: const Icon(Icons.flag_outlined),
                label: const Text('Choisir une Mission'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(fontSize: 16),
                ),
                onPressed: () {
                   mainShellNavigatorKey.currentState?.goToTab(2); // L'index des missions est 2
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScanTypeButton({required BuildContext context, required IconData icon, required String label, required FreeScanType type}) {
    return OutlinedButton.icon(
      icon: Icon(icon),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        textStyle: const TextStyle(fontSize: 16),
        foregroundColor: Colors.white,
        side: BorderSide(color: Theme.of(context).colorScheme.primary),
      ),
      onPressed: () {
        context.read<CaptureState>().startFreeScan(type);
      },
    );
  }

  // Vue de la caméra (légèrement modifiée pour être plus générique)
  Widget _buildCameraView(CaptureState captureState) {
    return Scaffold(
      body: FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return Stack(fit: StackFit.expand, children: [
              CameraPreview(_cameraController!),
              _buildHud(captureState),
            ]);
          } else {
            return const Center(child: CircularProgressIndicator());
          }
        },
      ),
    );
  }
  
  // Vue de l'upload (légèrement modifiée)
  Widget _buildUploadProgressView(CaptureState captureState) {
    String title = captureState.mode == CaptureMode.mission
      ? 'Mission: "${captureState.activeMission!.title}"'
      : 'Scan Libre: ${captureState.freeScanType.name}';
      
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Upload en cours...', style: TextStyle(fontSize: 22)),
              const SizedBox(height: 8),
              Text(title, style: TextStyle(color: Colors.grey[400]), textAlign: TextAlign.center),
              const SizedBox(height: 32),
              LinearProgressIndicator(value: captureState.uploadProgress, minHeight: 10, borderRadius: BorderRadius.circular(5)),
              const SizedBox(height: 16),
              Text('${(captureState.uploadProgress * 100).toStringAsFixed(0)} %', style: const TextStyle(fontSize: 20)),
            ],
          ),
        ),
      ),
    );
  }
  
  // HUD (modifié pour être plus générique)
  Widget _buildHud(CaptureState captureState) {
    String title = captureState.mode == CaptureMode.mission
      ? 'Mission: ${captureState.activeMission!.title}'
      : 'Scan Libre: ${captureState.freeScanType.name}';
      
    return Padding(
      padding: const EdgeInsets.all(20.0).copyWith(top: 40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Bouton pour annuler
          Align(
            alignment: Alignment.topLeft,
            child: TextButton.icon(
              icon: const Icon(Icons.close),
              label: const Text('Annuler'),
              onPressed: () {
                context.read<CaptureState>().cancelCapture();
                setState(() { _photoCount = 0; });
              },
              style: TextButton.styleFrom(foregroundColor: Colors.white, backgroundColor: Colors.black.withOpacity(0.5)),
            ),
          ),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (_photoCount > 0)
                ElevatedButton(
                  onPressed: () async {
                    final captureState = context.read<CaptureState>();
                    final scaffoldMessenger = ScaffoldMessenger.of(context);

                    // On lance l'upload et on attend le message de retour
                    final String successMessage = await captureState.completeAndUploadScan(_photoCount);
                    
                    // On réinitialise le compteur de photos
                    if (mounted) {
                      setState(() { _photoCount = 0; });
                    }

                    // On affiche le message de succès
                    scaffoldMessenger.showSnackBar(
                      SnackBar(
                        content: Text(successMessage),
                        backgroundColor: Colors.green[700],
                      ),
                    );
                  },
                  child: const Text('Terminer & Uploader'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                ),
              GestureDetector(
                onTap: () async {
                  await _cameraController!.takePicture();
                  setState(() { _photoCount++; });
                },
                child: Container(width: 70, height: 70, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(0.3), border: Border.all(color: Colors.white, width: 4))),
              ),
              Text('$_photoCount', style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold, shadows: [Shadow(blurRadius: 5)])),
            ],
          )
        ],
      ),
    );
  }
}