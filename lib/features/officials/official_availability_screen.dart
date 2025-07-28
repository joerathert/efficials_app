import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../shared/theme.dart';
import '../../shared/models/database_models.dart';

class OfficialAvailabilityScreen extends StatefulWidget {
  final List<GameAssignment>? acceptedGames;
  
  const OfficialAvailabilityScreen({
    super.key,
    this.acceptedGames,
  });

  @override
  State<OfficialAvailabilityScreen> createState() => _OfficialAvailabilityScreenState();
}

class _OfficialAvailabilityScreenState extends State<OfficialAvailabilityScreen> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  // Mock availability data
  Map<DateTime, String> availability = {
    DateTime.now().add(const Duration(days: 1)): 'available',
    DateTime.now().add(const Duration(days: 2)): 'unavailable',
    DateTime.now().add(const Duration(days: 3)): 'available',
    DateTime.now().add(const Duration(days: 5)): 'busy',
    DateTime.now().add(const Duration(days: 7)): 'available',
  };

  bool _isGenerallyAvailable = true;
  bool _weekdayAvailability = true;
  bool _weekendAvailability = true;
  bool _eveningAvailability = true;

  List<GameAssignment> get _acceptedGames => widget.acceptedGames ?? [];

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
                    'My Availability',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: efficialsYellow,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _isGenerallyAvailable ? Colors.green.withOpacity(0.2) : Colors.red.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _isGenerallyAvailable ? Icons.check_circle : Icons.cancel,
                          size: 16,
                          color: _isGenerallyAvailable ? Colors.green : Colors.red,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _isGenerallyAvailable ? 'Available' : 'Unavailable',
                          style: TextStyle(
                            color: _isGenerallyAvailable ? Colors.green : Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
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
              child: TableCalendar<String>(
                firstDay: DateTime.utc(2020, 1, 1),
                lastDay: DateTime.utc(2030, 12, 31),
                focusedDay: _focusedDay,
                calendarFormat: _calendarFormat,
                eventLoader: (day) {
                  final dayKey = DateTime(day.year, day.month, day.day);
                  List<String> events = [];
                  
                  // Add availability status
                  if (availability.containsKey(dayKey)) {
                    events.add(availability[dayKey]!);
                  }
                  
                  // Add accepted games for this day
                  for (final game in _acceptedGames) {
                    if (game.gameDate != null) {
                      final gameDate = DateTime(
                        game.gameDate!.year,
                        game.gameDate!.month,
                        game.gameDate!.day,
                      );
                      if (gameDate == dayKey) {
                        events.add('game');
                      }
                    }
                  }
                  
                  return events;
                },
                startingDayOfWeek: StartingDayOfWeek.sunday,
                calendarBuilders: CalendarBuilders(
                  markerBuilder: (context, day, events) {
                    if (events.isNotEmpty) {
                      final eventList = events.cast<String>();
                      final hasGame = eventList.contains('game');
                      
                      if (hasGame) {
                        // Game marker has priority
                        return Container(
                          width: 12,
                          height: 12,
                          margin: const EdgeInsets.only(top: 2),
                          decoration: BoxDecoration(
                            color: efficialsYellow,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 1),
                          ),
                          child: Icon(
                            Icons.sports,
                            size: 8,
                            color: Colors.black,
                          ),
                        );
                      } else {
                        // Show availability status
                        final status = eventList.first;
                        Color markerColor;
                        switch (status) {
                          case 'available':
                            markerColor = Colors.green;
                            break;
                          case 'unavailable':
                            markerColor = Colors.red;
                            break;
                          case 'busy':
                            markerColor = Colors.orange;
                            break;
                          default:
                            markerColor = Colors.grey;
                        }
                        return Container(
                          width: 8,
                          height: 8,
                          margin: const EdgeInsets.only(top: 2),
                          decoration: BoxDecoration(
                            color: markerColor,
                            shape: BoxShape.circle,
                          ),
                        );
                      }
                    }
                    return null;
                  },
                ),
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
                  setState(() {
                    _selectedDay = selectedDay;
                    _focusedDay = focusedDay;
                  });
                  _showAvailabilityDialog(selectedDay);
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

            // Legend
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: darkSurface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Legend',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: efficialsYellow,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildLegendItem('Available', Colors.green),
                          _buildLegendItem('Unavailable', Colors.red),
                          _buildLegendItem('Busy', Colors.orange),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildGameLegendItem('Confirmed Game', efficialsYellow),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // General Preferences
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  color: darkSurface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'General Preferences',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: efficialsYellow,
                        ),
                      ),
                      const SizedBox(height: 16),
                      SwitchListTile(
                        title: const Text('Generally Available', style: TextStyle(color: Colors.white)),
                        subtitle: const Text('Accept assignments when available', style: TextStyle(color: Colors.grey)),
                        value: _isGenerallyAvailable,
                        onChanged: (value) {
                          setState(() {
                            _isGenerallyAvailable = value;
                          });
                        },
                        activeColor: efficialsYellow,
                      ),
                      SwitchListTile(
                        title: const Text('Weekday Games', style: TextStyle(color: Colors.white)),
                        subtitle: const Text('Monday - Friday games', style: TextStyle(color: Colors.grey)),
                        value: _weekdayAvailability,
                        onChanged: (value) {
                          setState(() {
                            _weekdayAvailability = value;
                          });
                        },
                        activeColor: efficialsYellow,
                      ),
                      SwitchListTile(
                        title: const Text('Weekend Games', style: TextStyle(color: Colors.white)),
                        subtitle: const Text('Saturday - Sunday games', style: TextStyle(color: Colors.grey)),
                        value: _weekendAvailability,
                        onChanged: (value) {
                          setState(() {
                            _weekendAvailability = value;
                          });
                        },
                        activeColor: efficialsYellow,
                      ),
                      SwitchListTile(
                        title: const Text('Evening Games', style: TextStyle(color: Colors.white)),
                        subtitle: const Text('Games after 6:00 PM', style: TextStyle(color: Colors.grey)),
                        value: _eveningAvailability,
                        onChanged: (value) {
                          setState(() {
                            _eveningAvailability = value;
                          });
                        },
                        activeColor: efficialsYellow,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildGameLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 1),
          ),
          child: Icon(
            Icons.sports,
            size: 8,
            color: Colors.black,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  void _showAvailabilityDialog(DateTime selectedDay) {
    final dayKey = DateTime(selectedDay.year, selectedDay.month, selectedDay.day);
    final currentStatus = availability[dayKey] ?? 'available';
    
    // Check if there's a game on this day
    final gamesOnDay = _acceptedGames.where((game) {
      if (game.gameDate != null) {
        final gameDate = DateTime(
          game.gameDate!.year,
          game.gameDate!.month,
          game.gameDate!.day,
        );
        return gameDate == dayKey;
      }
      return false;
    }).toList();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: darkSurface,
        title: Text(
          'Set Availability',
          style: const TextStyle(color: efficialsYellow),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _formatDate(selectedDay),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // Show games if any
            if (gamesOnDay.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: efficialsYellow.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: efficialsYellow.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.sports, color: efficialsYellow, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Games on this day:',
                          style: TextStyle(
                            color: efficialsYellow,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ...gamesOnDay.map((game) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        '${game.sportName ?? 'Game'} - ${_formatGameTime(game.gameTime)} - \$${game.feeAmount?.toStringAsFixed(2) ?? '0.00'}',
                        style: TextStyle(
                          color: Colors.grey[300],
                          fontSize: 14,
                        ),
                      ),
                    )).toList(),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            
            // Availability settings
            Column(
              children: [
                RadioListTile<String>(
                  title: const Text('Available', style: TextStyle(color: Colors.white)),
                  value: 'available',
                  groupValue: currentStatus,
                  onChanged: gamesOnDay.isEmpty ? (value) {
                    Navigator.pop(context, value);
                  } : null,
                  activeColor: efficialsYellow,
                ),
                RadioListTile<String>(
                  title: const Text('Unavailable', style: TextStyle(color: Colors.white)),
                  value: 'unavailable',
                  groupValue: currentStatus,
                  onChanged: gamesOnDay.isEmpty ? (value) {
                    Navigator.pop(context, value);
                  } : null,
                  activeColor: efficialsYellow,
                ),
                RadioListTile<String>(
                  title: const Text('Busy/Has Game', style: TextStyle(color: Colors.white)),
                  value: 'busy',
                  groupValue: currentStatus,
                  onChanged: gamesOnDay.isEmpty ? (value) {
                    Navigator.pop(context, value);
                  } : null,
                  activeColor: efficialsYellow,
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: efficialsYellow)),
          ),
          if (availability.containsKey(dayKey))
            TextButton(
              onPressed: () {
                setState(() {
                  availability.remove(dayKey);
                });
                Navigator.pop(context);
              },
              child: const Text('Remove', style: TextStyle(color: Colors.red)),
            ),
        ],
      ),
    ).then((selectedStatus) {
      if (selectedStatus != null) {
        setState(() {
          availability[dayKey] = selectedStatus;
        });
      }
    });
  }

  String _formatDate(DateTime date) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    const weekdays = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
    
    return '${weekdays[date.weekday % 7]}, ${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  String _formatGameTime(DateTime? time) {
    if (time == null) return 'TBD';
    
    final hour = time.hour;
    final minute = time.minute;
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    
    return '$displayHour:${minute.toString().padLeft(2, '0')} $period';
  }
}