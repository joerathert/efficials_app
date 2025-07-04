import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'theme.dart';
import 'edit_location_screen.dart';

class LocationsScreen extends StatefulWidget {
  const LocationsScreen({super.key});

  @override
  State<LocationsScreen> createState() => _LocationsScreenState();
}

class _LocationsScreenState extends State<LocationsScreen> {
  String? selectedLocation;
  List<Map<String, dynamic>> locations = [];

  @override
  void initState() {
    super.initState();
    // Initialize with a default value to avoid empty list
    locations = [
      {'name': 'No saved locations', 'id': -1},
      {'name': '+ Create new location', 'id': 0},
    ];
    selectedLocation = locations[0]['name'] as String;
    print('initState - locations: $locations, selectedLocation: $selectedLocation');
    _fetchLocations();
  }

  // Helper method to ensure selectedLocation is valid
  void _validateSelectedLocation() {
    print('validateSelectedLocation - Before: locations: $locations, selectedLocation: $selectedLocation');
    if (locations.isEmpty) {
      locations = [
        {'name': 'No saved locations', 'id': -1},
        {'name': '+ Create new location', 'id': 0},
      ];
    }
    if (!locations.any((loc) => loc['name'] == selectedLocation)) {
      selectedLocation = locations[0]['name'] as String;
    }
    print('validateSelectedLocation - After: locations: $locations, selectedLocation: $selectedLocation');
  }

  Future<void> _fetchLocations() async {
    final prefs = await SharedPreferences.getInstance();
    final String? locationsJson = prefs.getString('saved_locations');
    setState(() {
      print('fetchLocations - Before: locations: $locations, selectedLocation: $selectedLocation');
      if (locationsJson != null) {
        List<Map<String, dynamic>> fetchedLocations = List<Map<String, dynamic>>.from(jsonDecode(locationsJson));
        // Remove duplicates based on the 'name' field
        locations = [];
        final seenNames = <String>{};
        for (var loc in fetchedLocations) {
          if (!seenNames.contains(loc['name'])) {
            seenNames.add(loc['name'] as String);
            locations.add(loc);
          }
        }
        if (locations.isEmpty) {
          locations.add({'name': 'No saved locations', 'id': -1});
        }
        locations.add({'name': '+ Create new location', 'id': 0});
      }
      _validateSelectedLocation();
      print('fetchLocations - After: locations: $locations, selectedLocation: $selectedLocation');
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
            child: const Text('Cancel', style: TextStyle(color: efficialsBlue)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                print('showDeleteConfirmationDialog - Before: locations: $locations, selectedLocation: $selectedLocation');
                locations.removeWhere((location) => location['id'] == locationId);
                if (locations.isEmpty || (locations.length == 1 && locations[0]['id'] == 0)) {
                  locations.insert(0, {'name': 'No saved locations', 'id': -1});
                }
                _validateSelectedLocation();
                _saveLocations();
                print('showDeleteConfirmationDialog - After: locations: $locations, selectedLocation: $selectedLocation');
              });
            },
            child: const Text('Delete', style: TextStyle(color: efficialsBlue)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Validate selectedLocation before rendering
    _validateSelectedLocation();
    print('build - locations: $locations, selectedLocation: $selectedLocation');

    return Scaffold(
      appBar: AppBar(
        backgroundColor: efficialsBlack,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, size: 36, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Locations',
          style: TextStyle(
            color: darkSurface,
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
                  locations.isEmpty || selectedLocation == null
                      ? const CircularProgressIndicator()
                      : DropdownButtonFormField<String>(
                          decoration: textFieldDecoration('Locations'),
                          value: selectedLocation,
                          onChanged: (newValue) {
                            setState(() {
                              print('Dropdown onChanged - Before: newValue: $newValue, selectedLocation: $selectedLocation');
                              selectedLocation = newValue;
                              if (newValue == '+ Create new location') {
                                Navigator.pushNamed(context, '/add_new_location').then((result) {
                                  if (result != null) {
                                    setState(() {
                                      print('Add new location - Before: locations: $locations, selectedLocation: $selectedLocation');
                                      if (locations.any((l) => l['name'] == 'No saved locations')) {
                                        locations.removeWhere((l) => l['name'] == 'No saved locations');
                                      }
                                      final newLocation = result as Map<String, dynamic>;
                                      // Check for duplicate names before adding
                                      if (!locations.any((loc) => loc['name'] == newLocation['name'])) {
                                        locations.insert(0, {
                                          'name': newLocation['name'],
                                          'address': newLocation['address'],
                                          'city': newLocation['city'],
                                          'state': newLocation['state'],
                                          'zip': newLocation['zip'],
                                          'id': locations.length + 1,
                                        });
                                        selectedLocation = newLocation['name'] as String;
                                        _saveLocations();
                                      } else {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('A location with this name already exists!')),
                                        );
                                        _validateSelectedLocation();
                                      }
                                      print('Add new location - After: locations: $locations, selectedLocation: $selectedLocation');
                                    });
                                  } else {
                                    _validateSelectedLocation();
                                    print('Add new location cancelled - After: locations: $locations, selectedLocation: $selectedLocation');
                                  }
                                });
                              } else if (newValue != 'No saved locations' && !newValue!.startsWith('Error')) {
                                selectedLocation = newValue;
                              }
                              print('Dropdown onChanged - After: selectedLocation: $selectedLocation');
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
                      onPressed: () {
                        final selected = locations.firstWhere((l) => l['name'] == selectedLocation);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const EditLocationScreen(),
                            settings: RouteSettings(arguments: selected),
                          ),
                        ).then((result) {
                          if (result != null) {
                            setState(() {
                              print('Edit location - Before: locations: $locations, selectedLocation: $selectedLocation');
                              final updatedLocation = result as Map<String, dynamic>;
                              final index = locations.indexWhere((l) => l['id'] == selected['id']);
                              if (index != -1) {
                                // Check for duplicate names before updating
                                if (!locations.any((loc) => loc['name'] == updatedLocation['name'] && loc['id'] != selected['id'])) {
                                  locations[index] = {
                                    ...updatedLocation,
                                    'id': selected['id'], // Preserve the original ID
                                  };
                                  selectedLocation = updatedLocation['name'] as String;
                                  _saveLocations();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Location updated!')),
                                  );
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('A location with this name already exists!')),
                                  );
                                  _validateSelectedLocation();
                                }
                              }
                              print('Edit location - After: locations: $locations, selectedLocation: $selectedLocation');
                            });
                          }
                        });
                      },
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