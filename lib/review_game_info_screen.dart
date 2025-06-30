import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'theme.dart';

class ReviewGameInfoScreen extends StatefulWidget {
  const ReviewGameInfoScreen({super.key});

  @override
  State<ReviewGameInfoScreen> createState() => _ReviewGameInfoScreenState();
}

class _ReviewGameInfoScreenState extends State<ReviewGameInfoScreen> {
  late Map<String, dynamic> args;
  late Map<String, dynamic> originalArgs;
  bool isEditMode = false;
  bool isFromGameInfo = false;
  bool isAwayGame = false;
  bool fromScheduleDetails = false;
  int? scheduleId;
  bool? isCoachScheduler;
  String? teamName;
  bool isUsingTemplate = false;
  bool isAssignerFlow = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final newArgs =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    setState(() {
      args = Map<String, dynamic>.from(newArgs);
      originalArgs = Map<String, dynamic>.from(newArgs);
      isEditMode = newArgs['isEdit'] == true;
      isFromGameInfo = newArgs['isFromGameInfo'] == true;
      isAwayGame = newArgs['isAway'] == true;
      fromScheduleDetails = newArgs['fromScheduleDetails'] == true;
      scheduleId = newArgs['scheduleId'] as int?;
      isUsingTemplate = newArgs['template'] != null;
      isAssignerFlow = newArgs['isAssignerFlow'] == true;
      if (args['officialsRequired'] != null) {
        args['officialsRequired'] =
            int.tryParse(args['officialsRequired'].toString()) ?? 0;
      }
      print('ReviewGameInfoScreen didChangeDependencies - Args: $args');
      print(
          'isEditMode: $isEditMode, isFromGameInfo: $isFromGameInfo, isAwayGame: $isAwayGame, fromScheduleDetails: $fromScheduleDetails, isUsingTemplate: $isUsingTemplate, isAssignerFlow: $isAssignerFlow');
    });
    _loadSchedulerType();
  }

  @override
  void initState() {
    super.initState();
    args = {};
    originalArgs = {};
  }

  Future<bool?> _showCreateTemplateDialog() async {
    final prefs = await SharedPreferences.getInstance();
    final dontAskAgain = prefs.getBool('dont_ask_create_template') ?? false;

    if (dontAskAgain) {
      return false; // Don't create template if user opted out
    }

    bool checkboxValue = false;

    return await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Create Game Template'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                  'Would you like to create a Game Template using the information from this game?'),
              const SizedBox(height: 16),
              Row(
                children: [
                  Checkbox(
                    value: checkboxValue,
                    onChanged: (value) {
                      setDialogState(() {
                        checkboxValue = value ?? false;
                      });
                    },
                    activeColor: efficialsBlue,
                  ),
                  const Expanded(
                    child: Text('Do not ask me again'),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () async {
                if (checkboxValue) {
                  await prefs.setBool('dont_ask_create_template', true);
                }
                Navigator.pop(context, false);
              },
              child: const Text('No', style: TextStyle(color: efficialsBlue)),
            ),
            TextButton(
              onPressed: () async {
                if (checkboxValue) {
                  await prefs.setBool('dont_ask_create_template', true);
                }
                Navigator.pop(context, true);
              },
              child: const Text('Yes', style: TextStyle(color: efficialsBlue)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _loadSchedulerType() async {
    final prefs = await SharedPreferences.getInstance();
    final schedulerType = prefs.getString('schedulerType');
    final savedTeamName = prefs.getString('team_name');
    setState(() {
      isCoachScheduler = schedulerType == 'Coach';
      teamName = savedTeamName;

      // If this is a Coach user and no schedule name is set yet, set it to team name
      if (isCoachScheduler == true &&
          args['scheduleName'] == null &&
          teamName != null) {
        args['scheduleName'] = teamName;
      }
    });
  }

  Future<void> _publishGame() async {
    if (!isAwayGame &&
        !(args['hireAutomatically'] == true) &&
        (args['selectedOfficials'] == null ||
            (args['selectedOfficials'] as List).isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'Please select at least one official for non-away games.')),
      );
      return;
    }

    final gameData = Map<String, dynamic>.from(args);
    gameData['id'] = gameData['id'] ?? DateTime.now().millisecondsSinceEpoch;
    gameData['createdAt'] = DateTime.now().toIso8601String();
    gameData['officialsHired'] = gameData['officialsHired'] ?? 0;
    gameData['status'] = 'Published';

    // Ensure schedule name is set
    if (gameData['scheduleName'] == null) {
      if (isCoachScheduler == true) {
        gameData['scheduleName'] = teamName ?? 'Team Schedule';
      } else {
        // For Athletic Director, require a schedule name
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Please set a schedule name before publishing.')),
        );
        return;
      }
    }

    if (gameData['date'] != null) {
      gameData['date'] = (gameData['date'] as DateTime).toIso8601String();
    }
    if (gameData['time'] != null) {
      final time = gameData['time'] as TimeOfDay;
      gameData['time'] = '${time.hour}:${time.minute}';
    }

    final prefs = await SharedPreferences.getInstance();

    // Determine which storage key to use based on user role
    String publishedGamesKey;
    if (isCoachScheduler == true) {
      publishedGamesKey = 'coach_published_games';
    } else if (isAssignerFlow == true) {
      publishedGamesKey = 'assigner_published_games';
    } else {
      publishedGamesKey = 'ad_published_games';
    }

    final String? gamesJson = prefs.getString(publishedGamesKey);
    List<Map<String, dynamic>> publishedGames = [];
    if (gamesJson != null && gamesJson.isNotEmpty) {
      publishedGames = List<Map<String, dynamic>>.from(jsonDecode(gamesJson));
    }

    publishedGames.add(gameData);
    await prefs.setString(publishedGamesKey, jsonEncode(publishedGames));

    // Don't show template dialog if game was created using a template
    bool? shouldCreateTemplate = false;
    if (!isUsingTemplate) {
      shouldCreateTemplate = await _showCreateTemplateDialog();
    }

    if (shouldCreateTemplate == true) {
      Navigator.pushNamed(
        context,
        '/new_game_template',
        arguments: gameData,
      ).then((result) {
        if (result == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Game Template created successfully!')),
          );
        }
        _navigateBack();
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Game published successfully!')),
      );
      _navigateBack();
    }
  }

  Future<void> _publishLater() async {
    final gameData = Map<String, dynamic>.from(args);
    gameData['id'] = gameData['id'] ?? DateTime.now().millisecondsSinceEpoch;
    gameData['createdAt'] = DateTime.now().toIso8601String();
    gameData['status'] = 'Unpublished';

    // Ensure schedule name is set
    if (gameData['scheduleName'] == null) {
      if (isCoachScheduler == true) {
        gameData['scheduleName'] = teamName ?? 'Team Schedule';
      } else {
        // For Athletic Director, require a schedule name
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Please set a schedule name before saving.')),
        );
        return;
      }
    }

    if (gameData['date'] != null) {
      gameData['date'] = (gameData['date'] as DateTime).toIso8601String();
    }
    if (gameData['time'] != null) {
      final time = gameData['time'] as TimeOfDay;
      gameData['time'] = '${time.hour}:${time.minute}';
    }

    final prefs = await SharedPreferences.getInstance();

    // Determine which storage key to use based on user role
    String unpublishedGamesKey;
    if (isCoachScheduler == true) {
      unpublishedGamesKey = 'coach_unpublished_games';
    } else if (isAssignerFlow == true) {
      unpublishedGamesKey = 'assigner_unpublished_games';
    } else {
      unpublishedGamesKey = 'ad_unpublished_games';
    }

    final String? gamesJson = prefs.getString(unpublishedGamesKey);
    List<Map<String, dynamic>> unpublishedGames = [];
    if (gamesJson != null && gamesJson.isNotEmpty) {
      unpublishedGames = List<Map<String, dynamic>>.from(jsonDecode(gamesJson));
    }

    unpublishedGames.add(gameData);
    await prefs.setString(unpublishedGamesKey, jsonEncode(unpublishedGames));

    // Don't show template dialog if game was created using a template
    bool? shouldCreateTemplate = false;
    if (!isUsingTemplate) {
      shouldCreateTemplate = await _showCreateTemplateDialog();
    }

    if (shouldCreateTemplate == true) {
      Navigator.pushNamed(
        context,
        '/new_game_template',
        arguments: gameData,
      ).then((result) {
        if (result == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Game Template created successfully!')),
          );
        }
        _navigateBack();
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Game saved to Unpublished Games list!')),
      );
      _navigateBack();
    }
  }

  void _navigateBack() async {
    if (fromScheduleDetails) {
      if (isAssignerFlow) {
        // For Assigners, navigate back to Manage Schedules screen with team selection
        final teamName = args['scheduleName'] as String?;
        print('ReviewGameInfo - Full args: $args');
        print('ReviewGameInfo - Team from scheduleName: $teamName');
        print('ReviewGameInfo - Team from opponent: ${args['opponent']}');
        print(
            'ReviewGameInfo - Navigating back to Manage Schedules with team: $teamName');

        final gameDate = args['date'] as DateTime?;
        print('ReviewGameInfo - Game date: $gameDate');

        Navigator.pushNamedAndRemoveUntil(
          context,
          '/assigner_manage_schedules',
          (route) =>
              route.settings.name ==
              '/assigner_home', // Keep assigner home in stack
          arguments: {
            'selectedTeam': teamName, // Pass the team name back
            'focusDate': gameDate, // Pass the game date to focus calendar
          },
        );
      } else {
        // For Athletic Directors, navigate to Schedule Details screen
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/schedule_details',
          (route) => false,
          arguments: {
            'scheduleName': args['scheduleName'],
            'scheduleId': scheduleId,
          },
        );
      }
    } else {
      final prefs = await SharedPreferences.getInstance();
      final schedulerType = prefs.getString('schedulerType');
      print('Current scheduler type: $schedulerType');

      String homeRoute;
      switch (schedulerType?.toLowerCase()) {
        case 'athletic director':
        case 'athleticdirector':
        case 'ad':
          print('Routing to Athletic Director home');
          homeRoute = '/athletic_director_home';
          break;
        case 'coach':
          print('Routing to Coach home');
          homeRoute = '/coach_home';
          break;
        case 'assigner':
          print('Routing to Assigner home');
          homeRoute = '/assigner_home';
          break;
        default:
          print(
              'No matching scheduler type found, defaulting to welcome screen');
          homeRoute = '/welcome';
      }

      Navigator.pushNamedAndRemoveUntil(
        context,
        homeRoute,
        (route) => false,
      );
    }
  }

  Future<void> _publishUpdate() async {
    final gameData = Map<String, dynamic>.from(args);

    if (gameData['date'] != null) {
      gameData['date'] = (gameData['date'] as DateTime).toIso8601String();
    }
    if (gameData['time'] != null) {
      final time = gameData['time'] as TimeOfDay;
      gameData['time'] = '${time.hour}:${time.minute}';
    }
    gameData['status'] = 'Published';

    final prefs = await SharedPreferences.getInstance();
    final String? gamesJson = prefs.getString('published_games');
    List<Map<String, dynamic>> publishedGames = [];
    if (gamesJson != null && gamesJson.isNotEmpty) {
      publishedGames = List<Map<String, dynamic>>.from(jsonDecode(gamesJson));
    }

    final index = publishedGames.indexWhere((g) => g['id'] == gameData['id']);
    if (index != -1) {
      publishedGames[index] = gameData;
    } else {
      publishedGames.add(gameData);
    }

    await prefs.setString('published_games', jsonEncode(publishedGames));

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Game updated successfully!')),
    );

    if (isFromGameInfo) {
      final schedulerType = prefs.getString('schedulerType');
      print('Current scheduler type: $schedulerType');

      String homeRoute;
      switch (schedulerType?.toLowerCase()) {
        case 'athletic director':
        case 'athleticdirector':
        case 'ad':
          print('Routing to Athletic Director home');
          homeRoute = '/athletic_director_home';
          break;
        case 'coach':
          print('Routing to Coach home');
          homeRoute = '/coach_home';
          break;
        case 'assigner':
          print('Routing to Assigner home');
          homeRoute = '/assigner_home';
          break;
        default:
          print(
              'No matching scheduler type found, defaulting to welcome screen');
          homeRoute = '/welcome';
      }

      Navigator.pushNamedAndRemoveUntil(
        context,
        homeRoute,
        (route) => false,
        arguments: {'refresh': true, 'gameData': gameData},
      );
    } else {
      Navigator.pop(context, {'refresh': true, 'gameData': gameData});
    }
  }

  bool _hasChanges() {
    return args.toString() != originalArgs.toString();
  }

  Future<bool> _onWillPop() async {
    if (!_hasChanges()) {
      return true;
    }

    final shouldDiscard = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Unsaved Changes'),
        content: const Text(
            'You have unsaved changes. Are you sure you want to discard them?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: efficialsBlue)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('OK', style: TextStyle(color: efficialsBlue)),
          ),
        ],
      ),
    );

    return shouldDiscard ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final gameDetails = {
      'Sport': args['sport'] as String? ?? 'Unknown',
      // For Coach users, don't show schedule name in UI but still store it
      if (isCoachScheduler != true)
        'Schedule Name': args['scheduleName'] as String? ?? 'Unnamed',
      'Date': args['date'] != null
          ? DateFormat('MMMM d, yyyy').format(args['date'] as DateTime)
          : 'Not set',
      'Time': args['time'] != null
          ? (args['time'] as TimeOfDay).format(context)
          : 'Not set',
      'Location': args['location'] as String? ?? 'Not set',
      'Opponent': args['opponent'] as String? ?? 'Not set',
    };

    final additionalDetails = !isAwayGame
        ? {
            'Officials Required': (args['officialsRequired'] ?? 0).toString(),
            'Fee per Official':
                args['gameFee'] != null ? '\$${args['gameFee']}' : 'Not set',
            'Gender': args['gender'] != null
                ? ((args['levelOfCompetition'] as String?)?.toLowerCase() ==
                            'college' ||
                        (args['levelOfCompetition'] as String?)
                                ?.toLowerCase() ==
                            'adult'
                    ? {
                          'boys': 'Men',
                          'girls': 'Women',
                          'co-ed': 'Co-ed'
                        }[(args['gender'] as String).toLowerCase()] ??
                        'Not set'
                    : args['gender'] as String)
                : 'Not set',
            'Competition Level':
                args['levelOfCompetition'] as String? ?? 'Not set',
            'Hire Automatically':
                args['hireAutomatically'] == true ? 'Yes' : 'No',
          }
        : {};

    final allDetails = {
      ...gameDetails,
      if (!isAwayGame) ...additionalDetails,
    };

    final isPublished = args['status'] == 'Published';

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: efficialsBlack,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, size: 36, color: Colors.white),
            onPressed: () async {
              if (await _onWillPop()) {
                Navigator.pop(context);
              }
            },
          ),
          title: const Text('Review Game Info', style: appBarTextStyle),
        ),
        body: CustomScrollView(
          slivers: [
            SliverPersistentHeader(
              pinned: true,
              delegate: _SliverHeaderDelegate(
                child: Container(
                  color: darkSurface,
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Game Details',
                          style: TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold)),
                      TextButton(
                        onPressed: () => Navigator.pushNamed(
                            context, '/edit_game_info',
                            arguments: {
                              ...args,
                              'isEdit': true,
                              'isFromGameInfo': isFromGameInfo,
                              'fromScheduleDetails': fromScheduleDetails,
                              'scheduleId': scheduleId,
                            }).then((result) {
                          if (result != null &&
                              result is Map<String, dynamic>) {
                            setState(() {
                              args = result;
                              fromScheduleDetails =
                                  result['fromScheduleDetails'] == true;
                              scheduleId = result['scheduleId'] as int?;
                              print(
                                  'ReviewGameInfoScreen Edit callback - Updated Args: $args');
                            });
                          }
                        }),
                        child: const Text('Edit',
                            style:
                                TextStyle(color: efficialsBlue, fontSize: 18)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ...allDetails.entries.map(
                        (e) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                width: 150,
                                child: Text('${e.key}:',
                                    style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500)),
                              ),
                              Expanded(
                                  child: Text(e.value,
                                      style: const TextStyle(fontSize: 16))),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text('Selected Officials',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 10),
                      if (isAwayGame)
                        const Text('No officials needed for away games.',
                            style: TextStyle(fontSize: 16, color: Colors.grey))
                      else if (args['method'] == 'use_list' &&
                          args['selectedListName'] != null)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Text(
                            'List Used: ${args['selectedListName']}',
                            style: const TextStyle(fontSize: 16),
                          ),
                        )
                      else if (args['selectedOfficials'] == null ||
                          (args['selectedOfficials'] as List).isEmpty)
                        const Text('No officials selected.',
                            style: TextStyle(fontSize: 16, color: Colors.grey))
                      else if (args['method'] == 'advanced' &&
                          args['selectedLists'] != null) ...[
                        ...((args['selectedLists']
                                as List<Map<String, dynamic>>)
                            .map(
                          (list) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Text(
                              '${list['name']}: Min ${list['minOfficials']}, Max ${list['maxOfficials']}',
                              style: const TextStyle(fontSize: 16),
                            ),
                          ),
                        )),
                      ] else ...[
                        ...((args['selectedOfficials']
                                as List<Map<String, dynamic>>)
                            .map(
                          (official) => ListTile(
                            title: Text(official['name'] as String),
                            subtitle: Text(
                                'Distance: ${(official['distance'] as num?)?.toStringAsFixed(1) ?? '0.0'} mi'),
                          ),
                        )),
                      ],
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        bottomNavigationBar: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isPublished) ...[
                ElevatedButton(
                  onPressed: _publishUpdate,
                  style: elevatedButtonStyle(),
                  child: const Text('Publish Update',
                      style: signInButtonTextStyle),
                ),
              ] else ...[
                ElevatedButton(
                  onPressed: _publishGame,
                  style: elevatedButtonStyle(),
                  child:
                      const Text('Publish Game', style: signInButtonTextStyle),
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: _publishLater,
                  style: elevatedButtonStyle(),
                  child:
                      const Text('Publish Later', style: signInButtonTextStyle),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _SliverHeaderDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;

  _SliverHeaderDelegate({required this.child});

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return child;
  }

  @override
  double get maxExtent => 80;

  @override
  double get minExtent => 80;

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) =>
      true;
}
