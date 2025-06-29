// lib/features/profile/screens/profile_screen.dart

import 'package:flutter/material.dart';
import 'package:immersya_mobile_app/features/profile/screens/settings_screen.dart';
import 'package:provider/provider.dart';
import 'package:immersya_mobile_app/features/auth/services/auth_service.dart';
import 'package:immersya_mobile_app/features/profile/state/profile_state.dart';
import 'package:immersya_mobile_app/features/team/state/team_state.dart';
import 'package:immersya_mobile_app/models/team_model.dart';
import 'package:immersya_mobile_app/api/mock_api_service.dart';
import 'package:immersya_mobile_app/features/gamification/models/badge_model.dart' as gamification_models;

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

  void _showEditUsernameDialog(BuildContext context, String currentUsername) {
    final formKey = GlobalKey<FormState>();
    final usernameController = TextEditingController(text: currentUsername);

    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: const Text("Changer de nom d'utilisateur"),
      content: Form(key: formKey, child: TextFormField(controller: usernameController, decoration: const InputDecoration(labelText: "Nouveau nom"), validator: (v) => v!.isEmpty ? "Requis" : null)),
      actions: [
        TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text("Annuler")),
        ElevatedButton(
          onPressed: () async {
            if (!formKey.currentState!.validate()) return;
            
            final navigator = Navigator.of(ctx);
            // On appelle la méthode du ProfileState
            final success = await context.read<ProfileState>().updateUsername(usernameController.text);
            
            if (success) {
              navigator.pop();
            } else {
              // Gérer l'affichage de l'erreur
              final error = context.read<ProfileState>().error;
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error ?? "Une erreur est survenue"), backgroundColor: Colors.red));
            }
          },
          child: const Text("Sauvegarder"),
        ),
      ],
    ));
  }

class _ProfileScreenState extends State<ProfileScreen> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  // Pas besoin de Future local, les States s'en occupent.

  @override
  void initState() {
    super.initState();
    // On peut potentiellement déclencher un rafraîchissement ici si nécessaire,
    // mais la logique est déjà dans les `init` des States.
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Nécessaire pour AutomaticKeepAliveClientMixin

    // On écoute les changements des providers dont on a besoin.
    final profileState = context.watch<ProfileState>();
    final teamState = context.watch<TeamState>();
    final authService = context.watch<AuthService>();

    final profile = profileState.userProfile;
    final team = teamState.currentTeam;
    final badges = profileState.unlockedBadges;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mon Profil'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsScreen())),
          ),
        ],
      ),
      body: Builder(
        builder: (context) {
          if (authService.isLoading || profileState.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (profile == null) {
            return const Center(child: Text("Utilisateur non trouvé."));
          }
          return RefreshIndicator(
            // On appelle la méthode de rafraîchissement du service qui est la source de vérité.
            onRefresh: () => context.read<AuthService>().refreshCurrentUser(),
            child: _buildProfileView(context, profile, team, badges),
          );
        },
      ),
    );
  }

  Widget _buildProfileView(BuildContext context, UserProfile profile, Team? team, List<gamification_models.Badge> badges) {
    final theme = Theme.of(context);
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16.0),
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(color: theme.colorScheme.surface, borderRadius: BorderRadius.circular(16)),
          child: Column(children: [
            const CircleAvatar(radius: 50, backgroundColor: Colors.blueGrey, child: Icon(Icons.person, size: 60, color: Colors.white)),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(profile.username, style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
                IconButton(
                  icon: Icon(Icons.edit_outlined, size: 20, color: Colors.grey[400]),
                  onPressed: () => _showEditUsernameDialog(context, profile.username),
                ),
              ],
            ),
            const SizedBox(height: 4),
            if (team != null)
              Text("${team.tag} ${team.name}", style: theme.textTheme.titleMedium?.copyWith(color: Colors.cyan))
            else
              Text(profile.rank, style: theme.textTheme.titleLarge?.copyWith(color: Colors.grey[400])),
          ]),
        ),
        const SizedBox(height: 24),
        Text('Statistiques', style: theme.textTheme.titleLarge),
        const SizedBox(height: 16),
        _buildStatCard(context, icon: Icons.star_border, label: 'Immersya Points', value: profile.immersyaPoints.toString(), color: Colors.amber),
        const SizedBox(height: 12),
        _buildStatCard(context, icon: Icons.map_outlined, label: 'Surface Couverte', value: '${profile.areaCoveredKm2} km²', color: Colors.green),
        const SizedBox(height: 12),
        _buildStatCard(context, icon: Icons.check_circle_outline, label: 'Scans Validés', value: profile.scansValidated.toString(), color: Colors.blue),
        const SizedBox(height: 24),
        Text('Badges Débloqués (${badges.length})', style: theme.textTheme.titleLarge),
        const SizedBox(height: 16),
        _buildBadgesSection(context, badges),
        const SizedBox(height: 32),
        ElevatedButton.icon(
          onPressed: () => context.read<AuthService>().logout(),
          icon: const Icon(Icons.logout),
          label: const Text('Se Déconnecter'),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red[700], foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 12)),
        ),
      ],
    );
  }

  Widget _buildStatCard(BuildContext context, {required IconData icon, required String label, required String value, required Color color}) {
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

  Widget _buildBadgesSection(BuildContext context, List<gamification_models.Badge> badges) {
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
          showDialog(context: context, builder: (ctx) => AlertDialog(
            title: Row(children: [Icon(badge.icon, color: badge.color), const SizedBox(width: 10), Text(badge.name)]),
            content: Text(badge.description),
            actions: [TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Fermer'))],
          ));
        },
        borderRadius: BorderRadius.circular(12),
        child: Ink(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, borderRadius: BorderRadius.circular(12)),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(badge.icon, color: badge.color, size: 32),
            const SizedBox(height: 4),
            Expanded(child: FittedBox(fit: BoxFit.scaleDown, child: Text(badge.name, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)))),
          ]),
        ),
      ),
    );
  }
}