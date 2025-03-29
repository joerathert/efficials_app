import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'theme.dart';

// Immutable Game class with better null safety
class Game {
  final int id;
  final String scheduleName;
  final DateTime date; // Non-nullable with default
  final TimeOfDay time; // Non-nullable with default
  final String sport;
  final int officialsRequired;
  final int officialsHired;
  final bool isAway;
  final List<Map<String, dynamic>> selectedOfficials;

  Game({
    required this.id,
    required this.scheduleName,
    DateTime? date,
    TimeOfDay? time,
    required this.sport,
    required this.officialsRequired,
    required this.officialsHired,
    this.isAway = false,
    this.selectedOfficials = const [],
  })  : date = date ?? DateTime.now(),
        time = time ?? const TimeOfDay(hour: 0, minute: 0);

  factory Game.fromJson(Map<String, dynamic> json) {
    final timeStr = json['time'] as String? ?? '00:00';
    final parts = timeStr.split(':');
    final time = TimeOfDay(
      hour: int.parse(parts[0]),
      minute: int.parse(parts.length > 1 ? parts[1] : '0'),
    );

    return Game(
      id: json['id'] as int? ?? 0,
      scheduleName: json['scheduleName'] as String? ?? 'Unnamed Schedule',
      date: json['date'] != null ? DateTime.parse(json['date'] as String) : null,
      time: time,
      sport: json['sport'] as String? ?? 'Unknown Sport',
      officialsRequired: int.parse(json['officialsRequired']?.toString() ?? '0'),
      officialsHired: json['officialsHired'] as int? ?? 0,
      isAway: json['isAway'] as bool? ?? false,
      selectedOfficials: (json['selectedOfficials'] as List<dynamic>?)
              ?.map((e) => Map<String, dynamic>.from(e as Map))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'scheduleName': scheduleName,
        'date': date.toIso8601String(),
        'time': '${time.hour}:${time.minute}',
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
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? gamesJson = prefs.getString('published_games');
      final String? unpublishedGamesJson = prefs.getString('unpublished_games');

      // Fetch existing schedules
      final scheduleNames = <String>{};
      if (unpublishedGamesJson != null && unpublishedGamesJson.isNotEmpty) {
        final unpublished = List<Map<String, dynamic>>.from(jsonDecode(unpublishedGamesJson));
        scheduleNames.addAll(unpublished.map((game) => game['scheduleName'] as String));
      }
      if (gamesJson != null && gamesJson.isNotEmpty) {
        final published = List<Map<String, dynamic>>.from(jsonDecode(gamesJson));
        scheduleNames.addAll(published.map((game) => game['scheduleName'] as String));
      }
      existingSchedules = scheduleNames.toList();

      setState(() {
        publishedGames = gamesJson != null && gamesJson.isNotEmpty
            ? List<Map<String, dynamic>>.from(jsonDecode(gamesJson))
                .map(Game.fromJson)
                .where((game) => existingSchedules.contains(game.scheduleName))
                .toList()
            : [];
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        publishedGames = [];
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading games: $e')),
      );
    }
  }

  Future<Game?> _fetchGameById(int gameId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? gamesJson = prefs.getString('published_games');
      if (gamesJson != null && gamesJson.isNotEmpty) {
        final games = List<Map<String, dynamic>>.from(jsonDecode(gamesJson));
        final gameJson = games.firstWhere((g) => g['id'] == gameId, orElse: () => {});
        if (gameJson.isNotEmpty) return Game.fromJson(gameJson);
      }
      return null;
    } catch (e) {
      print('Error fetching game by ID: $e');
      return null;
    }
  }

  IconData _getSportIcon(String sport) {
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
            DrawerHeader(
              decoration: const BoxDecoration(color: efficialsBlue),
              child: const Text(
                'Menu',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.schedule),
              title: const Text('Schedules'),
              onTap: () => Navigator.pushNamed(context, '/schedules')
                  .then((_) => _fetchPublishedGames()),
            ),
            ListTile(
              leading: const Icon(Icons.location_on),
              title: const Text('Locations'),
              onTap: () => Navigator.pushNamed(context, '/locations'),
            ),
            ListTile(
              leading: const Icon(Icons.people),
              title: const Text('Lists of Officials'),
              onTap: () => Navigator.pushNamed(context, '/lists_of_officials'),
            ),
            ListTile(
              leading: const Icon(Icons.games),
              title: const Text('Unpublished Games'),
              onTap: () => Navigator.pushNamed(context, '/unpublished_games'),
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
          child: isLoading
              ? const Center(child: CircularProgressIndicator())
              : publishedGames.isEmpty
                  ? const Center(
                      child: Text(
                        'Click the "+" icon to get started.',
                        style: homeTextStyle,
                        textAlign: TextAlign.center,
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _fetchPublishedGames,
                      child: ListView.builder(
                        itemCount: publishedGames.length,
                        itemBuilder: (context, index) {
                          final game = publishedGames[index];
                          final gameTitle = game.scheduleName;
                          final gameDate = DateFormat('EEEE, MMM d, yyyy').format(game.date);
                          final gameTime = game.time.format(context);
                          final requiredOfficials = game.officialsRequired;
                          final hiredOfficials = game.officialsHired;
                          final isFullyHired = hiredOfficials >= requiredOfficials;
                          final sportIcon = _getSportIcon(game.sport);

                          return GestureDetector(
                            onTap: () async {
                              final latestGame = await _fetchGameById(game.id);
                              if (latestGame == null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Game not found')),
                                );
                                return;
                              }
                              Navigator.pushNamed(context, '/game_information',
                                      arguments: latestGame.toJson())
                                  .then((result) async {
                                if (result == true) {
                                  _fetchPublishedGames();
                                } else if (result is Map<String, dynamic>) {
                                  setState(() {
                                    final index = publishedGames.indexWhere((g) => g.id == game.id);
                                    if (index != -1) {
                                      publishedGames[index] = Game.fromJson(result);
                                    }
                                  });
                                  final prefs = await SharedPreferences.getInstance();
                                  await prefs.setString(
                                      'published_games', jsonEncode(publishedGames.map((g) => g.toJson()).toList()));
                                  _fetchPublishedGames();
                                }
                              });
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8.0),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(sportIcon, color: efficialsBlue, size: 24),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(gameDate,
                                            style: const TextStyle(
                                                fontSize: 16, fontWeight: FontWeight.bold)),
                                        const SizedBox(height: 4),
                                        Text('$gameTime - $gameTitle (${game.sport})',
                                            style: const TextStyle(fontSize: 16)),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            if (game.isAway)
                                              const Text('Away game',
                                                  style: TextStyle(fontSize: 14, color: Colors.grey))
                                            else
                                              Text(
                                                '$hiredOfficials/$requiredOfficials Official(s)',
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  color: isFullyHired ? Colors.green : Colors.red,
                                                ),
                                              ),
                                            if (!game.isAway && !isFullyHired) ...[
                                              const SizedBox(width: 8),
                                              const Icon(Icons.warning_amber_rounded,
                                                  color: Colors.red, size: 16),
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
        onPressed: () => Navigator.pushNamed(context, '/select_schedule'),
        backgroundColor: efficialsBlue,
        child: const Icon(Icons.add, size: 30, color: Colors.white),
      ),
    );
  }
}