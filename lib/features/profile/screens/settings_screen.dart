// lib/features/profile/screens/settings_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:immersya_mobile_app/features/auth/services/auth_service.dart';

// --- AJOUTS POUR LA GESTION DES PERMISSIONS ---
import 'package:immersya_mobile_app/features/permissions/permission_service.dart';
import 'package:permission_handler/permission_handler.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late Future<void> _loadingFuture;
  bool _enableLiDAR = true;
  bool _enableNotifications = true;
  double _photoQuality = 0.8;

  @override
  void initState() {
    super.initState();
    _loadingFuture = _loadSettings();
  }

  Future<void> _loadSettings() async {
    // Rafraîchit l'état actuel des permissions au cas où l'utilisateur
    // viendrait des réglages de son téléphone.
    if (mounted) {
      context.read<PermissionService>().checkAllPermissions();
    }
    
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _enableLiDAR = prefs.getBool('settings_enableLiDAR') ?? true;
        _enableNotifications = prefs.getBool('settings_enableNotifications') ?? true;
        _photoQuality = prefs.getDouble('settings_photoQuality') ?? 0.8;
      });
    }
  }

  Future<void> _saveSetting<T>(String key, T value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value is bool) {
      await prefs.setBool(key, value);
    } else if (value is double) {
      await prefs.setDouble(key, value);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Paramètres'),
      ),
      body: FutureBuilder(
        future: _loadingFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          // On écoute le service de permission pour reconstruire si le statut change
          final permissionService = context.watch<PermissionService>();
          return _buildSettingsList(permissionService);
        },
      ),
    );
  }

  ListView _buildSettingsList(PermissionService permissionService) {
    return ListView(
      children: [
        // --- NOUVELLE SECTION : PERMISSIONS ---
        _buildSectionTitle(context, 'Permissions de l\'application'),
        _buildPermissionTile(
          context,
          permissionService,
          title: "Appareil photo",
          subtitle: "Nécessaire pour toutes les fonctionnalités de scan.",
          status: permissionService.cameraStatus,
          onRequest: () => permissionService.requestCameraPermission(),
        ),
        _buildPermissionTile(
          context,
          permissionService,
          title: "Localisation",
          subtitle: "Nécessaire pour la carte et les missions.",
          status: permissionService.locationStatus,
          onRequest: () => permissionService.requestLocationPermission(),
        ),
        const Divider(),
        
        // --- VOS SECTIONS EXISTANTES (INCHANGÉES) ---
        _buildSectionTitle(context, 'Capture'),
        SwitchListTile(
          title: const Text('Activer le Scan LiDAR'),
          subtitle: const Text('Si votre appareil est compatible'),
          value: _enableLiDAR,
          onChanged: (bool value) {
            setState(() { _enableLiDAR = value; });
            _saveSetting('settings_enableLiDAR', value);
          },
        ),
        ListTile(
          title: const Text('Qualité des Photos'),
          subtitle: Slider(
            value: _photoQuality,
            min: 0.5,
            max: 1.0,
            divisions: 5,
            label: '${(_photoQuality * 100).round()}%',
            onChanged: (double value) {
              setState(() { _photoQuality = value; });
            },
            onChangeEnd: (double value) {
              _saveSetting('settings_photoQuality', value);
            },
          ),
        ),
        const Divider(),
        _buildSectionTitle(context, 'Notifications'),
         SwitchListTile(
          title: const Text('Activer les notifications'),
          subtitle: const Text('Mission terminée, nouveau rang, etc.'),
          value: _enableNotifications,
          onChanged: (bool value) {
            setState(() { _enableNotifications = value; });
            _saveSetting('settings_enableNotifications', value);
          },
        ),
         const Divider(),
         _buildSectionTitle(context, 'Gestion du Compte'),
         ListTile(
          title: const Text('Vider le cache', style: TextStyle(color: Colors.orange)),
          leading: const Icon(Icons.delete_sweep_outlined, color: Colors.orange),
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Cache vidé ! (simulation)')),
            );
          },
         ),
         ListTile(
          title: const Text('Se déconnecter', style: TextStyle(color: Colors.red)),
          leading: const Icon(Icons.logout, color: Colors.red),
          onTap: () => _showLogoutDialog(context),
         ),
      ],
    );
  }

  // --- NOUVEAU WIDGET HELPER POUR LES PERMISSIONS ---
  Widget _buildPermissionTile(
    BuildContext context,
    PermissionService service, {
    required String title,
    required String subtitle,
    required PermissionStatus status,
    required VoidCallback onRequest,
  }) {
    String statusText;
    Color statusColor;
    Widget? trailing;

    switch (status) {
      case PermissionStatus.granted:
        statusText = "Autorisé";
        statusColor = Colors.green;
        trailing = const Icon(Icons.check_circle, color: Colors.green);
        break;
      case PermissionStatus.denied:
        statusText = "Non demandé";
        statusColor = Colors.orange;
        trailing = ElevatedButton(onPressed: onRequest, child: const Text("Demander"));
        break;
      case PermissionStatus.permanentlyDenied:
      case PermissionStatus.restricted:
        statusText = "Bloqué";
        statusColor = Colors.red;
        trailing = ElevatedButton(onPressed: () => service.openAppSettings(), child: const Text("Réglages"));
        break;
      default:
        statusText = "Inconnu";
        statusColor = Colors.grey;
    }

    return ListTile(
      title: Text(title),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(subtitle),
          const SizedBox(height: 4),
          Text('Statut : $statusText', style: TextStyle(color: statusColor, fontWeight: FontWeight.bold)),
        ],
      ),
      trailing: trailing,
    );
  }

  // --- VOS MÉTHODES EXISTANTES (INCHANGÉES) ---
  Padding _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Text(
        title.toUpperCase(),
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Colors.grey[500],
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
  
  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Se déconnecter'),
          content: const Text('Êtes-vous sûr de vouloir vous déconnecter ?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Annuler'),
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
            TextButton(
              child: const Text('Confirmer', style: TextStyle(color: Colors.red)),
              onPressed: () {
                Navigator.of(dialogContext).pop();
                context.read<AuthService>().logout();
                if (Navigator.of(context).canPop()) {
                    Navigator.of(context).pop();
                }
              },
            ),
          ],
        );
      },
    );
  }
}