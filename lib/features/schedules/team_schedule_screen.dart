import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../shared/theme.dart';

class TeamScheduleScreen extends StatefulWidget {
  const TeamScheduleScreen({super.key});

  @override
  State<TeamScheduleScreen> createState() => _TeamScheduleScreenState();
}

class _TeamScheduleScreenState extends State<TeamScheduleScreen> {
  String? teamName;
  List<Map<String, dynamic>> games = [];
  bool isLoading = true;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  List<Map<String, dynamic>> _selectedDayGames = [];
  bool _showOnlyNeedsOfficials = false; // Toggle state for filtering

  @override
  void initState() {
    super.initState();
    _loadTeamInfo();
    _fetchGames();
  }

  Future<void> _loadTeamInfo() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      teamName = prefs.getString('team_name') ?? 'Team';
    });
  }

  Future<void> _fetchGames() async {
    final prefs = await SharedPreferences.getInstance();
    final String? publishedGamesJson = prefs.getString('coach_published_games');
    List<Map<String, dynamic>> allGames = [];

    setState(() {
      games.clear();
      try {
        if (publishedGamesJson != null && publishedGamesJson.isNotEmpty) {
          final published =
              List<Map<String, dynamic>>.from(jsonDecode(publishedGamesJson));
          allGames.addAll(published);
        }

        // Filter games for this team and ensure they have dates
        games = allGames.where((game) {
          final matchesTeam = game['opponent'] == teamName ||
              (game['scheduleName'] != null &&
                  game['scheduleName']!.contains(teamName!));
          final hasDate = game['date'] != null;
          return matchesTeam && hasDate;
        }).toList();

        // Parse date and time objects
        for (var game in games) {
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
        }

        if (games.isNotEmpty) {
          games.sort(
              (a, b) => (a['date'] as DateTime).compareTo(b['date'] as DateTime));
          _focusedDay = games.first['date'] as DateTime;
          // Auto-select the first day with games and show its games
          _selectedDay = _focusedDay;
          _selectedDayGames = _getGamesForDay(_selectedDay!);
        } else {
          _focusedDay = DateTime.now();
        }

        isLoading = false;
      } catch (e) {
        // Handle any parsing errors
        games.clear();
        _focusedDay = DateTime.now();
        isLoading = false;
      }
    });
  }

  List<Map<String, dynamic>> _getGamesForDay(DateTime day) {
    return games.where((game) {
      final gameDate = game['date'] as DateTime?;
      if (gameDate == null) return false;
      final matchesDay = gameDate.year == day.year &&
          gameDate.month == day.month &&
          gameDate.day == day.day;
      if (_showOnlyNeedsOfficials) {
        final hiredOfficials = game['officialsHired'] as int? ?? 0;
        final requiredOfficials =
            int.tryParse(game['officialsRequired']?.toString() ?? '0') ?? 0;
        return matchesDay && hiredOfficials < requiredOfficials;
      }
      return matchesDay;
    }).toList();
  }

  Future<Map<String, dynamic>?> _fetchGameById(int gameId) async {
    final prefs = await SharedPreferences.getInstance();
    final String? gamesJson = prefs.getString('published_games');
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: efficialsWhite),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: efficialsYellow))
          : SingleChildScrollView(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Text(
                          '$teamName Schedule',
                          style: const TextStyle(
                              fontSize: 24, fontWeight: FontWeight.bold, color: efficialsYellow),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${games.length} games scheduled',
                          style: const TextStyle(
                              fontSize: 16, color: efficialsWhite),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TableCalendar(
                        firstDay: DateTime.utc(2020, 1, 1),
                        lastDay: DateTime.utc(2030, 12, 31),
                        focusedDay: _focusedDay,
                        calendarFormat: CalendarFormat.month,
                        selectedDayPredicate: (day) {
                          return _selectedDay != null &&
                              day.year == _selectedDay!.year &&
                              day.month == _selectedDay!.month &&
                              day.day == _selectedDay!.day;
                        },
                        onDaySelected: (selectedDay, focusedDay) {
                          setState(() {
                            _selectedDay = selectedDay;
                            _focusedDay = focusedDay;
                            _selectedDayGames = _getGamesForDay(selectedDay);
                          });
                        },
                        onPageChanged: (focusedDay) {
                          setState(() {
                            _focusedDay = focusedDay;
                          });
                        },
                        eventLoader: (day) {
                          return _getGamesForDay(day);
                        },
                        calendarStyle: CalendarStyle(
                          outsideDaysVisible: false,
                          todayDecoration: BoxDecoration(
                            color: efficialsYellow.withOpacity(0.5),
                            shape: BoxShape.rectangle,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          selectedDecoration: BoxDecoration(
                            color: efficialsYellow,
                            shape: BoxShape.rectangle,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          defaultTextStyle: const TextStyle(
                              fontSize: 16, color: Colors.white),
                          weekendTextStyle: const TextStyle(
                              fontSize: 16, color: Colors.white),
                          outsideTextStyle:
                              const TextStyle(fontSize: 16, color: Colors.grey),
                          markersMaxCount: 0,
                        ),
                        daysOfWeekStyle: DaysOfWeekStyle(
                          weekdayStyle: const TextStyle(fontSize: 14, color: Colors.white),
                          weekendStyle: const TextStyle(fontSize: 14, color: Colors.white),
                          dowTextFormatter: (date, locale) => date.weekday == 7
                              ? 'Sun'
                              : date.weekday == 1
                                  ? 'Mon'
                                  : date.weekday == 2
                                      ? 'Tue'
                                      : date.weekday == 3
                                          ? 'Wed'
                                          : date.weekday == 4
                                              ? 'Thu'
                                              : date.weekday == 5
                                                  ? 'Fri'
                                                  : 'Sat',
                        ),
                        headerStyle: const HeaderStyle(
                          formatButtonVisible: false,
                          titleTextStyle: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                          leftChevronIcon:
                              Icon(Icons.chevron_left, color: efficialsYellow),
                          rightChevronIcon:
                              Icon(Icons.chevron_right, color: efficialsYellow),
                          titleCentered: true,
                        ),
                        calendarBuilders: CalendarBuilders(
                          defaultBuilder: (context, day, focusedDay) {
                            final events = _getGamesForDay(day);
                            final hasEvents = events.isNotEmpty;
                            final isToday = isSameDay(day, DateTime.now());
                            final isOutsideMonth =
                                day.month != focusedDay.month;
                            final isSelected = _selectedDay != null &&
                                day.year == _selectedDay!.year &&
                                day.month == _selectedDay!.month &&
                                day.day == _selectedDay!.day;

                            Color? backgroundColor;
                            Color textColor =
                                isOutsideMonth ? Colors.grey : Colors.white;

                            if (hasEvents) {
                              bool allAway = true;
                              bool allFullyHired = true;
                              bool needsOfficials = false;

                              for (var event in events) {
                                final isEventAway =
                                    event['isAway'] as bool? ?? false;
                                final hiredOfficials =
                                    event['officialsHired'] as int? ?? 0;
                                final requiredOfficials = int.tryParse(
                                        event['officialsRequired']
                                                ?.toString() ??
                                            '0') ??
                                    0;
                                final isFullyHired =
                                    hiredOfficials >= requiredOfficials;

                                if (!isEventAway) allAway = false;
                                if (!isFullyHired) allFullyHired = false;
                                if (!isEventAway && !isFullyHired) {
                                  needsOfficials = true;
                                }
                              }

                              if (allAway) {
                                backgroundColor = Colors.grey[300];
                                textColor = Colors.white;
                              } else if (needsOfficials) {
                                backgroundColor = Colors.red;
                                textColor = Colors.white;
                              } else if (allFullyHired) {
                                backgroundColor = Colors.green;
                                textColor = Colors.white;
                              }
                            }

                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedDay = day;
                                  _selectedDayGames = _getGamesForDay(day);
                                });
                              },
                              child: Container(
                                margin: const EdgeInsets.all(4.0),
                                decoration: BoxDecoration(
                                  color: backgroundColor,
                                  borderRadius: BorderRadius.circular(4),
                                  border: isSelected && backgroundColor == null
                                      ? Border.all(
                                          color: efficialsYellow, width: 2)
                                      : isToday && backgroundColor == null
                                          ? Border.all(
                                              color: efficialsYellow, width: 2)
                                          : null,
                                ),
                                child: Center(
                                  child: Text(
                                    '${day.day}',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: textColor,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16.0, vertical: 8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 16,
                                  height: 16,
                                  decoration: BoxDecoration(
                                    color: Colors.grey[300],
                                    borderRadius: BorderRadius.circular(4.0),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Text('Away Game', style: TextStyle(color: Colors.white)),
                              ],
                            ),
                            const SizedBox(width: 16),
                            Row(
                              children: [
                                Container(
                                  width: 10,
                                  height: 10,
                                  decoration: const BoxDecoration(
                                    color: Colors.green,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Text('Fully Hired', style: TextStyle(color: Colors.white)),
                              ],
                            ),
                            const SizedBox(width: 16),
                            Row(
                              children: [
                                Container(
                                  width: 10,
                                  height: 10,
                                  decoration: const BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Text('Needs Officials', style: TextStyle(color: Colors.white)),
                              ],
                            ),
                          ],
                        ),
                      ),
                      // Add toggle checkbox below the legend
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16.0, vertical: 8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Checkbox(
                              value: _showOnlyNeedsOfficials,
                              onChanged: (value) {
                                setState(() {
                                  _showOnlyNeedsOfficials = value ?? false;
                                  // Update selected day games based on the new filter
                                  if (_selectedDay != null) {
                                    _selectedDayGames =
                                        _getGamesForDay(_selectedDay!);
                                  }
                                });
                              },
                              activeColor: efficialsYellow,
                              checkColor: efficialsBlack,
                            ),
                            const Text('Show only games needing officials', style: TextStyle(color: Colors.white)),
                          ],
                        ),
                      ),
                      // Scrollable game details section
                      if (_selectedDayGames.isNotEmpty)
                        Container(
                          constraints: const BoxConstraints(maxHeight: 300),
                          child: ListView.builder(
                            shrinkWrap: true,
                            itemCount: _selectedDayGames.length,
                            padding: const EdgeInsets.only(bottom: 20),
                            itemBuilder: (context, index) {
                              final game = _selectedDayGames[index];
                              final gameTime = game['time'] != null
                                  ? (game['time'] as TimeOfDay).format(context)
                                  : 'Not set';
                              final hiredOfficials =
                                  game['officialsHired'] as int? ?? 0;
                              final requiredOfficials = int.tryParse(
                                      game['officialsRequired']?.toString() ??
                                          '0') ??
                                  0;
                              final location =
                                  game['location'] as String? ?? 'Not set';
                              final opponent =
                                  game['opponent'] as String? ?? 'Not set';
                              final sport = game['sport'] as String? ?? 'Unknown';

                              return GestureDetector(
                                onTap: () async {
                                  final gameId = game['id'] as int;
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
                                        await _fetchGames();
                                      } else if (result != null &&
                                          (result as Map<String, dynamic>)['refresh'] == true) {
                                        await _fetchGames();
                                      }
                                    });
                                  }
                                },
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 4.0, horizontal: 16.0),
                                  child: Card(
                                    elevation: 2,
                                    color: darkSurface,
                                    child: Padding(
                                      padding: const EdgeInsets.all(12.0),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  '$sport vs $opponent',
                                                  style: const TextStyle(
                                                      fontSize: 18, 
                                                      fontWeight: FontWeight.bold,
                                                      color: efficialsYellow),
                                                ),
                                              ),
                                              if (game['isAway'] == true)
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                  decoration: BoxDecoration(
                                                    color: Colors.grey[600],
                                                    borderRadius: BorderRadius.circular(12),
                                                  ),
                                                  child: const Text(
                                                    'Away',
                                                    style: TextStyle(color: Colors.white, fontSize: 12),
                                                  ),
                                                ),
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            'Time: $gameTime',
                                            style: const TextStyle(
                                                fontSize: 16, color: Colors.white),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Location: $location',
                                            style: const TextStyle(
                                                fontSize: 16, color: Colors.white),
                                          ),
                                          const SizedBox(height: 4),
                                          if (hiredOfficials >= requiredOfficials)
                                            Container(
                                              padding: const EdgeInsets.symmetric(
                                                  horizontal: 8, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: Colors.green,
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              child: Text(
                                                '$hiredOfficials/$requiredOfficials officials confirmed',
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            )
                                          else
                                            Text(
                                              '$hiredOfficials/$requiredOfficials officials confirmed',
                                              style: const TextStyle(
                                                fontSize: 16,
                                                color: Colors.red,
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      if (_selectedDayGames.isEmpty && _selectedDay != null)
                        const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Text(
                            'No games scheduled for this day',
                            style: TextStyle(color: efficialsGray, fontSize: 16),
                            textAlign: TextAlign.center,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }
}