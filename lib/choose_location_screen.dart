import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'theme.dart';
import 'game_template.dart'; // Import the GameTemplate model

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
  bool isFromGameInfo = false; // Added to match the error context
  bool originalIsAway = false;
  GameTemplate? template; // Store the selected template

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
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null) {
      isFromEdit = args['isEdit'] == true;
      isFromGameInfo =
          args['isFromGameInfo'] == true; // Added to match the error context
      originalIsAway = args['isAwayGame'] == true;

      // Convert args['template'] from Map to GameTemplate if necessary
      template = args['template'] != null
          ? (args['template'] is GameTemplate
              ? args['template'] as GameTemplate?
              : GameTemplate.fromJson(args['template'] as Map<String, dynamic>))
          : null;

      if (isFromEdit && selectedLocation == null) {
        selectedLocation = args['location'] as String?;
        // If no location in args but template has location, use template location
        if (selectedLocation == null && template != null && template!.includeLocation && template!.location != null) {
          selectedLocation = template!.location;
        }
      }

      // If the template includes a location, use it and skip this screen (but not when editing)
      if (template != null &&
          template!.includeLocation &&
          template!.location != null &&
          !isFromEdit) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final isAwayGame = template!.location == 'Away Game';
          final nextArgs = {
            ...args,
            'location': template!.location,
            'isAwayGame': isAwayGame,
            'template': template,
          };
          final isCoach = args['teamName'] != null; // Detect Coach flow
          Navigator.pushReplacementNamed(
            context,
            isCoach
                ? '/additional_game_info_condensed'
                : '/additional_game_info',
            arguments: nextArgs,
          );
        });
      }
    }
  }

  Future<void> _fetchLocations() async {
    final prefs = await SharedPreferences.getInstance();
    final String? locationsJson = prefs.getString('saved_locations');
    setState(() {
      locations = [
        {'name': 'Away Game', 'id': -2},
      ];
      try {
        if (locationsJson != null && locationsJson.isNotEmpty) {
          locations.addAll(
              List<Map<String, dynamic>>.from(jsonDecode(locationsJson)));
        }
      } catch (e) {
        print('Error fetching locations: $e');
      }
      locations.add({'name': '+ Create new location', 'id': 0});
      isLoading = false;
      print('Locations loaded: $locations');
    });
  }

  Future<void> _saveLocations() async {
    final prefs = await SharedPreferences.getInstance();
    final locationsToSave = locations.where((loc) => loc['id'] > 0).toList();
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
              setState(() {
                locations.removeWhere((loc) => loc['id'] == locationId);
                if (selectedLocation == locationName) selectedLocation = null;
                _saveLocations();
              });
              Navigator.pop(context);
            },
            child: const Text('Delete', style: TextStyle(color: efficialsBlue)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final args =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    final sport = args['sport'] as String? ?? 'Unknown Sport';
    final date = args['date'] as DateTime?;
    final time = args['time'] as TimeOfDay?;

    return Scaffold(
      backgroundColor: darkBackground,
      appBar: AppBar(
        backgroundColor: efficialsBlack,
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
            padding: const EdgeInsets.all(16),
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Where will the game be played?',
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: efficialsYellow),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  isLoading
                      ? const CircularProgressIndicator()
                      : DropdownButtonFormField<String>(
                          decoration: textFieldDecoration('Locations'),
                          value: selectedLocation,
                          hint: const Text('Choose location',
                              style: TextStyle(color: efficialsGray)),
                          dropdownColor: darkSurface,
                          onChanged: (newValue) {
                            if (newValue == null) return;
                            setState(() {
                              selectedLocation = newValue;
                              if (newValue == '+ Create new location') {
                                Navigator.pushNamed(
                                        context, '/add_new_location')
                                    .then((result) {
                                  if (result != null) {
                                    final newLoc =
                                        result as Map<String, dynamic>;
                                    setState(() {
                                      locations.insert(locations.length - 1, {
                                        'name': newLoc['name'],
                                        'address': newLoc['address'],
                                        'city': newLoc['city'],
                                        'state': newLoc['state'],
                                        'zip': newLoc['zip'],
                                        'id': DateTime.now()
                                            .millisecondsSinceEpoch,
                                      });
                                      selectedLocation = newLoc['name'];
                                      _saveLocations();
                                    });
                                  }
                                });
                              }
                            });
                          },
                          items: locations
                              .map((loc) => DropdownMenuItem(
                                    value: loc['name'] as String,
                                    child: Text(loc['name'] as String,
                                        style: const TextStyle(color: primaryTextColor)),
                                  ))
                              .toList(),
                        ),
                  const SizedBox(height: 20),
                  if (selectedLocation != null &&
                      selectedLocation != 'Away Game' &&
                      selectedLocation != '+ Create new location') ...[
                    ElevatedButton(
                      onPressed: () {
                        final selected = locations
                            .firstWhere((l) => l['name'] == selectedLocation);
                        Navigator.pushNamed(context, '/edit_location',
                            arguments: {'location': selected}).then((result) {
                          if (result != null) {
                            final updatedLoc = result as Map<String, dynamic>;
                            setState(() {
                              final index = locations
                                  .indexWhere((l) => l['id'] == selected['id']);
                              if (index != -1) {
                                locations[index] = updatedLoc;
                                selectedLocation = updatedLoc['name'];
                                _saveLocations();
                              }
                            });
                          }
                        });
                      },
                      style: elevatedButtonStyle(),
                      child: const Text('Edit Location',
                          style: signInButtonTextStyle),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: () {
                        final selected = locations
                            .firstWhere((l) => l['name'] == selectedLocation);
                        _showDeleteConfirmationDialog(
                            selectedLocation!, selected['id'] as int);
                      },
                      style: elevatedButtonStyle(backgroundColor: Colors.red),
                      child: const Text('Delete Location',
                          style: signInButtonTextStyle),
                    ),
                  ],
                  const SizedBox(height: 60),
                  ElevatedButton(
                    onPressed: (selectedLocation != null &&
                            selectedLocation != '+ Create new location')
                        ? () {
                            final selected = locations.firstWhere(
                                (l) => l['name'] == selectedLocation);
                            final isAwayGame = selectedLocation == 'Away Game';
                            final nextArgs = {
                              ...args, // Spread all original args to preserve parameters like isAssignerFlow
                              'location':
                                  isAwayGame ? 'Away Game' : selected['name'],
                              'locationData': isAwayGame ? null : selected,
                              'isAwayGame': isAwayGame,
                              'template': template,
                            };
                            print('Continue - Args: $nextArgs');
                            final isCoach =
                                args['teamName'] != null; // Detect Coach flow
                            Navigator.pushNamed(
                              context,
                              isCoach
                                  ? '/additional_game_info_condensed'
                                  : '/additional_game_info',
                              arguments: nextArgs,
                            );
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: efficialsYellow,
                      foregroundColor: efficialsBlack,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Continue', style: TextStyle(
                      color: efficialsBlack,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    )),
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
