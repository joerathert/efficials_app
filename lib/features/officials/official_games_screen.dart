import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../shared/theme.dart';

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

  // Mock data for demonstration
  final List<Map<String, dynamic>> games = [
    {
      'id': 1,
      'sport': 'Football',
      'date': DateTime.now().add(const Duration(days: 1)),
      'time': '7:00 PM',
      'school': 'Madison vs Jefferson',
      'location': 'Madison High School',
      'status': 'confirmed',
      'fee': 60.0,
      'position': 'Referee',
    },
    {
      'id': 2,
      'sport': 'Basketball',
      'date': DateTime.now().add(const Duration(days: 2)),
      'time': '1:00 PM',
      'school': 'Adams vs Wilson',
      'location': 'Adams High School',
      'status': 'confirmed',
      'fee': 45.0,
      'position': 'Umpire',
    },
    {
      'id': 3,
      'sport': 'Basketball',
      'date': DateTime.now().subtract(const Duration(days: 1)),
      'time': '6:30 PM',
      'school': 'Central vs North',
      'location': 'Central High School',
      'status': 'completed',
      'fee': 45.0,
      'position': 'Referee',
    },
    {
      'id': 4,
      'sport': 'Football',
      'date': DateTime.now().subtract(const Duration(days: 7)),
      'time': '7:00 PM',
      'school': 'East vs West',
      'location': 'East High School',
      'status': 'completed',
      'fee': 60.0,
      'position': 'Referee',
    },
  ];

  List<Map<String, dynamic>> get filteredGames {
    List<Map<String, dynamic>> filtered = games;

    // Filter by status
    if (_selectedFilter == 'Upcoming') {
      filtered = filtered.where((game) => 
        game['date'].isAfter(DateTime.now()) || 
        game['status'] == 'confirmed'
      ).toList();
    } else if (_selectedFilter == 'Completed') {
      filtered = filtered.where((game) => game['status'] == 'completed').toList();
    }

    // Filter by selected day if any
    if (_selectedDay != null) {
      filtered = filtered.where((game) =>
        isSameDay(game['date'], _selectedDay)
      ).toList();
    }

    // Sort by date
    filtered.sort((a, b) => b['date'].compareTo(a['date']));
    return filtered;
  }

  List<DateTime> get gameDays {
    return games.map((game) => game['date'] as DateTime).toList();
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
                      const PopupMenuItem(value: 'All', child: Text('All Games')),
                      const PopupMenuItem(value: 'Upcoming', child: Text('Upcoming')),
                      const PopupMenuItem(value: 'Completed', child: Text('Completed')),
                    ],
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                          const Icon(Icons.arrow_drop_down, color: Colors.white),
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
                  return gameDays.where((gameDay) => isSameDay(gameDay, day)).toList();
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
                  leftChevronIcon: Icon(Icons.chevron_left, color: Colors.white),
                  rightChevronIcon: Icon(Icons.chevron_right, color: Colors.white),
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
                      child: filteredGames.isEmpty
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

  Widget _buildGameCard(Map<String, dynamic> game) {
    final isUpcoming = game['date'].isAfter(DateTime.now());
    final statusColor = game['status'] == 'completed' ? Colors.green : efficialsYellow;

    return Container(
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
                    game['sport'],
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: efficialsYellow,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      game['status'].toString().toUpperCase(),
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
                '\$${game['fee']}',
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
            game['school'],
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
                '${_formatDate(game['date'])} at ${game['time']}',
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
                  game['location'],
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
                'Position: ${game['position']}',
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
                      // TODO: View game details
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: efficialsYellow,
                      side: const BorderSide(color: efficialsYellow),
                    ),
                    child: const Text('View Details'),
                  ),
                ),
                const SizedBox(width: 12),
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
              ],
            ),
          ],
        ],
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
            _selectedDay != null 
              ? 'No games on this date' 
              : 'No games found',
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
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    const weekdays = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    
    return '${weekdays[date.weekday % 7]}, ${months[date.month - 1]} ${date.day}';
  }
}