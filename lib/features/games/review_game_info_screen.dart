import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../shared/theme.dart';
import '../../shared/services/game_service.dart';
import '../../shared/services/repositories/advanced_method_repository.dart';
import '../../shared/services/repositories/list_repository.dart'; // Added import for ListRepository
import '../../shared/services/repositories/game_assignment_repository.dart';
import '../../shared/services/repositories/notification_repository.dart';
import '../../shared/models/database_models.dart';

class ReviewGameInfoScreen extends StatefulWidget {
  const ReviewGameInfoScreen({super.key});

  @override
  State<ReviewGameInfoScreen> createState() => _ReviewGameInfoScreenState();
}

class _ReviewGameInfoScreenState extends State<ReviewGameInfoScreen> {
  late Map<String, dynamic> args;
  late Map<String, dynamic> originalArgs;
  bool isEditMode = false;
  bool isFromGameInfo = false;
  bool isAwayGame = false;
  bool fromScheduleDetails = false;
  int? scheduleId;
  bool? isCoachScheduler;
  String? teamName;
  bool isUsingTemplate = false;
  bool isAssignerFlow = false;
  bool _isPublishing =
      false; // Add loading state to prevent duplicate submissions
  bool _showButtonLoading =
      false; // Separate state for button loading indicators
  bool _hasInitialized =
      false; // Track if we've already initialized to prevent overwriting
  final GameService _gameService = GameService();
  final GameAssignmentRepository _gameAssignmentRepository = GameAssignmentRepository();
  final NotificationRepository _notificationRepository = NotificationRepository();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Only initialize once to prevent overwriting state updates from edit flows
    if (!_hasInitialized) {
      final newArgs =
          ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
      
      
      setState(() {
        args = Map<String, dynamic>.from(newArgs);
        originalArgs = Map<String, dynamic>.from(newArgs);
        isEditMode = newArgs['isEdit'] == true;
        isFromGameInfo = newArgs['isFromGameInfo'] == true;
        isAwayGame = newArgs['isAway'] == true;
        fromScheduleDetails = newArgs['fromScheduleDetails'] == true;
        scheduleId = newArgs['scheduleId'] as int?;
        isUsingTemplate = newArgs['template'] != null;
        isAssignerFlow = newArgs['isAssignerFlow'] == true;
        if (args['officialsRequired'] != null) {
          args['officialsRequired'] =
              int.tryParse(args['officialsRequired'].toString()) ?? 0;
        }
        _hasInitialized = true;
      });
      _loadSchedulerType();
    }
  }

  @override
  void initState() {
    super.initState();
    args = {};
    originalArgs = {};
    _hasInitialized = false;
  }

  Future<bool?> _showCreateTemplateDialog() async {
    final prefs = await SharedPreferences.getInstance();
    final dontAskAgain = prefs.getBool('dont_ask_create_template') ?? false;

    if (dontAskAgain) {
      return false; // Don't create template if user opted out
    }

    bool checkboxValue = false;

    if (!mounted) return false;
    return await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: darkSurface,
          title: const Text('Create Game Template',
              style: TextStyle(
                  color: efficialsYellow,
                  fontSize: 20,
                  fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                  'Would you like to create a Game Template using the information from this game?',
                  style: TextStyle(color: Colors.white)),
              const SizedBox(height: 16),
              Row(
                children: [
                  Checkbox(
                    value: checkboxValue,
                    onChanged: (value) {
                      setDialogState(() {
                        checkboxValue = value ?? false;
                      });
                    },
                    activeColor: efficialsYellow,
                    checkColor: efficialsBlack,
                  ),
                  const Expanded(
                    child: Text('Do not ask me again',
                        style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () async {
                if (checkboxValue) {
                  await prefs.setBool('dont_ask_create_template', true);
                }
                if (mounted) {
                  // ignore: use_build_context_synchronously
                  Navigator.pop(context, false);
                }
              },
              child: const Text('No', style: TextStyle(color: efficialsYellow)),
            ),
            TextButton(
              onPressed: () async {
                if (checkboxValue) {
                  await prefs.setBool('dont_ask_create_template', true);
                }
                if (mounted) {
                  // ignore: use_build_context_synchronously
                  Navigator.pop(context, true);
                }
              },
              child:
                  const Text('Yes', style: TextStyle(color: efficialsYellow)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _loadSchedulerType() async {
    final prefs = await SharedPreferences.getInstance();
    final schedulerType = prefs.getString('schedulerType');
    final savedTeamName = prefs.getString('team_name');
    setState(() {
      isCoachScheduler = schedulerType?.toLowerCase() == 'coach';
      teamName = savedTeamName;

      // If this is a Coach user and no schedule name is set yet, set it to team name
      if (isCoachScheduler == true &&
          args['scheduleName'] == null &&
          teamName != null) {
        args['scheduleName'] = teamName;
      }
    });
  }

  Future<void> _publishGame() async {
    // Prevent multiple simultaneous calls
    if (_isPublishing) return;

    setState(() {
      _isPublishing = true;
      _showButtonLoading = true;
    });

    try {
      // Validate that time is set before publishing
      if (args['time'] == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(
                  'Please set a game time before publishing.')),
        );
        return;
      }

      if (!isAwayGame &&
          !(args['hireAutomatically'] == true) &&
          args['selectedCrew'] == null &&
          (args['selectedCrews'] == null || (args['selectedCrews'] as List).isEmpty) &&
          (args['selectedOfficials'] == null ||
              (args['selectedOfficials'] as List).isEmpty)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(
                  'Please select at least one official for non-away games.')),
        );
        return;
      }

      final gameData = Map<String, dynamic>.from(args);
      gameData['id'] = gameData['id'] ?? DateTime.now().millisecondsSinceEpoch;
      gameData['createdAt'] = DateTime.now().toIso8601String();
      gameData['officialsHired'] = gameData['officialsHired'] ?? 0;
      gameData['status'] = 'Published';

      // Ensure schedule name is set
      if (gameData['scheduleName'] == null) {
        if (isCoachScheduler == true) {
          gameData['scheduleName'] = teamName ?? 'Team Schedule';
        } else {
          // For Athletic Director, require a schedule name
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Please set a schedule name before publishing.')),
          );
          return;
        }
      }

      // Save to database first with original data types
      try {
        final dbResult = await _gameService.createGame(gameData);
        if (dbResult != null) {
          final gameId = dbResult['id'] as int;

          // IMPORTANT: For officials to see games in "Available Games", we should NOT create initial assignments
          // Creating assignments puts games in "Pending Interest" instead of "Available Games"
          // Let officials discover and claim games themselves through the Available Games interface
          //
          // The old logic was:
          // - hireAutomatically = false → create assignments → Pending Interest
          // - hireAutomatically = true → no assignments → Available Games
          //
          // New logic: NO initial assignments for any method - let officials claim games
          final hireAutomatically = gameData['hireAutomatically'] ?? false;
          final method = gameData['method'] as String?;

          // Create assignments based on method type
          if (!isAwayGame && method != null) {
            if (method == 'hire_crew') {
              // For crew hiring, always create crew assignments regardless of hireAutomatically setting
              await _createCrewChiefAssignments(gameId, gameData);
            } else if (method != 'advanced' && !hireAutomatically) {
              // For other methods (use_list, standard), only create assignments if not hiring automatically
              await _gameService.createInitialAssignments(gameId, method, gameData);
            }
          }

          // Save advanced selection data for later reconstruction AND create quota records
          if (gameData['method'] == 'advanced' &&
              gameData['selectedLists'] != null) {
            final prefs = await SharedPreferences.getInstance();
            final advancedData = {
              'selectedLists': gameData['selectedLists'],
              'selectedOfficials': gameData['selectedOfficials'] ?? [],
            };
            await prefs.setString(
                'recent_advanced_selection_$gameId', jsonEncode(advancedData));

            // CREATE ACTUAL QUOTA RECORDS IN DATABASE WITH ENHANCED VALIDATION
            try {
              final selectedLists = gameData['selectedLists'] as List<dynamic>;

              // RESOLVE LIST IDS TO ACTUAL DATABASE IDS
              final resolvedLists = await _resolveListIds(selectedLists);
  
              // Validate each list has required fields
              final quotas = <Map<String, dynamic>>[];
              for (int i = 0; i < resolvedLists.length; i++) {
                final list = resolvedLists[i] as Map<String, dynamic>;
  
                // Validate required fields
                if (!list.containsKey('id') || list['id'] == null) {
                  continue;
                }
                if (!list.containsKey('minOfficials') ||
                    list['minOfficials'] == null) {
                  continue;
                }
                if (!list.containsKey('maxOfficials') ||
                    list['maxOfficials'] == null) {
                  continue;
                }

                final quota = {
                  'listId': list['id'] as int,
                  'minOfficials': list['minOfficials'] as int,
                  'maxOfficials': list['maxOfficials'] as int,
                };
                quotas.add(quota);
                }

              if (quotas.isEmpty) {
                throw Exception('No valid quotas found in selectedLists data');
              }

              // Create quota records in database
              final advancedRepo = AdvancedMethodRepository();
              await advancedRepo.setGameListQuotas(gameId, quotas);

              // Verify quota creation by reading back
              final createdQuotas =
                  await advancedRepo.getGameListQuotas(gameId);
            } catch (e, stackTrace) {
              debugPrint('📚 Stack trace: $stackTrace');

              // Show user-visible error for quota creation failure
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                        'Warning: Advanced Method quota setup failed. Game may not be visible to officials. Error: $e'),
                    backgroundColor: Colors.orange,
                    duration: const Duration(seconds: 5),
                  ),
                );
              }
            }
          } else if (gameData['method'] == 'use_list' &&
              gameData['selectedListName'] != null) {
            final prefs = await SharedPreferences.getInstance();
            final useListData = {
              'selectedListName': gameData['selectedListName'],
              'selectedOfficials': gameData['selectedOfficials'] ?? [],
            };
            await prefs.setString(
                'recent_use_list_selection_$gameId', jsonEncode(useListData));
          } else if (gameData['method'] == 'hire_crew' &&
              (gameData['selectedCrews'] != null || gameData['selectedCrewListName'] != null)) {
            final prefs = await SharedPreferences.getInstance();
            final hireCrewData = {
              'selectedCrews': gameData['selectedCrews'] ?? [],
              'selectedCrewListName': gameData['selectedCrewListName'],
            };
            await prefs.setString(
                'recent_hire_crew_selection_$gameId', jsonEncode(hireCrewData));
          }
        } else {
          debugPrint('Failed to save game to database - result was null');
        }
      } catch (e) {
        debugPrint('Error saving game to database: $e');
        // Continue with SharedPreferences as fallback
      }

      // Database storage is now the primary method - no longer saving to SharedPreferences to avoid duplicates

      // Don't show template dialog if game was created using a template or is away game
      bool? shouldCreateTemplate = false;
      if (!isUsingTemplate && !isAwayGame) {
        // Hide button loading before showing dialog
        if (mounted) {
          setState(() {
            _showButtonLoading = false;
          });
        }
        shouldCreateTemplate = await _showCreateTemplateDialog();
      }

      if (shouldCreateTemplate == true && !isAwayGame) {
        if (mounted) {
          // Prepare data for template creation (convert DateTime and TimeOfDay to strings)
          final templateData = Map<String, dynamic>.from(gameData);
          if (templateData['date'] != null) {
            templateData['date'] =
                (templateData['date'] as DateTime).toIso8601String();
          }
          if (templateData['time'] != null) {
            final time = templateData['time'] as TimeOfDay;
            templateData['time'] = '${time.hour}:${time.minute}';
          }

          Navigator.pushNamed(
            context,
            '/new_game_template',
            arguments: templateData,
          ).then((result) {
            if (result == true && mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Game Template created successfully!')),
              );
            }
            _navigateBack();
          });
        }
      } else if (shouldCreateTemplate == true && isAwayGame) {
        if (mounted) {
          await showDialog(
            context: context,
            builder: (context) => AlertDialog(
              backgroundColor: darkSurface,
              title: const Text('Away Game Template Not Supported',
                  style: TextStyle(
                      color: efficialsYellow,
                      fontSize: 18,
                      fontWeight: FontWeight.bold)),
              content: const Text(
                'Game templates can only be created from Home Games. Away Games have different data requirements and cannot be used as template bases.\n\nTo create a template, please use a Home Game instead.',
                style: TextStyle(color: Colors.white),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('OK',
                      style: TextStyle(color: efficialsYellow)),
                ),
              ],
            ),
          );
        }
        _navigateBack();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Game published successfully!')),
          );
        }
        _navigateBack();
      }
    } finally {
      // Always reset the publishing state
      if (mounted) {
        setState(() {
          _isPublishing = false;
          _showButtonLoading = false;
        });
      }
    }
  }

  Future<void> _publishLater() async {
    // Prevent multiple simultaneous calls
    if (_isPublishing) return;

    setState(() {
      _isPublishing = true;
      _showButtonLoading = true;
    });

    try {
      // Validate that time is set before saving
      if (args['time'] == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(
                  'Please set a game time before saving.')),
        );
        return;
      }

      final gameData = Map<String, dynamic>.from(args);
      gameData['id'] = gameData['id'] ?? DateTime.now().millisecondsSinceEpoch;
      gameData['createdAt'] = DateTime.now().toIso8601String();
      gameData['status'] = 'Unpublished';

      // Ensure schedule name is set
      if (gameData['scheduleName'] == null) {
        if (isCoachScheduler == true) {
          gameData['scheduleName'] = teamName ?? 'Team Schedule';
        } else {
          // For Athletic Director, require a schedule name
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Please set a schedule name before saving.')),
          );
          return;
        }
      }

      // Save to database first with original data types
      try {
        final dbResult = await _gameService.createGame(gameData);
        if (dbResult != null) {
        } else {
        }
      } catch (e) {
        debugPrint('Error saving unpublished game to database: $e');
        // Continue with SharedPreferences as fallback
      }

      // Convert data for SharedPreferences storage
      if (gameData['date'] != null) {
        gameData['date'] = (gameData['date'] as DateTime).toIso8601String();
      }
      if (gameData['time'] != null) {
        final time = gameData['time'] as TimeOfDay;
        gameData['time'] = '${time.hour}:${time.minute}';
      }

      final prefs = await SharedPreferences.getInstance();

      // Determine which storage key to use based on user role
      String unpublishedGamesKey;
      if (isCoachScheduler == true) {
        unpublishedGamesKey = 'coach_unpublished_games';
      } else if (isAssignerFlow == true) {
        unpublishedGamesKey = 'assigner_unpublished_games';
      } else {
        unpublishedGamesKey = 'ad_unpublished_games';
      }

      final String? gamesJson = prefs.getString(unpublishedGamesKey);
      List<Map<String, dynamic>> unpublishedGames = [];
      if (gamesJson != null && gamesJson.isNotEmpty) {
        unpublishedGames =
            List<Map<String, dynamic>>.from(jsonDecode(gamesJson));
      }

      unpublishedGames.add(gameData);
      await prefs.setString(unpublishedGamesKey, jsonEncode(unpublishedGames));

      // Don't show template dialog if game was created using a template or is away game
      bool? shouldCreateTemplate = false;
      if (!isUsingTemplate && !isAwayGame) {
        // Hide button loading before showing dialog
        if (mounted) {
          setState(() {
            _showButtonLoading = false;
          });
        }
        shouldCreateTemplate = await _showCreateTemplateDialog();
      }

      if (shouldCreateTemplate == true && !isAwayGame) {
        if (mounted) {
          Navigator.pushNamed(
            context,
            '/new_game_template',
            arguments: gameData,
          ).then((result) {
            if (result == true && mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Game Template created successfully!')),
              );
            }
            _navigateBack();
          });
        }
      } else if (shouldCreateTemplate == true && isAwayGame) {
        if (mounted) {
          await showDialog(
            context: context,
            builder: (context) => AlertDialog(
              backgroundColor: darkSurface,
              title: const Text('Away Game Template Not Supported',
                  style: TextStyle(
                      color: efficialsYellow,
                      fontSize: 18,
                      fontWeight: FontWeight.bold)),
              content: const Text(
                'Game templates can only be created from Home Games. Away Games have different data requirements and cannot be used as template bases.\n\nTo create a template, please use a Home Game instead.',
                style: TextStyle(color: Colors.white),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('OK',
                      style: TextStyle(color: efficialsYellow)),
                ),
              ],
            ),
          );
        }
        _navigateBack();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Game saved to Unpublished Games list!')),
          );
        }
        _navigateBack();
      }
    } finally {
      // Always reset the publishing state
      if (mounted) {
        setState(() {
          _isPublishing = false;
          _showButtonLoading = false;
        });
      }
    }
  }

  void _navigateBack() async {
    if (fromScheduleDetails) {
      if (isAssignerFlow) {
        // For Assigners, navigate back to Manage Schedules screen with team selection
        final teamName = args['scheduleName'] as String?;

        final gameDate = args['date'] as DateTime?;

        Navigator.pushNamedAndRemoveUntil(
          context,
          '/assigner_manage_schedules',
          (route) =>
              route.settings.name ==
              '/assigner_home', // Keep assigner home in stack
          arguments: {
            'selectedTeam': teamName, // Pass the team name back
            'focusDate': gameDate, // Pass the game date to focus calendar
          },
        );
      } else {
        // For Athletic Directors, navigate to Schedule Details screen
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/schedule_details',
          (route) => false,
          arguments: {
            'scheduleName': args['scheduleName'],
            'scheduleId': scheduleId,
          },
        );
      }
    } else {
      final prefs = await SharedPreferences.getInstance();
      final schedulerType = prefs.getString('schedulerType');

      String homeRoute;
      switch (schedulerType?.toLowerCase()) {
        case 'athletic director':
        case 'athleticdirector':
        case 'ad':
          homeRoute = '/athletic_director_home';
          break;
        case 'coach':
          homeRoute = '/coach_home';
          break;
        case 'assigner':
          homeRoute = '/assigner_home';
          break;
        default:
          homeRoute = '/welcome';
      }

      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          homeRoute,
          (route) => false,
          arguments: {'refresh': true}, // Force refresh when returning to home
        );
      }
    }
  }

  Future<void> _publishUpdate() async {
    final gameData = Map<String, dynamic>.from(args);
    gameData['status'] = 'Published';

    // Update the database first (GameService handles the data conversion internally)
    try {
      if (gameData['id'] != null) {
        final gameId = gameData['id'] as int;

        // Get the original game data to compare for assignment updates
        final originalGameData =
            await _gameService.getGameByIdWithOfficials(gameId);

        await _gameService.updateGame(gameId, gameData);
        debugPrint('Game updated in database successfully with ID: $gameId');

        // Update official assignments if the lists changed
        if (originalGameData != null && !isAwayGame) {
          final oldMethod = originalGameData['method'] as String? ?? '';
          final newMethod = gameData['method'] as String? ?? '';

          // Check if assignment-affecting data changed
          bool shouldUpdateAssignments = false;

          if (oldMethod == 'use_list' && newMethod == 'use_list') {
            // Check if selected list changed
            final oldListName = originalGameData['selectedListName'] as String?;
            final newListName = gameData['selectedListName'] as String?;
            shouldUpdateAssignments = oldListName != newListName;
          } else if (oldMethod == 'advanced' && newMethod == 'advanced') {
            // Check if selected lists changed
            final oldLists =
                originalGameData['selectedLists'] as List<dynamic>?;
            final newLists = gameData['selectedLists'] as List<dynamic>?;
            shouldUpdateAssignments = !_listsEqual(oldLists, newLists);
          } else if (oldMethod != newMethod) {
            // Method changed completely
            shouldUpdateAssignments = true;
          }

          if (shouldUpdateAssignments) {
            await _gameService.updateAssignmentsForListChange(
                gameId, oldMethod, originalGameData, newMethod, gameData);
          }
        }

        // Update selection data cache for both advanced and use_list methods
        final prefs = await SharedPreferences.getInstance();
        if (gameData['method'] == 'advanced' &&
            gameData['selectedLists'] != null) {
          final advancedData = {
            'selectedLists': gameData['selectedLists'],
            'selectedOfficials': gameData['selectedOfficials'] ?? [],
          };
          await prefs.setString(
              'recent_advanced_selection_$gameId', jsonEncode(advancedData));
          debugPrint('Updated advanced selection data for game $gameId');

          // UPDATE QUOTA RECORDS IN DATABASE WITH ENHANCED VALIDATION
          try {
            final selectedLists = gameData['selectedLists'] as List<dynamic>;

            // RESOLVE LIST IDS TO ACTUAL DATABASE IDS
            final resolvedLists = await _resolveListIds(selectedLists);

            // Validate each list has required fields
            final quotas = <Map<String, dynamic>>[];
            for (int i = 0; i < resolvedLists.length; i++) {
              final list = resolvedLists[i] as Map<String, dynamic>;

              // Validate required fields
              if (!list.containsKey('id') || list['id'] == null) {
                continue;
              }
              if (!list.containsKey('minOfficials') ||
                  list['minOfficials'] == null) {
                continue;
              }
              if (!list.containsKey('maxOfficials') ||
                  list['maxOfficials'] == null) {
                continue;
              }

              final quota = {
                'listId': list['id'] as int,
                'minOfficials': list['minOfficials'] as int,
                'maxOfficials': list['maxOfficials'] as int,
              };
              quotas.add(quota);
            }

            if (quotas.isEmpty) {
              throw Exception('No valid quotas found in selectedLists data');
            }

            // Update quota records in database
            final advancedRepo = AdvancedMethodRepository();
            await advancedRepo.setGameListQuotas(gameId, quotas);

            // Verify quota update by reading back
            final updatedQuotas = await advancedRepo.getGameListQuotas(gameId);
          } catch (e, stackTrace) {
            debugPrint('📚 Stack trace: $stackTrace');

            // Show user-visible error for quota update failure
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                      'Warning: Advanced Method quota update failed. Game may not be visible to officials. Error: $e'),
                  backgroundColor: Colors.orange,
                  duration: const Duration(seconds: 5),
                ),
              );
            }
          }
        } else if (gameData['method'] == 'use_list' &&
            gameData['selectedListName'] != null) {
          final useListData = {
            'selectedListName': gameData['selectedListName'],
            'selectedOfficials': gameData['selectedOfficials'] ?? [],
          };
          await prefs.setString(
              'recent_use_list_selection_$gameId', jsonEncode(useListData));
        } else if (gameData['method'] == 'hire_crew' &&
            (gameData['selectedCrews'] != null || gameData['selectedCrewListName'] != null)) {
          final hireCrewData = {
            'selectedCrews': gameData['selectedCrews'] ?? [],
            'selectedCrewListName': gameData['selectedCrewListName'],
          };
          await prefs.setString(
              'recent_hire_crew_selection_$gameId', jsonEncode(hireCrewData));
        }
      }
    } catch (e) {
      debugPrint('Error updating game in database: $e');
    }

    // Update SharedPreferences cache with properly formatted data
    final prefs = await SharedPreferences.getInstance();
    final String? gamesJson = prefs.getString('ad_published_games');
    List<Map<String, dynamic>> publishedGames = [];
    if (gamesJson != null && gamesJson.isNotEmpty) {
      publishedGames = List<Map<String, dynamic>>.from(jsonDecode(gamesJson));
    }

    // Create a copy of gameData with proper JSON formatting for SharedPreferences
    final gameDataForJson = Map<String, dynamic>.from(gameData);

    // Convert DateTime and TimeOfDay objects to strings for JSON storage
    if (gameDataForJson['date'] != null &&
        gameDataForJson['date'] is DateTime) {
      gameDataForJson['date'] =
          (gameDataForJson['date'] as DateTime).toIso8601String();
    }
    if (gameDataForJson['time'] != null &&
        gameDataForJson['time'] is TimeOfDay) {
      final time = gameDataForJson['time'] as TimeOfDay;
      gameDataForJson['time'] = '${time.hour}:${time.minute}';
    }
    if (gameDataForJson['createdAt'] != null &&
        gameDataForJson['createdAt'] is DateTime) {
      gameDataForJson['createdAt'] =
          (gameDataForJson['createdAt'] as DateTime).toIso8601String();
    }
    if (gameDataForJson['updatedAt'] != null &&
        gameDataForJson['updatedAt'] is DateTime) {
      gameDataForJson['updatedAt'] =
          (gameDataForJson['updatedAt'] as DateTime).toIso8601String();
    }

    final index = publishedGames.indexWhere((g) => g['id'] == gameData['id']);
    if (index != -1) {
      publishedGames[index] = gameDataForJson;
    } else {
      publishedGames.add(gameDataForJson);
    }

    await prefs.setString('ad_published_games', jsonEncode(publishedGames));

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Game updated successfully!')),
      );
    }

    if (isFromGameInfo) {
      // Navigate back to the original source screen
      final sourceScreen = args['sourceScreen'] as String?;

      if (mounted) {
        if (sourceScreen == 'schedule_details') {
          // Navigate back to schedule details screen
          Navigator.pushNamedAndRemoveUntil(
            context,
            '/schedule_details',
            (route) => false,
            arguments: {
              'scheduleName': args['scheduleName'],
              'scheduleId': args['scheduleId'],
            },
          );
        } else {
          // Default to athletic director home (covers both 'athletic_director_home' and unknown sources)
          Navigator.pushNamedAndRemoveUntil(
            context,
            '/athletic_director_home',
            (route) => false,
            arguments: {'refresh': true, 'gameUpdated': true},
          );
        }
      }
    } else {
      if (mounted) {
        Navigator.pop(context, {'refresh': true, 'gameData': gameData});
      }
    }
  }

  bool _hasChanges() {
    return args.toString() != originalArgs.toString();
  }

  // Helper method to compare two lists for equality
  bool _listsEqual(List<dynamic>? list1, List<dynamic>? list2) {
    if (list1 == null && list2 == null) return true;
    if (list1 == null || list2 == null) return false;
    if (list1.length != list2.length) return false;

    for (int i = 0; i < list1.length; i++) {
      final item1 = list1[i] as Map<String, dynamic>;
      final item2 = list2[i] as Map<String, dynamic>;
      if (item1['name'] != item2['name']) return false;
    }

    return true;
  }

  Future<List<Map<String, dynamic>>> _resolveListIds(
      List<dynamic> selectedLists) async {
    final resolvedLists = <Map<String, dynamic>>[];

    try {
      // Get the ListRepository to query actual database IDs
      final listRepository = ListRepository();

      for (final listItem in selectedLists) {
        final list = Map<String, dynamic>.from(listItem as Map);
        final listName = list['name'] as String;
        final sharedPrefsId = list['id']; // This is the SharedPreferences ID

        // First try to query database to get actual list ID by name
        final dbResults = await listRepository.rawQuery(
            'SELECT id FROM official_lists WHERE name = ?', [listName]);

        if (dbResults.isNotEmpty) {
          final actualId = dbResults.first['id'] as int;
          resolvedLists.add({...list, 'id': actualId});
        } else {
          // If not found by name, check if the SharedPrefs ID is already a valid database ID
          final idCheckResults = await listRepository.rawQuery(
              'SELECT id FROM official_lists WHERE id = ?', [sharedPrefsId]);
          
          if (idCheckResults.isNotEmpty) {
            // The SharedPrefs ID is actually a valid database ID
            resolvedLists.add(list); // Use as-is
          } else {
          }
        }
      }
    } catch (e) {
      debugPrint('❌ Error resolving list IDs: $e');
      // Fallback to original list if resolution fails
      return selectedLists
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList();
    }

    return resolvedLists;
  }

  Future<void> _createCrewChiefAssignments(int gameId, Map<String, dynamic> gameData) async {
    try {
      final selectedCrews = gameData['selectedCrews'] as List<dynamic>?;
      final selectedCrew = gameData['selectedCrew'];
      
      
      List<dynamic> crewsToProcess = [];
      if (selectedCrews != null) {
        crewsToProcess = selectedCrews;
      } else if (selectedCrew != null) {
        crewsToProcess = [selectedCrew];
      }
      
      
      if (crewsToProcess.isEmpty) {
        return;
      }
      
      // Create CREW assignments (not individual game assignments) for hire_crew games
      // This allows the game to remain visible in Available Games until crews respond
      for (final crewData in crewsToProcess) {
        final crewId = crewData is Map<String, dynamic> 
            ? crewData['id'] as int?
            : (crewData as dynamic).id as int?;
            
        
        // Look up the actual crew_chief_id from the database
        int? crewChiefId;
        if (crewId != null) {
          final crewQuery = await _gameAssignmentRepository.rawQuery(
            'SELECT crew_chief_id FROM crews WHERE id = ? AND is_active = 1',
            [crewId]
          );
          crewChiefId = crewQuery.isNotEmpty ? crewQuery.first['crew_chief_id'] as int? : null;
        }
            
        
        if (crewId != null && crewChiefId != null) {
          // Create crew assignment instead of individual game assignment
          final crewAssignment = {
            'game_id': gameId,
            'crew_id': crewId,
            'status': 'pending',
            'assigned_by': await _getCurrentUserId(),
            'assigned_at': DateTime.now().toIso8601String(),
            'total_fee_amount': _parseDouble(gameData['gameFee']),
            'response_notes': 'Crew hiring - notification sent to crew chief',
          };
          
          
          await _gameAssignmentRepository.rawQuery(
            'INSERT INTO crew_assignments (game_id, crew_id, crew_chief_id, status, assigned_by, assigned_at, total_fee_amount, response_notes) VALUES (?, ?, ?, ?, ?, ?, ?, ?)',
            [
              crewAssignment['game_id'],
              crewAssignment['crew_id'],
              crewChiefId,
              crewAssignment['status'],
              crewAssignment['assigned_by'],
              crewAssignment['assigned_at'],
              crewAssignment['total_fee_amount'],
              crewAssignment['response_notes'],
            ]
          );
          
          
          // Small delay to ensure database transaction is committed
          await Future.delayed(const Duration(milliseconds: 100));
          
          // NOTE: No notification needed - crew chiefs will see the game in Available Games list
        }
      }
    } catch (e) {
    }
  }
  
  double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  Future<void> _createCrewChiefNotification(int crewChiefId, Map<String, dynamic> gameData) async {
    try {
      final sportName = gameData['sport'] as String? ?? 'Game';
      final opponent = gameData['opponent'] as String? ?? 'TBD';
      final homeTeam = gameData['homeTeam'] as String? ?? 'TBD';
      final gameDate = gameData['date'] as DateTime?;
      final gameTime = gameData['time'] as TimeOfDay?;
      final gameFee = _parseDouble(gameData['gameFee']) ?? 0;
      
      final gameTitle = opponent != 'TBD' && homeTeam != 'TBD' 
          ? '$opponent @ $homeTeam' 
          : (opponent != 'TBD' ? opponent : homeTeam);
      
      final dateStr = gameDate != null 
          ? DateFormat('MMMM d, yyyy').format(gameDate)
          : 'TBD';
      final timeStr = gameTime != null 
          ? gameTime.format(context)
          : 'TBD';
      
      await _notificationRepository.createOfficialNotification(
        officialId: crewChiefId,
        type: 'crew_game_available',
        title: 'Crew Game Available',
        message: 'A $sportName game ($gameTitle) is available for your crew on $dateStr at $timeStr. Fee: \$${gameFee.toStringAsFixed(2)}. Tap to view and claim for your crew.',
        relatedGameId: gameData['id'] as int?,
      );
      debugPrint('Created crew chief notification for official $crewChiefId');
    } catch (e) {
      debugPrint('Error creating crew chief notification: $e');
    }
  }
  
  Future<int> _getCurrentUserId() async {
    // This should get the current scheduler's user ID
    // For now, return a default value, but this should be implemented properly
    return 1; // TODO: Implement proper user ID retrieval
  }

  Future<bool> _onWillPop() async {
    if (!_hasChanges()) {
      return true;
    }

    final shouldDiscard = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: darkSurface,
        title: const Text('Unsaved Changes',
            style: TextStyle(
                color: efficialsYellow,
                fontSize: 20,
                fontWeight: FontWeight.bold)),
        content: const Text(
            'You have unsaved changes. Are you sure you want to discard them?',
            style: TextStyle(color: Colors.white)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child:
                const Text('Cancel', style: TextStyle(color: efficialsYellow)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('OK', style: TextStyle(color: efficialsYellow)),
          ),
        ],
      ),
    );

    return shouldDiscard ?? false;
  }

  @override
  Widget build(BuildContext context) {
    
    // Create gameDetails map without Schedule Name initially
    final gameDetails = <String, String>{
      'Sport': args['sport'] as String? ?? 'Unknown',
    };
    
    // Only add Schedule Name for non-Coach users (when isCoachScheduler is explicitly false)
    if (isCoachScheduler == false) {
      gameDetails['Schedule Name'] = args['scheduleName'] as String? ?? 'Unnamed';
    }
    
    // Add remaining details
    gameDetails.addAll({
      'Date': args['date'] != null
          ? DateFormat('MMMM d, yyyy').format(args['date'] as DateTime)
          : 'Not set',
      'Time': args['time'] != null
          ? (args['time'] as TimeOfDay).format(context)
          : 'Not set',
      'Location': args['location'] as String? ?? 'Not set',
      'Opponent': args['opponent'] as String? ?? 'Not set',
    });

    final additionalDetails = !isAwayGame
        ? {
            'Officials Required': (args['officialsRequired'] ?? 0).toString(),
            'Fee per Official':
                args['gameFee'] != null ? '\$${args['gameFee']}' : 'Not set',
            'Gender': args['gender'] != null
                ? ((args['levelOfCompetition'] as String?)?.toLowerCase() ==
                            'college' ||
                        (args['levelOfCompetition'] as String?)
                                ?.toLowerCase() ==
                            'adult'
                    ? {
                          'boys': 'Men',
                          'girls': 'Women',
                          'co-ed': 'Co-ed'
                        }[(args['gender'] as String).toLowerCase()] ??
                        'Not set'
                    : args['gender'] as String)
                : 'Not set',
            'Competition Level':
                args['levelOfCompetition'] as String? ?? 'Not set',
            'Hire Automatically':
                args['hireAutomatically'] == true ? 'Yes' : 'No',
          }
        : {};

    final allDetails = {
      ...gameDetails,
      if (!isAwayGame) ...additionalDetails,
    };

    final isPublished = args['status'] == 'Published';

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
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
            onPressed: () async {
              if (await _onWillPop() && mounted) {
                // ignore: use_build_context_synchronously
                Navigator.pop(context);
              }
            },
          ),
        ),
        body: CustomScrollView(
          slivers: [
            SliverPersistentHeader(
              pinned: true,
              delegate: _SliverHeaderDelegate(
                child: Container(
                  color: darkSurface,
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Game Details',
                          style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: efficialsYellow)),
                      TextButton(
                        onPressed: () => Navigator.pushNamed(
                            context, '/edit_game_info',
                            arguments: {
                              ...args,
                              'isEdit': true,
                              'isFromGameInfo': isFromGameInfo,
                              'fromScheduleDetails': fromScheduleDetails,
                              'scheduleId': scheduleId,
                            }).then((result) {
                          if (result != null &&
                              result is Map<String, dynamic>) {
                            setState(() {
                              args = result;
                              fromScheduleDetails =
                                  result['fromScheduleDetails'] == true;
                              scheduleId = result['scheduleId'] as int?;
                            });
                          }
                        }),
                        child: const Text('Edit',
                            style: TextStyle(
                                color: efficialsYellow, fontSize: 18)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ...allDetails.entries.map(
                        (e) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                width: 150,
                                child: Text('${e.key}:',
                                    style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.white)),
                              ),
                              Expanded(
                                  child: Text(e.value,
                                      style: const TextStyle(
                                          fontSize: 16, color: Colors.white))),
                            ],
                          ),
                        ),
                      ),
                      // Only show Selected Officials section for non-away games
                      if (!isAwayGame) ...[
                        const SizedBox(height: 20),
                        const Text('Selected Officials',
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: efficialsYellow)),
                        const SizedBox(height: 10),
                        if (args['method'] == 'hire_crew' && 
                            (args['selectedCrews'] != null || args['selectedCrew'] != null)) ...[
                          if (args['selectedCrews'] != null) ...[
                            ...((args['selectedCrews'] as List<dynamic>).map((crewData) {
                              // Handle both Crew objects and Map data
                              final crewName = crewData is Map<String, dynamic> 
                                  ? crewData['name'] as String? ?? 'Unknown Crew'
                                  : (crewData as dynamic).name ?? 'Unknown Crew';
                              final memberCount = crewData is Map<String, dynamic>
                                  ? crewData['memberCount'] as int? ?? 0
                                  : (crewData as dynamic).memberCount as int? ?? 0;
                              
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4),
                                child: Text(
                                  'Crew: $crewName ($memberCount officials)',
                                  style: const TextStyle(
                                      fontSize: 16, color: Colors.white),
                                ),
                              );
                            })),
                          ] else if (args['selectedCrew'] != null) ...[
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Text(
                                'Crew: ${(args['selectedCrew'] as dynamic).name} (${(args['selectedCrew'] as dynamic).memberCount ?? 0} officials)',
                                style: const TextStyle(
                                    fontSize: 16, color: Colors.white),
                              ),
                            ),
                          ],
                        ] else if (args['method'] == 'use_list' &&
                            args['selectedListName'] != null) ...[
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Text(
                              'List Used: ${args['selectedListName']}',
                              style: const TextStyle(
                                  fontSize: 16, color: Colors.white),
                            ),
                          ),
                        ] else if (args['selectedOfficials'] == null ||
                            (args['selectedOfficials'] as List).isEmpty)
                          const Text('No officials selected.',
                              style: TextStyle(fontSize: 16, color: Colors.grey))
                        else if (args['method'] == 'advanced' &&
                            args['selectedLists'] != null) ...[
                          ...((args['selectedLists']
                                  as List<Map<String, dynamic>>)
                              .map(
                            (list) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Text(
                                '${list['name']}: Min ${list['minOfficials']}, Max ${list['maxOfficials']}',
                                style: const TextStyle(
                                    fontSize: 16, color: Colors.white),
                              ),
                            ),
                          )),
                        ] else ...[
                          ...((args['selectedOfficials']
                                  as List<Map<String, dynamic>>)
                              .map(
                            (official) => ListTile(
                              title: Text(official['name'] as String,
                                  style: const TextStyle(color: Colors.white)),
                              subtitle: Text(
                                  'Distance: ${(official['distance'] as num?)?.toStringAsFixed(1) ?? '0.0'} mi',
                                  style: const TextStyle(color: Colors.grey)),
                            ),
                          )),
                        ],
                      ],
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        bottomNavigationBar: Container(
          color: efficialsBlack,
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: MediaQuery.of(context).padding.bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isPublished) ...[
                ElevatedButton(
                  onPressed: _publishUpdate,
                  style: elevatedButtonStyle(),
                  child: const Text('Publish Update',
                      style: signInButtonTextStyle),
                ),
              ] else ...[
                ElevatedButton(
                  onPressed: _isPublishing ? null : _publishGame,
                  style: elevatedButtonStyle(),
                  child: _showButtonLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text('Publish Game',
                          style: signInButtonTextStyle),
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: _isPublishing ? null : _publishLater,
                  style: elevatedButtonStyle(),
                  child: _showButtonLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text('Publish Later',
                          style: signInButtonTextStyle),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _SliverHeaderDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;

  _SliverHeaderDelegate({required this.child});

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return child;
  }

  @override
  double get maxExtent => 80;

  @override
  double get minExtent => 80;

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) =>
      true;
}
