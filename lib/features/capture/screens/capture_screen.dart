import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:immersya_mobile_app/features/capture/capture_state.dart';
import 'package:immersya_mobile_app/features/shell/screens/main_shell.dart';
import 'package:immersya_mobile_app/features/permissions/permission_service.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

class CaptureScreen extends StatefulWidget {
  const CaptureScreen({super.key});

  @override
  State<CaptureScreen> createState() => _CaptureScreenState();
}

class _CaptureScreenState extends State<CaptureScreen> with AutomaticKeepAliveClientMixin {
  CameraController? _cameraController;
  Future<void>? _initializeControllerFuture;
  int _photoCount = 0;

  @override
  void initState() {
    super.initState();
    // Initialisation déplacée dans le build
  }

  Future<void> _initializeCamera() async {
    final cameras = await availableCameras();
    if (cameras.isEmpty) throw Exception("Aucune caméra disponible.");

    _cameraController?.dispose(); // Sécurité
    final firstCamera = cameras.first;
    _cameraController = CameraController(
      firstCamera,
      ResolutionPreset.high,
      enableAudio: false,
    );
    await _cameraController!.initialize();
    setState(() {}); // Redessine après init
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Consumer2<CaptureState, PermissionService>(
      builder: (context, captureState, permissionService, child) {
        // Demande ou attend la permission caméra
        if (!permissionService.cameraStatus.isGranted) {
          return _buildPermissionRequestView(permissionService);
        }

        // Initialiser la caméra dès que la permission est accordée
        if (_cameraController == null || !_cameraController!.value.isInitialized) {
          _initializeControllerFuture ??= _initializeCamera();
        }

        if (captureState.isUploading) {
          return _buildUploadProgressView(captureState);
        }

        switch (captureState.mode) {
          case CaptureMode.mission:
          case CaptureMode.freeScan:
            return _buildCameraView(captureState);
          case CaptureMode.idle:
            return _buildIdleSelectionView();
        }
      },
    );
  }

  Widget _buildPermissionRequestView(PermissionService permissionService) {
    return Scaffold(
      appBar: AppBar(title: const Text('Permission Requise')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.no_photography_outlined, size: 80, color: Colors.grey),
              const SizedBox(height: 16),
              const Text(
                "Accès à la caméra requis",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                "Pour scanner le monde en 3D, Immersya a besoin d'accéder à votre appareil photo.",
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => permissionService.requestCameraPermission(),
                child: const Text("Autoriser l'accès"),
              ),
              if (permissionService.cameraStatus.isPermanentlyDenied) ...[
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => permissionService.openDeviceSettings(),
                  child: const Text("Ouvrir les réglages", style: TextStyle(decoration: TextDecoration.underline)),
                ),
              ]
            ],
          ),
        ),
      ),
    );
  }

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
              _buildScanTypeButton(context, Icons.chair_outlined, 'Scanner un Intérieur / Objet', FreeScanType.interior),
              const SizedBox(height: 12),
              _buildScanTypeButton(context, Icons.face_retouching_natural, 'Scanner un Avatar', FreeScanType.avatar),
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
                  mainShellNavigatorKey.currentState?.goToTab(2);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScanTypeButton(BuildContext context, IconData icon, String label, FreeScanType type) {
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

  Widget _buildCameraView(CaptureState captureState) {
    return Scaffold(
      body: FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            if (snapshot.hasError) {
              return Center(child: Text("Erreur d'initialisation de la caméra: ${snapshot.error}"));
            }
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
              LinearProgressIndicator(
                value: captureState.uploadProgress,
                minHeight: 10,
                borderRadius: BorderRadius.circular(5),
              ),
              const SizedBox(height: 16),
              Text('${(captureState.uploadProgress * 100).toStringAsFixed(0)} %', style: const TextStyle(fontSize: 20)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHud(CaptureState captureState) {
    return Padding(
      padding: const EdgeInsets.all(20.0).copyWith(top: 40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Align(
            alignment: Alignment.topLeft,
            child: TextButton.icon(
              icon: const Icon(Icons.close),
              label: const Text('Annuler'),
              onPressed: () {
                context.read<CaptureState>().cancelCapture();
                setState(() => _photoCount = 0);
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.black.withAlpha(128),
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              if (_photoCount > 0)
                ElevatedButton(
                  onPressed: () async {
                    final captureState = context.read<CaptureState>();
                    final scaffoldMessenger = ScaffoldMessenger.of(context);

                    try {
                      final currentPosition = await Geolocator.getCurrentPosition(
                        desiredAccuracy: LocationAccuracy.high,
                      );

                      if (mounted) {
                        await captureState.completeCapture(
                          photoCount: _photoCount,
                          location: LatLng(currentPosition.latitude, currentPosition.longitude),
                        );
                        setState(() => _photoCount = 0);
                        scaffoldMessenger.showSnackBar(
                          SnackBar(
                            content: const Text("Scan uploadé avec succès !"),
                            backgroundColor: Colors.green[700],
                          ),
                        );
                      }
                    } catch (_) {
                      scaffoldMessenger.showSnackBar(
                        const SnackBar(
                          content: Text("Erreur: Impossible d'obtenir la position GPS."),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                  child: const Text('Terminer & Uploader'),
                ),
              GestureDetector(
                onTap: () async {
                  if (_cameraController?.value.isInitialized != true) return;
                  try {
                    await _cameraController!.takePicture();
                    if (mounted) setState(() => _photoCount++);
                  } catch (_) {}
                },
                child: Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withAlpha(77),
                    border: Border.all(color: Colors.white, width: 4),
                  ),
                ),
              ),
              Text(
                '$_photoCount',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  shadows: [Shadow(blurRadius: 5)],
                ),
              ),
            ],
          )
        ],
      ),
    );
  }
}
