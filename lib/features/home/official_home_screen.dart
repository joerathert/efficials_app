import 'package:flutter/material.dart';
import '../../shared/theme.dart';
import '../officials/official_games_screen.dart';
import '../officials/official_assignments_screen.dart';
import '../officials/official_availability_screen.dart';
import '../officials/official_profile_screen.dart';
import '../crews/crew_dashboard_screen.dart';
import '../crews/crew_invitations_screen.dart';
import '../../shared/services/user_session_service.dart';
import '../../shared/services/repositories/game_assignment_repository.dart';
import '../../shared/services/repositories/official_repository.dart';
import '../../shared/services/repositories/crew_repository.dart';
import '../../shared/services/repositories/notification_repository.dart';
import '../../shared/services/game_service.dart';
import '../../shared/models/database_models.dart';
import '../../shared/widgets/linked_games_list.dart';

class OfficialHomeScreen extends StatefulWidget {
  const OfficialHomeScreen({super.key});

  @override
  State<OfficialHomeScreen> createState() => _OfficialHomeScreenState();
}

class _OfficialHomeScreenState extends State<OfficialHomeScreen> {
  int _currentIndex = 0;
  
  // Repositories
  final GameAssignmentRepository _assignmentRepo = GameAssignmentRepository();
  final OfficialRepository _officialRepo = OfficialRepository();
  final CrewRepository _crewRepo = CrewRepository();
  final NotificationRepository _notificationRepo = NotificationRepository();
  final GameService _gameService = GameService();
  
  // State variables
  String officialName = "";
  List<GameAssignment> acceptedGames = [];
  List<Map<String, dynamic>> availableGames = [];
  List<GameAssignment> pendingGames = [];
  bool _isLoading = true;
  Official? _currentOfficial;
  int _pendingInvitationsCount = 0;
  int _unreadNotificationCount = 0;
  double _ytdEarnings = 0.0;
  
  @override
  void initState() {
    super.initState();
    _loadData();
  }
  
