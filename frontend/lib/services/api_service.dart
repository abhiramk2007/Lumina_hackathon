import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/aws_config.dart';

class ApiService {
  final Future<String?> Function() getToken;

  ApiService({required this.getToken});

  Future<Map<String, String>> _getHeaders() async {
    final token = await getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': token,
    };
  }

  Future<bool> triggerSOS(double lat, double lng, String email) async {
    try {
      final response = await http.post(
        Uri.parse('${AWSConfig.apiEndpoint}sos'),
        headers: await _getHeaders(),
        body: jsonEncode({
          'email': email,
          'location': {'latitude': lat, 'longitude': lng}
        }),
      );
      return response.statusCode == 200;
    } catch (e) {
      print('Error triggering SOS: $e');
      return false;
    }
  }

  Future<List<dynamic>> getRoutes(String origin, String destination, String mode, String email) async {
    try {
      final uri = Uri.parse('${AWSConfig.apiEndpoint}routes').replace(queryParameters: {
        'origin': origin,
        'destination': destination,
        'mode': mode,
        'email': email,
      });
      final response = await http.get(uri, headers: await _getHeaders());
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as List<dynamic>;
      }
      return [];
    } catch (e) {
      print('Error fetching routes: $e');
      return [];
    }
  }

  Future<bool> reportHazard(String type, double lat, double lng, String description) async {
    try {
      final response = await http.post(
        Uri.parse('${AWSConfig.apiEndpoint}reports'),
        headers: await _getHeaders(),
        body: jsonEncode({
          'type': type,
          'location': {'latitude': lat, 'longitude': lng},
          'description': description,
        }),
      );
      return response.statusCode == 200;
    } catch (e) {
      print('Error reporting hazard: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>?> getProfile(String email) async {
    try {
      final uri = Uri.parse('${AWSConfig.apiEndpoint}profile').replace(queryParameters: {
        'email': email,
      });
      final response = await http.get(uri, headers: await _getHeaders());
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (e) {
      print('Error fetching profile: $e');
      return null;
    }
  }

  Future<bool> updateProfile(Map<String, dynamic> profileData) async {
    try {
      final response = await http.put(
        Uri.parse('${AWSConfig.apiEndpoint}profile'),
        headers: await _getHeaders(),
        body: jsonEncode(profileData),
      );
      return response.statusCode == 200;
    } catch (e) {
      print('Error updating profile: $e');
      return false;
    }
  }
}
