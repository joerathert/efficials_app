import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../shared/theme.dart';
import '../../shared/utils/utils.dart'; // For getSportIcon

class Game {
  final int id;
  final String? scheduleName;
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
    this.scheduleName,
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
        time =
            TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
      } else if (json['time'] is TimeOfDay) {
        time = json['time'] as TimeOfDay;
      }
    }
    return Game(
      id: json['id'] as int,
      scheduleName: json['scheduleName'] as String?,
      date:
          json['date'] != null ? DateTime.parse(json['date'] as String) : null,
      time: time,
      sport: json['sport'] as String? ?? 'Unknown Sport',
      officialsRequired:
          int.parse(json['officialsRequired']?.toString() ?? '0'),
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
  String? sport;
  String? grade;
  String? gender;
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
    final savedSport = prefs.getString('sport');
    final savedGrade = prefs.getString('grade');
    final savedGender = prefs.getString('gender');

    setState(() {
      teamName = savedTeamName ?? 'Team';
      sport = savedSport;
      grade = savedGrade;
      gender = savedGender;
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
    final String? gamesJson = prefs.getString('coach_published_games');
    setState(() {
      if (gamesJson != null && gamesJson.isNotEmpty) {
        try {
          final List<Map<String, dynamic>> allGames =
              List<Map<String, dynamic>>.from(jsonDecode(gamesJson));
          games = allGames
              .map(Game.fromJson)
              .where((game) =>
                  game.opponent == teamName ||
                  (game.scheduleName != null &&
                      game.scheduleName!.contains(teamName!)))
              .toList();
          games.sort((a, b) {
            if (a.date == null && b.date == null) return 0;
            if (a.date == null) return 1;
            if (b.date == null) return -1;
            DateTime aDateTime = a.date!;
            DateTime bDateTime = b.date!;
            if (a.time != null) {
              aDateTime = DateTime(aDateTime.year, aDateTime.month,
                  aDateTime.day, a.time!.hour, a.time!.minute);
            }
            if (b.time != null) {
              bDateTime = DateTime(bDateTime.year, bDateTime.month,
                  bDateTime.day, b.time!.hour, b.time!.minute);
            }
            return aDateTime.compareTo(bDateTime);
          });
        } catch (e) {
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
    final String? gamesJson = prefs.getString('coach_published_games');
    if (gamesJson != null && gamesJson.isNotEmpty) {
      try {
        final List<Map<String, dynamic>> games =
            List<Map<String, dynamic>>.from(jsonDecode(gamesJson));
        final game =
            games.firstWhere((g) => g['id'] == gameId, orElse: () => {});
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
            game['selectedOfficials'] = (game['selectedOfficials']
                    as List<dynamic>)
                .map((official) => Map<String, dynamic>.from(official as Map))
                .toList();
          }
          return game;
        }
      } catch (e) {
        // Handle parsing errors
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: efficialsBlue)),
      );
    }

    final double statusBarHeight = MediaQuery.of(context).padding.top;
    const double appBarHeight = kToolbarHeight;
    final double totalBannerHeight = statusBarHeight + appBarHeight;

    return Scaffold(
      backgroundColor: darkBackground,
      appBar: AppBar(
        backgroundColor: efficialsBlack,
        title: const Text('', style: appBarTextStyle),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, color: efficialsYellow),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
      ),
      drawer: Drawer(
        backgroundColor: Colors.grey[800],
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            Container(
              height: totalBannerHeight,
              decoration: const BoxDecoration(color: efficialsBlack),
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
                      color: efficialsWhite,
                      fontSize: 20,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.calendar_month, color: efficialsYellow),
              title: const Text('Team Schedule', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/team_schedule');
              },
            ),
            ListTile(
              leading: const Icon(Icons.games, color: efficialsYellow),
              title: const Text('Unpublished Games',
                  style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/unpublished_games').then((result) {
                  if (result == true) {
                    // Refresh the games list when returning from unpublished games
                    _loadGames();
                  }
                });
              },
            ),
            ListTile(
              leading: const Icon(Icons.location_on, color: efficialsYellow),
              title: const Text('Locations',
                  style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/locations');
              },
            ),
            ListTile(
              leading: const Icon(Icons.people, color: efficialsYellow),
              title: const Text('Lists of Officials',
                  style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/lists_of_officials');
              },
            ),
            ListTile(
              leading: const Icon(Icons.copy, color: efficialsYellow),
              title: const Text('Game Templates',
                  style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/sport_templates', arguments: {'sport': sport});
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings, color: efficialsYellow),
              title: const Text('Settings', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/settings');
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Team Info Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: darkSurface,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          spreadRadius: 1,
                          blurRadius: 3,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Icon(
                          getSportIcon(sport ?? ''),
                          color: getSportIconColor(sport ?? ''),
                          size: 32,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                teamName ?? 'Team',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: efficialsWhite,
                                ),
                              ),
                              Text(
                                '${grade ?? ''} ${gender ?? ''} ${sport ?? ''}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: secondaryTextColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Upcoming Games',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: efficialsWhite,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: games.isEmpty
                        ? const Center(
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
                          Navigator.pushNamed(context, '/select_game_template',
                              arguments: {
                                'sport': sport,
                              });
                        },
                        backgroundColor: efficialsYellow,
                        label: const Text('Use Game Template',
                            style: TextStyle(color: efficialsBlack)),
                        icon: const Icon(Icons.copy, color: efficialsBlack),
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
                        onPressed: () async {
                          setState(() {
                            isFabExpanded = false;
                          });
                          Navigator.pushNamed(context, '/date_time',
                              arguments: {
                                'teamName': teamName,
                                'sport': sport,
                                'grade': grade,
                                'gender': gender,
                              });
                        },
                        backgroundColor: efficialsYellow,
                        label: const Text('Start from Scratch',
                            style: TextStyle(color: efficialsBlack)),
                        icon: const Icon(Icons.add, color: efficialsBlack),
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
                  backgroundColor: efficialsYellow,
                  child: Icon(isFabExpanded ? Icons.close : Icons.add,
                      size: 30, color: efficialsBlack),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGameTile(Game game) {
    final gameTitle = game.scheduleName ?? 'Not set';
    final gameDate = game.date != null
        ? DateFormat('EEEE, MMM d, yyyy').format(game.date!)
        : 'Not set';
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
          return;
        }
        if (mounted) {
          Navigator.pushNamed(context, '/game_information', arguments: latestGame)
              .then((result) async {
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
                  await prefs.setString(
                      'published_games', jsonEncode(updatedGames));
                  await _loadGames();
                }
              }
            } else if (result != null &&
                (result as Map<String, dynamic>)['refresh'] == true) {
              await _loadGames();
            }
          });
        }
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
                        color: efficialsWhite),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text('$gameTime - $gameTitle',
                          style: const TextStyle(
                              fontSize: 16, color: efficialsWhite)),
                      const SizedBox(width: 8),
                      Icon(sportIcon,
                          color: getSportIconColor(sport), size: 24),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (isAway)
                        const Text('Away game',
                            style: TextStyle(fontSize: 14, color: Colors.grey))
                      else ...[
                        Text('$hiredOfficials/$requiredOfficials Official(s)',
                            style: TextStyle(
                                fontSize: 14,
                                color:
                                    isFullyHired ? Colors.green : Colors.red)),
                        if (!isFullyHired) ...[
                          const SizedBox(width: 8),
                          const Icon(Icons.warning_amber_rounded,
                              color: Colors.red, size: 16),
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
