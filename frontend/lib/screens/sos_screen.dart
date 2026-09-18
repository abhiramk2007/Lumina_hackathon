import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/location_service.dart';

class SOSScreen extends StatefulWidget {
  const SOSScreen({super.key});

  @override
  State<SOSScreen> createState() => _SOSScreenState();
}

class _SOSScreenState extends State<SOSScreen> {
  Timer? _timer;
  int _countdown = 10;
  bool _isCountingDown = false;
  
  List<dynamic> _contacts = [];
  bool _isLoadingContacts = false;

  @override
  void initState() {
    super.initState();
    _fetchContacts();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _fetchContacts() async {
    setState(() => _isLoadingContacts = true);
    final email = context.read<AuthService>().currentEmail;
    if (email != null) {
      final profile = await context.read<ApiService>().getProfile(email);
      if (profile != null && mounted) {
        setState(() {
          _contacts = profile['emergencyContacts'] ?? [];
        });
      }
    }
    if (mounted) setState(() => _isLoadingContacts = false);
  }

  void _startSOSCountdown() {
    setState(() {
      _isCountingDown = true;
      _countdown = 10;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      if (_countdown > 1) {
        setState(() => _countdown--);
      } else {
        _timer?.cancel();
        await _fireSOS();
      }
    });
  }

  void _cancelSOSCountdown() {
    _timer?.cancel();
    setState(() {
      _isCountingDown = false;
      _countdown = 10;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('SOS Cancelled')),
    );
  }

  Future<void> _fireSOS() async {
    setState(() {
      _isCountingDown = false;
    });

    final api = context.read<ApiService>();
    final auth = context.read<AuthService>();
    final email = auth.currentEmail ?? 'anonymous';
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Sending SOS...'), duration: Duration(seconds: 1)),
    );
    
    final locationService = context.read<LocationService>();
    await locationService.getCurrentPosition();
    
    double lat = 37.7749; // Default if location fails
    double lng = -122.4194;
    
    if (locationService.currentPosition != null) {
      lat = locationService.currentPosition!.latitude;
      lng = locationService.currentPosition!.longitude;
    }
    
    final success = await api.triggerSOS(lat, lng, email);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'SOS Sent Successfully!' : 'Failed to send SOS'),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    }
  }

  void _showContactsBottomSheet(String actionLabel, IconData actionIcon) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).brightness == Brightness.dark 
          ? const Color(0xFF2D2D2D) 
          : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Select Contact to $actionLabel",
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              if (_isLoadingContacts)
                const CircularProgressIndicator(color: Colors.pink)
              else if (_contacts.isEmpty)
                const Text("No emergency contacts found. Add some in your Profile.")
              else
                ..._contacts.map((contact) {
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: const Color(0xFFFFEEF4),
                      child: Icon(actionIcon, color: Colors.pink),
                    ),
                    title: Text(contact['name'] ?? 'Unknown'),
                    subtitle: Text(contact['phone'] ?? ''),
                    onTap: () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('$actionLabel ${contact['name']}...')),
                      );
                    },
                  );
                }),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Emergency SOS"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 20),
            GestureDetector(
              onTap: _isCountingDown ? _cancelSOSCountdown : _startSOSCountdown,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  color: _isCountingDown ? Colors.orange : Colors.red,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _isCountingDown ? "$_countdown" : "SOS",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 50,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (_isCountingDown)
                        const Text(
                          "Tap to Cancel",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 30),
            Text(
              _isCountingDown ? "SOS Dispatches in $_countdown seconds" : "Press SOS in an emergency",
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            const Text(
              "Your trusted contacts will receive your location instantly.",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton.icon(
                onPressed: () => _showContactsBottomSheet("Call", Icons.phone),
                icon: const Icon(Icons.phone),
                label: const Text("Call Emergency Contact"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 15),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton.icon(
                onPressed: () => _showContactsBottomSheet("Share with", Icons.location_on),
                icon: const Icon(Icons.location_on),
                label: const Text("Share Live Location"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.pink,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
