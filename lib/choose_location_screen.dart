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
  bool originalIsAway = false; // Track the original isAway value
  Map<String, dynamic> _args = {};
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    locations = [
      {'name': 'Away Game', 'id': -2},
      {'name': '+ Create new location', 'id': 0},
    ];
    _fetchLocations();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (args != null) {
        _args = args;
        isFromEdit = args['isEdit'] == true;
        originalIsAway = args['isAway'] == true; // Store the original isAway value
        if (isFromEdit) {
          selectedLocation = args['location'] as String?;
          if (args['isAway'] == true && selectedLocation == null) {
            selectedLocation = 'Away Game';
          }
        }
      }
      _isInitialized = true;
    }
  }

  Future<void> _fetchLocations() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? locationsJson = prefs.getString('saved_locations');
      setState(() {
        locations = [
          {'name': 'Away Game', 'id': -2},
        ];
        if (locationsJson != null && locationsJson.isNotEmpty) {
          locations.addAll(List<Map<String, dynamic>>.from(jsonDecode(locationsJson)));
        }
        // Do not add "No saved locations" even if the list is empty
        locations.add({'name': '+ Create new location', 'id': 0});
        // Ensure selectedLocation is valid
        if (selectedLocation == null || !locations.any((loc) => loc['name'] == selectedLocation)) {
          selectedLocation = locations.isNotEmpty ? locations[0]['name'] as String : null;
        }
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        locations = [
          {'name': 'Error loading locations', 'id': -1},
          {'name': 'Away Game', 'id': -2},
          {'name': '+ Create new location', 'id': 0}
        ];
        selectedLocation = null;
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load locations: $e')),
      );
    }
  }

  Future<void> _saveLocations() async {
    final prefs = await SharedPreferences.getInstance();
    final locationsToSave = locations.where((location) => location['id'] != 0 && location['id'] != -1 && location['id'] != -2).toList();
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
                if (!locations.any((loc) => loc['name'] == selectedLocation)) {
                  selectedLocation = locations.isNotEmpty ? locations[0]['name'] as String : null;
                }
                _saveLocations();
              });
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _handleLocationSelection(String? newValue) {
    if (newValue == null) return;
    setState(() {
      selectedLocation = newValue;
      if (newValue == '+ Create new location') {
        Navigator.pushNamed(context, '/add_new_location').then((result) {
          if (result != null) {
            final newLocation = result as Map<String, dynamic>;
            setState(() {
              locations.insert(locations.length - 1, {
                'name': newLocation['name'],
                'address': newLocation['address'],
                'city': newLocation['city'],
                'state': newLocation['state'],
                'zip': newLocation['zip'],
                'id': DateTime.now().millisecondsSinceEpoch,
              });
              selectedLocation = newLocation['name'] as String;
              _saveLocations();
            });
          } else {
            if (!locations.any((loc) => loc['name'] == selectedLocation)) {
              selectedLocation = locations.isNotEmpty ? locations[0]['name'] as String : null;
            }
          }
        });
      }
    });
  }

  void _handleEditLocation() {
    final selected = locations.firstWhere((l) => l['name'] == selectedLocation);
    Navigator.pushNamed(context, '/edit_location', arguments: {'location': selected}).then((result) {
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
  }

  void _handleContinue() {
    final isAway = selectedLocation == 'Away Game';
    final nextArgs = {
      ..._args,
      'location': isAway ? null : selectedLocation,
      'isAway': isAway,
    };

    if (isFromEdit && originalIsAway != isAway) {
      if (isAway) {
        // Changed from home to away: Clear officials-related fields
        nextArgs
          ..remove('officialsRequired')
          ..remove('gameFee')
          ..remove('gender')
          ..remove('levelOfCompetition')
          ..remove('hireAutomatically')
          ..remove('selectedOfficials')
          ..remove('method');
        Navigator.pushReplacementNamed(context, '/review_game_info', arguments: nextArgs);
      } else {
        // Changed from away to home: Navigate to AdditionalGameInfoScreen
        Navigator.pushNamed(context, '/additional_game_info', arguments: nextArgs);
      }
    } else {
      // No change in isAway, proceed as normal
      Navigator.pushNamed(
        context,
        isFromEdit ? '/review_game_info' : '/additional_game_info',
        arguments: nextArgs,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isContinueEnabled = selectedLocation != null && selectedLocation != '+ Create new location' && !selectedLocation!.startsWith('Error');
    final isEditableLocation = isContinueEnabled && selectedLocation != 'Away Game';

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, size: 36, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Choose Location', style: appBarTextStyle),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Where will the game be played?',
                    style: headlineStyle,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  isLoading
                      ? const CircularProgressIndicator()
                      : DropdownButtonFormField<String>(
                          decoration: textFieldDecoration('Locations'),
                          value: selectedLocation,
                          hint: const Text('Select a location'),
                          onChanged: _handleLocationSelection,
                          items: locations.map((location) {
                            return DropdownMenuItem(
                              value: location['name'] as String,
                              child: Text(
                                location['name'] as String,
                                style: location['name'] == 'Error loading locations'
                                    ? const TextStyle(color: Colors.red)
                                    : null, // "Away Game" uses default black text
                              ),
                            );
                          }).toList(),
                        ),
                  const SizedBox(height: 60),
                  if (isEditableLocation) ...[
                    ElevatedButton(
                      onPressed: _handleEditLocation,
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
                      onPressed: isContinueEnabled ? _handleContinue : null,
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