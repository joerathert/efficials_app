import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../shared/models/database_models.dart';
import '../../shared/theme.dart';
import '../../shared/services/game_service.dart';

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
  final GameService _gameService = GameService();

  @override
  void initState() {
    super.initState();
    // Check multiple possible sport field names
    sport = (widget.gameData['sport'] as String?) ?? 
            (widget.gameData['sportName'] as String?) ?? 
            (widget.gameData['sport_name'] as String?) ?? 
            'Baseball'; // Default fallback
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
        gameFee = feeDouble?.toStringAsFixed(0); // e.g., "100"
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
        ? List<String>.from(widget.gameData['selectedOfficials'].map((official) => (official['name'] as String?) ?? 'Unknown Official'))
        : null;


    // Compute the display string for officials
    if (method == 'use_list' && selectedListName != null) {
      officialsDisplay = 'List Used ($selectedListName)';
    } else if (method == 'standard' && selectedOfficials != null && selectedOfficials!.isNotEmpty) {
      officialsDisplay = 'Standard (${selectedOfficials!.join(', ')})';
    } else if (method == 'advanced') {
      // Check if we have selectedLists data for advanced method
      final selectedLists = widget.gameData['selectedLists'] as List<dynamic>?;
      if (selectedLists != null && selectedLists.isNotEmpty) {
        final listConstraints = selectedLists.map((list) {
          final listMap = list as Map<String, dynamic>;
          return '${listMap['name']} - Max ${listMap['maxOfficials']} Min ${listMap['minOfficials']}';
        }).join(', ');
        officialsDisplay = 'Advanced ($listConstraints)';
      } else if (selectedOfficials != null && selectedOfficials!.isNotEmpty) {
        // Fallback to showing selected officials if selectedLists not available
        officialsDisplay = 'Advanced (${selectedOfficials!.join(', ')})';
      } else {
        officialsDisplay = 'Advanced (No constraints set)';
      }
    } else {
      officialsDisplay = 'None';
    }
  }

  Future<void> _saveTemplate() async {
    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a name for the template')),
      );
      return;
    }

    // Get officials list ID if we have a list name
    int? officialsListId;
    if (selectedListName != null && selectedListName!.isNotEmpty) {
      officialsListId = await _getOfficialsListId(selectedListName!);
    }

    // Prepare template data for database
    final templateData = {
      'name': _nameController.text,
      'sport': sport,
      'includeSport': includeSport,
      'time': time,
      'includeTime': includeTime,
      'location': location,
      'includeLocation': includeLocation,
      'levelOfCompetition': levelOfCompetition,
      'includeLevelOfCompetition': includeLevelOfCompetition,
      'gender': gender,
      'includeGender': includeGender,
      'officialsRequired': officialsRequired,
      'includeOfficialsRequired': includeOfficialsRequired,
      'gameFee': gameFee,
      'includeGameFee': includeGameFee,
      'hireAutomatically': hireAutomatically,
      'includeHireAutomatically': includeHireAutomatically,
      'officialsListId': officialsListId,  // Save the ID for database reference
      'officialsListName': selectedListName,  // Also save the name directly
      'includeOfficialsList': includeOfficialsList,
      'method': method,
      'selectedOfficials': selectedOfficials?.map((name) => {'name': name}).toList(),
      'includeSelectedOfficials': includeSelectedOfficials,
    };

    try {
      // Save template to database
      final result = await _gameService.createTemplate(templateData);
      
      if (result != null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Template saved successfully!')),
          );
          Navigator.pop(context, true);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to save template. Template name might already exist.')),
          );
        }
      }
    } catch (e) {
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error saving template. Please try again.')),
        );
      }
    }
  }

  Future<int?> _getOfficialsListId(String listName) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? listsJson = prefs.getString('saved_lists');
      
      if (listsJson != null && listsJson.isNotEmpty) {
        final List<dynamic> lists = jsonDecode(listsJson);
        for (final list in lists) {
          if (list['name'] == listName) {
            return (list['id'] as int?) ?? 0;
          }
        }
      }
    } catch (e) {
      // Error looking up list ID
    }
    return null;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: darkBackground,
      appBar: AppBar(
        backgroundColor: efficialsBlack,
        title: const Text('New Game Template', style: appBarTextStyle),
        iconTheme: const IconThemeData(color: efficialsWhite),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _nameController,
              decoration: textFieldDecoration('Template Name'),
              style: textFieldTextStyle,
            ),
            const SizedBox(height: 20),
            const Text('Select fields to include in the template:', style: headlineStyle),
            const SizedBox(height: 10),
            _buildFieldRow('Sport', sport, (value) => setState(() => includeSport = value!)),
            if (time != null) _buildFieldRow('Time', time!.format(context), (value) => setState(() => includeTime = value!)),
            if (location != null) _buildFieldRow('Location', location!, (value) => setState(() => includeLocation = value!)),
            if (levelOfCompetition != null) _buildFieldRow('Level of Competition', levelOfCompetition!, (value) => setState(() => includeLevelOfCompetition = value!)),
            if (gender != null) _buildFieldRow('Gender', gender!, (value) => setState(() => includeGender = value!)),
            if (officialsRequired != null) _buildFieldRow('Officials Required', officialsRequired.toString(), (value) => setState(() => includeOfficialsRequired = value!)),
            if (gameFee != null) _buildFieldRow('Game Fee', '\$${double.parse(gameFee!).toStringAsFixed(2)}', (value) => setState(() => includeGameFee = value!)),
            if (hireAutomatically != null) _buildFieldRow('Hire Automatically', hireAutomatically! ? 'Yes' : 'No', (value) => setState(() => includeHireAutomatically = value!)),
            // Show Officials List for use_list method, or Selected Officials for other methods
            if (method == 'use_list' && selectedListName != null) 
              _buildFieldRow('Officials List', 'Use Saved List: $selectedListName', (value) => setState(() => includeOfficialsList = value!))
            else if (officialsDisplay != 'None' && method != 'use_list') 
              _buildFieldRow('Selected Officials', officialsDisplay, (value) => setState(() => includeSelectedOfficials = value!)),
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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
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
                  label == 'Officials List' ? includeOfficialsList :
                  false,
            onChanged: onChanged,
            activeColor: efficialsYellow,
            checkColor: efficialsBlack,
            fillColor: WidgetStateProperty.resolveWith<Color>((Set<WidgetState> states) {
              if (states.contains(WidgetState.selected)) {
                return efficialsYellow;
              }
              return darkSurface;
            }),
            side: WidgetStateBorderSide.resolveWith((Set<WidgetState> states) {
              if (states.contains(WidgetState.selected)) {
                return const BorderSide(color: efficialsYellow, width: 2);
              }
              return BorderSide(color: efficialsGray.withOpacity(0.5), width: 1.5);
            }),
          ),
          Expanded(
            child: Text(
              '$label: $value',
              style: homeTextStyle,
            ),
          ),
        ],
      ),
    );
  }
}