import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../shared/theme.dart';
import '../games/game_template.dart';
import '../../shared/services/repositories/official_repository.dart';
import '../../shared/services/repositories/user_repository.dart';
import '../../shared/services/repositories/list_repository.dart';
import '../../shared/services/user_session_service.dart';

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

  late final OfficialRepository _officialRepository;
  late final UserRepository _userRepository;
  late final ListRepository _listRepository;
  int? _currentUserId;

  @override
  void initState() {
    super.initState();
    _officialRepository = OfficialRepository();
    _userRepository = UserRepository();
    _listRepository = ListRepository();
    _initializeUser();
  }

  Future<void> _initializeUser() async {
    _currentUserId = await UserSessionService.instance.getCurrentUserId();
    if (_currentUserId != null) {
      await _loadDefaultChoice();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    template = args['template'] as GameTemplate?; // Extract the template


    // Check for template with crew selection first
    if (template != null &&
        template!.method == 'hire_crew' &&
        template!.selectedCrews != null &&
        template!.selectedCrews!.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (mounted) {
          Navigator.pushReplacementNamed(
            context,
            '/review_game_info',
            arguments: <String, dynamic>{
              ...args,
              'method': 'hire_crew',
              'selectedCrews': template!.selectedCrews,
              'selectedCrew':
                  template!.selectedCrews!.first, // Single crew selection
              'template': template,
              'fromScheduleDetails':
                  args['fromScheduleDetails'] ?? false, // Add flag
              'scheduleId': args['scheduleId'], // Add scheduleId
            },
          );
        }
      });
    }
    // If the template includes an officials list, pre-fill the selection and navigate
    else if (template != null &&
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
    if (_currentUserId == null) return [];

    try {
      return await _officialRepository.getOfficialsFromList(
          listName, _currentUserId!);
    } catch (e) {
      // Handle database errors
      return [];
    }
  }

  Future<void> _loadDefaultChoice() async {
    if (_currentUserId == null) return;

    try {
      final defaultChoice = await _userRepository.getBoolSetting(
          _currentUserId!, 'defaultChoice');
      final defaultMethod =
          await _userRepository.getSetting(_currentUserId!, 'defaultMethod');

      setState(() {
        _defaultChoice = defaultChoice;
        _defaultMethod = defaultMethod;
      });
    } catch (e) {
      // Handle database errors
      setState(() {
        _defaultChoice = false;
        _defaultMethod = null;
      });
    }
  }

  Future<void> _saveDefaultChoice(String method) async {
    if (_currentUserId == null) return;

    try {
      await _userRepository.setBoolSetting(
          _currentUserId!, 'defaultChoice', _defaultChoice);
      if (_defaultChoice) {
        await _userRepository.setSetting(
            _currentUserId!, 'defaultMethod', method);
      } else {
        await _userRepository.deleteSetting(_currentUserId!, 'defaultMethod');
      }
    } catch (e) {
      // Handle database errors
    }
  }

  Future<int> _getAvailableListsCount() async {
    if (_currentUserId == null) return 0;

    try {
      return await _officialRepository.getAvailableListsCount(_currentUserId!);
    } catch (e) {
      // Handle database errors
      return 0;
    }
  }

  Future<int> _getBaseballListsCount() async {
    if (_currentUserId == null) return 0;

    try {
      return await _officialRepository.getBaseballListsCount(_currentUserId!);
    } catch (e) {
      // Handle database errors
      return 0;
    }
  }

  Future<int> _getListsCountBySport(String sport) async {
    if (_currentUserId == null) return 0;

    try {
      final lists = await _listRepository.getUserLists(_currentUserId!);
      return lists.where((list) => list['sport_name'] == sport).length;
    } catch (e) {
      // Handle database errors
      return 0;
    }
  }

  void _showDifferenceDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: darkSurface,
        title: const Text('Selection Methods',
            style: TextStyle(
                color: efficialsYellow,
                fontSize: 20,
                fontWeight: FontWeight.bold)),
        content: const Text(
            '• Multiple Lists: Combine and filter across multiple saved lists\n\n• Single List: Select all officials from one saved list\n\n• Hire a Crew: Select an entire pre-formed crew',
            style: TextStyle(color: Colors.white)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child:
                const Text('Close', style: TextStyle(color: efficialsYellow)),
          ),
        ],
      ),
    );
  }

  void _showInsufficientListsDialog() {
    final args =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    final sport = args['sport'] as String? ?? 'Baseball';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: darkSurface,
        title: const Text('Insufficient Lists',
            style: TextStyle(
                color: efficialsYellow,
                fontSize: 20,
                fontWeight: FontWeight.bold)),
        content: const Text(
            'The Multiple Lists method requires at least two lists of officials. Would you like to create a new list?',
            style: TextStyle(color: Colors.white)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child:
                const Text('Cancel', style: TextStyle(color: efficialsYellow)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/name_list', arguments: {
                'sport': sport,
                'fromGameCreation': true,
                ...args, // Pass through all game creation context
              }).then((result) {
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
          final currentSportListsCount = await _getListsCountBySport(sport);
          if (currentSportListsCount < 2) {
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
        } else if (_defaultMethod == 'hire_crew') {
          Navigator.pushNamed(
            context,
            '/select_crew',
            arguments: <String, dynamic>{
              ...args,
              'sport': sport,
              'listName': listName,
              'listId': listId,
              'method': 'hire_crew',
              'locationData': args['locationData'],
              'isAwayGame': args['isAwayGame'] ?? false,
              'template': template,
              'fromScheduleDetails': args['fromScheduleDetails'] ?? false,
              'scheduleId': args['scheduleId'],
            },
          );
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
              'fromTemplateCreation':
                  template != null, // Add template creation flag
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
          child: SingleChildScrollView(
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
                          onPressed: () async {
                            final currentSportListsCount =
                                await _getListsCountBySport(sport);
                            if (currentSportListsCount < 2) {
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
                                    'scheduleId':
                                        args['scheduleId'], // Add scheduleId
                                  },
                                );
                              }
                            }
                          },
                          style: elevatedButtonStyle(
                            padding: const EdgeInsets.symmetric(
                                vertical: 15, horizontal: 32),
                          ),
                          child: const Text('Multiple Lists',
                              style: signInButtonTextStyle),
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
                                    args['fromScheduleDetails'] ??
                                        false, // Add flag
                                'scheduleId':
                                    args['scheduleId'], // Add scheduleId
                                'fromTemplateCreation': template !=
                                    null, // Add template creation flag
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
                            padding: const EdgeInsets.symmetric(
                                vertical: 15, horizontal: 32),
                          ),
                          child: const Text('Single List',
                              style: signInButtonTextStyle),
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: 200,
                        child: ElevatedButton(
                          onPressed: () {
                            _saveDefaultChoice('hire_crew');
                            Navigator.pushNamed(
                              context,
                              '/select_crew',
                              arguments: <String, dynamic>{
                                ...args,
                                'sport': sport,
                                'listName': listName,
                                'listId': listId,
                                'method': 'hire_crew',
                                'locationData': args['locationData'],
                                'isAwayGame': args['isAwayGame'] ?? false,
                                'template': template,
                                'fromScheduleDetails':
                                    args['fromScheduleDetails'] ?? false,
                                'scheduleId': args['scheduleId'],
                              },
                            );
                          },
                          style: elevatedButtonStyle(
                            padding: const EdgeInsets.symmetric(
                                vertical: 15, horizontal: 32),
                          ),
                          child: const Text('Hire a Crew',
                              style: signInButtonTextStyle),
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
      ),
    );
  }
}
