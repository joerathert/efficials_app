import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../shared/theme.dart';
import '../games/game_template.dart'; // Import the GameTemplate model
import '../../shared/services/schedule_service.dart';

class SelectScheduleScreen extends StatefulWidget {
  const SelectScheduleScreen({super.key});

  @override
  State<SelectScheduleScreen> createState() => _SelectScheduleScreenState();
}

class _SelectScheduleScreenState extends State<SelectScheduleScreen> {
  String? selectedSchedule;
  List<Map<String, dynamic>> schedules = [];
  bool isLoading = true;
  GameTemplate? template; // Store the selected template
  final ScheduleService _scheduleService = ScheduleService();
  bool _hasInitialized = false; // Flag to prevent multiple initializations

  @override
  void initState() {
    super.initState();
    // Don't fetch schedules immediately - wait for template to load in didChangeDependencies
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    // Only initialize once to prevent multiple calls
    if (!_hasInitialized) {
      _hasInitialized = true;
      
      // Get the arguments from the current route
      final args = ModalRoute.of(context)!.settings.arguments;

      // Handle the case when args is a Map (coming from HomeScreen with a template)
      if (args is Map<String, dynamic>?) {
        if (args != null && args.containsKey('template')) {
          template = args['template'] as GameTemplate?;
        }
      }
      
      // Now fetch schedules after template is loaded
      _fetchSchedules();
    }
  }

  Future<void> _fetchSchedules() async {
    try {
      // Try to get schedules from database first
      final schedulesList = await _scheduleService.getSchedules();
      
      setState(() {
        schedules = schedulesList;
        
        // Filter schedules by the template's sport if a template is provided
        if (template != null &&
            template!.includeSport &&
            template!.sport != null) {
          schedules = schedules
              .where((schedule) =>
                  schedule['sport'] == template!.sport ||
                  schedule['name'] == '+ Create new schedule')
              .toList();
        }
        
        // Add default options if no schedules are available
        if (schedules.isEmpty) {
          schedules.add({'name': 'No schedules available', 'id': -1, 'sport': 'None'});
        }
        schedules.add({'name': '+ Create new schedule', 'id': 0, 'sport': 'None'});
        
        // Ensure selectedSchedule is valid or null
        if (selectedSchedule != null && !schedules.any((s) => s['name'] == selectedSchedule)) {
          selectedSchedule = null;
        }
        
        isLoading = false;
      });
    } catch (e) {
      // Fallback to SharedPreferences if database fails
      await _fetchSchedulesFromPrefs();
    }
  }

  Future<void> _fetchSchedulesFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final String? unpublishedGamesJson = prefs.getString('unpublished_games');
    final String? publishedGamesJson = prefs.getString('published_games');

    // One-time migration: Update existing games to set a default sport
    if (unpublishedGamesJson != null && unpublishedGamesJson.isNotEmpty) {
      final unpublished =
          List<Map<String, dynamic>>.from(jsonDecode(unpublishedGamesJson));
      bool updated = false;
      for (var game in unpublished) {
        if (!game.containsKey('sport') || game['sport'] == 'Unknown Sport') {
          game['sport'] = 'Football'; // Set a default sport (adjust as needed)
          updated = true;
        }
      }
      if (updated) {
        await prefs.setString('unpublished_games', jsonEncode(unpublished));
      }
    }
    if (publishedGamesJson != null && publishedGamesJson.isNotEmpty) {
      final published =
          List<Map<String, dynamic>>.from(jsonDecode(publishedGamesJson));
      bool updated = false;
      for (var game in published) {
        if (!game.containsKey('sport') || game['sport'] == 'Unknown Sport') {
          game['sport'] = 'Football'; // Set a default sport (adjust as needed)
          updated = true;
        }
      }
      if (updated) {
        await prefs.setString('published_games', jsonEncode(published));
      }
    }

