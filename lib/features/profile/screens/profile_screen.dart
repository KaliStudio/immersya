// lib/features/profile/screens/profile_screen.dart
import 'package:flutter/material.dart';
import 'package:immersya_mobile_app/api/mock_api_service.dart';
import 'package:immersya_mobile_app/features/capture/capture_state.dart';
import 'package:immersya_mobile_app/features/profile/screens/settings_screen.dart';
import 'package:provider/provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Future<UserProfile>? _userProfileFuture;
  UserProfile? _currentProfile;
  late CaptureState _captureState;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadProfileData();
      
      // Initialiser et écouter CaptureState
      _captureState = context.read<CaptureState>();
      _captureState.addListener(_onCaptureStateChanged);
    });
  }

  @override
  void dispose() {
    _captureState.removeListener(_onCaptureStateChanged);
    super.dispose();
  }

  void _onCaptureStateChanged() {
    if (_captureState.lastGainedPoints > 0 && _currentProfile != null) {
      if (mounted) {
        setState(() {
          _currentProfile = UserProfile(
            username: _currentProfile!.username,
            rank: _currentProfile!.rank,
            areaCoveredKm2: _currentProfile!.areaCoveredKm2,
            scansValidated: _currentProfile!.scansValidated + 1, // On incrémente aussi les scans
            immersyaPoints: _currentProfile!.immersyaPoints + _captureState.lastGainedPoints,
          );
        });
      }
    }
  }

  void _loadProfileData() {
    if(mounted) {
      final apiService = context.read<MockApiService>();
      setState(() {
         _userProfileFuture = apiService.fetchUserProfile();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
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
            return const Center(child: Text('Aucun profil trouvé.'));
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
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                const CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.blueGrey,
                  child: Icon(Icons.person, size: 60, color: Colors.white),
                ),
                const SizedBox(height: 16),
                Text(
                  profile.username,
                  style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  profile.rank,
                  style: theme.textTheme.titleLarge?.copyWith(color: Colors.cyanAccent),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text('Statistiques', style: theme.textTheme.titleLarge),
          const SizedBox(height: 16),
          _buildStatCard(
            icon: Icons.star_border,
            label: 'Immersya Points',
            value: profile.immersyaPoints.toString(),
            color: Colors.amber,
          ),
          const SizedBox(height: 12),
          _buildStatCard(
            icon: Icons.map_outlined,
            label: 'Surface Couverte',
            value: '${profile.areaCoveredKm2} km²',
            color: Colors.green,
          ),
          const SizedBox(height: 12),
          _buildStatCard(
            icon: Icons.check_circle_outline,
            label: 'Scans Validés',
            value: profile.scansValidated.toString(),
            color: Colors.blue,
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
          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}