import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'emergency_contacts_screen.dart';
import 'saved_places_screen.dart';
import '../services/auth_service.dart';

class ProfileScreen extends StatefulWidget {
  final bool isDarkMode;
  final Function(bool) onThemeChanged;

  const ProfileScreen({
    super.key,
    required this.isDarkMode,
    required this.onThemeChanged,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isSafeModePreferred = true;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isSafeModePreferred = prefs.getBool('isSafeModePreferred') ?? true;
    });
  }

  Future<void> _toggleSafeMode(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isSafeModePreferred', value);
    setState(() {
      _isSafeModePreferred = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          widget.isDarkMode ? const Color(0xFF1E1E1E) : const Color(0xFFFFF8F8),

      appBar: AppBar(
        title: const Text("Profile"),
        backgroundColor:
            widget.isDarkMode ? Colors.black : const Color(0xFFFFD6E8),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),

        child: Column(
          children: [
            const SizedBox(height: 10),

            CircleAvatar(
              radius: 50,
              backgroundColor:
                  widget.isDarkMode ? Colors.grey.shade800 : const Color(0xFFFFD6E8),

              child: const Icon(
                Icons.person,
                size: 60,
                color: Colors.white,
              ),
            ),

            const SizedBox(height: 15),

            Text(
              context.watch<AuthService>().currentName ?? "GUEST",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: widget.isDarkMode ? Colors.white : Colors.black,
              ),
            ),

            Text(
              "Stay Safe Always 💜",
              style: TextStyle(
                color:
                    widget.isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
              ),
            ),

            const SizedBox(height: 30),

            GestureDetector(
  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            const EmergencyContactsScreen(),
      ),
    );
  },

  child: profileTile(
    Icons.phone,
    "Emergency Contacts",
    widget.isDarkMode,
  ),
),

            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SavedPlacesScreen(isDarkMode: widget.isDarkMode),
                  ),
                );
              },
              child: profileTile(
                Icons.location_on,
                "Saved Places",
                widget.isDarkMode,
              ),
            ),

            profileTile(
              Icons.history,
              "Journey History",
              widget.isDarkMode,
            ),

            profileTile(
              Icons.notifications,
              "Safety Alerts",
              widget.isDarkMode,
            ),

            profileTile(
              Icons.settings,
              "Settings",
              widget.isDarkMode,
            ),

            const SizedBox(height: 10),

            Card(
              color:
                  widget.isDarkMode ? const Color(0xFF2D2D2D) : Colors.white,

              child: Column(
                children: [
                  SwitchListTile(
                    title: Text(
                      "Dark Mode",
                      style: TextStyle(
                        color:
                            widget.isDarkMode ? Colors.white : Colors.black,
                      ),
                    ),

                    secondary: Icon(
                      Icons.dark_mode,
                      color:
                          widget.isDarkMode ? Colors.white : Colors.black,
                    ),

                    value: widget.isDarkMode,

                    onChanged: widget.onThemeChanged,
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    title: Text(
                      "Prefer Safe Routes",
                      style: TextStyle(
                        color:
                            widget.isDarkMode ? Colors.white : Colors.black,
                      ),
                    ),
                    subtitle: Text(
                      "Toggle off to prioritize fastest routes.",
                      style: TextStyle(
                        fontSize: 12,
                        color: widget.isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                      ),
                    ),
                    secondary: Icon(
                      _isSafeModePreferred ? Icons.shield : Icons.speed,
                      color:
                          widget.isDarkMode ? Colors.white : Colors.black,
                    ),
                    value: _isSafeModePreferred,
                    onChanged: _toggleSafeMode,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              height: 55,

              child: ElevatedButton(
                onPressed: () {
                  context.read<AuthService>().signOut();
                },

                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                ),

                child: const Text(
                  "Logout",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget profileTile(
    IconData icon,
    String title,
    bool isDarkMode,
  ) {
    return Card(
      color:
          isDarkMode ? const Color(0xFF2D2D2D) : Colors.white,

      margin: const EdgeInsets.only(bottom: 12),

      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),

      child: ListTile(
        leading: Icon(
          icon,
          color: Colors.pink,
        ),

        title: Text(
          title,
          style: TextStyle(
            color:
                isDarkMode ? Colors.white : Colors.black,
          ),
        ),

        trailing: Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color:
              isDarkMode ? Colors.white : Colors.black,
        ),
      ),
    );
  }
}
