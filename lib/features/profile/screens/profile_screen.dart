// lib/features/profile/screens/profile_screen.dart
import 'package:flutter/material.dart';
import 'package:immersya_pathfinder/api/mock_api_service.dart';
import 'package:immersya_pathfinder/features/profile/screens/settings_screen.dart';
import 'package:provider/provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Future<UserProfile>? _userProfileFuture;

  @override
  void initState() {
    super.initState();
    // Charger les données du profil au démarrage de l'écran
    _loadProfileData();
  }

  void _loadProfileData() {
    final apiService = context.read<MockApiService>();
    _userProfileFuture = apiService.fetchUserProfile();
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
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Erreur: ${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return const Center(child: Text('Aucun profil trouvé.'));
          }

          final profile = snapshot.data!;
          return _buildProfileView(profile);
        },
      ),
    );
  }

  Widget _buildProfileView(UserProfile profile) {
    final theme = Theme.of(context);
    return RefreshIndicator(
      onRefresh: () async {
        setState(() {
          _loadProfileData();
        });
      },
      child: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Section d'identité
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
          
          // Section des statistiques
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