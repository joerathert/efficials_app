import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:table_calendar/table_calendar.dart';
import 'theme.dart';
import 'game_template.dart'; // Import the GameTemplate model

class ScheduleDetailsScreen extends StatefulWidget {
  const ScheduleDetailsScreen({super.key});

  @override
  State<ScheduleDetailsScreen> createState() => _ScheduleDetailsScreenState();
}

class _ScheduleDetailsScreenState extends State<ScheduleDetailsScreen> {
  String? scheduleName;
  int? scheduleId;
  List<Map<String, dynamic>> games = [];
  bool isLoading = true;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  List<Map<String, dynamic>> _selectedDayGames = [];
  bool _showOnlyNeedsOfficials = false; // Toggle state for filtering
  String? associatedTemplateName; // Store the associated template name

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    scheduleName = args['scheduleName'] as String?;
    scheduleId = args['scheduleId'] as int?;
    _fetchGames();
    _loadAssociatedTemplate(); // Load the associated template
  }

  Future<void> _fetchGames() async {
    final prefs = await SharedPreferences.getInstance();
    final String? unpublishedGamesJson = prefs.getString('unpublished_games');
    final String? publishedGamesJson = prefs.getString('published_games');
    List<Map<String, dynamic>> allGames = [];

    setState(() {
      games.clear();
      try {
        if (unpublishedGamesJson != null && unpublishedGamesJson.isNotEmpty) {
          final unpublished = List<Map<String, dynamic>>.from(jsonDecode(unpublishedGamesJson));
          allGames.addAll(unpublished);
        }
        if (publishedGamesJson != null && publishedGamesJson.isNotEmpty) {
          final published = List<Map<String, dynamic>>.from(jsonDecode(publishedGamesJson));
          allGames.addAll(published);
        }
      } catch (e) {
        print('Error fetching games: $e');
      }

      games = allGames.where((game) {
        final matchesSchedule = game['scheduleName'] == scheduleName;
        final hasDate = game['date'] != null;
        return matchesSchedule && hasDate;
      }).toList();

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
        games.sort((a, b) => (a['date'] as DateTime).compareTo(b['date'] as DateTime));
        _focusedDay = games.first['date'] as DateTime;
      } else {
        _focusedDay = DateTime.now();
      }

      isLoading = false;
    });
  }

  Future<void> _loadAssociatedTemplate() async {
    if (scheduleName == null) return;
    final prefs = await SharedPreferences.getInstance();
    final String? templateJson = prefs.getString('schedule_template_${scheduleName!.toLowerCase()}');
    if (templateJson != null) {
      final templateData = jsonDecode(templateJson) as Map<String, dynamic>;
      setState(() {
        associatedTemplateName = templateData['name'] as String?;
      });
    }
  }

  Future<void> _removeAssociatedTemplate() async {
    if (scheduleName == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('schedule_template_${scheduleName!.toLowerCase()}');
    setState(() {
      associatedTemplateName = null;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Template association removed')),
    );
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
        final requiredOfficials = int.tryParse(game['officialsRequired']?.toString() ?? '0') ?? 0;
        return matchesDay && hiredOfficials < requiredOfficials;
      }
      return matchesDay;
    }).toList();
  }

  Future<void> _createTemplateFromGame(Map<String, dynamic> game) async {
    // Navigate to the create game template screen with the game data pre-filled
    final result = await Navigator.pushNamed(
      context,
      '/create_game_template',
      arguments: {
        'scheduleName': scheduleName,
        'sport': game['sport'] as String? ?? 'Unknown',
        'time': game['time'], // TimeOfDay object
        'location': game['location'] as String?,
        'locationData': game['locationData'], // Location details if available
        'levelOfCompetition': game['levelOfCompetition'] as String?,
        'gender': game['gender'] as String?,
        'officialsRequired': game['officialsRequired'] is String 
            ? int.tryParse(game['officialsRequired'] as String) 
            : game['officialsRequired'] as int?,
        'gameFee': game['gameFee']?.toString(),
        'hireAutomatically': game['hireAutomatically'] as bool? ?? false,
        'selectedListName': game['selectedListName'] as String?,
        'isAway': game['isAway'] as bool? ?? false,
      },
    );

    if (result != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Game template created successfully!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: efficialsBlue,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, size: 36, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Schedule Details', style: appBarTextStyle),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Text(
                          scheduleName ?? 'Unnamed Schedule',
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        // Display the associated template (if any)
                        if (associatedTemplateName != null) ...[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Chip(
                                label: Text('Template: $associatedTemplateName'),
                                backgroundColor: Colors.grey[200],
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                icon: const Icon(Icons.clear, color: Colors.red, size: 20),
                                onPressed: _removeAssociatedTemplate,
                              ),
                            ],
                          ),
                        ],
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
                            color: efficialsBlue.withOpacity(0.5),
                            shape: BoxShape.rectangle,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          selectedDecoration: BoxDecoration(
                            color: efficialsBlue,
                            shape: BoxShape.rectangle,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          defaultTextStyle: const TextStyle(fontSize: 16, color: Colors.black),
                          weekendTextStyle: const TextStyle(fontSize: 16, color: Colors.black),
                          outsideTextStyle: const TextStyle(fontSize: 16, color: Colors.grey),
                          markersMaxCount: 0,
                        ),
                        daysOfWeekStyle: DaysOfWeekStyle(
                          weekdayStyle: const TextStyle(fontSize: 14),
                          weekendStyle: const TextStyle(fontSize: 14),
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
                          titleTextStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          leftChevronIcon: Icon(Icons.chevron_left, color: efficialsBlue),
                          rightChevronIcon: Icon(Icons.chevron_right, color: efficialsBlue),
                          titleCentered: true,
                        ),
                        calendarBuilders: CalendarBuilders(
                          defaultBuilder: (context, day, focusedDay) {
                            final events = _getGamesForDay(day);
                            final hasEvents = events.isNotEmpty;
                            final isToday = isSameDay(day, DateTime.now());
                            final isOutsideMonth = day.month != focusedDay.month;
                            final isSelected = _selectedDay != null &&
                                day.year == _selectedDay!.year &&
                                day.month == _selectedDay!.month &&
                                day.day == _selectedDay!.day;

                            Color? backgroundColor;
                            Color textColor = isOutsideMonth ? Colors.grey : Colors.black;

                            if (hasEvents) {
                              bool allAway = true;
                              bool allFullyHired = true;
                              bool needsOfficials = false;

                              for (var event in events) {
                                final isEventAway = event['isAway'] as bool? ?? false;
                                final hiredOfficials = event['officialsHired'] as int? ?? 0;
                                final requiredOfficials = int.tryParse(
                                        event['officialsRequired']?.toString() ?? '0') ?? 0;
                                final isFullyHired = hiredOfficials >= requiredOfficials;

                                if (!isEventAway) allAway = false;
                                if (!isFullyHired) allFullyHired = false;
                                if (!isEventAway && !isFullyHired) needsOfficials = true;
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
                                      ? Border.all(color: efficialsBlue, width: 2)
                                      : isToday && backgroundColor == null
                                          ? Border.all(color: efficialsBlue, width: 2)
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
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
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
                                const Text('Away Game'),
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
                                const Text('Fully Hired'),
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
                                const Text('Needs Officials'),
                              ],
                            ),
                          ],
                        ),
                      ),
                      // Add toggle checkbox below the legend
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
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
                                    _selectedDayGames = _getGamesForDay(_selectedDay!);
                                  }
                                });
                              },
                              activeColor: efficialsBlue,
                            ),
                            const Text('Show only games needing officials'),
                          ],
                        ),
                      ),
                      // Scrollable game details section
                      if (_selectedDayGames.isNotEmpty)
                        Container(
                          constraints: const BoxConstraints(maxHeight: 200),
                          child: ListView.builder(
                            shrinkWrap: true,
                            itemCount: _selectedDayGames.length,
                            itemBuilder: (context, index) {
                              final game = _selectedDayGames[index];
                              final gameTime = game['time'] != null
                                  ? (game['time'] as TimeOfDay).format(context)
                                  : 'Not set';
                              final hiredOfficials = game['officialsHired'] as int? ?? 0;
                              final requiredOfficials = int.tryParse(
                                      game['officialsRequired']?.toString() ?? '0') ?? 0;
                              final location = game['location'] as String? ?? 'Not set';
                              final opponent = game['opponent'] as String? ?? 'Not set';

                              return GestureDetector(
                                onTap: () {
                                  Navigator.pushNamed(
                                    context,
                                    '/game_information',
                                    arguments: game,
                                  ).then((result) {
                                    if (result == true || (result is Map<String, dynamic> && result.isNotEmpty)) {
                                      _fetchGames();
                                    }
                                  });
                                },
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 16.0),
                                  child: Card(
                                    elevation: 2,
                                    child: Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'Time: $gameTime',
                                                  style: const TextStyle(fontSize: 16),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  '$hiredOfficials/$requiredOfficials officials confirmed',
                                                  style: TextStyle(
                                                    fontSize: 16,
                                                    color: hiredOfficials >= requiredOfficials
                                                        ? Colors.green
                                                        : Colors.red,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  'Location: $location',
                                                  style: const TextStyle(fontSize: 16),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  'Opponent: $opponent',
                                                  style: const TextStyle(fontSize: 16),
                                                ),
                                              ],
                                            ),
                                          ),
                                          IconButton(
                                            onPressed: () => _createTemplateFromGame(game),
                                            icon: const Icon(Icons.link, color: efficialsBlue),
                                            tooltip: 'Create Template from Game',
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
                    ],
                  ),
                ],
              ),
            ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
  heroTag: 'setTemplate',
  onPressed: () {
    // Determine the sport from the first game, if available
    final sport = games.isNotEmpty ? games.first['sport'] as String? ?? 'Unknown' : 'Unknown';
    Navigator.pushNamed(
      context,
      '/select_game_template',
      arguments: {
        'scheduleName': scheduleName,
        'sport': sport,
      },
    ).then((_) {
      _loadAssociatedTemplate();
    });
  },
  backgroundColor: efficialsBlue,
  tooltip: 'Set Template',
  child: const Icon(Icons.link, color: Colors.white),
),
          const SizedBox(height: 10),
          FloatingActionButton(
            heroTag: 'addGame',
            onPressed: _selectedDay == null
                ? null
                : () async {
                    // Check for an associated template
                    final prefs = await SharedPreferences.getInstance();
                    final String? templateJson = prefs.getString('schedule_template_${scheduleName!.toLowerCase()}');
                    GameTemplate? template;
                    if (templateJson != null) {
                      final templateData = jsonDecode(templateJson) as Map<String, dynamic>;
                      template = GameTemplate.fromJson(templateData);
                    }

                    // Navigate to the game creation flow with the template (if any)
                    Navigator.pushNamed(
                      context,
                      '/date_time',
                      arguments: {
                        'scheduleName': scheduleName,
                        'scheduleId': scheduleId,
                        'date': _selectedDay,
                        'fromScheduleDetails': true,
                        'template': template, // Pass the associated template
                      },
                    ).then((_) {
                      _fetchGames();
                    });
                  },
            backgroundColor: _selectedDay == null ? Colors.grey : efficialsBlue,
            tooltip: 'Add Game',
            child: const Icon(Icons.add, size: 30, color: Colors.white),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}