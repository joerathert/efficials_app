import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'theme.dart';

class NameScheduleScreen extends StatefulWidget {
  const NameScheduleScreen({super.key});

  @override
  State<NameScheduleScreen> createState() => _NameScheduleScreenState();
}

class _NameScheduleScreenState extends State<NameScheduleScreen> {
  final _nameController = TextEditingController();
  String? _sport;
  List<String> _existingSchedules = [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null) {
      _sport = args['sport'] as String?;
      _existingSchedules = args['existingSchedules'] as List<String>? ?? [];
    }
    if (_sport == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: Sport not provided')),
      );
      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _saveSchedule(String scheduleName) async {
    final prefs = await SharedPreferences.getInstance();
    final String? unpublishedGamesJson = prefs.getString('unpublished_games');
    List<Map<String, dynamic>> unpublishedGames = [];
    if (unpublishedGamesJson != null && unpublishedGamesJson.isNotEmpty) {
      unpublishedGames = List<Map<String, dynamic>>.from(jsonDecode(unpublishedGamesJson));
    }
    // Add a dummy game entry to ensure the schedule name appears in SelectScheduleScreen
    unpublishedGames.add({
      'scheduleName': scheduleName,
      'sport': _sport,
      'id': DateTime.now().millisecondsSinceEpoch,
      // Add minimal fields to avoid breaking other screens
      'date': DateTime.now().toIso8601String(),
      'time': TimeOfDay.now().format(context),
      'location': null,
      'isAway': false,
    });
    await prefs.setString('unpublished_games', jsonEncode(unpublishedGames));
  }

  void _handleContinue() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a schedule name!')),
      );
      return;
    }
    if (RegExp(r'^\s+$').hasMatch(name)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Schedule name cannot be just spaces!')),
      );
      return;
    }
    if (_existingSchedules.contains(name)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Schedule name must be unique!')),
      );
      return;
    }
    // Save the schedule and navigate back to SelectScheduleScreen
    _saveSchedule(name).then((_) {
      Navigator.popUntil(context, ModalRoute.withName('/select_schedule'));
      Navigator.pushNamed(
        context,
        '/select_schedule',
        arguments: {'newScheduleName': name},
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, size: 36, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Name Schedule', style: appBarTextStyle),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    'Provide a name for your new ${_sport?.toUpperCase() ?? 'SPORT'} schedule. The name you choose should identify the level of competition.',
                    style: headlineStyle,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _nameController,
                    decoration: textFieldDecoration('Ex. Varsity ${_sport ?? 'Sport'}'),
                    style: const TextStyle(fontSize: 18),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Note: There is no need to specify a time period for your schedule. For example, use "Varsity Football" rather than "2025 Varsity Football".',
                    style: secondaryTextStyle,
                    textAlign: TextAlign.left,
                  ),
                  const SizedBox(height: 60),
                  Center(
                    child: ElevatedButton(
                      onPressed: _handleContinue,
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