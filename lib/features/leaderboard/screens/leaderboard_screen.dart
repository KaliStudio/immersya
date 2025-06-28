// lib/features/leaderboard/screens/leaderboard_screen.dart

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:immersya_mobile_app/api/mock_api_service.dart';
import 'package:immersya_mobile_app/models/team_model.dart';
import 'package:provider/provider.dart';
import 'package:immersya_mobile_app/services/location_service.dart';
import 'package:visibility_detector/visibility_detector.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});
  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> with TickerProviderStateMixin {
  TabController? _tabController;
  bool _isLoading = true;
  List<Map<String, dynamic>> _tabData = [];
  final LocationService _locationService = LocationService();
  DateTime _lastLoadTime = DateTime.now().subtract(const Duration(minutes: 1));
  bool _isInitialLoad = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this, initialIndex: 0); // Commence avec 2 onglets fixes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAndBuildTabsFromGPS().then((_) {
        if (mounted) setState(() => _isInitialLoad = false);
      });
    });
  }

  String? _getBestRegion(Placemark placemark) {
    if (placemark.administrativeArea != null && placemark.administrativeArea!.isNotEmpty) return placemark.administrativeArea;
    if (placemark.subAdministrativeArea != null && placemark.subAdministrativeArea!.isNotEmpty) return placemark.subAdministrativeArea;
    return null;
  }

  void _onVisibilityChanged(VisibilityInfo info) {
    if (info.visibleFraction == 1.0 && !_isInitialLoad && DateTime.now().difference(_lastLoadTime).inSeconds > 30) {
      _lastLoadTime = DateTime.now();
      _loadAndBuildTabsFromGPS();
    }
  }

  Future<void> _loadAndBuildTabsFromGPS() async {
    if (!mounted) return;
    if (!_isLoading) setState(() => _isLoading = true);
    
    final position = await _locationService.getCurrentPosition();
    Placemark? placemark;
    if (position != null) {
      placemark = await _locationService.getPlacemarkFromCoordinates(position);
    }
    
    // --- CORRECTION : On spécifie explicitement le type de la carte ---
    final newTabData = <Map<String, dynamic>>[
      {'label': 'Global', 'type': 'individual', 'filter': <String, String?>{}},
      {'label': 'Équipes', 'type': 'team', 'filter': <String, String?>{}},
    ];
    
    if (placemark != null) {
      final country = placemark.country;
      final region = _getBestRegion(placemark);
      final city = placemark.locality;

      // On spécifie aussi le type ici pour la cohérence
      if (country != null && country.isNotEmpty) {
        newTabData.add({'label': country, 'type': 'individual', 'filter': <String, String?>{'country': country}});
      }
      if (region != null && region.isNotEmpty) {
        newTabData.add({'label': region, 'type': 'individual', 'filter': <String, String?>{'region': region}});
      }
      if (city != null && city.isNotEmpty) {
        newTabData.add({'label': city, 'type': 'individual', 'filter': <String, String?>{'city': city}});
      }
    }
    
    if (mounted) {
      int previousIndex = _tabController?.index ?? 0;
      _tabController?.dispose(); 
      
      setState(() {
        _tabData = newTabData;
        _tabController = TabController(length: _tabData.length, vsync: this, initialIndex: min(previousIndex, _tabData.length - 1));
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return VisibilityDetector(
      key: const Key('leaderboard-visibility-detector'),
      onVisibilityChanged: _onVisibilityChanged,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Classements'),
          centerTitle: true,
          actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _isLoading ? null : _loadAndBuildTabsFromGPS)],
          bottom: _isLoading
            ? const PreferredSize(preferredSize: Size.fromHeight(4.0), child: LinearProgressIndicator())
            : _tabController != null 
              ? TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  tabAlignment: TabAlignment.start, 
                  tabs: _tabData.map((data) => Tab(text: data['label'])).toList(),
                )
              : null,
        ),
        body: _isLoading 
          ? const Center(child: CircularProgressIndicator()) 
          : _tabController == null 
            ? Center(child: ElevatedButton(onPressed: _loadAndBuildTabsFromGPS, child: const Text("Charger les classements")))
            : TabBarView(
                controller: _tabController,
                children: _tabData.map((data) {
                  // Si l'onglet est de type 'team', on affiche la vue dédiée
                  if (data['type'] == 'team') {
                    return const _TeamLeaderboardListView(key: ValueKey('team-leaderboard'));
                  }
                  
                  // Sinon, c'est un classement individuel
                  final filter = data['filter'] as Map<String, String?>;
                  return _LeaderboardListView(key: ValueKey(filter.toString()), country: filter['country'], region: filter['region'], city: filter['city']);
                }).toList(),
              ),
      ),
    );
  }
}

// --- WIDGET POUR LE CLASSEMENT INDIVIDUEL (INCHANGÉ) ---
class _LeaderboardListView extends StatefulWidget {
  final String? country, region, city;
  const _LeaderboardListView({super.key, this.country, this.region, this.city});
  @override
  State<_LeaderboardListView> createState() => __LeaderboardListViewState();
}

class __LeaderboardListViewState extends State<_LeaderboardListView> with AutomaticKeepAliveClientMixin {
  Future<List<UserProfile>>? _leaderboardFuture;

  @override
  void initState() {
    super.initState();
    _loadLeaderboard();
  }

