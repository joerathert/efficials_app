import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'theme.dart';
import 'utils.dart'; // For getSportIcon

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
  final String? opponent;
  final String status;

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
    this.opponent,
    required this.status,
  });

  factory Game.fromJson(Map<String, dynamic> json) {
    TimeOfDay? time;
    if (json['time'] != null) {
      if (json['time'] is String) {
        final parts = (json['time'] as String).split(':');
        time = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
      } else if (json['time'] is TimeOfDay) {
        time = json['time'] as TimeOfDay;
      }
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
      opponent: json['opponent'] as String?,
      status: json['status'] as String? ?? 'Unpublished',
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
        'opponent': opponent,
        'status': status,
      };
}

class CoachHomeScreen extends StatefulWidget {
  const CoachHomeScreen({Key? key}) : super(key: key);

  @override
  _CoachHomeScreenState createState() => _CoachHomeScreenState();
}

class _CoachHomeScreenState extends State<CoachHomeScreen> {
  String? teamName;
  List<Game> games = [];
  bool isLoading = true;
  bool isFabExpanded = false;

  @override
  void initState() {
    super.initState();
    _checkTeamSetup();
  }

  Future<void> _checkTeamSetup() async {
    final prefs = await SharedPreferences.getInstance();
    final teamSetupCompleted = prefs.getBool('team_setup_completed') ?? false;
    final savedTeamName = prefs.getString('team_name');
    setState(() {
      teamName = savedTeamName ?? 'Team';
      isLoading = false;
    });

    if (!teamSetupCompleted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacementNamed(context, '/select_team');
      });
    } else {
      _loadGames();
    }
  }

  Future<void> _loadGames() async {
    final prefs = await SharedPreferences.getInstance();
    final String? gamesJson = prefs.getString('published_games');
    setState(() {
      if (gamesJson != null && gamesJson.isNotEmpty) {
        try {
          final List<Map<String, dynamic>> allGames =
              List<Map<String, dynamic>>.from(jsonDecode(gamesJson));
          games = allGames
              .map(Game.fromJson)
              .where((game) =>
                  game.opponent == teamName || game.scheduleName.contains(teamName!))
              .toList();
          games.sort((a, b) {
            if (a.date == null && b.date == null) return 0;
            if (a.date == null) return 1;
            if (b.date == null) return -1;
            DateTime aDateTime = a.date!;
            DateTime bDateTime = b.date!;
            if (a.time != null) {
              aDateTime = DateTime(
                  aDateTime.year, aDateTime.month, aDateTime.day, a.time!.hour, a.time!.minute);
            }
            if (b.time != null) {
              bDateTime = DateTime(
                  bDateTime.year, bDateTime.month, bDateTime.day, b.time!.hour, b.time!.minute);
            }
            return aDateTime.compareTo(bDateTime);
          });
        } catch (e) {
          print('Error loading games: $e');
          games = [];
        }
      } else {
        games = [];
      }
      isLoading = false;
    });
  }

  Future<Map<String, dynamic>?> _fetchGameById(int gameId) async {
    final prefs = await SharedPreferences.getInstance();
    final String? gamesJson = prefs.getString('published_games');
    if (gamesJson != null && gamesJson.isNotEmpty) {
      try {
        final List<Map<String, dynamic>> games =
            List<Map<String, dynamic>>.from(jsonDecode(gamesJson));
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

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        body: Center(child: CircularProgressIndicator(color: efficialsBlue)),
      );
    }

    final double statusBarHeight = MediaQuery.of(context).padding.top;
    const double appBarHeight = kToolbarHeight;
    final double totalBannerHeight = statusBarHeight + appBarHeight;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: efficialsBlue,
        title: Text('', style: appBarTextStyle),
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
              height: totalBannerHeight, // Match AppBar height including status bar
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
                  style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            ListTile(
              leading: Icon(Icons.schedule),
              title: Text('Team Schedule'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Team Schedule not implemented yet')),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.settings),
              title: Text('Settings'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Settings not implemented yet')),
                );
              },
            ),
          ],
        ),
      ),
      body: Stack(
        children: [
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  SizedBox(height: 10),
                  Expanded(
                    child: games.isEmpty
                        ? Center(
                            child: Text(
                              'Click the "+" icon to get started.',
                              style: homeTextStyle,
                              textAlign: TextAlign.center,
                            ),
                          )
                        : ListView.builder(
                            itemCount: games.length,
                            itemBuilder: (context, index) {
                              final game = games[index];
                              return _buildGameTile(game);
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
          if (isFabExpanded)
            GestureDetector(
              onTap: () {
                setState(() {
                  isFabExpanded = false;
                });
              },
              child: AnimatedOpacity(
                opacity: isFabExpanded ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 300),
                child: Container(
                  color: Colors.black.withOpacity(0.3),
                  width: double.infinity,
                  height: double.infinity,
                ),
              ),
            ),
          Positioned(
            bottom: 16,
            right: 16,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                AnimatedOpacity(
                  opacity: isFabExpanded ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 300),
                  child: Visibility(
                    visible: isFabExpanded,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: FloatingActionButton.extended(
                        onPressed: () {
                          setState(() {
                            isFabExpanded = false;
                          });
                          Navigator.pushNamed(context, '/game_templates');
                        },
                        backgroundColor: Colors.blue[300],
                        label: const Text('Use Game Template', style: TextStyle(color: Colors.white)),
                        icon: const Icon(Icons.copy, color: Colors.white),
                      ),
                    ),
                  ),
                ),
                AnimatedOpacity(
                  opacity: isFabExpanded ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 300),
                  child: Visibility(
                    visible: isFabExpanded,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: FloatingActionButton.extended(
                        onPressed: () {
                          setState(() {
                            isFabExpanded = false;
                          });
                          Navigator.pushNamed(context, '/select_schedule', arguments: {'teamName': teamName});
                        },
                        backgroundColor: Colors.white,
                        label: const Text('Start from Scratch', style: TextStyle(color: efficialsBlue)),
                        icon: const Icon(Icons.add, color: efficialsBlue),
                      ),
                    ),
                  ),
                ),
                FloatingActionButton(
                  onPressed: () {
                    setState(() {
                      isFabExpanded = !isFabExpanded;
                    });
                  },
                  backgroundColor: efficialsBlue,
                  child: Icon(isFabExpanded ? Icons.close : Icons.add, size: 30, color: Colors.white),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGameTile(Game game) {
    final gameTitle = game.scheduleName;
    final gameDate = game.date != null ? DateFormat('EEEE, MMM d, yyyy').format(game.date!) : 'Not set';
    final gameTime = game.time != null ? game.time!.format(context) : 'Not set';
    final requiredOfficials = game.officialsRequired;
    final hiredOfficials = game.officialsHired;
    final isFullyHired = hiredOfficials >= requiredOfficials;
    final sport = game.sport;
    final sportIcon = getSportIcon(sport);
    final isAway = game.isAway;

    return GestureDetector(
      onTap: () async {
        final gameId = game.id;
        final latestGame = await _fetchGameById(gameId);
        if (latestGame == null) {
          print('Error: Could not fetch game with ID $gameId');
          return;
        }
        Navigator.pushNamed(context, '/game_information', arguments: latestGame).then((result) async {
          if (result == true) {
            await _loadGames();
          } else if (result != null && result is Map<String, dynamic>) {
            final prefs = await SharedPreferences.getInstance();
            final String? gamesJson = prefs.getString('published_games');
            if (gamesJson != null && gamesJson.isNotEmpty) {
              List<Map<String, dynamic>> updatedGames =
                  List<Map<String, dynamic>>.from(jsonDecode(gamesJson));
              final index = updatedGames.indexWhere((g) => g['id'] == game.id);
              if (index != -1) {
                updatedGames[index] = {
                  ...updatedGames[index],
                  ...result,
                  'date': result['date'] is String
                      ? result['date']
                      : (result['date'] as DateTime?)?.toIso8601String(),
                  'time': result['time'] is String
                      ? result['time']
                      : result['time'] != null
                          ? '${(result['time'] as TimeOfDay).hour}:${(result['time'] as TimeOfDay).minute}'
                          : null,
                };
                await prefs.setString('published_games', jsonEncode(updatedGames));
                await _loadGames();
              }
            }
          } else if (result != null && (result as Map<String, dynamic>)['refresh'] == true) {
            await _loadGames();
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
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text('$gameTime - $gameTitle',
                          style: const TextStyle(fontSize: 16, color: Colors.black)),
                      const SizedBox(width: 8),
                      Icon(sportIcon, color: efficialsBlue, size: 24),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (isAway)
                        const Text('Away game', style: TextStyle(fontSize: 14, color: Colors.grey))
                      else ...[
                        Text('$hiredOfficials/$requiredOfficials Official(s)',
                            style: TextStyle(fontSize: 14, color: isFullyHired ? Colors.green : Colors.red)),
                        if (!isFullyHired) ...[
                          const SizedBox(width: 8),
                          const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 16),
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
  }
}