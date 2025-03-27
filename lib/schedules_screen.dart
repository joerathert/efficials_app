import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'theme.dart';

class SchedulesScreen extends StatefulWidget {
  const SchedulesScreen({super.key});

  @override
  State<SchedulesScreen> createState() => _SchedulesScreenState();
}

class _SchedulesScreenState extends State<SchedulesScreen> {
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

    setState(() {
      schedules.clear();
      try {
        if (unpublishedGamesJson != null && unpublishedGamesJson.isNotEmpty) {
          final unpublished = List<Map<String, dynamic>>.from(jsonDecode(unpublishedGamesJson));
          for (var game in unpublished) {
            if (!schedules.any((s) => s['name'] == game['scheduleName'])) {
              schedules.add({'name': game['scheduleName'] as String, 'id': game['id']});
            }
          }
        }
        if (publishedGamesJson != null && publishedGamesJson.isNotEmpty) {
          final published = List<Map<String, dynamic>>.from(jsonDecode(publishedGamesJson));
          for (var game in published) {
            if (!schedules.any((s) => s['name'] == game['scheduleName'])) {
              schedules.add({'name': game['scheduleName'] as String, 'id': game['id']});
            }
          }
        }
      } catch (e) {
        print('Error fetching schedules: $e');
      }
      if (schedules.isEmpty) {
        schedules.add({'name': 'No schedules available', 'id': -1});
      }
      schedules.add({'name': '+ Create new schedule', 'id': 0});
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
        title: const Text('Schedules', style: appBarTextStyle),
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
                          final selected = schedules.firstWhere((s) => s['name'] == selectedSchedule);
                          Navigator.pushNamed(
                            context,
                            '/schedule_details',
                            arguments: {
                              'scheduleName': selectedSchedule,
                              'scheduleId': selected['id'],
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