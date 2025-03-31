import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'theme.dart';
import 'game_template.dart'; // Import the GameTemplate model

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

  @override
  void initState() {
    super.initState();
    _fetchSchedules();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Get the arguments from the current route
    final args = ModalRoute.of(context)!.settings.arguments;
    
    // Handle the case when args is a Map (coming from HomeScreen with a template)
    if (args is Map<String, dynamic>?) {
      if (args != null && args.containsKey('template')) {
        template = args['template'] as GameTemplate?;
      }
    }
  }

  Future<void> _fetchSchedules() async {
    final prefs = await SharedPreferences.getInstance();
    final String? unpublishedGamesJson = prefs.getString('unpublished_games');
    final String? publishedGamesJson = prefs.getString('published_games');

    // One-time migration: Update existing games to set a default sport
    if (unpublishedGamesJson != null && unpublishedGamesJson.isNotEmpty) {
      final unpublished = List<Map<String, dynamic>>.from(jsonDecode(unpublishedGamesJson));
      bool updated = false;
      for (var game in unpublished) {
        if (!game.containsKey('sport') || game['sport'] == 'Unknown Sport') {
          game['sport'] = 'Football'; // Set a default sport (adjust as needed)
          updated = true;
        }
      }
      if (updated) {
        await prefs.setString('unpublished_games', jsonEncode(unpublished));
        print('Migrated unpublished games with default sport: $unpublished');
      }
    }
    if (publishedGamesJson != null && publishedGamesJson.isNotEmpty) {
      final published = List<Map<String, dynamic>>.from(jsonDecode(publishedGamesJson));
      bool updated = false;
      for (var game in published) {
        if (!game.containsKey('sport') || game['sport'] == 'Unknown Sport') {
          game['sport'] = 'Football'; // Set a default sport (adjust as needed)
          updated = true;
        }
      }
      if (updated) {
        await prefs.setString('published_games', jsonEncode(published));
        print('Migrated published games with default sport: $published');
      }
    }

    setState(() {
      schedules.clear();
      try {
        if (unpublishedGamesJson != null && unpublishedGamesJson.isNotEmpty) {
          final unpublished = List<Map<String, dynamic>>.from(jsonDecode(unpublishedGamesJson));
          print('Unpublished games: $unpublished');
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
          final published = List<Map<String, dynamic>>.from(jsonDecode(publishedGamesJson));
          print('Published games: $published');
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
      } catch (e) {
        print('Error fetching schedules: $e');
      }
      if (schedules.isEmpty) {
        schedules.add({'name': 'No schedules available', 'id': -1, 'sport': 'None'});
      }
      schedules.add({'name': '+ Create new schedule', 'id': 0, 'sport': 'None'});
      print('Schedules after fetching: $schedules');
      isLoading = false;
    });
  }

  Future<void> _deleteSchedule(String scheduleName, int scheduleId) async {
    final prefs = await SharedPreferences.getInstance();
    final String? unpublishedGamesJson = prefs.getString('unpublished_games');
    final String? publishedGamesJson = prefs.getString('published_games');

    List<Map<String, dynamic>> unpublishedGames = [];
    List<Map<String, dynamic>> publishedGames = [];

    if (unpublishedGamesJson != null && unpublishedGamesJson.isNotEmpty) {
      unpublishedGames = List<Map<String, dynamic>>.from(jsonDecode(unpublishedGamesJson));
      unpublishedGames.removeWhere((game) => game['scheduleName'] == scheduleName);
      await prefs.setString('unpublished_games', jsonEncode(unpublishedGames));
    }

    if (publishedGamesJson != null && publishedGamesJson.isNotEmpty) {
      publishedGames = List<Map<String, dynamic>>.from(jsonDecode(publishedGamesJson));
      publishedGames.removeWhere((game) => game['scheduleName'] == scheduleName);
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

  void _showSecondDeleteConfirmationDialog(String scheduleName, int scheduleId) {
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
                selectedSchedule = schedules.isNotEmpty ? schedules[0]['name'] as String : null;
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

    final selected = schedules.firstWhere((s) => s['name'] == selectedSchedule, orElse: () => {});
    if (selected.isEmpty || selected['sport'] == null || selected['sport'] == 'None') {
      return true; // No sport associated with the schedule (e.g., "No schedules available" or "+ Create new schedule")
    }

    final scheduleSport = selected['sport'] as String;
    if (scheduleSport.toLowerCase() != template!.sport.toLowerCase()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('The selected schedule\'s sport ($scheduleSport) does not match the template\'s sport (${template!.sport}). Please select a different schedule.'),
        ),
      );
      return false;
    }
    return true;
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
        title: const Text('Select Schedule', style: appBarTextStyle),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 20),
                isLoading
                    ? const CircularProgressIndicator()
                    : DropdownButtonFormField<String>(
                        decoration: textFieldDecoration('Schedules'),
                        value: selectedSchedule,
                        hint: const Text('Select a schedule'),
                        onChanged: (newValue) {
                          setState(() {
                            selectedSchedule = newValue;
                            if (newValue == '+ Create new schedule') {
                              // Reset selectedSchedule to ensure the dropdown updates correctly
                              selectedSchedule = null;
                              Navigator.pushNamed(context, '/select_sport').then((result) async {
                                print('Returned from SelectSportScreen with result: $result');
                                if (result != null && result is String) {
                                  await _fetchSchedules();
                                  print('Schedules after fetch: $schedules');
                                  setState(() {
                                    if (schedules.any((s) => s['name'] == result)) {
                                      selectedSchedule = result;
                                      print('Set selectedSchedule to: $selectedSchedule');
                                    } else {
                                      print('Schedule $result not found in schedules');
                                      // Fallback: Select the first schedule if the new one isn't found
                                      if (schedules.isNotEmpty && schedules.first['name'] != 'No schedules available') {
                                        selectedSchedule = schedules.first['name'] as String;
                                      }
                                    }
                                  });
                                } else {
                                  print('Result is null or not a String');
                                  // Fallback: Refresh schedules in case the new schedule was created
                                  await _fetchSchedules();
                                  print('Schedules after fallback fetch: $schedules');
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
                              style: schedule['name'] == 'No schedules available'
                                  ? const TextStyle(color: Colors.red)
                                  : null,
                            ),
                          );
                        }).toList(),
                      ),
                const SizedBox(height: 60),
                ElevatedButton(
                  onPressed: (selectedSchedule == null ||
                          selectedSchedule == 'No schedules available' ||
                          selectedSchedule == '+ Create new schedule')
                      ? null
                      : () {
                          // Validate sport match if a template is used
                          if (!_validateSportMatch()) {
                            return;
                          }
                          final selected = schedules.firstWhere((s) => s['name'] == selectedSchedule);
                          Navigator.pushNamed(
                            context,
                            '/date_time',
                            arguments: {
                              'scheduleName': selectedSchedule,
                              'sport': selected['sport'],
                              'template': template, // Pass the template to the next screen
                            },
                          );
                        },
                  style: elevatedButtonStyle(),
                  child: const Text('Continue', style: signInButtonTextStyle),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: (selectedSchedule == null ||
                          selectedSchedule == 'No schedules available' ||
                          selectedSchedule == '+ Create new schedule')
                      ? null
                      : () {
                          final selected = schedules.firstWhere((s) => s['name'] == selectedSchedule);
                          _showFirstDeleteConfirmationDialog(selectedSchedule!, selected['id'] as int);
                        },
                  style: elevatedButtonStyle(backgroundColor: Colors.red),
                  child: const Text('Delete', style: signInButtonTextStyle),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}