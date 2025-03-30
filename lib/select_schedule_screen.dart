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

    setState(() {
      schedules.clear();
      final scheduleNames = <String>{}; // Use Set for uniqueness

      void addSchedulesFromJson(String? json) {
        if (json != null && json.isNotEmpty) {
          final games = List<Map<String, dynamic>>.from(jsonDecode(json));
          for (var game in games) {
            scheduleNames.add(game['scheduleName'] as String? ?? 'Unnamed');
          }
        }
      }

      addSchedulesFromJson(unpublishedGamesJson);
      addSchedulesFromJson(publishedGamesJson);

      schedules = scheduleNames
          .map((name) => <String, dynamic>{'name': name, 'id': 1})
          .toList();
      if (schedules.isEmpty) {
        schedules.add(<String, dynamic>{'name': 'No schedules available', 'id': -1});
      }
      schedules.add(<String, dynamic>{'name': '+ Create new schedule', 'id': 0});
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
            padding: const EdgeInsets.all(16.0),
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
                                  : null, // Black by default unless red
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
                          Navigator.pushNamed(
                            context,
                            '/date_time',
                            arguments: {'scheduleName': selectedSchedule},
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