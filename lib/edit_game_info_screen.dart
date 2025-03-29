import 'package:flutter/material.dart';
import 'theme.dart';

class EditGameInfoScreen extends StatefulWidget {
  const EditGameInfoScreen({super.key});

  @override
  _EditGameInfoScreenState createState() => _EditGameInfoScreenState();
}

class _EditGameInfoScreenState extends State<EditGameInfoScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _isAwayGame = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
    if (args != null) {
      _isAwayGame = args['isAway'] == true;
      print('didChangeDependencies - EditGameInfo Args: $args');
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
    final date = args['date'] as DateTime? ?? DateTime.now();
    final time = args['time'] as TimeOfDay? ?? const TimeOfDay(hour: 12, minute: 0);
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
        backgroundColor: efficialsBlue,
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
                              },
                            );
                          }
                        });
                      },
                      style: elevatedButtonStyle().copyWith(
                        minimumSize: const MaterialStatePropertyAll(Size(300, 60)),
                        padding: const MaterialStatePropertyAll(EdgeInsets.symmetric(vertical: 10, horizontal: 20)),
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
                              },
                            );
                          }
                        });
                      },
                      style: elevatedButtonStyle().copyWith(
                        minimumSize: const MaterialStatePropertyAll(Size(300, 60)),
                        padding: const MaterialStatePropertyAll(EdgeInsets.symmetric(vertical: 10, horizontal: 20)),
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
                              },
                            );
                          }
                        });
                      },
                      style: elevatedButtonStyle().copyWith(
                        minimumSize: const MaterialStatePropertyAll(Size(300, 60)),
                        padding: const MaterialStatePropertyAll(EdgeInsets.symmetric(vertical: 10, horizontal: 20)),
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
                                    },
                                  );
                                }
                              });
                            },
                      style: elevatedButtonStyle().copyWith(
                        minimumSize: const MaterialStatePropertyAll(Size(300, 60)),
                        padding: const MaterialStatePropertyAll(EdgeInsets.symmetric(vertical: 10, horizontal: 20)),
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
                        minimumSize: const MaterialStatePropertyAll(Size(300, 60)),
                        padding: const MaterialStatePropertyAll(EdgeInsets.symmetric(vertical: 10, horizontal: 20)),
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