  void _loadLeaderboard() {
    if (mounted) {
      final apiService = context.read<MockApiService>();
      setState(() {
        _leaderboardFuture = apiService.fetchAllUserProfiles(country: widget.country, region: widget.region, city: widget.city);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return FutureBuilder<List<UserProfile>>(
      future: _leaderboardFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        if (snapshot.hasError) return Center(child: Text('Erreur: ${snapshot.error}'));
        if (!snapshot.hasData || snapshot.data!.isEmpty) return const Center(child: Text('Aucun contributeur dans ce classement.'));
        
        final sortedProfiles = snapshot.data!;
        sortedProfiles.sort((a, b) => b.immersyaPoints.compareTo(a.immersyaPoints));
        
        return RefreshIndicator(
          onRefresh: () async => _loadLeaderboard(),
          child: ListView.builder(itemCount: sortedProfiles.length, itemBuilder: (context, index) => _LeaderboardTile(profile: sortedProfiles[index], rank: index + 1)),
        );
      },
    );
  }

  @override
  bool get wantKeepAlive => true;
}

class _LeaderboardTile extends StatelessWidget {
  final UserProfile profile;
  final int rank;
  const _LeaderboardTile({required this.profile, required this.rank});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isTop3 = rank <= 3;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      color: isTop3 ? Colors.amber.withAlpha(26) : theme.colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: isTop3 ? BorderSide(color: Colors.amber[600]!, width: 1.5) : BorderSide.none),
      child: ListTile(
        leading: _buildRankWidget(theme, rank),
        title: Text(profile.username, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(profile.rank),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text('${profile.immersyaPoints} pts', style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.primary, fontSize: 16)),
            Text('${profile.scansValidated} scans', style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}

// --- NOUVEAU WIDGET : Pour afficher le classement des Équipes ---
class _TeamLeaderboardListView extends StatefulWidget {
  const _TeamLeaderboardListView({super.key});
  @override
  State<_TeamLeaderboardListView> createState() => __TeamLeaderboardListViewState();
}

class __TeamLeaderboardListViewState extends State<_TeamLeaderboardListView> with AutomaticKeepAliveClientMixin {
  Future<List<Map<String, dynamic>>>? _teamsLeaderboardFuture;

  @override
  void initState() {
    super.initState();
    _loadTeamsLeaderboard();
  }

  void _loadTeamsLeaderboard() {
    if(mounted) {
      final apiService = context.read<MockApiService>();
      setState(() {
        _teamsLeaderboardFuture = _calculateTeamScores(apiService);
      });
    }
  }

  Future<List<Map<String, dynamic>>> _calculateTeamScores(MockApiService apiService) async {
    final allTeams = await apiService.fetchAllTeams();
    final allProfiles = await apiService.fetchAllUserProfiles();
    final List<Map<String, dynamic>> teamsWithScores = [];

    for (final team in allTeams) {
      final members = allProfiles.where((p) => p.teamId == team.id);
      final totalPoints = members.fold(0, (sum, member) => sum + member.immersyaPoints);
      
      teamsWithScores.add({'team': team, 'score': totalPoints, 'memberCount': members.length});
    }
    teamsWithScores.sort((a, b) => b['score'].compareTo(a['score']));
    return teamsWithScores;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _teamsLeaderboardFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        if (snapshot.hasError) return Center(child: Text('Erreur: ${snapshot.error}'));
        if (!snapshot.hasData || snapshot.data!.isEmpty) return const Center(child: Text('Aucune équipe trouvée.'));
        
        final sortedTeams = snapshot.data!;
        return RefreshIndicator(
          onRefresh: () async => _loadTeamsLeaderboard(),
          child: ListView.builder(
            itemCount: sortedTeams.length,
            itemBuilder: (context, index) {
              final teamData = sortedTeams[index];
              return _TeamLeaderboardTile(team: teamData['team'], score: teamData['score'], memberCount: teamData['memberCount'], rank: index + 1);
            },
          ),
        );
      },
    );
  }

  @override
  bool get wantKeepAlive => true;
}

class _TeamLeaderboardTile extends StatelessWidget {
  final Team team;
  final int score, memberCount, rank;
  const _TeamLeaderboardTile({required this.team, required this.score, required this.memberCount, required this.rank});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isTop3 = rank <= 3;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      color: isTop3 ? Colors.deepPurple.withAlpha(26) : theme.colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: isTop3 ? BorderSide(color: Colors.deepPurple[200]!, width: 1.5) : BorderSide.none),
      child: ListTile(
        leading: _buildRankWidget(theme, rank),
        title: Text('${team.tag} ${team.name}', style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('$memberCount membres'),
        trailing: Text('$score pts', style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.primary, fontSize: 16)),
      ),
    );
  }
}

Widget _buildRankWidget(ThemeData theme, int rank) {
  IconData? icon;
  Color? color;
  if (rank == 1) { icon = Icons.emoji_events; color = Colors.amber; }
  if (rank == 2) { icon = Icons.emoji_events; color = Colors.grey[400]; }
  if (rank == 3) { icon = Icons.emoji_events; color = Colors.brown[400]; }
  return CircleAvatar(
    radius: 22,
    backgroundColor: theme.colorScheme.surfaceContainerHighest,
    child: icon != null ? Icon(icon, color: color) : Text(rank.toString(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
  );
}