// lib/features/profile/screens/profile_screen.dart

import 'package:flutter/material.dart';
import 'package:immersya_mobile_app/api/mock_api_service.dart';
import 'package:immersya_mobile_app/features/capture/capture_state.dart';
import 'package:immersya_mobile_app/features/profile/screens/settings_screen.dart';
import 'package:provider/provider.dart';
import 'package:immersya_mobile_app/features/auth/services/auth_service.dart';
// import 'package:immersya_mobile_app/models/user_model.dart';
import 'package:immersya_mobile_app/features/gamification/models/badge_model.dart' as gamification_models;
import 'package:immersya_mobile_app/features/gamification/services/gamification_service.dart';
import 'package:latlong2/latlong.dart';
import 'package:immersya_mobile_app/models/team_model.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with AutomaticKeepAliveClientMixin  {
  // Un seul Future pour piloter le chargement de toutes les données de l'écran
  Future<Map<String, dynamic>>? _profileDataFuture;

  // Services
  late CaptureState _captureState;
  
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    // On utilise didChangeDependencies pour un accès sûr au Provider
  }
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // On ne charge les données qu'une seule fois au début
    if (_profileDataFuture == null) {
      // On s'abonne à CaptureState ici
      _captureState = context.read<CaptureState>();
      _captureState.addListener(_onCaptureStateChanged);
      _loadProfileData();
    }
  }

  @override
  void dispose() {
    _captureState.removeListener(_onCaptureStateChanged);
    super.dispose();
  }

  // Recharge toutes les données depuis l'API en assignant un nouveau Future
  void _loadProfileData() {
    setState(() {
      _profileDataFuture = _fetchProfileData();
    });
  }

  // Fonction centrale pour récupérer toutes les données nécessaires à l'écran
  Future<Map<String, dynamic>> _fetchProfileData() async {
    final authService = context.read<AuthService>();
    final apiService = context.read<MockApiService>();
    final gamificationService = GamificationService(apiService);

    final userId = authService.currentUser?.id;
    if (userId == null) throw Exception("Utilisateur non authentifié.");

    // 1. Charger le profil de l'utilisateur
    final userProfile = await apiService.fetchUserProfile(userId: userId);
    
    // 2. Si le profil a un teamId, charger les détails de l'équipe
    Team? team;
    if (userProfile.teamId != null) {
      team = await apiService.fetchTeamDetails(userProfile.teamId!);
    }
    
    // 3. Charger les badges débloqués
    final badges = await gamificationService.getUnlockedBadges(userProfile);

    // On retourne un Map avec toutes les données pour le FutureBuilder
    return {
      'profile': userProfile,
      'team': team,
      'badges': badges,
    };
  }
  
  // Met à jour l'état local après une capture, sans recharger depuis l'API
  void _onCaptureStateChanged() async {
    // S'assurer que le Future est complété avant de lire ses données
    if (_profileDataFuture == null) return;
    
    final currentData = await _profileDataFuture!;
    UserProfile currentProfile = currentData['profile'];
    
    if (_captureState.lastGainedPoints > 0) {
      UserProfile updatedProfile = currentProfile.copyWith(
        scansValidated: currentProfile.scansValidated + 1,
        immersyaPoints: currentProfile.immersyaPoints + _captureState.lastGainedPoints,
      );
      
      // On met à jour le Future avec les nouvelles données locales pour un affichage immédiat
      setState(() {
        _profileDataFuture = Future.value({
          'profile': updatedProfile,
          'team': currentData['team'],
          'badges': currentData['badges'],
        });
      });
      
      // En arrière-plan, on lance la mise à jour de la localisation
      if (_captureState.lastCaptureLocation != null && context.read<AuthService>().currentUser != null) {
        _updateProfileLocationInBackground(_captureState.lastCaptureLocation!);
      }
    }
  }

  Future<void> _updateProfileLocationInBackground(LatLng lastCaptureLocation) async {
    final authService = context.read<AuthService>();
    final apiService = context.read<MockApiService>();
    final gamificationService = GamificationService(apiService);

    final userId = authService.currentUser?.id;
    if (userId == null) return;
    
    await apiService.logCapture(userId, lastCaptureLocation);
    final newLocation = await gamificationService.determinePrimaryLocation(userId);

    if (newLocation.isNotEmpty) {
      final currentData = await _profileDataFuture!;
      final currentProfile = currentData['profile'] as UserProfile;
      
      if (newLocation['city'] != null && newLocation['city'] != currentProfile.city) {
         await apiService.updateMockUserLocation(
            userId,
            country: newLocation['country'],
            region: newLocation['region'],
            city: newLocation['city'],
         );
         _loadProfileData(); // On recharge tout pour que les données soient à jour
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mon Profil'),
        centerTitle: true,
        actions: [
          IconButton(icon: const Icon(Icons.settings_outlined), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsScreen()))),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => _loadProfileData(),
        child: FutureBuilder<Map<String, dynamic>>(
          future: _profileDataFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text("Erreur: ${snapshot.error}"));
            }
            if (!snapshot.hasData) {
              return const Center(child: Text("Aucun profil trouvé."));
            }

            final profile = snapshot.data!['profile'] as UserProfile;
            final team = snapshot.data!['team'] as Team?;
            final badges = snapshot.data!['badges'] as List<gamification_models.Badge>;

            return _buildProfileView(profile, team, badges);
          },
        ),
      ),
    );
  }

  Widget _buildProfileView(UserProfile profile, Team? team, List<gamification_models.Badge> badges) {
    final theme = Theme.of(context);
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
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
              // Affiche le nom de l'équipe si elle existe, sinon le rang
              if (team != null)
                Text("${team.tag} ${team.name}", style: theme.textTheme.titleMedium?.copyWith(color: Colors.cyan))
              else
                Text(profile.rank, style: theme.textTheme.titleLarge?.copyWith(color: Colors.grey[400])),
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
        Text('Badges Débloqués (${badges.length})', style: theme.textTheme.titleLarge),
        const SizedBox(height: 16),
        _buildBadgesSection(badges),
        const SizedBox(height: 32),

        // Bouton de déconnexion
        ElevatedButton.icon(
          onPressed: () => context.read<AuthService>().logout(),
          icon: const Icon(Icons.logout),
          label: const Text('Se Déconnecter'),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red[700], foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 12)),
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

  Widget _buildBadgesSection(List<gamification_models.Badge> badges) {
    if (badges.isEmpty) {
      return Card(
        color: Theme.of(context).colorScheme.surface,
        child: const Padding(
          padding: EdgeInsets.all(24.0),
          child: Text("Continuez à explorer pour débloquer votre premier badge !", textAlign: TextAlign.center, style: TextStyle(fontStyle: FontStyle.italic)),
        ),
      );
    }
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 4, crossAxisSpacing: 12, mainAxisSpacing: 12),
      itemCount: badges.length,
      itemBuilder: (context, index) => _BadgeWidget(badge: badges[index]),
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
          decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, borderRadius: BorderRadius.circular(12)),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(badge.icon, color: badge.color, size: 32),
              const SizedBox(height: 4),
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(badge.name, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}