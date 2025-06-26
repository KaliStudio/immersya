// lib/features/leaderboard/screens/leaderboard_screen.dart

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:immersya_mobile_app/api/mock_api_service.dart';
import 'package:provider/provider.dart';
import 'package:immersya_mobile_app/services/location_service.dart';
import 'package:visibility_detector/visibility_detector.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});
  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  TabController? _tabController;
  bool _isLoading = true;

  List<Tab> _tabs = [const Tab(text: 'Global')];
  List<Widget> _tabViews = [const _LeaderboardListView(key: ValueKey('Global'))];

  // Instanciation de notre service de localisation
  final LocationService _locationService = LocationService();
  
  // Pour éviter des rechargements trop fréquents
  DateTime _lastLoadTime = DateTime.now().subtract(const Duration(minutes: 1));

  @override
  void initState() {
    super.initState();
    // On initialise un TabController minimaliste pour commencer.
    // Il sera reconstruit plus tard.
    _tabController = TabController(length: 1, vsync: this);
  }

  // Choisit la meilleure "région" disponible depuis un Placemark
  String? _getBestRegion(Placemark placemark) {
    if (placemark.administrativeArea != null && placemark.administrativeArea!.isNotEmpty) {
      return placemark.administrativeArea; // Idéal : on a la région
    }
    if (placemark.subAdministrativeArea != null && placemark.subAdministrativeArea!.isNotEmpty) {
      return placemark.subAdministrativeArea; // Sinon, on prend le département
    }
    return null; // Sinon, tant pis
  }

  // Cette méthode est appelée lorsque l'écran devient visible.
  void _onVisibilityChanged(VisibilityInfo info) {
    // On ne recharge que si l'écran est entièrement visible et si un certain temps s'est écoulé.
    if (info.visibleFraction == 1.0 && DateTime.now().difference(_lastLoadTime).inSeconds > 30) {
      print("Leaderboard est visible, rafraîchissement des onglets GPS...");
      _lastLoadTime = DateTime.now();
      _loadAndBuildTabsFromGPS();
    }
  }

  // La logique principale pour construire les onglets dynamiquement
  Future<void> _loadAndBuildTabsFromGPS() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    
    // 1. Obtenir la position GPS
    Position? position = await _locationService.getCurrentPosition();
    
    // 2. Convertir la position en adresse (géocodage inverse)
    Placemark? placemark;
    if (position != null) {
      try {
        List<Placemark> placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
        if (placemarks.isNotEmpty) {
          placemark = placemarks.first;
          print("📍 Localisation GPS pour les classements : ${placemark.locality}, ${placemark.country}");
        }
      } catch (e) {
        print("Erreur de géocodage pour le classement: $e");
      }
    }
    
    // 3. Construire les listes de Tabs et de TabViews
    final newTabs = [const Tab(text: 'Global')];
    final newViews = [const _LeaderboardListView(key: ValueKey('Global'))];
    
    if (placemark != null) {
      final country = placemark.country;
      final region = _getBestRegion(placemark); // On utilise notre helper
      final city = placemark.locality;
  
      if (country != null && country.isNotEmpty) {
        newTabs.add(Tab(text: country));
        newViews.add(_LeaderboardListView(key: ValueKey(country), country: country));
      }
      if (region != null && region.isNotEmpty) {
        newTabs.add(Tab(text: region));
        newViews.add(_LeaderboardListView(key: ValueKey(region), region: region));
      }
      if (city != null && city.isNotEmpty) {
        newTabs.add(Tab(text: city));
        newViews.add(_LeaderboardListView(key: ValueKey(city), city: city));
      }
    }
    
    // 4. Mettre à jour l'état de l'interface
    if (mounted) {
      // Sauvegarder l'index actuel pour une transition fluide
      int previousIndex = _tabController?.index ?? 0;
      
      _tabController?.dispose();
      
      setState(() {
        _tabs = newTabs;
        _tabViews = newViews;
        _tabController = TabController(
          length: _tabs.length, 
          vsync: this, 
          // Restaurer l'index précédent, en s'assurant qu'il est valide
          initialIndex: min(previousIndex, _tabs.length - 1)
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
    return VisibilityDetector(
      key: const Key('leaderboard-visibility-detector'),
      onVisibilityChanged: _onVisibilityChanged,
      child: Scaffold(
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
            ? const PreferredSize(
                preferredSize: Size.fromHeight(4.0),
                child: LinearProgressIndicator(),
              )
            : _tabController != null 
                ? TabBar(
                    controller: _tabController,
                    isScrollable: true,
                    tabs: _tabs,
                  )
                : null,
        ),
        body: _isLoading 
          ? const Center(child: CircularProgressIndicator()) 
          : _tabController == null 
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text("Impossible de déterminer la localisation.", textAlign: TextAlign.center),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadAndBuildTabsFromGPS,
                        child: const Text("Réessayer"),
                      )
                    ],
                  ),
                ),
              )
            : TabBarView(
                controller: _tabController,
                children: _tabViews,
              ),
      ),
    );
  }
}

// Ce widget reste inchangé, il reçoit juste des filtres différents
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

// Ce widget reste inchangé
class _LeaderboardTile extends StatelessWidget {
  final UserProfile profile;
  final int rank;
  const _LeaderboardTile({super.key, required this.profile, required this.rank});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isTop3 = rank <= 3;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      color: isTop3 ? Colors.amber.withOpacity(0.1) : theme.colorScheme.surface,
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
      backgroundColor: theme.colorScheme.surfaceVariant,
      child: icon != null ? Icon(icon, color: color) : Text(rank.toString(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
    );
  }
}