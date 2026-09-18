import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'route_options_screen.dart';
import 'sos_screen.dart';
import 'safe_haven_screen.dart';
import 'profile_screen.dart';
import 'community_screen.dart';

class NavigationScreen extends StatefulWidget {
  final bool isDarkMode;
  final Function(bool) onThemeChanged;

  const NavigationScreen({
    super.key,
    required this.isDarkMode,
    required this.onThemeChanged,
  });

  @override
  State<NavigationScreen> createState() => _NavigationScreenState();
}

class _NavigationScreenState extends State<NavigationScreen> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      const HomeScreen(),
      const RouteOptionsScreen(),
      const SOSScreen(),
      const CommunityScreen(),
      ProfileScreen(
        isDarkMode: widget.isDarkMode,
        onThemeChanged: widget.onThemeChanged,
      ),
    ];

    return Scaffold(
      body: screens[_selectedIndex],

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,

        selectedItemColor: const Color(0xFFFF7FA7),
        unselectedItemColor: Colors.black54,

        selectedFontSize: 14,
        unselectedFontSize: 12,
        iconSize: 28,

        showUnselectedLabels: true,

        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),

          BottomNavigationBarItem(
            icon: Icon(Icons.map),
            label: 'Routes',
          ),

          BottomNavigationBarItem(
            icon: Icon(Icons.warning),
            label: 'SOS',
          ),

          BottomNavigationBarItem(
            icon: Icon(Icons.groups),
            label: 'Community',
          ),

          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
