import 'package:flutter/material.dart';
import 'theme.dart';
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
      final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
      if (args != null) {
        _isAwayGame = args['isAway'] as bool? ?? false;

        // Convert args['template'] to GameTemplate if necessary
        template = args['template'] != null
            ? (args['template'] is GameTemplate
                ? args['template'] as GameTemplate?
                : GameTemplate.fromJson(args['template'] as Map<String, dynamic>))
            : null;

        print('didChangeDependencies - EditGameInfo Args: $args, Template: $template');
      }
      _isInitialized = true;
    }
  }

  void _handleEditOfficials(Map<String, dynamic> args) {
    final method = args['method'] as String? ?? 'standard';
    final selectedOfficials = args['selectedOfficials'] as List<Map<String, dynamic>>? ?? [];

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
        routeArgs['selectedLists'] = args['selectedLists'] ?? [];
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
        print('EditGameInfoScreen - Updated Args from $route: $updatedArgs');
        Navigator.pushReplacementNamed(
          context,
          '/review_game_info',
          arguments: {
            ...updatedArgs,
            'isEdit': true,
            'isFromGameInfo': args['isFromGameInfo'] ?? false,
            'template': template, // Pass the GameTemplate object
          },
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    // Safely access fields with defaults, handling different types
    final scheduleName = args['scheduleName'] as String? ?? 'Unnamed Schedule';
    final sport = args['sport'] as String? ?? 'Unknown Sport';
    final location = args['location'] as String? ?? 'Unknown Location';
    final date = args['date'] != null
        ? (args['date'] is String ? DateTime.parse(args['date'] as String) : args['date'] as DateTime)
        : DateTime.now();
    final time = args['time'] != null
        ? (args['time'] is String
            ? () {
                final timeParts = (args['time'] as String).split(':');
                return TimeOfDay(hour: int.parse(timeParts[0]), minute: int.parse(timeParts[1]));
              }()
            : args['time'] as TimeOfDay)
        : const TimeOfDay(hour: 12, minute: 0);
    final levelOfCompetition = args['levelOfCompetition'] as String? ?? 'Not set';
    final gender = args['gender'] as String? ?? 'Not set';
    // Handle officialsRequired as either String or int
    final officialsRequired = args['officialsRequired'] != null
        ? args['officialsRequired'].toString()
        : '0';
    final gameFee = args['gameFee'] != null ? args['gameFee'].toString() : 'Not set';
    final hireAutomatically = args['hireAutomatically'] as bool? ?? false;
    final selectedOfficials = args['selectedOfficials'] as List<Map<String, dynamic>>? ?? [];

    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        backgroundColor: efficialsBlack,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, size: 36, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Edit Game Info', style: appBarTextStyle),
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
                  const SizedBox(height: 20),
                  SizedBox(
                    width: 300,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pushNamed(context, '/choose_location', arguments: {
                          ...args,
                          'isEdit': true,
                          'isFromGameInfo': args['isFromGameInfo'] ?? false,
                          'template': template, // Pass the GameTemplate object
                        }).then((result) {
                          if (result != null) {
                            final updatedArgs = result as Map<String, dynamic>;
                            print('EditGameInfoScreen - Updated Args from /choose_location: $updatedArgs');
                            Navigator.pushReplacementNamed(
                              context,
                              '/review_game_info',
                              arguments: {
                                ...updatedArgs,
                                'isEdit': true,
                                'isFromGameInfo': args['isFromGameInfo'] ?? false,
                                'template': template, // Pass the GameTemplate object
                              },
                            );
                          }
                        });
                      },
                      style: elevatedButtonStyle().copyWith(
                        minimumSize: const WidgetStatePropertyAll(Size(300, 60)),
                        padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(vertical: 10, horizontal: 20)),
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
                        Navigator.pushNamed(context, '/date_time', arguments: {
                          ...args,
                          'isEdit': true,
                          'isFromGameInfo': args['isFromGameInfo'] ?? false,
                          'template': template, // Pass the GameTemplate object
                        }).then((result) {
                          if (result != null) {
                            final updatedArgs = result as Map<String, dynamic>;
                            print('EditGameInfoScreen - Updated Args from /date_time: $updatedArgs');
                            Navigator.pushReplacementNamed(
                              context,
                              '/review_game_info',
                              arguments: {
                                ...updatedArgs,
                                'isEdit': true,
                                'isFromGameInfo': args['isFromGameInfo'] ?? false,
                                'template': template, // Pass the GameTemplate object
                              },
                            );
                          }
                        });
                      },
                      style: elevatedButtonStyle().copyWith(
                        minimumSize: const WidgetStatePropertyAll(Size(300, 60)),
                        padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(vertical: 10, horizontal: 20)),
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
                        Navigator.pushNamed(context, '/additional_game_info', arguments: {
                          ...args,
                          'isEdit': true,
                          'isFromGameInfo': args['isFromGameInfo'] ?? false,
                          'template': template, // Pass the GameTemplate object
                        }).then((result) {
                          if (result != null) {
                            final updatedArgs = result as Map<String, dynamic>;
                            print('EditGameInfoScreen - Updated Args from /additional_game_info: $updatedArgs');
                            Navigator.pushReplacementNamed(
                              context,
                              '/review_game_info',
                              arguments: {
                                ...updatedArgs,
                                'isEdit': true,
                                'isFromGameInfo': args['isFromGameInfo'] ?? false,
                                'template': template, // Pass the GameTemplate object
                              },
                            );
                          }
                        });
                      },
                      style: elevatedButtonStyle().copyWith(
                        minimumSize: const WidgetStatePropertyAll(Size(300, 60)),
                        padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(vertical: 10, horizontal: 20)),
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
                              Navigator.pushNamed(context, '/select_officials', arguments: {
                                ...args,
                                'isEdit': true,
                                'isFromGameInfo': args['isFromGameInfo'] ?? false,
                                'template': template, // Pass the GameTemplate object
                              }).then((result) {
                                if (result != null) {
                                  final updatedArgs = result as Map<String, dynamic>;
                                  print('EditGameInfoScreen - Updated Args from /select_officials: $updatedArgs');
                                  Navigator.pushReplacementNamed(
                                    context,
                                    '/review_game_info',
                                    arguments: {
                                      ...updatedArgs,
                                      'isEdit': true,
                                      'isFromGameInfo': args['isFromGameInfo'] ?? false,
                                      'template': template, // Pass the GameTemplate object
                                    },
                                  );
                                }
                              });
                            },
                      style: elevatedButtonStyle().copyWith(
                        minimumSize: const WidgetStatePropertyAll(Size(300, 60)),
                        padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(vertical: 10, horizontal: 20)),
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
                        minimumSize: const WidgetStatePropertyAll(Size(300, 60)),
                        padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(vertical: 10, horizontal: 20)),
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
      ),
    );
  }
}