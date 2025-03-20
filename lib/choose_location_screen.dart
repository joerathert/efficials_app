import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'theme.dart';

class ChooseLocationScreen extends StatefulWidget {
  const ChooseLocationScreen({super.key});

  @override
  State<ChooseLocationScreen> createState() => _ChooseLocationScreenState();
}

class _ChooseLocationScreenState extends State<ChooseLocationScreen> {
  String? selectedLocation;
  List<Map<String, dynamic>> locations = [];
  bool isLoading = true;
  bool isFromEdit = false;

  @override
  void initState() {
    super.initState();
    _fetchLocations();
    print('initState - Initial selectedLocation: $selectedLocation, isFromEdit: $isFromEdit');
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null && selectedLocation == null) { // Only set initial value if not user-selected
      selectedLocation = args['location'] as String?;
      isFromEdit = args['isEdit'] == true; // Changed from 'fromEdit' to 'isEdit' for consistency
      // Ensure selectedLocation matches an existing item
      if (selectedLocation != null && !locations.any((loc) => loc['name'] == selectedLocation)) {
        selectedLocation = locations.isNotEmpty ? locations[0]['name'] as String : null;
      }
      print('didChangeDependencies - Args: $args, Updated selectedLocation: $selectedLocation, isFromEdit: $isFromEdit');
    } else {
      print('didChangeDependencies - No change, selectedLocation: $selectedLocation, isFromEdit: $isFromEdit');
    }
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
      // Ensure selectedLocation matches an existing item
      if (selectedLocation == null || !locations.any((loc) => loc['name'] == selectedLocation)) {
        selectedLocation = locations.isNotEmpty ? locations[0]['name'] as String : null;
      }
      isLoading = false;
      print('fetchLocations - Loaded locations: $locations, selectedLocation: $selectedLocation');
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
                locations.removeWhere((location) => location['id'] == locationId);
                if (locations.isEmpty || (locations.length == 1 && locations[0]['id'] == 0)) {
                  locations.insert(0, {'name': 'No saved locations', 'id': -1});
                }
                // Reset selectedLocation if it no longer exists
                if (!locations.any((loc) => loc['name'] == selectedLocation)) {
                  selectedLocation = locations.isNotEmpty ? locations[0]['name'] as String : null;
                }
                _saveLocations();
                print('Delete - Updated locations: $locations, selectedLocation: $selectedLocation');
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
    print('build - Current selectedLocation: $selectedLocation, isLoading: $isLoading');
    final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    final scheduleName = args['scheduleName'] as String;
    final sport = args['sport'] as String;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: efficialsBlue,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, size: 36, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Choose Location',
          style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
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
                    'Where will the game be played?',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  isLoading
                      ? const CircularProgressIndicator()
                      : DropdownButtonFormField<String>(
                          decoration: textFieldDecoration('Locations'),
                          value: selectedLocation,
                          onChanged: (newValue) {
                            print('Dropdown onChanged - New Value: $newValue, Current selectedLocation: $selectedLocation');
                            if (newValue != null) {
                              setState(() {
                                selectedLocation = newValue;
                                print('Dropdown onChanged - Updated selectedLocation: $selectedLocation');
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
                                        print('Create new - Updated locations: $locations, selectedLocation: $selectedLocation');
                                      });
                                    } else {
                                      // Reset selectedLocation if it no longer exists
                                      if (!locations.any((loc) => loc['name'] == selectedLocation)) {
                                        selectedLocation = locations.isNotEmpty ? locations[0]['name'] as String : null;
                                      }
                                      print('Create new - Reverted selectedLocation: $selectedLocation');
                                    }
                                  });
                                }
                              });
                            }
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
                  const SizedBox(height: 60),
                  Center(
                    child: ElevatedButton(
                      onPressed: (selectedLocation == null ||
                              selectedLocation == 'No saved locations' ||
                              selectedLocation == '+ Create new location')
                          ? null
                          : () {
                              print('Continue pressed - Selected Location: $selectedLocation, isFromEdit: $isFromEdit');
                              final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
                              if (isFromEdit) {
                                Navigator.pushNamedAndRemoveUntil(
                                  context,
                                  '/review_game_info',
                                  (route) => route.settings.name == '/review_game_info',
                                  arguments: {
                                    ...args,
                                    'location': selectedLocation,
                                  },
                                );
                              } else {
                                Navigator.pushNamed(
                                  context,
                                  '/date_time',
                                  arguments: {
                                    'scheduleName': scheduleName,
                                    'sport': sport,
                                    'location': selectedLocation,
                                  },
                                );
                              }
                            },
                      style: elevatedButtonStyle(),
                      child: const Text('Continue', style: signInButtonTextStyle),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}