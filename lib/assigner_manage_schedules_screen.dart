import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:table_calendar/table_calendar.dart';
import 'theme.dart';
import 'game_template.dart';

class AssignerManageSchedulesScreen extends StatefulWidget {
  const AssignerManageSchedulesScreen({super.key});

  @override
  State<AssignerManageSchedulesScreen> createState() => _AssignerManageSchedulesScreenState();
}

class _AssignerManageSchedulesScreenState extends State<AssignerManageSchedulesScreen> {
  String? selectedTeam;
  List<String> teams = [];
  List<Map<String, dynamic>> games = [];
  bool isLoading = true;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  List<Map<String, dynamic>> _selectedDayGames = [];
  bool _showOnlyNeedsOfficials = false;
  String? associatedTemplateName;
  String? assignerSport;
  String? _teamToRestore; // Store team to restore separately
  DateTime? _dateToFocus; // Store date to focus calendar on

  @override
  void initState() {
    super.initState();
    _loadAssignerInfo();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null) {
      if (args['selectedTeam'] != null && _teamToRestore == null) {
        _teamToRestore = args['selectedTeam'] as String;
        print('AssignerManageSchedules - Captured team to restore: $_teamToRestore');
      }
      if (args['focusDate'] != null && _dateToFocus == null) {
        _dateToFocus = args['focusDate'] as DateTime;
        print('AssignerManageSchedules - Captured date to focus: $_dateToFocus');
      }
    }
  }

  Future<void> _restoreTeamSelection(String teamToSelect) async {
    // Wait for the teams to be loaded first
    await _fetchTeams();
    
    print('AssignerManageSchedules - Teams loaded: $teams');
    print('AssignerManageSchedules - Looking for team: $teamToSelect');
    
    if (teams.contains(teamToSelect)) {
      print('AssignerManageSchedules - Team found, restoring selection');
      setState(() {
        selectedTeam = teamToSelect;
      });
      await _fetchGames();
      await _loadAssociatedTemplate();
    } else {
      print('AssignerManageSchedules - Team not found in list: $teams');
    }
  }

  Future<void> _loadAssignerInfo() async {
    final prefs = await SharedPreferences.getInstance();
    assignerSport = prefs.getString('assigner_sport');
    await _fetchTeams();
    
    // Check if we need to restore team selection after loading teams
    if (_teamToRestore != null) {
      print('AssignerManageSchedules - Restoring team selection after load: $_teamToRestore');
      print('AssignerManageSchedules - Available teams: $teams');
      
      if (teams.contains(_teamToRestore)) {
        print('AssignerManageSchedules - Team found in _loadAssignerInfo, setting selection');
        selectedTeam = _teamToRestore;
        await _fetchGames();
        await _loadAssociatedTemplate();
        _teamToRestore = null; // Clear after restoration
      } else {
        print('AssignerManageSchedules - Team $_teamToRestore NOT found in teams list: $teams');
      }
    }
    
    setState(() {
      isLoading = false;
    });
  }

  Future<void> _fetchTeams() async {
    final prefs = await SharedPreferences.getInstance();
    final String? teamsJson = prefs.getString('assigner_teams');
    setState(() {
      teams.clear();
      if (teamsJson != null && teamsJson.isNotEmpty) {
        final List<dynamic> decoded = jsonDecode(teamsJson);
        teams = decoded.cast<String>();
      }
    });
  }

  Future<void> _addNewTeam() async {
    final TextEditingController teamController = TextEditingController();
    
    final String? newTeamName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Team'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: teamController,
              decoration: textFieldDecoration('Team Name (e.g. Alton Redbirds)'),
              textCapitalization: TextCapitalization.words,
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: efficialsBlue)),
          ),
          TextButton(
            onPressed: () {
              if (teamController.text.trim().isNotEmpty) {
                Navigator.pop(context, teamController.text.trim());
              }
            },
            child: const Text('Add', style: TextStyle(color: efficialsBlue)),
          ),
        ],
      ),
    );

    if (newTeamName != null) {
      final prefs = await SharedPreferences.getInstance();
      teams.add(newTeamName);
      await prefs.setString('assigner_teams', jsonEncode(teams));
      setState(() {
        selectedTeam = newTeamName;
      });
      await _fetchGames();
    }
  }

  Future<void> _fetchGames() async {
    print('AssignerManageSchedules - _fetchGames called for team: $selectedTeam');
    if (selectedTeam == null) {
      print('AssignerManageSchedules - selectedTeam is null, clearing games');
      setState(() {
        games.clear();
      });
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final String? unpublishedGamesJson = prefs.getString('unpublished_games');
    final String? publishedGamesJson = prefs.getString('published_games');
    List<Map<String, dynamic>> allGames = [];

    if (mounted) {
      setState(() {
        games.clear();
      });
    }
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

      // Filter games by selected team and sport
      print('AssignerManageSchedules - Filtering games for team: $selectedTeam, sport: $assignerSport');
      print('AssignerManageSchedules - Total games before filtering: ${allGames.length}');
      games = allGames.where((game) {
        final matchesTeam = game['opponent'] == selectedTeam || 
                           (game['scheduleName'] != null && game['scheduleName'].toString().contains(selectedTeam!));
        final matchesSport = game['sport'] == assignerSport;
        final hasDate = game['date'] != null;
        final shouldInclude = matchesTeam && matchesSport && hasDate;
        
        if (shouldInclude) {
          print('AssignerManageSchedules - Including game: ${game['opponent']} vs ${game['scheduleName']} (${game['sport']})');
        }
        
        return shouldInclude;
      }).toList();
      print('AssignerManageSchedules - Games found for $selectedTeam: ${games.length}');

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

      // Set focused day based on priority: dateToFocus > latest game > current date
      if (_dateToFocus != null) {
        _focusedDay = _dateToFocus!;
        print('AssignerManageSchedules - Using focus date: $_focusedDay');
        _dateToFocus = null; // Clear after use
      } else if (games.isNotEmpty) {
        games.sort((a, b) => (a['date'] as DateTime).compareTo(b['date'] as DateTime));
        _focusedDay = games.first['date'] as DateTime;
        print('AssignerManageSchedules - Using first game date: $_focusedDay');
      } else {
        _focusedDay = DateTime.now();
        print('AssignerManageSchedules - Using current date: $_focusedDay');
      }

    // Update UI only if widget is still mounted
    if (mounted) {
      setState(() {
        this.games = games; // Update the instance variable
      });
    }

    await _loadAssociatedTemplate();
  }

  Future<void> _loadAssociatedTemplate() async {
    if (selectedTeam == null) return;
    print('AssignerManageSchedules - Loading template for team: $selectedTeam');
    final prefs = await SharedPreferences.getInstance();
    final String templateKey = 'assigner_team_template_${selectedTeam!.toLowerCase().replaceAll(' ', '_')}';
    final String? templateJson = prefs.getString(templateKey);
    print('AssignerManageSchedules - Template key: $templateKey');
    print('AssignerManageSchedules - Template found: ${templateJson != null}');
    
    if (templateJson != null) {
      final templateData = jsonDecode(templateJson) as Map<String, dynamic>;
      if (mounted) {
        setState(() {
          associatedTemplateName = templateData['name'] as String?;
        });
      }
      print('AssignerManageSchedules - Template name set to: $associatedTemplateName');
    } else {
      if (mounted) {
        setState(() {
          associatedTemplateName = null;
        });
      }
      print('AssignerManageSchedules - No template found, clearing template name');
    }
  }

  Future<void> _removeAssociatedTemplate() async {
    if (selectedTeam == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('assigner_team_template_${selectedTeam!.toLowerCase().replaceAll(' ', '_')}');
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: efficialsBlue,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, size: 36, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Manage Schedules', style: appBarTextStyle),
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
                        // Team dropdown
                        DropdownButtonFormField<String>(
                          decoration: textFieldDecoration('Select Team'),
                          value: selectedTeam,
                          hint: teams.isEmpty 
                              ? const Text('No teams added yet')
                              : const Text('Select a team'),
                          onChanged: (newValue) async {
                            if (newValue == '+ Add a new team') {
                              await _addNewTeam();
                            } else {
                              print('AssignerManageSchedules - Team dropdown changed to: $newValue');
                              if (mounted) { // Check if widget is still mounted
                                setState(() {
                                  selectedTeam = newValue;
                                  // Reset selected day when switching teams
                                  _selectedDay = null;
                                  _selectedDayGames = [];
                                });
                                await _fetchGames();
                                await _loadAssociatedTemplate();
                                print('AssignerManageSchedules - Team switch completed, selected team: $selectedTeam');
                              }
                            }
                          },
                          items: [
                            ...teams.map((team) => DropdownMenuItem(
                              value: team,
                              child: Text(team),
                            )),
                            const DropdownMenuItem(
                              value: '+ Add a new team',
                              child: Text('+ Add a new team'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // Display the associated template (if any)
                        if (selectedTeam != null && associatedTemplateName != null) ...[
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
                        if (selectedTeam != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            '$selectedTeam Schedule',
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (selectedTeam != null) ...[
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
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
      floatingActionButton: selectedTeam != null ? Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: 'setTemplate',
            onPressed: () {
              Navigator.pushNamed(
                context,
                '/select_game_template',
                arguments: {
                  'scheduleName': selectedTeam,
                  'sport': assignerSport,
                  'isAssignerFlow': true,
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
                    final String? templateJson = prefs.getString('assigner_team_template_${selectedTeam!.toLowerCase().replaceAll(' ', '_')}');
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
                        'scheduleName': selectedTeam,
                        'date': _selectedDay,
                        'fromScheduleDetails': true,
                        'template': template,
                        'isAssignerFlow': true,
                        'opponent': selectedTeam,
                        'sport': assignerSport,
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
      ) : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}