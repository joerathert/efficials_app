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
  late Map<String, dynamic> originalArgs; // Store original args to detect changes
  bool isEditMode = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final newArgs = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    setState(() {
      args = Map<String, dynamic>.from(newArgs); // Create a modifiable copy
      originalArgs = Map<String, dynamic>.from(newArgs); // Store original for comparison
      // Set isEditMode based on the presence of 'id'
      isEditMode = newArgs['id'] != null;
      print('ReviewGameInfoScreen didChangeDependencies - Args: $args, isEditMode: $isEditMode');
    });
  }

  @override
  void initState() {
    super.initState();
    args = {};
    originalArgs = {};
  }

  Future<void> _publishGame() async {
    // Prepare the game data to save, converting DateTime and TimeOfDay to strings
    final gameData = Map<String, dynamic>.from(args);
    gameData['id'] = DateTime.now().millisecondsSinceEpoch; // Unique ID for the game
    gameData['createdAt'] = DateTime.now().toIso8601String();
    gameData['officialsHired'] = 0; // Initialize hired officials count to 0

    // Convert DateTime to string
    if (gameData['date'] != null) {
      gameData['date'] = (gameData['date'] as DateTime).toIso8601String();
    }
    // Convert TimeOfDay to string (e.g., "HH:mm")
    if (gameData['time'] != null) {
      final time = gameData['time'] as TimeOfDay;
      gameData['time'] = '${time.hour}:${time.minute}';
    }

    // Save to shared_preferences under 'published_games'
    final prefs = await SharedPreferences.getInstance();
    final String? gamesJson = prefs.getString('published_games');
    List<Map<String, dynamic>> publishedGames = [];
    if (gamesJson != null && gamesJson.isNotEmpty) {
      publishedGames = List<Map<String, dynamic>>.from(jsonDecode(gamesJson));
    }

    publishedGames.add(gameData);
    await prefs.setString('published_games', jsonEncode(publishedGames));

    // Show snackbar and navigate back to home
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Game published!')),
    );
    Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
  }

  Future<void> _publishLater() async {
    // Prepare the game data to save, converting DateTime and TimeOfDay to strings
    final gameData = Map<String, dynamic>.from(args);
    gameData['id'] = DateTime.now().millisecondsSinceEpoch; // Unique ID for the game
    gameData['createdAt'] = DateTime.now().toIso8601String();

    // Convert DateTime to string
    if (gameData['date'] != null) {
      gameData['date'] = (gameData['date'] as DateTime).toIso8601String();
    }
    // Convert TimeOfDay to string (e.g., "HH:mm")
    if (gameData['time'] != null) {
      final time = gameData['time'] as TimeOfDay;
      gameData['time'] = '${time.hour}:${time.minute}';
    }

    // Save to shared_preferences
    final prefs = await SharedPreferences.getInstance();
    final String? gamesJson = prefs.getString('unpublished_games');
    List<Map<String, dynamic>> unpublishedGames = [];
    if (gamesJson != null && gamesJson.isNotEmpty) {
      unpublishedGames = List<Map<String, dynamic>>.from(jsonDecode(gamesJson));
    }

    unpublishedGames.add(gameData);
    await prefs.setString('unpublished_games', jsonEncode(unpublishedGames));

    // Show snackbar and navigate back to home
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Moved to Unpublished Games!')),
    );
    Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
  }

  Future<void> _publishUpdate() async {
    // Prepare the game data to save, converting DateTime and TimeOfDay to strings
    final gameData = Map<String, dynamic>.from(args);

    // Convert DateTime to string
    if (gameData['date'] != null) {
      gameData['date'] = (gameData['date'] as DateTime).toIso8601String();
    }
    // Convert TimeOfDay to string (e.g., "HH:mm")
    if (gameData['time'] != null) {
      final time = gameData['time'] as TimeOfDay;
      gameData['time'] = '${time.hour}:${time.minute}';
    }

    // Update the published games in shared_preferences
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

    // Show snackbar and navigate back to GameInformationScreen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Game updated!')),
    );
    Navigator.pop(context, gameData); // Return updated game data to GameInformationScreen
  }

  bool _hasChanges() {
    // Compare args with originalArgs to detect changes
    return args.toString() != originalArgs.toString();
  }

  Future<bool> _onWillPop() async {
    if (!_hasChanges()) {
      return true; // Allow navigation if no changes
    }

    final shouldDiscard = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Unsaved Changes'),
        content: const Text('You have unsaved changes. Are you sure you want to discard them?'),
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
    final isAdultLevel = (args['levelOfCompetition'] as String?)?.toLowerCase() == 'college' ||
        (args['levelOfCompetition'] as String?)?.toLowerCase() == 'adult';

    final gameDetails = {
      'Sport': args['sport'] as String? ?? 'Unknown',
      'Schedule Name': args['scheduleName'] as String? ?? 'Unnamed',
      'Date': args['date'] != null ? DateFormat('MMMM d, yyyy').format(args['date'] as DateTime) : 'Not set',
      'Time': args['time'] != null ? (args['time'] as TimeOfDay).format(context) : 'Not set',
      'Location': args['location'] as String? ?? 'Not set',
      'Officials Required': args['officialsRequired'] as String? ?? '0',
      'Game Fee per Official': args['gameFee'] != null ? '\$${args['gameFee']}' : 'Not set',
      'Gender': args['gender'] != null
          ? (isAdultLevel
              ? {'boys': 'Men', 'girls': 'Women', 'co-ed': 'Co-ed'}[(args['gender'] as String).toLowerCase()] ??
                  'Not set'
              : args['gender'] as String)
          : 'Not set',
      'Competition Level': args['levelOfCompetition'] as String? ?? 'Not set',
      'Hire Automatically': args['hireAutomatically'] == true ? 'Yes' : 'No',
    };

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
                      const Text('Game Details', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      TextButton(
                        onPressed: () => Navigator.pushNamed(context, '/edit_game_info', arguments: args).then((result) {
                          if (result != null && result is Map<String, dynamic>) {
                            setState(() {
                              args = result;
                              print('ReviewGameInfoScreen Edit callback - Updated Args: $args');
                            });
                          }
                        }),
                        child: const Text('Edit', style: TextStyle(color: efficialsBlue, fontSize: 18)),
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
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ...gameDetails.entries.map(
                        (e) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Text('${e.key}: ${e.value}', style: const TextStyle(fontSize: 16)),
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text('Selected Officials', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 10),
                      if (args['selectedOfficials'] == null || (args['selectedOfficials'] as List).isEmpty)
                        const Text('No officials selected.', style: TextStyle(fontSize: 16, color: Colors.grey))
                      else if (args['method'] == 'advanced' && args['selectedLists'] != null) ...[
                        // Display summary for Advanced method
                        ...((args['selectedLists'] as List<Map<String, dynamic>>).map(
                          (list) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Text(
                              '${list['name']}: Min ${list['minOfficials']}, Max ${list['maxOfficials']}',
                              style: const TextStyle(fontSize: 16),
                            ),
                          ),
                        )),
                      ]
                      else if (args['method'] == 'use_list' && args['selectedListName'] != null) ...[
                        // Display summary for Use List method
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Text(
                            'List Used: ${args['selectedListName']}',
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                      ]
                      else ...[
                        // Display detailed officials list for Standard method
                        ...((args['selectedOfficials'] as List<Map<String, dynamic>>).map(
                          (official) => ListTile(
                            title: Text(official['name'] as String),
                            subtitle: Text('Distance: ${(official['distance'] as num?)?.toStringAsFixed(1) ?? '0.0'} mi'),
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
              if (isEditMode) ...[
                ElevatedButton(
                  onPressed: _publishUpdate,
                  style: elevatedButtonStyle(),
                  child: const Text('Publish Update', style: signInButtonTextStyle),
                ),
              ] else ...[
                ElevatedButton(
                  onPressed: _publishGame,
                  style: elevatedButtonStyle(),
                  child: const Text('Publish Game', style: signInButtonTextStyle),
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: _publishLater,
                  style: elevatedButtonStyle(),
                  child: const Text('Publish Later', style: signInButtonTextStyle),
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
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return child;
  }

  @override
  double get maxExtent => 80;

  @override
  double get minExtent => 80;

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) => true;
}