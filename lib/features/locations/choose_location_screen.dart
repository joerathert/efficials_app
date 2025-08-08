import 'package:flutter/material.dart';
import '../../shared/theme.dart';
import '../games/game_template.dart' as game_template;
import '../../shared/services/location_service.dart';

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
  bool isFromGameInfo = false;
  bool originalIsAway = false;
  bool isAssignerFlow = false;
  game_template.GameTemplate? template;
  final LocationService _locationService = LocationService();

  @override
  void initState() {
    super.initState();
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
      isAssignerFlow = args['isAssignerFlow'] == true;

      // Convert args['template'] from Map to GameTemplate if necessary
      template = args['template'] != null
          ? (args['template'] is game_template.GameTemplate
              ? args['template'] as game_template.GameTemplate?
              : game_template.GameTemplate.fromJson(args['template'] as Map<String, dynamic>))
          : null;

      if (isFromEdit && selectedLocation == null) {
        selectedLocation = args['location'] as String?;
        // If no location in args but template has location, use template location
        if (selectedLocation == null &&
            template != null &&
            template!.includeLocation &&
            template!.location != null) {
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
            'opponent': args['opponent'] ?? '', // Preserve opponent from args
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
    try {
      final dbLocations = await _locationService.getLocations();
      
      setState(() {
        locations = [];
        
        // Only add "Away Game" if not in Assigner flow
        if (!isAssignerFlow) {
          locations.add({'name': 'Away Game', 'id': -2});
        }
        
        // Add locations from database (now properly formatted with separate address components)
        locations.addAll(dbLocations);
        
        locations.add({'name': '+ Create new location', 'id': 0});
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        locations = [
          if (!isAssignerFlow) {'name': 'Away Game', 'id': -2},
          {'name': '+ Create new location', 'id': 0},
        ];
        isLoading = false;
      });
    }
  }


  void _showDeleteConfirmationDialog(String locationName, int locationId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: darkSurface,
        title: const Text('Confirm Delete', style: TextStyle(color: efficialsWhite)),
        content: Text('Are you sure you want to delete "$locationName"?', 
            style: const TextStyle(color: primaryTextColor)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: efficialsYellow)),
          ),
          TextButton(
            onPressed: () async {
              try {
                final success = await _locationService.deleteLocation(locationId);
                if (success) {
                  setState(() {
                    locations.removeWhere((loc) => loc['id'] == locationId);
                    if (selectedLocation == locationName) selectedLocation = null;
                  });
                  if (mounted) Navigator.pop(context);
                } else {
                  if (mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Error deleting location'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              } catch (e) {
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error deleting location: ${e.toString()}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final args =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;

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
          padding: const EdgeInsets.all(20.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
              const SizedBox(height: 40),
              const Text(
                'Choose Location',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: efficialsYellow,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              Container(
                padding: const EdgeInsets.all(24),
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
                      'Where will the game be played?',
                      style: TextStyle(
                        fontSize: 16,
                        color: primaryTextColor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : DropdownButtonFormField<String>(
                            decoration: textFieldDecoration('Choose location'),
                            value: selectedLocation != null 
                                ? () {
                                    // Find the first match for the selected location name
                                    for (int i = 0; i < locations.length; i++) {
                                      if (locations[i]['name'] == selectedLocation) {
                                        return '${locations[i]['name']}#$i';
                                      }
                                    }
                                    return null;
                                  }()
                                : null,
                            hint: const Text('Select a location',
                                style: TextStyle(color: efficialsGray)),
                            dropdownColor: darkSurface,
                            style: const TextStyle(
                                color: Colors.white, fontSize: 16),
                            onChanged: (newValue) {
                              if (newValue == null) return;
                              // Extract actual location name from unique value (format: "name#index")
                              final actualLocationName = newValue.contains('#') 
                                  ? newValue.substring(0, newValue.lastIndexOf('#'))
                                  : newValue;
                              setState(() {
                                selectedLocation = actualLocationName;
                                if (actualLocationName == '+ Create new location') {
                                  Navigator.pushNamed(
                                          context, '/add_new_location')
                                      .then((result) async {
                                    if (result != null) {
                                      final newLoc = result as Map<String, dynamic>;
                                      // Location was already created in AddNewLocationScreen
                                      // Just add it to our local list and select it
                                      setState(() {
                                        locations.insert(locations.length - 1, {
                                          'name': newLoc['name'],
                                          'address': newLoc['address'],
                                          'notes': newLoc['notes'],
                                          'id': newLoc['id'], // Use the ID returned from AddNewLocationScreen
                                        });
                                        selectedLocation = newLoc['name'];
                                      });
                                    }
                                  });
                                }
                              });
                            },
                            items: locations
                                .asMap()
                                .entries
                                .map((entry) {
                                  final index = entry.key;
                                  final loc = entry.value;
                                  final locationName = loc['name'] as String;
                                  // Create unique value by combining name with index to avoid duplicates
                                  final uniqueValue = '$locationName#$index';
                                  return DropdownMenuItem(
                                    value: uniqueValue,
                                    child: Text(locationName,
                                        style: const TextStyle(
                                            color: Colors.white)),
                                  );
                                })
                                .toList(),
                          ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              if (selectedLocation != null &&
                  selectedLocation != 'Away Game' &&
                  selectedLocation != '+ Create new location') ...[
                SizedBox(
                  width: 200,
                  child: ElevatedButton(
                    onPressed: () {
                      final selected = locations
                          .firstWhere((l) => l['name'] == selectedLocation);
                      Navigator.pushNamed(context, '/edit_location',
                          arguments: {'location': selected}).then((result) async {
                        if (result != null) {
                          final updatedLoc = result as Map<String, dynamic>;
                          setState(() {
                            final index = locations
                                .indexWhere((l) => l['id'] == selected['id']);
                            if (index != -1) {
                              locations[index] = updatedLoc;
                              selectedLocation = updatedLoc['name'];
                            }
                          });
                        }
                      });
                    },
                    style: elevatedButtonStyle(
                      padding: const EdgeInsets.symmetric(
                          vertical: 15, horizontal: 32),
                    ),
                    child: const Text('Edit Location',
                        style: signInButtonTextStyle),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: 200,
                  child: ElevatedButton(
                    onPressed: () {
                      final selected = locations
                          .firstWhere((l) => l['name'] == selectedLocation);
                      _showDeleteConfirmationDialog(
                          selectedLocation!, selected['id'] as int);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          vertical: 15, horizontal: 32),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Delete Location',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              SizedBox(
                width: 200,
                child: ElevatedButton(
                  onPressed: (selectedLocation != null &&
                          selectedLocation != '+ Create new location')
                      ? () {
                          final selected = locations
                              .firstWhere((l) => l['name'] == selectedLocation);
                          final isAwayGame = selectedLocation == 'Away Game';
                          final nextArgs = {
                            ...args, // Spread all original args to preserve parameters like isAssignerFlow
                            'location':
                                isAwayGame ? 'Away Game' : selected['name'],
                            'locationData': isAwayGame ? null : selected,
                            'isAwayGame': isAwayGame,
                            'template': template,
                            'isEdit': isFromEdit, // Explicitly pass the isEdit flag
                            // Ensure we preserve all existing args
                            'opponent': args['opponent'] ?? '', // Explicitly preserve opponent with fallback
                            'levelOfCompetition': args['levelOfCompetition'],
                            'gender': args['gender'],
                            'officialsRequired': args['officialsRequired'],
                            'gameFee': args['gameFee'],
                            'hireAutomatically': args['hireAutomatically'],
                            'selectedOfficials': args['selectedOfficials'],
                            'method': args['method'],
                            'selectedListName': args['selectedListName'],
                            'selectedLists': args['selectedLists'],
                            'time': args['time'], // Explicitly preserve time from template
                            'date': args['date'], // Explicitly preserve date
                          };
                          final isCoach =
                              args['teamName'] != null; // Detect Coach flow
                          
                          // Debug: Print location being passed
                          debugPrint('🔍 ChooseLocation - Location being set: ${nextArgs['location']}');
                          debugPrint('🔍 ChooseLocation - isAwayGame: $isAwayGame');
                          debugPrint('🔍 ChooseLocation - selected name: ${selected['name']}');
                          
                          // Check if we're in edit mode to determine correct navigation
                          if (isFromEdit) {
                            // Return to the calling edit screen with updated data
                            Navigator.pop(context, nextArgs);
                          } else {
                            Navigator.pushNamed(
                              context,
                              isCoach
                                  ? '/additional_game_info_condensed'
                                  : '/additional_game_info',
                              arguments: nextArgs,
                            );
                          }
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: efficialsYellow,
                    foregroundColor: efficialsBlack,
                    disabledBackgroundColor: Colors.grey[600],
                    disabledForegroundColor: Colors.grey[300],
                    padding: const EdgeInsets.symmetric(
                        vertical: 15, horizontal: 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Continue',
                      style: TextStyle(
                        color: efficialsBlack,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      )),
                ),
              ),
            ],
            ),
          ),
        ),
      ),
    );
  }
}
