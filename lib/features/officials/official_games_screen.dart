import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../shared/theme.dart';
import '../../shared/services/repositories/game_assignment_repository.dart';
import '../../shared/services/repositories/official_repository.dart';
import '../../shared/services/user_session_service.dart';
import '../../shared/models/database_models.dart';
import '../../shared/widgets/back_out_dialog.dart';
import '../../shared/widgets/linked_games_back_out_dialog.dart';
import 'package:intl/intl.dart';

class OfficialGamesScreen extends StatefulWidget {
  const OfficialGamesScreen({super.key});

  @override
  State<OfficialGamesScreen> createState() => _OfficialGamesScreenState();
}

class _OfficialGamesScreenState extends State<OfficialGamesScreen> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  String _selectedFilter = 'All';

  // Repositories
  final GameAssignmentRepository _assignmentRepo = GameAssignmentRepository();
  final OfficialRepository _officialRepo = OfficialRepository();

  // State
  List<GameAssignment> games = [];
  bool _isLoading = true;
  Official? _currentOfficial;

  @override
  void initState() {
    super.initState();
    _loadGames();
  }

  Future<void> _loadGames() async {
    try {
      setState(() {
        _isLoading = true;
      });

      // Get current user session
      final userSession = UserSessionService.instance;
      final userId = await userSession.getCurrentUserId();
      final userType = await userSession.getCurrentUserType();

      if (userId == null || userType != 'official') {
        return;
      }

      // Get the official record
      _currentOfficial =
          await _officialRepo.getOfficialByOfficialUserId(userId);

      if (_currentOfficial == null) {
        return;
      }

      // Load all assignments for this official
      final assignments = await _assignmentRepo
          .getAssignmentsForOfficial(_currentOfficial!.id!);

      if (mounted) {
        setState(() {
          games = assignments;
        });
      }
    } catch (e) {
      print('Error loading games: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  List<GameAssignment> get filteredGames {
    List<GameAssignment> filtered = games;

    // Filter by status
    if (_selectedFilter == 'Upcoming') {
      filtered = filtered
          .where((assignment) =>
              (assignment.gameDate?.isAfter(DateTime.now()) ?? false) ||
              assignment.status == 'accepted')
          .toList();
    } else if (_selectedFilter == 'Completed') {
      filtered = filtered
          .where((assignment) => assignment.status == 'completed')
          .toList();
    }

    // Filter by selected day if any
    if (_selectedDay != null) {
      filtered = filtered
          .where((assignment) =>
              assignment.gameDate != null &&
              isSameDay(assignment.gameDate!, _selectedDay))
          .toList();
    }

    // Sort by date (newest first)
    filtered.sort((a, b) {
      final dateA = a.gameDate ?? DateTime(1970);
      final dateB = b.gameDate ?? DateTime(1970);
      return dateB.compareTo(dateA);
    });
    return filtered;
  }

  List<DateTime> get gameDays {
    return games
        .where((assignment) => assignment.gameDate != null)
        .map((assignment) => assignment.gameDate!)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: darkBackground,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'My Games',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: efficialsYellow,
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (String value) {
                      setState(() {
                        _selectedFilter = value;
                      });
                    },
                    itemBuilder: (BuildContext context) => [
                      const PopupMenuItem(
                          value: 'All', child: Text('All Games')),
                      const PopupMenuItem(
                          value: 'Upcoming', child: Text('Upcoming')),
                      const PopupMenuItem(
                          value: 'Completed', child: Text('Completed')),
                    ],
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: darkSurface,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _selectedFilter,
                            style: const TextStyle(color: Colors.white),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.arrow_drop_down,
                              color: Colors.white),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Calendar
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: darkSurface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: TableCalendar<DateTime>(
                firstDay: DateTime.utc(2020, 1, 1),
                lastDay: DateTime.utc(2030, 12, 31),
                focusedDay: _focusedDay,
                calendarFormat: _calendarFormat,
                eventLoader: (day) {
                  return gameDays
                      .where((gameDay) => isSameDay(gameDay, day))
                      .toList();
                },
                startingDayOfWeek: StartingDayOfWeek.sunday,
                calendarStyle: CalendarStyle(
                  outsideDaysVisible: false,
                  weekendTextStyle: const TextStyle(color: Colors.white),
                  holidayTextStyle: const TextStyle(color: Colors.white),
                  defaultTextStyle: const TextStyle(color: Colors.white),
                  todayDecoration: BoxDecoration(
                    color: efficialsYellow.withOpacity(0.3),
                    shape: BoxShape.circle,
                  ),
                  selectedDecoration: const BoxDecoration(
                    color: efficialsYellow,
                    shape: BoxShape.circle,
                  ),
                  selectedTextStyle: const TextStyle(color: efficialsBlack),
                  markerDecoration: const BoxDecoration(
                    color: Colors.orange,
                    shape: BoxShape.circle,
                  ),
                ),
                headerStyle: const HeaderStyle(
                  formatButtonVisible: false,
                  titleCentered: true,
                  titleTextStyle: TextStyle(
                    color: efficialsYellow,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  leftChevronIcon:
                      Icon(Icons.chevron_left, color: Colors.white),
                  rightChevronIcon:
                      Icon(Icons.chevron_right, color: Colors.white),
                ),
                daysOfWeekStyle: const DaysOfWeekStyle(
                  weekendStyle: TextStyle(color: Colors.grey),
                  weekdayStyle: TextStyle(color: Colors.grey),
                ),
                selectedDayPredicate: (day) {
                  return isSameDay(_selectedDay, day);
                },
                onDaySelected: (selectedDay, focusedDay) {
                  if (!isSameDay(_selectedDay, selectedDay)) {
                    setState(() {
                      _selectedDay = selectedDay;
                      _focusedDay = focusedDay;
                    });
                  }
                },
                onFormatChanged: (format) {
                  if (_calendarFormat != format) {
                    setState(() {
                      _calendarFormat = format;
                    });
                  }
                },
                onPageChanged: (focusedDay) {
                  _focusedDay = focusedDay;
                },
              ),
            ),

            const SizedBox(height: 20),

            // Games List
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _selectedDay != null
                              ? 'Games on ${_formatDate(_selectedDay!)}'
                              : 'All Games',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: efficialsYellow,
                          ),
                        ),
                        if (_selectedDay != null)
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _selectedDay = null;
                              });
                            },
                            child: const Text(
                              'Clear Filter',
                              style: TextStyle(color: efficialsYellow),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: _isLoading
                          ? const Center(
                              child: CircularProgressIndicator(
                                  color: efficialsYellow),
                            )
                          : filteredGames.isEmpty
                              ? _buildEmptyState()
                              : ListView.builder(
                                  itemCount: filteredGames.length,
                                  itemBuilder: (context, index) {
                                    return _buildGameCard(filteredGames[index]);
                                  },
                                ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGameCard(GameAssignment assignment) {
    final gameDate = assignment.gameDate;
    final isUpcoming = gameDate?.isAfter(DateTime.now()) ?? false;
    final isConfirmed = assignment.status == 'accepted';
    final statusColor =
        assignment.status == 'completed' ? Colors.green : efficialsYellow;

    final sportName = assignment.sportName ?? 'Sport';
    final locationName = assignment.locationName ?? 'TBD';
    final fee = assignment.feeAmount ?? 0.0;

    final dateString = gameDate != null ? _formatDate(gameDate) : 'TBD';
    final timeString =
        assignment.gameTime != null ? _formatTime(assignment.gameTime!) : 'TBD';

    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(
          context,
          '/available_game_details',
          arguments: assignment,
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: darkSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border(left: BorderSide(color: statusColor, width: 4)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      sportName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: efficialsYellow,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        assignment.status.toUpperCase(),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: statusColor,
                        ),
                      ),
                    ),
                  ],
                ),
                Text(
                  '\$${fee.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
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
                Expanded(
                  child: Text(
                    locationName,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[400],
                    ),
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
                  'Position: ${assignment.position ?? 'Official'}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[400],
                  ),
                ),
              ],
            ),
            if (isUpcoming) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.pushNamed(
                          context,
                          '/available_game_details',
                          arguments: assignment,
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: efficialsYellow,
                        side: const BorderSide(color: efficialsYellow),
                      ),
                      child: const Text('View Details'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        // TODO: Navigate to game location
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: efficialsYellow,
                        foregroundColor: efficialsBlack,
                      ),
                      child: const Text('Directions'),
                    ),
                  ),
                  if (isConfirmed) ...[
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _showBackOutDialog(assignment),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                        ),
                        child: const Text('Back Out'),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.sports, size: 64, color: Colors.grey[600]),
          const SizedBox(height: 16),
          Text(
            _selectedDay != null ? 'No games on this date' : 'No games found',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[400],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _selectedDay != null
                ? 'Try selecting a different date'
                : 'Your assigned games will appear here',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    const weekdays = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

    return '${weekdays[date.weekday % 7]}, ${months[date.month - 1]} ${date.day}';
  }

  String _formatTime(DateTime time) {
    final hour = time.hour;
    final minute = time.minute;
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);

    return '$displayHour:${minute.toString().padLeft(2, '0')} $period';
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

  Future<void> _showBackOutDialog(GameAssignment assignment) async {
    final sportName = assignment.sportName ?? 'Sport';
    final opponent = assignment.opponent;
    final homeTeam = assignment.homeTeam;
    final gameDate = assignment.gameDate;
    final gameTime = assignment.gameTime;
    final locationName = assignment.locationName ?? 'TBD';

    String gameTitle = _formatAssignmentTitle(assignment);
    String dateString = gameDate != null ? _formatDate(gameDate) : 'TBD';
    String timeString = gameTime != null ? _formatTime(gameTime) : 'TBD';

    final gameSummary =
        '$sportName: $gameTitle\n$dateString at $timeString\n$locationName';

    try {
      print('🎯 Back out clicked for assignment ID: ${assignment.id}');

      // Check if this assignment has linked games
      final linkedAssignments =
          await _assignmentRepo.getLinkedAssignments(assignment.id!);

      print('🔗 Found ${linkedAssignments.length} linked assignments');

      if (linkedAssignments.isNotEmpty) {
        print('🚨 Showing linked games back out dialog');
        // Add the current assignment to the list
        final allLinkedAssignments = [assignment, ...linkedAssignments];

        // Show linked games back out dialog
        final result = await showDialog<bool>(
          context: context,
          builder: (BuildContext context) {
            return LinkedGamesBackOutDialog(
              linkedAssignments: allLinkedAssignments,
              onConfirmBackOut: (String reason) =>
                  _handleLinkedBackOut(allLinkedAssignments, reason),
            );
          },
        );

        if (result == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  'Successfully backed out of ${allLinkedAssignments.length} linked games'),
              backgroundColor: Colors.green,
            ),
          );
          _loadGames(); // Reload games to reflect the change
        }
      } else {
        print('📱 Showing regular back out dialog for single game');
        // Show regular back out dialog for single game
        final result = await showDialog<bool>(
          context: context,
          builder: (BuildContext context) {
            return BackOutDialog(
              gameSummary: gameSummary,
              onConfirmBackOut: (String reason) =>
                  _handleBackOut(assignment, reason),
            );
          },
        );

        if (result == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Successfully backed out of game'),
              backgroundColor: Colors.green,
            ),
          );
          _loadGames(); // Reload games to reflect the change
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error checking for linked games: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _handleBackOut(GameAssignment assignment, String reason) async {
    if (assignment.id == null) {
      throw Exception('Assignment ID is null - cannot back out of game');
    }
    await _assignmentRepo.backOutOfGame(assignment.id!, reason);
  }

  Future<void> _handleLinkedBackOut(
      List<GameAssignment> assignments, String reason) async {
    final assignmentIds = assignments
        .where((assignment) => assignment.id != null)
        .map((assignment) => assignment.id!)
        .toList();

    if (assignmentIds.isEmpty) {
      throw Exception(
          'No valid assignment IDs found - cannot back out of games');
    }

    await _assignmentRepo.backOutOfLinkedGames(assignmentIds, reason);
  }
}
