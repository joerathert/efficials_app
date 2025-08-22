import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../shared/theme.dart';
import '../../shared/models/database_models.dart';
import '../../shared/services/schedule_service.dart';
import '../../shared/services/game_service.dart';
import '../../shared/services/repositories/template_repository.dart';
import '../../shared/services/repositories/game_template_repository.dart';
import '../../shared/services/repositories/user_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class ScheduleDetailsScreen extends StatefulWidget {
  const ScheduleDetailsScreen({super.key});

  @override
  State<ScheduleDetailsScreen> createState() => _ScheduleDetailsScreenState();
}

class _ScheduleDetailsScreenState extends State<ScheduleDetailsScreen> {
  String? scheduleName;
  int? scheduleId;
  String? sport; // Store the schedule's sport
  List<Map<String, dynamic>> games = [];
  bool isLoading = true;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  List<Map<String, dynamic>> _selectedDayGames = [];
  bool _showOnlyNeedsOfficials = false; // Toggle state for filtering
  String? associatedTemplateName; // Store the associated template name
  GameTemplate? template; // Store the associated template object
  bool _hasInitialized = false; // Track if we've initialized from route args
  final ScheduleService _scheduleService = ScheduleService();
  final GameService _gameService = GameService();
  final TemplateRepository _templateRepository = TemplateRepository();
  final GameTemplateRepository _gameTemplateRepository =
      GameTemplateRepository();
  final UserRepository _userRepository = UserRepository();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    // Only initialize from route arguments if we haven't already
    if (!_hasInitialized) {
      final args =
          ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
      scheduleName = args['scheduleName'] as String?;
      scheduleId = args['scheduleId'] as int?;
      
      // If scheduleId is null but we have a scheduleName, try to look it up
      if (scheduleId == null && scheduleName != null) {
        _lookupScheduleId();
      }
      
      _hasInitialized = true;
    } else {
    }
    
