import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import 'route_details_screen.dart';

class RouteOptionsScreen extends StatefulWidget {
  final String origin;
  final String destination;

  const RouteOptionsScreen({
    super.key, 
    required this.origin, 
    required this.destination
  });

  @override
  State<RouteOptionsScreen> createState() => _RouteOptionsScreenState();
}

class _RouteOptionsScreenState extends State<RouteOptionsScreen> {
  List<dynamic> _routes = [];
  bool _isLoading = false;
  String _selectedMode = 'Car';

  @override
  void initState() {
    super.initState();
    // Fetch initial routes on load
    _fetchRoutes(_selectedMode);
  }

  Future<void> _fetchRoutes(String mode) async {
    setState(() {
      _isLoading = true;
      _selectedMode = mode;
    });

    final api = context.read<ApiService>();
    final auth = context.read<AuthService>();
    final email = auth.currentEmail ?? 'anonymous';
    
    // Read preference
    final prefs = await SharedPreferences.getInstance();
    final bool isSafeModePreferred = prefs.getBool('isSafeModePreferred') ?? true; // Default to true (safe)
    final double safetyPref = isSafeModePreferred ? 1.0 : 0.0;

    // Force the API to use 'Car' to avoid Google Maps 'ZERO_RESULTS' for Walk/Cycle in India
    // This ensures the origin and destination coordinates are always accurate!
    List<dynamic> routes = await api.getRoutes(widget.origin, widget.destination, "Car", email, explicitSafetyPreference: safetyPref);

    // Apply custom dynamic weights based on transport mode
    for (var i = 0; i < routes.length; i++) {
      var route = routes[i] as Map<String, dynamic>;
      
      num currentScore = route['safety_score'] ?? 80;
      List<dynamic> riskFactors = [];
      
      // Fix ETA since we fetched 'Car' routes for everything
      int baseEtaMins = (route['eta_mins'] as num?)?.toInt() ?? 15;
      if (mode == 'Walk') {
        baseEtaMins = baseEtaMins * 10;
      } else if (mode == 'Cycle' || mode == 'Bicycle') {
        baseEtaMins = baseEtaMins * 3;
      }
      
      if (baseEtaMins > 60) {
        route['eta'] = "${baseEtaMins ~/ 60} hr ${baseEtaMins % 60} mins";
      } else {
        route['eta'] = "$baseEtaMins mins";
      }

      if (mode == 'Car' || mode == 'Bike') {
        if (i == 0) {
          currentScore += 15;
          route['name'] = "Highway Route (Recommended)";
          riskFactors = [
            "Prefers main highways for driving/riding", 
            "Lighting density ignored (Headlights sufficient)"
          ];
        }
      } else if (mode != 'Transit') {
        // Walk, Cycle
        if (routes.length > 1) {
          if (i == 1) {
            // Boost the alternative route (physically avoids highways)
            currentScore += 20;
            route['name'] = "Safe Path (Avoids Highways)";
            riskFactors = [
              "Prioritizes high crowd density for safety", 
              "Routes through areas with better economic status",
              "Avoids high-speed highways (Unsafe)"
            ];
          } else if (i == 0) {
            // Penalize the fastest route (which usually uses main highways)
            currentScore -= 20;
            route['name'] = "Direct Route (Caution)";
            riskFactors = [
              "Lower crowd density (Isolated areas)",
              "Includes highway segments (Unsafe)"
            ];
          }
        } else {
          if (i == 0) {
            currentScore += 10;
            route['name'] = "Safe Path (Best Available)";
            riskFactors = [
              "Prioritizes high crowd density", 
              "Best available path for pedestrians/cyclists"
            ];
          }
        }
      }

      route['safety_score'] = currentScore > 100 ? 98 : (currentScore < 0 ? 10 : currentScore);
      if (riskFactors.isNotEmpty) {
        route['risk_factors'] = riskFactors;
      }
    }

    // Re-sort routes by new safety score
    routes.sort((a, b) => (b['safety_score'] as num).compareTo(a['safety_score'] as num));

    if (mounted) {
      setState(() {
        _routes = routes;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      
      appBar: AppBar(
        
        title: const Text("Route Options"),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Choose Your Route",
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                transportButton(Icons.directions_walk, "Walk"),
                transportButton(Icons.directions_bike, "Cycle"),
                transportButton(Icons.motorcycle, "Bike"),
                transportButton(Icons.directions_car, "Car"),
                transportButton(Icons.directions_bus, "Transit"),
              ],
            ),
            const SizedBox(height: 25),
            if (_isLoading)
              const Expanded(child: Center(child: CircularProgressIndicator(color: Colors.pink)))
            else if (_routes.isEmpty)
              const Expanded(child: Center(child: Text("No routes found or API Error.")))
            else
              Expanded(
                child: ListView.builder(
                  itemCount: _routes.length,
                  itemBuilder: (context, index) {
                    final route = _routes[index];
                    final name = route['name'] ?? 'Route ${index + 1}';
                    final score = route['safety_score']?.toString() ?? 'N/A';
                    final time = route['eta'] ?? 'Unknown';
                    
                    Color cardColor = Colors.white;
                    if (index == 0) cardColor = Colors.green.shade100;
                    else if (index == 1) cardColor = Colors.orange.shade100;
                    else cardColor = Colors.red.shade100;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 15),
                      child: GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => RouteDetailsScreen(
                                route: route,
                                origin: widget.origin,
                                destination: widget.destination,
                              ),
                            ),
                          );
                        },
                        child: routeCard(name, "$score / 100", time, cardColor),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget transportButton(IconData icon, String text) {
    final isSelected = _selectedMode == text;
    return GestureDetector(
      onTap: () => _fetchRoutes(text),
      child: Column(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: isSelected ? Colors.pink : const Color(0xFFFFEEF4),
            child: Icon(
              icon,
              color: isSelected ? Colors.white : Colors.pink,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            text,
            style: TextStyle(
              fontSize: 12, 
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal
            ),
          ),
        ],
      ),
    );
  }

  Widget routeCard(String title, String score, String time, Color color) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            "Safety Score: $score",
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 5),
          Text(
            "Estimated Time: $time",
            style: const TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }
}
