import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'theme.dart';

class SelectScheduleScreen extends StatefulWidget {
  const SelectScheduleScreen({super.key});

  @override
  State<SelectScheduleScreen> createState() => _SelectScheduleScreenState();
}

class _SelectScheduleScreenState extends State<SelectScheduleScreen> {
  String? selectedSchedule;
  List<Map<String, dynamic>> schedules = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchSchedules();
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
                              Navigator.pushNamed(context, '/select_sport');
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
                          final selectedScheduleData = schedules.firstWhere(
                            (schedule) => schedule['name'] == selectedSchedule,
                            orElse: () => {'name': selectedSchedule, 'sport': 'Unknown Sport'},
                          );
                          print('Navigating to DateTimeScreen with schedule: $selectedScheduleData');
                          Navigator.pushNamed(
                            context,
                            '/date_time',
                            arguments: {
                              'scheduleName': selectedSchedule,
                              'sport': selectedScheduleData['sport'],
                            },
                          );
                        },
                  style: elevatedButtonStyle(),
                  child: const Text('Continue', style: signInButtonTextStyle),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}