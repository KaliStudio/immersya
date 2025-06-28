// lib/features/shell/screens/main_shell.dart
import 'package:flutter/material.dart';
import 'package:immersya_mobile_app/features/capture/screens/capture_screen.dart';
import 'package:immersya_mobile_app/features/gallery/screens/gallery_screen.dart';
import 'package:immersya_mobile_app/features/map/screens/map_screen.dart';
import 'package:immersya_mobile_app/features/missions/screens/missions_screen.dart';
import 'package:immersya_mobile_app/features/profile/screens/profile_screen.dart';
import 'package:immersya_mobile_app/features/leaderboard/screens/leaderboard_screen.dart';
import 'package:immersya_mobile_app/features/team/screens/team_screen.dart';

// La GlobalKey est essentielle pour la navigation entre les onglets
final mainShellNavigatorKey = GlobalKey<MainShellState>();

class MainShell extends StatefulWidget {
  // On passe la clé au constructeur pour qu'elle soit correctement assignée
  const MainShell({super.key});

  @override
  State<MainShell> createState() => MainShellState();
}

class MainShellState extends State<MainShell> {
  // --- MODIFICATION : On utilise un PageController ---
  late PageController _pageController;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void goToTab(int index) {
    setState(() {
      _selectedIndex = index;
    });
    // On anime la transition vers la nouvelle page
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  // On revient à une liste statique, c'est plus performant et stable
  static const List<Widget> _pages = <Widget>[
    MapScreen(),
    CaptureScreen(),
    MissionsScreen(),
    TeamScreen(),
    GalleryScreen(),
    LeaderboardScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        // Cette fonction est appelée quand l'utilisateur glisse entre les pages
        onPageChanged: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.map_outlined), activeIcon: Icon(Icons.map), label: 'Carte'),
          BottomNavigationBarItem(icon: Icon(Icons.camera_alt_outlined), activeIcon: Icon(Icons.camera_alt), label: 'Capture'),
          BottomNavigationBarItem(icon: Icon(Icons.flag_outlined), activeIcon: Icon(Icons.flag), label: 'Missions'),
          BottomNavigationBarItem(icon: Icon(Icons.group_outlined), activeIcon: Icon(Icons.group), label: 'Équipe'),
          BottomNavigationBarItem(icon: Icon(Icons.photo_library_outlined), activeIcon: Icon(Icons.photo_library), label: 'Galerie'),
          BottomNavigationBarItem(icon: Icon(Icons.leaderboard_outlined), activeIcon: Icon(Icons.leaderboard), label: 'Classement'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: 'Profil'),
        ],
        currentIndex: _selectedIndex,
        onTap: goToTab,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}