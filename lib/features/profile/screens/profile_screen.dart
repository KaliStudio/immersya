// lib/features/profile/screens/profile_screen.dart

import 'package:flutter/material.dart';
import 'package:immersya_mobile_app/api/mock_api_service.dart';
import 'package:immersya_mobile_app/features/capture/capture_state.dart';
import 'package:immersya_mobile_app/features/profile/screens/settings_screen.dart';
import 'package:provider/provider.dart';
import 'package:immersya_mobile_app/features/auth/services/auth_service.dart';
import 'package:immersya_mobile_app/models/user_model.dart';
import 'package:immersya_mobile_app/features/gamification/models/badge_model.dart' as gamification_models;
import 'package:immersya_mobile_app/features/gamification/services/gamification_service.dart';
import 'package:latlong2/latlong.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with AutomaticKeepAliveClientMixin  {
  // --- VARIABLES D'ÉTAT ---
  User? _currentUser;
  UserProfile? _currentProfile;
  late GamificationService _gamificationService;
  List<gamification_models.Badge> _unlockedBadges = [];
  bool _isLoadingProfile = true;
  late CaptureState _captureState;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Initialisation des services et de l'écouteur
      final apiService = context.read<MockApiService>();
      _gamificationService = GamificationService(apiService);
      _captureState = context.read<CaptureState>();
      _captureState.addListener(_onCaptureStateChanged);
      _currentUser = context.read<AuthService>().currentUser;
      
      if (_currentUser != null) {
        _loadProfileData();
      } else {
        setState(() => _isLoadingProfile = false);
      }
    });
  }

  @override
  void dispose() {
    _captureState.removeListener(_onCaptureStateChanged);
    super.dispose();
  }

  // --- LOGIQUE DE GESTION DES DONNÉES ---

  // Recharge toutes les données du profil et des badges depuis l'API.
  Future<void> _loadProfileData() async {
    if (!mounted) return;
    setState(() => _isLoadingProfile = true);

    if (_currentUser != null) {
      final apiService = context.read<MockApiService>();
      final profile = await apiService.fetchUserProfile(userId: _currentUser!.id);
      final badges = await _gamificationService.getUnlockedBadges(profile);
      
      if (mounted) {
        setState(() {
          _currentProfile = profile;
          _unlockedBadges = badges;
          _isLoadingProfile = false;
        });
      }
    } else {
       if (mounted) setState(() => _isLoadingProfile = false);
    }
  }

  // Méthode appelée chaque fois qu'une capture est terminée.
  void _onCaptureStateChanged() {
    final lastLocation = _captureState.lastCaptureLocation;
    // On vérifie que toutes les conditions sont réunies pour une mise à jour.
    if (_captureState.lastGainedPoints > 0 && _currentProfile != null && _currentUser != null && lastLocation != null) {
      
      // 1. Mettre à jour l'UI immédiatement pour le feedback des points (mise à jour locale)
      if (mounted) {
        setState(() {
          _currentProfile = _currentProfile!.copyWith(
            scansValidated: _currentProfile!.scansValidated + 1,
            immersyaPoints: _currentProfile!.immersyaPoints + _captureState.lastGainedPoints,
          );
        });
      }
      
      // 2. Lancer la logique complexe de mise à jour de la localisation en arrière-plan
      _updateProfileLocationInBackground(lastLocation);
    }
  }

  // Lance le processus de mise à jour de la localisation principale.
  Future<void> _updateProfileLocationInBackground(LatLng lastCaptureLocation) async {
    if (_currentUser == null) return;
    
    final userId = _currentUser!.id;
    final apiService = context.read<MockApiService>();
    
    // a. Enregistrer la nouvelle capture dans l'historique
    await apiService.logCapture(userId, lastCaptureLocation);

    // b. Déterminer la nouvelle localisation principale à partir de l'historique
    final newLocation = await _gamificationService.determinePrimaryLocation(userId);

    // c. Si la localisation principale a changé, on met à jour le profil dans l'API
    if (newLocation.isNotEmpty) {
      final newCity = newLocation['city'];
      if (newCity != null && newCity != _currentProfile?.city) {
         //print("Changement de localisation détecté ! Mise à jour du profil.");
         await apiService.updateMockUserLocation(
            userId,
            country: newLocation['country'],
            region: newLocation['region'],
            city: newCity,
         );
        // d. Recharger toutes les données pour que l'UI soit parfaitement synchronisée
        if (mounted) _loadProfileData();
      }
    }
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (_isLoadingProfile) {
      return Scaffold(appBar: AppBar(title: const Text('Mon Profil')), body: const Center(child: CircularProgressIndicator()));
    }
    if (_currentProfile == null) {
      return Scaffold(appBar: AppBar(title: const Text('Mon Profil')), body: const Center(child: Text("Connectez-vous pour voir votre profil.")));
    }
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mon Profil'),
        centerTitle: true,
        actions: [
          IconButton(icon: const Icon(Icons.settings_outlined), onPressed: () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsScreen()));
          }),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadProfileData,
        child: _buildProfileView(_currentProfile!),
      ),
    );
  }

  Widget _buildProfileView(UserProfile profile) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        // Header du profil
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(color: theme.colorScheme.surface, borderRadius: BorderRadius.circular(16)),
          child: Column(
            children: [
              const CircleAvatar(radius: 50, backgroundColor: Colors.blueGrey, child: Icon(Icons.person, size: 60, color: Colors.white)),
              const SizedBox(height: 16),
              Text(profile.username, style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(profile.rank, style: theme.textTheme.titleLarge?.copyWith(color: Colors.cyanAccent)),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Section des statistiques
        Text('Statistiques', style: theme.textTheme.titleLarge),
        const SizedBox(height: 16),
        _buildStatCard(icon: Icons.star_border, label: 'Immersya Points', value: profile.immersyaPoints.toString(), color: Colors.amber),
        const SizedBox(height: 12),
        _buildStatCard(icon: Icons.map_outlined, label: 'Surface Couverte', value: '${profile.areaCoveredKm2} km²', color: Colors.green),
        const SizedBox(height: 12),
        _buildStatCard(icon: Icons.check_circle_outline, label: 'Scans Validés', value: profile.scansValidated.toString(), color: Colors.blue),
        const SizedBox(height: 24),
        
        // Section des badges
        Text('Badges Débloqués (${_unlockedBadges.length})', style: theme.textTheme.titleLarge),
        const SizedBox(height: 16),
        _buildBadgesSection(),
        const SizedBox(height: 32),

        // Bouton de déconnexion
        ElevatedButton.icon(
          onPressed: () => context.read<AuthService>().logout(),
          icon: const Icon(Icons.logout),
          label: const Text('Se Déconnecter'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red[700],
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
      ],
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
        trailing: Text(value, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildBadgesSection() {
    if (_unlockedBadges.isEmpty) {
      return Card(
        color: Theme.of(context).colorScheme.surface,
        child: const Padding(
          padding: EdgeInsets.all(24.0),
          child: Text(
            "Continuez à explorer pour débloquer votre premier badge !",
            textAlign: TextAlign.center,
            style: TextStyle(fontStyle: FontStyle.italic),
          ),
        ),
      );
    }
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: _unlockedBadges.length,
      itemBuilder: (context, index) {
        final badge = _unlockedBadges[index];
        return _BadgeWidget(badge: badge);
      },
    );
  }
}

class _BadgeWidget extends StatelessWidget {
  final gamification_models.Badge badge;
  const _BadgeWidget({required this.badge});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: "${badge.name}\n${badge.description}",
      child: InkWell(
        onTap: () {
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              title: Row(children: [Icon(badge.icon, color: badge.color), const SizedBox(width: 10), Text(badge.name)]),
              content: Text(badge.description),
              actions: [TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Fermer'))],
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Ink(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(badge.icon, color: badge.color, size: 32),
              const SizedBox(height: 4),
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    badge.name,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}