// lib/features/profile/screens/profile_screen.dart
import 'package:flutter/material.dart';
import 'package:immersya_mobile_app/api/mock_api_service.dart';
import 'package:immersya_mobile_app/features/capture/capture_state.dart';
import 'package:immersya_mobile_app/features/profile/screens/settings_screen.dart';
import 'package:provider/provider.dart';
// --- Nouveaux imports pour la logique d'authentification ---
import 'package:immersya_mobile_app/features/auth/services/auth_service.dart';
import 'package:immersya_mobile_app/models/user_model.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Future<UserProfile>? _userProfileFuture;
  UserProfile? _currentProfile;
  late CaptureState _captureState;
  User? _currentUser; // Référence à l'utilisateur authentifié

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // On récupère l'utilisateur connecté depuis AuthService
      _currentUser = context.read<AuthService>().currentUser;
      
      if (_currentUser != null) {
        _loadProfileData();
      }
      
      // On initialise l'écouteur pour la mise à jour des points en temps réel
      _captureState = context.read<CaptureState>();
      _captureState.addListener(_onCaptureStateChanged);
    });
  }

  @override
  void dispose() {
    _captureState.removeListener(_onCaptureStateChanged);
    super.dispose();
  }

  // Cette méthode met à jour l'état local du profil quand des points sont gagnés
  void _onCaptureStateChanged() {
    if (_captureState.lastGainedPoints > 0 && _currentProfile != null) {
      if (mounted) {
        setState(() {
          _currentProfile = UserProfile(
            username: _currentProfile!.username,
            rank: _currentProfile!.rank,
            areaCoveredKm2: _currentProfile!.areaCoveredKm2,
            scansValidated: _currentProfile!.scansValidated + 1,
            immersyaPoints: _currentProfile!.immersyaPoints + _captureState.lastGainedPoints,
          );
        });
      }
    }
  }

  // Cette méthode charge (ou recharge) les données du profil depuis l'API
  void _loadProfileData() {
    if (mounted && _currentUser != null) {
      final apiService = context.read<MockApiService>();
      setState(() {
         // On passe l'ID de l'utilisateur connecté pour récupérer le bon profil
         _userProfileFuture = apiService.fetchUserProfile(userId: _currentUser!.id);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUser == null) {
      return const Scaffold(body: Center(child: Text("Utilisateur non connecté.")));
    }
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mon Profil'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: FutureBuilder<UserProfile>(
        future: _userProfileFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting && _currentProfile == null) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Erreur: ${snapshot.error}'));
          }
          if (snapshot.hasData && _currentProfile == null) {
            _currentProfile = snapshot.data;
          }
          if (_currentProfile == null) {
            return const Center(child: Text('Impossible de charger le profil.'));
          }

          return _buildProfileView(_currentProfile!);
        },
      ),
    );
  }

  Widget _buildProfileView(UserProfile profile) {
    final theme = Theme.of(context);
    return RefreshIndicator(
      onRefresh: () async { _loadProfileData(); },
      child: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Header du profil (inchangé)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(16)),
            child: Column(
              children: [
                const CircleAvatar(
                 radius: 50,
                 backgroundColor: Colors.blueGrey,
                 child: Icon(Icons.person, size: 60, color: Colors.white)),
                const SizedBox(height: 16),
                Text(profile.username, style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(
                  profile.rank,
                  style: theme.textTheme.titleLarge?.copyWith(color: Colors.cyanAccent)
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text('Statistiques', style: theme.textTheme.titleLarge),
          const SizedBox(height: 16),
          // Cartes de statistiques (inchangées)
          _buildStatCard(
            icon: Icons.star_border,
            label: 'Immersya Points',
            value: profile.immersyaPoints.toString(),
            color: Colors.amber),
            const SizedBox(height: 12),
          _buildStatCard(
            icon: Icons.map_outlined,
            label: 'Surface Couverte',
            value: '${profile.areaCoveredKm2} km²',
            color: Colors.green),
            const SizedBox(height: 12),
          _buildStatCard(
            icon: Icons.check_circle_outline,
            label: 'Scans Validés',
            value: profile.scansValidated.toString(),
            color: Colors.blue),
            const SizedBox(height: 32),
          // Bouton de déconnexion (ajouté)
          ElevatedButton.icon(
            onPressed: () {
              context.read<AuthService>().logout();
            },
            icon: const Icon(Icons.logout),
            label: const Text('Se Déconnecter'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[700],
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({required IconData icon, required String label, required String value, required Color color}) {
    final theme = Theme.of(context);
    return Card(
      color: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(icon, color: color, size: 30),
        title: Text(label, style: theme.textTheme.bodyLarge),
        trailing: Text(
          value,
          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)
        ),
      ),
    );
  }
}