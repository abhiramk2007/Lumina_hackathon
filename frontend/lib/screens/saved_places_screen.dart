import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/places_service.dart';

class SavedPlacesScreen extends StatefulWidget {
  final bool isDarkMode;
  const SavedPlacesScreen({super.key, this.isDarkMode = false});

  @override
  State<SavedPlacesScreen> createState() => _SavedPlacesScreenState();
}

class _SavedPlacesScreenState extends State<SavedPlacesScreen> {
  final PlacesService _placesService = PlacesService();
  
  final TextEditingController _homeController = TextEditingController();
  final TextEditingController _workController = TextEditingController();
  final TextEditingController _otherController = TextEditingController();

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSavedPlaces();
  }

  Future<void> _loadSavedPlaces() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _homeController.text = prefs.getString('saved_home') ?? "";
      _workController.text = prefs.getString('saved_work') ?? "";
      _otherController.text = prefs.getString('saved_other') ?? "";
      _isLoading = false;
    });
  }

  Future<void> _savePlace(String key, String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, value);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Place saved successfully!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: widget.isDarkMode ? const Color(0xFF1E1E1E) : const Color(0xFFFFF8F8),
      appBar: AppBar(
        title: const Text("Saved Places"),
        backgroundColor: widget.isDarkMode ? Colors.black : const Color(0xFFFFD6E8),
        iconTheme: IconThemeData(color: widget.isDarkMode ? Colors.white : Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Manage Quick Locations",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            _buildPlaceField("Home", Icons.home, _homeController, 'saved_home'),
            const SizedBox(height: 20),
            _buildPlaceField("Work", Icons.work, _workController, 'saved_work'),
            const SizedBox(height: 20),
            _buildPlaceField("Other", Icons.location_on, _otherController, 'saved_other'),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceField(String title, IconData icon, TextEditingController controller, String prefKey) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: Colors.pink),
            const SizedBox(width: 10),
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: widget.isDarkMode ? Colors.white : Colors.black,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Autocomplete<String>(
          initialValue: TextEditingValue(text: controller.text),
          optionsBuilder: (TextEditingValue textEditingValue) async {
            if (textEditingValue.text.isEmpty) {
              return const Iterable<String>.empty();
            }
            return await _placesService.getPlaceSuggestions(textEditingValue.text);
          },
          onSelected: (String selection) {
            controller.text = selection;
            _savePlace(prefKey, selection);
          },
          fieldViewBuilder: (context, fieldController, focusNode, onEditingComplete) {
            // Ensure the fieldViewBuilder starts with the correct value on load
            if (fieldController.text.isEmpty && controller.text.isNotEmpty) {
              fieldController.text = controller.text;
            }
            // Keep controllers in sync
            fieldController.addListener(() {
              controller.text = fieldController.text;
            });

            return TextField(
              controller: fieldController,
              focusNode: focusNode,
              style: const TextStyle(color: Colors.black87),
              decoration: InputDecoration(
                hintText: "Search for $title...",
                hintStyle: const TextStyle(color: Colors.grey),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide.none,
                ),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.save, color: Colors.pink),
                  onPressed: () => _savePlace(prefKey, fieldController.text),
                ),
              ),
              onSubmitted: (value) => _savePlace(prefKey, value),
            );
          },
        ),
      ],
    );
  }
}
