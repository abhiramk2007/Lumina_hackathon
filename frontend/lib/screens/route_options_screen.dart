import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';

class RouteOptionsScreen extends StatefulWidget {
  const RouteOptionsScreen({super.key});

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

    // Using mock origin/destination since there are no input fields yet
    final routes = await api.getRoutes("Golden Gate Bridge", "Coit Tower", mode, email);

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
                      child: routeCard(name, "$score / 100", time, cardColor),
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
