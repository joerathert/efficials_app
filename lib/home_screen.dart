import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'theme.dart';

class Game {
  final int id;
  final String scheduleName;
  final DateTime? date;
  final TimeOfDay? time;
  final String sport;
  final int officialsRequired;
  final int officialsHired;
  final bool isAway;
  final List<Map<String, dynamic>>? selectedOfficials;

  Game({
    required this.id,
    required this.scheduleName,
    this.date,
    this.time,
    required this.sport,
    required this.officialsRequired,
    required this.officialsHired,
    this.isAway = false,
    this.selectedOfficials,
  });

  factory Game.fromJson(Map<String, dynamic> json) {
    final timeStr = json['time'] as String?;
    TimeOfDay? time;
    if (timeStr != null) {
      final parts = timeStr.split(':');
      time = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
    }

    return Game(
      id: json['id'] as int,
      scheduleName: json['scheduleName'] as String,
      date: json['date'] != null ? DateTime.parse(json['date'] as String) : null,
      time: time,
      sport: json['sport'] as String? ?? 'Unknown Sport',
      officialsRequired: int.parse(json['officialsRequired']?.toString() ?? '0'),
      officialsHired: json['officialsHired'] as int? ?? 0,
      isAway: json['isAway'] as bool? ?? false,
      selectedOfficials: json['selectedOfficials'] != null
          ? (json['selectedOfficials'] as List<dynamic>)
              .map((e) => Map<String, dynamic>.from(e as Map))
              .toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'scheduleName': scheduleName,
        'date': date?.toIso8601String(),
        'time': time != null ? '${time!.hour}:${time!.minute}' : null,
        'sport': sport,
        'officialsRequired': officialsRequired,
        'officialsHired': officialsHired,
        'isAway': isAway,
        'selectedOfficials': selectedOfficials,
      };
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Game> publishedGames = [];
  List<String> existingSchedules = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchPublishedGames();
  }

  Future<void> _fetchPublishedGames() async {
    final prefs = await SharedPreferences.getInstance();
    final String? gamesJson = prefs.getString('published_games');
    final String? unpublishedGamesJson = prefs.getString('unpublished_games');

    // Fetch existing schedules
    Set<String> scheduleNames = {};
    if (unpublishedGamesJson != null && unpublishedGamesJson.isNotEmpty) {
      final unpublished = List<Map<String, dynamic>>.from(jsonDecode(unpublishedGamesJson));
      for (var game in unpublished) {
        scheduleNames.add(game['scheduleName'] as String);
      }
    }
    if (gamesJson != null && gamesJson.isNotEmpty) {
      final published = List<Map<String, dynamic>>.from(jsonDecode(gamesJson));
      for (var game in published) {
        scheduleNames.add(game['scheduleName'] as String);
      }
    }
    existingSchedules = scheduleNames.toList();

    setState(() {
      if (gamesJson != null && gamesJson.isNotEmpty) {
        try {
          publishedGames = List<Map<String, dynamic>>.from(jsonDecode(gamesJson))
              .map(Game.fromJson)
              .where((game) => existingSchedules.contains(game.scheduleName))
              .toList();
        } catch (e) {
          publishedGames = [];
          print('Error loading published games: $e');
        }
      } else {
        publishedGames = [];
      }
      isLoading = false;
    });
  }

  Future<Map<String, dynamic>?> _fetchGameById(int gameId) async {
    final prefs = await SharedPreferences.getInstance();
    final String? gamesJson = prefs.getString('published_games');
    if (gamesJson != null && gamesJson.isNotEmpty) {
      try {
        final List<Map<String, dynamic>> games = List<Map<String, dynamic>>.from(jsonDecode(gamesJson));
        final game = games.firstWhere((g) => g['id'] == gameId, orElse: () => {});
        if (game.isNotEmpty) {
          if (game['date'] != null) {
            game['date'] = DateTime.parse(game['date'] as String);
          }
          if (game['time'] != null) {
            final timeParts = (game['time'] as String).split(':');
            game['time'] = TimeOfDay(
              hour: int.parse(timeParts[0]),
              minute: int.parse(timeParts[1]),
            );
          }
          if (game['selectedOfficials'] != null) {
            game['selectedOfficials'] = (game['selectedOfficials'] as List<dynamic>)
                .map((official) => Map<String, dynamic>.from(official as Map))
                .toList();
          }
          return game;
        }
      } catch (e) {
        print('Error fetching game by ID: $e');
      }
    }
    return null;
  }

