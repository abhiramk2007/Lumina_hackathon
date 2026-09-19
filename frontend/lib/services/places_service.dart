import 'dart:convert';
import 'package:http/http.dart' as http;

class PlacesService {
  // Using the API key found in web/index.html
  static const String _apiKey = 'AIzaSyAC39nIG3SM0ZbIBigHA59YAHfRAIVLyKA';

  Future<List<String>> getPlaceSuggestions(String query) async {
    if (query.trim().isEmpty) return [];

    try {
      final uri = Uri.parse(
          'https://maps.googleapis.com/maps/api/place/autocomplete/json'
          '?input=${Uri.encodeComponent(query)}&key=$_apiKey');
          
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'OK' && data['predictions'] != null) {
          final predictions = data['predictions'] as List;
          return predictions.map((p) => p['description'] as String).toList();
        }
      }
      
      // FALLBACK FOR HACKATHON DEMO
      // If the API key doesn't have Places API enabled, return mock data
      return _getMockSuggestions(query);
    } catch (e) {
      print('Error fetching place suggestions: $e');
      return _getMockSuggestions(query);
    }
  }

  List<String> _getMockSuggestions(String query) {
    final lowerQuery = query.toLowerCase();
    final List<String> mockDatabase = [
      "Rajaji Nagar, Bangalore",
      "Rajarajeshwari Nagar, Bangalore",
      "Rajarajeshwari Temple, Bangalore",
      "Ramamurthy Nagar, Bangalore",
      "Bangalore Palace",
      "Banaswadi, Bangalore",
      "Bannerghatta National Park",
      "Banashankari, Bangalore",
      "MG Road, Bangalore",
      "Malleshwaram, Bangalore",
      "Koramangala, Bangalore",
      "Indiranagar, Bangalore",
      "Whitefield, Bangalore",
      "Electronic City, Bangalore",
    ];

    return mockDatabase
        .where((place) => place.toLowerCase().contains(lowerQuery))
        .toList();
  }
}

