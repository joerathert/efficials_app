import 'package:flutter/material.dart';
import '../../shared/theme.dart';
import '../../shared/utils/utils.dart';
import '../../shared/services/user_session_service.dart';
import '../../shared/services/repositories/user_repository.dart';
import '../../shared/services/repositories/notification_repository.dart';
import '../../shared/services/game_service.dart';
import '../../shared/widgets/scheduler_bottom_navigation.dart';

class AssignerHomeScreen extends StatefulWidget {
  const AssignerHomeScreen({super.key});

  @override
  State<AssignerHomeScreen> createState() => _AssignerHomeScreenState();
}

class _AssignerHomeScreenState extends State<AssignerHomeScreen>
    with TickerProviderStateMixin {
  String? sport;
  String? leagueName;
  bool isLoading = true;
  int _currentIndex = 0;
  int _unreadNotificationCount = 0;
  int _unpublishedGamesCount = 0;
  List<Map<String, dynamic>> _gamesNeedingOfficials = [];

  // Animation controllers
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;
  bool _isExpanded = false;

  final NotificationRepository _notificationRepo = NotificationRepository();
  final UserRepository _userRepository = UserRepository();
  final GameService _gameService = GameService();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _slideAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    _fadeAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    _initializeAssignerHome();
  }

  Future<void> _initializeAssignerHome() async {
    await Future.wait([
      _checkAssignerSetup(),
      _loadUnreadNotificationCount(),
      _loadUnpublishedGamesCount(),
      _loadGamesNeedingOfficials(),
    ]);
  }

  Future<void> _checkAssignerSetup() async {
    debugPrint('Checking assigner setup from database');
    try {
      // Get current user directly from UserRepository
      final currentUser = await _userRepository.getCurrentUser();

      if (currentUser == null) {
        debugPrint('No current user found, redirecting to welcome');
        if (mounted) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.pushReplacementNamed(context, '/welcome');
          });
        }
        return;
      }

      debugPrint(
          'Current user: ${currentUser.email}, setupCompleted: ${currentUser.setupCompleted}');

      // Load sport and league from user record
      if (mounted) {
        setState(() {
          sport = currentUser.sport;
          leagueName = currentUser.leagueName ?? 'League';
          isLoading = false;
        });
      }

      // Redirect if setup not completed
      if (!currentUser.setupCompleted) {
        debugPrint('Setup not completed, redirecting to sport selection');
        if (mounted) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.pushReplacementNamed(
                context, '/assigner_sport_selection');
          });
        }
      }
    } catch (e) {
      debugPrint('Error checking assigner setup: $e');
      if (mounted) {
        setState(() {
          isLoading = false;
        });
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Navigator.pushReplacementNamed(context, '/welcome');
        });
      }
    }
  }

  Future<void> _loadUnreadNotificationCount() async {
    try {
      final currentUser = await _userRepository.getCurrentUser();
      if (currentUser != null) {
        final count =
            await _notificationRepo.getUnreadNotificationCount(currentUser.id!);
        if (mounted) {
          setState(() {
            _unreadNotificationCount = count;
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading unread notification count: $e');
    }
  }

  Future<void> _loadUnpublishedGamesCount() async {
    try {
      final unpublishedGames = await _gameService.getUnpublishedGames();
      if (mounted) {
        setState(() {
          _unpublishedGamesCount = unpublishedGames.length;
        });
      }
    } catch (e) {
      debugPrint('Error loading unpublished games count: $e');
    }
  }

  Future<void> _loadGamesNeedingOfficials() async {
    debugPrint('🏠 _loadGamesNeedingOfficials() STARTING');
    try {
      debugPrint('🏠 About to call _gameService.getPublishedGames()');
      final games = await _gameService.getPublishedGames();
      debugPrint('🏠 Got ${games.length} games from getPublishedGames()');
      
      // Debug: Print all games to see what we're getting
      debugPrint('🏠 All published games (${games.length}):');
      for (final game in games) {
        debugPrint('  Game ${game.id}: opponent="${game.opponent}", date=${game.date}, hired=${game.officialsHired}/${game.officialsRequired}, method="${game.method}"');
      }
      
      final gamesNeedingOfficials = games.where((game) {
        final needsOfficials = game.officialsHired < game.officialsRequired;
        final hasDate = game.date != null;
        final isFuture = hasDate && game.date!.isAfter(DateTime.now());
        
        // Debug: Show filtering decision for each game
        if (hasDate) {
          debugPrint('🏠 Game ${game.id} filtering: needsOfficials=$needsOfficials, hasDate=$hasDate, isFuture=$isFuture (${game.date})');
        }
        
        return needsOfficials && hasDate && isFuture;
      }).toList();

      gamesNeedingOfficials.sort((a, b) => a.date!.compareTo(b.date!));

      debugPrint('🏠 About to set state with ${gamesNeedingOfficials.length} games');
      
      if (mounted) {
        setState(() {
          _gamesNeedingOfficials = gamesNeedingOfficials.map((game) {
            // Debug: Print the game data to see what we're getting
            debugPrint(
                'Game ${game.id}: homeTeam=${game.homeTeam}, scheduleHomeTeamName=${game.scheduleHomeTeamName}, scheduleName=${game.scheduleName}');

            return {
              'id': game.id,
              'opponent': game.opponent ?? 'TBD',
              'homeTeam':
                  game.scheduleHomeTeamName ?? game.homeTeam ?? 'Home Team',
              'scheduleName': game.scheduleName ?? 'Unknown Schedule',
              'date': game.date,
              'time': game.time,
              'sport': game.sportName ?? 'Unknown',
              'location': game.locationName ?? 'TBD',
              'officialsRequired': game.officialsRequired,
              'officialsHired': game.officialsHired,
              'isAway': game.isAway,
            };
          }).toList();
          
          debugPrint('🏠 Final _gamesNeedingOfficials list has ${_gamesNeedingOfficials.length} games:');
          for (final game in _gamesNeedingOfficials) {
            debugPrint('  - Game ${game['id']}: ${game['opponent']} on ${game['date']}');
          }
        });
      }
    } catch (e, stackTrace) {
      debugPrint('🏠 ERROR in _loadGamesNeedingOfficials: $e');
      debugPrint('🏠 Stack trace: $stackTrace');
    }
    debugPrint('🏠 _loadGamesNeedingOfficials() FINISHED');
  }

  void _toggleExpandedView() {
    setState(() {
      _isExpanded = !_isExpanded;
    });
    if (_isExpanded) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }
  }

  void _navigateToFullScheduleView() {
    Navigator.pushNamed(context, '/assigner_manage_schedules');
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onBottomNavTap(int index) {
    switch (index) {
      case 0: // Home - already on home screen, do nothing
        break;
      case 1: // Schedules
        Navigator.pushNamed(context, '/assigner_manage_schedules').then((_) {
          // Refresh games needing officials when returning from schedules
          _loadUnpublishedGamesCount();
          _loadGamesNeedingOfficials();
        });
        break;
      case 2: // Officials/Crews Choice
        Navigator.pushNamed(context, '/officials_crews_choice').then((_) {
          // Refresh games needing officials when returning from choice screen
          _loadUnpublishedGamesCount();
          _loadGamesNeedingOfficials();
        });
        break;
      case 3: // Templates (Game Templates)
        Navigator.pushNamed(context, '/game_templates').then((_) {
          // Refresh games needing officials when returning from templates screen
          _loadUnpublishedGamesCount();
          _loadGamesNeedingOfficials();
        });
        break;
      case 4: // Notifications
        Navigator.pushNamed(context, '/backout_notifications').then((_) {
          // Refresh notification count and games when returning from notifications screen
          _loadUnreadNotificationCount();
          _loadUnpublishedGamesCount();
          _loadGamesNeedingOfficials();
        });
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        backgroundColor: darkBackground,
        body: Center(child: CircularProgressIndicator(color: efficialsYellow)),
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
              leading: const Icon(Icons.sports, color: efficialsYellow),
              title: const Text('Officials Assignment',
                  style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content:
                          Text('Officials Assignment not implemented yet')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.schedule, color: efficialsYellow),
              title: const Text('Manage Schedules',
                  style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/assigner_manage_schedules')
                    .then((_) {
                  _loadUnpublishedGamesCount();
                  _loadGamesNeedingOfficials();
                });
              },
            ),
            ListTile(
              leading: const Icon(Icons.unpublished, color: efficialsYellow),
              title: Row(
                children: [
                  const Text('Unpublished Games',
                      style: TextStyle(color: Colors.white)),
                  if (_unpublishedGamesCount > 0) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.orange,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '$_unpublishedGamesCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/unpublished_games').then((_) {
                  _loadUnpublishedGamesCount(); // Refresh count after returning
                  _loadGamesNeedingOfficials();
                });
              },
            ),
            ListTile(
              leading: const Icon(Icons.people, color: efficialsYellow),
              title: const Text('Manage Officials',
                  style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/officials_crews_choice').then((_) {
                  _loadUnpublishedGamesCount();
                  _loadGamesNeedingOfficials();
                });
              },
            ),
            ListTile(
              leading: const Icon(Icons.copy, color: efficialsYellow),
              title: const Text('Game Templates',
                  style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/game_templates').then((_) {
                  _loadUnpublishedGamesCount();
                  _loadGamesNeedingOfficials();
                });
              },
            ),
            ListTile(
              leading: const Icon(Icons.location_on, color: efficialsYellow),
              title: const Text('Manage Locations',
                  style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/locations');
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings, color: efficialsYellow),
              title: const Text('Game Defaults',
                  style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/assigner_sport_defaults');
              },
            ),
            ListTile(
              leading: const Icon(Icons.upload_file, color: efficialsYellow),
              title: const Text('Bulk Import Games',
                  style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/bulk_import_preflight');
              },
            ),
            const Divider(color: Colors.grey),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Logout', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _handleLogout();
              },
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: GestureDetector(
          onPanUpdate: (details) {
            // Detect upward swipe
            if (details.delta.dy < -2 && !_isExpanded) {
              _toggleExpandedView();
            }
            // Detect downward swipe when expanded
            else if (details.delta.dy > 2 && _isExpanded) {
              _toggleExpandedView();
            }
          },
          onTap: () {
            if (_isExpanded) {
              _navigateToFullScheduleView();
            }
          },
          child: AnimatedBuilder(
            animation: _slideAnimation,
            builder: (context, child) {
              return Stack(
                children: [
                  // Main home content
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: Transform.translate(
                      offset: Offset(
                          0,
                          -MediaQuery.of(context).size.height *
                              0.4 *
                              _slideAnimation.value),
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // League Info Card
                              FadeTransition(
                                opacity: _fadeAnimation,
                                child: Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: efficialsYellow,
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.3),
                                        spreadRadius: 1,
                                        blurRadius: 3,
                                        offset: const Offset(0, 1),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(
                                            getSportIcon(sport ?? ''),
                                            color: efficialsBlack,
                                            size: 32,
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  leagueName ?? 'League',
                                                  style: const TextStyle(
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.bold,
                                                    color: efficialsBlack,
                                                  ),
                                                ),
                                                Text(
                                                  '${sport ?? 'Unknown'} Assigner',
                                                  style: const TextStyle(
                                                    fontSize: 14,
                                                    color: efficialsBlack,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 30),

                              // Quick Actions Section
                              FadeTransition(
                                opacity: _fadeAnimation,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Quick Actions',
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: _buildActionCard(
                                            icon: Icons.calendar_today,
                                            title: 'Manage Schedules',
                                            onTap: () {
                                              Navigator.pushNamed(context,
                                                      '/assigner_manage_schedules')
                                                  .then((_) {
                                                _loadGamesNeedingOfficials();
                                              });
                                            },
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: _buildActionCard(
                                            icon: Icons.people,
                                            title: 'Manage Officials',
                                            onTap: () {
                                              Navigator.pushNamed(context,
                                                      '/officials_crews_choice')
                                                  .then((_) {
                                                _loadGamesNeedingOfficials();
                                              });
                                            },
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: _buildActionCard(
                                            icon: Icons.copy,
                                            title: 'Game Templates',
                                            onTap: () {
                                              Navigator.pushNamed(context,
                                                      '/game_templates')
                                                  .then((_) {
                                                _loadGamesNeedingOfficials();
                                              });
                                            },
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: _buildActionCard(
                                            icon: Icons.notifications,
                                            title: 'Notifications',
                                            onTap: () {
                                              Navigator.pushNamed(context,
                                                      '/backout_notifications')
                                                  .then((_) {
                                                _loadGamesNeedingOfficials();
                                              });
                                            },
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 30),

                              // Games Needing Officials Section
                              FadeTransition(
                                opacity: _fadeAnimation,
                                child: _buildGamesNeedingOfficialsSection(),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Overlay hint for expanded state
                  if (_isExpanded)
                    Positioned(
                      bottom: 50,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: efficialsYellow.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            'Tap to open full schedule view',
                            style: TextStyle(
                              color: efficialsBlack,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
      bottomNavigationBar: SchedulerBottomNavigation(
        currentIndex: _currentIndex,
        onTap: _onBottomNavTap,
        schedulerType: SchedulerType.assigner,
        unreadNotificationCount: _unreadNotificationCount,
      ),
    );
  }

  Widget _buildGamesNeedingOfficialsSection() {
    debugPrint('🏠 _buildGamesNeedingOfficialsSection called with ${_gamesNeedingOfficials.length} games');
    if (_gamesNeedingOfficials.isEmpty) {
      debugPrint('🏠 Games list is empty, showing empty state');
      // Check if there are any upcoming games at all
      final now = DateTime.now();
      final hasUpcomingGames = _gameService.getPublishedGames().then((games) {
        return games
            .any((game) => game.date != null && game.date!.isAfter(now));
      }).catchError((_) => false);

      return FutureBuilder<bool>(
        future: hasUpcomingGames,
        builder: (context, snapshot) {
          final hasGames = snapshot.data ?? false;

          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: hasGames
                  ? Colors.green.withOpacity(0.1)
                  : efficialsBlue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: hasGames
                      ? Colors.green.withOpacity(0.3)
                      : efficialsBlue.withOpacity(0.3)),
            ),
            child: Column(
              children: [
                Icon(
                  hasGames ? Icons.check_circle : Icons.calendar_today,
                  color: hasGames ? Colors.green : efficialsBlue,
                  size: 48,
                ),
                const SizedBox(height: 12),
                Text(
                  hasGames ? 'All Games Covered!' : 'No Upcoming Games',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: hasGames ? Colors.green : efficialsBlue,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  hasGames
                      ? 'All upcoming games have the necessary number of officials confirmed.'
                      : 'You have no games scheduled for future dates.',
                  style: const TextStyle(
                    fontSize: 14,
                    color: secondaryTextColor,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        },
      );
    }

    debugPrint('🏠 Games list is NOT empty, showing ${_gamesNeedingOfficials.length} games');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Games Needing Officials',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: primaryTextColor,
          ),
        ),
        const SizedBox(height: 16),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _gamesNeedingOfficials.length,
          itemBuilder: (context, index) {
            return _buildGameNeedingOfficialsCard(_gamesNeedingOfficials[index]);
          },
        ),
      ],
    );
  }

  Widget _buildGameNeedingOfficialsCard(Map<String, dynamic> game) {
    final date = game['date'] as DateTime?;
    final time = game['time'] as TimeOfDay?;
    final officialsNeeded = game['officialsRequired'] - game['officialsHired'];

    String dateText = 'TBD';
    if (date != null) {
      dateText = '${date.month}/${date.day}/${date.year}';
      if (time != null) {
        // Format time as 9:00 AM/PM instead of 09:00
        final hour =
            time.hour == 0 ? 12 : (time.hour > 12 ? time.hour - 12 : time.hour);
        final minute = time.minute.toString().padLeft(2, '0');
        final period = time.hour >= 12 ? 'PM' : 'AM';
        final timeText = '$hour:$minute $period';
        dateText += ' at $timeText';
      }
    }

    return GestureDetector(
      onTap: () {
        // Navigate to game information screen
        Navigator.pushNamed(
          context,
          '/game_information',
          arguments: {
            'id': game['id'],
            'sport': game['sport'],
            'sportName': game['sport'],
            'opponent': game['opponent'],
            'date': date,
            'time': time,
            'location': game['location'],
            'locationName': game['location'],
            'officialsRequired': game['officialsRequired'],
            'officialsHired': game['officialsHired'],
            'isAway': game['isAway'],
            'sourceScreen': 'assigner_home',
          },
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: darkSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.orange.withOpacity(0.3)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              spreadRadius: 1,
              blurRadius: 3,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  getSportIcon(game['sport']),
                  color: efficialsYellow,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        game['isAway']
                            ? '${game['homeTeam']} @ ${game['opponent']}'
                            : '${game['opponent']} @ ${game['homeTeam']}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: primaryTextColor,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        game['scheduleName'],
                        style: const TextStyle(
                          fontSize: 12,
                          color: secondaryTextColor,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Need $officialsNeeded',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              dateText,
              style: const TextStyle(
                fontSize: 14,
                color: secondaryTextColor,
              ),
            ),
            if (game['location'] != 'TBD') ...[
              const SizedBox(height: 4),
              Text(
                game['location'],
                style: const TextStyle(
                  fontSize: 14,
                  color: secondaryTextColor,
                ),
              ),
            ],
            const SizedBox(height: 8),
            Text(
              '${game['officialsHired']} of ${game['officialsRequired']} officials confirmed',
              style: const TextStyle(
                fontSize: 12,
                color: secondaryTextColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: darkSurface,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              spreadRadius: 1,
              blurRadius: 3,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              icon,
              color: efficialsYellow,
              size: 28,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: primaryTextColor,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 12,
                  color: secondaryTextColor,
                ),
              ),
            ],
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
              child: const Text('Cancel',
                  style: TextStyle(color: secondaryTextColor)),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context); // Close dialog

                // Clear user session
                await UserSessionService.instance.clearSession();

                if (mounted) {
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    '/welcome',
                    (route) => false,
                  ); // Go to welcome screen and clear navigation stack
                }
              },
              child: const Text('Logout', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }
}
