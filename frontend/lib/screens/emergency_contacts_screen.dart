import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';

class EmergencyContactsScreen extends StatefulWidget {
  const EmergencyContactsScreen({super.key});

  @override
  State<EmergencyContactsScreen> createState() => _EmergencyContactsScreenState();
}

class _EmergencyContactsScreenState extends State<EmergencyContactsScreen> {
  bool _isLoading = false;
  List<dynamic> _contacts = [];
  Map<String, dynamic>? _profile;

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    setState(() => _isLoading = true);
    final email = context.read<AuthService>().currentEmail;
    if (email != null) {
      final profile = await context.read<ApiService>().getProfile(email);
      if (profile != null && mounted) {
        setState(() {
          _profile = profile;
          _contacts = profile['emergencyContacts'] ?? [];
        });
      }
    }
    if (mounted) setState(() => _isLoading = false);
  }
  
  Future<void> _addContact() async {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();

    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Add Emergency Contact"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: "Name"),
              ),
              TextField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: "Phone Number"),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                if (nameController.text.isNotEmpty && phoneController.text.isNotEmpty) {
                  Navigator.pop(context, {
                    "name": nameController.text.trim(),
                    "phone": phoneController.text.trim(),
                  });
                }
              },
              child: const Text("Save"),
            ),
          ],
        );
      },
    );

    if (result != null) {
      _contacts.add(result);
      await _saveProfile();
    }
  }
  
  Future<void> _deleteContact(int index) async {
    _contacts.removeAt(index);
    await _saveProfile();
  }
  
  Future<void> _saveProfile() async {
    setState(() => _isLoading = true);
    final email = context.read<AuthService>().currentEmail;
    if (_profile == null) {
      if (email != null) {
        _profile = {'email': email, 'emergencyContacts': _contacts};
      }
    } else {
      _profile!['emergencyContacts'] = _contacts;
    }
    if (_profile != null) {
      await context.read<ApiService>().updateProfile(_profile!);
    }
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      
      appBar: AppBar(
        title: const Text("Emergency Contacts"),
        
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: Colors.pink))
        : Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Expanded(
                  child: _contacts.isEmpty 
                    ? const Center(child: Text("No emergency contacts yet."))
                    : ListView.builder(
                        itemCount: _contacts.length,
                        itemBuilder: (context, index) {
                          final c = _contacts[index];
                          return contactCard(
                            c['name'] ?? 'Unknown',
                            c['phone'] ?? 'No number',
                            Icons.person,
                            () => _deleteContact(index),
                          );
                        },
                      ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton.icon(
                    onPressed: _addContact,
                    icon: const Icon(Icons.add),
                    label: const Text("Add Contact"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF7FA7),
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
    );
  }

  Widget contactCard(String name, String number, IconData icon, VoidCallback onDelete) {
    return Card(
      margin: const EdgeInsets.only(bottom: 15),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: const Color(0xFFFFEEF4),
          child: Icon(icon, color: Colors.pink),
        ),
        title: Text(name),
        subtitle: Text(number),
        trailing: IconButton(
          onPressed: onDelete,
          icon: const Icon(Icons.delete_outline, color: Colors.red),
        ),
      ),
    );
  }
}
