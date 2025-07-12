import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../shared/theme.dart';
import '../games/game_template.dart'; // Import the GameTemplate model

class SelectOfficialsScreen extends StatefulWidget {
  const SelectOfficialsScreen({super.key});

  @override
  State<SelectOfficialsScreen> createState() => _SelectOfficialsScreenState();
}

class _SelectOfficialsScreenState extends State<SelectOfficialsScreen> {
  bool _defaultChoice = false;
  String? _defaultMethod;
  GameTemplate? template; // Store the selected template
  List<Map<String, dynamic>> _selectedOfficials =
      []; // Store the selected officials

  @override
  void initState() {
    super.initState();
    _loadDefaultChoice();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    template = args['template'] as GameTemplate?; // Extract the template

    // If the template includes an officials list, pre-fill the selection and navigate
    if (template != null &&
        template!.includeOfficialsList &&
        template!.officialsListName != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        final officials =
            await _fetchOfficialsFromList(template!.officialsListName!);
        setState(() {
          _selectedOfficials = officials;
        });

        if (mounted) {
          Navigator.pushReplacementNamed(
            context,
            '/review_game_info',
            arguments: <String, dynamic>{
              ...args,
              'method': 'use_list',
              'selectedListName': template!.officialsListName,
              'selectedOfficials': _selectedOfficials,
              'template': template,
              'fromScheduleDetails':
                  args['fromScheduleDetails'] ?? false, // Add flag
              'scheduleId': args['scheduleId'], // Add scheduleId
            },
          );
        }
      });
    }
  }

  Future<List<Map<String, dynamic>>> _fetchOfficialsFromList(
      String listName) async {
    final prefs = await SharedPreferences.getInstance();
    final String? listsJson = prefs.getString('saved_lists');
    if (listsJson != null && listsJson.isNotEmpty) {
      try {
        final List<dynamic> lists =
            List<Map<String, dynamic>>.from(jsonDecode(listsJson));
        final selectedList = lists.firstWhere(
          (list) => list['name'] == listName,
          orElse: () => <String, dynamic>{},
        );
        if (selectedList.isNotEmpty && selectedList['officials'] != null) {
          return List<Map<String, dynamic>>.from(selectedList['officials']);
        }
      } catch (e) {
        // Handle parsing errors
      }
    }
    return [];
  }

  Future<void> _loadDefaultChoice() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _defaultChoice = prefs.getBool('defaultChoice') ?? false;
      _defaultMethod = prefs.getString('defaultMethod');
    });
  }

  Future<void> _saveDefaultChoice(String method) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('defaultChoice', _defaultChoice);
    if (_defaultChoice) {
      await prefs.setString('defaultMethod', method);
    } else {
      await prefs.remove('defaultMethod');
    }
  }

  Future<int> _getAvailableListsCount() async {
    final prefs = await SharedPreferences.getInstance();
    final String? listsJson = prefs.getString('saved_lists');
    if (listsJson != null && listsJson.isNotEmpty) {
      try {
        final List<dynamic> lists =
            List<Map<String, dynamic>>.from(jsonDecode(listsJson));
        return lists.length;
      } catch (e) {
        return 0;
      }
    }
    return 0;
  }

  void _showDifferenceDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: darkSurface,
        title: const Text('Standard vs. Advanced',
            style: TextStyle(color: efficialsYellow, fontSize: 20, fontWeight: FontWeight.bold)),
        content: const Text(
            'Standard method uses basic filters to find officials. Advanced method allows detailed customization of filters for more specific selections.',
            style: TextStyle(color: Colors.white)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close', style: TextStyle(color: efficialsYellow)),
          ),
        ],
      ),
    );
  }

  void _showInsufficientListsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: darkSurface,
        title: const Text('Insufficient Lists',
            style: TextStyle(color: efficialsYellow, fontSize: 20, fontWeight: FontWeight.bold)),
        content: const Text(
            'The Advanced method requires at least two lists of officials. Would you like to create a new list?',
            style: TextStyle(color: Colors.white)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: efficialsYellow)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/create_new_list').then((result) {
                setState(() {});
              });
            },
            child: const Text('Create List',
                style: TextStyle(color: efficialsYellow)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final args =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    final sport = args['sport'] as String? ?? 'Baseball';
    final listName = args['scheduleName'] as String? ?? 'New Roster';
    final listId =
        args['listId'] as int? ?? DateTime.now().millisecondsSinceEpoch;

    if (_defaultChoice && _defaultMethod != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (_defaultMethod == 'standard') {
          Navigator.pushNamed(
            context,
            '/populate_roster',
            arguments: <String, dynamic>{
              ...args,
              'sport': sport,
              'listName': listName,
              'listId': listId,
              'method': 'standard',
              'requiredCount': 2,
              'locationData': args['locationData'],
              'isAwayGame': args['isAwayGame'] ?? false,
              'template': template,
              'fromScheduleDetails':
                  args['fromScheduleDetails'] ?? false, // Add flag
              'scheduleId': args['scheduleId'], // Add scheduleId
            },
          );
        } else if (_defaultMethod == 'advanced') {
          final listCount = await _getAvailableListsCount();
          if (listCount < 2) {
            _showInsufficientListsDialog();
          } else {
            if (mounted) {
              // ignore: use_build_context_synchronously
              Navigator.pushNamed(
                context,
                '/advanced_officials_selection',
                arguments: <String, dynamic>{
                  ...args,
                  'sport': sport,
                  'listName': listName,
                  'listId': listId,
                  'locationData': args['locationData'],
                  'isAwayGame': args['isAwayGame'] ?? false,
                  'template': template,
                  'fromScheduleDetails':
                      args['fromScheduleDetails'] ?? false, // Add flag
                  'scheduleId': args['scheduleId'], // Add scheduleId
                },
              );
            }
          }
        } else if (_defaultMethod == 'use_list') {
          Navigator.pushNamed(
            context,
            '/lists_of_officials',
            arguments: <String, dynamic>{
              ...args,
              'fromGameCreation': true,
              'locationData': args['locationData'],
              'isAwayGame': args['isAwayGame'] ?? false,
              'template': template,
              'fromScheduleDetails':
                  args['fromScheduleDetails'] ?? false, // Add flag
              'scheduleId': args['scheduleId'], // Add scheduleId
            },
          ).then((result) {
            if (result != null) {
              Navigator.pushNamed(
                context,
                '/review_game_info',
                arguments: <String, dynamic>{
                  ...result as Map<String, dynamic>,
                  'template': template,
                  'fromScheduleDetails':
                      args['fromScheduleDetails'] ?? false, // Add flag
                  'scheduleId': args['scheduleId'], // Add scheduleId
                },
              );
            }
          });
        }
      });
    }

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
          icon: const Icon(Icons.arrow_back, color: efficialsWhite),
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
                'Select Officials',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: efficialsYellow,
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
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const Text(
                      'Choose a method for finding your officials.',
                      style: TextStyle(
                        fontSize: 16,
                        color: primaryTextColor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 30),
                    SizedBox(
                      width: 200,
                      child: ElevatedButton(
                        onPressed: () {
                          _saveDefaultChoice('standard');
                          Navigator.pushNamed(
                            context,
                            '/populate_roster',
                            arguments: <String, dynamic>{
                              ...args,
                              'sport': sport,
                              'listName': listName,
                              'listId': listId,
                              'method': 'standard',
                              'requiredCount': 2,
                              'locationData': args['locationData'],
                              'isAwayGame': args['isAwayGame'] ?? false,
                              'template': template,
                              'fromScheduleDetails':
                                  args['fromScheduleDetails'] ?? false, // Add flag
                              'scheduleId': args['scheduleId'], // Add scheduleId
                            },
                          );
                        },
                        style: elevatedButtonStyle(
                          padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 32),
                        ),
                        child: const Text('Standard', style: signInButtonTextStyle),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: 200,
                      child: ElevatedButton(
                        onPressed: () async {
                          final listCount = await _getAvailableListsCount();
                          if (listCount < 2) {
                            _showInsufficientListsDialog();
                          } else {
                            _saveDefaultChoice('advanced');
                            if (mounted) {
                              // ignore: use_build_context_synchronously
                              Navigator.pushNamed(
                                context,
                                '/advanced_officials_selection',
                                arguments: <String, dynamic>{
                                  ...args,
                                  'sport': sport,
                                  'listName': listName,
                                  'listId': listId,
                                  'locationData': args['locationData'],
                                  'isAwayGame': args['isAwayGame'] ?? false,
                                  'template': template,
                                  'fromScheduleDetails':
                                      args['fromScheduleDetails'] ??
                                          false, // Add flag
                                  'scheduleId': args['scheduleId'], // Add scheduleId
                                },
                              );
                            }
                          }
                        },
                        style: elevatedButtonStyle(
                          padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 32),
                        ),
                        child: const Text('Advanced', style: signInButtonTextStyle),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: 200,
                      child: ElevatedButton(
                        onPressed: () {
                          _saveDefaultChoice('use_list');
                          Navigator.pushNamed(
                            context,
                            '/lists_of_officials',
                            arguments: <String, dynamic>{
                              ...args,
                              'fromGameCreation': true,
                              'locationData': args['locationData'],
                              'isAwayGame': args['isAwayGame'] ?? false,
                              'template': template,
                              'fromScheduleDetails':
                                  args['fromScheduleDetails'] ?? false, // Add flag
                              'scheduleId': args['scheduleId'], // Add scheduleId
                            },
                          ).then((result) {
                            if (result != null) {
                              Navigator.pushNamed(
                                context,
                                '/review_game_info',
                                arguments: <String, dynamic>{
                                  ...result as Map<String, dynamic>,
                                  'template': template,
                                  'fromScheduleDetails':
                                      args['fromScheduleDetails'] ??
                                          false, // Add flag
                                  'scheduleId':
                                      args['scheduleId'], // Add scheduleId
                                },
                              );
                            }
                          });
                        },
                        style: elevatedButtonStyle(
                          padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 32),
                        ),
                        child: const Text('Use List', style: signInButtonTextStyle),
                      ),
                    ),
                    const SizedBox(height: 20),
                    GestureDetector(
                      onTap: _showDifferenceDialog,
                      child: const Text(
                        'What\'s the difference?',
                        style: TextStyle(
                            color: efficialsYellow,
                            decoration: TextDecoration.underline),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Checkbox(
                          value: _defaultChoice,
                          onChanged: (value) =>
                              setState(() => _defaultChoice = value ?? false),
                          activeColor: efficialsYellow,
                          checkColor: efficialsBlack,
                        ),
                        const Text('Make this my default choice',
                            style: TextStyle(color: Colors.white)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
