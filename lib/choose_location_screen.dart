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
    if (args != null) {
      isFromEdit = args['isEdit'] == true;
      if (isFromEdit && selectedLocation == null) {
        selectedLocation = args['location'] as String?; // Set to game's original location when editing
        print('didChangeDependencies - Args: $args, Updated selectedLocation: $selectedLocation, isFromEdit: $isFromEdit');
      }
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
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (args != null && args['isEdit'] == true) {
        selectedLocation = args['location'] as String?;
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
                if (!locations.any((loc) => loc['name'] == selectedLocation)) {
                  selectedLocation = null;
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
    final scheduleName = args['scheduleName'] as String? ?? 'Unnamed Schedule';
    final sport = args['sport'] as String? ?? 'Unknown Sport';
    final date = args['date'] as DateTime?;
    final time = args['time'] as TimeOfDay?;
    final levelOfCompetition = args['levelOfCompetition'] as String?;
    final gender = args['gender'] as String?;
    final officialsRequired = args['officialsRequired'] as String?;
    final gameFee = args['gameFee'] as String?;
    final hireAutomatically = args['hireAutomatically'] as bool?;
    final selectedOfficials = args['selectedOfficials'] as List<Map<String, dynamic>>? ?? [];

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
                          hint: const Text('Choose location', style: TextStyle(color: Colors.grey)),
                          onChanged: (newValue) {
                            print('Dropdown onChanged - New Value: $newValue, Current selectedLocation: $selectedLocation');
                            if (newValue != null) {
                              setState(() {
                                selectedLocation = newValue;
                                print('Dropdown onChanged - Updated selectedLocation: $selectedLocation');
                                if (newValue == '+ Create new location') {
                                  Navigator.pushNamed(context, '/add_new_location').then((result) {
                                    if (result != null) {
                                      final newLocation = result as Map<String, dynamic>;
                                      setState(() {
                                        if (locations.any((l) => l['name'] == 'No saved locations')) {
                                          locations.removeWhere((l) => l['name'] == 'No saved locations');
                                        }
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
                                        print('Create new - Updated locations: $locations, selectedLocation: $selectedLocation');
                                      });
                                    } else {
                                      if (!locations.any((loc) => loc['name'] == selectedLocation)) {
                                        selectedLocation = null;
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
                      onPressed: () {
                        final selected = locations.firstWhere((l) => l['name'] == selectedLocation);
                        final argsToPass = {'location': selected};
                        print('ChooseLocationScreen - Selected location data: $selected');
                        print('ChooseLocationScreen - Navigating to /edit_location with arguments: $argsToPass');
                        Navigator.pushNamed(context, '/edit_location', arguments: argsToPass).then((result) {
                          if (result != null) {
                            final updatedLocation = result as Map<String, dynamic>;
                            setState(() {
                              final index = locations.indexWhere((l) => l['id'] == selected['id']);
                              if (index != -1) {
                                locations[index] = {
                                  'name': updatedLocation['name'],
                                  'address': updatedLocation['address'],
                                  'city': updatedLocation['city'],
                                  'state': updatedLocation['state'],
                                  'zip': updatedLocation['zip'],
                                  'id': selected['id'],
                                };
                                selectedLocation = updatedLocation['name'] as String;
                                _saveLocations();
                              }
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
                  const SizedBox(height: 60),
                  Center(
                    child: ElevatedButton(
                      onPressed: (selectedLocation == null ||
                              selectedLocation == 'No saved locations' ||
                              selectedLocation == '+ Create new location')
                          ? null
                          : () {
                              print('Continue pressed - Selected Location: $selectedLocation, isFromEdit: $isFromEdit');
                              if (isFromEdit) {
                                Navigator.pushNamedAndRemoveUntil(
                                  context,
                                  '/review_game_info',
                                  (route) => route.settings.name == '/review_game_info',
                                  arguments: {
                                    'scheduleName': scheduleName,
                                    'sport': sport,
                                    'location': selectedLocation,
                                    'date': date,
                                    'time': time,
                                    'levelOfCompetition': levelOfCompetition,
                                    'gender': gender,
                                    'officialsRequired': officialsRequired,
                                    'gameFee': gameFee,
                                    'hireAutomatically': hireAutomatically,
                                    'selectedOfficials': selectedOfficials,
                                  },
                                );
                              } else {
                                Navigator.pushNamed(
                                  context,
                                  '/additional_game_info',
                                  arguments: {
                                    'scheduleName': scheduleName,
                                    'sport': sport,
                                    'location': selectedLocation,
                                    'date': date,
                                    'time': time,
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