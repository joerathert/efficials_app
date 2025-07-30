import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../shared/theme.dart';
import '../../shared/utils/utils.dart'; // For getSportIcon
import '../../shared/services/repositories/user_repository.dart';
import '../../shared/services/repositories/notification_repository.dart';
import '../../shared/services/game_service.dart';
import '../../shared/widgets/scheduler_bottom_navigation.dart';
import '../../shared/models/database_models.dart';

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
  int _currentIndex = 0;
  int _unreadNotificationCount = 0;
  
  // Services for database operations
  final GameService _gameService = GameService();
  final NotificationRepository _notificationRepo = NotificationRepository();
  final UserRepository _userRepo = UserRepository();

  @override
  void initState() {
    super.initState();
    _checkTeamSetup();
    _loadUnreadNotificationCount();
  }

  Future<void> _checkTeamSetup() async {
    try {
      // Get current user from UserRepository
      final currentUser = await _userRepo.getCurrentUser();
      
      if (currentUser == null) {
        // No user logged in, redirect to login
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Navigator.pushReplacementNamed(context, '/welcome');
        });
        return;
      }

      // Check if user setup is completed in database
      final teamSetupCompleted = currentUser.setupCompleted;

      setState(() {
        teamName = currentUser.teamName ?? 'Team';
        sport = currentUser.sport;
        grade = currentUser.grade;
        gender = currentUser.gender;
        isLoading = false;
      });

      if (!teamSetupCompleted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Navigator.pushReplacementNamed(context, '/select_team');
        });
      } else {
        _loadGames();
      }
    } catch (e) {
      // Handle error
      setState(() {
        isLoading = false;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacementNamed(context, '/welcome');
      });
    }
  }

  Future<void> _loadUnreadNotificationCount() async {
    try {
      final currentUser = await _userRepo.getCurrentUser();
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
      debugPrint('Error loading unread notification count: $e');
    }
  }

  Future<void> _loadGames() async {
    try {
      debugPrint('Loading games from database for team: $teamName');
      // Use GameService getFilteredGames with showAway: true and status: 'Published'
      final allGamesData = await _gameService.getFilteredGames(
        showAwayGames: true, 
        status: 'Published'
      );
      debugPrint('Retrieved ${allGamesData.length} published games from database');
      
      // Filter by teamName/scheduleName containing team
      List<Game> filteredGames = allGamesData
          .where((game) =>
              game.opponent == teamName ||
              (game.scheduleName != null &&
                  game.scheduleName!.contains(teamName!)))
          .toList();
      
      // Sort games by date and time
      filteredGames.sort((a, b) {
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
      
      debugPrint('Filtered to ${filteredGames.length} games for this team');
      
      setState(() {
        games = filteredGames;
        isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading games from database: $e');
      setState(() {
        games = [];
        isLoading = false;
      });
    }
  }


  Future<Map<String, dynamic>?> _fetchGameById(int gameId) async {
    try {
      final game = await _gameService.getGameById(gameId);
      if (game != null) {
        debugPrint('Retrieved game from database: ${game['id']}');
        return game;
      }
    } catch (e) {
      debugPrint('Error fetching game from database: $e');
    }
    return null;
  }

  void _onBottomNavTap(int index) {
    if (index == _currentIndex) return;

    setState(() {
      _currentIndex = index;
    });

    switch (index) {
      case 0: // Home - stay on current screen
        break;
      case 1: // Officials
        Navigator.pushNamed(context, '/lists_of_officials');
        // Reset to home after navigation
        setState(() {
          _currentIndex = 0;
        });
        break;
      case 2: // Locations
        Navigator.pushNamed(context, '/locations');
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
      bottomNavigationBar: SchedulerBottomNavigation(
        currentIndex: _currentIndex,
        onTap: _onBottomNavTap,
        schedulerType: SchedulerType.coach,
        unreadNotificationCount: _unreadNotificationCount,
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
    final sport = game.sportName ?? 'Unknown Sport';
    final sportIcon = getSportIcon(sport);
    final isAway = game.isAway;

    return GestureDetector(
      onTap: () async {
        final gameId = game.id;
        if (gameId == null) return;
        final latestGame = await _fetchGameById(gameId);
        if (latestGame == null) {
          return;
        }
        if (mounted) {
          Navigator.pushNamed(context, '/game_information', arguments: latestGame)
              .then((result) async {
            // Always refresh from database after game information screen
            if (result == true || 
                (result != null && result is Map<String, dynamic>) ||
                (result != null && (result as Map<String, dynamic>)['refresh'] == true)) {
              debugPrint('Refreshing games after game information screen update');
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
                        Builder(
                          builder: (context) {
                            // Check if game is within a week
                            final now = DateTime.now();
                            final isWithinWeek = game.date != null && 
                                game.date!.difference(now).inDays <= 7 && 
                                game.date!.isAfter(now.subtract(const Duration(days: 1)));
                            
                            if (isFullyHired) {
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.green,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text('$hiredOfficials/$requiredOfficials Official(s)',
                                        style: const TextStyle(
                                            fontSize: 14,
                                            color: Colors.white)),
                                    const SizedBox(width: 4),
                                    const Icon(Icons.check_circle,
                                        color: Colors.white, size: 16),
                                  ],
                                ),
                              );
                            } else if (isWithinWeek) {
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.red.withOpacity(0.7),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text('$hiredOfficials/$requiredOfficials Official(s)',
                                        style: const TextStyle(
                                            fontSize: 14,
                                            color: Colors.white)),
                                    const SizedBox(width: 8),
                                    const Icon(Icons.warning_amber_rounded,
                                        color: efficialsYellow, size: 16),
                                  ],
                                ),
                              );
                            } else {
                              return Text('$hiredOfficials/$requiredOfficials Official(s)',
                                  style: const TextStyle(
                                      fontSize: 14,
                                      color: Colors.red));
                            }
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
                
                // Clear user session (assuming UserSessionService still handles sessions)
                try {
                  // Get current user to clear properly
                  final currentUser = await _userRepo.getCurrentUser();
                  if (currentUser != null) {
                    // Clear session would typically be handled by a session service
                    // For now, just navigate to welcome
                  }
                } catch (e) {
                  debugPrint('Error during logout: $e');
                }
                
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
