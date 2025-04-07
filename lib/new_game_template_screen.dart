import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'game_template.dart';
import 'theme.dart';

class NewGameTemplateScreen extends StatefulWidget {
  final Map<String, dynamic> gameData;

  const NewGameTemplateScreen({super.key, required this.gameData});

  @override
  State<NewGameTemplateScreen> createState() => _NewGameTemplateScreenState();
}

class _NewGameTemplateScreenState extends State<NewGameTemplateScreen> {
  late String sport;
  late TimeOfDay? time;
  late String? location;
  late String? levelOfCompetition;
  late String? gender;
  late int? officialsRequired;
  late String? gameFee; // Changed from double? to String?
  late bool? hireAutomatically;
  late String? selectedListName;
  late String? method;
  late List<String>? selectedOfficials;
  late String officialsDisplay; // For displaying the officials selection

  bool includeSport = true;
  bool includeTime = true;
  bool includeLocation = true;
  bool includeLevelOfCompetition = true;
  bool includeGender = true;
  bool includeOfficialsRequired = true;
  bool includeGameFee = true;
  bool includeHireAutomatically = true;
  bool includeOfficialsList = true;
  bool includeSelectedOfficials = true;

  final TextEditingController _nameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Debug print to inspect gameData
    print('NewGameTemplateScreen gameData: ${widget.gameData}');

    sport = widget.gameData['sport'] as String;
    // Handle the time field, which may be a String in "hour:minute" format
    if (widget.gameData['time'] != null) {
      if (widget.gameData['time'] is String) {
        final timeStr = widget.gameData['time'] as String;
        final parts = timeStr.split(':');
        time = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
      } else if (widget.gameData['time'] is TimeOfDay) {
        time = widget.gameData['time'] as TimeOfDay;
      } else if (widget.gameData['time'] is Map) {
        // Handle case where time is a Map (e.g., {"hour": 23, "minute": 0})
        final timeMap = widget.gameData['time'] as Map<String, dynamic>;
        time = TimeOfDay(
          hour: int.parse(timeMap['hour'].toString()),
          minute: int.parse(timeMap['minute'].toString()),
        );
      } else {
        time = null;
      }
    } else {
      time = null;
    }
    location = widget.gameData['location'] as String?;
    levelOfCompetition = widget.gameData['levelOfCompetition'] as String?;
    gender = widget.gameData['gender'] as String?;
    officialsRequired = widget.gameData['officialsRequired'] as int?;
    // Handle the gameFee field, which may be a String (e.g., "100" or "$100")
    if (widget.gameData['gameFee'] != null) {
      if (widget.gameData['gameFee'] is String) {
        final feeStr = widget.gameData['gameFee'] as String;
        // Remove any "$" symbol and ensure it's a clean numeric string
        final cleanedFeeStr = feeStr.replaceAll(r'$', '');
        // Parse to double to validate, then convert back to a clean string
        final feeDouble = double.tryParse(cleanedFeeStr);
        gameFee = feeDouble != null ? feeDouble.toStringAsFixed(0) : null; // e.g., "100"
      } else if (widget.gameData['gameFee'] is double) {
        gameFee = (widget.gameData['gameFee'] as double).toStringAsFixed(0); // e.g., "100"
      } else {
        gameFee = null;
      }
    } else {
      gameFee = null;
    }
    hireAutomatically = widget.gameData['hireAutomatically'] as bool?;
    selectedListName = widget.gameData['selectedListName'] as String?;
    method = widget.gameData['method'] as String?;
    selectedOfficials = widget.gameData['selectedOfficials'] != null
        ? List<String>.from(widget.gameData['selectedOfficials'].map((official) => official['name'] as String))
        : null;

    // Debug prints to verify values
    print('method: $method');
    print('selectedListName: $selectedListName');
    print('selectedOfficials: $selectedOfficials');
    print('gameFee: $gameFee');
    print('time: $time');

