// lib/features/leaderboard/screens/leaderboard_screen.dart

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:immersya_mobile_app/api/mock_api_service.dart';
import 'package:provider/provider.dart';
import 'package:immersya_mobile_app/services/location_service.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});
  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  TabController? _tabController;
  bool _isLoading = true;
  // --- NOUVEAU : Un flag pour s'assurer que le chargement ne se fait qu'une fois ---
  bool _isInitialLoad = true;

  List<Map<String, dynamic>> _tabData = [];
  final LocationService _locationService = LocationService();

  // @override
  // void initState() {
  //   super.initState();
  //   // initState doit être le plus léger possible. On ne fait rien ici.
  // }

  // --- MODIFICATION PRINCIPALE : On utilise didChangeDependencies ---
  // Cette méthode est appelée après initState et chaque fois qu'une dépendance change.
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // On utilise le flag pour ne lancer le chargement qu'une seule fois.
    if (_isInitialLoad) {
      _loadAndBuildTabsFromGPS();
      _isInitialLoad = false;
    }
  }

  String? _getBestRegion(Placemark placemark) {
    if (placemark.administrativeArea != null && placemark.administrativeArea!.isNotEmpty) return placemark.administrativeArea;
    if (placemark.subAdministrativeArea != null && placemark.subAdministrativeArea!.isNotEmpty) return placemark.subAdministrativeArea;
    return null;
  }
  
  Future<void> _loadAndBuildTabsFromGPS() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    
    final position = await _locationService.getCurrentPosition();
    final placemark = position != null ? await _locationService.getPlacemarkFromCoordinates(position) : null;
    
    final newTabData = <Map<String, dynamic>>[
      {'label': 'Global', 'filter': {}}
    ];
    
    if (placemark != null) {
      final country = placemark.country;
      final region = _getBestRegion(placemark);
      final city = placemark.locality;
  
      if (country != null && country.isNotEmpty) {
        newTabData.add({'label': country, 'filter': {'country': country}});
      }
      if (region != null && region.isNotEmpty) {
        newTabData.add({'label': region, 'filter': {'region': region}});
      }
      if (city != null && city.isNotEmpty) {
        newTabData.add({'label': city, 'filter': {'city': city}});
      }
    }
    
    if (mounted) {
      int previousIndex = _tabController?.index ?? 0;
      _tabController?.dispose(); 
      
      setState(() {
        _tabData = newTabData;
        _tabController = TabController(
          length: _tabData.length, 
          vsync: this,
          initialIndex: min(previousIndex, _tabData.length - 1)
        );
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
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context); // L'appel à super.build est nécessaire avec le mixin
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Classements'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _loadAndBuildTabsFromGPS,
          )
        ],
        bottom: _isLoading
          ? const PreferredSize(preferredSize: Size.fromHeight(4.0), child: LinearProgressIndicator())
          : _tabController != null 
            ? TabBar(
                controller: _tabController,
                isScrollable: true,
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
                final filter = data['filter'];
                return _LeaderboardListView(
                  key: ValueKey(filter.toString()),
                  country: filter['country'],
                  region: filter['region'],
                  city: filter['city'],
                );
              }).toList(),
            ),
    );
  }
}

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
        _leaderboardFuture = apiService.fetchAllUserProfiles(
          country: widget.country,
          region: widget.region,
          city: widget.city,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return FutureBuilder<List<UserProfile>>(
      future: _leaderboardFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Erreur: ${snapshot.error}'));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('Aucun contributeur dans ce classement.'));
        }
        final sortedProfiles = snapshot.data!;
        sortedProfiles.sort((a, b) => b.immersyaPoints.compareTo(a.immersyaPoints));
        return RefreshIndicator(
          onRefresh: () async => _loadLeaderboard(),
          child: ListView.builder(
            itemCount: sortedProfiles.length,
            itemBuilder: (context, index) {
              return _LeaderboardTile(
                profile: sortedProfiles[index],
                rank: index + 1,
              );
            },
          ),
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
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isTop3 ? BorderSide(color: Colors.amber[600]!, width: 1.5) : BorderSide.none,
      ),
      child: ListTile(
        leading: _buildRankWidget(theme),
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

  Widget _buildRankWidget(ThemeData theme) {
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
}