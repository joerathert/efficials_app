import 'package:flutter/material.dart';
import 'theme.dart';

class EditGameInfoScreen extends StatefulWidget {
  const EditGameInfoScreen({super.key});

  @override
  _EditGameInfoScreenState createState() => _EditGameInfoScreenState();
}

class _EditGameInfoScreenState extends State<EditGameInfoScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
    print('didChangeDependencies - EditGameInfo Args: $args');
  }

  void _handleEditOfficials(Map<String, dynamic> args) {
    final method = args['method'] as String? ?? 'standard';
    final scheduleName = args['scheduleName'] as String? ?? 'Unnamed Schedule';
    final sport = args['sport'] as String? ?? 'Unknown Sport';
    final selectedOfficials = args['selectedOfficials'] as List<Map<String, dynamic>>? ?? [];

    String route;
    Map<String, dynamic> routeArgs = {
      ...args,
      'isEdit': true,
      'isFromGameInfo': args['isFromGameInfo'] ?? false, // Pass isFromGameInfo
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
        routeArgs = {
          'sport': sport,
          'listName': scheduleName,
          'selectedOfficials': selectedOfficials,
          'method': 'standard',
          'isEdit': true,
          'isFromGameInfo': args['isFromGameInfo'] ?? false, // Pass isFromGameInfo
        };
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
            'isFromGameInfo': args['isFromGameInfo'] ?? false, // Preserve isFromGameInfo
          },
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    final scheduleName = args['scheduleName'] as String? ?? 'Unnamed Schedule';
    final sport = args['sport'] as String? ?? 'Unknown Sport';
    final location = args['location'] as String? ?? 'Unknown Location';
    final date = args['date'] as DateTime? ?? DateTime.now();
    final time = args['time'] as TimeOfDay? ?? const TimeOfDay(hour: 12, minute: 0);
    final levelOfCompetition = args['levelOfCompetition'] as String?;
    final gender = args['gender'] as String?;
    final officialsRequired = args['officialsRequired'] as String?;
    final gameFee = args['gameFee'] as String?;
    final hireAutomatically = args['hireAutomatically'] as bool?;
    final selectedOfficials = args['selectedOfficials'] as List<Map<String, dynamic>>? ?? [];

    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        backgroundColor: efficialsBlue,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, size: 36, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Edit Game Info',
          style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
        ),
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
                          'isFromGameInfo': args['isFromGameInfo'] ?? false, // Pass isFromGameInfo
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
                                'isFromGameInfo': args['isFromGameInfo'] ?? false, // Preserve isFromGameInfo
                              },
                            );
                          }
                        });
                      },
                      style: elevatedButtonStyle().copyWith(
                        minimumSize: MaterialStateProperty.all(const Size(300, 60)),
                        padding: MaterialStateProperty.all(const EdgeInsets.symmetric(vertical: 10, horizontal: 20)),
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
                          'isFromGameInfo': args['isFromGameInfo'] ?? false, // Pass isFromGameInfo
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
                                'isFromGameInfo': args['isFromGameInfo'] ?? false, // Preserve isFromGameInfo
                              },
                            );
                          }
                        });
                      },
                      style: elevatedButtonStyle().copyWith(
                        minimumSize: MaterialStateProperty.all(const Size(300, 60)),
                        padding: MaterialStateProperty.all(const EdgeInsets.symmetric(vertical: 10, horizontal: 20)),
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
                          'isFromGameInfo': args['isFromGameInfo'] ?? false, // Pass isFromGameInfo
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
                                'isFromGameInfo': args['isFromGameInfo'] ?? false, // Preserve isFromGameInfo
                              },
                            );
                          }
                        });
                      },
                      style: elevatedButtonStyle().copyWith(
                        minimumSize: MaterialStateProperty.all(const Size(300, 60)),
                        padding: MaterialStateProperty.all(const EdgeInsets.symmetric(vertical: 10, horizontal: 20)),
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
                      onPressed: () {
                        Navigator.pushNamed(context, '/select_officials', arguments: {
                          ...args,
                          'isEdit': true,
                          'isFromGameInfo': args['isFromGameInfo'] ?? false, // Pass isFromGameInfo
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
                                'isFromGameInfo': args['isFromGameInfo'] ?? false, // Preserve isFromGameInfo
                              },
                            );
                          }
                        });
                      },
                      style: elevatedButtonStyle().copyWith(
                        minimumSize: MaterialStateProperty.all(const Size(300, 60)),
                        padding: MaterialStateProperty.all(const EdgeInsets.symmetric(vertical: 10, horizontal: 20)),
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
                      onPressed: () => _handleEditOfficials(args),
                      style: elevatedButtonStyle().copyWith(
                        minimumSize: MaterialStateProperty.all(const Size(300, 60)),
                        padding: MaterialStateProperty.all(const EdgeInsets.symmetric(vertical: 10, horizontal: 20)),
                      ),
                      child: const Text(
                        'Selected Officials',
                        style: signInButtonTextStyle,
                        textAlign: TextAlign.center,
                      ),
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