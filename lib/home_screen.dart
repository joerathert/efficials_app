import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'theme.dart';
import 'schedule_filter_screen.dart';
import 'game_template.dart';

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

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Game> publishedGames = [];
  List<String> existingSchedules = [];
  bool isLoading = true;
  bool showAwayGames = true;
  bool showFullyCoveredGames = true;
  Map<String, Map<String, bool>> scheduleFilters = {};

  @override
  void initState() {
    super.initState();
    _fetchGames();
    _loadFilters();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args != null && args is Map<String, dynamic> && args['refresh'] == true) {
      _fetchGames(); // Force refresh when returning with 'refresh' flag
    }
  }

  Future<void> _fetchGames() async {
    final prefs = await SharedPreferences.getInstance();
    final String? gamesJson = prefs.getString('published_games');
    final String? unpublishedGamesJson = prefs.getString('unpublished_games');

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
              .toList();
          print('Fetched publishedGames: $publishedGames'); // Debug log
        } catch (e) {
          publishedGames = [];
          print('Error loading published games: $e');
        }
      } else {
        publishedGames = [];
      }
      isLoading = false;
    });

    await _initializeScheduleFilters();
  }

  Future<void> _loadFilters() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      showAwayGames = prefs.getBool('showAwayGames') ?? true;
      showFullyCoveredGames = prefs.getBool('showFullyCoveredGames') ?? true;

      final String? scheduleFiltersJson = prefs.getString('scheduleFilters');
      if (scheduleFiltersJson != null && scheduleFiltersJson.isNotEmpty) {
        final Map<String, dynamic> decodedFilters = jsonDecode(scheduleFiltersJson);
        scheduleFilters = decodedFilters.map((sport, schedules) => MapEntry(
              sport,
              (schedules as Map<String, dynamic>).map((schedule, selected) => MapEntry(schedule, selected as bool)),
            ));
      }
    });
  }

  Future<void> _initializeScheduleFilters() async {
    final prefs = await SharedPreferences.getInstance();
    final String? gamesJson = prefs.getString('published_games');
    final String? unpublishedGamesJson = prefs.getString('unpublished_games');

    List<Game> allGames = [];
    if (gamesJson != null && gamesJson.isNotEmpty) {
      try {
        final published = List<Map<String, dynamic>>.from(jsonDecode(gamesJson));
        allGames.addAll(published.map(Game.fromJson));
      } catch (e) {
        print('Error loading published games for filters: $e');
      }
    }
    if (unpublishedGamesJson != null && unpublishedGamesJson.isNotEmpty) {
      try {
        final unpublished = List<Map<String, dynamic>>.from(jsonDecode(unpublishedGamesJson));
        allGames.addAll(unpublished.map(Game.fromJson));
      } catch (e) {
        print('Error loading unpublished games for filters: $e');
      }
    }

    final Map<String, Map<String, bool>> newScheduleFilters = {};
    for (var game in allGames) {
      if (!newScheduleFilters.containsKey(game.sport)) {
        newScheduleFilters[game.sport] = {};
      }
      if (!newScheduleFilters[game.sport]!.containsKey(game.scheduleName)) {
        newScheduleFilters[game.sport]![game.scheduleName] = true;
      }
    }

    if (newScheduleFilters.isNotEmpty && (scheduleFilters.isEmpty || _hasNewSchedules(newScheduleFilters))) {
      setState(() {
        scheduleFilters = newScheduleFilters;
      });
      await _saveFilters();
    }
  }

  bool _hasNewSchedules(Map<String, Map<String, bool>> newFilters) {
    for (var sport in newFilters.keys) {
      if (!scheduleFilters.containsKey(sport)) return true;
      for (var schedule in newFilters[sport]!.keys) {
        if (!scheduleFilters[sport]!.containsKey(schedule)) return true;
      }
    }
    return false;
  }

  Future<void> _saveFilters() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('showAwayGames', showAwayGames);
    await prefs.setBool('showFullyCoveredGames', showFullyCoveredGames);
    await prefs.setString('scheduleFilters', jsonEncode(scheduleFilters));
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

  List<Game> _filterGames(List<Game> games) {
    var filteredGames = games.where((game) {
      if (!showAwayGames && game.isAway) return false;
      if (!showFullyCoveredGames && game.officialsHired >= game.officialsRequired) return false;
      if (scheduleFilters.containsKey(game.sport) && scheduleFilters[game.sport]!.containsKey(game.scheduleName)) {
        return scheduleFilters[game.sport]![game.scheduleName]!;
      }
      return false;
    }).toList();

    filteredGames.sort((a, b) {
      if (a.date == null && b.date == null) return 0;
      if (a.date == null) return 1;
      if (b.date == null) return -1;

      DateTime aDateTime = a.date!;
      DateTime bDateTime = b.date!;

      if (a.time != null) {
        aDateTime = DateTime(
          aDateTime.year,
          aDateTime.month,
          aDateTime.day,
          a.time!.hour,
          a.time!.minute,
        );
      } else {
        aDateTime = DateTime(aDateTime.year, aDateTime.month, aDateTime.day);
      }

      if (b.time != null) {
        bDateTime = DateTime(
          bDateTime.year,
          bDateTime.month,
          bDateTime.day,
          b.time!.hour,
          b.time!.minute,
        );
      } else {
        bDateTime = DateTime(bDateTime.year, bDateTime.month, bDateTime.day);
      }

      return aDateTime.compareTo(bDateTime);
    });

    return filteredGames;
  }

  Future<GameTemplate?> _showTemplateSelectionDialog() async {
    final prefs = await SharedPreferences.getInstance();
    final String? templatesJson = prefs.getString('game_templates');
    if (templatesJson == null || templatesJson.isEmpty) {
      return null;
    }

    final List<dynamic> decoded = jsonDecode(templatesJson);
    final List<GameTemplate> templates = decoded.map((json) => GameTemplate.fromJson(json)).toList();

    if (templates.isEmpty) {
      return null;
    }

    return await showDialog<GameTemplate>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Use a Game Template?'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Would you like to use a game template?'),
              const SizedBox(height: 10),
              ...templates.map((template) => ListTile(
                    title: Text(template.name),
                    onTap: () => Navigator.pop(context, template),
                  )),
              ListTile(
                title: const Text('No, create a new game from scratch'),
                onTap: () => Navigator.pop(context, null),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double statusBarHeight = MediaQuery.of(context).padding.top;
    const double appBarHeight = kToolbarHeight;
    final double totalBannerHeight = statusBarHeight + appBarHeight;

    final filteredPublishedGames = _filterGames(publishedGames);

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
                  if (result == true) {
                    _fetchGames();
                  }
                });
              },
            ),
            ListTile(
              leading: const Icon(Icons.filter_list),
              title: const Text('Filter Schedules'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ScheduleFilterScreen(
                      scheduleFilters: scheduleFilters,
                      showAwayGames: showAwayGames,
                      showFullyCoveredGames: showFullyCoveredGames,
                      onFiltersChanged: (updatedFilters, away, fullyCovered) {
                        setState(() {
                          scheduleFilters = updatedFilters;
                          showAwayGames = away;
                          showFullyCoveredGames = fullyCovered;
                        });
                        _saveFilters();
                      },
                    ),
                  ),
                );
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
              leading: const Icon(Icons.copy),
              title: const Text('Game Templates'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/game_templates');
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
          child: Column(
            children: [
              const SizedBox(height: 10),
              Expanded(
                child: isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : filteredPublishedGames.isEmpty
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
                            itemCount: filteredPublishedGames.length,
                            itemBuilder: (context, index) {
                              final game = filteredPublishedGames[index];
                              return _buildGameTile(game);
                            },
                          ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final selectedTemplate = await _showTemplateSelectionDialog();
          Navigator.pushNamed(
            context,
            '/select_schedule',
            arguments: {'template': selectedTemplate},
          );
        },
        backgroundColor: efficialsBlue,
        child: const Icon(Icons.add, size: 30, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget _buildGameTile(Game game) {
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
        print('Navigating to GameInformationScreen with game: $latestGame');
        Navigator.pushNamed(
          context,
          '/game_information',
          arguments: latestGame,
        ).then((result) async {
          print('Returned from GameInformationScreen with result: $result');
          if (result == true) {
            print('Result is true, refreshing games');
            await _fetchGames();
          } else if (result != null && result is Map<String, dynamic>) {
            print('Result is Map, updating game: $result');
            final prefs = await SharedPreferences.getInstance();
            final String? gamesJson = prefs.getString('published_games');
            if (gamesJson != null && gamesJson.isNotEmpty) {
              List<Map<String, dynamic>> updatedGames = List<Map<String, dynamic>>.from(jsonDecode(gamesJson));
              final index = updatedGames.indexWhere((g) => g['id'] == game.id);
              if (index != -1) {
                // Ensure all fields are updated, including date and time
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
                print('Updated SharedPreferences with: ${updatedGames[index]}');
                // Force UI refresh after update
                await _fetchGames();
              } else {
                print('Game with ID $gameId not found in SharedPreferences');
              }
            } else {
              print('No published games found in SharedPreferences');
            }
            print('Games refreshed');
          } else if (result != null && (result as Map<String, dynamic>)['refresh'] == true) {
            print('Refresh flag detected, refreshing games');
            await _fetchGames();
          } else {
            print('Unexpected result type or null: $result');
          }
          print('Navigation callback completed');
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
                        '$gameTime - $gameTitle',
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
  }
}