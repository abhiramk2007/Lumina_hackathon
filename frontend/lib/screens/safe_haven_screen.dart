import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:math' as math;

class SafeHaven {
  final String title;
  final double latitude;
  final double longitude;
  final IconData icon;
  final Color color;

  SafeHaven(this.title, this.latitude, this.longitude, this.icon, this.color);
}

class SafeHavenScreen extends StatefulWidget {
  final List<dynamic>? routeGeometry;
  final String? customTitle;

  const SafeHavenScreen({
    super.key, 
    this.routeGeometry,
    this.customTitle,
  });

  @override
  State<SafeHavenScreen> createState() => _SafeHavenScreenState();
}

class _SafeHavenScreenState extends State<SafeHavenScreen> {
  Position? _currentPosition;
  bool _isLoading = true;
  List<SafeHaven> _havens = [];
  String _selectedCategory = "All";

  @override
  void initState() {
    super.initState();
    _fetchLocationAndGenerateHavens();
  }

  Future<void> _fetchLocationAndGenerateHavens() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    try {
      Position position = await Geolocator.getCurrentPosition();
      
      double refLat = position.latitude;
      double refLng = position.longitude;

      if (widget.routeGeometry != null && widget.routeGeometry!.isNotEmpty) {
        // If a route is active, generate havens near the midpoint of the route
        int midIndex = widget.routeGeometry!.length ~/ 2;
        refLat = widget.routeGeometry![midIndex]['latitude'];
        refLng = widget.routeGeometry![midIndex]['longitude'];
      }

      // Generate dynamic safe havens around the reference location
      _havens = [
        SafeHaven(
          "Police Station", 
          refLat + 0.005, 
          refLng + 0.005, 
          Icons.local_police, 
          Colors.blue,
        ),
        SafeHaven(
          "City Hospital", 
          refLat - 0.008, 
          refLng + 0.003, 
          Icons.local_hospital, 
          Colors.red,
        ),
        SafeHaven(
          "24x7 Pharmacy", 
          refLat + 0.002, 
          refLng - 0.004, 
          Icons.medication, 
          Colors.green,
        ),
        SafeHaven(
          "Metro Station", 
          refLat - 0.006, 
          refLng - 0.007, 
          Icons.train, 
          Colors.purple,
        ),
      ];

      // Sort by distance to the user's current physical position (nearest first)
      _havens.sort((a, b) {
        double distA = _calculateDistance(position.latitude, position.longitude, a.latitude, a.longitude);
        double distB = _calculateDistance(position.latitude, position.longitude, b.latitude, b.longitude);
        return distA.compareTo(distB);
      });

      if (mounted) {
        setState(() {
          _currentPosition = position;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    var p = 0.017453292519943295;
    var c = math.cos;
    var a = 0.5 - c((lat2 - lat1) * p) / 2 + 
          c(lat1 * p) * c(lat2 * p) * 
          (1 - c((lon2 - lon1) * p)) / 2;
    return 12742 * math.asin(math.sqrt(a));
  }

  Future<void> _startNavigation(SafeHaven haven) async {
    if (_currentPosition == null) return;
    
    final originStr = "${_currentPosition!.latitude},${_currentPosition!.longitude}";
    final destStr = "${haven.latitude},${haven.longitude}";
    
    final url = Uri.parse('https://www.google.com/maps/dir/?api=1&origin=$originStr&destination=$destStr&dir_action=navigate');
    
    try {
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not open maps')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  List<SafeHaven> get _filteredHavens {
    List<SafeHaven> filtered = _havens;
    if (_selectedCategory == "Police") filtered = _havens.where((h) => h.icon == Icons.local_police).toList();
    else if (_selectedCategory == "Hospital") filtered = _havens.where((h) => h.icon == Icons.local_hospital).toList();
    else if (_selectedCategory == "Pharmacy") filtered = _havens.where((h) => h.icon == Icons.medication).toList();
    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.customTitle ?? "Nearby Safe Havens"),
        centerTitle: true,
        backgroundColor: Colors.white,
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _categoryChip("All"),
                      const SizedBox(width: 10),
                      _categoryChip("Police"),
                      const SizedBox(width: 10),
                      _categoryChip("Hospital"),
                      const SizedBox(width: 10),
                      _categoryChip("Pharmacy"),
                    ],
                  ),
                ),
                const SizedBox(height: 25),
                if (_currentPosition == null)
                  const Text("Location not available. Please enable location permissions.")
                else
                  Expanded(
                    child: ListView.builder(
                      itemCount: _filteredHavens.length,
                      itemBuilder: (context, index) {
                        final haven = _filteredHavens[index];
                        final distance = _calculateDistance(
                          _currentPosition!.latitude, 
                          _currentPosition!.longitude, 
                          haven.latitude, 
                          haven.longitude
                        );
                        return _safePlaceCard(haven, distance);
                      },
                    ),
                  ),
              ],
            ),
          ),
    );
  }

  Widget _categoryChip(String text) {
    final isSelected = _selectedCategory == text;
    return ChoiceChip(
      label: Text(text),
      selected: isSelected,
      onSelected: (bool selected) {
        setState(() {
          _selectedCategory = text;
        });
      },
      selectedColor: const Color(0xFFFFEEF4),
      backgroundColor: Colors.grey.shade200,
    );
  }

  Widget _safePlaceCard(SafeHaven haven, double distanceInKm) {
    return Card(
      margin: const EdgeInsets.only(bottom: 15),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: haven.color.withOpacity(0.2),
          child: Icon(haven.icon, color: haven.color),
        ),
        title: Text(haven.title),
        subtitle: Text("${distanceInKm.toStringAsFixed(1)} km"),
        trailing: ElevatedButton(
          onPressed: () => _startNavigation(haven),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFF7FA7),
          ),
          child: const Text(
            "Directions",
            style: TextStyle(color: Colors.white),
          ),
        ),
      ),
    );
  }
}
