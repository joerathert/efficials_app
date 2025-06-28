import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'theme.dart';
import 'game_template.dart';

class CreateGameTemplateScreen extends StatefulWidget {
  const CreateGameTemplateScreen({super.key});

  @override
  State<CreateGameTemplateScreen> createState() =>
      _CreateGameTemplateScreenState();
}

class _CreateGameTemplateScreenState extends State<CreateGameTemplateScreen> {
  final _nameController = TextEditingController();
  final _gameFeeController = TextEditingController();
  String? sport;
  TimeOfDay? selectedTime;
  String? scheduleName;
  String? levelOfCompetition;
  String? gender;
  int? officialsRequired;
  bool hireAutomatically = false;
  String? selectedListName;
  String? location; // Selected location name
  bool isEditing = false;
  GameTemplate? existingTemplate;
  List<Map<String, dynamic>> locations = []; // List of saved locations
  bool isLoadingLocations = true; // Track location loading

  // Toggle states for including fields in the template
  bool includeSport = true;
  bool includeTime = true;
  bool includeLevelOfCompetition = true;
  bool includeGender = true;
  bool includeOfficialsRequired = true;
  bool includeGameFee = true;
  bool includeHireAutomatically = true;
  bool includeOfficialsList = true;
  bool includeLocation = true;

  // Options for dropdowns
  final List<String> competitionLevels = [
    'Grade School',
    'Middle School',
    'Underclass',
    'JV',
    'Varsity',
    'College',
    'Adult'
  ];
  final List<String> youthGenders = ['Boys', 'Girls', 'Co-ed'];
  final List<String> adultGenders = ['Men', 'Women', 'Co-ed'];
  final List<int> officialsOptions = [1, 2, 3, 4, 5, 6, 7, 8, 9];
  List<String> currentGenders = ['Boys', 'Girls', 'Co-ed'];

  @override
  void initState() {
    super.initState();
    _fetchLocations(); // Fetch locations at initialization
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args =
          ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
      print('CreateGameTemplateScreen - Received arguments: $args');
      if (args != null) {
        setState(() {
          scheduleName = args['scheduleName'] as String?;
          sport = args['sport'] as String?;
          existingTemplate = args['template'] as GameTemplate?;

          // Handle location from args or template
          if (args['locationData'] != null) {
            final locationData = args['locationData'] as Map<String, dynamic>;
            location = locationData['name'] as String? ?? '';
          } else {
            location = args['location'] as String?;
          }

          print(
              'CreateGameTemplateScreen - Existing template: ${existingTemplate?.toJson()}');
          if (existingTemplate != null) {
            isEditing = true;
            _nameController.text = existingTemplate!.name ?? '';
            sport = existingTemplate!.sport ?? sport;
            selectedTime = existingTemplate!.time;
            levelOfCompetition = existingTemplate!.levelOfCompetition;
            gender = existingTemplate!.gender;
            officialsRequired = existingTemplate!.officialsRequired;
            _gameFeeController.text = existingTemplate!.gameFee ?? '';
            hireAutomatically = existingTemplate!.hireAutomatically ?? false;
            selectedListName = existingTemplate!.officialsListName;
            location = existingTemplate!.location ?? location;
            includeSport = existingTemplate!.includeSport;
            includeTime = existingTemplate!.includeTime;
            includeLevelOfCompetition =
                existingTemplate!.includeLevelOfCompetition;
            includeGender = existingTemplate!.includeGender;
            includeOfficialsRequired =
                existingTemplate!.includeOfficialsRequired;
            includeGameFee = existingTemplate!.includeGameFee;
            includeHireAutomatically =
                existingTemplate!.includeHireAutomatically;
            includeOfficialsList = existingTemplate!.includeOfficialsList;
            includeLocation = existingTemplate!.includeLocation;
          } else {
            // Pre-fill fields from gameData
            levelOfCompetition = args['levelOfCompetition'] as String?;
            gender = args['gender'] as String?;
            officialsRequired = args['officialsRequired'] as int?;
            _gameFeeController.text = args['gameFee']?.toString() ?? '';
            hireAutomatically = args['hireAutomatically'] as bool? ?? false;
            selectedListName = args['selectedListName'] as String?;
            if (args['time'] != null) {
              if (args['time'] is TimeOfDay) {
                selectedTime = args['time'] as TimeOfDay;
              } else if (args['time'] is String) {
                final parts = (args['time'] as String).split(':');
                if (parts.length == 2) {
                  selectedTime = TimeOfDay(
                    hour: int.parse(parts[0]),
                    minute: int.parse(parts[1]),
                  );
                }
              }
            }
          }

          print('CreateGameTemplateScreen - Received sport: $sport');
          print('CreateGameTemplateScreen - Location: $location');
          print(
              'CreateGameTemplateScreen - Include Location: $includeLocation');
          if (sport == null) {
            print(
                'Warning: Sport is null. Check navigation arguments from ScheduleDetailsScreen.');
            sport = 'Unknown';
          }
          _updateCurrentGenders();
        });
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _gameFeeController.dispose();
    super.dispose();
  }

  Future<void> _fetchLocations() async {
    final prefs = await SharedPreferences.getInstance();
    final String? locationsJson = prefs.getString('saved_locations');
    setState(() {
      locations = [];
      try {
        if (locationsJson != null && locationsJson.isNotEmpty) {
          locations.addAll(
              List<Map<String, dynamic>>.from(jsonDecode(locationsJson)));
        }
      } catch (e) {
        print('Error fetching locations: $e');
      }
      locations
          .add({'name': '+ Create new location', 'id': 0}); // Add create option
      isLoadingLocations = false;
      print('CreateGameTemplateScreen - Locations loaded: $locations');
    });
  }

  Future<void> _saveLocations() async {
    final prefs = await SharedPreferences.getInstance();
    final locationsToSave = locations.where((loc) => loc['id'] != 0).toList();
    await prefs.setString('saved_locations', jsonEncode(locationsToSave));
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: selectedTime ?? TimeOfDay.now(),
    );
    if (picked != null && picked != selectedTime) {
      setState(() {
        selectedTime = picked;
        includeTime = true;
      });
    }
  }