    // Run async operations concurrently for better performance
    _initializeScheduleData();
  }

  Future<void> _initializeScheduleData() async {
    // Run independent operations concurrently for better performance
    final futures = <Future<void>>[
      _fetchGames(),
      _loadAssociatedTemplate(),
    ];
    
    await Future.wait(futures);
    
    // Load schedule details after games are loaded (depends on games data)
    await _loadScheduleDetails();
  }

  Future<void> _lookupScheduleId() async {
    if (scheduleName == null) return;
    
    try {
      final schedules = await _scheduleService.getSchedules();
      final matchingSchedule = schedules.firstWhere(
        (schedule) => schedule['name'] == scheduleName,
        orElse: () => <String, dynamic>{},
      );
      
      if (matchingSchedule.isNotEmpty) {
        scheduleId = matchingSchedule['id'] as int?;
      } else {
      }
    } catch (e) {
      debugPrint('SCHEDULE SCREEN: Error looking up scheduleId: $e');
    }
  }

  Future<void> _loadScheduleDetails() async {
    if (scheduleId != null) {
      try {
        final scheduleDetails =
            await _scheduleService.getScheduleById(scheduleId!);
        if (scheduleDetails != null) {
          final scheduleSport = scheduleDetails['sport'] as String?;

          // If schedule sport is null or empty, try to infer it from games
          if (scheduleSport == null ||
              scheduleSport.isEmpty ||
              scheduleSport == 'null') {
            await _inferAndUpdateScheduleSport();
          } else {
            if (mounted) {
              setState(() {
                sport = scheduleSport;
              });
            }
          }
        }
      } catch (e) {
        // If database fails, sport will remain null and we'll fall back to the old method
        debugPrint('Failed to load schedule details: $e');
      }
    }
  }

  Future<void> _inferAndUpdateScheduleSport() async {
    // Try to infer sport from existing games
    String? inferredSport;
    if (games.isNotEmpty) {
      inferredSport = games.first['sport'] as String?;
    }

    // If we still don't have a sport, try to guess from schedule name
    if (inferredSport == null || inferredSport.isEmpty) {
      inferredSport = _inferSportFromScheduleName(scheduleName ?? '');
    }

    if (inferredSport.isNotEmpty && inferredSport != 'Unknown') {
      try {
        // Update the schedule in the database with the inferred sport
        // This is a simplified approach - you might want to implement updateScheduleSport in ScheduleService
        if (mounted) {
          setState(() {
            sport = inferredSport;
          });
        }
      } catch (e) {
        debugPrint('Failed to update schedule sport: $e');
      }
    } else {
      if (mounted) {
        setState(() {
          sport = 'Unknown';
        });
      }
    }
  }

  String _inferSportFromScheduleName(String scheduleName) {
    final name = scheduleName.toLowerCase();
    if (name.contains('football')) return 'Football';
    if (name.contains('basketball')) return 'Basketball';
    if (name.contains('baseball')) return 'Baseball';
    if (name.contains('soccer')) return 'Soccer';
    if (name.contains('tennis')) return 'Tennis';
    if (name.contains('volleyball')) return 'Volleyball';
    if (name.contains('track')) return 'Track';
    if (name.contains('swim')) return 'Swimming';
    if (name.contains('golf')) return 'Golf';
    if (name.contains('wrestling')) return 'Wrestling';
    if (name.contains('cross country')) return 'Cross Country';
    return 'Unknown';
  }

  Future<void> _fetchGames() async {
    try {
      // Use GameService exclusively to get games for this schedule
      final scheduleGames = scheduleName != null
          ? await _gameService.getGamesByScheduleName(scheduleName!)
          : <Map<String, dynamic>>[];

      if (mounted) {
        setState(() {
          games.clear();
          games = scheduleGames;

          // Ensure DateTime and TimeOfDay objects are properly parsed
        for (var game in games) {
          if (game['date'] != null && game['date'] is String) {
            game['date'] = DateTime.parse(game['date'] as String);
          }
          if (game['time'] != null && game['time'] is String) {
            final timeParts = (game['time'] as String).split(':');
            game['time'] = TimeOfDay(
              hour: int.parse(timeParts[0]),
              minute: int.parse(timeParts[1]),
            );
          }
        }

        if (games.isNotEmpty) {
          games.sort((a, b) =>
              (a['date'] as DateTime).compareTo(b['date'] as DateTime));

          // Find the next upcoming game (today or later)
          final now = DateTime.now();
          final today = DateTime(now.year, now.month, now.day);

          DateTime? nextGameDate;
          for (var game in games) {
            final gameDate = game['date'] as DateTime;
            final gameDateOnly =
                DateTime(gameDate.year, gameDate.month, gameDate.day);
            if (gameDateOnly.isAtSameMomentAs(today) ||
                gameDateOnly.isAfter(today)) {
              nextGameDate = gameDate;
              break;
            }
          }

          // Focus on the month containing the next upcoming game, or first game if all are past
          _focusedDay = nextGameDate ?? games.first['date'] as DateTime;

          // Don't auto-select any date - let user manually select
          _selectedDay = null;
          _selectedDayGames = [];
        } else {
          _focusedDay = DateTime.now();
        }

          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading games from database: $e');
      if (mounted) {
        setState(() {
          games.clear();
          _focusedDay = DateTime.now();
          isLoading = false;
        });
      }
    }
  }

  Future<void> _loadAssociatedTemplate() async {
    if (scheduleName == null) return;
    try {
      final user = await _userRepository.getCurrentUser();
      if (user?.id != null) {
        // First get the template name from the association
        final templateName = await _templateRepository.getByScheduleName(
            user!.id!, scheduleName!);

        if (templateName != null) {
          // Then get the full template data from game_templates table
          final templates = await _gameTemplateRepository
              .getTemplatesByNameSearch(user.id!, templateName);
          if (templates.isNotEmpty) {
            // Get selectedLists data from SharedPreferences if method is advanced
            if (templates.first.method == 'advanced' &&
                templates.first.id != null) {
              final prefs = await SharedPreferences.getInstance();
              final key = 'template_selectedLists_${templates.first.id}';
              final selectedListsJson = prefs.getString(key);
              if (selectedListsJson != null) {
                try {
                  final selectedLists = List<Map<String, dynamic>>.from(
                      jsonDecode(selectedListsJson));
                  templates.first = GameTemplate(
                    id: templates.first.id,
                    name: templates.first.name,
                    sportId: templates.first.sportId,
                    userId: templates.first.userId,
                    scheduleName: templates.first.scheduleName,
                    date: templates.first.date,
                    time: templates.first.time,
                    locationId: templates.first.locationId,
                    isAwayGame: templates.first.isAwayGame,
                    levelOfCompetition: templates.first.levelOfCompetition,
                    gender: templates.first.gender,
                    officialsRequired: templates.first.officialsRequired,
                    gameFee: templates.first.gameFee,
                    opponent: templates.first.opponent,
                    hireAutomatically: templates.first.hireAutomatically,
                    method: templates.first.method,
                    officialsListId: templates.first.officialsListId,
                    selectedOfficials: templates.first.selectedOfficials,
                    selectedLists: selectedLists,
                    officialsListName: templates.first.officialsListName,
                    includeScheduleName: templates.first.includeScheduleName,
                    includeSport: templates.first.includeSport,
                    includeDate: templates.first.includeDate,
                    includeTime: templates.first.includeTime,
                    includeLocation: templates.first.includeLocation,
                    includeIsAwayGame: templates.first.includeIsAwayGame,
                    includeLevelOfCompetition:
                        templates.first.includeLevelOfCompetition,
                    includeGender: templates.first.includeGender,
                    includeOfficialsRequired:
                        templates.first.includeOfficialsRequired,
                    includeGameFee: templates.first.includeGameFee,
                    includeOpponent: templates.first.includeOpponent,
                    includeHireAutomatically:
                        templates.first.includeHireAutomatically,
                    includeSelectedOfficials:
                        templates.first.includeSelectedOfficials,
                    includeOfficialsList: templates.first.includeOfficialsList,
                    createdAt: templates.first.createdAt,
                    sportName: templates.first.sportName,
                    locationName: templates.first.locationName,
                  );
                } catch (e) {
                }
              }
            }

            if (mounted) {
              setState(() {
                template = templates.first;
                associatedTemplateName = templateName;
              });
            }
          } else {
          }
        } else {
        }
      }
    } catch (e) {
      debugPrint('Error loading associated template: $e');
    }
  }

  Future<void> _removeAssociatedTemplate() async {
    if (scheduleName == null) return;
    try {
      final user = await _userRepository.getCurrentUser();
      if (user?.id != null) {
        await _templateRepository.removeAssociation(user!.id!, scheduleName!);
        if (mounted) {
          setState(() {
            associatedTemplateName = null;
            template = null; // Clear the template object
          });
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Template association removed')),
          );
        }
      }
    } catch (e) {
      debugPrint('Error removing associated template: $e');
    }
  }

  Future<void> _showTemplateDetails() async {
    if (template != null && mounted) {
      showDialog(
        context: context,
        builder: (context) => _buildTemplateDetailsDialog(template!),
      );
    } else {
      // Template not loaded, show error
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Template details not available')),
        );
      }
    }
  }

  void _showEditScheduleNameDialog() {
    final TextEditingController controller =
        TextEditingController(text: scheduleName);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: darkSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.edit, color: efficialsYellow, size: 24),
            SizedBox(width: 12),
            Text(
              'Edit Schedule Name',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: efficialsYellow,
              ),
            ),
          ],
        ),
        content: TextField(
          controller: controller,
          decoration: textFieldDecoration('Schedule Name'),
          style: const TextStyle(color: Colors.white),
          textCapitalization: TextCapitalization.words,
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(color: efficialsYellow, fontSize: 16),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              final newName = controller.text.trim();
              
              if (newName.isNotEmpty && newName != scheduleName) {
                Navigator.pop(context);
                _updateScheduleName(newName);
              } else if (newName.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Schedule name cannot be empty')),
                );
              } else {
                Navigator.pop(context);
              }
            },
            style: elevatedButtonStyle(),
            child: const Text(
              'Save',
              style: signInButtonTextStyle,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _updateScheduleName(String newName) async {
    
    if (scheduleName == null || scheduleId == null) {
      return;
    }

    try {
      final oldName = scheduleName!;

      // Update schedule name using ScheduleService
      final updatedSchedule =
          await _scheduleService.updateScheduleName(scheduleId!, newName);


      if (updatedSchedule != null) {
        
        // Update template association if it exists
        final user = await _userRepository.getCurrentUser();
        if (user?.id != null && associatedTemplateName != null) {
          await _templateRepository.updateScheduleName(
              user!.id!, oldName, newName);
        }

        // Update the current state
        if (mounted) {
          setState(() {
            scheduleName = newName;
          });
        }


        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Schedule renamed to "$newName"')),
          );
        }

        // Refresh the games to reflect the new name
        await _fetchGames();
        await _loadScheduleDetails();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to update schedule name')),
          );
        }
      }
    } catch (e) {
      debugPrint('SCHEDULE UPDATE ERROR: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating schedule name: $e')),
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

  Future<void> _showGameTypeDialog(DateTime day) async {
    if (scheduleName == null) return;

    final String? gameType = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: darkSurface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              const Icon(
                Icons.add_circle_outline,
                color: efficialsYellow,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'Add Game',
                style: const TextStyle(
                  color: efficialsYellow,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: Text(
            'Add a game for ${day.month}/${day.day}/${day.year}?',
            style: const TextStyle(
              color: primaryTextColor,
              fontSize: 16,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Cancel',
                style: TextStyle(color: secondaryTextColor),
              ),
            ),
            const SizedBox(width: 4),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop('away'),
              style: ElevatedButton.styleFrom(
                backgroundColor: efficialsYellow,
                foregroundColor: efficialsBlack,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.directions_bus, size: 16),
                  const SizedBox(width: 4),
                  const Text('Away', style: TextStyle(fontSize: 14)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop('home'),
              style: ElevatedButton.styleFrom(
                backgroundColor: efficialsYellow,
                foregroundColor: efficialsBlack,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.home, size: 16),
                  const SizedBox(width: 4),
                  const Text('Home', style: TextStyle(fontSize: 14)),
                ],
              ),
            ),
          ],
        );
      },
    );

    if (gameType != null && mounted) {
      await _createGame(day, gameType == 'away');
    }
  }

  Future<void> _createGame(DateTime selectedDate, bool isAway) async {
    if (!mounted) return;

    // Ensure template is loaded
    if (scheduleName != null) {
      await _loadAssociatedTemplate();
    }

    // Set up navigation arguments
    Map<String, dynamic> routeArgs = {
      'scheduleName': scheduleName,
      'scheduleId': scheduleId,
      'date': selectedDate,
      'fromScheduleDetails': true,
      'sport': sport ?? _inferSportFromScheduleName(scheduleName ?? ''),
      'template': template,
      'isAwayGame': isAway,
      'isAway': isAway,
    };

    // Add template time if available
    if (template != null && template!.includeTime && template!.time != null) {
      routeArgs['time'] = template!.time;
    }

    // Determine navigation route
    String nextRoute;
    bool canSkipToAdditionalInfo = template != null &&
        ((template!.includeTime && template!.time != null) ||
            (template!.method == 'advanced' &&
                template!.selectedLists != null &&
                template!.selectedLists!.isNotEmpty));

    if (canSkipToAdditionalInfo) {
      nextRoute = '/additional_game_info';
    } else {
      nextRoute = '/date_time';
    }

    Navigator.pushNamed(
      context,
      nextRoute,
      arguments: routeArgs,
    ).then((_) {
      _fetchGames();
    });
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

    if (result != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Game template created successfully!')),
      );
    }
  }

  void _showDeleteConfirmationDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: darkSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Delete Schedule',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.red,
          ),
        ),
        content: const Text(
          'Are you sure you want to delete this schedule? This action cannot be undone.',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(color: efficialsYellow, fontSize: 16),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              _showSecondDeleteConfirmationDialog();
            },
            style: elevatedButtonStyle(),
            child: const Text(
              'Delete',
              style: signInButtonTextStyle,
            ),
          ),
        ],
      ),
    );
  }

  void _showSecondDeleteConfirmationDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: darkSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border:
                    Border.all(color: Colors.red.withOpacity(0.3), width: 2),
              ),
              child: const Icon(
                Icons.warning_amber_rounded,
                color: Colors.red,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: Text(
                '⚠️ FINAL WARNING',
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'This action will permanently delete:',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.withOpacity(0.3)),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.schedule, color: Colors.red, size: 16),
                      SizedBox(width: 8),
                      Text(
                        'The entire schedule',
                        style: TextStyle(
                            color: Colors.red, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.sports, color: Colors.red, size: 16),
                      SizedBox(width: 8),
                      Text(
                        'All associated games',
                        style: TextStyle(
                            color: Colors.red, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.link, color: Colors.red, size: 16),
                      SizedBox(width: 8),
                      Text(
                        'Template associations',
                        style: TextStyle(
                            color: Colors.red, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'This action cannot be undone. Are you absolutely sure?',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: const Text(
              'Cancel',
              style: TextStyle(
                color: efficialsYellow,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deleteSchedule();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'DELETE PERMANENTLY',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteSchedule() async {
    if (scheduleId == null || scheduleName == null) return;

    try {
      // First, remove any template association
      final user = await _userRepository.getCurrentUser();
      if (user?.id != null) {
        await _templateRepository.removeAssociation(user!.id!, scheduleName!);
      }

      // Then, delete all games associated with this schedule
      final gamesToDelete =
          await _gameService.getGamesByScheduleName(scheduleName!);
      for (var game in gamesToDelete) {
        final gameId = game['id'] as int?;
        if (gameId != null) {
          await _gameService.deleteGame(gameId);
        }
      }

      // Finally, delete the schedule itself
      final success = await _scheduleService.deleteSchedule(scheduleId!);

      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  'Schedule and all associated games deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true); // Indicate deletion
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to delete schedule'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error deleting schedule: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error deleting schedule'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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
          onPressed: () {
            // Check if we can pop back to the previous screen
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              // Fallback to AD home screen if navigation stack is empty
              Navigator.pushNamedAndRemoveUntil(
                context,
                '/athletic_director_home',
                (route) => false,
              );
            }
          },
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: efficialsWhite),
            color: darkSurface,
            onSelected: (value) {
              if (value == 'delete') {
                _showDeleteConfirmationDialog();
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem<String>(
                value: 'delete',
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.delete,
                            color: Colors.red, size: 20),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Delete Schedule',
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
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
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Flexible(
                              child: Text(
                                scheduleName ?? 'Unnamed Schedule',
                                style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: efficialsYellow),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit,
                                  color: efficialsYellow, size: 20),
                              onPressed: _showEditScheduleNameDialog,
                              tooltip: 'Edit schedule name',
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        // Display the associated template (if any)
                        if (associatedTemplateName != null) ...[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: efficialsYellow.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                      color: efficialsYellow.withOpacity(0.3),
                                      width: 1),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.link,
                                      size: 16,
                                      color: efficialsYellow,
                                    ),
                                    const SizedBox(width: 6),
                                    GestureDetector(
                                      onTap: () async {
                                        await _showTemplateDetails();
                                      },
                                      child: Text(
                                        'Associated Template: $associatedTemplateName',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: efficialsYellow,
                                          decoration: TextDecoration.underline,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              GestureDetector(
                                onTap: _removeAssociatedTemplate,
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: Colors.red.withOpacity(0.1),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                        color: Colors.red.withOpacity(0.3),
                                        width: 1),
                                  ),
                                  child: Icon(
                                    Icons.close,
                                    size: 16,
                                    color: Colors.red.shade600,
                                  ),
                                ),
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
                            color: efficialsYellow.withOpacity(0.5),
                            shape: BoxShape.rectangle,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          selectedDecoration: BoxDecoration(
                            color: efficialsYellow,
                            shape: BoxShape.rectangle,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          selectedTextStyle: const TextStyle(
                              fontSize: 16, color: Colors.black),
                          defaultTextStyle: const TextStyle(
                              fontSize: 16, color: Colors.white),
                          weekendTextStyle: const TextStyle(
                              fontSize: 16, color: Colors.white),
                          outsideTextStyle:
                              const TextStyle(fontSize: 16, color: Colors.grey),
                          markersMaxCount: 0,
                        ),
                        daysOfWeekStyle: DaysOfWeekStyle(
                          weekdayStyle: const TextStyle(
                              fontSize: 14, color: Colors.white),
                          weekendStyle: const TextStyle(
                              fontSize: 14, color: Colors.white),
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
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white),
                          leftChevronIcon:
                              Icon(Icons.chevron_left, color: efficialsYellow),
                          rightChevronIcon:
                              Icon(Icons.chevron_right, color: efficialsYellow),
                          titleCentered: true,
                        ),
                        calendarBuilders: CalendarBuilders(
                          selectedBuilder: (context, day, focusedDay) {
                            final events = _getGamesForDay(day);
                            final hasEvents = events.isNotEmpty;
                            
                            Color backgroundColor = efficialsYellow;
                            Color textColor = Colors.black;

                            if (hasEvents) {
                              bool allAway = true;
                              bool allFullyHired = true;
                              bool needsOfficials = false;

                              for (var event in events) {
                                final isEventAway = event['isAway'] as bool? ?? false;
                                final hiredOfficials = event['officialsHired'] as int? ?? 0;
                                final requiredOfficials = int.tryParse(
                                        event['officialsRequired']?.toString() ?? '0') ??
                                    0;
                                final isFullyHired = hiredOfficials >= requiredOfficials;

                                if (!isEventAway) allAway = false;
                                if (!isFullyHired) allFullyHired = false;
                                if (!isEventAway && !isFullyHired) {
                                  needsOfficials = true;
                                }
                              }

                              if (allAway) {
                                backgroundColor = Colors.grey[300]!;
                                textColor = Colors.black;
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
                              onLongPress: () => _showGameTypeDialog(day),
                              onSecondaryTap: () => _showGameTypeDialog(day),
                              child: Container(
                                margin: const EdgeInsets.all(4.0),
                                decoration: BoxDecoration(
                                  color: backgroundColor,
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(color: efficialsYellow, width: 2),
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

                            // If the day is selected, return null to let the built-in selectedDecoration handle it
                            if (isSelected) {
                              return null;
                            }

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
                                textColor = Colors.black;
                              } else if (needsOfficials) {
                                backgroundColor = Colors.red;
                                textColor = Colors.white;
                              } else if (allFullyHired) {
                                backgroundColor = Colors.green;
                                textColor = Colors.white;
                              }
                            }

                            // Override text color to black when day is selected
                            if (isSelected) {
                              textColor = Colors.black;
                            }

                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedDay = day;
                                  _selectedDayGames = _getGamesForDay(day);
                                });
                              },
                              onLongPress: () => _showGameTypeDialog(day),
                              onSecondaryTap: () => _showGameTypeDialog(day), // Right-click for web
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
                                const Text('Away Game',
                                    style: TextStyle(color: Colors.white)),
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
                                const Text('Fully Hired',
                                    style: TextStyle(color: Colors.white)),
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
                                const Text('Needs Officials',
                                    style: TextStyle(color: Colors.white)),
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
                            const Text('Show only games needing officials',
                                style: TextStyle(color: Colors.white)),
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
                            padding: const EdgeInsets.only(
                                bottom:
                                    140), // Add bottom padding to prevent FAB overlap
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

                              return GestureDetector(
                                onTap: () {
                                  Navigator.pushNamed(
                                    context,
                                    '/game_information',
                                    arguments: {
                                      ...game,
                                      'sourceScreen': 'schedule_details',
                                      'scheduleName': scheduleName,
                                      'scheduleId': scheduleId,
                                    },
                                  ).then((result) {
                                    if (result != null) {
                                      if (result is Map<String, dynamic> &&
                                          result['deleted'] == true) {
                                        // Game was deleted, refresh and notify parent
                                        _fetchGames();
                                        Navigator.pop(context, true);
                                      } else if (result == true ||
                                          (result is Map<String, dynamic> &&
                                              result.isNotEmpty)) {
                                        // Game was modified, just refresh
                                        _fetchGames();
                                      }
                                    }
                                  });
                                },
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 4.0, horizontal: 16.0),
                                  child: Card(
                                    elevation: 2,
                                    color: darkSurface,
                                    child: Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Row(
                                        children: [
                                          IconButton(
                                            onPressed: () =>
                                                _createTemplateFromGame(game),
                                            icon: const Icon(Icons.link,
                                                color: efficialsYellow),
                                            tooltip:
                                                'Create Template from Game',
                                          ),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'Time: $gameTime',
                                                  style: const TextStyle(
                                                      fontSize: 16,
                                                      color: Colors.white),
                                                ),
                                                const SizedBox(height: 4),
                                                if (hiredOfficials >=
                                                    requiredOfficials)
                                                  Container(
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                        horizontal: 8,
                                                        vertical: 4),
                                                    decoration: BoxDecoration(
                                                      color: Colors.green,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              12),
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
                                                const SizedBox(height: 4),
                                                Text(
                                                  'Location: $location',
                                                  style: const TextStyle(
                                                      fontSize: 16,
                                                      color: Colors.white),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  'Opponent: $opponent',
                                                  style: const TextStyle(
                                                      fontSize: 16,
                                                      color: Colors.white),
                                                ),
                                              ],
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
              // Use the sport from the schedule itself, fallback to games if needed
              final sportToUse = sport ??
                  (games.isNotEmpty
                      ? games.first['sport'] as String? ?? 'Unknown'
                      : 'Unknown');
              Navigator.pushNamed(
                context,
                '/select_game_template',
                arguments: {
                  'scheduleName': scheduleName,
                  'sport': sportToUse,
                },
              ).then((_) {
                _loadAssociatedTemplate();
              });
            },
            backgroundColor: Colors.grey[600],
            tooltip: 'Set Template',
            child: const Icon(Icons.link, color: efficialsYellow),
          ),
          const SizedBox(height: 10),
          FloatingActionButton(
            heroTag: 'addGame',
            onPressed: _selectedDay == null
                ? null
                : () async {
                    // Ensure template is loaded before proceeding
                    if (scheduleName != null) {
                      await _loadAssociatedTemplate();
                    }

                    if (!mounted) return;

                    // Check if we can skip straight to additional info
                    bool canSkipToAdditionalInfo = template != null &&
                        ((template!.includeTime && template!.time != null) ||
                            (template!.method == 'advanced' &&
                                template!.selectedLists != null &&
                                template!.selectedLists!.isNotEmpty)) &&
                        _selectedDay != null;

                    String nextRoute = canSkipToAdditionalInfo
                        ? '/additional_game_info'
                        : '/date_time';

                    Navigator.pushNamed(
                      context,
                      nextRoute,
                      arguments: {
                        'scheduleName': scheduleName,
                        'scheduleId': scheduleId,
                        'date': _selectedDay,
                        'time': canSkipToAdditionalInfo ? template!.time : null,
                        'fromScheduleDetails': true,
                        'sport': sport ??
                            _inferSportFromScheduleName(scheduleName ?? ''),
                        'template': template,
                      },
                    ).then((_) {
                      _fetchGames();
                    });
                  },
            backgroundColor:
                _selectedDay == null ? Colors.grey[800] : Colors.grey[600],
            tooltip: 'Add Game',
            child: const Icon(Icons.add, size: 30, color: efficialsYellow),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget _buildTemplateDetailsDialog(GameTemplate template) {
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
              if (template.includeSport && template.sportName != null)
                _buildDetailRow('Sport', template.sportName!),
              if (template.includeTime && template.time != null)
                _buildDetailRow('Time', template.time!.format(context)),
              if (template.includeLocation && template.locationName != null)
                _buildDetailRow('Location', template.locationName!),
              if (template.includeOpponent && template.opponent != null)
                _buildDetailRow('Opponent', template.opponent!),
              if (template.includeIsAwayGame != null)
                _buildDetailRow('Game Type', template.isAwayGame! ? 'Away Game' : 'Home Game'),
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
