import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'theme.dart';
import 'game_template.dart'; // Import the GameTemplate model

class SelectOfficialsScreen extends StatefulWidget {
  const SelectOfficialsScreen({super.key});

  @override
  State<SelectOfficialsScreen> createState() => _SelectOfficialsScreenState();
}

class _SelectOfficialsScreenState extends State<SelectOfficialsScreen> {
  bool _defaultChoice = false;
  String? _defaultMethod;
  GameTemplate? template; // Store the selected template
  List<Map<String, dynamic>> _selectedOfficials = []; // Store the selected officials

  @override
  void initState() {
    super.initState();
    _loadDefaultChoice();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    template = args['template'] as GameTemplate?; // Extract the template

    // If the template includes an officials list, pre-fill the selection and navigate
    if (template != null && template!.includeOfficialsList && template!.officialsListName != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        // Fetch the officials from the specified list
        final officials = await _fetchOfficialsFromList(template!.officialsListName!);
        setState(() {
          _selectedOfficials = officials;
        });

        // Navigate to ReviewGameInfoScreen with the populated selectedOfficials
        Navigator.pushReplacementNamed(
          context,
          '/review_game_info',
          arguments: <String, dynamic>{
            ...args,
            'method': 'use_list',
            'selectedListName': template!.officialsListName,
            'selectedOfficials': _selectedOfficials,
            'template': template,
          },
        );
      });
    }
  }

  Future<List<Map<String, dynamic>>> _fetchOfficialsFromList(String listName) async {
    final prefs = await SharedPreferences.getInstance();
    final String? listsJson = prefs.getString('saved_lists');
    if (listsJson != null && listsJson.isNotEmpty) {
      try {
        final List<dynamic> lists = List<Map<String, dynamic>>.from(jsonDecode(listsJson));
        final selectedList = lists.firstWhere(
          (list) => list['name'] == listName,
          orElse: () => <String, dynamic>{},
        );
        if (selectedList.isNotEmpty && selectedList['officials'] != null) {
          return List<Map<String, dynamic>>.from(selectedList['officials']);
        }
      } catch (e) {
        print('Error fetching officials from list: $e');
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
        final List<dynamic> lists = List<Map<String, dynamic>>.from(jsonDecode(listsJson));
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
        title: const Text('Standard vs. Advanced'),
        content: const Text('Standard method uses basic filters to find officials. Advanced method allows detailed customization of filters for more specific selections.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close', style: TextStyle(color: efficialsBlue)),
          ),
        ],
      ),
    );
  }

  void _showInsufficientListsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Insufficient Lists'),
        content: const Text('The Advanced method requires at least two lists of officials. Would you like to create a new list?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: efficialsBlue)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/create_new_list').then((result) {
                setState(() {});
              });
            },
            child: const Text('Create List', style: TextStyle(color: efficialsBlue)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    final sport = args['sport'] as String? ?? 'Baseball';
    final listName = args['scheduleName'] as String? ?? 'New Roster';
    final listId = args['listId'] as int? ?? DateTime.now().millisecondsSinceEpoch;

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
              'template': template,
            },
          );
        } else if (_defaultMethod == 'advanced') {
          final listCount = await _getAvailableListsCount();
          if (listCount < 2) {
            _showInsufficientListsDialog();
          } else {
            Navigator.pushNamed(
              context,
              '/advanced_officials_selection',
              arguments: <String, dynamic>{
                ...args,
                'sport': sport,
                'listName': listName,
                'listId': listId,
                'template': template,
              },
            );
          }
        } else if (_defaultMethod == 'use_list') {
          Navigator.pushNamed(
            context,
            '/lists_of_officials',
            arguments: <String, dynamic>{
              ...args,
              'fromGameCreation': true,
              'template': template,
            },
          ).then((result) {
            if (result != null) {
              Navigator.pushNamed(
                context,
                '/review_game_info',
                arguments: <String, dynamic>{
                  ...result as Map<String, dynamic>,
                  'template': template,
                },
              );
            }
          });
        }
      });
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: efficialsBlue,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, size: 36, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Select Officials', style: appBarTextStyle),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Choose a method for finding your officials.',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 60),
                  ElevatedButton(
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
                          'template': template,
                        },
                      );
                    },
                    style: elevatedButtonStyle(),
                    child: const Text('Standard', style: signInButtonTextStyle),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () async {
                      final listCount = await _getAvailableListsCount();
                      if (listCount < 2) {
                        _showInsufficientListsDialog();
                      } else {
                        _saveDefaultChoice('advanced');
                        Navigator.pushNamed(
                          context,
                          '/advanced_officials_selection',
                          arguments: <String, dynamic>{
                            ...args,
                            'sport': sport,
                            'listName': listName,
                            'listId': listId,
                            'template': template,
                          },
                        );
                      }
                    },
                    style: elevatedButtonStyle(),
                    child: const Text('Advanced', style: signInButtonTextStyle),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      _saveDefaultChoice('use_list');
                      Navigator.pushNamed(
                        context,
                        '/lists_of_officials',
                        arguments: <String, dynamic>{
                          ...args,
                          'fromGameCreation': true,
                          'template': template,
                        },
                      ).then((result) {
                        if (result != null) {
                          Navigator.pushNamed(
                            context,
                            '/review_game_info',
                            arguments: <String, dynamic>{
                              ...result as Map<String, dynamic>,
                              'template': template,
                            },
                          );
                        }
                      });
                    },
                    style: elevatedButtonStyle(),
                    child: const Text('Use List', style: signInButtonTextStyle),
                  ),
                  const SizedBox(height: 20),
                  GestureDetector(
                    onTap: _showDifferenceDialog,
                    child: const Text(
                      'What\'s the difference?',
                      style: TextStyle(color: efficialsBlue, decoration: TextDecoration.underline),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Checkbox(
                        value: _defaultChoice,
                        onChanged: (value) => setState(() => _defaultChoice = value ?? false),
                        activeColor: efficialsBlue,
                      ),
                      const Text('Make this my default choice'),
                    ],
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