    setState(() {
      schedules.clear();
      try {
        if (unpublishedGamesJson != null && unpublishedGamesJson.isNotEmpty) {
          final unpublished =
              List<Map<String, dynamic>>.from(jsonDecode(unpublishedGamesJson));
          for (var game in unpublished) {
            if (!schedules.any((s) => s['name'] == game['scheduleName'])) {
              schedules.add({
                'name': game['scheduleName'] as String,
                'id': game['id'],
                'sport': game['sport'] as String? ?? 'Unknown Sport',
              });
            }
          }
        }
        if (publishedGamesJson != null && publishedGamesJson.isNotEmpty) {
          final published =
              List<Map<String, dynamic>>.from(jsonDecode(publishedGamesJson));
          for (var game in published) {
            if (!schedules.any((s) => s['name'] == game['scheduleName'])) {
              schedules.add({
                'name': game['scheduleName'] as String,
                'id': game['id'],
                'sport': game['sport'] as String? ?? 'Unknown Sport',
              });
            }
          }
        }

        // Filter schedules by the template's sport if a template is provided
        if (template != null &&
            template!.includeSport &&
            template!.sport != null) {
          schedules = schedules
              .where((schedule) =>
                  schedule['sport'] == template!.sport ||
                  schedule['name'] == '+ Create new schedule')
              .toList();
        }

        if (schedules.isEmpty) {
          schedules
              .add({'name': 'No schedules available', 'id': -1, 'sport': 'None'});
        }
        schedules
            .add({'name': '+ Create new schedule', 'id': 0, 'sport': 'None'});
        
        // Ensure selectedSchedule is valid or null
        if (selectedSchedule != null && !schedules.any((s) => s['name'] == selectedSchedule)) {
          selectedSchedule = null;
        }
        
        isLoading = false;
      } catch (e) {
        // Handle parsing errors
        schedules.clear();
        schedules
            .add({'name': 'No schedules available', 'id': -1, 'sport': 'None'});
        schedules
            .add({'name': '+ Create new schedule', 'id': 0, 'sport': 'None'});
        
        // Ensure selectedSchedule is valid or null
        if (selectedSchedule != null && !schedules.any((s) => s['name'] == selectedSchedule)) {
          selectedSchedule = null;
        }
        
        isLoading = false;
      }
    });
  }

  Future<void> _deleteSchedule(String scheduleName, int scheduleId) async {
    final prefs = await SharedPreferences.getInstance();
    final String? unpublishedGamesJson = prefs.getString('unpublished_games');
    final String? publishedGamesJson = prefs.getString('published_games');

    List<Map<String, dynamic>> unpublishedGames = [];
    List<Map<String, dynamic>> publishedGames = [];

    if (unpublishedGamesJson != null && unpublishedGamesJson.isNotEmpty) {
      unpublishedGames =
          List<Map<String, dynamic>>.from(jsonDecode(unpublishedGamesJson));
      unpublishedGames
          .removeWhere((game) => game['scheduleName'] == scheduleName);
      await prefs.setString('unpublished_games', jsonEncode(unpublishedGames));
    }

    if (publishedGamesJson != null && publishedGamesJson.isNotEmpty) {
      publishedGames =
          List<Map<String, dynamic>>.from(jsonDecode(publishedGamesJson));
      publishedGames
          .removeWhere((game) => game['scheduleName'] == scheduleName);
      await prefs.setString('published_games', jsonEncode(publishedGames));
    }

    // Refresh the schedule list
    await _fetchSchedules();
  }

  void _showFirstDeleteConfirmationDialog(String scheduleName, int scheduleId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: Text('Are you sure you want to delete "$scheduleName"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: efficialsBlue)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _showSecondDeleteConfirmationDialog(scheduleName, scheduleId);
            },
            child: const Text('Delete', style: TextStyle(color: efficialsBlue)),
          ),
        ],
      ),
    );
  }

  void _showSecondDeleteConfirmationDialog(
      String scheduleName, int scheduleId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Final Confirmation'),
        content: const Text(
          'Deleting a schedule will erase all games associated with the schedule. Are you sure you want to delete this schedule?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: efficialsBlue)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deleteSchedule(scheduleName, scheduleId);
              setState(() {
                selectedSchedule = schedules.isNotEmpty
                    ? schedules[0]['name'] as String
                    : null;
              });
            },
            child: const Text('Delete', style: TextStyle(color: efficialsBlue)),
          ),
        ],
      ),
    );
  }

  bool _validateSportMatch() {
    if (template == null || !template!.includeSport) {
      return true; // No template or sport not included, so no validation needed
    }

    final selected = schedules.firstWhere((s) => s['name'] == selectedSchedule,
        orElse: () => {});
    if (selected.isEmpty ||
        selected['sport'] == null ||
        selected['sport'] == 'None') {
      return true; // No sport associated with the schedule (e.g., "No schedules available" or "+ Create new schedule")
    }

    final scheduleSport = selected['sport'] as String;
    final templateSport =
        template!.sport?.toLowerCase() ?? ''; // Handle null sport
    if (scheduleSport.toLowerCase() != templateSport) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'The selected schedule\'s sport ($scheduleSport) does not match the template\'s sport (${template!.sport ?? "Not set"}). Please select a different schedule.'),
        ),
      );
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
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
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 40),
              const Text(
                'Select Schedule',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: efficialsYellow,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Choose an existing schedule or create a new one',
                style: TextStyle(
                  fontSize: 16,
                  color: secondaryTextColor,
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
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : DropdownButtonFormField<String>(
                            decoration:
                                textFieldDecoration('Select a schedule'),
                            value: selectedSchedule,
                            hint: const Text('Choose from existing schedules',
                                style: TextStyle(color: efficialsGray)),
                            dropdownColor: darkSurface,
                            style: const TextStyle(
                                color: Colors.white, fontSize: 16),
                            isDense: false,
                            isExpanded: true,
                            onChanged: (newValue) {
                              setState(() {
                                selectedSchedule = newValue;
                                if (newValue == '+ Create new schedule') {
                                  // Reset selectedSchedule to ensure the dropdown updates correctly
                                  selectedSchedule = null;
                                  Navigator.pushNamed(context, '/select_sport',
                                      arguments: {
                                        'fromTemplate':
                                            true, // Indicate this navigation is from a template
                                        'sport': template
                                            ?.sport, // Pass the template's sport
                                      }).then((result) async {
                                    if (result != null) {
                                      await _fetchSchedules();
                                      
                                      // Handle both schedule objects and schedule names
                                      String? scheduleName;
                                      if (result is Map<String, dynamic>) {
                                        // Result is a schedule object from database
                                        scheduleName = result['name'] as String?;
                                      } else if (result is String) {
                                        // Result is a schedule name from SharedPreferences
                                        scheduleName = result;
                                      }
                                      
                                      setState(() {
                                        if (scheduleName != null && schedules
                                            .any((s) => s['name'] == scheduleName)) {
                                          selectedSchedule = scheduleName;
                                        } else {
                                          // Fallback: Select the first schedule if the new one isn't found
                                          if (schedules.isNotEmpty &&
                                              schedules.first['name'] !=
                                                  'No schedules available') {
                                            selectedSchedule = schedules
                                                .first['name'] as String;
                                          }
                                        }
                                      });
                                    } else {
                                      // Fallback: Refresh schedules in case the new schedule was created
                                      await _fetchSchedules();
                                    }
                                  });
                                }
                              });
                            },
                            items: schedules.map((schedule) {
                              return DropdownMenuItem(
                                value: schedule['name'] as String,
                                child: Text(
                                  schedule['name'] as String,
                                  style: schedule['name'] ==
                                          'No schedules available'
                                      ? const TextStyle(color: Colors.red)
                                      : const TextStyle(color: Colors.white),
                                ),
                              );
                            }).toList(),
                          ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              Center(
                child: SizedBox(
                  width: 200,
                  child: ElevatedButton(
                    onPressed: (selectedSchedule == null ||
                            selectedSchedule == 'No schedules available' ||
                            selectedSchedule == '+ Create new schedule')
                        ? null
                        : () {
                            // Validate sport match if a template is used
                            if (!_validateSportMatch()) {
                              return;
                            }
                            final selected = schedules.firstWhere(
                                (s) => s['name'] == selectedSchedule);
                            Navigator.pushNamed(
                              context,
                              '/date_time',
                              arguments: {
                                'scheduleName': selectedSchedule,
                                'sport': selected['sport'],
                                'template':
                                    template, // Pass the template to the next screen
                              },
                            );
                          },
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
              ),
              const SizedBox(height: 16),
              if (selectedSchedule != null &&
                  selectedSchedule != 'No schedules available' &&
                  selectedSchedule != '+ Create new schedule')
                Center(
                  child: SizedBox(
                    width: 200,
                    child: ElevatedButton(
                      onPressed: () {
                        final selected = schedules
                            .firstWhere((s) => s['name'] == selectedSchedule);
                        _showFirstDeleteConfirmationDialog(
                            selectedSchedule!, selected['id'] as int);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(
                            vertical: 15, horizontal: 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Delete',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
