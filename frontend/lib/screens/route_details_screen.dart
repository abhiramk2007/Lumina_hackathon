import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:math' as math;

class RouteDetailsScreen extends StatefulWidget {
  final dynamic route;

  const RouteDetailsScreen({super.key, required this.route});

  @override
  State<RouteDetailsScreen> createState() => _RouteDetailsScreenState();
}

class _RouteDetailsScreenState extends State<RouteDetailsScreen> {
  GoogleMapController? _mapController;
  Set<Polyline> _polylines = {};
  Set<Marker> _markers = {};
  
  @override
  void initState() {
    super.initState();
    _processRouteData();
  }

  void _processRouteData() {
    if (widget.route == null || widget.route['geometry'] == null) return;
    
    List<LatLng> points = [];
    for (var point in widget.route['geometry']) {
      points.add(LatLng(point['latitude'], point['longitude']));
    }

    if (points.isNotEmpty) {
      _polylines.add(
        Polyline(
          polylineId: const PolylineId('route'),
          points: points,
          color: Colors.pink,
          width: 5,
        ),
      );

      _markers.add(Marker(
        markerId: const MarkerId('start'),
        position: points.first,
        infoWindow: const InfoWindow(title: 'Start'),
      ));

      _markers.add(Marker(
        markerId: const MarkerId('end'),
        position: points.last,
        infoWindow: const InfoWindow(title: 'Destination'),
      ));
    }
  }

  void _fitBounds() {
    if (_mapController == null || widget.route == null || widget.route['geometry'] == null) return;
    
    List<LatLng> points = [];
    for (var point in widget.route['geometry']) {
      points.add(LatLng(point['latitude'], point['longitude']));
    }
    
    if (points.isEmpty) return;
    
    double minLat = points[0].latitude;
    double minLng = points[0].longitude;
    double maxLat = points[0].latitude;
    double maxLng = points[0].longitude;
    
    for (var p in points) {
      minLat = math.min(minLat, p.latitude);
      minLng = math.min(minLng, p.longitude);
      maxLat = math.max(maxLat, p.latitude);
      maxLng = math.max(maxLng, p.longitude);
    }
    
    _mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(minLat, minLng),
          northeast: LatLng(maxLat, maxLng),
        ),
        50.0, // padding
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final route = widget.route ?? {};
    final score = route['safety_score']?.toString() ?? 'N/A';
    final isSafe = (route['safety_score'] ?? 0) > 50;
    final riskFactors = route['risk_factors'] as List<dynamic>? ?? [];
    return Scaffold(
      

      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text("Safer Route"),
        centerTitle: true,
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // Live Map
            Container(
              height: 250,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.pink.shade100, width: 2),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: GoogleMap(
                  initialCameraPosition: const CameraPosition(
                    target: LatLng(12.9716, 77.5946),
                    zoom: 12,
                  ),
                  polylines: _polylines,
                  markers: _markers,
                  myLocationEnabled: true,
                  onMapCreated: (controller) {
                    _mapController = controller;
                    Future.delayed(const Duration(milliseconds: 500), _fitBounds);
                  },
                ),
              ),
            ),

            const SizedBox(height: 20),

            if (riskFactors.isNotEmpty) ...[
              const Text(
                "Risk Factors",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
              const SizedBox(height: 15),
              ...riskFactors.map((r) => reasonTile(r.toString(), false)).toList(),
            ] else ...[
              const Text(
                "Why this route?",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 15),
              reasonTile("Well lit streets", true),
              reasonTile("Higher crowd density", true),
              reasonTile("Near shops & emergency points", true),
              reasonTile("Lower crime reports", true),
            ],

            const SizedBox(height: 25),

            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),

              child: Column(
                children: [
                  const Text(
                    "Route Safety Score",
                    style: TextStyle(
                      fontSize: 18,
                    ),
                  ),

                  const SizedBox(height: 15),

                    Container(
                      height: 120,
                      width: 120,

                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isSafe ? Colors.green.shade100 : Colors.red.shade100,
                      ),

                      child: Center(
                        child: Text(
                          score,
                          style: const TextStyle(
                            fontSize: 40,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 15),

                    Text(
                      isSafe ? "Generally Safe" : "Caution Advised",
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 25),

            SizedBox(
              width: double.infinity,
              height: 55,

              child: ElevatedButton(
                onPressed: () {},

                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF7FA7),
                ),

                child: const Text(
                  "Start Navigation",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget reasonTile(String text, bool isPositive) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),

      child: Row(
        children: [
          Icon(
            isPositive ? Icons.check_circle : Icons.warning,
            color: isPositive ? Colors.green : Colors.red,
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}