  IconData _getSportIcon(String sport) {
    print('Sport value for game: $sport');
    switch (sport.toLowerCase()) {
      case 'football':
        return Icons.sports_football;
      case 'basketball':
        return Icons.sports_basketball;
      case 'baseball':
        return Icons.sports_baseball;
      case 'soccer':
        return Icons.sports_soccer;
      case 'volleyball':
        return Icons.sports_volleyball;
      default:
        return Icons.sports;
    }
  }

  @override
  Widget build(BuildContext context) {
    final double statusBarHeight = MediaQuery.of(context).padding.top;
    const double appBarHeight = kToolbarHeight;
    final double totalBannerHeight = statusBarHeight + appBarHeight;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Home'),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, color: Colors.white),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            Container(
              height: totalBannerHeight,
              decoration: const BoxDecoration(color: efficialsBlue),
              child: Padding(
                padding: EdgeInsets.only(
                  top: statusBarHeight + 8.0,
                  bottom: 8.0,
                  left: 16.0,
                  right: 16.0,
                ),
                child: const Text(
                  'Menu',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.schedule),
              title: const Text('Schedules'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/schedules').then((result) {
                  _fetchPublishedGames();
                });
              },
            ),
            ListTile(
              leading: const Icon(Icons.location_on),
              title: const Text('Locations'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/locations');
              },
            ),
            ListTile(
              leading: const Icon(Icons.people),
              title: const Text('Lists of Officials'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/lists_of_officials');
              },
            ),
            ListTile(
              leading: const Icon(Icons.games),
              title: const Text('Unpublished Games'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/unpublished_games');
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Settings'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Settings not implemented yet')),
                );
              },
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Center(
            child: isLoading
                ? const CircularProgressIndicator()
                : publishedGames.isEmpty
                    ? const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            'Click the "+" icon to get started.',
                            style: homeTextStyle,
                            textAlign: TextAlign.center,
                          ),
                        ],
                      )
                    : ListView.builder(
                        itemCount: publishedGames.length,
                        itemBuilder: (context, index) {
                          final game = publishedGames[index];
                          final gameTitle = game.scheduleName;
                          final gameDate = game.date != null
                              ? DateFormat('EEEE, MMM d, yyyy').format(game.date!)
                              : 'Not set';
                          final gameTime = game.time != null ? game.time!.format(context) : 'Not set';
                          final requiredOfficials = game.officialsRequired;
                          final hiredOfficials = game.officialsHired;
                          final isFullyHired = hiredOfficials >= requiredOfficials;
                          final sport = game.sport;
                          final sportIcon = _getSportIcon(sport);
                          final isAway = game.isAway;

                          return GestureDetector(
                            onTap: () async {
                              final gameId = game.id;
                              final latestGame = await _fetchGameById(gameId);
                              if (latestGame == null) {
                                print('Error: Could not fetch game with ID $gameId');
                                return;
                              }
                              Navigator.pushNamed(
                                context,
                                '/game_information',
                                arguments: latestGame,
                              ).then((result) async {
                                if (result == true) {
                                  _fetchPublishedGames();
                                } else if (result != null && result is Map<String, dynamic>) {
                                  setState(() {
                                    final index = publishedGames.indexWhere((g) => g.id == game.id);
                                    if (index != -1) {
                                      publishedGames[index] = Game.fromJson(result);
                                    }
                                  });
                                  final prefs = await SharedPreferences.getInstance();
                                  final gamesToSave = publishedGames.map((g) => g.toJson()).toList();
                                  await prefs.setString('published_games', jsonEncode(gamesToSave));
                                  _fetchPublishedGames();
                                }
                              });
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8.0),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          gameDate,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Text(
                                              '$gameTime - $gameTitle ($sport)',
                                              style: const TextStyle(
                                                fontSize: 16,
                                                color: Colors.black,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Icon(
                                              sportIcon,
                                              color: efficialsBlue,
                                              size: 24,
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            if (isAway)
                                              const Text(
                                                'Away game',
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  color: Colors.grey,
                                                ),
                                              )
                                            else ...[
                                              Text(
                                                '$hiredOfficials/$requiredOfficials Official(s)',
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  color: isFullyHired ? Colors.green : Colors.red,
                                                ),
                                              ),
                                              if (!isFullyHired) ...[
                                                const SizedBox(width: 8),
                                                const Icon(
                                                  Icons.warning_amber_rounded,
                                                  color: Colors.red,
                                                  size: 16,
                                                ),
                                              ],
                                            ],
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, '/select_schedule');
        },
        backgroundColor: efficialsBlue,
        child: const Icon(Icons.add, size: 30, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}