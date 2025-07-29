import 'package:flutter/material.dart';
import '../../shared/theme.dart';
import 'game_template.dart'; // Import the GameTemplate model

class EditGameInfoScreen extends StatefulWidget {
  const EditGameInfoScreen({super.key});

  @override
  _EditGameInfoScreenState createState() => _EditGameInfoScreenState();
}

class _EditGameInfoScreenState extends State<EditGameInfoScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _isAwayGame = false;
  GameTemplate? template; // Store the template as a GameTemplate object
  bool _isInitialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      final args =
          ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
      if (args != null) {
        _isAwayGame = args['isAway'] as bool? ?? false;

        // Convert args['template'] to GameTemplate if necessary
        template = args['template'] != null
            ? (args['template'] is GameTemplate
                ? args['template'] as GameTemplate?
                : GameTemplate.fromJson(
                    args['template'] as Map<String, dynamic>))
            : null;

      }
      _isInitialized = true;
    }
  }

  void _handleEditOfficials(Map<String, dynamic> args) {
    final method = args['method'] as String? ?? 'standard';
    
    // Safely convert selectedOfficials from List<dynamic> to List<Map<String, dynamic>>
    List<Map<String, dynamic>> selectedOfficials = [];
    if (args['selectedOfficials'] != null) {
      final officialsRaw = args['selectedOfficials'] as List<dynamic>;
      selectedOfficials = officialsRaw.map((official) {
        if (official is Map<String, dynamic>) {
          return official;
        } else if (official is Map) {
          return Map<String, dynamic>.from(official);
        }
        return <String, dynamic>{'name': 'Unknown Official'};
      }).toList();
    }

    String route;
    Map<String, dynamic> routeArgs = {
      ...args,
      'isEdit': true,
      'isFromGameInfo': args['isFromGameInfo'] ?? false,
      'template': template, // Pass the GameTemplate object
    };

    switch (method) {
      case 'advanced':
        route = '/advanced_officials_selection';
        // Safely convert selectedLists from List<dynamic> to List<Map<String, dynamic>>
        List<Map<String, dynamic>> selectedLists = [];
        if (args['selectedLists'] != null) {
          final listsRaw = args['selectedLists'] as List<dynamic>;
          selectedLists = listsRaw.map((list) {
            if (list is Map<String, dynamic>) {
              return list;
            } else if (list is Map) {
              return Map<String, dynamic>.from(list);
            }
            return <String, dynamic>{'name': 'Unknown List'};
          }).toList();
        }
        routeArgs['selectedLists'] = selectedLists;
        break;
      case 'use_list':
        route = '/lists_of_officials';
        routeArgs['fromGameCreation'] = true;
        break;
      case 'standard':
      default:
        route = '/populate_roster';
        routeArgs['selectedOfficials'] = selectedOfficials;
        routeArgs['method'] = 'standard';
        break;
    }

    Navigator.pushNamed(context, route, arguments: routeArgs).then((result) {
      if (result != null) {
        final updatedArgs = result as Map<String, dynamic>;
        final finalArgs = {
          ...updatedArgs,
          'isEdit': true,
          'isFromGameInfo': args['isFromGameInfo'] ?? false,
          'template': template, // Pass the GameTemplate object
        };
        
        // Always navigate to review screen after updating officials
        // This is consistent with other edit buttons (Location, Date/Time, etc.)
        Navigator.pushReplacementNamed(
          context,
          '/review_game_info',
          arguments: finalArgs,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final args =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    // Safely access fields with defaults, handling different types
    final scheduleName = args['scheduleName'] as String? ?? 'Unnamed Schedule';
    final sport = args['sport'] as String? ?? 'Unknown Sport';
    final location = args['location'] as String? ?? 'Unknown Location';
    final date = args['date'] != null
        ? (args['date'] is String
            ? DateTime.parse(args['date'] as String)
            : args['date'] as DateTime)
        : DateTime.now();
    final time = args['time'] != null
        ? (args['time'] is String
            ? () {
                final timeParts = (args['time'] as String).split(':');
                return TimeOfDay(
                    hour: int.parse(timeParts[0]),
                    minute: int.parse(timeParts[1]));
              }()
            : args['time'] as TimeOfDay)
        : const TimeOfDay(hour: 12, minute: 0);
    final levelOfCompetition =
        args['levelOfCompetition'] as String? ?? 'Not set';
    final gender = args['gender'] as String? ?? 'Not set';
    // Handle officialsRequired as either String or int
    final officialsRequired = args['officialsRequired'] != null
        ? args['officialsRequired'].toString()
        : '0';
    final gameFee =
        args['gameFee'] != null ? args['gameFee'].toString() : 'Not set';
    final hireAutomatically = args['hireAutomatically'] as bool? ?? false;
    final selectedOfficials = (args['selectedOfficials'] as List<dynamic>?)
            ?.map((e) => Map<String, dynamic>.from(e as Map))
            .toList() ??
        [];

    return Scaffold(
      key: _scaffoldKey,
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
                'Edit Game Info',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: efficialsYellow,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              Expanded(
                child: Container(
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
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        const SizedBox(height: 20),
                        SizedBox(
                          width: 300,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.pushNamed(context, '/choose_location',
                                  arguments: {
                                    ...args,
                                    'isEdit': true,
                                    'isFromGameInfo':
                                        args['isFromGameInfo'] ?? false,
                                    'template':
                                        template, // Pass the GameTemplate object
                                    // Ensure we preserve all existing args
                                    'opponent': args['opponent'] ?? '',
                                    'levelOfCompetition':
                                        args['levelOfCompetition'],
                                    'gender': args['gender'],
                                    'officialsRequired':
                                        args['officialsRequired'],
                                    'gameFee': args['gameFee'],
                                    'hireAutomatically':
                                        args['hireAutomatically'],
                                    'selectedOfficials':
                                        args['selectedOfficials'],
                                    'method': args['method'],
                                    'selectedListName':
                                        args['selectedListName'],
                                    'selectedLists': args['selectedLists'],
                                  }).then((result) {
                                if (result != null) {
                                  final updatedArgs =
                                      result as Map<String, dynamic>;
                                  Navigator.pushReplacementNamed(
                                    context,
                                    '/review_game_info',
                                    arguments: {
                                      ...updatedArgs,
                                      'isEdit': true,
                                      'isFromGameInfo':
                                          args['isFromGameInfo'] ?? false,
                                      'template':
                                          template, // Pass the GameTemplate object
                                    },
                                  );
                                }
                              });
                            },
                            style: elevatedButtonStyle().copyWith(
                              minimumSize:
                                  const WidgetStatePropertyAll(Size(300, 60)),
                              padding: const WidgetStatePropertyAll(
                                  EdgeInsets.symmetric(
                                      vertical: 10, horizontal: 20)),
                            ),
                            child: const Text(
                              'Location',
                              style: signInButtonTextStyle,
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: 300,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.pushNamed(context, '/date_time',
                                  arguments: {
                                    ...args,
                                    'isEdit': true,
                                    'isFromGameInfo':
                                        args['isFromGameInfo'] ?? false,
                                    'template':
                                        template, // Pass the GameTemplate object
                                  }).then((result) {
                                if (result != null) {
                                  final updatedArgs =
                                      result as Map<String, dynamic>;
                                  Navigator.pushReplacementNamed(
                                    context,
                                    '/review_game_info',
                                    arguments: {
                                      ...updatedArgs,
                                      'isEdit': true,
                                      'isFromGameInfo':
                                          args['isFromGameInfo'] ?? false,
                                      'template':
                                          template, // Pass the GameTemplate object
                                    },
                                  );
                                }
                              });
                            },
                            style: elevatedButtonStyle().copyWith(
                              minimumSize:
                                  const WidgetStatePropertyAll(Size(300, 60)),
                              padding: const WidgetStatePropertyAll(
                                  EdgeInsets.symmetric(
                                      vertical: 10, horizontal: 20)),
                            ),
                            child: const Text(
                              'Date/Time',
                              style: signInButtonTextStyle,
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: 300,
                          child: ElevatedButton(
                            onPressed: () {
                              // Check if this is a coach flow by checking for teamName
                              final isCoach = args['teamName'] != null;
                              final route = isCoach ? '/additional_game_info_condensed' : '/additional_game_info';
                              
                              Navigator.pushNamed(
                                  context, route,
                                  arguments: {
                                    ...args,
                                    'isEdit': true,
                                    'isFromGameInfo':
                                        args['isFromGameInfo'] ?? false,
                                    'template':
                                        template, // Pass the GameTemplate object
                                  }).then((result) {
                                if (result != null) {
                                  final updatedArgs =
                                      result as Map<String, dynamic>;
                                  Navigator.pushReplacementNamed(
                                    context,
                                    '/review_game_info',
                                    arguments: {
                                      ...updatedArgs,
                                      'isEdit': true,
                                      'isFromGameInfo':
                                          args['isFromGameInfo'] ?? false,
                                      'template':
                                          template, // Pass the GameTemplate object
                                    },
                                  );
                                }
                              });
                            },
                            style: elevatedButtonStyle().copyWith(
                              minimumSize:
                                  const WidgetStatePropertyAll(Size(300, 60)),
                              padding: const WidgetStatePropertyAll(
                                  EdgeInsets.symmetric(
                                      vertical: 10, horizontal: 20)),
                            ),
                            child: const Text(
                              'Additional Game Info',
                              style: signInButtonTextStyle,
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: 300,
                          child: ElevatedButton(
                            onPressed: _isAwayGame
                                ? null // Disable for away games
                                : () {
                                    Navigator.pushNamed(
                                        context, '/select_officials',
                                        arguments: {
                                          ...args,
                                          'isEdit': true,
                                          'isFromGameInfo':
                                              args['isFromGameInfo'] ?? false,
                                          'template':
                                              template, // Pass the GameTemplate object
                                        }).then((result) {
                                      if (result != null) {
                                        final updatedArgs =
                                            result as Map<String, dynamic>;
                                        Navigator.pushReplacementNamed(
                                          context,
                                          '/review_game_info',
                                          arguments: {
                                            ...updatedArgs,
                                            'isEdit': true,
                                            'isFromGameInfo':
                                                args['isFromGameInfo'] ?? false,
                                            'template':
                                                template, // Pass the GameTemplate object
                                          },
                                        );
                                      }
                                    });
                                  },
                            style: elevatedButtonStyle().copyWith(
                              minimumSize:
                                  const WidgetStatePropertyAll(Size(300, 60)),
                              padding: const WidgetStatePropertyAll(
                                  EdgeInsets.symmetric(
                                      vertical: 10, horizontal: 20)),
                            ),
                            child: const Text(
                              'Selection Method',
                              style: signInButtonTextStyle,
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: 300,
                          child: ElevatedButton(
                            onPressed: _isAwayGame
                                ? null // Disable for away games
                                : () => _handleEditOfficials(args),
                            style: elevatedButtonStyle().copyWith(
                              minimumSize:
                                  const WidgetStatePropertyAll(Size(300, 60)),
                              padding: const WidgetStatePropertyAll(
                                  EdgeInsets.symmetric(
                                      vertical: 10, horizontal: 20)),
                            ),
                            child: const Text(
                              'Selected Officials',
                              style: signInButtonTextStyle,
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