  void _updateCurrentGenders() {
    if (levelOfCompetition == null) {
      currentGenders = youthGenders;
    } else {
      currentGenders =
          (levelOfCompetition == 'College' || levelOfCompetition == 'Adult')
              ? adultGenders
              : youthGenders;
    }
    if (gender != null && !currentGenders.contains(gender)) {
      gender = null;
    }
  }

  Future<void> _selectOfficialsList() async {
    final result = await Navigator.pushNamed(
      context,
      '/lists_of_officials',
      arguments: {
        'sport': sport,
        'fromGameCreation': true,
      },
    );
    if (result != null && result is Map<String, dynamic>) {
      setState(() {
        selectedListName = result['selectedListName'] as String?;
      });
    }
  }

  Future<void> _saveTemplate() async {
    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a template name!')),
      );
      return;
    }
    if (includeGameFee &&
        (_gameFeeController.text.isEmpty ||
            !RegExp(r'^\d+(\.\d+)?$').hasMatch(_gameFeeController.text))) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please enter a valid game fee (e.g., 50 or 50.00)')),
      );
      return;
    }
    if (includeGameFee) {
      final fee = double.parse(_gameFeeController.text.trim());
      if (fee < 1 || fee > 99999) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Game fee must be between 1 and 99,999')),
        );
        return;
      }
    }

    final newTemplate = GameTemplate(
      id: isEditing
          ? existingTemplate!.id
          : DateTime.now().millisecondsSinceEpoch.toString(),
      name: _nameController.text.trim(),
      sport: sport,
      includeSport: true,
      time: selectedTime,
      includeTime: includeTime,
      levelOfCompetition: levelOfCompetition,
      includeLevelOfCompetition: includeLevelOfCompetition,
      gender: gender,
      includeGender: includeGender,
      officialsRequired: officialsRequired,
      includeOfficialsRequired: includeOfficialsRequired,
      gameFee: includeGameFee ? _gameFeeController.text.trim() : null,
      includeGameFee: includeGameFee,
      hireAutomatically: hireAutomatically,
      includeHireAutomatically: includeHireAutomatically,
      officialsListName: selectedListName,
      includeOfficialsList: includeOfficialsList,
      method: selectedListName != null ? 'use_list' : null,
      location:
          includeLocation ? location : null, // Use dropdown-selected location
      includeLocation: includeLocation,
    );

    final prefs = await SharedPreferences.getInstance();
    final String? templatesJson = prefs.getString('game_templates');
    List<GameTemplate> templates = [];
    if (templatesJson != null && templatesJson.isNotEmpty) {
      final List<dynamic> decoded = jsonDecode(templatesJson);
      templates = decoded.map((json) => GameTemplate.fromJson(json)).toList();
    }
    
    if (isEditing) {
      // Find and update the existing template
      final index = templates.indexWhere((t) => t.id == existingTemplate!.id);
      if (index != -1) {
        templates[index] = newTemplate;
      }
    } else {
      // Add new template
      templates.add(newTemplate);
    }
    
    await prefs.setString('game_templates',
        jsonEncode(templates.map((t) => t.toJson()).toList()));

    Navigator.pop(context, newTemplate);
  }

  Widget _buildFieldRow(String label, String value, Function(bool?)? onChanged,
      {bool isEditable = true, bool isCheckboxEnabled = true}) {
    bool checkboxValue;
    switch (label) {
      case 'Sport':
        checkboxValue = includeSport;
        break;
      case 'Time':
        checkboxValue = includeTime;
        break;
      case 'Level of Competition':
        checkboxValue = includeLevelOfCompetition;
        break;
      case 'Gender':
        checkboxValue = includeGender;
        break;
      case 'Officials Required':
        checkboxValue = includeOfficialsRequired;
        break;
      case 'Game Fee':
        checkboxValue = includeGameFee;
        break;
      case 'Hire Automatically':
        checkboxValue = includeHireAutomatically;
        break;
      case 'Selected Officials':
        checkboxValue = includeOfficialsList;
        break;
      case 'Location':
        checkboxValue = includeLocation;
        break;
      default:
        checkboxValue = false;
    }

    return Row(
      children: [
        Checkbox(
          value: checkboxValue,
          onChanged: isCheckboxEnabled ? onChanged : null,
          activeColor: efficialsBlue,
          checkColor: Colors.white,
          fillColor: MaterialStateProperty.resolveWith<Color?>((states) {
            if (!isCheckboxEnabled) {
              return Colors.grey;
            }
            return states.contains(MaterialState.selected)
                ? efficialsBlue
                : Colors.grey;
          }),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Text(
              '$label: $value',
              style: TextStyle(
                fontSize: 16,
                color: isEditable ? Colors.black : Colors.grey,
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    print(
        'CreateGameTemplateScreen - Building UI with Location: $location, Include Location: $includeLocation');
    return Scaffold(
      appBar: AppBar(
        backgroundColor: efficialsBlue,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, size: 36, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(isEditing ? 'Edit Game Template' : 'Create Game Template',
            style: appBarTextStyle),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _nameController,
              decoration: textFieldDecoration('Template Name'),
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 20),
            const Text('Select fields to include in the template:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            _buildFieldRow('Sport', sport ?? 'Unknown', (value) {},
                isEditable: false, isCheckboxEnabled: false),
            const SizedBox(height: 10),
            Row(
              children: [
                Checkbox(
                  value: includeTime,
                  onChanged: (value) => setState(() => includeTime = value!),
                  activeColor: efficialsBlue,
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => _selectTime(context),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            selectedTime == null
                                ? 'Time: Select Time'
                                : 'Time: ${selectedTime!.format(context)}',
                            style: const TextStyle(fontSize: 16),
                          ),
                          const Icon(Icons.access_time),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Checkbox(
                  value: includeLocation,
                  onChanged: (value) =>
                      setState(() => includeLocation = value!),
                  activeColor: efficialsBlue,
                ),
                Expanded(
                  child: isLoadingLocations
                      ? const CircularProgressIndicator()
                      : DropdownButtonFormField<String>(
                          decoration: textFieldDecoration('Location'),
                          value: location != null &&
                                  locations
                                      .any((loc) => loc['name'] == location)
                              ? location
                              : null,
                          hint: locations.isEmpty ||
                                  locations.length ==
                                      1 // Only "+ Create new location"
                              ? const Text('No locations available',
                                  style: TextStyle(color: Colors.grey))
                              : const Text('Select location',
                                  style: TextStyle(color: Colors.grey)),
                          onChanged: (newValue) {
                            if (newValue == null) return;
                            setState(() {
                              if (newValue == '+ Create new location') {
                                Navigator.pushNamed(
                                        context, '/add_new_location')
                                    .then((result) {
                                  if (result != null) {
                                    final newLoc =
                                        result as Map<String, dynamic>;
                                    setState(() {
                                      locations.insert(locations.length - 1, {
                                        'name': newLoc['name'],
                                        'address': newLoc['address'],
                                        'city': newLoc['city'],
                                        'state': newLoc['state'],
                                        'zip': newLoc['zip'],
                                        'id': newLoc['id'] ??
                                            DateTime.now()
                                                .millisecondsSinceEpoch,
                                      });
                                      location = newLoc['name'];
                                      _saveLocations();
                                    });
                                  }
                                });
                              } else {
                                location = newValue;
                              }
                            });
                          },
                          items: locations.map((loc) {
                            return DropdownMenuItem(
                              value: loc['name'] as String,
                              child: Text(loc['name'] as String),
                            );
                          }).toList(),
                        ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Checkbox(
                  value: includeLevelOfCompetition,
                  onChanged: (value) =>
                      setState(() => includeLevelOfCompetition = value!),
                  activeColor: efficialsBlue,
                ),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    decoration: textFieldDecoration('Level of Competition'),
                    value: levelOfCompetition,
                    hint: const Text('Level of Competition',
                        style: TextStyle(fontSize: 16)),
                    onChanged: (value) {
                      setState(() {
                        levelOfCompetition = value;
                        _updateCurrentGenders();
                      });
                    },
                    items: competitionLevels.map((level) {
                      return DropdownMenuItem(
                        value: level,
                        child:
                            Text(level, style: const TextStyle(fontSize: 16)),
                      );
                    }).toList(),
                    style: const TextStyle(fontSize: 16, color: Colors.black),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Checkbox(
                  value: includeGender,
                  onChanged: (value) => setState(() => includeGender = value!),
                  activeColor: efficialsBlue,
                ),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    decoration: textFieldDecoration('Gender'),
                    value: gender,
                    hint: const Text('Gender', style: TextStyle(fontSize: 16)),
                    onChanged: (value) => setState(() => gender = value),
                    items: currentGenders.map((g) {
                      return DropdownMenuItem(
                        value: g,
                        child: Text(g, style: const TextStyle(fontSize: 16)),
                      );
                    }).toList(),
                    style: const TextStyle(fontSize: 16, color: Colors.black),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Checkbox(
                  value: includeOfficialsRequired,
                  onChanged: (value) =>
                      setState(() => includeOfficialsRequired = value!),
                  activeColor: efficialsBlue,
                ),
                Expanded(
                  child: DropdownButtonFormField<int>(
                    decoration: textFieldDecoration('# of Officials Required'),
                    value: officialsRequired,
                    hint: const Text('# of Officials Required',
                        style: TextStyle(fontSize: 16)),
                    onChanged: (value) =>
                        setState(() => officialsRequired = value),
                    items: officialsOptions.map((num) {
                      return DropdownMenuItem(
                        value: num,
                        child: Text(num.toString(),
                            style: const TextStyle(fontSize: 16)),
                      );
                    }).toList(),
                    style: const TextStyle(fontSize: 16, color: Colors.black),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Checkbox(
                  value: includeGameFee,
                  onChanged: (value) => setState(() => includeGameFee = value!),
                  activeColor: efficialsBlue,
                ),
                Expanded(
                  child: TextField(
                    controller: _gameFeeController,
                    decoration:
                        textFieldDecoration('Game Fee per Official').copyWith(
                      prefixText: '\$',
                      hintText: 'Enter fee (e.g., 50 or 50.00)',
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                      LengthLimitingTextInputFormatter(7),
                    ],
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Checkbox(
                  value: includeHireAutomatically,
                  onChanged: (value) =>
                      setState(() => includeHireAutomatically = value!),
                  activeColor: efficialsBlue,
                ),
                Expanded(
                  child: Row(
                    children: [
                      const Text('Hire Automatically: ',
                          style: TextStyle(fontSize: 16)),
                      Switch(
                        value: hireAutomatically,
                        onChanged: (value) =>
                            setState(() => hireAutomatically = value),
                        activeColor: efficialsBlue,
                      ),
                      Text(hireAutomatically ? 'Yes' : 'No',
                          style: const TextStyle(fontSize: 16)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Checkbox(
                  value: includeOfficialsList,
                  onChanged: (value) =>
                      setState(() => includeOfficialsList = value!),
                  activeColor: efficialsBlue,
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: _selectOfficialsList,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            selectedListName == null
                                ? 'Selected Officials: List Used'
                                : 'Selected Officials: List Used ($selectedListName)',
                            style: const TextStyle(fontSize: 16),
                          ),
                          const Icon(Icons.list),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Center(
              child: ElevatedButton(
                onPressed: _saveTemplate,
                style: elevatedButtonStyle(),
                child:
                    const Text('Save Template', style: signInButtonTextStyle),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
