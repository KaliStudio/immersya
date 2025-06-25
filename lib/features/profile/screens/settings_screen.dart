// lib/features/profile/screens/settings_screen.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // On utilise un Future pour gérer l'état de chargement initial
  late Future<void> _loadingFuture;

  // Valeurs par défaut
  bool _enableLiDAR = true;
  bool _enableNotifications = true;
  double _photoQuality = 0.8;

  @override
  void initState() {
    super.initState();
    // On assigne le Future dans initState
    _loadingFuture = _loadSettings();
  }

  // Fonction pour charger les préférences depuis le disque
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    // Utiliser setState pour mettre à jour l'UI une fois les données chargées
    setState(() {
      _enableLiDAR = prefs.getBool('settings_enableLiDAR') ?? true;
      _enableNotifications = prefs.getBool('settings_enableNotifications') ?? true;
      _photoQuality = prefs.getDouble('settings_photoQuality') ?? 0.8;
    });
  }

  // Fonction générique pour sauvegarder les changements
  Future<void> _saveSetting<T>(String key, T value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value is bool) {
      await prefs.setBool(key, value);
    } else if (value is double) {
      await prefs.setDouble(key, value);
    }
    // On pourrait ajouter d'autres types si besoin (String, int...)
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Paramètres'),
      ),
      // On utilise un FutureBuilder pour afficher un loader pendant le chargement
      body: FutureBuilder(
        future: _loadingFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          // Une fois le chargement terminé, on affiche la liste des paramètres
          return _buildSettingsList();
        },
      ),
    );
  }

  ListView _buildSettingsList() {
    return ListView(
      children: [
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

  // Helper pour les titres de section
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
  
  // Helper pour la boîte de dialogue de déconnexion
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
              onPressed: () {
                Navigator.of(dialogContext).pop(); // Ferme la dialogue
              },
            ),
            TextButton(
              child: const Text('Confirmer', style: TextStyle(color: Colors.red)),
              onPressed: () {
                // Ici, on mettrait la vraie logique de déconnexion
                print("Déconnexion de l'utilisateur...");
                Navigator.of(dialogContext).pop(); // Ferme la dialogue
              },
            ),
          ],
        );
      },
    );
  }
}