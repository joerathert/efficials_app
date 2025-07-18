import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../shared/theme.dart';
import '../schedules/schedule_filter_screen.dart';
import '../games/game_template.dart';
import '../../shared/utils/utils.dart';
import '../../shared/services/game_service.dart';
import 'dart:developer' as developer;

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

class AthleticDirectorHomeScreen extends StatefulWidget {
  const AthleticDirectorHomeScreen({super.key});

  @override
  State<AthleticDirectorHomeScreen> createState() =>
      _AthleticDirectorHomeScreenState();
}

class _AthleticDirectorHomeScreenState
    extends State<AthleticDirectorHomeScreen> {
  List<Game> publishedGames = [];
  List<String> existingSchedules = [];
  bool isLoading = true;
  bool showAwayGames = true;
  bool showFullyCoveredGames = true;
  Map<String, Map<String, bool>> scheduleFilters = {};
  bool isFabExpanded = false;
  bool showPastGames = false;
  bool isPullingDown = false;
  double pullDistance = 0.0;
  static const double pullThreshold = 80.0;
  ScrollController scrollController = ScrollController();
  final GameService _gameService = GameService();

  @override
  void initState() {
    super.initState();
    _fetchGames();
    _loadFilters();
  }

  @override
  void dispose() {
    scrollController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args != null &&
        args is Map<String, dynamic> &&
        args['refresh'] == true) {
      _fetchGames();
    }
    // Reset pull state when navigating to home screen
    _resetPullState();
  }

  void _resetPullState() {
    setState(() {
      showPastGames = false;
      isPullingDown = false;
      pullDistance = 0.0;
    });
    // Reset scroll position
    if (scrollController.hasClients) {
      scrollController.jumpTo(0);
    }
  }

  void _scrollToFirstUpcomingGame() {
    if (scrollController.hasClients) {
      try {
        final upcomingGames = _filterGamesByTime(publishedGames, false);
        final pastGames = _filterGamesByTime(publishedGames, true);
        final estimatedOffset =
            pastGames.length * 150.0; // Conservative height estimate
        scrollController.jumpTo(estimatedOffset.clamp(
            0.0, scrollController.position.maxScrollExtent));
      } catch (e) {
        // Handle scroll errors
      }
    }
  }

  Future<void> _fetchGames() async {
    try {
      // Try to get games from database first
      final publishedGamesData = await _gameService.getFilteredGames(
        showAwayGames: showAwayGames,
        showFullyCoveredGames: showFullyCoveredGames,
        scheduleFilters: scheduleFilters,
        status: 'Published',
      );
      
      final unpublishedGamesData = await _gameService.getUnpublishedGames();
      
      // Extract schedule names from all games
      Set<String> scheduleNames = {};
      for (var game in [...publishedGamesData, ...unpublishedGamesData]) {
        final scheduleName = game['scheduleName'];
        if (scheduleName != null) {
          scheduleNames.add(scheduleName as String);
        }
      }
      existingSchedules = scheduleNames.toList();
      
      setState(() {
        publishedGames = publishedGamesData.map(Game.fromJson).toList();
        isLoading = false;
      });
    } catch (e) {
      // Fallback to SharedPreferences if database fails
      await _fetchGamesFromPrefs();
    }

    await _initializeScheduleFilters();
  }

  Future<void> _fetchGamesFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final String? gamesJson = prefs.getString('ad_published_games');
    final String? unpublishedGamesJson =
        prefs.getString('ad_unpublished_games');

    Set<String> scheduleNames = {};
    if (unpublishedGamesJson != null && unpublishedGamesJson.isNotEmpty) {
      final unpublished =
          List<Map<String, dynamic>>.from(jsonDecode(unpublishedGamesJson));
      for (var game in unpublished) {
        final scheduleName = game['scheduleName'];
        if (scheduleName != null) {
          scheduleNames.add(scheduleName as String);
        }
      }
    }
    if (gamesJson != null && gamesJson.isNotEmpty) {
      final published = List<Map<String, dynamic>>.from(jsonDecode(gamesJson));
      for (var game in published) {
        final scheduleName = game['scheduleName'];
        if (scheduleName != null) {
          scheduleNames.add(scheduleName as String);
        }
      }
    }
    existingSchedules = scheduleNames.toList();

    setState(() {
      if (gamesJson != null && gamesJson.isNotEmpty) {
        try {
          publishedGames =
              List<Map<String, dynamic>>.from(jsonDecode(gamesJson))
                  .map(Game.fromJson)
                  .toList();
        } catch (e) {
          publishedGames = [];
        }
      } else {
        publishedGames = [];
      }
      isLoading = false;
    });
  }

  Future<void> _loadFilters() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      showAwayGames = prefs.getBool('showAwayGames') ?? true;
      showFullyCoveredGames = prefs.getBool('showFullyCoveredGames') ?? true;

      final String? scheduleFiltersJson = prefs.getString('scheduleFilters');
      if (scheduleFiltersJson != null && scheduleFiltersJson.isNotEmpty) {
        final Map<String, dynamic> decodedFilters =
            jsonDecode(scheduleFiltersJson);
        scheduleFilters = decodedFilters.map((sport, schedules) => MapEntry(
              sport,
              (schedules as Map<String, dynamic>).map(
                  (schedule, selected) => MapEntry(schedule, selected as bool)),
            ));
      }
    });
  }

  Future<void> _initializeScheduleFilters() async {
    final prefs = await SharedPreferences.getInstance();
    final String? gamesJson = prefs.getString('ad_published_games');
    final String? unpublishedGamesJson =
        prefs.getString('ad_unpublished_games');

    List<Game> allGames = [];
    if (gamesJson != null && gamesJson.isNotEmpty) {
      try {
        final published =
            List<Map<String, dynamic>>.from(jsonDecode(gamesJson));
        allGames.addAll(published.map(Game.fromJson));
      } catch (e) {
        // Handle parsing errors
      }
    }
    if (unpublishedGamesJson != null && unpublishedGamesJson.isNotEmpty) {
      try {
        final unpublished =
            List<Map<String, dynamic>>.from(jsonDecode(unpublishedGamesJson));
        allGames.addAll(unpublished.map(Game.fromJson));
      } catch (e) {
        // Handle parsing errors
      }
    }

    final Map<String, Map<String, bool>> newScheduleFilters = {};
    for (var game in allGames) {
      if (game.scheduleName == null) {
        continue; // Skip games without a schedule name
      }
      if (!newScheduleFilters.containsKey(game.sport)) {
        newScheduleFilters[game.sport] = {};
      }
      if (!newScheduleFilters[game.sport]!.containsKey(game.scheduleName)) {
        newScheduleFilters[game.sport]![game.scheduleName!] = true;
      }
    }

    if (newScheduleFilters.isNotEmpty &&
        (scheduleFilters.isEmpty || _hasNewSchedules(newScheduleFilters))) {
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
    final String? gamesJson = prefs.getString('ad_published_games');
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

  List<Game> _filterGamesByTime(List<Game> games, bool getPastGames) {
    final now = DateTime.now();
    // Create a DateTime at the start of today (midnight) for date comparison
    final today = DateTime(now.year, now.month, now.day);

    var filteredGames = games.where((game) {
      if (!showAwayGames && game.isAway) return false;
      if (!showFullyCoveredGames &&
          game.officialsHired >= game.officialsRequired) {
        return false;
      }
      if (game.scheduleName == null) return false;

      // Filter by past/upcoming
      if (game.date != null) {
        final gameDate =
            DateTime(game.date!.year, game.date!.month, game.date!.day);
        final isPastGame = gameDate.isBefore(today);
        if (getPastGames && !isPastGame) return false;
        if (!getPastGames && isPastGame) return false;
      }

      if (scheduleFilters.containsKey(game.sport) &&
          scheduleFilters[game.sport]!.containsKey(game.scheduleName!)) {
        return scheduleFilters[game.sport]![game.scheduleName!]!;
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
        aDateTime = DateTime(aDateTime.year, aDateTime.month, aDateTime.day,
            a.time!.hour, a.time!.minute);
      } else {
        aDateTime = DateTime(aDateTime.year, aDateTime.month, aDateTime.day);
      }

      if (b.time != null) {
        bDateTime = DateTime(bDateTime.year, bDateTime.month, bDateTime.day,
            b.time!.hour, b.time!.minute);
      } else {
        bDateTime = DateTime(bDateTime.year, bDateTime.month, bDateTime.day);
      }

      return aDateTime.compareTo(bDateTime);
    });

    return filteredGames;
  }

  Widget _buildGamesList(List<Game> pastGames, List<Game> upcomingGames) {
    if (upcomingGames.isEmpty && pastGames.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Transform.translate(
                offset: const Offset(0, -80),
                child: Column(
                  children: [
                    const Icon(
                      Icons.sports,
                      size: 80,
                      color: efficialsYellow,
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Welcome to Efficials!',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: efficialsYellow,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Get started by adding your first game to manage schedules and officials.',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton.icon(
                      onPressed: () {
                        setState(() {
                          isFabExpanded = true;
                        });
                      },
                      icon: const Icon(Icons.add_circle_outline, size: 24),
                      label: const Text(
                        'Add Your First Game',
                        style: TextStyle(fontSize: 18),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: efficialsYellow,
                        foregroundColor: efficialsBlack,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (!showPastGames) {
      if (upcomingGames.isEmpty) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Transform.translate(
                  offset: const Offset(0, -80),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.event_available,
                        size: 80,
                        color: efficialsYellow,
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'No Upcoming Games',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: efficialsYellow,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Add a new game to start managing your schedule.',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),
                      ElevatedButton.icon(
                        onPressed: () {
                          setState(() {
                            isFabExpanded = true;
                          });
                        },
                        icon: const Icon(Icons.add_circle_outline, size: 24),
                        label: const Text(
                          'Add New Game',
                          style: TextStyle(fontSize: 18),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: efficialsYellow,
                          foregroundColor: efficialsBlack,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 16,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      }
      return ListView.builder(
        controller: scrollController,
        itemCount: upcomingGames.length,
        itemBuilder: (context, index) {
          final game = upcomingGames[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: _buildGameTile(game),
          );
        },
      );
    } else {
      return ListView.builder(
        controller: scrollController,
        itemCount: pastGames.length + upcomingGames.length,
        itemBuilder: (context, index) {
          if (index >= pastGames.length) {
            final upcomingIndex = index - pastGames.length;
            final game = upcomingGames[upcomingIndex];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: _buildGameTile(game),
            );
          } else {
            final game = pastGames[pastGames.length - 1 - index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: _buildGameTile(game),
            );
          }
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final double statusBarHeight = MediaQuery.of(context).padding.top;
    const double appBarHeight = kToolbarHeight;
    final double totalBannerHeight = statusBarHeight + appBarHeight;

    final upcomingGames = _filterGamesByTime(publishedGames, false);
    final pastGames = _filterGamesByTime(publishedGames, true);

    return Scaffold(
      backgroundColor: darkBackground,
      appBar: AppBar(
        backgroundColor: efficialsBlack,
        title: (upcomingGames.isNotEmpty || pastGames.isNotEmpty) 
          ? const Icon(
              Icons.sports,
              color: efficialsYellow,
              size: 32,
            )
          : null,
        elevation: 0,
        centerTitle: true,
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
                    right: 16.0),
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
              leading: const Icon(Icons.schedule, color: efficialsYellow),
              title: const Text('Schedules',
                  style: TextStyle(color: Colors.white)),
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
              leading: const Icon(Icons.filter_list, color: efficialsYellow),
              title: const Text('Filter Schedules',
                  style: TextStyle(color: Colors.white)),
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
              leading: const Icon(Icons.games, color: efficialsYellow),
              title: const Text('Unpublished Games',
                  style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/unpublished_games').then((result) {
                  if (result == true) {
                    // Refresh the games list when returning from unpublished games
                    _fetchGames();
                  }
                });
              },
            ),
            ListTile(
              leading: const Icon(Icons.copy, color: efficialsYellow),
              title: const Text('Game Templates',
                  style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/game_templates');
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings, color: efficialsYellow),
              title: const Text('Settings',
                  style: TextStyle(color: Colors.white)),
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
            child: GestureDetector(
              onPanUpdate: (details) {
                if (details.delta.dy > 0) {
                  setState(() {
                    pullDistance = (pullDistance + details.delta.dy)
                        .clamp(0.0, pullThreshold * 1.5);
                    isPullingDown = pullDistance > 10;
                  });
                }
              },
              onPanEnd: (details) {
                if (pullDistance >= pullThreshold && !showPastGames) {
                  _onShowPastGames();
                } else {
                  setState(() {
                    pullDistance = 0.0;
                    isPullingDown = false;
                  });
                }
              },
              child: Column(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    height: pullDistance > 0
                        ? pullDistance.clamp(0.0, pullThreshold)
                        : 0,
                    child: pullDistance > 0
                        ? Container(
                            width: double.infinity,
                            color: darkBackground,
                            child: Center(
                              child: Text(
                                pullDistance >= pullThreshold
                                    ? 'Release to view past games'
                                    : 'View past games',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: pullDistance >= pullThreshold
                                      ? efficialsBlue
                                      : secondaryTextColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          )
                        : null,
                  ),
                  Flexible(
                    fit: FlexFit.loose,
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (!showPastGames && upcomingGames.isNotEmpty) ...[
                            const Text(
                              'Upcoming Games',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: primaryTextColor,
                              ),
                            ),
                            const SizedBox(height: 10),
                          ],
                          Expanded(
                            child: isLoading
                                ? const Center(
                                    child: CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        efficialsBlue),
                                  ))
                                : _buildGamesList(pastGames, upcomingGames),
                          ),
                        ],
                      ),
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
                  color: efficialsBlack.withOpacity(0.3),
                  width: double.infinity,
                  height: double.infinity,
                ),
              ),
            ),
          Positioned(
            bottom: MediaQuery.of(context).padding.bottom + 16,
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
                        onPressed: () {
                          setState(() {
                            isFabExpanded = false;
                          });
                          Navigator.pushNamed(context, '/select_schedule',
                              arguments: {'template': null});
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
                  backgroundColor: Colors.grey[800],
                  child: Icon(isFabExpanded ? Icons.close : Icons.add,
                      size: 30, color: efficialsYellow),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _onShowPastGames() {
    setState(() {
      showPastGames = true;
      pullDistance = 0.0;
      isPullingDown = false;
    });

    // Ensure layout is complete and adjust scroll position
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (scrollController.hasClients) {
        final pastGames = _filterGamesByTime(publishedGames, true);
        final upcomingGames = _filterGamesByTime(publishedGames, false);
        if (upcomingGames.isNotEmpty) {
          // Calculate the index where upcoming games start
          final firstUpcomingIndex = pastGames.length;
          // Estimate the height of each game tile (adjust based on actual measurement)
          const double estimatedTileHeight = 160.0; // Current estimate
          // Initial target offset
          double targetOffset = firstUpcomingIndex * estimatedTileHeight;
          // Get initial max scroll extent
          final initialMaxScrollExtent =
              scrollController.position.maxScrollExtent;
          developer.log(
              'Initial Target Offset: $targetOffset, Initial Max Scroll Extent: $initialMaxScrollExtent, Total Items: ${pastGames.length + upcomingGames.length}');

          // If maxScrollExtent is too small, delay and retry with a longer wait
          if (targetOffset > initialMaxScrollExtent) {
            Future.delayed(const Duration(milliseconds: 300), () {
              if (scrollController.hasClients) {
                final updatedMaxScrollExtent =
                    scrollController.position.maxScrollExtent;
                targetOffset = firstUpcomingIndex *
                    estimatedTileHeight.clamp(0.0, updatedMaxScrollExtent);
                developer.log(
                    'Adjusted Target Offset: $targetOffset, Updated Max Scroll Extent: $updatedMaxScrollExtent, Total Items: ${pastGames.length + upcomingGames.length}');
                scrollController
                    .jumpTo(targetOffset.clamp(0.0, updatedMaxScrollExtent));
              }
            });
          } else {
            scrollController
                .jumpTo(targetOffset.clamp(0.0, initialMaxScrollExtent));
          }
        }
      }
    });
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
    final opponent = game.opponent;
    final opponentDisplay =
        opponent != null ? (isAway ? '@ $opponent' : 'vs $opponent') : null;

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
              await _fetchGames();
            } else if (result != null && result is Map<String, dynamic>) {
              final prefs = await SharedPreferences.getInstance();
              final String? gamesJson = prefs.getString('ad_published_games');
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
                      'ad_published_games', jsonEncode(updatedGames));
                  await _fetchGames();
                }
              }
            } else if (result != null &&
                (result as Map<String, dynamic>)['refresh'] == true) {
              await _fetchGames();
            }
          });
        }
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: darkSurface,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: efficialsGray.withOpacity(0.2),
              spreadRadius: 1,
              blurRadius: 3,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: efficialsYellow.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                sportIcon,
                color: efficialsYellow,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    gameDate,
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: primaryTextColor),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    opponentDisplay != null
                        ? '$gameTime $opponentDisplay'
                        : '$gameTime - $gameTitle',
                    style:
                        const TextStyle(fontSize: 16, color: primaryTextColor),
                  ),
                  if (opponentDisplay != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      gameTitle,
                      style: const TextStyle(
                          fontSize: 14,
                          color: secondaryTextColor,
                          fontWeight: FontWeight.w500),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      if (isAway)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: efficialsYellow.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'Away game',
                            style:
                                TextStyle(fontSize: 12, color: efficialsYellow),
                          ),
                        )
                      else ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: isFullyHired
                                ? efficialsYellow.withOpacity(0.2)
                                : efficialsBlue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '$hiredOfficials/$requiredOfficials Officials',
                                style: TextStyle(
                                    fontSize: 12,
                                    color: isFullyHired
                                        ? efficialsBlack
                                        : efficialsBlue),
                              ),
                              if (!isFullyHired) ...[
                                const SizedBox(width: 4),
                                const Icon(
                                  Icons.warning_amber_rounded,
                                  color: efficialsYellow,
                                  size: 14,
                                ),
                              ],
                            ],
                          ),
                        ),
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
