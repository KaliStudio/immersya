// lib/features/team/screens/team_screen.dart

import 'package:flutter/material.dart';
import 'package:immersya_mobile_app/api/mock_api_service.dart';
import 'package:immersya_mobile_app/features/auth/services/auth_service.dart';
import 'package:immersya_mobile_app/models/team_model.dart';
import 'package:provider/provider.dart';

class TeamScreen extends StatefulWidget {
  const TeamScreen({super.key});
  @override
  State<TeamScreen> createState() => _TeamScreenState();
}

class _TeamScreenState extends State<TeamScreen> {
  // Un seul Future pour piloter tout l'écran
  Future<Map<String, dynamic>>? _teamDataFuture;

  @override
  void initState() {
    super.initState();
    // On lance le chargement initial des données
    _loadTeamData();
  }
  
  // Méthode pour (re)charger toutes les données nécessaires
  void _loadTeamData() {
    setState(() {
      _teamDataFuture = _fetchTeamData();
    });
  }
  
  // Fonction asynchrone qui récupère les données
  Future<Map<String, dynamic>> _fetchTeamData() async {
    // On utilise context.read car on est dans une méthode appelée par l'état
    final authService = context.read<AuthService>();
    final apiService = context.read<MockApiService>();
    final currentUser = authService.currentUser;

    if (currentUser == null) throw Exception("Utilisateur non connecté");

    final userProfile = await apiService.fetchUserProfile(userId: currentUser.id);
    final teamId = userProfile.teamId;
    
    // Si l'utilisateur n'a pas d'équipe, on retourne une structure vide
    if (teamId == null) {
      return {'team': null, 'members': <UserProfile>[], 'currentUserId': currentUser.id};
    }

    // Si l'utilisateur a une équipe, on charge ses détails et la liste des membres
    final results = await Future.wait([
      apiService.fetchTeamDetails(teamId),
      apiService.fetchTeamMembers(teamId),
    ]);

    return {
      'team': results[0] as Team?,
      'members': (results[1] as List).cast<UserProfile>().toList(),
      'currentUserId': currentUser.id
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mon Équipe'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadTeamData,
          ),
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: _teamDataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("Erreur: ${snapshot.error}."));
          }
          if (!snapshot.hasData || snapshot.data == null) {
            return Center(child: ElevatedButton(onPressed: _loadTeamData, child: const Text("Réessayer")));
          }
          
          final Team? team = snapshot.data!['team'];
          final List<UserProfile> members = snapshot.data!['members'];
          final String currentUserId = snapshot.data!['currentUserId'];

          if (team == null) {
            return _NoTeamView(onActionCompleted: _loadTeamData);
          }
          return _TeamDetailsView(
            team: team, 
            members: members, 
            currentUserId: currentUserId, 
            onActionCompleted: _loadTeamData,
          );
        },
      ),
    );
  }
}

// --- WIDGET QUAND L'UTILISATEUR N'A PAS D'ÉQUIPE ---
class _NoTeamView extends StatelessWidget {
  final VoidCallback onActionCompleted;
  const _NoTeamView({required this.onActionCompleted});

  void _showCreateTeamDialog(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final tagController = TextEditingController();

    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: const Text("Créer une nouvelle équipe"),
      content: Form(key: formKey, child: Column(mainAxisSize: MainAxisSize.min, children: [
        TextFormField(controller: nameController, decoration: const InputDecoration(labelText: "Nom de l'équipe"), validator: (v) => v!.isEmpty ? "Requis" : null),
        TextFormField(controller: tagController, decoration: const InputDecoration(labelText: "Tag (3-5 car.)"), validator: (v) => v!.isEmpty ? "Requis" : null),
      ])),
      actions: [
        TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text("Annuler")),
        ElevatedButton(
          onPressed: () async {
            if (!formKey.currentState!.validate()) return;
            
            final navigator = Navigator.of(ctx);
            final apiService = context.read<MockApiService>();
            final authService = context.read<AuthService>();
            
            final newTeam = await apiService.createTeam(nameController.text, tagController.text, authService.currentUser!.id);
            
            if (newTeam != null) {
              onActionCompleted();
              navigator.pop();
            } else {
              // Gérer l'erreur
            }
          },
          child: const Text("Créer"),
        ),
      ],
    ));
  }

  void _showJoinTeamDialog(BuildContext context) {
    final apiService = context.read<MockApiService>();
    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: const Text("Rejoindre une équipe"),
      content: SizedBox(
        width: double.maxFinite,
        child: FutureBuilder<List<Team>>(
          future: apiService.fetchAllTeams(),
          builder: (dialogContext, snapshot) {
            if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
            return ListView.builder(shrinkWrap: true, itemCount: snapshot.data!.length, itemBuilder: (listContext, index) {
              final team = snapshot.data![index];
              return ListTile(
                title: Text(team.name),
                subtitle: Text(team.description),
                onTap: () async {
                  final navigator = Navigator.of(ctx);
                  final authService = context.read<AuthService>();
                  await apiService.joinTeam(authService.currentUser!.id, team.id);
                  onActionCompleted();
                  navigator.pop();
                },
              );
            });
          },
        ),
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.group_add_outlined, size: 60, color: Colors.grey),
          const SizedBox(height: 16),
          const Text("Vous n'êtes dans aucune équipe.", style: TextStyle(fontSize: 18)),
          const SizedBox(height: 24),
          ElevatedButton(onPressed: () => _showCreateTeamDialog(context), child: const Text("Créer une équipe")),
          const SizedBox(height: 12),
          OutlinedButton(onPressed: () => _showJoinTeamDialog(context), child: const Text("Rejoindre une équipe")),
        ]),
      ),
    );
  }
}


