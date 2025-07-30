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
import '../../shared/models/database_models.dart';

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
                : SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final assignment = acceptedGames[index];
                        final isNext = index == 0;
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                          child: _buildEnhancedGameCard(assignment, isNext),
                        );
                      },
                      childCount: acceptedGames.length,
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
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: availableGames.length,
                    itemBuilder: (context, index) {
                      final game = availableGames[index];
                      return _buildAvailableGameCard(game);
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
          'home_team': game['home_team'],
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
          },
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
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      minimumSize: Size.zero,
                    ),
                    child: const Text(
                      'Claim',
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to express interest. Please try again.'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
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
    final homeTeam = game['home_team'] as String?;
    
    if (opponent != null && homeTeam != null) {
      return '$opponent @ $homeTeam';
    } else if (opponent != null) {
      return opponent;
    } else {
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