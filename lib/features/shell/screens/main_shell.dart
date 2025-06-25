// lib/features/shell/screens/main_shell.dart
import 'package:flutter/material.dart';
import 'package:immersya_mobile_app/features/capture/screens/capture_screen.dart';
import 'package:immersya_mobile_app/features/gallery/screens/gallery_screen.dart'; // <-- NOUVEL IMPORT
import 'package:immersya_mobile_app/features/map/screens/map_screen.dart';
import 'package:immersya_mobile_app/features/missions/screens/missions_screen.dart';
import 'package:immersya_mobile_app/features/profile/screens/profile_screen.dart';

final mainShellNavigatorKey = GlobalKey<MainShellState>();

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => MainShellState();
}

class MainShellState extends State<MainShell> {
  int _selectedIndex = 0;

  void goToTab(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  // MODIFIÉ : Ajout de la GalleryScreen
  static const List<Widget> _pages = <Widget>[
    MapScreen(),
    CaptureScreen(),
    MissionsScreen(),
    GalleryScreen(), // <-- NOUVELLE PAGE
    ProfileScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        // MODIFIÉ : Ajout de la 5ème icône
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.map_outlined),
            activeIcon: Icon(Icons.map),
            label: 'Carte',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.camera_alt_outlined),
            activeIcon: Icon(Icons.camera_alt),
            label: 'Capture',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.flag_outlined),
            activeIcon: Icon(Icons.flag),
            label: 'Missions',
          ),
          BottomNavigationBarItem( // <-- NOUVEL ITEM
            icon: Icon(Icons.photo_library_outlined),
            activeIcon: Icon(Icons.photo_library),
            label: 'Galerie',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profil',
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}