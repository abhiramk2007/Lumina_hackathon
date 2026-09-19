import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/location_service.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'route_options_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  GoogleMapController? _mapController;
  final TextEditingController _searchController = TextEditingController();

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

              const SizedBox(height: 20),

              TextField(
                controller: _searchController,
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
              ),

              const SizedBox(height: 20),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,

                children: [
                  quickButton(Icons.home, "Home"),
                  quickButton(Icons.work, "Work"),
                  quickButton(Icons.school, "School"),
                  quickButton(Icons.more_horiz, "Other"),
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
                        crossAxisAlignment:
                        CrossAxisAlignment.start,

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
                    backgroundColor:
                    const Color(0xFFFF7FA7),

                    shape: RoundedRectangleBorder(
                      borderRadius:
                      BorderRadius.circular(20),
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
                    backgroundColor:
                    const Color(0xFFFFE6EE).withOpacity(0.9),

                    shape: RoundedRectangleBorder(
                      borderRadius:
                      BorderRadius.circular(20),
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

              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 15,
                  mainAxisSpacing: 15,

                  children: [
                    featureCard(
                        "SOS",
                        Icons.warning,
                        const Color(0xFFFFE5E5)
                    ),

                    featureCard(
                        "Safe Haven",
                        Icons.home,
                        const Color(0xFFF1E3FF)
                    ),

                    featureCard(
                        "My Journeys",
                        Icons.menu_book,
                        const Color(0xFFE9F5FF)
                    ),

                    featureCard(
                        "Community",
                        Icons.groups,
                        const Color(0xFFFFF2DE)
                    ),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
      ],
    ),
    );
  }

  void _planRoute(BuildContext context, LocationService locService) {
    if (_searchController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a destination')),
      );
      return;
    }
    
    String origin = "12.9716,77.5946"; // Bangalore default
    if (locService.currentPosition != null) {
      origin = "${locService.currentPosition!.latitude},${locService.currentPosition!.longitude}";
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

  Widget quickButton(IconData icon, String text) {
    return Column(
      children: [
        CircleAvatar(
          radius: 25,
          backgroundColor: Colors.white,
          child: Icon(icon, color: Colors.pink),
        ),
        const SizedBox(height: 6),
        Text(text),
      ],
    );
  }

  Widget featureCard(String title, IconData icon, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),

      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,

        children: [
          Icon(icon, size: 40, color: Colors.pink),
          const SizedBox(height: 10),
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
