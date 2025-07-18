import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../shared/theme.dart';
import '../../shared/services/location_service.dart';
import 'edit_location_screen.dart';

class LocationsScreen extends StatefulWidget {
  const LocationsScreen({super.key});

  @override
  State<LocationsScreen> createState() => _LocationsScreenState();
}

class _LocationsScreenState extends State<LocationsScreen> {
  String? selectedLocation;
  List<Map<String, dynamic>> locations = [];
  final LocationService _locationService = LocationService();

  @override
  void initState() {
    super.initState();
    // Initialize with a default value to avoid empty list
    locations = [
      {'name': 'No saved locations', 'id': -1},
      {'name': '+ Create new location', 'id': 0},
    ];
    selectedLocation = locations[0]['name'] as String? ?? 'No saved locations';
    _fetchLocations();
  }

  // Helper method to ensure selectedLocation is valid
  void _validateSelectedLocation() {
    if (locations.isEmpty) {
      locations = [
        {'name': 'No saved locations', 'id': -1},
        {'name': '+ Create new location', 'id': 0},
      ];
    }
    if (!locations.any((loc) => loc['name'] == selectedLocation)) {
      selectedLocation = locations[0]['name'] as String? ?? 'No saved locations';
    }
  }

  Future<void> _fetchLocations() async {
    try {
      // Use LocationService exclusively now that database is stable
      final fetchedLocations = await _locationService.getLocations();
      
      setState(() {
        locations = [];
        
        // Add saved locations from database
        locations.addAll(fetchedLocations);
        
        // Add default options
        if (locations.isEmpty) {
          locations.add({'name': 'No saved locations', 'id': -1});
        }
        locations.add({'name': '+ Create new location', 'id': 0});
        
        // Ensure selectedLocation is valid
        if (selectedLocation == null || !locations.any((loc) => loc['name'] == selectedLocation)) {
          selectedLocation = locations.first['name'] as String;
        }
      });
    } catch (e) {
      debugPrint('Error fetching locations: $e');
      setState(() {
        locations = [
          {'name': 'No saved locations', 'id': -1},
          {'name': '+ Create new location', 'id': 0},
        ];
        selectedLocation = 'No saved locations';
      });
    }
  }

  Future<void> _saveLocations() async {
    // This method is no longer needed as we're using the database
    // But keeping it for now to avoid breaking existing code
    // Will be removed in cleanup phase
  }

  Future<void> _deleteLocationFromPrefs(String locationName) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? locationsJson = prefs.getString('saved_locations');
      
      if (locationsJson != null && locationsJson.isNotEmpty) {
        final List<dynamic> locationsList = jsonDecode(locationsJson);
        locationsList.removeWhere((loc) => loc['name'] == locationName);
        await prefs.setString('saved_locations', jsonEncode(locationsList));
      }
      
      // Refresh the locations list
      await _fetchLocations();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location deleted successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error deleting location')),
        );
      }
    }
  }

  void _showDeleteConfirmationDialog(String locationName, int locationId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: darkSurface,
        title: const Text('Confirm Delete', 
            style: TextStyle(color: efficialsYellow, fontSize: 20, fontWeight: FontWeight.bold)),
        content: Text('Are you sure you want to delete "$locationName"?',
            style: const TextStyle(color: Colors.white)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: efficialsYellow)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                // Use LocationService to delete from database
                final success = await _locationService.deleteLocation(locationId);
                
                if (success) {
                  // Refresh the locations list
                  await _fetchLocations();
                  
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Location deleted successfully')),
                    );
                  }
                } else {
                  // Fallback to SharedPreferences
                  await _deleteLocationFromPrefs(locationName);
                }
              } catch (e) {
                // Fallback to SharedPreferences
                await _deleteLocationFromPrefs(locationName);
              }
            },
            child: const Text('Delete', style: TextStyle(color: efficialsYellow)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Validate selectedLocation before rendering
    _validateSelectedLocation();

    return Scaffold(
      backgroundColor: darkBackground,
      appBar: AppBar(
        backgroundColor: efficialsBlack,
        title: const Icon(
          Icons.sports,
          color: efficialsYellow,
          size: 32,
        ),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: efficialsWhite),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Locations',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: primaryTextColor,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Manage your saved locations',
                  style: TextStyle(
                    fontSize: 16,
                    color: secondaryTextColor,
                  ),
                ),
                const SizedBox(height: 40),
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: darkSurface,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Select a location to edit, or create a new location.',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      locations.isEmpty || selectedLocation == null
                          ? const Center(child: CircularProgressIndicator())
                          : DropdownButtonFormField<String>(
                              decoration: textFieldDecoration('Locations'),
                              value: selectedLocation,
                              hint: const Text('Select a location', style: TextStyle(color: efficialsGray)),
                              style: const TextStyle(color: Colors.white, fontSize: 16),
                              dropdownColor: darkSurface,
                              onChanged: (newValue) {
                                setState(() {
                                  selectedLocation = newValue;
                                  if (newValue == '+ Create new location') {
                                    Navigator.pushNamed(context, '/add_new_location').then((result) {
                                      if (result != null) {
                                        // Location was created successfully, refresh the list
                                        _fetchLocations();
                                        final newLocation = result as Map<String, dynamic>;
                                        selectedLocation = newLocation['name'] as String? ?? 'Unknown Location';
                                      } else {
                                        _validateSelectedLocation();
                                      }
                                    });
                                  } else if (newValue != 'No saved locations' && !newValue!.startsWith('Error')) {
                                    selectedLocation = newValue;
                                  }
                                });
                              },
                              items: locations.map((location) {
                                final locationName = location['name'] as String;
                                return DropdownMenuItem(
                                  value: locationName,
                                  child: Container(
                                    constraints: const BoxConstraints(maxWidth: 250),
                                    child: Text(
                                      locationName,
                                      style: location['name'] == 'No saved locations'
                                          ? const TextStyle(color: Colors.red)
                                          : const TextStyle(color: Colors.white),
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
                if (selectedLocation != null &&
                    selectedLocation != '+ Create new location' &&
                    selectedLocation != 'No saved locations' &&
                    !selectedLocation!.startsWith('Error')) ...[
                  Center(
                    child: Column(
                      children: [
                        Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          constraints: const BoxConstraints(maxWidth: 200),
                          child: ElevatedButton(
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
                                    // Location was updated successfully, refresh the list
                                    _fetchLocations();
                                    final updatedLocation = result as Map<String, dynamic>;
                                    selectedLocation = updatedLocation['name'] as String? ?? 'Unknown Location';
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Location updated!')),
                                    );
                                  }
                                });
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: efficialsYellow,
                                foregroundColor: efficialsBlack,
                                padding: const EdgeInsets.symmetric(
                                    vertical: 15, horizontal: 32),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: const Text(
                                'Edit Location',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ),
                        Container(
                          constraints: const BoxConstraints(maxWidth: 200),
                          child: ElevatedButton(
                            onPressed: () {
                              final selected = locations.firstWhere((l) => l['name'] == selectedLocation);
                              _showDeleteConfirmationDialog(selectedLocation!, selected['id'] as int? ?? 0);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                  vertical: 15, horizontal: 32),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text(
                              'Delete Location',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}