// --- VUE QUAND L'UTILISATEUR A UNE ÉQUIPE ---
class _TeamDetailsView extends StatelessWidget {
  final Team team;
  final List<UserProfile> members;
  final String currentUserId;
  final VoidCallback onActionCompleted;

  const _TeamDetailsView({required this.team, required this.members, required this.currentUserId, required this.onActionCompleted});

  void _showLeaveTeamDialog(BuildContext context) {
     final isCreator = team.creatorId == currentUserId;
     final contentText = isCreator ? "Vous êtes le créateur. Quitter transférera la propriété ou dissoudra l'équipe. Confirmer ?" : "Êtes-vous sûr de vouloir quitter cette équipe ?";
     showDialog(context: context, builder: (ctx) => AlertDialog(
        title: const Text("Quitter l'équipe"),
        content: Text(contentText),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text("Annuler")),
          TextButton(
            child: const Text("Confirmer", style: TextStyle(color: Colors.red)),
            onPressed: () async {
              final navigator = Navigator.of(ctx);
              await context.read<MockApiService>().leaveTeam(currentUserId);
              onActionCompleted();
              navigator.pop();
            },
          ),
        ],
     ));
  }
  
  void _showExcludeMemberDialog(BuildContext context, UserProfile memberToExclude) {
     showDialog(context: context, builder: (ctx) => AlertDialog(
        title: Text("Exclure ${memberToExclude.username}"),
        content: const Text("Êtes-vous sûr de vouloir exclure ce membre ?"),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text("Annuler")),
          TextButton(
            child: const Text("Exclure", style: TextStyle(color: Colors.red)),
            onPressed: () async {
              final navigator = Navigator.of(ctx);
              await context.read<MockApiService>().excludeMember(memberToExclude.id, team.id);
              onActionCompleted();
              navigator.pop();
            },
          ),
        ],
     ));
  }

  @override
  Widget build(BuildContext context) {
    final totalPoints = members.fold(0, (sum, member) => sum + member.immersyaPoints);
    final totalScans = members.fold(0, (sum, member) => sum + member.scansValidated);
    final bool isCurrentUserTheCreator = currentUserId == team.creatorId;

    return RefreshIndicator(
      onRefresh: () async => onActionCompleted(),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          Stack(children: [
            Container(height: 150, color: Colors.grey[800], child: Center(child: Text(team.name, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)))),
            Positioned(top: 8, right: 8, child: IconButton(icon: const Icon(Icons.exit_to_app, color: Colors.white), tooltip: "Quitter l'équipe", onPressed: () => _showLeaveTeamDialog(context))),
          ]),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(team.description, style: const TextStyle(fontSize: 16, color: Colors.grey)),
              const Divider(height: 48),
              Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
                _Stat(title: 'Points Totaux', value: totalPoints.toString()), 
                _Stat(title: 'Membres', value: members.length.toString()), 
                _Stat(title: 'Scans Totaux', value: totalScans.toString())
              ]),
              const SizedBox(height: 32),
              Text('Membres', style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 16),
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: members.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final member = members[index];
                  final bool isThisMemberTheCreator = member.id == team.creatorId;
                  final bool isThisMemberTheCurrentUser = member.id == currentUserId;
                  
                  Widget? trailingWidget;
                  if (isCurrentUserTheCreator && !isThisMemberTheCurrentUser) {
                    trailingWidget = IconButton(
                      icon: const Icon(Icons.person_remove_outlined, color: Colors.redAccent),
                      tooltip: "Exclure le membre",
                      onPressed: () => _showExcludeMemberDialog(context, member),
                    );
                  } else {
                    trailingWidget = Text('${member.immersyaPoints} pts');
                  }
      
                  return ListTile(
                    leading: CircleAvatar(child: Icon(isThisMemberTheCreator ? Icons.workspace_premium_outlined : Icons.person_outline)),
                    title: Text(member.username, style: isThisMemberTheCurrentUser ? const TextStyle(fontWeight: FontWeight.bold, color: Colors.cyan) : null),
                    subtitle: Text(isThisMemberTheCreator ? 'Créateur' : member.rank),
                    trailing: trailingWidget,
                  );
                },
              ),
            ]),
          )
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String title; final String value;
  const _Stat({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)), 
      const SizedBox(height: 4), 
      Text(title, style: const TextStyle(color: Colors.grey))
    ]);
  }
}