import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'theme.dart';

class SelectSportScreen extends StatefulWidget {
  const SelectSportScreen({super.key});

  @override
  State<SelectSportScreen> createState() => _SelectSportScreenState();
}

class _SelectSportScreenState extends State<SelectSportScreen> {
  String? selectedSport;
  List<String> existingSchedules = [];
  static const List<String> sports = [
    'Football',
    'Basketball',
    'Baseball',
    'Soccer',
    'Volleyball',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _fetchSchedules();
  }

  Future<void> _fetchSchedules() async {
    final prefs = await SharedPreferences.getInstance();
    final String? unpublishedGamesJson = prefs.getString('unpublished_games');
    final String? publishedGamesJson = prefs.getString('published_games');

    final scheduleNames = <String>{};
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
    setState(() {
      existingSchedules = scheduleNames.toList();
    });
  }

  void _onSportSelected(String? newValue) {
    setState(() => selectedSport = newValue);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, size: 36, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Select Sport', style: appBarTextStyle),
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
                    'Select a sport for your schedule.',
                    style: headlineStyle,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  DropdownButtonFormField<String>(
                    decoration: textFieldDecoration('Sport'),
                    value: selectedSport,
                    hint: const Text('Select a sport'),
                    onChanged: _onSportSelected,
                    items: sports
                        .map((value) => DropdownMenuItem(
                              value: value,
                              child: Text(value),
                            ))
                        .toList(),
                  ),
                  const SizedBox(height: 60),
                  ElevatedButton(
                    onPressed: () {
                      if (selectedSport != null) {
                        Navigator.pushNamed(
                          context,
                          '/name_schedule',
                          arguments: {
                            'sport': selectedSport,
                            'existingSchedules': existingSchedules,
                          },
                        ).then((result) {
                          if (result != null) {
                            // Pass the new schedule name back to SelectScheduleScreen
                            Navigator.pop(context, result);
                          }
                        });
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Please select a sport!')),
                        );
                      }
                    },
                    style: elevatedButtonStyle(),
                    child: const Text('Continue', style: signInButtonTextStyle),
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