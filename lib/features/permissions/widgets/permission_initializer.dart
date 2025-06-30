import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionInitializer extends StatefulWidget {
  final Widget child;

  const PermissionInitializer({super.key, required this.child});

  @override
  State<PermissionInitializer> createState() => _PermissionInitializerState();
}

class _PermissionInitializerState extends State<PermissionInitializer> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    final cameraStatus = await Permission.camera.status;
    final locationStatus = await Permission.location.status;

    if (!cameraStatus.isGranted && !cameraStatus.isPermanentlyDenied) {
      await Permission.camera.request();
    }

    if (!locationStatus.isGranted && !locationStatus.isPermanentlyDenied) {
      await Permission.location.request();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkPermissions();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