    // Compute the display string for officials
    if (method == 'use_list' && selectedListName != null) {
      officialsDisplay = 'List Used ($selectedListName)';
    } else if (method == 'standard' && selectedOfficials != null && selectedOfficials!.isNotEmpty) {
      officialsDisplay = 'Standard (${selectedOfficials!.join(', ')})';
    } else if (method == 'advanced' && selectedOfficials != null && selectedOfficials!.isNotEmpty) {
      officialsDisplay = 'Advanced (${selectedOfficials!.join(', ')})';
    } else {
      officialsDisplay = 'None';
    }
    print('officialsDisplay: $officialsDisplay');
  }

  Future<void> _saveTemplate() async {
  if (_nameController.text.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Please enter a name for the template')),
    );
    return;
  }

  final template = GameTemplate(
    id: DateTime.now().millisecondsSinceEpoch.toString(), // Generate unique ID
    name: _nameController.text,
    sport: sport,
    includeSport: includeSport,
    time: time,
    includeTime: includeTime,
    location: location,
    includeLocation: includeLocation,
    levelOfCompetition: levelOfCompetition,
    includeLevelOfCompetition: includeLevelOfCompetition,
    gender: gender,
    includeGender: includeGender,
    officialsRequired: officialsRequired,
    includeOfficialsRequired: includeOfficialsRequired,
    gameFee: gameFee,
    includeGameFee: includeGameFee,
    hireAutomatically: hireAutomatically,
    includeHireAutomatically: includeHireAutomatically,
    officialsListName: selectedListName,
    includeOfficialsList: includeOfficialsList,
    method: method,
    selectedOfficials: selectedOfficials?.map((name) => {'name': name}).toList(),
    includeSelectedOfficials: includeSelectedOfficials,
  );

  final prefs = await SharedPreferences.getInstance();
  final String? templatesJson = prefs.getString('game_templates');
  List<GameTemplate> templates = [];
  if (templatesJson != null && templatesJson.isNotEmpty) {
    final List<dynamic> decoded = jsonDecode(templatesJson);
    templates = decoded.map((json) => GameTemplate.fromJson(json)).toList();
  }
  templates.add(template);
  await prefs.setString('game_templates', jsonEncode(templates.map((t) => t.toJson()).toList()));

  Navigator.pop(context, true);
}

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: efficialsBlue,
        title: const Text('New Game Template', style: appBarTextStyle),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _nameController,
              decoration: textFieldDecoration('Template Name'),
            ),
            const SizedBox(height: 20),
            const Text('Select fields to include in the template:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            _buildFieldRow('Sport', sport, (value) => setState(() => includeSport = value!)),
            if (time != null) _buildFieldRow('Time', time!.format(context), (value) => setState(() => includeTime = value!)),
            if (location != null) _buildFieldRow('Location', location!, (value) => setState(() => includeLocation = value!)),
            if (levelOfCompetition != null) _buildFieldRow('Level of Competition', levelOfCompetition!, (value) => setState(() => includeLevelOfCompetition = value!)),
            if (gender != null) _buildFieldRow('Gender', gender!, (value) => setState(() => includeGender = value!)),
            if (officialsRequired != null) _buildFieldRow('Officials Required', officialsRequired.toString(), (value) => setState(() => includeOfficialsRequired = value!)),
            if (gameFee != null) _buildFieldRow('Game Fee', '\$${double.parse(gameFee!).toStringAsFixed(2)}', (value) => setState(() => includeGameFee = value!)),
            if (hireAutomatically != null) _buildFieldRow('Hire Automatically', hireAutomatically! ? 'Yes' : 'No', (value) => setState(() => includeHireAutomatically = value!)),
            if (officialsDisplay != 'None') _buildFieldRow('Selected Officials', officialsDisplay, (value) => setState(() => includeSelectedOfficials = value!)),
            const SizedBox(height: 20),
            Center(
              child: ElevatedButton(
                onPressed: _saveTemplate,
                style: elevatedButtonStyle(),
                child: const Text('Save Template', style: signInButtonTextStyle),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFieldRow(String label, String value, Function(bool?) onChanged) {
    return Row(
      children: [
        Checkbox(
          value: label == 'Sport' ? includeSport :
                label == 'Time' ? includeTime :
                label == 'Location' ? includeLocation :
                label == 'Level of Competition' ? includeLevelOfCompetition :
                label == 'Gender' ? includeGender :
                label == 'Officials Required' ? includeOfficialsRequired :
                label == 'Game Fee' ? includeGameFee :
                label == 'Hire Automatically' ? includeHireAutomatically :
                label == 'Selected Officials' ? includeSelectedOfficials :
                false,
          onChanged: onChanged,
          activeColor: efficialsBlue,
        ),
        Expanded(child: Text('$label: $value')),
      ],
    );
  }
}