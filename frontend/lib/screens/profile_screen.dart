import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'emergency_contacts_screen.dart';
import '../services/auth_service.dart';
class ProfileScreen extends StatelessWidget {
  final bool isDarkMode;
  final Function(bool) onThemeChanged;

  const ProfileScreen({
    super.key,
    required this.isDarkMode,
    required this.onThemeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          isDarkMode ? const Color(0xFF1E1E1E) : const Color(0xFFFFF8F8),

      appBar: AppBar(
        title: const Text("Profile"),
        backgroundColor:
            isDarkMode ? Colors.black : const Color(0xFFFFD6E8),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),

        child: Column(
          children: [
            const SizedBox(height: 10),

            CircleAvatar(
              radius: 50,
              backgroundColor:
                  isDarkMode ? Colors.grey.shade800 : const Color(0xFFFFD6E8),

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
                color: isDarkMode ? Colors.white : Colors.black,
              ),
            ),

            Text(
              "Stay Safe Always 💜",
              style: TextStyle(
                color:
                    isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
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
    isDarkMode,
  ),
),

            profileTile(
              Icons.location_on,
              "Saved Places",
              isDarkMode,
            ),

            profileTile(
              Icons.history,
              "Journey History",
              isDarkMode,
            ),

            profileTile(
              Icons.notifications,
              "Safety Alerts",
              isDarkMode,
            ),

            profileTile(
              Icons.settings,
              "Settings",
              isDarkMode,
            ),

            const SizedBox(height: 10),

            Card(
              color:
                  isDarkMode ? const Color(0xFF2D2D2D) : Colors.white,

              child: SwitchListTile(
                title: Text(
                  "Dark Mode",
                  style: TextStyle(
                    color:
                        isDarkMode ? Colors.white : Colors.black,
                  ),
                ),

                secondary: Icon(
                  Icons.dark_mode,
                  color:
                      isDarkMode ? Colors.white : Colors.black,
                ),

                value: isDarkMode,

                onChanged: onThemeChanged,
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