  Future<void> _loadData() async {
    try {
      setState(() {
        _isLoading = true;
      });
      
      // Get current user session
      final userSession = UserSessionService.instance;
      final userId = await userSession.getCurrentUserId();
      final userType = await userSession.getCurrentUserType();
      
      if (userId == null || userType != 'official') {
        // Handle error - redirect to login
        return;
      }
      
      // Get the official record
      _currentOfficial = await _officialRepo.getOfficialByOfficialUserId(userId);
      
      if (_currentOfficial == null) {
        // Handle error - no official record found
        return;
      }
      
      // Set official name
      officialName = _currentOfficial!.name ?? "Official";
      
      // Load assignments
      await _loadAssignments();
      
      // Load pending invitations count
      await _loadInvitationsCount();
      
      // Load unread notification count
      await _loadUnreadNotificationCount();
      
    } catch (e) {
      print('Error loading data: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  Future<void> _loadAssignments() async {
    if (_currentOfficial == null) return;
    
    try {
      // Use optimized batch method to load all data in one call
      final homeData = await _assignmentRepo.getOfficialHomeData(_currentOfficial!.id!);
      
      final accepted = homeData['accepted'] as List<GameAssignment>;
      final pending = homeData['pending'] as List<GameAssignment>;
      final transformedAvailable = homeData['available'] as List<Map<String, dynamic>>;
      
      if (mounted) {
        setState(() {
          // Sort accepted games by date and time (earliest first)
          accepted.sort((a, b) {
            final aDate = a.gameDate;
            final bDate = b.gameDate;
            
            if (aDate == null && bDate == null) return 0;
            if (aDate == null) return 1;
            if (bDate == null) return -1;
            
            final dateComparison = aDate.compareTo(bDate);
            if (dateComparison != 0) return dateComparison;
            
            // If dates are the same, compare times
            final aTime = a.gameTime;
            final bTime = b.gameTime;
            
            if (aTime == null && bTime == null) return 0;
            if (aTime == null) return 1;
            if (bTime == null) return -1;
            
            return aTime.compareTo(bTime);
          });
          
          acceptedGames = accepted;
          pendingGames = pending;
          // Convert to mutable list to allow removeWhere operations
          availableGames = transformedAvailable;
          
          // Calculate YTD earnings from accepted games
          _calculateYtdEarnings();
        });
      }
    } catch (e) {
      print('Error loading assignments: $e');
    }
  }

  Future<void> _loadInvitationsCount() async {
    try {
      if (_currentOfficial?.id != null) {
        final invitations = await _crewRepo.getPendingInvitations(_currentOfficial!.id!);
        if (mounted) {
          setState(() {
            _pendingInvitationsCount = invitations.length;
          });
        }
      }
    } catch (e) {
      print('Error loading invitations count: $e');
    }
  }

  Future<void> _loadUnreadNotificationCount() async {
    try {
      if (_currentOfficial?.id != null) {
        final count = await _notificationRepo.getUnreadOfficialNotificationCount(_currentOfficial!.id!);
        if (mounted) {
          setState(() {
            _unreadNotificationCount = count;
          });
        }
      }
    } catch (e) {
      print('Error loading unread notification count: $e');
    }
  }

  void _calculateYtdEarnings() {
    final currentYear = DateTime.now().year;
    double totalEarnings = 0.0;
    
    for (final assignment in acceptedGames) {
      // Only count games from current year
      if (assignment.gameDate != null && 
          assignment.gameDate!.year == currentYear &&
          assignment.feeAmount != null) {
        totalEarnings += assignment.feeAmount!;
      }
    }
    
    _ytdEarnings = totalEarnings;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: darkBackground,
      appBar: AppBar(
        backgroundColor: efficialsBlack,
        title: const Icon(
          Icons.sports,
          color: efficialsYellow,
          size: 32,
        ),
        elevation: 0,
        centerTitle: true,
        actions: [
          GestureDetector(
            onTap: () {
              Navigator.pushNamed(context, '/official_notifications').then((_) {
                // Refresh notification count when returning from notifications screen
                _loadUnreadNotificationCount();
              });
            },
            child: Container(
              width: 48,
              height: 48,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              child: Stack(
                children: [
                  Center(
                    child: Icon(Icons.notifications, color: efficialsWhite, size: 24),
                  ),
                  if (_unreadNotificationCount > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          _unreadNotificationCount > 99 ? '99+' : _unreadNotificationCount.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: efficialsWhite),
            color: darkSurface,
            onSelected: (value) {
              if (value == 'logout') {
                _handleLogout();
              } else if (value == 'dismissed_games') {
                _showDismissedGames();
              }
            },
            itemBuilder: (BuildContext context) => [
              const PopupMenuItem<String>(
                value: 'dismissed_games',
                child: Row(
                  children: [
                    Icon(Icons.remove_circle_outline, color: Colors.orange),
                    SizedBox(width: 8),
                    Text('Dismissed Games', style: TextStyle(color: Colors.white)),
                  ],
                ),
              ),
              const PopupMenuItem<String>(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Logout', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: _buildCurrentScreen(),
      bottomNavigationBar: _buildBottomNavigation(),
    );
  }

  Widget _buildCurrentScreen() {
    switch (_currentIndex) {
      case 0:
        return _buildHomeTab(); // Accepted games
      case 1:
        return _buildAvailableTab(); // Available games from schedulers
      case 2:
        return _buildPendingTab(); // Games you've expressed interest in
      case 3:
        return _buildAvailabilityTab(); // Calendar
      case 4:
        return _buildProfileTab(); // Profile
      default:
        return _buildHomeTab();
    }
  }

  Widget _buildHomeTab() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: efficialsYellow),
            SizedBox(height: 16),
            Text(
              'Loading your assignments...',
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
          ],
        ),
      );
    }
    
    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _loadData,
        color: efficialsYellow,
        child: CustomScrollView(
          slivers: [
            // Enhanced Header with gradient
            SliverToBoxAdapter(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      efficialsBlack,
                      darkSurface,
                    ],
                  ),
                ),
                child: Column(
                  children: [
                    _buildWelcomeHeader(),
                    _buildStatsCards(),
                  ],
                ),
              ),
            ),
            // Games Section
            SliverToBoxAdapter(
              child: Container(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Your Confirmed Games',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: efficialsYellow,
                      ),
                    ),
                    if (acceptedGames.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: efficialsYellow.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${acceptedGames.length}',
                          style: const TextStyle(
                            color: efficialsYellow,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            // Games List
            acceptedGames.isEmpty
                ? SliverFillRemaining(
                    child: _buildEnhancedEmptyState(),
                  )
                : SliverFillRemaining(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: FutureBuilder<List<dynamic>>(
                        future: _processConfirmedGamesWithLinking(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator(color: efficialsYellow));
                          }
                          
                          final processedGames = snapshot.data ?? [];
                          if (processedGames.isEmpty) {
                            return _buildEmptyState('No confirmed games', Icons.assignment_turned_in);
                          }
                          
                          return ListView.builder(
                            itemCount: processedGames.length,
                            itemBuilder: (context, index) {
                              final item = processedGames[index];
                              if (item is List<Map<String, dynamic>>) {
                                // This is a group of linked games
                                return _buildLinkedConfirmedGamesCard(item);
                              } else {
                                // This is a single game
                                return _buildConfirmedGameCard(item as Map<String, dynamic>);
                              }
                            },
                          );
                        },
                      ),
                    ),
                  ),
            // Bottom padding
            const SliverToBoxAdapter(
              child: SizedBox(height: 100),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvailableTab() {
    return SafeArea(
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Text(
                  'Available Games',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: efficialsYellow,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${availableGames.length} ${availableGames.length == 1 ? 'game' : 'games'} posted by schedulers',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[400],
                  ),
                ),
              ],
            ),
          ),
          // Available Games List
          Expanded(
            child: availableGames.isEmpty
                ? _buildEmptyState('No available games', Icons.sports)
                : FutureBuilder<List<dynamic>>(
                    future: _processAvailableGamesWithLinking(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator(color: efficialsYellow));
                      }
                      
                      final processedGames = snapshot.data ?? [];
                      return ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: processedGames.length,
                        itemBuilder: (context, index) {
                          final item = processedGames[index];
                          if (item is List<Map<String, dynamic>>) {
                            // This is a group of linked games
                            return _buildLinkedAvailableGamesCard(item);
                          } else {
                            // This is a single game
                            return _buildAvailableGameCard(item as Map<String, dynamic>);
                          }
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildPendingTab() {
    return SafeArea(
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Text(
                  'Pending Interest',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: efficialsYellow,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${pendingGames.length} ${pendingGames.length == 1 ? 'game' : 'games'} awaiting scheduler response',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[400],
                  ),
                ),
              ],
            ),
          ),
          // Pending Games List
          Expanded(
            child: pendingGames.isEmpty
                ? _buildEmptyState('No pending applications', Icons.hourglass_empty)
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: pendingGames.length,
                    itemBuilder: (context, index) {
                      final game = pendingGames[index];
                      return _buildPendingGameCard(game);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvailabilityTab() {
    return OfficialAvailabilityScreen(acceptedGames: acceptedGames);
  }

  Widget _buildProfileTab() {
    return const OfficialProfileScreen();
  }

  Widget _buildAcceptedGameCard(GameAssignment assignment, bool isNext) {
    // Format the date and time
    final gameDate = assignment.gameDate != null 
        ? _formatDate(assignment.gameDate!) 
        : 'TBD';
    final gameTime = assignment.gameTime != null 
        ? _formatTime(assignment.gameTime!) 
        : 'TBD';
    final sportName = assignment.sportName ?? 'Sport';
    final locationName = assignment.locationName ?? 'TBD';
    final fee = assignment.feeAmount ?? 0.0;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: darkSurface,
        borderRadius: BorderRadius.circular(12),
        border: isNext ? Border.all(color: efficialsYellow.withOpacity(0.5), width: 2) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                sportName,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: efficialsYellow,
                ),
              ),
              Row(
                children: [
                  if (isNext)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: efficialsYellow.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'NEXT',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: efficialsYellow,
                        ),
                      ),
                    ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'CONFIRMED',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.green[300],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _formatAssignmentTitle(assignment),
            style: const TextStyle(
              fontSize: 14,
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.schedule, size: 14, color: Colors.grey[400]),
              const SizedBox(width: 4),
              Text(
                '$gameDate at $gameTime',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[400],
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.location_on, size: 14, color: Colors.grey[400]),
              const SizedBox(width: 4),
              Text(
                locationName,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[400],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Fee: \$${fee.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
              if (isNext)
                ElevatedButton.icon(
                  onPressed: () {
                    // TODO: Navigate to game details
                  },
                  icon: const Icon(Icons.directions, size: 16),
                  label: const Text('Directions', style: TextStyle(fontSize: 12)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: efficialsYellow,
                    foregroundColor: efficialsBlack,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    minimumSize: Size.zero,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Future<List<dynamic>> _processAvailableGamesWithLinking() async {
    final processedItems = <dynamic>[];
    final processedGameIds = <int>{};
    
    debugPrint('🔗 Processing ${availableGames.length} available games for linking...');
    
    for (final game in availableGames) {
      final gameId = game['id'] as int?;
      if (gameId == null || processedGameIds.contains(gameId)) continue;
      
      try {
        debugPrint('🔗 Checking if game $gameId is linked...');
        final isLinked = await _gameService.isGameLinked(gameId);
        debugPrint('🔗 Game $gameId linked status: $isLinked');
        if (isLinked) {
          final linkedGames = await _gameService.getLinkedGames(gameId);
          debugPrint('🔗 Found ${linkedGames.length} linked games for game $gameId');
          
          // Find linked games that are also in our available games list
          final linkedGamesInList = <Map<String, dynamic>>[]; 
          linkedGamesInList.add(game); // Add the primary game
          
          for (final linkedGame in linkedGames) {
            final linkedGameId = linkedGame['id'] as int?;
            if (linkedGameId == null) continue;
            
            debugPrint('🔗 Looking for linked game $linkedGameId in available games list...');
            final matchingAvailableGame = availableGames.where(
              (g) => (g['id'] as int?) == linkedGameId,
            );
            
            if (matchingAvailableGame.isNotEmpty) {
              debugPrint('🔗 Found matching available game $linkedGameId');
              linkedGamesInList.add(matchingAvailableGame.first);
              processedGameIds.add(linkedGameId);
            } else {
              debugPrint('🔗 Linked game $linkedGameId not found in available games list');
            }
          }
          
          debugPrint('🔗 Total games in linked group: ${linkedGamesInList.length}');
          if (linkedGamesInList.length > 1) {
            // Sort by time if available (safely handle different time formats)
            linkedGamesInList.sort((a, b) {
              TimeOfDay? timeA, timeB;
              
              try {
                final timeValueA = a['time'];
                if (timeValueA is TimeOfDay) {
                  timeA = timeValueA;
                } else if (timeValueA is DateTime) {
                  timeA = TimeOfDay.fromDateTime(timeValueA);
                }
              } catch (e) {
                debugPrint('Error parsing time for game ${a['id']}: $e');
              }
              
              try {
                final timeValueB = b['time'];
                if (timeValueB is TimeOfDay) {
                  timeB = timeValueB;
                } else if (timeValueB is DateTime) {
                  timeB = TimeOfDay.fromDateTime(timeValueB);
                }
              } catch (e) {
                debugPrint('Error parsing time for game ${b['id']}: $e');
              }
              
              if (timeA == null && timeB == null) return 0;
              if (timeA == null) return 1;
              if (timeB == null) return -1;
              final minutesA = timeA.hour * 60 + timeA.minute;
              final minutesB = timeB.hour * 60 + timeB.minute;
              return minutesA.compareTo(minutesB);
            });
            
            processedItems.add(linkedGamesInList);
            processedGameIds.add(gameId);
          } else {
            processedItems.add(game);
            processedGameIds.add(gameId);
          }
        } else {
          processedItems.add(game);
          processedGameIds.add(gameId);
        }
      } catch (e) {
        debugPrint('Error checking if game $gameId is linked: $e');
        processedItems.add(game);
        processedGameIds.add(gameId);
      }
    }
    
    debugPrint('🔗 Final processed items count: ${processedItems.length}');
    return processedItems;
  }

  Widget _buildLinkedAvailableGamesCard(List<Map<String, dynamic>> linkedGames) {
    if (linkedGames.length < 2) {
      return _buildAvailableGameCard(linkedGames.first);
    }
    
    // Calculate total fee for linked games
    double totalFee = 0.0;
    for (final game in linkedGames) {
      final fee = double.tryParse(game['game_fee']?.toString() ?? '0') ?? 0.0;
      totalFee += fee;
    }
    
    // Get shared information (location, scheduler)
    final primaryGame = linkedGames.first;
    final location = primaryGame['location_name'] ?? 'TBD';
    final scheduler = '${primaryGame['first_name'] ?? ''} ${primaryGame['last_name'] ?? ''}'.trim();
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Stack(
        children: [
          Column(
            children: [
              // Top card - just game info
              Container(
                decoration: BoxDecoration(
                  color: darkSurface,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                    bottomLeft: Radius.circular(2),
                    bottomRight: Radius.circular(2),
                  ),
                  border: Border.all(color: Colors.blue.withOpacity(0.3), width: 1),
                ),
                child: _buildTopLinkedGameContent(linkedGames[0]),
              ),
              // No gap - cards pressed together
              // Bottom card - game info + shared info + buttons
              Container(
                decoration: BoxDecoration(
                  color: darkSurface,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(2),
                    topRight: Radius.circular(2),
                    bottomLeft: Radius.circular(12),
                    bottomRight: Radius.circular(12),
                  ),
                  border: Border.all(color: Colors.blue.withOpacity(0.3), width: 1),
                ),
                child: _buildBottomLinkedGameContent(linkedGames[1], location, scheduler, totalFee, linkedGames),
              ),
            ],
          ),
          // Linked badge in top-right corner
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: efficialsYellow.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: efficialsYellow, width: 1),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.link, color: efficialsYellow, size: 14),
                  const SizedBox(width: 4),
                  const Text(
                    'Linked Games',
                    style: TextStyle(
                      color: efficialsYellow,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopLinkedGameContent(Map<String, dynamic> game) {
    return GestureDetector(
      onTap: () => _handleAvailableGameTap(game),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              game['sport_name'] ?? 'Sport',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: efficialsYellow,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _formatGameTitle(game),
              style: const TextStyle(
                fontSize: 14,
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.schedule, size: 14, color: Colors.grey[400]),
                const SizedBox(width: 4),
                Text(
                  '${_formatAvailableGameDate(game)} at ${_formatAvailableGameTime(game)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[400],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              game['schedule_name'] ?? game['scheduleName'] ?? 'Schedule',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[400],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomLinkedGameContent(
    Map<String, dynamic> game, 
    String location, 
    String scheduler, 
    double totalFee, 
    List<Map<String, dynamic>> linkedGames
  ) {
    return GestureDetector(
      onTap: () => _handleAvailableGameTap(game),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _formatGameTitle(game),
              style: const TextStyle(
                fontSize: 14,
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.schedule, size: 14, color: Colors.grey[400]),
                const SizedBox(width: 4),
                Text(
                  '${_formatAvailableGameDate(game)} at ${_formatAvailableGameTime(game)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[400],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              game['schedule_name'] ?? game['scheduleName'] ?? 'Schedule',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[400],
              ),
            ),
            const SizedBox(height: 8),
            // Shared information
            Row(
              children: [
                Icon(Icons.location_on, size: 14, color: Colors.grey[400]),
                const SizedBox(width: 4),
                Text(
                  location,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[400],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.person, size: 14, color: Colors.grey[400]),
                const SizedBox(width: 4),
                Text(
                  'Posted by: $scheduler',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[400],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total Fee: \$${totalFee.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ElevatedButton(
                      onPressed: () => _dismissLinkedGames(linkedGames),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        minimumSize: Size.zero,
                      ),
                      child: const Text(
                        'Dismiss',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () => _handleLinkedGamesAction(linkedGames),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _getLinkedGamesActionColor(linkedGames),
                        foregroundColor: _getLinkedGamesActionTextColor(linkedGames),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        minimumSize: Size.zero,
                      ),
                      child: Text(
                        _getLinkedGamesActionText(linkedGames),
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLinkedGameContent(Map<String, dynamic> game, {bool showButtons = true}) {
    return GestureDetector(
      onTap: () => _handleAvailableGameTap(game),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  game['sport_name'] ?? 'Sport',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: efficialsYellow,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'AVAILABLE',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[300],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              _formatGameTitle(game),
              style: const TextStyle(
                fontSize: 14,
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.schedule, size: 14, color: Colors.grey[400]),
                const SizedBox(width: 4),
                Text(
                  '${_formatAvailableGameDate(game)} at ${_formatAvailableGameTime(game)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[400],
                  ),
                ),
              ],
            ),
            if (!showButtons) const SizedBox(height: 60), // Spacer for overlay
          ],
        ),
      ),
    );
  }

  void _dismissLinkedGames(List<Map<String, dynamic>> linkedGames) {
    for (final game in linkedGames) {
      _dismissGame(game);
    }
  }

  void _handleLinkedGamesAction(List<Map<String, dynamic>> linkedGames) {
    // Check if all games have the same action type
    final firstGame = linkedGames.first;
    final isClaimAction = firstGame['hire_automatically'] == 1;
    
    // For simplicity, use the action type of the first game
    if (isClaimAction) {
      _showClaimLinkedGamesDialog(linkedGames);
    } else {
      _showExpressInterestLinkedGamesDialog(linkedGames);
    }
  }

  Color _getLinkedGamesActionColor(List<Map<String, dynamic>> linkedGames) {
    final firstGame = linkedGames.first;
    return firstGame['hire_automatically'] == 1 ? Colors.green : efficialsYellow;
  }

  Color _getLinkedGamesActionTextColor(List<Map<String, dynamic>> linkedGames) {
    final firstGame = linkedGames.first;
    return firstGame['hire_automatically'] == 1 ? Colors.white : Colors.black;
  }

  String _getLinkedGamesActionText(List<Map<String, dynamic>> linkedGames) {
    final firstGame = linkedGames.first;
    return firstGame['hire_automatically'] == 1 ? 'Claim' : 'Express Interest';
  }

  void _showClaimLinkedGamesDialog(List<Map<String, dynamic>> linkedGames) {
    // Calculate total fee for both games
    double totalFee = 0.0;
    for (final game in linkedGames) {
      final fee = double.tryParse(game['game_fee']?.toString() ?? '0') ?? 0.0;
      totalFee += fee;
    }
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: darkSurface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(Icons.link, color: Colors.green, size: 24),
              const SizedBox(width: 8),
              const Text(
                'Claim Linked Games',
                style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Are you sure you want to claim these linked games?',
                style: TextStyle(color: Colors.grey[300], fontSize: 16),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: darkBackground,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.link, color: efficialsYellow, size: 16),
                        const SizedBox(width: 4),
                        const Text(
                          'Linked Games',
                          style: TextStyle(color: efficialsYellow, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ...linkedGames.map((game) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '• ${_formatGameTitle(game)}',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 2),
                          Padding(
                            padding: const EdgeInsets.only(left: 12),
                            child: Text(
                              '${_formatAvailableGameDate(game)} at ${_formatAvailableGameTime(game)}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[400],
                              ),
                            ),
                          ),
                        ],
                      ),
                    )).toList(),
                    const SizedBox(height: 8),
                    Text(
                      'Total Fee: \$${totalFee.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'By claiming these linked games, you are committing to officiate both games.',
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _claimLinkedGames(linkedGames);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              child: const Text('Claim Both Games'),
            ),
          ],
        );
      },
    );
  }

  void _showExpressInterestLinkedGamesDialog(List<Map<String, dynamic>> linkedGames) {
    // Calculate total fee for both games
    double totalFee = 0.0;
    for (final game in linkedGames) {
      final fee = double.tryParse(game['game_fee']?.toString() ?? '0') ?? 0.0;
      totalFee += fee;
    }
    
    // Get response timeframe from first game (assuming both have same timeframe)
    final responseTime = linkedGames.first['response_timeframe'] ?? 24;
    final responseUnit = linkedGames.first['response_unit'] ?? 'hours';
    String timeframeText = _formatResponseTimeframe(responseTime, responseUnit);
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: darkSurface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(Icons.link, color: efficialsYellow, size: 24),
              const SizedBox(width: 8),
              const Text(
                'Express Interest in Linked Games',
                style: TextStyle(color: efficialsYellow, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Express interest in these linked games?',
                style: TextStyle(color: Colors.grey[300], fontSize: 16),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: darkBackground,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.link, color: efficialsYellow, size: 16),
                        const SizedBox(width: 4),
                        const Text(
                          'Linked Games',
                          style: TextStyle(color: efficialsYellow, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ...linkedGames.map((game) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        '• ${_formatGameTitle(game)}',
                        style: const TextStyle(color: Colors.white),
                      ),
                    )).toList(),
                    const SizedBox(height: 8),
                    Text(
                      'Total Fee: \$${totalFee.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: efficialsYellow,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'The scheduler will respond within $timeframeText. If selected, you will be assigned to both games.',
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _expressInterestInLinkedGames(linkedGames);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: efficialsYellow,
                foregroundColor: Colors.black,
              ),
              child: const Text('Express Interest'),
            ),
          ],
        );
      },
    );
  }

  void _claimLinkedGames(List<Map<String, dynamic>> linkedGames) async {
    try {
      // Show loading indicator
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Claiming linked games...'),
          backgroundColor: Colors.blue,
        ),
      );

      // Claim each game in the linked set
      for (final game in linkedGames) {
        await _claimSingleGame(game);
      }

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Successfully claimed ${linkedGames.length} linked games'),
          backgroundColor: Colors.green,
        ),
      );

      // Refresh the data
      await _loadData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to claim linked games: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _expressInterestInLinkedGames(List<Map<String, dynamic>> linkedGames) async {
    try {
      // Show loading indicator
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Expressing interest in linked games...'),
          backgroundColor: Colors.blue,
        ),
      );

      // Express interest in each game in the linked set
      for (final game in linkedGames) {
        await _expressInterestInSingleGame(game);
      }

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Successfully expressed interest in ${linkedGames.length} linked games'),
          backgroundColor: Colors.green,
        ),
      );

      // Refresh the data
      await _loadData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to express interest in linked games: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _claimSingleGame(Map<String, dynamic> game) async {
    final gameId = game['id'] as int?;
    final feeAmount = double.tryParse(game['game_fee']?.toString() ?? '0') ?? 0.0;
    
    if (gameId == null) {
      throw Exception('Invalid game ID');
    }
    
    // Get current user and official info
    final userSession = UserSessionService.instance;
    final userId = await userSession.getCurrentUserId();
    
    if (userId == null) {
      throw Exception('No user logged in');
    }
    
    final official = await _officialRepo.getOfficialByOfficialUserId(userId);
    
    if (official?.id == null) {
      throw Exception('Official record not found');
    }
    
    final officialId = official!.id!;
    
    // Claim the game
    await _assignmentRepo.claimGame(gameId, officialId, feeAmount);
  }

  Future<void> _expressInterestInSingleGame(Map<String, dynamic> game) async {
    final gameId = game['id'] as int?;
    final feeAmount = double.tryParse(game['game_fee']?.toString() ?? '0') ?? 0.0;
    
    if (gameId == null) {
      throw Exception('Invalid game ID');
    }
    
    // Get current user and official info
    final userSession = UserSessionService.instance;
    final userId = await userSession.getCurrentUserId();
    
    if (userId == null) {
      throw Exception('No user logged in');
    }
    
    final official = await _officialRepo.getOfficialByOfficialUserId(userId);
    
    if (official?.id == null) {
      throw Exception('Official record not found');
    }
    
    final officialId = official!.id!;
    
    // Express interest in the game
    await _assignmentRepo.expressInterest(gameId, officialId, feeAmount);
  }

  Future<List<dynamic>> _processConfirmedGamesWithLinking() async {
    final List<dynamic> processedGames = [];
    final Set<int> processedGameIds = {};
    
    final confirmedGameMaps = _convertGameAssignmentsToMaps(acceptedGames);
    
    debugPrint('Processing ${confirmedGameMaps.length} confirmed games for linking');
    
    for (final game in confirmedGameMaps) {
      final gameId = game['id'] as int?;
      if (gameId == null || processedGameIds.contains(gameId)) continue;
      
      debugPrint('Processing game ID: $gameId');
      
      try {
        // Check if this game is linked to others
        final isLinked = await _gameService.isGameLinked(gameId);
        debugPrint('Game $gameId is linked: $isLinked');
        
        if (isLinked) {
          final linkedGames = await _gameService.getLinkedGames(gameId);
          debugPrint('Found ${linkedGames.length} linked games for game $gameId');
          
          // Filter linked games to only include those that are also in our confirmed list
          final linkedGamesInConfirmed = <Map<String, dynamic>>[];
          linkedGamesInConfirmed.add(game); // Add current game first
          
          for (final linkedGame in linkedGames) {
            final linkedGameId = linkedGame['id'] as int?;
            if (linkedGameId == null || linkedGameId == gameId) continue;
            
            // Find the corresponding game in our confirmed list
            final originalLinkedGame = confirmedGameMaps.where(
              (g) => (g['id'] as int?) == linkedGameId,
            );
            
            if (originalLinkedGame.isNotEmpty) {
              linkedGamesInConfirmed.add(originalLinkedGame.first);
              processedGameIds.add(linkedGameId);
            }
          }
          
          if (linkedGamesInConfirmed.length > 1) {
            debugPrint('Adding ${linkedGamesInConfirmed.length} linked games as group');
            processedGames.add(linkedGamesInConfirmed);
            processedGameIds.add(gameId);
            continue;
          }
        }
      } catch (e) {
        debugPrint('Error checking if game $gameId is linked: $e');
      }
      
      // Single game (not linked or linking failed)
      debugPrint('Adding single game: $gameId');
      processedGames.add(game);
      processedGameIds.add(gameId);
    }
    
    debugPrint('Final processed games count: ${processedGames.length}');
    return processedGames;
  }

  Widget _buildLinkedConfirmedGamesCard(List<Map<String, dynamic>> linkedGames) {
    if (linkedGames.length < 2) {
      return _buildConfirmedGameCard(linkedGames.first);
    }
    
    // Calculate total fee for linked games
    double totalFee = 0.0;
    for (final game in linkedGames) {
      final fee = double.tryParse(game['game_fee']?.toString() ?? '0') ?? 0.0;
      totalFee += fee;
    }
    
    // Get shared information (location, scheduler)
    final primaryGame = linkedGames.first;
    final location = primaryGame['location_name'] ?? 'TBD';
    final assignment = primaryGame['_assignment'] as GameAssignment?;
    final scheduler = 'Confirmed Game'; // For confirmed games, we don't need "Posted by"
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Stack(
        children: [
          Column(
            children: [
              // Top card - clickable for first game
              GestureDetector(
                onTap: () => _handleConfirmedGameTap(linkedGames[0]),
                child: Container(
                  decoration: BoxDecoration(
                    color: darkSurface,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(12),
                      topRight: Radius.circular(12),
                      bottomLeft: Radius.circular(2),
                      bottomRight: Radius.circular(2),
                    ),
                    border: Border.all(color: Colors.blue.withOpacity(0.3), width: 1),
                  ),
                  child: _buildTopConfirmedGameContent(linkedGames[0]),
                ),
              ),
              // No gap - cards pressed together
              // Bottom card - clickable for second game + shared info
              GestureDetector(
                onTap: () => _handleConfirmedGameTap(linkedGames[1]),
                child: Container(
                  decoration: BoxDecoration(
                    color: darkSurface,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(2),
                      topRight: Radius.circular(2),
                      bottomLeft: Radius.circular(12),
                      bottomRight: Radius.circular(12),
                    ),
                    border: Border.all(color: Colors.blue.withOpacity(0.3), width: 1),
                  ),
                  child: _buildBottomConfirmedGameContent(linkedGames[1], location, scheduler, totalFee),
                ),
              ),
            ],
          ),
          // Linked badge in top-right corner
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: efficialsYellow.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: efficialsYellow, width: 1),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.link, color: efficialsYellow, size: 14),
                  const SizedBox(width: 4),
                  const Text(
                    'Linked Games',
                    style: TextStyle(
                      color: efficialsYellow,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmedGameCard(Map<String, dynamic> game) {
    return GestureDetector(
      onTap: () => _handleConfirmedGameTap(game),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: darkSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.blue.withOpacity(0.3), width: 1),
        ),
        child: _buildConfirmedGameContent(game),
      ),
    );
  }

  Widget _buildTopConfirmedGameContent(Map<String, dynamic> game) {
    final assignment = game['_assignment'] as GameAssignment?;
    
    String dateTimeText = 'TBD';
    if (assignment?.gameDate != null) {
      dateTimeText = _formatDate(assignment!.gameDate!);
      if (assignment.gameTime != null) {
        dateTimeText += ' at ${_formatTime(assignment.gameTime!)}';
      }
    }
    
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
            Text(
              game['sport_name'] ?? 'Sport',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: efficialsYellow,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _formatGameTitle(game),
              style: const TextStyle(
                fontSize: 14,
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.schedule, size: 14, color: Colors.grey[400]),
                const SizedBox(width: 4),
                Text(
                  dateTimeText,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[400],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              game['schedule_name'] ?? game['scheduleName'] ?? 'Schedule',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[400],
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      );
  }

  Widget _buildBottomConfirmedGameContent(
    Map<String, dynamic> game, 
    String location, 
    String scheduler, 
    double totalFee
  ) {
    final assignment = game['_assignment'] as GameAssignment?;
    
    String dateTimeText = 'TBD';
    if (assignment?.gameDate != null) {
      dateTimeText = _formatDate(assignment!.gameDate!);
      if (assignment.gameTime != null) {
        dateTimeText += ' at ${_formatTime(assignment.gameTime!)}';
      }
    }
    
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
            Text(
              _formatGameTitle(game),
              style: const TextStyle(
                fontSize: 14,
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.schedule, size: 14, color: Colors.grey[400]),
                const SizedBox(width: 4),
                Text(
                  dateTimeText,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[400],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              game['schedule_name'] ?? game['scheduleName'] ?? 'Schedule',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[400],
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 12),
            // Shared information section
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.location_on, size: 14, color: Colors.grey[400]),
                    const SizedBox(width: 4),
                    Text(
                      location,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[400],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Fee and CONFIRMED badge in same row (like Available Games)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      'Total Fee: \$${totalFee.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'CONFIRMED',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      );
  }

  Widget _buildConfirmedGameContent(Map<String, dynamic> game) {
    // For single games, show full content including fee and confirmed badge
    final assignment = game['_assignment'] as GameAssignment?;
    
    String dateTimeText = 'TBD';
    if (assignment?.gameDate != null) {
      dateTimeText = _formatDate(assignment!.gameDate!);
      if (assignment.gameTime != null) {
        dateTimeText += ' at ${_formatTime(assignment.gameTime!)}';
      }
    }
    
    final fee = double.tryParse(game['game_fee']?.toString() ?? '0') ?? 0.0;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          game['sport_name'] ?? 'Sport',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: efficialsYellow,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _formatGameTitle(game),
          style: const TextStyle(
            fontSize: 14,
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Icon(Icons.schedule, size: 14, color: Colors.grey[400]),
            const SizedBox(width: 4),
            Text(
              dateTimeText,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[400],
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          game['schedule_name'] ?? game['scheduleName'] ?? 'Schedule',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[400],
            fontStyle: FontStyle.italic,
          ),
        ),
        const SizedBox(height: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.location_on, size: 14, color: Colors.grey[400]),
                const SizedBox(width: 4),
                Text(
                  game['location_name'] ?? 'TBD',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[400],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Fee and CONFIRMED badge in same row (like Available Games)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  'Fee: \$${fee.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'CONFIRMED',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  void _handleAvailableGameTap(Map<String, dynamic> game) {
    // Create a basic GameAssignment with the available data
    final Map<String, dynamic> assignmentMap = {
      'id': game['id'],
      'game_id': game['id'], // Use the game's actual ID
      'official_id': 0, // Not relevant for available games
      'status': 'available',
      'assigned_by': 0, // Not relevant for available games
      'assigned_at': DateTime.now().toIso8601String(),
      'fee_amount': double.tryParse(game['game_fee']?.toString() ?? '0') ?? 0.0,
      // Scheduler information
      'scheduler_first_name': game['first_name'],
      'scheduler_last_name': game['last_name'],
      'scheduler_user_id': game['user_id'],
      // Additional fields from the game data (use actual field names from query)
      'date': game['date'], // This comes from g.date in the SQL query
      'time': game['time'], // This comes from g.time in the SQL query
      'sport_name': game['sport_name'],
      'opponent': game['opponent'],
      'home_team': game['schedule_home_team_name'] ?? game['home_team'] ?? 'Home Team',
      'location_name': game['location_name'],
    };
    
    final gameAssignment = GameAssignment.fromMap(assignmentMap);
    
    Navigator.pushNamed(
      context,
      '/available_game_details',
      arguments: {
        'assignment': gameAssignment,
        'schedulerInfo': {
          'name': '${game['first_name'] ?? ''} ${game['last_name'] ?? ''}'.trim(),
          'first_name': game['first_name'],
          'last_name': game['last_name'],
          'user_id': game['user_id'],
        },
        'hireAutomatically': game['hire_automatically'] == 1,
      },
    );
  }

  Widget _buildAvailableGameCard(Map<String, dynamic> game) {
    return GestureDetector(
      onTap: () {
        // Create a basic GameAssignment with the available data
        final Map<String, dynamic> assignmentMap = {
          'id': game['id'],
          'game_id': game['id'], // Use the game's actual ID
          'official_id': 0, // Not relevant for available games
          'status': 'available',
          'assigned_by': 0, // Not relevant for available games
          'assigned_at': DateTime.now().toIso8601String(),
          'fee_amount': double.tryParse(game['game_fee']?.toString() ?? '0') ?? 0.0,
          // Scheduler information
          'scheduler_first_name': game['first_name'],
          'scheduler_last_name': game['last_name'],
          'scheduler_user_id': game['user_id'],
          // Additional fields from the game data (use actual field names from query)
          'date': game['date'], // This comes from g.date in the SQL query
          'time': game['time'], // This comes from g.time in the SQL query
          'sport_name': game['sport_name'],
          'opponent': game['opponent'],
          'home_team': game['schedule_home_team_name'] ?? game['home_team'] ?? 'Home Team',
          'location_name': game['location_name'],
        };
        
        final gameAssignment = GameAssignment.fromMap(assignmentMap);
        
        Navigator.pushNamed(
          context,
          '/official_game_details',
          arguments: gameAssignment,
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: darkSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.blue.withOpacity(0.3)),
        ),
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                game['sport_name'] ?? 'Sport',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: efficialsYellow,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'AVAILABLE',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[300],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _formatGameTitle(game),
            style: const TextStyle(
              fontSize: 14,
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.schedule, size: 14, color: Colors.grey[400]),
              const SizedBox(width: 4),
              Text(
                '${_formatAvailableGameDate(game)} at ${_formatAvailableGameTime(game)}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[400],
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.location_on, size: 14, color: Colors.grey[400]),
              const SizedBox(width: 4),
              Text(
                game['location_name'] ?? 'TBD',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[400],
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.person, size: 14, color: Colors.grey[400]),
              const SizedBox(width: 4),
              Text(
                'Posted by: ${game['scheduler']}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[400],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Fee: \$${game['game_fee'] ?? '0'}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ElevatedButton(
                    onPressed: () => _dismissGame(game),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      minimumSize: Size.zero,
                    ),
                    child: const Text(
                      'Dismiss',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () => game['hire_automatically'] == 1 
                        ? _showClaimGameDialog(game)
                        : _showExpressInterestDialog(game),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: game['hire_automatically'] == 1 ? Colors.green : efficialsYellow,
                      foregroundColor: game['hire_automatically'] == 1 ? Colors.white : Colors.black,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      minimumSize: Size.zero,
                    ),
                    child: Text(
                      game['hire_automatically'] == 1 ? 'Claim' : 'Express Interest',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
        ),
      ),
    );
  }

  Widget _buildPendingGameCard(GameAssignment assignment) {
    final gameDate = assignment.gameDate;
    final gameTime = assignment.gameTime;
    final sportName = assignment.sportName ?? 'Sport';
    final locationName = assignment.locationName ?? 'TBD';
    final fee = assignment.feeAmount ?? 0.0;
    
    final dateString = gameDate != null ? _formatDate(gameDate) : 'TBD';
    final timeString = gameTime != null ? _formatTime(gameTime) : 'TBD';
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: darkSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                sportName,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: efficialsYellow,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'PENDING',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange[300],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _formatAssignmentTitle(assignment),
            style: const TextStyle(
              fontSize: 14,
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.schedule, size: 14, color: Colors.grey[400]),
              const SizedBox(width: 4),
              Text(
                '$dateString at $timeString',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[400],
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.location_on, size: 14, color: Colors.grey[400]),
              const SizedBox(width: 4),
              Text(
                locationName,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[400],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Fee: \$${fee}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                  Text(
                    'Applied: ${'Pending response'}',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
              ElevatedButton(
                onPressed: () {
                  // TODO: Withdraw interest
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.withOpacity(0.2),
                  foregroundColor: Colors.red,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  minimumSize: Size.zero,
                ),
                child: const Text('Withdraw', style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String message, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Center(
        child: Column(
          children: [
            Icon(icon, size: 48, color: Colors.grey[600]),
            const SizedBox(height: 16),
            Text(
              message,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[400],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavigation() {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      backgroundColor: efficialsBlack,
      selectedItemColor: efficialsYellow,
      unselectedItemColor: Colors.grey,
      currentIndex: _currentIndex,
      onTap: (index) {
        setState(() {
          _currentIndex = index;
        });
      },
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.sports),
          label: 'Available',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.hourglass_empty),
          label: 'Pending',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.calendar_today),
          label: 'Calendar',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person),
          label: 'Profile',
        ),
      ],
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
  
  // Enhanced UI Components
  Widget _buildWelcomeHeader() {
    final now = DateTime.now();
    final greeting = now.hour < 12 ? 'Good morning' : 
                    now.hour < 17 ? 'Good afternoon' : 'Good evening';
    
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [efficialsYellow, Colors.orange],
                  ),
                  borderRadius: BorderRadius.circular(25),
                ),
                child: const Icon(
                  Icons.sports_basketball,
                  color: Colors.black,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$greeting,',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[400],
                      ),
                    ),
                    Text(
                      officialName,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: efficialsYellow,
                      ),
                    ),
                  ],
                ),
              ),
              // Crew Management Button
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CrewDashboardScreen(),
                    ),
                  ).then((_) => _loadInvitationsCount());
                },
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: efficialsYellow.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: efficialsYellow.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.groups,
                        color: efficialsYellow,
                        size: 20,
                      ),
                      if (_pendingInvitationsCount > 0) ...[
                        const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '$_pendingInvitationsCount',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCards() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              title: 'Confirmed',
              value: '${acceptedGames.length}',
              icon: Icons.check_circle,
              color: Colors.green,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              title: 'Available',
              value: '${availableGames.length}',
              icon: Icons.sports,
              color: Colors.blue,
              onTap: () => setState(() => _currentIndex = 1),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              title: 'Pending',
              value: '${pendingGames.length}',
              icon: Icons.hourglass_empty,
              color: Colors.orange,
              onTap: () => setState(() => _currentIndex = 2),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: darkSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: color,
              size: 28,
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[400],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEarningsCard() {
    return InkWell(
      onTap: () {
        // Show detailed earnings breakdown
        _showEarningsDetails();
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.green.withOpacity(0.2),
              Colors.green.withOpacity(0.1),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.green.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(
              Icons.attach_money,
              color: Colors.green,
              size: 28,
            ),
            const SizedBox(height: 8),
            Text(
              '\$${_ytdEarnings.toStringAsFixed(0)}',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            Text(
              'YTD Earnings',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[400],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showEarningsDetails() {
    final currentYear = DateTime.now().year;
    final monthlyEarnings = <int, double>{};
    
    // Calculate monthly breakdown
    for (final assignment in acceptedGames) {
      if (assignment.gameDate != null && 
          assignment.gameDate!.year == currentYear &&
          assignment.feeAmount != null) {
        final month = assignment.gameDate!.month;
        monthlyEarnings[month] = (monthlyEarnings[month] ?? 0) + assignment.feeAmount!;
      }
    }
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: darkSurface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(Icons.attach_money, color: Colors.green, size: 24),
              const SizedBox(width: 8),
              Text(
                '$currentYear Earnings',
                style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: Container(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.green.withOpacity(0.2), Colors.green.withOpacity(0.1)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Total YTD Earnings',
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '\$${_ytdEarnings.toStringAsFixed(2)}',
                        style: TextStyle(
                          color: Colors.green,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Games Officiated: ${acceptedGames.where((a) => a.gameDate?.year == currentYear).length}',
                  style: TextStyle(
                    color: Colors.grey[300],
                    fontSize: 16,
                  ),
                ),
                if (acceptedGames.where((a) => a.gameDate?.year == currentYear).isNotEmpty)
                  Text(
                    'Average per Game: \$${(_ytdEarnings / acceptedGames.where((a) => a.gameDate?.year == currentYear).length).toStringAsFixed(2)}',
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 14,
                    ),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Close', style: TextStyle(color: efficialsYellow)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildEnhancedEmptyState() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: efficialsYellow.withOpacity(0.1),
              borderRadius: BorderRadius.circular(40),
            ),
            child: Icon(
              Icons.sports,
              size: 40,
              color: efficialsYellow.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'No games assigned yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: efficialsYellow,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            'Check the Available tab to see games you can apply for, or contact your scheduler.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[400],
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => setState(() => _currentIndex = 1),
            icon: const Icon(Icons.search, size: 18),
            label: const Text('Browse Available Games'),
            style: ElevatedButton.styleFrom(
              backgroundColor: efficialsYellow,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedGameCard(GameAssignment assignment, bool isNext) {
    final gameDate = assignment.gameDate != null 
        ? _formatDate(assignment.gameDate!) 
        : 'TBD';
    final gameTime = assignment.gameTime != null 
        ? _formatTime(assignment.gameTime!) 
        : 'TBD';
    final sportName = assignment.sportName ?? 'Sport';
    final locationName = assignment.locationName ?? 'TBD';
    final fee = assignment.feeAmount ?? 0.0;
    
    return GestureDetector(
      onTap: () => _navigateToGameDetails(assignment),
      child: Container(
      decoration: BoxDecoration(
        gradient: isNext
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  efficialsYellow.withOpacity(0.1),
                  darkSurface,
                ],
              )
            : null,
        color: isNext ? null : darkSurface,
        borderRadius: BorderRadius.circular(16),
        border: isNext 
            ? Border.all(color: efficialsYellow.withOpacity(0.5), width: 2)
            : Border.all(color: Colors.grey.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header with sport and status
          Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: _getSportColor(sportName).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Icon(
                            _getSportIcon(sportName),
                            color: _getSportColor(sportName),
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                sportName,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: efficialsYellow,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                _formatAssignmentTitle(assignment),
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[400],
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 2,
                              ),
                            ],
                          ),
                        ),
                        ],
                      ),
                    ),
                    Column(
                      children: [
                        if (isNext)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [efficialsYellow, Colors.orange],
                              ),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text(
                              'NEXT UP',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                          ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'CONFIRMED',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.green[300],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Game details in a more structured layout
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Icon(Icons.schedule, size: 16, color: Colors.grey[400]),
                          const SizedBox(width: 8),
                          Text(
                            '$gameDate at $gameTime',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[300],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.location_on, size: 16, color: Colors.grey[400]),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              locationName,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[300],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.attach_money, size: 16, color: Colors.green[400]),
                              const SizedBox(width: 4),
                              Text(
                                '${fee.toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green[400],
                                ),
                              ),
                            ],
                          ),
                          if (isNext)
                            TextButton.icon(
                              onPressed: () {
                                // TODO: Navigate to game details
                              },
                              icon: const Icon(Icons.directions, size: 16),
                              label: const Text('Get Directions'),
                              style: TextButton.styleFrom(
                                foregroundColor: efficialsYellow,
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ));
  }

  List<Map<String, dynamic>> _convertGameAssignmentsToMaps(List<GameAssignment> assignments) {
    debugPrint('Converting ${assignments.length} GameAssignments to maps');
    return assignments.map((assignment) {
      debugPrint('Assignment - GameID: ${assignment.gameId}, HomeTeam: ${assignment.homeTeam}, Opponent: ${assignment.opponent}');
      return {
      'id': assignment.gameId,
      'game_id': assignment.gameId,
      'date': assignment.gameDate?.toIso8601String(),
      'time': assignment.gameTime?.toIso8601String(),
      'opponent': assignment.opponent,
      'home_team': assignment.homeTeam,
      'schedule_home_team_name': assignment.homeTeam,
      'homeTeam': assignment.homeTeam,
      'schedule_name': assignment.scheduleName ?? assignment.homeTeam ?? assignment.opponent ?? 'Game',
      'scheduleName': assignment.scheduleName ?? assignment.homeTeam ?? assignment.opponent ?? 'Game',
      'sport_name': assignment.sportName,
      'sport': assignment.sportName,
      'location_name': assignment.locationName,
      'location': assignment.locationName,
      'is_away': false, // GameAssignment doesn't have isAway field, default to false
      'isAway': false,
      'officialsRequired': 1, // Individual official assignment
      'officials_required': 1,
      'officialsHired': 1, // This official is confirmed
      'officials_hired': 1,
      'game_fee': assignment.feeAmount?.toString() ?? '0',
      // Store the original assignment for navigation
      '_assignment': assignment,
    };
    }).toList();
  }

  void _handleConfirmedGameTap(Map<String, dynamic> gameMap) async {
    final assignment = gameMap['_assignment'] as GameAssignment?;
    if (assignment != null) {
      // Check if this game is part of a linked set
      try {
        final gameId = assignment.gameId;
        final isLinked = await _gameService.isGameLinked(gameId);
        
        if (isLinked) {
          // Get all linked games for context
          final linkedGames = await _gameService.getLinkedGames(gameId);
          
          // Find linked games that are also in confirmed list
          final confirmedGameMaps = _convertGameAssignmentsToMaps(acceptedGames);
          final linkedConfirmedGames = <GameAssignment>[];
          
          // Add the current game
          linkedConfirmedGames.add(assignment);
          
          // Add other linked games that are confirmed
          for (final linkedGame in linkedGames) {
            final linkedGameId = linkedGame['id'] as int?;
            if (linkedGameId != null && linkedGameId != gameId) {
              final matchingConfirmed = confirmedGameMaps.where(
                (g) => (g['id'] as int?) == linkedGameId,
              );
              if (matchingConfirmed.isNotEmpty) {
                final matchingAssignment = matchingConfirmed.first['_assignment'] as GameAssignment?;
                if (matchingAssignment != null) {
                  linkedConfirmedGames.add(matchingAssignment);
                }
              }
            }
          }
          
          _navigateToLinkedGameDetails(assignment, linkedConfirmedGames);
        } else {
          _navigateToGameDetails(assignment);
        }
      } catch (e) {
        debugPrint('Error checking linked games: $e');
        // Fallback to single game details
        _navigateToGameDetails(assignment);
      }
    }
  }

  void _navigateToGameDetails(GameAssignment assignment) async {
    final result = await Navigator.pushNamed(
      context,
      '/official_game_details', 
      arguments: assignment,
    );
    
    // If the user backed out of the game, refresh the data
    if (result == true) {
      // Show a subtle loading indicator while refreshing
      await _loadData();
    }
  }

  void _navigateToLinkedGameDetails(GameAssignment primaryAssignment, List<GameAssignment> linkedGames) async {
    // Pass both the primary game and the linked games list
    final arguments = {
      'assignment': primaryAssignment,
      'linkedGames': linkedGames,
      'isLinkedView': true,
    };
    
    final result = await Navigator.pushNamed(
      context,
      '/official_game_details', 
      arguments: arguments,
    );
    
    // If the user backed out of any games, refresh the data
    if (result == true) {
      await _loadData();
    }
  }

  void _showDismissedGames() async {
    try {
      if (_currentOfficial?.id == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Official information not found')),
        );
        return;
      }

      final dismissedGames = await _assignmentRepo.getDismissedGamesForOfficial(_currentOfficial!.id!);
      
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            backgroundColor: darkSurface,
            title: const Text(
              'Dismissed Games',
              style: TextStyle(color: efficialsYellow, fontWeight: FontWeight.bold),
            ),
            content: SizedBox(
              width: double.maxFinite,
              height: 400,
              child: dismissedGames.isEmpty
                  ? const Center(
                      child: Text(
                        'No dismissed games',
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  : ListView.builder(
                      itemCount: dismissedGames.length,
                      itemBuilder: (context, index) {
                        final dismissal = dismissedGames[index];
                        final sportName = dismissal.sportName ?? 'Sport';
                        final opponent = dismissal.opponent ?? 'TBD';
                        final homeTeam = dismissal.homeTeam ?? 'TBD';
                        final gameTitle = opponent != 'TBD' && homeTeam != 'TBD' 
                            ? '$opponent @ $homeTeam' 
                            : (opponent != 'TBD' ? opponent : homeTeam);
                        
                        return Card(
                          color: darkBackground,
                          child: ListTile(
                            leading: const Icon(Icons.remove_circle_outline, color: Colors.red),
                            title: Text(
                              '$sportName: $gameTitle',
                              style: const TextStyle(color: Colors.white),
                            ),
                            subtitle: dismissal.reason != null 
                                ? Text(
                                    'Reason: ${dismissal.reason}',
                                    style: TextStyle(color: Colors.grey[400]),
                                  )
                                : null,
                            trailing: TextButton(
                              onPressed: () => _undismissFromDialog(dismissal),
                              child: const Text(
                                'Restore',
                                style: TextStyle(color: efficialsYellow),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close', style: TextStyle(color: Colors.grey)),
              ),
            ],
          );
        },
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load dismissed games: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _undismissFromDialog(GameDismissal dismissal) async {
    try {
      await _assignmentRepo.undismissGame(dismissal.gameId, dismissal.officialId);
      
      Navigator.of(context).pop(); // Close dialog
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Game restored to available list'),
          backgroundColor: Colors.green,
        ),
      );
      
      // Reload data to refresh available games
      await _loadData();
      
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to restore game: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _dismissGame(Map<String, dynamic> game) async {
    try {
      final gameId = game['id'] as int?;
      if (gameId == null || _currentOfficial?.id == null) {
        throw Exception('Missing required information');
      }
      
      await _assignmentRepo.dismissGame(gameId, _currentOfficial!.id!, null);
      
      // Remove from UI immediately
      setState(() {
        availableGames.removeWhere((g) => g['id'] == gameId);
      });
      
      // Show undo option briefly
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Game dismissed'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
          action: SnackBarAction(
            label: 'Undo',
            textColor: Colors.white,
            onPressed: () => _undismissGame(gameId, game),
          ),
        ),
      );
      
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to dismiss game: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _undismissGame(int gameId, Map<String, dynamic> game) async {
    try {
      if (_currentOfficial?.id == null) {
        throw Exception('Missing official information');
      }
      
      await _assignmentRepo.undismissGame(gameId, _currentOfficial!.id!);
      
      // Add back to UI
      setState(() {
        availableGames.add(game);
      });
      
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Game restored to available list'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
      
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to restore game: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showExpressInterestDialog(Map<String, dynamic> game) {
    // Get response timeframe from game data (fallback to 24 hours if not set)
    final responseTime = game['response_timeframe'] ?? 24;
    final responseUnit = game['response_unit'] ?? 'hours';
    
    // Format the timeframe text
    String timeframeText = _formatResponseTimeframe(responseTime, responseUnit);
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: darkSurface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(Icons.sports, color: efficialsYellow, size: 24),
              const SizedBox(width: 8),
              const Text(
                'Express Interest',
                style: TextStyle(color: efficialsYellow, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Are you sure you want to express interest in this game?',
                style: TextStyle(color: Colors.grey[300], fontSize: 16),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue[300], size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'You will be notified by the Scheduler whether you\'ve been selected for the game within $timeframeText.',
                        style: TextStyle(color: Colors.blue[300], fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.grey[400],
                side: BorderSide(color: Colors.grey[600]!),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _expressInterest(game);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: efficialsYellow,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              child: const Text('Express Interest'),
            ),
          ],
        );
      },
    );
  }

  void _showClaimGameDialog(Map<String, dynamic> game) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: darkSurface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(Icons.sports, color: Colors.green, size: 24),
              const SizedBox(width: 8),
              const Text(
                'Claim Game',
                style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Are you sure you want to claim this game?',
                style: TextStyle(color: Colors.grey[300], fontSize: 16),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green[300], size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'You will be assigned to this game and the Scheduler will be notified.',
                        style: TextStyle(color: Colors.green[300], fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.grey[400],
                side: BorderSide(color: Colors.grey[600]!),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _claimGame(game);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              child: const Text('Claim Game'),
            ),
          ],
        );
      },
    );
  }

  String _formatResponseTimeframe(int time, String unit) {
    if (time == 1) {
      switch (unit) {
        case 'hours':
          return '1 hour';
        case 'days':
          return '1 day';
        case 'weeks':
          return '1 week';
        default:
          return '1 hour';
      }
    } else {
      return '$time $unit';
    }
  }

  void _expressInterest(Map<String, dynamic> game) async {
    final gameId = game['game_id'] ?? game['id'];
    final officialId = _currentOfficial!.id!;
    final feeAmount = _parseDoubleFromString(game['game_fee']);
    
    
    // Immediately update the UI state for responsive UX
    setState(() {
      // Remove from available games
      final removedCount = availableGames.length;
      availableGames.removeWhere((availableGame) => 
        availableGame['id'] == game['id'] || 
        (availableGame['game_id'] == game['game_id'] && game['game_id'] != null)
      );
      
      // Create a GameAssignment object for pending list using fromMap
      final pendingAssignmentMap = {
        'id': null, // Will be set by database
        'game_id': gameId,
        'official_id': officialId,
        'status': 'pending',
        'assigned_by': officialId, // Official is expressing interest
        'assigned_at': DateTime.now().toIso8601String(),
        'fee_amount': feeAmount,
        // Additional fields from game data
        'date': game['date'],
        'time': game['time'],
        'sport_name': game['sport_name'],
        'opponent': game['opponent'],
        'location_name': game['location_name'],
      };
      
      final pendingAssignment = GameAssignment.fromMap(pendingAssignmentMap);
      
      // Add to pending games
      pendingGames.add(pendingAssignment);
      
    });
    
    // Show immediate feedback
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Interest expressed in ${game['sport_name']} game'),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
    
    // Persist to database in the background
    try {
      final assignmentId = await _assignmentRepo.expressInterest(gameId, officialId, feeAmount);
      print('Successfully persisted interest expression to database with ID: $assignmentId');
      
      // Update the assignment in the UI with the actual database ID
      if (mounted) {
        setState(() {
          final index = pendingGames.indexWhere((assignment) => 
            assignment.gameId == gameId && assignment.officialId == officialId && assignment.id == null
          );
          
          if (index != -1) {
            // Create an updated assignment with the actual ID
            final updatedAssignmentMap = {
              'id': assignmentId,
              'game_id': gameId,
              'official_id': officialId,
              'status': 'pending',
              'assigned_by': officialId,
              'assigned_at': DateTime.now().toIso8601String(),
              'fee_amount': feeAmount,
              // Additional fields from game data
              'date': game['date'],
              'time': game['time'],
              'sport_name': game['sport_name'],
              'opponent': game['opponent'],
              'location_name': game['location_name'],
            };
            
            final updatedAssignment = GameAssignment.fromMap(updatedAssignmentMap);
            pendingGames[index] = updatedAssignment;
          }
        });
      }
    } catch (e) {
      print('Error persisting interest expression: $e');
      
      // Revert UI changes if database operation failed
      setState(() {
        // Add the game back to available games
        availableGames.add(game);
        
        // Remove from pending games
        pendingGames.removeWhere((assignment) => 
          assignment.gameId == gameId && assignment.officialId == officialId
        );
      });
      
      // Show error message
      if (mounted) {
        String errorMessage = 'Failed to express interest. Please try again.';
        
        // Provide specific error messages for common issues
        if (e.toString().contains('No active crew found for this crew chief')) {
          errorMessage = 'You must be part of an active crew to express interest in crew-hire games. Please contact your administrator to set up your crew.';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  void _claimGame(Map<String, dynamic> game) async {
    final gameId = game['game_id'] ?? game['id'];
    final officialId = _currentOfficial!.id!;
    
    // Show loading indicator
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Claiming ${game['sport_name']} game...'),
          backgroundColor: Colors.blue,
          duration: const Duration(seconds: 1),
        ),
      );
    }
    
    // Attempt to claim the game in the database
    try {
      final success = await _assignmentRepo.claimGameForOfficial(gameId, officialId);
      if (!success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Game is no longer available or you are not eligible to claim it'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }
      
      print('Successfully claimed game $gameId for official $officialId');
      
      // Reload the data to reflect the changes
      if (mounted) {
        await _loadData();
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Successfully claimed ${game['sport_name']} game!'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('Error persisting game claim: $e');
      
      // Reload data to revert any UI changes
      if (mounted) {
        await _loadData();
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to claim game. Please try again.'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  // Helper method to safely parse fee amount
  double? _parseDoubleFromString(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      return double.tryParse(value);
    }
    return null;
  }

  // Helper methods for sports
  IconData _getSportIcon(String sport) {
    switch (sport.toLowerCase()) {
      case 'basketball':
        return Icons.sports_basketball;
      case 'football':
        return Icons.sports_football;
      case 'baseball':
        return Icons.sports_baseball;
      case 'volleyball':
        return Icons.sports_volleyball;
      default:
        return Icons.sports;
    }
  }

  Color _getSportColor(String sport) {
    switch (sport.toLowerCase()) {
      case 'basketball':
        return Colors.orange;
      case 'football':
        return Colors.brown;
      case 'baseball':
        return Colors.blue;
      case 'volleyball':
        return Colors.purple;
      default:
        return efficialsYellow;
    }
  }

  // Helper methods for formatting
  String _formatDate(DateTime date) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                   'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    
    final dayName = days[date.weekday - 1];
    final monthName = months[date.month - 1];
    
    return '$dayName, $monthName ${date.day}';
  }
  
  String _formatTime(DateTime time) {
    final hour = time.hour;
    final minute = time.minute;
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    
    return '$displayHour:${minute.toString().padLeft(2, '0')} $period';
  }
  
  String _formatAvailableGameDate(Map<String, dynamic> game) {
    if (game['date'] == null) return 'TBD';
    try {
      final date = DateTime.parse(game['date']);
      return _formatDate(date);
    } catch (e) {
      return 'TBD';
    }
  }
  
  String _formatAvailableGameTime(Map<String, dynamic> game) {
    if (game['time'] == null) return 'TBD';
    try {
      final time = DateTime.parse('1970-01-01 ${game['time']}');
      return _formatTime(time);
    } catch (e) {
      return 'TBD';
    }
  }
  
  String _formatGameTitle(Map<String, dynamic> game) {
    final opponent = game['opponent'] as String?;
    final scheduleHomeTeam = game['schedule_home_team_name'] as String?;
    final queryHomeTeam = game['home_team'] as String?;
    
    final homeTeam = (scheduleHomeTeam != null && scheduleHomeTeam.trim().isNotEmpty) 
        ? scheduleHomeTeam 
        : (queryHomeTeam != null && queryHomeTeam.trim().isNotEmpty) 
            ? queryHomeTeam 
            : 'Home Team';
    
    // Debug logging to track home team issues
    debugPrint('🏠 Game ${game['id']} title formatting:');
    debugPrint('  opponent: "$opponent"');
    debugPrint('  schedule_home_team_name: "${game['schedule_home_team_name']}"');
    debugPrint('  home_team: "${game['home_team']}"');
    debugPrint('  final homeTeam: "$homeTeam"');
    
    if (opponent != null && homeTeam != null && homeTeam.trim().isNotEmpty && homeTeam != 'Home Team') {
      final result = '$opponent @ $homeTeam';
      debugPrint('  result: "$result"');
      return result;
    } else if (opponent != null) {
      debugPrint('  returning opponent only: "$opponent"');
      return opponent;
    } else {
      debugPrint('  returning TBD');
      return 'TBD';
    }
  }
  
  String _formatAssignmentTitle(GameAssignment assignment) {
    final opponent = assignment.opponent;
    final homeTeam = assignment.homeTeam;
    
    if (opponent != null && homeTeam != null) {
      return '$opponent @ $homeTeam';
    } else if (opponent != null) {
      return opponent;
    } else {
      return 'TBD';
    }
  }

  Widget _buildCrewManagementCard() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Card(
        color: efficialsBlack,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const CrewDashboardScreen(),
              ),
            ).then((_) => _loadInvitationsCount()); // Refresh count when returning
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  efficialsYellow.withOpacity(0.1),
                  efficialsYellow.withOpacity(0.05),
                ],
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: efficialsYellow,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.groups,
                    color: efficialsBlack,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Crew Management',
                        style: TextStyle(
                          color: efficialsWhite,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Create or join crews to work games together',
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 14,
                        ),
                      ),
                      if (_pendingInvitationsCount > 0) ...[
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const CrewInvitationsScreen(),
                              ),
                            ).then((_) => _loadInvitationsCount()); // Refresh count when returning
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.8),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '$_pendingInvitationsCount pending invitation${_pendingInvitationsCount == 1 ? '' : 's'}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.grey[500],
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

}