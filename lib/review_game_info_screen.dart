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
  bool fromScheduleDetails = false; // Added flag
  int? scheduleId; // Added scheduleId

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
      fromScheduleDetails = newArgs['fromScheduleDetails'] == true; // Set flag
      scheduleId = newArgs['scheduleId'] as int?; // Set scheduleId
      if (args['sport'] == null || args['sport'] == 'Unknown Sport') {
        args['sport'] = 'Football';
      }
      if (args['officialsRequired'] != null) {
        args['officialsRequired'] =
            int.tryParse(args['officialsRequired'].toString()) ?? 0;
      }
      print('ReviewGameInfoScreen didChangeDependencies - Args: $args');
      print(
          'isEditMode: $isEditMode, isFromGameInfo: $isFromGameInfo, isAwayGame: $isAwayGame, fromScheduleDetails: $fromScheduleDetails');
    });
  }

  @override
  void initState() {
    super.initState();
    args = {};
    originalArgs = {};
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

    if (gameData['date'] != null) {
      gameData['date'] = (gameData['date'] as DateTime).toIso8601String();
    }
    if (gameData['time'] != null) {
      final time = gameData['time'] as TimeOfDay;
      gameData['time'] = '${time.hour}:${time.minute}';
    }

    final prefs = await SharedPreferences.getInstance();
    final String? gamesJson = prefs.getString('published_games');
    List<Map<String, dynamic>> publishedGames = [];
    if (gamesJson != null && gamesJson.isNotEmpty) {
      publishedGames = List<Map<String, dynamic>>.from(jsonDecode(gamesJson));
    }

    publishedGames.add(gameData);
    await prefs.setString('published_games', jsonEncode(publishedGames));

    final shouldCreateTemplate = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Game Template'),
        content: const Text(
            'Would you like to create a Game Template using the information from this game?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No', style: TextStyle(color: efficialsBlue)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Yes', style: TextStyle(color: efficialsBlue)),
          ),
        ],
      ),
    );

    print('PublishGame - shouldCreateTemplate: $shouldCreateTemplate'); // Debug
    if (shouldCreateTemplate == true) {
      print('Navigating to /new_game_template'); // Debug
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
        print(
            'Returning from /new_game_template, calling _navigateBack'); // Debug
        _navigateBack();
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Game published successfully!')),
      );
      print('Calling _navigateBack after publishing'); // Debug
      _navigateBack();
    }
  }

  Future<void> _publishLater() async {
    final gameData = Map<String, dynamic>.from(args);
    gameData['id'] = gameData['id'] ?? DateTime.now().millisecondsSinceEpoch;
    gameData['createdAt'] = DateTime.now().toIso8601String();
    gameData['status'] = 'Unpublished';

    if (gameData['date'] != null) {
      gameData['date'] = (gameData['date'] as DateTime).toIso8601String();
    }
    if (gameData['time'] != null) {
      final time = gameData['time'] as TimeOfDay;
      gameData['time'] = '${time.hour}:${time.minute}';
    }

    final prefs = await SharedPreferences.getInstance();
    final String? gamesJson = prefs.getString('unpublished_games');
    List<Map<String, dynamic>> unpublishedGames = [];
    if (gamesJson != null && gamesJson.isNotEmpty) {
      unpublishedGames = List<Map<String, dynamic>>.from(jsonDecode(gamesJson));
    }

    unpublishedGames.add(gameData);
    await prefs.setString('unpublished_games', jsonEncode(unpublishedGames));

    final shouldCreateTemplate = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Game Template'),
        content: const Text(
            'Would you like to create a Game Template using the information from this game?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No', style: TextStyle(color: efficialsBlue)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Yes', style: TextStyle(color: efficialsBlue)),
          ),
        ],
      ),
    );

    print(
        'PublishLater - shouldCreateTemplate: $shouldCreateTemplate'); // Debug
    if (shouldCreateTemplate == true) {
      print('Navigating to /new_game_template'); // Debug
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
        print(
            'Returning from /new_game_template, calling _navigateBack'); // Debug
        _navigateBack();
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Game saved to Unpublished Games list!')),
      );
      print('Calling _navigateBack after saving unpublished'); // Debug
      _navigateBack();
    }
  }

  void _navigateBack() {
    print(
        'Navigating back - fromScheduleDetails: $fromScheduleDetails'); // Debug
    if (fromScheduleDetails) {
      print(
          'Returning to Schedule Details with scheduleName: ${args['scheduleName']}, scheduleId: $scheduleId'); // Debug
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/schedule_details',
        (route) => false,
        arguments: {
          'scheduleName': args['scheduleName'],
          'scheduleId': scheduleId,
        },
      );
    } else {
      print('Returning to Home'); // Debug
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/home',
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
      const SnackBar(content: Text('Game updated on Home screen!')),
    );
    if (isFromGameInfo) {
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/home',
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
          backgroundColor: efficialsBlue,
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
                  color: Colors.white,
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
                              'fromScheduleDetails':
                                  fromScheduleDetails, // Pass flag forward
                              'scheduleId':
                                  scheduleId, // Pass scheduleId forward
                            }).then((result) {
                          if (result != null &&
                              result is Map<String, dynamic>) {
                            setState(() {
                              args = result;
                              fromScheduleDetails =
                                  result['fromScheduleDetails'] ==
                                      true; // Update flag
                              scheduleId = result['scheduleId']
                                  as int?; // Update scheduleId
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
