import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';
import '../services/location_service.dart';
import '../services/places_service.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'route_options_screen.dart';
import 'sos_screen.dart';
import 'safe_haven_screen.dart';
import 'community_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  GoogleMapController? _mapController;
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _originController = TextEditingController(text: "Current Location");
  final PlacesService _placesService = PlacesService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LocationService>().getCurrentPosition();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _originController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final locService = context.watch<LocationService>();
    final initialCameraPosition = CameraPosition(
      target: locService.currentPosition != null 
          ? LatLng(locService.currentPosition!.latitude, locService.currentPosition!.longitude)
          : const LatLng(12.9716, 77.5946), // Bangalore default
      zoom: 14.0,
    );

    if (_mapController != null && locService.currentPosition != null) {
      _mapController!.animateCamera(CameraUpdate.newLatLng(
        LatLng(locService.currentPosition!.latitude, locService.currentPosition!.longitude)
      ));
    }

    return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: initialCameraPosition,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            onMapCreated: (controller) => _mapController = controller,
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 10),
                    Text(
                      "Hi, ${context.watch<AuthService>().currentName} 👋",
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 5),
                    const Text(
                      "Where would you like to go?",
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 15),
                    Autocomplete<String>(
                      optionsBuilder: (TextEditingValue textEditingValue) async {
                        if (textEditingValue.text.isEmpty || textEditingValue.text == "Current Location") {
                          return const Iterable<String>.empty();
                        }
                        return await _placesService.getPlaceSuggestions(textEditingValue.text);
                      },
                      onSelected: (String selection) {
                        _originController.text = selection;
                      },
                      fieldViewBuilder: (context, controller, focusNode, onEditingComplete) {
                        if (controller.text.isEmpty && _originController.text == "Current Location") {
                          controller.text = "Current Location";
                        }
                        controller.addListener(() {
                          _originController.text = controller.text;
                        });
                        return TextField(
                          controller: controller,
                          focusNode: focusNode,
                          style: const TextStyle(color: Colors.black87),
                          decoration: InputDecoration(
                            hintText: "Source (e.g. Current Location)",
                            hintStyle: const TextStyle(color: Colors.grey),
                            prefixIcon: const Icon(Icons.my_location, color: Colors.grey),
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 15),
                    Autocomplete<String>(
                      optionsBuilder: (TextEditingValue textEditingValue) async {
                        if (textEditingValue.text.isEmpty) {
                          return const Iterable<String>.empty();
                        }
                        return await _placesService.getPlaceSuggestions(textEditingValue.text);
                      },
                      onSelected: (String selection) {
                        _searchController.text = selection;
                      },
                      fieldViewBuilder: (context, controller, focusNode, onEditingComplete) {
                        controller.addListener(() {
                          _searchController.text = controller.text;
                        });
                        return TextField(
                          controller: controller,
                          focusNode: focusNode,
                          style: const TextStyle(color: Colors.black87),
                          decoration: InputDecoration(
                            hintText: "Search destination (e.g. Bangalore Palace)",
                            hintStyle: const TextStyle(color: Colors.grey),
                            prefixIcon: const Icon(Icons.search, color: Colors.grey),
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          onSubmitted: (value) => _planRoute(context, locService),
                        );
                      },
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        quickButton(Icons.home, "Home", () => _navigateToSavedPlace('saved_home', 'Home')),
                        quickButton(Icons.work, "Work", () => _navigateToSavedPlace('saved_work', 'Work')),
                        quickButton(Icons.location_on, "Other", () => _navigateToSavedPlace('saved_other', 'Other')),
                      ],
                    ),
                    const SizedBox(height: 25),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        color: const Color(0xFFFFEEF4),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                Text(
                                  "Choose a route that feels safer",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                    color: Colors.black87,
                                  ),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  "AI powered route recommendations",
                                  style: TextStyle(color: Colors.black54),
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.shield,
                            size: 50,
                            color: Colors.pink,
                          )
                        ],
                      ),
                    ),
                    const SizedBox(height: 25),
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        onPressed: () => _planRoute(context, locService),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF7FA7),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        child: const Text(
                          "Plan Route",
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 15),
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        onPressed: () {
                          context.read<LocationService>().getCurrentPosition();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFFE6EE).withOpacity(0.9),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        child: const Text(
                          "Live Location",
                          style: TextStyle(
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 25),
                    SizedBox(
                      height: 100,
                      child: Row(
                        children: [
                          Expanded(
                            child: featureCard(
                                "SOS",
                                Icons.warning,
                                const Color(0xFFFFE5E5),
                                () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SOSScreen())),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: featureCard(
                                "Haven",
                                Icons.home,
                                const Color(0xFFF1E3FF),
                                () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SafeHavenScreen())),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: featureCard(
                                "History",
                                Icons.menu_book,
                                const Color(0xFFE9F5FF),
                                () {},
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: featureCard(
                                "Community",
                                Icons.groups,
                                const Color(0xFFFFF2DE),
                                () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CommunityScreen())),
                            ),
                          ),
                        ],
                      ),
                    )
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _navigateToSavedPlace(String prefKey, String type) async {
    final prefs = await SharedPreferences.getInstance();
    final String? savedAddress = prefs.getString(prefKey);
    
    if (savedAddress == null || savedAddress.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No $type address saved. Please set it in Profile > Saved Places.')),
        );
      }
      return;
    }
    if (!mounted) return;
    _searchController.text = savedAddress;
    _planRoute(context, context.read<LocationService>());
  }

  void _planRoute(BuildContext context, LocationService locService) {
    if (_searchController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a destination')),
      );
      return;
    }
    
    String origin = _originController.text.trim();
    if (origin.isEmpty || origin.toLowerCase() == "current location") {
      origin = "12.9716,77.5946"; // Bangalore default
      if (locService.currentPosition != null) {
        origin = "${locService.currentPosition!.latitude},${locService.currentPosition!.longitude}";
      }
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RouteOptionsScreen(
          origin: origin,
          destination: _searchController.text.trim(),
        ),
      ),
    );
  }

  Widget quickButton(IconData icon, String text, VoidCallback onTap) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Column(
        children: [
          CircleAvatar(
            radius: 25,
            backgroundColor: Colors.white,
            child: Icon(icon, color: Colors.pink),
          ),
          const SizedBox(height: 6),
          Text(text),
        ],
      ),
    );
  }

  Widget featureCard(String title, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 28, color: Colors.pink),
            const SizedBox(height: 5),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2.0),
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                  color: Colors.black87,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
