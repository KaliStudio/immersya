import 'package:flutter/material.dart';
import 'package:immersya_mobile_app/api/mock_api_service.dart';
import 'package:immersya_mobile_app/features/capture/capture_state.dart';
import 'package:immersya_mobile_app/features/profile/screens/settings_screen.dart';
import 'package:provider/provider.dart';
import 'package:immersya_mobile_app/features/auth/services/auth_service.dart';
import 'package:immersya_mobile_app/models/user_model.dart';
import 'package:immersya_mobile_app/features/gamification/models/badge_model.dart' as gamification_models;
import 'package:immersya_mobile_app/features/gamification/services/gamification_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
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
      // On récupère l'utilisateur connecté depuis AuthService
      final apiService = context.read<MockApiService>();
      _gamificationService = GamificationService(apiService);
      // On initialise l'écouteur pour la mise à jour des points en temps réel
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

  // Cette méthode met à jour l'état local du profil quand des points sont gagnés
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
              Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsScreen()));
            },
          ),
        ],
      ),
      body: _isLoadingProfile
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
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
        Text('Statistiques', style: theme.textTheme.titleLarge),
        const SizedBox(height: 16),
        _buildStatCard(icon: Icons.star_border, label: 'Immersya Points', value: profile.immersyaPoints.toString(), color: Colors.amber),
        const SizedBox(height: 12),
        _buildStatCard(icon: Icons.map_outlined, label: 'Surface Couverte', value: '${profile.areaCoveredKm2} km²', color: Colors.green),
        const SizedBox(height: 12),
        _buildStatCard(icon: Icons.check_circle_outline, label: 'Scans Validés', value: profile.scansValidated.toString(), color: Colors.blue),
        const SizedBox(height: 24),
        Text('Badges Débloqués (${_unlockedBadges.length})', style: theme.textTheme.titleLarge),
        const SizedBox(height: 16),
        _buildBadgesSection(),
        const SizedBox(height: 32),
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
          child: Text("Continuez à explorer pour débloquer votre premier badge !", textAlign: TextAlign.center, style: TextStyle(fontStyle: FontStyle.italic)),
        ),
      );
    }
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 4, crossAxisSpacing: 12, mainAxisSpacing: 12),
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
          decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, borderRadius: BorderRadius.circular(12)),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(badge.icon, color: badge.color, size: 32),
              const SizedBox(height: 4),
              //Text(badge.name, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold), maxLines: 2, overflow: TextOverflow.ellipsis),
            Expanded(
                child: FittedBox(
                  child: Text(
                    badge.name,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold), // Police légèrement plus petite
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
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