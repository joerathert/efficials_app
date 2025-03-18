import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'theme.dart';

class LocationsScreen extends StatefulWidget {
  const LocationsScreen({super.key});

  @override
  State<LocationsScreen> createState() => _LocationsScreenState();
}

class _LocationsScreenState extends State<LocationsScreen> {
  String? selectedLocation;
  List<Map<String, dynamic>> locations = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchLocations();
  }

  Future<void> _fetchLocations() async {
    final prefs = await SharedPreferences.getInstance();
    final String? locationsJson = prefs.getString('saved_locations');
    setState(() {
      if (locationsJson != null) {
        locations = List<Map<String, dynamic>>.from(jsonDecode(locationsJson));
      }
      if (locations.isEmpty) {
        locations.add({'name': 'No saved locations', 'id': -1});
      }
      locations.add({'name': '+ Create new location', 'id': 0});
      selectedLocation = locations.isNotEmpty ? locations[0]['name'] as String : null;
      isLoading = false;
    });
  }

  Future<void> _saveLocations() async {
    final prefs = await SharedPreferences.getInstance();
    final locationsToSave = locations.where((location) => location['id'] != 0 && location['id'] != -1).toList();
    await prefs.setString('saved_locations', jsonEncode(locationsToSave));
  }

  void _showDeleteConfirmationDialog(String locationName, int locationId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: Text('Are you sure you want to delete "$locationName"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                locations.removeWhere((location) => location['id'] == locationId);
                if (locations.isEmpty || (locations.length == 1 && locations[0]['id'] == 0)) {
                  locations.insert(0, {'name': 'No saved locations', 'id': -1});
                }
                selectedLocation = locations.isNotEmpty ? locations[0]['name'] as String : null;
                _saveLocations();
              });
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: efficialsBlue,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, size: 36, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Locations',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Select a location to edit, or create a new location.',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 60),
                  isLoading
                      ? const CircularProgressIndicator()
                      : DropdownButtonFormField<String>(
                          decoration: textFieldDecoration('Locations'),
                          value: selectedLocation,
                          onChanged: (newValue) {
                            setState(() {
                              selectedLocation = newValue;
                              if (newValue == '+ Create new location') {
                                Navigator.pushNamed(context, '/add_new_location').then((result) {
                                  if (result != null) {
                                    setState(() {
                                      if (locations.any((l) => l['name'] == 'No saved locations')) {
                                        locations.removeWhere((l) => l['name'] == 'No saved locations');
                                      }
                                      locations.insert(0, {'name': result as String, 'id': locations.length + 1});
                                      selectedLocation = result;
                                      _saveLocations();
                                    });
                                  } else {
                                    selectedLocation = locations.isNotEmpty ? locations[0]['name'] as String : null;
                                  }
                                });
                              } else if (newValue != 'No saved locations' && !newValue!.startsWith('Error')) {
                                selectedLocation = newValue;
                              }
                            });
                          },
                          items: locations.map((location) {
                            return DropdownMenuItem(
                              value: location['name'] as String,
                              child: Text(
                                location['name'] as String,
                                style: location['name'] == 'No saved locations'
                                    ? const TextStyle(color: Colors.red)
                                    : null,
                              ),
                            );
                          }).toList(),
                        ),
                  const SizedBox(height: 60),
                  if (selectedLocation != null &&
                      selectedLocation != '+ Create new location' &&
                      selectedLocation != 'No saved locations' &&
                      !selectedLocation!.startsWith('Error')) ...[
                    ElevatedButton(
                      onPressed: () {},
                      style: elevatedButtonStyle(),
                      child: const Text('Edit Location', style: signInButtonTextStyle),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: () {
                        final selected = locations.firstWhere((l) => l['name'] == selectedLocation);
                        _showDeleteConfirmationDialog(selectedLocation!, selected['id'] as int);
                      },
                      style: elevatedButtonStyle(backgroundColor: Colors.red),
                      child: const Text('Delete Location', style: signInButtonTextStyle),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}