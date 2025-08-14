import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../shared/theme.dart';
import '../schedules/schedule_filter_screen.dart';
import '../games/game_template.dart';
import '../../shared/utils/utils.dart';
import '../../shared/services/game_service.dart';
import '../../shared/services/user_session_service.dart';
import '../../shared/services/repositories/notification_repository.dart';
import '../../shared/services/repositories/user_repository.dart';
import '../../shared/widgets/scheduler_bottom_navigation.dart';
import '../../shared/models/database_models.dart';
import 'dart:developer' as developer;

class AthleticDirectorHomeScreen extends StatefulWidget {
  const AthleticDirectorHomeScreen({super.key});

  @override
  State<AthleticDirectorHomeScreen> createState() =>
      _AthleticDirectorHomeScreenState();
}

class _AthleticDirectorHomeScreenState
    extends State<AthleticDirectorHomeScreen> with WidgetsBindingObserver {
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
  final NotificationRepository _notificationRepo = NotificationRepository();
  final UserRepository _userRepository = UserRepository();
  int _currentIndex = 0;
  int _unreadNotificationCount = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeData();
  }

  Future<void> _initializeData() async {
    _fetchGames();
    _loadFilters();
    _loadUnreadNotificationCount();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    scrollController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _fetchGames(); // Refresh data on app resume/hot restart
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args != null &&
        args is Map<String, dynamic> &&
        args['refresh'] == true) {
      // Use post frame callback to ensure the refresh happens after the navigation is complete
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _fetchGames();
      });
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

  Future<void> _loadUnreadNotificationCount() async {
    try {
      final currentUser = await UserSessionService.instance.getCurrentSchedulerUser();
      if (currentUser != null) {
        final count = await _notificationRepo.getUnreadNotificationCount(currentUser.id!);
        if (mounted) {
          setState(() {
            _unreadNotificationCount = count;
          });
        }
      }
    } catch (e) {
      // Handle error silently, badge will show 0
      print('Error loading unread notification count: $e');
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
      // Get games from database first
      final publishedGamesData = await _gameService.getFilteredGames(
        showAwayGames: showAwayGames,
        showFullyCoveredGames: showFullyCoveredGames,
        scheduleFilters: null, // Don't filter by schedule at database level initially
        status: 'Published',
      );
      
      final unpublishedGamesData = await _gameService.getUnpublishedGames();
      
      // Extract schedule names from all games
      Set<String> scheduleNames = {};
      for (var game in [...publishedGamesData, ...unpublishedGamesData]) {
        final scheduleName = game.scheduleName;
        if (scheduleName != null) {
          scheduleNames.add(scheduleName);
        }
      }
      existingSchedules = scheduleNames.toList();
      
      // Initialize schedule filters after getting games to ensure new games are included
      await _initializeScheduleFilters();
      
      setState(() {
        publishedGames = publishedGamesData; // No conversion needed - already Game objects
        isLoading = false;
        
        // Debug logging to understand what's happening with games
        developer.log('Published games loaded: ${publishedGames.length}');
        for (var game in publishedGames) {
          developer.log('Game: id=${game.id}, scheduleName=${game.scheduleName}, sportName=${game.sportName}, opponent=${game.opponent}, isAway=${game.isAway}, date=${game.date}');
        }
      });
    } catch (e) {
      developer.log('Error fetching games from database: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading games: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      setState(() {
        publishedGames = [];
        isLoading = false;
      });
    }
  }


  Future<void> _loadFilters() async {
    try {
      final currentUser = await UserSessionService.instance.getCurrentSchedulerUser();
      if (currentUser == null) return;
      
      final userId = currentUser.id!;
      
      setState(() {
        // Load filters from database settings
      });
      
      // Load filters asynchronously
      final awayGames = await _userRepository.getBoolSetting(userId, 'showAwayGames', defaultValue: true);
      final fullyCovered = await _userRepository.getBoolSetting(userId, 'showFullyCoveredGames', defaultValue: true);
      final scheduleFiltersJson = await _userRepository.getSetting(userId, 'scheduleFilters');
      
      Map<String, Map<String, bool>> loadedScheduleFilters = {};
      if (scheduleFiltersJson != null && scheduleFiltersJson.isNotEmpty) {
        try {
          final Map<String, dynamic> decodedFilters = jsonDecode(scheduleFiltersJson);
          loadedScheduleFilters = decodedFilters.map((sport, schedules) => MapEntry(
                sport,
                (schedules as Map<String, dynamic>).map(
                    (schedule, selected) => MapEntry(schedule, selected as bool)),
              ));
        } catch (e) {
          developer.log('Error parsing schedule filters: $e');
        }
      }
      
      if (mounted) {
        setState(() {
          showAwayGames = awayGames;
          showFullyCoveredGames = fullyCovered;
          scheduleFilters = loadedScheduleFilters;
        });
      }
    } catch (e) {
      developer.log('Error loading filters from database: $e');
      // Keep default values
    }
  }

  Future<void> _initializeScheduleFilters() async {
    try {
      // Get all games (published and unpublished) from database
      final publishedGamesData = await _gameService.getPublishedGames();
      final unpublishedGamesData = await _gameService.getUnpublishedGames();
      
      List<Game> allGames = [];
      allGames.addAll(publishedGamesData); // Already Game objects
      allGames.addAll(unpublishedGamesData); // Already Game objects
      
      final Map<String, Map<String, bool>> newScheduleFilters = {};
      for (var game in allGames) {
        if (game.scheduleName == null) {
          continue; // Skip games without a schedule name
        }
        
        final baseSportName = game.sportName ?? 'Unknown Sport';
        String sportKey = baseSportName;
        
        // For basketball, use gender-specific sport names
        if (baseSportName.toLowerCase() == 'basketball' && game.gender != null) {
          if (game.gender!.toLowerCase() == 'boys' || game.gender!.toLowerCase() == 'male') {
            sportKey = 'Boys Basketball';
          } else if (game.gender!.toLowerCase() == 'girls' || game.gender!.toLowerCase() == 'female') {
            sportKey = 'Girls Basketball';
          }
        }
        
        if (!newScheduleFilters.containsKey(sportKey)) {
          newScheduleFilters[sportKey] = {};
        }
        if (!newScheduleFilters[sportKey]!.containsKey(game.scheduleName)) {
          newScheduleFilters[sportKey]![game.scheduleName!] = true;
        }
      }

      // Only update if we found new schedules or filters are completely empty
      if (newScheduleFilters.isNotEmpty &&
          (scheduleFilters.isEmpty || _hasNewSchedules(newScheduleFilters))) {
        
        // Merge with existing filters to preserve user selections
        final Map<String, Map<String, bool>> mergedFilters = Map.from(scheduleFilters);
        
        newScheduleFilters.forEach((sport, schedules) {
          if (!mergedFilters.containsKey(sport)) {
            mergedFilters[sport] = {};
          }
          schedules.forEach((schedule, defaultValue) {
            if (!mergedFilters[sport]!.containsKey(schedule)) {
              mergedFilters[sport]![schedule] = defaultValue;
            }
          });
        });
        
        setState(() {
          scheduleFilters = mergedFilters;
        });
        await _saveFilters();
      }
    } catch (e) {
      developer.log('Error initializing schedule filters: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error initializing filters: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
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
    try {
      final currentUser = await UserSessionService.instance.getCurrentSchedulerUser();
      if (currentUser == null) return;
      
      final userId = currentUser.id!;
      
      await _userRepository.setSetting(userId, 'showAwayGames', showAwayGames.toString());
      await _userRepository.setSetting(userId, 'showFullyCoveredGames', showFullyCoveredGames.toString());
      await _userRepository.setSetting(userId, 'scheduleFilters', jsonEncode(scheduleFilters));
    } catch (e) {
      developer.log('Error saving filters to database: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving filters: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<Map<String, dynamic>?> _fetchGameById(int gameId) async {
    try {
      // Get game from database with officials data
      final game = await _gameService.getGameByIdWithOfficials(gameId);
      return game;
    } catch (e) {
      developer.log('Error fetching game by ID: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading game details: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return null;
    }
  }

  List<Game> _filterGamesByTime(List<Game> games, bool getPastGames, {bool applyScheduleFilters = true}) {
    final now = DateTime.now();
    // Create a DateTime at the start of today (midnight) for date comparison
    final today = DateTime(now.year, now.month, now.day);
    
    developer.log('Filtering ${games.length} games, getPastGames: $getPastGames');

    var filteredGames = games.where((game) {
      if (!showAwayGames && game.isAway) return false;
      if (!showFullyCoveredGames &&
          game.officialsHired >= game.officialsRequired) {
        return false;
      }
      // Don't filter out games with null schedule names immediately - they might be new games
      // The schedule filter logic below will handle this properly

      // Filter by past/upcoming
      if (game.date != null) {
        final gameDate =
            DateTime(game.date!.year, game.date!.month, game.date!.day);
        final isPastGame = gameDate.isBefore(today);
        if (getPastGames && !isPastGame) return false;
        if (!getPastGames && isPastGame) return false;
      }

      // Apply schedule filters only if requested
      if (applyScheduleFilters) {
        if (scheduleFilters.isEmpty) {
          return true; // Show all games when no filters are set
        }
        
        final baseSportName = game.sportName ?? 'Unknown Sport';
        String sportKey = baseSportName;
        
        // For basketball, use gender-specific sport names to match filter keys
        if (baseSportName.toLowerCase() == 'basketball' && game.gender != null) {
          if (game.gender!.toLowerCase() == 'boys' || game.gender!.toLowerCase() == 'male') {
            sportKey = 'Boys Basketball';
          } else if (game.gender!.toLowerCase() == 'girls' || game.gender!.toLowerCase() == 'female') {
            sportKey = 'Girls Basketball';
          }
        }
        
        final scheduleName = game.scheduleName;
        
        // If game has no schedule name, hide it when filters are active
        if (scheduleName == null || scheduleName.isEmpty) {
          return false;
        }
        
        // If the game's sport/schedule combination is not in filters,
        // it might be a new game that wasn't included during filter initialization
        // Add it to filters and show it by default
        if (sportKey.isNotEmpty) {
          if (!scheduleFilters.containsKey(sportKey)) {
            scheduleFilters[sportKey] = {};
          }
          if (!scheduleFilters[sportKey]!.containsKey(scheduleName)) {
            scheduleFilters[sportKey]![scheduleName] = true;
            // Save the updated filters asynchronously
            _saveFilters();
          }
          return scheduleFilters[sportKey]![scheduleName]!;
        }
        
        // If game doesn't have proper sport info, hide it when filters are active
        return false;
      }
      
      // If not applying schedule filters, just return true (show all games)
      return true;
    }).toList();
    
    developer.log('After filtering: ${filteredGames.length} games remaining');

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
      // Check if there are any games at all vs games filtered out
      final bool hasAnyGames = publishedGames.isNotEmpty;
      
      if (!hasAnyGames) {
        // No games exist - show welcome message
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
      } else {
        // Games exist but are filtered out - show filter message
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
                      const Text(
                        'No Games Found',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: primaryTextColor,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'You have ${publishedGames.length} game${publishedGames.length == 1 ? '' : 's'} created, but ${publishedGames.length == 1 ? 'it is' : 'they are'} currently hidden by your filter settings.',
                        style: const TextStyle(
                          fontSize: 16,
                          color: secondaryTextColor,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),
                      ElevatedButton.icon(
                        onPressed: () {
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
                        icon: const Icon(Icons.filter_list, size: 24),
                        label: const Text(
                          'Adjust Filters',
                          style: TextStyle(fontSize: 18),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: efficialsBlue,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 16,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            // Reset all filters to show all games
                            scheduleFilters.forEach((sport, schedules) {
                              schedules.forEach((schedule, _) {
                                scheduleFilters[sport]![schedule] = true;
                              });
                            });
                            showAwayGames = true;
                            showFullyCoveredGames = true;
                          });
                          _saveFilters();
                        },
                        child: const Text(
                          'Show All Games',
                          style: TextStyle(
                            fontSize: 16,
                            color: efficialsYellow,
                            decoration: TextDecoration.underline,
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
    }

    if (!showPastGames) {
      if (upcomingGames.isEmpty) {
        // Check if there are upcoming games in the unfiltered list
        final unfilteredUpcomingGames = _filterGamesByTime(publishedGames, false, applyScheduleFilters: false);
        final bool hasUpcomingGamesFiltered = unfilteredUpcomingGames.isNotEmpty;
        
        if (hasUpcomingGamesFiltered) {
          // There are upcoming games but they're filtered out
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
                        const Text(
                          'No Upcoming Games Found',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: primaryTextColor,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'You have ${unfilteredUpcomingGames.length} upcoming game${unfilteredUpcomingGames.length == 1 ? '' : 's'}, but ${unfilteredUpcomingGames.length == 1 ? 'it is' : 'they are'} currently hidden by your filter settings.',
                          style: const TextStyle(
                            fontSize: 16,
                            color: secondaryTextColor,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 32),
                        ElevatedButton.icon(
                          onPressed: () {
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
                          icon: const Icon(Icons.filter_list, size: 24),
                          label: const Text(
                            'Adjust Filters',
                            style: TextStyle(fontSize: 18),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: efficialsBlue,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 16,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextButton(
                          onPressed: () {
                            setState(() {
                              // Reset all filters to show all games
                              scheduleFilters.forEach((sport, schedules) {
                                schedules.forEach((schedule, _) {
                                  scheduleFilters[sport]![schedule] = true;
                                });
                              });
                              showAwayGames = true;
                              showFullyCoveredGames = true;
                            });
                            _saveFilters();
                          },
                          child: const Text(
                            'Show All Games',
                            style: TextStyle(
                              fontSize: 16,
                              color: efficialsYellow,
                              decoration: TextDecoration.underline,
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
        } else {
          // No upcoming games exist at all
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
      }
      return ListView.builder(
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

  void _onBottomNavTap(int index) {
    if (index == _currentIndex) return;

    setState(() {
      _currentIndex = index;
    });

    switch (index) {
      case 0: // Home - stay on current screen
        break;
      case 1: // Schedules
        Navigator.pushNamed(context, '/schedules').then((result) {
          if (result == true) {
            _fetchGames();
          }
        });
        // Reset to home after navigation
        setState(() {
          _currentIndex = 0;
        });
        break;
      case 2: // Filter
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
        // Reset to home after navigation
        setState(() {
          _currentIndex = 0;
        });
        break;
      case 3: // Notifications
        Navigator.pushNamed(context, '/backout_notifications').then((_) {
          // Refresh notification count when returning from notifications screen
          _loadUnreadNotificationCount();
        });
        // Reset to home after navigation
        setState(() {
          _currentIndex = 0;
        });
        break;
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
            const Divider(color: Colors.grey),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Logout',
                  style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _handleLogout();
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
                        heroTag: "fab_use_template",
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
                        heroTag: "fab_start_scratch",
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
                  heroTag: "fab_main",
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
      bottomNavigationBar: SchedulerBottomNavigation(
        currentIndex: _currentIndex,
        onTap: _onBottomNavTap,
        schedulerType: SchedulerType.athleticDirector,
        unreadNotificationCount: _unreadNotificationCount,
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

          // If maxScrollExtent is too small, delay and retry with a longer wait
          if (targetOffset > initialMaxScrollExtent) {
            Future.delayed(const Duration(milliseconds: 300), () {
              if (scrollController.hasClients) {
                final updatedMaxScrollExtent =
                    scrollController.position.maxScrollExtent;
                targetOffset = firstUpcomingIndex *
                    estimatedTileHeight.clamp(0.0, updatedMaxScrollExtent);
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
    final sport = game.sportName ?? 'Unknown Sport';
    final sportIcon = getSportIcon(sport);
    final isAway = game.isAway;
    final opponent = game.opponent;
    
    // Restore exact previous working logic
    final opponentDisplay =
        opponent != null ? (isAway ? '@ $opponent' : 'vs $opponent') : null;

    return GestureDetector(
      onTap: () async {
        final gameId = game.id;
        if (gameId == null) return;
        final latestGame = await _fetchGameById(gameId);
        if (latestGame == null) {
          return;
        }
        if (mounted) {
          Navigator.pushNamed(context, '/game_information', arguments: {
            ...latestGame,
            'sourceScreen': 'athletic_director_home',
          })
              .then((result) async {
            // Always refresh from database after game information screen
            if (result == true || 
                (result != null && result is Map<String, dynamic>) ||
                (result != null && (result as Map<String, dynamic>)['refresh'] == true)) {
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
                    style: const TextStyle(fontSize: 16, color: primaryTextColor),
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
                        Builder(
                          builder: (context) {
                            // Check if game is within a week
                            final now = DateTime.now();
                            final isWithinWeek = game.date != null && 
                                game.date!.difference(now).inDays <= 7 && 
                                game.date!.isAfter(now.subtract(const Duration(days: 1)));
                            
                            // Determine background color
                            Color backgroundColor;
                            if (isFullyHired) {
                              backgroundColor = Colors.green;
                            } else if (isWithinWeek) {
                              backgroundColor = Colors.red.withOpacity(0.7);
                            } else {
                              backgroundColor = efficialsBlue.withOpacity(0.1);
                            }
                            
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: backgroundColor,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '$hiredOfficials/$requiredOfficials Officials',
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: isFullyHired || isWithinWeek
                                            ? Colors.white
                                            : efficialsBlue),
                                  ),
                                  if (isFullyHired) ...[
                                    const SizedBox(width: 4),
                                    const Icon(
                                      Icons.check_circle,
                                      color: Colors.white,
                                      size: 14,
                                    ),
                                  ] else if (isWithinWeek) ...[
                                    const SizedBox(width: 4),
                                    const Icon(
                                      Icons.warning_amber_rounded,
                                      color: efficialsYellow,
                                      size: 14,
                                    ),
                                  ],
                                ],
                              ),
                            );
                          },
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

  void _handleLogout() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: darkSurface,
          title: const Text(
            'Logout',
            style: TextStyle(color: primaryTextColor),
          ),
          content: const Text(
            'Are you sure you want to logout?',
            style: TextStyle(color: primaryTextColor),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: secondaryTextColor)),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context); // Close dialog
                
                // Clear user session
                await UserSessionService.instance.clearSession();
                
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/welcome',
                  (route) => false,
                ); // Go to welcome screen and clear navigation stack
              },
              child: const Text('Logout', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }
}
