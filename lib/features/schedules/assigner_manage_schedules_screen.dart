import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../shared/theme.dart';
import '../../shared/models/database_models.dart';
import '../../shared/services/repositories/schedule_repository.dart';
import '../../shared/services/repositories/template_repository.dart';
import '../../shared/services/repositories/user_repository.dart';
import '../../shared/services/game_service.dart';
import '../../shared/services/user_session_service.dart';
import '../../shared/utils/utils.dart';
import '../games/game_template.dart' as ui;

class AssignerManageSchedulesScreen extends StatefulWidget {
  const AssignerManageSchedulesScreen({super.key});

  @override
  State<AssignerManageSchedulesScreen> createState() =>
      _AssignerManageSchedulesScreenState();
}

class _AssignerManageSchedulesScreenState
    extends State<AssignerManageSchedulesScreen> {
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

  // Services
  final ScheduleRepository _scheduleRepository = ScheduleRepository();
  final TemplateRepository _templateRepository = TemplateRepository();
  final GameService _gameService = GameService();
  final UserSessionService _userSessionService = UserSessionService.instance;
  final UserRepository _userRepository = UserRepository();

  @override
  void initState() {
    super.initState();
    _loadAssignerInfo();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null) {
      if (args['selectedTeam'] != null && _teamToRestore == null) {
        _teamToRestore = args['selectedTeam'] as String;
      }
      if (args['focusDate'] != null && _dateToFocus == null) {
        _dateToFocus = args['focusDate'] as DateTime;
      }
    }
  }

  Future<void> _restoreTeamSelection(String teamToSelect) async {
    // Wait for the teams to be loaded first
    await _fetchTeams();
    if (teams.contains(teamToSelect)) {
      setState(() {
        selectedTeam = teamToSelect;
      });
      await _fetchGames();
      await _loadAssociatedTemplate();
    }
  }

  Future<void> _loadAssignerInfo() async {
    try {
      // Get current user info and sport from database
      final currentUser = await _userRepository.getCurrentUser();
      if (currentUser != null) {
        assignerSport = currentUser.sport;
      }

      await _fetchTeams();

      // Check if we need to restore team selection after loading teams
      if (_teamToRestore != null) {
        if (teams.contains(_teamToRestore)) {
          setState(() {
            selectedTeam = _teamToRestore;
          });
          await _fetchGames();
          await _loadAssociatedTemplate();
          _teamToRestore = null; // Clear after restoration
        }
      }

      setState(() {
        isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading assigner info: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _fetchTeams() async {
    try {
      final userId = await _userSessionService.getCurrentUserId();
      if (userId != null) {
        final schedules = await _scheduleRepository.getSchedulesByUser(userId);
        setState(() {
          teams = schedules.map((schedule) => schedule.name).toList();
        });
      } else {
        setState(() {
          teams = [];
        });
      }
    } catch (e) {
      debugPrint('Error fetching schedules: $e');
      setState(() {
        teams = [];
      });
    }
  }

  Future<void> _addNewTeam() async {
    final result = await Navigator.pushNamed(
      context,
      '/name_schedule',
      arguments: {
        'sport': assignerSport,
      },
    );

    if (result != null) {
      await _fetchTeams();
      if (mounted) {
        setState(() {
          // Handle both schedule object (from database) and string (from SharedPreferences)
          if (result is Map<String, dynamic>) {
            selectedTeam = result['name'] as String;
          } else {
            selectedTeam = result as String;
          }
        });
        await _fetchGames();
      }
    }
  }

  Future<void> _fetchGames() async {
    if (selectedTeam == null) {
      setState(() {
        games.clear();
      });
      return;
    }

    try {
      // Get games from GameService using the team name
      final teamGames = await _gameService.getGamesByTeam(selectedTeam!);

      // Filter by sport if needed
      games = teamGames.where((game) {
        final matchesSport =
            assignerSport == null || game['sport'] == assignerSport;
        final hasDate = game['date'] != null;
        return matchesSport && hasDate;
      }).toList();

      // Set focused day based on priority: dateToFocus > latest game > current date
      if (_dateToFocus != null) {
        _focusedDay = _dateToFocus!;
        _dateToFocus = null; // Clear after use
      } else if (games.isNotEmpty) {
        games.sort(
            (a, b) => (a['date'] as DateTime).compareTo(b['date'] as DateTime));
        _focusedDay = games.first['date'] as DateTime;
      } else {
        _focusedDay = DateTime.now();
      }

      // Update UI only if widget is still mounted
      if (mounted) {
        setState(() {});
      }

      await _loadAssociatedTemplate();
    } catch (e) {
      debugPrint('Error fetching games: $e');
      if (mounted) {
        setState(() {
          games = [];
        });
      }
    }
  }

  Future<void> _loadAssociatedTemplate() async {
    if (selectedTeam == null) return;

    try {
      final userId = await _userSessionService.getCurrentUserId();
      if (userId != null) {
        final templateName =
            await _templateRepository.getByTeam(userId, selectedTeam!);
        if (mounted) {
          setState(() {
            associatedTemplateName = templateName;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            associatedTemplateName = null;
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading associated template: $e');
      if (mounted) {
        setState(() {
          associatedTemplateName = null;
        });
      }
    }
  }

  Future<void> _removeAssociatedTemplate() async {
    if (selectedTeam == null) return;

    try {
      final userId = await _userSessionService.getCurrentUserId();
      if (userId != null) {
        await _templateRepository.removeAssociation(userId, selectedTeam!);
        setState(() {
          associatedTemplateName = null;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Template association removed')),
          );
        }
      }
    } catch (e) {
      debugPrint('Error removing template association: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error removing template: $e')),
        );
      }
    }
  }

  Future<void> _showTemplateDetails() async {
    if (associatedTemplateName == null) return;

    try {
      final userId = await _userSessionService.getCurrentUserId();
      if (userId != null) {
        final templateData = await _templateRepository.getTemplateData(userId, selectedTeam!);
        if (templateData != null) {
          final template = ui.GameTemplate.fromJson(templateData);
          if (mounted) {
            showDialog(
              context: context,
              builder: (context) => _buildTemplateDetailsDialog(template),
            );
          }
        }
      }
    } catch (e) {
      debugPrint('Error loading template details: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error loading template details')),
        );
      }
    }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: darkBackground,
      appBar: AppBar(
        backgroundColor: efficialsBlack,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, size: 36, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Manage Schedules', style: appBarTextStyle),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : teams.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Transform.translate(
                          offset: const Offset(0, -80),
                          child: Column(
                            children: [
                              Icon(
                                getSportIcon(assignerSport ?? ''),
                                size: 80,
                                color: getSportIconColor(assignerSport ?? '')
                                    .withOpacity(0.6),
                              ),
                              const SizedBox(height: 24),
                              const Text(
                                'Welcome to Schedule Management!',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: efficialsBlue,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'Get started by adding your first team to manage their game schedules.',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: secondaryTextColor,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 32),
                              ElevatedButton.icon(
                                onPressed: _addNewTeam,
                                icon: const Icon(Icons.add_circle_outline,
                                    size: 24),
                                label: const Text(
                                  'Add Your First Team',
                                  style: TextStyle(fontSize: 18),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: efficialsBlack,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 16,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : SingleChildScrollView(
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16.0),
                        decoration: BoxDecoration(
                          color: darkSurface,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.1),
                              spreadRadius: 1,
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Team dropdown with improved styling
                            DropdownButtonFormField<String>(
                              decoration: InputDecoration(
                                labelText: 'Select Team',
                                labelStyle:
                                    const TextStyle(color: efficialsBlue),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide:
                                      const BorderSide(color: efficialsBlue),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(
                                      color: efficialsBlue.withOpacity(0.5)),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(
                                      color: efficialsBlue, width: 2),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 16),
                              ),
                              value: selectedTeam,
                              hint: const Text('Select a team',
                                  style: TextStyle(color: efficialsGray)),
                              dropdownColor: darkSurface,
                              style: const TextStyle(color: primaryTextColor),
                              onChanged: (newValue) async {
                                if (newValue == '+ Add new') {
                                  await _addNewTeam();
                                } else {
                                  if (mounted) {
                                    setState(() {
                                      selectedTeam = newValue;
                                      _selectedDay = null;
                                      _selectedDayGames = [];
                                    });
                                    await _fetchGames();
                                    await _loadAssociatedTemplate();
                                  }
                                }
                              },
                              items: [
                                ...teams.map((team) => DropdownMenuItem(
                                      value: team,
                                      child: Text(team,
                                          style: const TextStyle(
                                              color: primaryTextColor)),
                                    )),
                                const DropdownMenuItem(
                                  value: '+ Add new',
                                  child: Row(
                                    children: [
                                      Icon(Icons.add_circle_outline,
                                          color: efficialsBlue, size: 20),
                                      SizedBox(width: 8),
                                      Text('+ Add new',
                                          style: TextStyle(
                                              color: primaryTextColor)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            // Display the associated template (if any)
                            if (selectedTeam != null) ...[
                              if (associatedTemplateName != null)
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.description,
                                        size: 16, color: efficialsBlue),
                                    const SizedBox(width: 4),
                                    GestureDetector(
                                      onTap: () async {
                                        await _showTemplateDetails();
                                      },
                                      child: Text(
                                        'Template: $associatedTemplateName',
                                        style: const TextStyle(
                                          color: efficialsBlue,
                                          fontSize: 14,
                                          decoration: TextDecoration.underline,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    IconButton(
                                      icon: const Icon(Icons.clear,
                                          color: Colors.red, size: 16),
                                      onPressed: _removeAssociatedTemplate,
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                    ),
                                  ],
                                ),
                              const SizedBox(height: 8),
                              _buildAdaptiveScheduleTitle(selectedTeam!),
                            ],
                          ],
                        ),
                      ),
                      if (selectedTeam != null) ...[
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              margin: const EdgeInsets.symmetric(vertical: 16),
                              decoration: BoxDecoration(
                                color: darkSurface,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.withOpacity(0.1),
                                    spreadRadius: 1,
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Column(
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
                                        _selectedDayGames =
                                            _getGamesForDay(selectedDay);
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
                                      selectedTextStyle: const TextStyle(
                                        fontSize: 16,
                                        color: efficialsBlack,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      defaultTextStyle: const TextStyle(
                                          fontSize: 16,
                                          color: primaryTextColor),
                                      weekendTextStyle: const TextStyle(
                                          fontSize: 16,
                                          color: primaryTextColor),
                                      outsideTextStyle: TextStyle(
                                          fontSize: 16,
                                          color: Colors.grey[400]),
                                      markersMaxCount: 0,
                                    ),
                                    daysOfWeekStyle: const DaysOfWeekStyle(
                                      weekdayStyle: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: primaryTextColor),
                                      weekendStyle: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: primaryTextColor),
                                    ),
                                    headerStyle: const HeaderStyle(
                                      formatButtonVisible: false,
                                      titleTextStyle: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: efficialsBlue),
                                      leftChevronIcon: Icon(Icons.chevron_left,
                                          color: efficialsBlue, size: 28),
                                      rightChevronIcon: Icon(
                                          Icons.chevron_right,
                                          color: efficialsBlue,
                                          size: 28),
                                      titleCentered: true,
                                    ),
                                    calendarBuilders: CalendarBuilders(
                                      defaultBuilder:
                                          (context, day, focusedDay) {
                                        final events = _getGamesForDay(day);
                                        final hasEvents = events.isNotEmpty;
                                        final isToday =
                                            isSameDay(day, DateTime.now());
                                        final isOutsideMonth =
                                            day.month != focusedDay.month;
                                        final isSelected = _selectedDay !=
                                                null &&
                                            day.year == _selectedDay!.year &&
                                            day.month == _selectedDay!.month &&
                                            day.day == _selectedDay!.day;

                                        Color? backgroundColor;
                                        Color textColor = isOutsideMonth
                                            ? Colors.grey[400]!
                                            : primaryTextColor;

                                        if (hasEvents) {
                                          bool allAway = true;
                                          bool allFullyHired = true;
                                          bool needsOfficials = false;

                                          for (var event in events) {
                                            final isEventAway =
                                                event['isAway'] as bool? ??
                                                    false;
                                            final hiredOfficials =
                                                event['officialsHired']
                                                        as int? ??
                                                    0;
                                            final requiredOfficials =
                                                int.tryParse(
                                                        event['officialsRequired']
                                                                ?.toString() ??
                                                            '0') ??
                                                    0;
                                            final isFullyHired =
                                                hiredOfficials >=
                                                    requiredOfficials;

                                            if (!isEventAway) allAway = false;
                                            if (!isFullyHired) {
                                              allFullyHired = false;
                                            }
                                            if (!isEventAway && !isFullyHired) {
                                              needsOfficials = true;
                                            }
                                          }

                                          if (allAway) {
                                            backgroundColor = Colors.grey[300];
                                            textColor = Colors.white;
                                          } else if (needsOfficials) {
                                            backgroundColor = Colors.red[400];
                                            textColor = Colors.white;
                                          } else if (allFullyHired) {
                                            backgroundColor = Colors.green[400];
                                            textColor = Colors.white;
                                          }
                                        }

                                        // Override text color for selected dates to ensure readability
                                        if (isSelected) {
                                          textColor = efficialsBlack;
                                        }

                                        return Container(
                                          margin: const EdgeInsets.all(4.0),
                                          decoration: BoxDecoration(
                                            color: backgroundColor,
                                            borderRadius:
                                                BorderRadius.circular(4),
                                            border: isSelected
                                                ? Border.all(
                                                    color: efficialsBlue,
                                                    width: 2)
                                                : isToday &&
                                                        backgroundColor == null
                                                    ? Border.all(
                                                        color: efficialsBlue
                                                            .withOpacity(0.5),
                                                        width: 1)
                                                    : null,
                                            boxShadow: hasEvents
                                                ? [
                                                    BoxShadow(
                                                      color: Colors.black
                                                          .withOpacity(0.1),
                                                      spreadRadius: 1,
                                                      blurRadius: 1,
                                                      offset:
                                                          const Offset(0, 1),
                                                    ),
                                                  ]
                                                : null,
                                          ),
                                          child: Center(
                                            child: Text(
                                              '${day.day}',
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: hasEvents
                                                    ? FontWeight.w600
                                                    : FontWeight.normal,
                                                color: textColor,
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                  // Calendar legend with improved styling
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16.0, vertical: 8.0),
                                    decoration: BoxDecoration(
                                      color: darkSurface,
                                      border: Border(
                                        top: BorderSide(
                                          color: efficialsGray.withOpacity(0.3),
                                        ),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceEvenly,
                                      children: [
                                        _buildLegendItem(
                                          color: Colors.green[400]!,
                                          label: 'Fully Hired',
                                          icon: Icons.check_circle,
                                        ),
                                        _buildLegendItem(
                                          color: Colors.red[400]!,
                                          label: 'Needs Officials',
                                          icon: Icons.warning,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Selected day games list with improved styling
                            if (_selectedDayGames.isNotEmpty)
                              Container(
                                margin:
                                    const EdgeInsets.fromLTRB(16, 0, 16, 16),
                                decoration: BoxDecoration(
                                  color: darkSurface,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.grey.withOpacity(0.1),
                                      spreadRadius: 1,
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                constraints: BoxConstraints(
                                  maxHeight:
                                      MediaQuery.of(context).size.height * 0.3,
                                  minHeight: 100,
                                ),
                                child: ListView.separated(
                                  padding: const EdgeInsets.all(16),
                                  shrinkWrap: true,
                                  itemCount: _selectedDayGames.length,
                                  separatorBuilder: (context, index) =>
                                      const Divider(height: 16),
                                  itemBuilder: (context, index) {
                                    final game = _selectedDayGames[index];
                                    final gameTime = game['time'] != null
                                        ? (game['time'] as TimeOfDay)
                                            .format(context)
                                        : 'Not set';
                                    final hiredOfficials =
                                        game['officialsHired'] as int? ?? 0;
                                    final requiredOfficials = int.tryParse(
                                            game['officialsRequired']
                                                    ?.toString() ??
                                                '0') ??
                                        0;
                                    final location =
                                        game['location'] as String? ??
                                            'Not set';
                                    final opponent =
                                        game['opponent'] as String? ??
                                            'Not set';
                                    final isAway =
                                        game['isAway'] as bool? ?? false;

                                    return InkWell(
                                      onTap: () {
                                        Navigator.pushNamed(
                                          context,
                                          '/game_information',
                                          arguments: game,
                                        ).then((result) {
                                          if (result == true ||
                                              (result is Map<String, dynamic> &&
                                                  result.isNotEmpty)) {
                                            _fetchGames();
                                          }
                                        });
                                      },
                                      borderRadius: BorderRadius.circular(8),
                                      child: Container(
                                        padding: const EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                          color: darkSurface,
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          border: Border.all(
                                            color: hiredOfficials >=
                                                    requiredOfficials
                                                ? Colors.green[400]!
                                                : Colors.red[400]!,
                                            width: 1,
                                          ),
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Row(
                                                  children: [
                                                    const Icon(
                                                      Icons.access_time,
                                                      size: 18,
                                                      color: secondaryTextColor,
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Text(
                                                      gameTime,
                                                      style: const TextStyle(
                                                        fontSize: 16,
                                                        fontWeight:
                                                            FontWeight.w500,
                                                        color: primaryTextColor,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                Container(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                    horizontal: 8,
                                                    vertical: 4,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: hiredOfficials >=
                                                            requiredOfficials
                                                        ? Colors.green
                                                        : Colors.red[400],
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            12),
                                                  ),
                                                  child: Text(
                                                    '$hiredOfficials/$requiredOfficials officials',
                                                    style: TextStyle(
                                                      color: hiredOfficials >=
                                                              requiredOfficials
                                                          ? Colors.white
                                                          : darkSurface,
                                                      fontSize: 14,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 12),
                                            Row(
                                              children: [
                                                Icon(
                                                  isAway
                                                      ? Icons.directions_bus
                                                      : Icons.location_on,
                                                  size: 18,
                                                  color: secondaryTextColor,
                                                ),
                                                const SizedBox(width: 8),
                                                Expanded(
                                                  child: Text(
                                                    location,
                                                    style: const TextStyle(
                                                        fontSize: 16,
                                                        color:
                                                            primaryTextColor),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 8),
                                            Row(
                                              children: [
                                                const Icon(
                                                  Icons.people,
                                                  size: 18,
                                                  color: secondaryTextColor,
                                                ),
                                                const SizedBox(width: 8),
                                                Expanded(
                                                  child: Text(
                                                    'vs $opponent',
                                                    style: const TextStyle(
                                                        fontSize: 16,
                                                        color:
                                                            primaryTextColor),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            if (_selectedDay != null &&
                                _selectedDayGames.isEmpty)
                              Container(
                                margin: const EdgeInsets.all(16),
                                padding: const EdgeInsets.symmetric(
                                    vertical: 12, horizontal: 24),
                                decoration: BoxDecoration(
                                  color: darkSurface,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                      color: efficialsGray.withOpacity(0.3)),
                                ),
                                child: Text(
                                  'No games scheduled for ${_selectedDay!.month}/${_selectedDay!.day}/${_selectedDay!.year}',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: secondaryTextColor,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
      floatingActionButton: selectedTeam != null
          ? Column(
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
                  backgroundColor: efficialsYellow,
                  tooltip: 'Set Template',
                  child: const Icon(Icons.link, color: efficialsBlack),
                ),
                const SizedBox(height: 10),
                FloatingActionButton(
                  heroTag: 'addGame',
                  onPressed: _selectedDay == null
                      ? null
                      : () async {
                          // Load template from database if one is associated with this team
                          ui.GameTemplate? template;

                          if (associatedTemplateName != null) {
                            try {
                              final userId =
                                  await _userSessionService.getCurrentUserId();
                              if (userId != null) {
                                final templateData = await _templateRepository
                                    .getTemplateData(userId, selectedTeam!);
                                if (templateData != null) {
                                  template =
                                      ui.GameTemplate.fromJson(templateData);
                                }
                              }
                            } catch (e) {
                              debugPrint('Error loading template: $e');
                            }
                          }

                          if (mounted) {
                            // Determine the navigation flow based on template settings
                            String nextRoute;
                            Map<String, dynamic> routeArgs = {
                              'scheduleName': selectedTeam,
                              'date': _selectedDay,
                              'fromScheduleDetails': true,
                              'template': template,
                              'isAssignerFlow': true,
                              'opponent': selectedTeam,
                              'sport': assignerSport,
                            };

                            // Add template time to args if it exists, regardless of route
                            if (template != null &&
                                template.includeTime &&
                                template.time != null) {
                              routeArgs['time'] = template.time;
                            }


                            // Check if template has location set - if not, go to location screen first
                            if (template == null ||
                                !template.includeLocation ||
                                template.location == null ||
                                template.location!.isEmpty) {
                              nextRoute = '/choose_location';
                            }
                            // Check if template uses crew method - skip directly to review (only if location is set)
                            else if (template != null &&
                                template.method == 'hire_crew' &&
                                template.selectedCrews != null &&
                                template.selectedCrews!.isNotEmpty) {
                              nextRoute = '/review_game_info';
                              routeArgs.addAll({
                                'method': 'hire_crew',
                                'selectedCrews': template.selectedCrews,
                                'selectedCrew': template.selectedCrews!.first,
                              });
                            }
                            // Check if template has time set and we can skip date_time screen
                            else if (template.includeTime &&
                                template.time != null) {
                              // Skip date_time screen and go directly to additional_game_info
                              nextRoute = '/additional_game_info';
                            } else {
                              // Normal flow through date_time screen
                              nextRoute = '/date_time';
                            }

                            // ignore: use_build_context_synchronously
                            Navigator.pushNamed(
                              context,
                              nextRoute,
                              arguments: routeArgs,
                            ).then((_) {
                              _fetchGames();
                            });
                          }
                        },
                  backgroundColor:
                      _selectedDay == null ? Colors.grey : efficialsYellow,
                  tooltip: 'Add Game',
                  child: const Icon(Icons.add, size: 30, color: efficialsBlack),
                ),
              ],
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget _buildLegendItem({
    required Color color,
    required String label,
    required IconData icon,
  }) {
    return Row(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: primaryTextColor,
          ),
        ),
      ],
    );
  }

  Widget _buildAdaptiveScheduleTitle(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Account for container padding
          final availableWidth =
              constraints.maxWidth - 32; // 16px padding on each side

          // Start with maximum font size and work down
          double fontSize = 28; // Start with a reasonable max size
          const double minFontSize = 14; // Minimum readable size
          const double stepSize = 0.5; // Smaller steps for more precision

          // Find the largest font size that fits
          while (fontSize >= minFontSize) {
            final textPainter = TextPainter(
              text: TextSpan(
                text: text,
                style: TextStyle(
                  fontSize: fontSize,
                  fontWeight: FontWeight.bold,
                  color: efficialsBlue,
                ),
              ),
              maxLines: 1,
              textDirection: TextDirection.ltr,
            );

            textPainter.layout(maxWidth: double.infinity);

            // If text width fits within available width, use this font size
            if (textPainter.width <= availableWidth) {
              break;
            }

            // Reduce font size and try again
            fontSize -= stepSize;
          }

          // Ensure we don't go below minimum
          fontSize = fontSize.clamp(minFontSize, 28.0);

          return Text(
            text,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
              color: efficialsBlue,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow
                .clip, // Changed from ellipsis to clip since we're sizing to fit
          );
        },
      ),
    );
  }

  Widget _buildTemplateDetailsDialog(ui.GameTemplate template) {
    return AlertDialog(
      backgroundColor: darkSurface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: efficialsYellow.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.description,
              color: efficialsYellow,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Template Details',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: efficialsYellow,
              ),
            ),
          ),
        ],
      ),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 400),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                template.name,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: primaryTextColor,
                ),
              ),
              const SizedBox(height: 16),
              if (template.includeSport && template.sport != null)
                _buildDetailRow('Sport', template.sport!),
              if (template.includeTime && template.time != null)
                _buildDetailRow('Time', template.time!.format(context)),
              if (template.includeLocation && template.location != null)
                _buildDetailRow('Location', template.location!),
              if (template.includeOpponent && template.opponent != null)
                _buildDetailRow('Opponent', template.opponent!),
              if (template.includeIsAwayGame)
                _buildDetailRow('Game Type', template.isAwayGame ? 'Away Game' : 'Home Game'),
              if (template.includeLevelOfCompetition && template.levelOfCompetition != null)
                _buildDetailRow('Level', template.levelOfCompetition!),
              if (template.includeGender && template.gender != null)
                _buildDetailRow('Gender', template.gender!),
              if (template.includeOfficialsRequired && template.officialsRequired != null)
                _buildDetailRow('Officials Required', '${template.officialsRequired}'),
              if (template.includeGameFee && template.gameFee != null)
                _buildDetailRow('Game Fee', '\$${template.gameFee}'),
              if (template.includeHireAutomatically && template.hireAutomatically != null)
                _buildDetailRow('Auto Hire', template.hireAutomatically! ? 'Yes' : 'No'),
              if (template.method != null)
                _buildDetailRow('Method', _getMethodDisplayName(template.method!)),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: const Text(
            'Close',
            style: TextStyle(
              color: efficialsYellow,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label: ',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: secondaryTextColor,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                color: primaryTextColor,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
          ),
        ],
      ),
    );
  }

  String _getMethodDisplayName(String method) {
    switch (method) {
      case 'use_list':
        return 'Use Saved List';
      case 'standard':
        return 'Standard Selection';
      case 'advanced':
        return 'Advanced Selection';
      case 'hire_crew':
        return 'Hire a Crew';
      default:
        return 'Not Set';
    }
  }
}
