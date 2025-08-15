import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../shared/theme.dart';
import '../../shared/services/repositories/game_assignment_repository.dart';
import '../../shared/services/repositories/notification_repository.dart';
import '../../shared/services/repositories/list_repository.dart';
import '../../shared/services/game_service.dart';
import '../../shared/services/user_session_service.dart';

class GameInformationScreen extends StatefulWidget {
  const GameInformationScreen({super.key});

  @override
  State<GameInformationScreen> createState() => _GameInformationScreenState();
}

class _GameInformationScreenState extends State<GameInformationScreen> {
  late Map<String, dynamic> args;
  late String sport;
  late String scheduleName;
  late String location;
  late DateTime? selectedDate;
  late TimeOfDay? selectedTime;
  late String levelOfCompetition;
  late String gender;
  late int? officialsRequired;
  late String gameFee;
  late bool hireAutomatically;
  late List<Map<String, dynamic>> selectedOfficials;
  late List<Map<String, dynamic>> selectedLists;
  late bool isAwayGame;
  late String opponent;
  late int officialsHired;
  List<Map<String, dynamic>> interestedOfficials = [];
  List<Map<String, dynamic>> interestedCrews = [];
  List<Map<String, dynamic>> confirmedOfficialsFromDB = [];
  List<Map<String, dynamic>> dismissedOfficials = [];
  Map<int, bool> selectedForHire = {};
  Map<int, bool> selectedCrewsForHire = {};
  bool isGameLinked = false;
  List<Map<String, dynamic>> linkedGames = [];

  // Repository for fetching real interested officials data
  final GameAssignmentRepository _gameAssignmentRepo =
      GameAssignmentRepository();

  // Repository for notifications
  final NotificationRepository _notificationRepo = NotificationRepository();

  // Service for database game operations
  final GameService _gameService = GameService();

  // Repository for list operations
  final ListRepository _listRepository = ListRepository();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final newArgs =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;

    debugPrint('GAME INFO SCREEN: Received arguments: ${newArgs.keys.toList()}');
    debugPrint('GAME INFO SCREEN: scheduleId=${newArgs['scheduleId']}, scheduleName=${newArgs['scheduleName']}');

    // Always try to reload database games to get fresh data
    final gameId = newArgs['id'];
    if (gameId != null && _isDatabaseGame(gameId)) {
      _reloadGameDataFromDatabase(newArgs);
    } else {
      _initializeFromArguments(newArgs);
    }
  }

  bool _isDatabaseGame(dynamic gameId) {
    int? databaseGameId;
    if (gameId is int) {
      databaseGameId = gameId;
    } else if (gameId is String) {
      databaseGameId = int.tryParse(gameId);
    }
    return databaseGameId != null && databaseGameId < 1000000000000;
  }

  void _initializeFromArguments(Map<String, dynamic> newArgs) {
    setState(() {
      args = Map<String, dynamic>.from(newArgs);

      sport =
          args['sport'] as String? ?? args['sportName'] as String? ?? 'Unknown';
      scheduleName = args['scheduleName'] as String? ?? 'Unnamed';
      location = args['location'] as String? ?? 'Not set';
      selectedDate = args['date'] != null
          ? (args['date'] is String
              ? DateTime.parse(args['date'] as String)
              : args['date'] as DateTime)
          : null;
      selectedTime = args['time'] != null
          ? (args['time'] is String
              ? () {
                  final timeParts = (args['time'] as String).split(':');
                  return TimeOfDay(
                    hour: int.parse(timeParts[0]),
                    minute: int.parse(timeParts[1]),
                  );
                }()
              : args['time'] as TimeOfDay)
          : null;
      levelOfCompetition = args['levelOfCompetition'] as String? ?? 'Not set';
      gender = args['gender'] as String? ?? 'Not set';
      officialsRequired = args['officialsRequired'] != null
          ? int.tryParse(args['officialsRequired'].toString())
          : null;
      gameFee = args['gameFee']?.toString() ?? 'Not set';
      hireAutomatically = args['hireAutomatically'] as bool? ?? false;
      isAwayGame = args['isAwayGame'] as bool? ?? args['isAway'] as bool? ?? false;
      opponent = args['opponent'] as String? ?? 'Not set';
      officialsHired = args['officialsHired'] as int? ?? 0;
      try {
        final officialsRaw = args['selectedOfficials'] as List<dynamic>? ?? [];
        selectedOfficials = officialsRaw.map((official) {
          if (official is Map) {
            return Map<String, dynamic>.from(official);
          }
          return <String, dynamic>{'name': 'Unknown Official', 'distance': 0.0};
        }).toList();
      } catch (e) {
        selectedOfficials = [];
      }
      try {
        final listsRaw = args['selectedLists'] as List<dynamic>? ?? [];
        selectedLists = listsRaw.map((list) {
          if (list is Map) {
            final processedList = Map<String, dynamic>.from(list);
            return processedList;
          }
          return <String, dynamic>{
            'name': 'Unknown List',
            'minOfficials': 0,
            'maxOfficials': 0,
            'officials': <Map<String, dynamic>>[],
          };
        }).toList();
      } catch (e) {
        selectedLists = [];
      }
      // Load real interested officials from database
      _loadInterestedOfficials();
    });
  }

  Future<void> _reloadGameDataFromDatabase(Map<String, dynamic> newArgs) async {
    final gameId = newArgs['id'];
    if (gameId == null || !_isDatabaseGame(gameId)) {
      _initializeFromArguments(newArgs);
      return;
    }

    try {
      int databaseGameId;
      if (gameId is int) {
        databaseGameId = gameId;
      } else {
        databaseGameId = int.parse(gameId as String);
      }

      // Load fresh data from database with officials data
      final gameData =
          await _gameService.getGameByIdWithOfficials(databaseGameId);
      if (gameData != null) {
        // Merge the fresh database data with the navigation args
        final updatedArgs = {
          ...newArgs,
          ...gameData,
          // Preserve navigation-specific args
          'sourceScreen': newArgs['sourceScreen'],
          // Use fresh database data for schedule name and ID (prioritize database over navigation args)
          'scheduleName': gameData['scheduleName'] ?? newArgs['scheduleName'],
          'scheduleId': gameData['scheduleId'] ?? newArgs['scheduleId'],
        };
        _initializeFromArguments(updatedArgs);
        // Check if this game is linked to others
        _checkGameLinkStatus(databaseGameId);
      } else {
        _initializeFromArguments(newArgs);
      }
    } catch (e) {
      _initializeFromArguments(newArgs);
    }
  }

  // Check if the current game is linked to others
  Future<void> _checkGameLinkStatus(int gameId) async {
    try {
      final isLinked = await _gameService.isGameLinked(gameId);
      final linkedGamesList = await _gameService.getLinkedGames(gameId);
      
      if (mounted) {
        setState(() {
          isGameLinked = isLinked;
          linkedGames = linkedGamesList;
        });
      }
    } catch (e) {
    }
  }

  @override
  void initState() {
    super.initState();
    args = {};
    sport = 'Unknown';
    scheduleName = 'Unnamed';
    location = 'Not set';
    selectedDate = null;
    selectedTime = null;
    levelOfCompetition = 'Not set';
    gender = 'Not set';
    officialsRequired = null;
    gameFee = 'Not set';
    hireAutomatically = false;
    selectedOfficials = [];
    selectedLists = [];
    isAwayGame = false;
    opponent = 'Not set';
    officialsHired = 0;
  }

  // Load real interested officials and crews from database
  Future<void> _loadInterestedOfficials() async {
    final gameId = args['id'];
    if (gameId == null) return;

    try {
      // Check if this is a database game (integer ID) or SharedPreferences game (timestamp ID)
      // Database IDs are typically small integers (1, 2, 3...)
      // SharedPreferences IDs are large timestamps (1721664123456...)
      int? databaseGameId;

      if (gameId is int) {
        databaseGameId = gameId;
      } else if (gameId is String) {
        databaseGameId = int.tryParse(gameId);
      }

      // Only try to load from database if this looks like a database game ID
      // (small integer, not a large timestamp)
      if (databaseGameId != null && databaseGameId < 1000000000000) {
        final interestedOfficials = await _gameAssignmentRepo
            .getInterestedOfficialsForGame(databaseGameId);
        final interestedCrews =
            await _gameAssignmentRepo.getInterestedCrewsForGame(databaseGameId);
        final confirmedOfficials = await _gameAssignmentRepo
            .getConfirmedOfficialsForGame(databaseGameId);
        final dismissedOfficials =
            await _gameAssignmentRepo.getGameDismissals(databaseGameId);

        setState(() {
          // Create mutable copies of the query results
          this.interestedOfficials =
              List<Map<String, dynamic>>.from(interestedOfficials);
          this.interestedCrews =
              List<Map<String, dynamic>>.from(interestedCrews);
          confirmedOfficialsFromDB =
              List<Map<String, dynamic>>.from(confirmedOfficials);
          this.dismissedOfficials =
              List<Map<String, dynamic>>.from(dismissedOfficials);
          selectedForHire = {};
          selectedCrewsForHire = {};
          for (var official in this.interestedOfficials) {
            selectedForHire[official['id'] as int] = false;
          }
          for (var crew in this.interestedCrews) {
            selectedCrewsForHire[crew['crew_assignment_id'] as int] = false;
          }
        });
      } else {
        // For SharedPreferences games, interested officials feature is not supported
        // as they use a different storage system
        setState(() {
          interestedOfficials = [];
          interestedCrews = [];
          dismissedOfficials = [];
          selectedForHire = {};
          selectedCrewsForHire = {};
        });
      }
    } catch (e) {
      setState(() {
        interestedOfficials = [];
        interestedCrews = [];
        dismissedOfficials = [];
        selectedForHire = {};
        selectedCrewsForHire = {};
      });
    }
  }

  Future<void> _deleteGame() async {
    final gameId = args['id'];
    if (gameId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: Game ID not found')),
      );
      return;
    }

    try {
      // Check if this is a database game (integer ID) or SharedPreferences game (timestamp ID)
      int? databaseGameId;

      if (gameId is int) {
        databaseGameId = gameId;
      } else if (gameId is String) {
        databaseGameId = int.tryParse(gameId);
      }

      // For database games, use the GameService
      if (databaseGameId != null && databaseGameId < 1000000000000) {
        final success = await _gameService.deleteGame(databaseGameId);

        if (success) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Game deleted successfully'),
                backgroundColor: Colors.green,
              ),
            );
            Navigator.pop(context, true);
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Failed to delete game'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } else {
        // For SharedPreferences games, use the legacy approach
        await _deleteSharedPreferencesGame(gameId);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error deleting game'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Legacy method for SharedPreferences games (to be phased out)
  Future<void> _deleteSharedPreferencesGame(dynamic gameId) async {
    final prefs = await SharedPreferences.getInstance();

    // Determine which storage key to use based on user role
    final schedulerType = prefs.getString('schedulerType');
    String publishedGamesKey;

    switch (schedulerType?.toLowerCase()) {
      case 'coach':
        publishedGamesKey = 'coach_published_games';
        break;
      case 'assigner':
        publishedGamesKey = 'assigner_published_games';
        break;
      case 'athletic director':
      case 'athleticdirector':
      case 'ad':
      default:
        publishedGamesKey = 'ad_published_games';
        break;
    }

    final String? gamesJson = prefs.getString(publishedGamesKey);
    if (gamesJson != null && gamesJson.isNotEmpty) {
      try {
        List<Map<String, dynamic>> publishedGames =
            List<Map<String, dynamic>>.from(jsonDecode(gamesJson));
        final initialCount = publishedGames.length;
        publishedGames.removeWhere((game) => game['id'] == gameId);
        final finalCount = publishedGames.length;

        await prefs.setString(publishedGamesKey, jsonEncode(publishedGames));

        if (initialCount > finalCount) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Legacy game deleted successfully'),
                backgroundColor: Colors.green,
              ),
            );
            Navigator.pop(context, true);
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Game not found in storage')),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Error deleting legacy game')),
          );
        }
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No games found in storage')),
        );
      }
    }
  }

  Future<void> _createTemplateFromGame() async {
    // Navigate to the create game template screen with the game data pre-filled
    final result = await Navigator.pushNamed(
      context,
      '/create_game_template',
      arguments: {
        'scheduleName': scheduleName,
        'sport': sport,
        'time': selectedTime, // TimeOfDay object
        'location': location,
        'locationData': args['locationData'], // Location details if available
        'levelOfCompetition': levelOfCompetition,
        'gender': gender,
        'officialsRequired': officialsRequired,
        'gameFee': gameFee != 'Not set' ? gameFee : null,
        'hireAutomatically': hireAutomatically,
        'selectedListName': args['selectedListName'] as String?,
        'method': args['method'] as String?,
        'isAway': isAwayGame,
      },
    );

    if (result != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Game template created successfully!')),
      );
    }
  }

  Future<void> _confirmHires() async {
    final selectedCount = selectedForHire.values.where((v) => v).length;
    final selectedCrewCount =
        selectedCrewsForHire.values.where((v) => v).length;

    if (selectedCount == 0 && selectedCrewCount == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content:
                Text('Please select at least one official or crew to confirm')),
      );
      return;
    }

    // Handle crew hires first
    if (selectedCrewCount > 0) {
      await _confirmCrewHires();
    }

    // Handle individual official hires (if any)
    if (selectedCount == 0) return;

    final newTotalHired = officialsHired + selectedCount;
    if (newTotalHired > (officialsRequired ?? 0)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text('Cannot hire more than $officialsRequired officials')),
      );
      return;
    }

    if (args['method'] == 'advanced' && args['selectedLists'] != null) {
      final listCounts = <String, int>{};
      final selectedIds = selectedForHire.entries
          .where((e) => e.value)
          .map((e) => e.key)
          .toList();
      final hiredOfficials = interestedOfficials
          .where((o) => selectedIds.contains(o['id']))
          .toList();

      final prefs = await SharedPreferences.getInstance();
      final String? listsJson = prefs.getString('saved_lists');
      final List<Map<String, dynamic>> savedListsRaw =
          listsJson != null && listsJson.isNotEmpty
              ? List<Map<String, dynamic>>.from(jsonDecode(listsJson))
              : [];
      final Map<String, List<Map<String, dynamic>>> savedLists = {
        for (var list in savedListsRaw)
          list['name'] as String:
              List<Map<String, dynamic>>.from(list['officials'] ?? [])
      };

      for (var official in hiredOfficials) {
        final listName = (args['selectedLists'] as List<dynamic>)
            .map((list) => Map<String, dynamic>.from(list as Map))
            .firstWhere(
              (list) => (savedLists[list['name']] ?? [])
                  .any((o) => o['id'] == official['id']),
              orElse: () => {'name': 'Unknown'},
            )['name'];
        listCounts[listName] = (listCounts[listName] ?? 0) + 1;
      }

      for (var official in selectedOfficials) {
        final listName = (args['selectedLists'] as List<dynamic>)
            .map((list) => Map<String, dynamic>.from(list as Map))
            .firstWhere(
              (list) => (savedLists[list['name']] ?? [])
                  .any((o) => o['id'] == official['id']),
              orElse: () => {'name': 'Unknown'},
            )['name'];
        listCounts[listName] = (listCounts[listName] ?? 0) + 1;
      }

      for (var list in (args['selectedLists'] as List<dynamic>)
          .map((list) => Map<String, dynamic>.from(list as Map))) {
        final count = listCounts[list['name']] ?? 0;
        if (count > list['maxOfficials']) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text(
                      'Cannot exceed max (${list['maxOfficials']}) for ${list['name']}')),
            );
          }
          return;
        }
      }
    }

    final hiredIds = selectedForHire.entries
        .where((e) => e.value)
        .map((e) => e.key)
        .toList();
    final hiredOfficials =
        interestedOfficials.where((o) => hiredIds.contains(o['id'])).toList();

    setState(() {
      officialsHired += selectedCount;
      args['officialsHired'] = officialsHired;
      selectedOfficials.addAll(hiredOfficials);
      // Create a new mutable list instead of modifying the read-only query result
      interestedOfficials = interestedOfficials
          .where((o) => !hiredIds.contains(o['id']))
          .toList();
      selectedForHire.clear();
    });

    try {
      final gameId = args['id'];

      // Check if this is a database game (integer ID) or SharedPreferences game (timestamp ID)
      int? databaseGameId;

      if (gameId is int) {
        databaseGameId = gameId;
      } else if (gameId is String) {
        databaseGameId = int.tryParse(gameId);
      }

      // For database games, use the GameService
      if (databaseGameId != null && databaseGameId < 1000000000000) {
        // Update the officials hired count in database
        final updateResult = await _gameService.updateOfficialsHired(
            databaseGameId, officialsHired);

        // Update GameAssignment status from 'pending' to 'accepted' for hired officials
        for (final officialId in hiredIds) {
          try {
            final assignmentId =
                await _getAssignmentId(databaseGameId, officialId);
            if (assignmentId > 0) {
              await _gameAssignmentRepo.updateAssignmentStatus(
                  assignmentId, 'accepted');
            } else {}
          } catch (e) {
          }
        }

        if (updateResult) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Officials hired successfully!'),
                backgroundColor: Colors.green,
              ),
            );
            // Reload the officials data to show the updated state
            _loadInterestedOfficials();
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Failed to update game'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } else {
        // For SharedPreferences games, use the legacy approach
        await _updateSharedPreferencesGame();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error updating game'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Legacy method for SharedPreferences games (to be phased out)
  Future<void> _updateSharedPreferencesGame() async {
    final prefs = await SharedPreferences.getInstance();

    // Determine which storage key to use based on user role
    final schedulerType = prefs.getString('schedulerType');
    String publishedGamesKey;

    switch (schedulerType?.toLowerCase()) {
      case 'coach':
        publishedGamesKey = 'coach_published_games';
        break;
      case 'assigner':
        publishedGamesKey = 'assigner_published_games';
        break;
      case 'athletic director':
      case 'athleticdirector':
      case 'ad':
      default:
        publishedGamesKey = 'ad_published_games';
        break;
    }

    final String? gamesJson = prefs.getString(publishedGamesKey);
    if (gamesJson != null && gamesJson.isNotEmpty) {
      List<Map<String, dynamic>> publishedGames =
          List<Map<String, dynamic>>.from(jsonDecode(gamesJson));
      final index = publishedGames.indexWhere((g) => g['id'] == args['id']);
      if (index != -1) {
        publishedGames[index] = {
          ...publishedGames[index],
          'officialsHired': officialsHired,
          'selectedOfficials': selectedOfficials,
        };
        await prefs.setString(publishedGamesKey, jsonEncode(publishedGames));
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Legacy game updated successfully!')),
          );
        }
      }
    }
  }

  Future<int> _getAssignmentId(int gameId, int officialId) async {
    final assignment = await _gameAssignmentRepo.getAssignmentByGameAndOfficial(
        gameId, officialId);
    return assignment?.id ?? 0;
  }

  Future<void> _confirmCrewHires() async {
    try {
      final selectedCrewAssignmentIds = selectedCrewsForHire.entries
          .where((e) => e.value)
          .map((e) => e.key)
          .toList();

      // Get current user ID to use as scheduler ID
      final currentUserId =
          await UserSessionService.instance.getCurrentUserId();

      if (currentUserId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Error: Unable to identify current user')),
        );
        return;
      }

      // Confirm each selected crew
      bool allSuccessful = true;
      for (final crewAssignmentId in selectedCrewAssignmentIds) {
        final success = await _gameAssignmentRepo.confirmCrewHire(
            crewAssignmentId, currentUserId);
        if (!success) {
          allSuccessful = false;
          break;
        }
      }

      if (allSuccessful) {
        setState(() {
          // Remove confirmed crews from interested list
          interestedCrews.removeWhere((crew) =>
              selectedCrewAssignmentIds.contains(crew['crew_assignment_id']));
          selectedCrewsForHire.clear();
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                '${selectedCrewAssignmentIds.length} crew${selectedCrewAssignmentIds.length == 1 ? '' : 's'} hired successfully!'),
            backgroundColor: Colors.green,
          ),
        );

        // Reload the officials data to show the updated state
        _loadInterestedOfficials();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to hire some crews'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error confirming crew hires'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _navigateToOfficialProfile(String officialName) async {
    try {
      // Find the official ID by name from either selectedOfficials or confirmedOfficialsFromDB
      int? officialId;

      // Check selectedOfficials first
      for (var official in selectedOfficials) {
        if (official['name'] == officialName) {
          officialId = official['id'] as int?;
          break;
        }
      }

      // If not found, check confirmedOfficialsFromDB
      if (officialId == null) {
        for (var official in confirmedOfficialsFromDB) {
          if (official['name'] == officialName) {
            officialId = official['id'] as int?;
            break;
          }
        }
      }

      // If still not found, check interestedOfficials
      if (officialId == null) {
        for (var official in interestedOfficials) {
          if (official['name'] == officialName) {
            officialId = official['id'] as int?;
            break;
          }
        }
      }

      if (officialId != null) {
        // Get official data from repository including follow through rate
        final officialRepo = _gameAssignmentRepo;
        final officialData = await officialRepo.rawQuery('''
          SELECT o.*, 
                 COALESCE(o.follow_through_rate, 100.0) as followThroughRate,
                 o.total_accepted_games,
                 o.total_backed_out_games,
                 o.experience_years as experienceYears,
                 o.phone,
                 o.email,
                 o.city,
                 o.state,
                 1 as showCareerStats
          FROM officials o 
          WHERE o.id = ?
        ''', [officialId]);

        if (officialData.isNotEmpty && mounted) {
          final official = officialData.first;

          // Create profile data compatible with OfficialProfileScreen
          final city = official['city'] as String?;
          final state = official['state'] as String?;
          String location = 'N/A';
          if (city != null && state != null) {
            location = '$city, $state';
          } else if (city != null) {
            location = city;
          } else if (state != null) {
            location = state;
          }

          final profileData = {
            'id': official['id'],
            'name': official['name'],
            'email': official['email'] ?? 'N/A',
            'phone': official['phone'] ?? 'N/A',
            'location': location,
            'experienceYears': official['experienceYears'] ?? 0,
            'primarySport': 'N/A', // Would need to query from official_sports
            'certificationLevel': official['certification_level'] ?? 'N/A',
            'ratePerGame': 0.0, // Not available in current schema
            'maxTravelDistance': 0, // Not available in current schema
            'joinedDate': DateTime.now(), // Would use created_at if available
            'totalGames': official['total_accepted_games'] ?? 0,
            'schedulerEndorsements': 0, // Not implemented yet
            'officialEndorsements': 0, // Not implemented yet
            'profileVerified': false,
            'emailVerified': false,
            'phoneVerified': false,
            'showCareerStats': true, // Always show for scheduler view
            'followThroughRate': official['followThroughRate'] ?? 100.0,
          };

          Navigator.pushNamed(
            context,
            '/official_profile',
            arguments: profileData,
          );
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Official profile not found')),
            );
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Official ID not found')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error loading official profile')),
        );
      }
    }
  }

  void _showCrewMembers(String crewName, int crewId) async {
    try {
      final crewMembers =
          await _gameAssignmentRepo.getCrewMembersForDisplay(crewId);

      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: darkSurface,
            title: Text(
              'Members of "$crewName"',
              style: const TextStyle(
                  color: efficialsYellow,
                  fontSize: 18,
                  fontWeight: FontWeight.bold),
            ),
            content: SizedBox(
              width: double.maxFinite,
              height: 300,
              child: crewMembers.isEmpty
                  ? const Text('No members found.',
                      style: TextStyle(color: Colors.white))
                  : ListView.builder(
                      itemCount: crewMembers.length,
                      itemBuilder: (context, index) {
                        final member = crewMembers[index];
                        final officialName =
                            member['name'] as String? ?? 'Unknown Official';
                        final position =
                            member['position'] as String? ?? 'member';
                        final isCrewChief = position == 'crew_chief';

                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              Icon(
                                isCrewChief ? Icons.star : Icons.person,
                                color: isCrewChief
                                    ? efficialsYellow
                                    : Colors.grey[400],
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  officialName,
                                  style: TextStyle(
                                    color: isCrewChief
                                        ? efficialsYellow
                                        : Colors.white,
                                    fontSize: 16,
                                    fontWeight: isCrewChief
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                ),
                              ),
                              if (isCrewChief)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: efficialsYellow.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Text(
                                    'CHIEF',
                                    style: TextStyle(
                                      color: efficialsYellow,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close',
                    style: TextStyle(color: efficialsYellow)),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error loading crew members')),
        );
      }
    }
  }

  void _showListOfficials(String listName) async {
    try {
      final userId = await UserSessionService.instance.getCurrentUserId();
      if (userId == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Error: User not found')),
          );
        }
        return;
      }

      // Get all lists from database
      final userLists = await _listRepository.getLists(userId);
      debugPrint('DEBUG GAME INFO: Found ${userLists.length} lists from database');
      
      // Find the specific list
      final listData = userLists.firstWhere(
        (list) => list['name'] == listName,
        orElse: () => <String, dynamic>{},
      );

      // Get the full original list of officials
      final fullOfficialsList = List<Map<String, dynamic>>.from(listData['officials'] ?? []);
      debugPrint('DEBUG GAME INFO: List "$listName" has ${fullOfficialsList.length} officials');

      // Get the game-specific officials for this list (the ones actually selected for this game)
      List<Map<String, dynamic>> gameSpecificOfficials = [];

      if (args['method'] == 'advanced' && selectedLists.isNotEmpty) {
        // For advanced method, get officials from the specific list in selectedLists

        final gameList = selectedLists.firstWhere(
          (list) => list['name'] == listName,
          orElse: () => <String, dynamic>{},
        );

        gameSpecificOfficials =
            List<Map<String, dynamic>>.from(gameList['officials'] ?? []);
      } else if (args['method'] == 'use_list' &&
          args['selectedListName'] == listName) {
        // For use_list method, all selected officials are from this list
        gameSpecificOfficials = selectedOfficials;
      }

      // Get the names of officials actually selected for this game
      final gameOfficialNames =
          gameSpecificOfficials.map((o) => o['name'] as String?).toSet();

      // Get the names of officials who dismissed this game
      final dismissedOfficialNames =
          dismissedOfficials.map((d) => d['official_name'] as String?).toSet();

      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: darkSurface,
            title: Text(
              'Officials in "$listName"',
              style: const TextStyle(
                  color: efficialsYellow,
                  fontSize: 18,
                  fontWeight: FontWeight.bold),
            ),
            content: SizedBox(
              width: double.maxFinite,
              height: 400,
              child: fullOfficialsList.isEmpty
                  ? const Text('No officials in this list.',
                      style: TextStyle(color: Colors.white))
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: ListView.builder(
                            itemCount: fullOfficialsList.length,
                            itemBuilder: (context, index) {
                              final official = fullOfficialsList[index];
                              final officialName =
                                  official['name'] as String? ??
                                      'Unknown Official';
                              final isSelectedForGame =
                                  gameOfficialNames.contains(officialName);
                              final isDismissed =
                                  dismissedOfficialNames.contains(officialName);

                              // Determine display style based on status
                              Color textColor;
                              TextDecoration decoration;
                              Color? decorationColor;

                              if (isDismissed) {
                                // Dismissed officials: red with strikethrough
                                textColor = Colors.red;
                                decoration = TextDecoration.lineThrough;
                                decorationColor = Colors.red;
                              } else if (isSelectedForGame) {
                                // Selected officials: white text
                                textColor = Colors.white;
                                decoration = TextDecoration.none;
                                decorationColor = null;
                              } else {
                                // Other officials: grey text
                                textColor = Colors.grey;
                                decoration = TextDecoration.none;
                                decorationColor = null;
                              }

                              return Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 4),
                                child: Text(
                                  '• $officialName (${official['distance']?.toStringAsFixed(1) ?? '0.0'} mi)',
                                  style: TextStyle(
                                    color: textColor,
                                    fontSize: 16,
                                    decoration: decoration,
                                    decorationColor: decorationColor,
                                    decorationThickness: 2.0,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        // Add legend if there are dismissed officials
                        if (dismissedOfficials.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          const Divider(color: Colors.grey),
                          const SizedBox(height: 8),
                          Text(
                            'Names with red strikethrough have dismissed this game',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[500],
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ],
                    ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close',
                    style: TextStyle(color: efficialsYellow)),
              ),
            ],
          ),
        );
      }
    } catch (e) {
    }
  }

  Widget _buildSelectedOfficialsSection() {
    if (isAwayGame) {
      return const Text('No officials needed for away games.',
          style: TextStyle(fontSize: 16, color: Colors.grey));
    }

    // For hire_crew games, show selected crews
    if (args['method'] == 'hire_crew') {
      final selectedCrews = args['selectedCrews'] as List<dynamic>? ?? [];
      if (selectedCrews.isNotEmpty) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: selectedCrews.map((crew) {
            final crewName = crew['name'] ?? 'Unknown Crew';
            final crewChiefName = crew['crewChiefName'] ?? 'Unknown Chief';
            final memberCount = crew['members']?.length ?? 0;

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text(
                '• $crewName (Chief: $crewChiefName, $memberCount officials)',
                style: const TextStyle(fontSize: 16, color: Colors.white),
              ),
            );
          }).toList(),
        );
      } else {
        return const Text('No crews selected.',
            style: TextStyle(fontSize: 16, color: Colors.grey));
      }
    }

    // For list-based selection methods, show clickable list names
    if (args['method'] == 'use_list' && args['selectedListName'] != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: GestureDetector(
          onTap: () => _showListOfficials(args['selectedListName']),
          child: Text(
            'List Used: ${args['selectedListName']}',
            style: const TextStyle(
              fontSize: 16,
              color: efficialsYellow,
              decoration: TextDecoration.underline,
              decorationColor: efficialsYellow,
            ),
          ),
        ),
      );
    }

    if (args['method'] == 'advanced' && selectedLists.isNotEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: selectedLists
            .map((list) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: GestureDetector(
                    onTap: () => _showListOfficials(list['name']),
                    child: Text(
                      '${list['name']} (${list['maxOfficials']} max, ${list['minOfficials']} min)',
                      style: const TextStyle(
                        fontSize: 16,
                        color: efficialsYellow,
                        decoration: TextDecoration.underline,
                        decorationColor: efficialsYellow,
                      ),
                    ),
                  ),
                ))
            .toList(),
      );
    }

    // For manual selection, show individual officials
    if (selectedOfficials.isNotEmpty || dismissedOfficials.isNotEmpty) {
      final allOfficials = <Widget>[];

      // Add selected officials
      for (final official in selectedOfficials) {
        allOfficials.add(
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Text(
              '• ${official['name']} (${(official['distance'] as num?)?.toStringAsFixed(1) ?? '0.0'} mi)',
              style: const TextStyle(fontSize: 16, color: Colors.white),
            ),
          ),
        );
      }

      // Add dismissed officials with strikethrough
      for (final dismissal in dismissedOfficials) {
        final officialName = dismissal['official_name'] as String? ?? 'Unknown';
        allOfficials.add(
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Text(
              '• $officialName',
              style: const TextStyle(
                fontSize: 16,
                color: Colors.red,
                decoration: TextDecoration.lineThrough,
                decorationColor: Colors.red,
                decorationThickness: 2,
              ),
            ),
          ),
        );
      }

      // Add legend if there are dismissed officials
      if (dismissedOfficials.isNotEmpty) {
        allOfficials.add(
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(
              '• Names with strikethrough have dismissed this game',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[500],
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        );
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: allOfficials,
      );
    }

    return const Text('No officials selected.',
        style: TextStyle(fontSize: 16, color: Colors.grey));
  }

  void _showDeleteConfirmationDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: darkSurface,
        title: const Text('Confirm Delete',
            style: TextStyle(
                color: efficialsYellow,
                fontSize: 20,
                fontWeight: FontWeight.bold)),
        content: const Text('Are you sure you want to delete this game?',
            style: TextStyle(color: Colors.white)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child:
                const Text('Cancel', style: TextStyle(color: efficialsYellow)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteGame();
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showRemoveOfficialDialog(String officialName, int officialId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: darkSurface,
        title: const Text('Remove Official',
            style: TextStyle(
                color: efficialsYellow,
                fontSize: 20,
                fontWeight: FontWeight.bold)),
        content: Text(
            'Are you sure you want to remove $officialName from this game?',
            style: const TextStyle(color: Colors.white)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child:
                const Text('Cancel', style: TextStyle(color: efficialsYellow)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _removeOfficialFromGame(officialId, officialName);
            },
            child: const Text('Remove', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _showLinkGamesDialog() async {
    final gameId = args['id'];
    if (gameId == null || !_isDatabaseGame(gameId)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Game linking is not available for legacy games'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      final eligibleGames = await _gameService.getEligibleGamesForLinking(gameId);
      final isCurrentlyLinked = await _gameService.isGameLinked(gameId);
      
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => _LinkGamesDialog(
            currentGameId: gameId,
            eligibleGames: eligibleGames,
            isCurrentlyLinked: isCurrentlyLinked,
            gameService: _gameService,
            onLinkCreated: () {
              // Refresh the screen to show linked status
              final gameId = args['id'];
              if (gameId != null) {
                _checkGameLinkStatus(gameId);
              }
            },
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading linkable games: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _removeOfficialFromGame(
      int officialId, String officialName) async {
    final gameId = args['id'];
    if (gameId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: Game ID not found')),
      );
      return;
    }

    try {
      // Check if this is a database game
      int? databaseGameId;
      if (gameId is int) {
        databaseGameId = gameId;
      } else if (gameId is String) {
        databaseGameId = int.tryParse(gameId);
      }

      if (databaseGameId != null && databaseGameId < 1000000000000) {
        // Remove from database
        final success = await _gameService.removeOfficialFromGame(
            databaseGameId, officialId);

        if (success) {
          // Send notification to the official
          try {
            final prefs = await SharedPreferences.getInstance();
            final currentUserName = prefs.getString('user_name') ??
                prefs.getString('first_name') ??
                prefs.getString('schedulerName') ??
                'Scheduler';

            final gameTime = selectedTime != null
                ? '${selectedTime!.hour.toString().padLeft(2, '0')}:${selectedTime!.minute.toString().padLeft(2, '0')}'
                : 'TBD';


            final notificationId =
                await _notificationRepo.createOfficialRemovalNotification(
              officialId: officialId,
              schedulerName: currentUserName,
              gameSport: sport,
              gameOpponent: opponent,
              gameDate: selectedDate ?? DateTime.now(),
              gameTime: gameTime,
              additionalData: {
                'game_id': databaseGameId,
                'schedule_name': scheduleName,
                'location': location,
              },
            );

          } catch (e) {
            // Show error to user for debugging
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                      'Warning: Failed to send notification to official. Error: $e'),
                  backgroundColor: Colors.orange,
                  duration: const Duration(seconds: 5),
                ),
              );
            }
          }

          // Refresh the data to show updated state
          await _loadInterestedOfficials();

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('$officialName has been removed from this game'),
                backgroundColor: Colors.green,
              ),
            );
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Failed to remove official from game'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } else {
        // For SharedPreferences games, show info message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Manual removal is not supported for legacy games'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error removing official from game'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Map<String, int> _getSelectedCounts(
      Map<String, List<Map<String, dynamic>>> savedLists) {
    final listCounts = <String, int>{};
    final selectedIds = selectedForHire.entries
        .where((e) => e.value)
        .map((e) => e.key)
        .toList();
    final selectedOfficials = interestedOfficials
        .where((o) => selectedIds.contains(o['id']))
        .toList();

    for (var official in selectedOfficials) {
      final listName = (args['selectedLists'] as List<dynamic>)
          .map((list) => Map<String, dynamic>.from(list as Map))
          .firstWhere(
            (list) => (savedLists[list['name']] ?? [])
                .any((o) => o['id'] == official['id']),
            orElse: () => {'name': 'Unknown'},
          )['name'];
      listCounts[listName] = (listCounts[listName] ?? 0) + 1;
    }
    return listCounts;
  }

  @override
  Widget build(BuildContext context) {
    final isAdultLevel = levelOfCompetition.toLowerCase() == 'college' ||
        levelOfCompetition.toLowerCase() == 'adult';
    final displayGender = isAdultLevel
        ? {
              'boys': 'Men',
              'girls': 'Women',
              'co-ed': 'Co-ed'
            }[gender.toLowerCase()] ??
            gender
        : gender;

    final gameDetails = <String, String>{
      'Sport': sport,
      'Schedule Name': scheduleName,
      'Date': selectedDate != null
          ? DateFormat('MMMM d, yyyy').format(selectedDate!)
          : 'Not set',
      'Time': selectedTime != null ? selectedTime!.format(context) : 'Not set',
      'Location': location,
      'Opponent': opponent,
    };

    // Only add additional details for non-away games
    if (!isAwayGame) {
      gameDetails.addAll({
        'Officials Required': officialsRequired?.toString() ?? '0',
        'Fee per Official': gameFee != 'Not set' ? '\$$gameFee' : 'Not set',
        'Gender': displayGender,
        'Competition Level': levelOfCompetition,
        'Hire Automatically': hireAutomatically ? 'Yes' : 'No',
      });
    }

    final requiredOfficials = officialsRequired ?? 0;

    // Only show database confirmed officials (actual claims/assignments)
    // Do NOT include selectedOfficials as those are just pre-selected during game creation
    final confirmedOfficials = confirmedOfficialsFromDB
        .map((official) => official['name'] as String)
        .toList();

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
            final returnArgs = {
              ...args,
              'date': selectedDate?.toIso8601String(),
              'time': selectedTime != null
                  ? '${selectedTime!.hour}:${selectedTime!.minute}'
                  : null,
              'officialsRequired': officialsRequired,
              'selectedOfficials': selectedOfficials,
              'selectedLists': selectedLists,
            };
            Navigator.pop(context, returnArgs);
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
                    Row(
                      children: [
                        const Text('Game Details',
                            style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: efficialsYellow)),
                        if (isGameLinked) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: efficialsYellow.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: efficialsYellow, width: 1),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.link, color: efficialsYellow, size: 14),
                                const SizedBox(width: 4),
                                Text(
                                  'Linked (${linkedGames.length + 1})',
                                  style: const TextStyle(
                                    color: efficialsYellow,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          onPressed: _createTemplateFromGame,
                          icon: const Icon(Icons.content_copy, color: efficialsYellow),
                          tooltip: 'Create Template from Game',
                        ),
                        IconButton(
                          onPressed: _showLinkGamesDialog,
                          icon: Icon(
                            isGameLinked ? Icons.link_off : Icons.link, 
                            color: efficialsYellow
                          ),
                          tooltip: isGameLinked ? 'Manage Linked Games' : 'Link Games',
                        ),
                        TextButton(
                          onPressed: () => Navigator.pushNamed(
                            context,
                            '/edit_game_info',
                            arguments: {
                              ...args,
                              'isEdit': true,
                              'isFromGameInfo': true,
                              'sourceScreen': args[
                                  'sourceScreen'], // Pass through source info
                              'scheduleName': args['scheduleName'],
                              'scheduleId': args['scheduleId'],
                            },
                          ).then((result) async {
                            if (result != null &&
                                result is Map<String, dynamic>) {
                              // For database games, reload fresh data from database to ensure 
                              // we have the latest min/max values after Advanced Method Setup changes
                              final gameId = result['id'];
                              if (gameId != null && _isDatabaseGame(gameId)) {
                                await _reloadGameDataFromDatabase(result);
                              } else {
                                // For non-database games, use the returned data directly
                                setState(() {
                                  args = result;
                                  sport = args['sport'] as String? ?? sport;
                                  scheduleName =
                                      args['scheduleName'] as String? ??
                                          scheduleName;
                                  location =
                                      args['location'] as String? ?? location;
                                  selectedDate = args['date'] != null
                                      ? (args['date'] is String
                                          ? DateTime.parse(args['date'] as String)
                                          : args['date'] as DateTime)
                                      : selectedDate;
                                  selectedTime = args['time'] != null
                                      ? (args['time'] is String
                                          ? () {
                                              final timeParts =
                                                  (args['time'] as String)
                                                      .split(':');
                                              return TimeOfDay(
                                                hour: int.parse(timeParts[0]),
                                                minute: int.parse(timeParts[1]),
                                              );
                                            }()
                                          : args['time'] as TimeOfDay)
                                      : selectedTime;
                                  levelOfCompetition =
                                      args['levelOfCompetition'] as String? ??
                                          levelOfCompetition;
                                  gender = args['gender'] as String? ?? gender;
                                  officialsRequired = args['officialsRequired'] !=
                                          null
                                      ? int.tryParse(
                                          args['officialsRequired'].toString())
                                      : officialsRequired;
                                  gameFee =
                                      args['gameFee']?.toString() ?? gameFee;
                                  hireAutomatically =
                                      args['hireAutomatically'] as bool? ??
                                          hireAutomatically;
                                  isAwayGame =
                                      args['isAwayGame'] as bool? ?? args['isAway'] as bool? ?? isAwayGame;
                                  opponent =
                                      args['opponent'] as String? ?? opponent;
                                  officialsHired =
                                      args['officialsHired'] as int? ??
                                          officialsHired;
                                  try {
                                    final officialsRaw = args['selectedOfficials']
                                            as List<dynamic>? ??
                                        [];
                                    selectedOfficials =
                                        officialsRaw.map((official) {
                                      if (official is Map) {
                                        return Map<String, dynamic>.from(
                                            official);
                                      }
                                      return <String, dynamic>{
                                        'name': 'Unknown Official',
                                        'distance': 0.0
                                      };
                                    }).toList();
                                  } catch (e) {
                                    selectedOfficials = [];
                                  }
                                  try {
                                    final listsRaw =
                                        args['selectedLists'] as List<dynamic>? ??
                                            [];
                                    selectedLists = listsRaw.map((list) {
                                      if (list is Map) {
                                        return Map<String, dynamic>.from(list);
                                      }
                                      return <String, dynamic>{
                                        'name': 'Unknown List',
                                        'minOfficials': 0,
                                        'maxOfficials': 0,
                                        'officials': <Map<String, dynamic>>[],
                                      };
                                    }).toList();
                                  } catch (e) {
                                    selectedLists = [];
                                  }
                                  // Load real interested officials from database
                                  _loadInterestedOfficials();
                                });
                              }
                              Navigator.pop(context, result);
                            }
                          }),
                          child: const Text('Edit',
                              style: TextStyle(
                                  color: efficialsYellow, fontSize: 18)),
                        ),
                      ],
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
                    ...gameDetails.entries.map(
                      (e) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              width: 150,
                              child: Text(
                                '${e.key}:',
                                style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white),
                              ),
                            ),
                            Expanded(
                              child: e.key == 'Schedule Name'
                                  ? GestureDetector(
                                      onTap: () async {
                                        final prefs = await SharedPreferences
                                            .getInstance();
                                        final schedulerType =
                                            prefs.getString('schedulerType');

                                        if (!mounted) return;

                                        String route;
                                        Map<String, dynamic> arguments;

                                        switch (schedulerType?.toLowerCase()) {
                                          case 'coach':
                                            route = '/team_schedule';
                                            arguments = {
                                              'teamName': scheduleName,
                                              'focusDate': selectedDate,
                                            };
                                            break;
                                          case 'athletic director':
                                          case 'athleticdirector':
                                          case 'ad':
                                            route = '/schedule_details';
                                            arguments = {
                                              'scheduleName': scheduleName,
                                              'scheduleId': args['scheduleId'],
                                              'focusDate': selectedDate,
                                            };
                                            break;
                                          case 'assigner':
                                          default:
                                            route =
                                                '/assigner_manage_schedules';
                                            arguments = {
                                              'selectedTeam': scheduleName,
                                              'focusDate': selectedDate,
                                            };
                                            break;
                                        }

                                        if (mounted) {
                                          Navigator.pushNamed(
                                            context,
                                            route,
                                            arguments: arguments,
                                          );
                                        }
                                      },
                                      child: Text(
                                        e.value,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          color: efficialsYellow,
                                          decoration: TextDecoration.underline,
                                          decorationColor: efficialsYellow,
                                        ),
                                      ),
                                    )
                                  : Text(
                                      e.value,
                                      style: const TextStyle(
                                          fontSize: 16, color: Colors.white),
                                    ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    if (!isAwayGame) ...[
                      Text(
                        args['method'] == 'hire_crew'
                            ? 'Confirmed Crew (${confirmedOfficialsFromDB.length}/$requiredOfficials)'
                            : 'Confirmed Officials (${confirmedOfficialsFromDB.length}/$requiredOfficials)',
                        style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: efficialsYellow),
                      ),
                      const SizedBox(height: 10),
                      if (confirmedOfficialsFromDB.isEmpty)
                        Text(
                            args['method'] == 'hire_crew'
                                ? 'No crew confirmed.'
                                : 'No officials confirmed.',
                            style: const TextStyle(
                                fontSize: 16, color: Colors.grey))
                      else
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: confirmedOfficialsFromDB.map((official) {
                            final officialName = official['name'] as String;
                            final officialId = official['id'] as int;

                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 2),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () {
                                        _navigateToOfficialProfile(
                                            officialName);
                                      },
                                      child: Text(
                                        officialName,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          color: efficialsYellow,
                                          decoration: TextDecoration.underline,
                                          decorationColor: efficialsYellow,
                                        ),
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: () {
                                      _showRemoveOfficialDialog(
                                          officialName, officialId);
                                    },
                                    icon: const Icon(
                                      Icons.remove_circle_outline,
                                      color: Colors.red,
                                      size: 20,
                                    ),
                                    tooltip: 'Remove from this game',
                                    padding: const EdgeInsets.all(4),
                                    constraints: const BoxConstraints(),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      if (!hireAutomatically &&
                          officialsHired < requiredOfficials) ...[
                        const SizedBox(height: 20),
                        // Show Interested Crews section for hire_crew games, Interested Officials for others
                        if (args['method'] == 'hire_crew') ...[
                          const Text(
                            'Interested Crews',
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: efficialsYellow),
                          ),
                          const SizedBox(height: 10),
                          if (interestedCrews.isEmpty)
                            _buildNoCrewsMessage()
                          else
                            Column(
                              children: interestedCrews.map((crew) {
                                final crewAssignmentId =
                                    crew['crew_assignment_id'] as int;
                                final crewId = crew['crew_id'] as int;
                                final crewName = crew['crew_name'] as String;
                                final memberCount =
                                    crew['member_count'] as int? ?? 0;
                                final requiredOfficials =
                                    crew['required_officials'] as int? ?? 0;

                                return CheckboxListTile(
                                  title: GestureDetector(
                                    onTap: () =>
                                        _showCrewMembers(crewName, crewId),
                                    child: Text(
                                      crewName,
                                      style: const TextStyle(
                                        color: efficialsYellow,
                                        decoration: TextDecoration.underline,
                                        decorationColor: efficialsYellow,
                                      ),
                                    ),
                                  ),
                                  subtitle: Text(
                                    '$memberCount members • Click crew name to view members',
                                    style: const TextStyle(color: Colors.grey),
                                  ),
                                  value:
                                      selectedCrewsForHire[crewAssignmentId] ??
                                          false,
                                  onChanged: (value) {
                                    setState(() {
                                      selectedCrewsForHire[crewAssignmentId] =
                                          value ?? false;
                                    });
                                  },
                                  activeColor: efficialsYellow,
                                  checkColor: efficialsBlack,
                                );
                              }).toList(),
                            ),
                          if (interestedCrews.isNotEmpty) ...[
                            const SizedBox(height: 10),
                            Center(
                              child: ElevatedButton(
                                onPressed: _confirmHires,
                                style: elevatedButtonStyle(),
                                child: const Text('Confirm Crew Hire(s)',
                                    style: signInButtonTextStyle),
                              ),
                            ),
                          ],
                        ] else ...[
                          const Text(
                            'Interested Officials',
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: efficialsYellow),
                          ),
                          const SizedBox(height: 10),
                          if (interestedOfficials.isEmpty)
                            _buildNoOfficialsMessage()
                          else
                            Column(
                              children: interestedOfficials.map((official) {
                                final officialId = official['id'] as int;
                                return CheckboxListTile(
                                  title: GestureDetector(
                                    onTap: () {
                                      _navigateToOfficialProfile(
                                          official['name'] as String);
                                    },
                                    child: Text(
                                      official['name'] as String,
                                      style: const TextStyle(
                                        color: efficialsYellow,
                                        decoration: TextDecoration.underline,
                                        decorationColor: efficialsYellow,
                                      ),
                                    ),
                                  ),
                                  subtitle: Text(
                                      'Distance: ${(official['distance'] as num?)?.toStringAsFixed(1) ?? '0.0'} mi',
                                      style:
                                          const TextStyle(color: Colors.grey)),
                                  value: selectedForHire[officialId] ?? false,
                                  onChanged: (value) {
                                    setState(() {
                                      final currentSelected = selectedForHire
                                          .values
                                          .where((v) => v)
                                          .length;
                                      if (value == true &&
                                          currentSelected < requiredOfficials) {
                                        selectedForHire[officialId] = true;
                                      } else if (value == false) {
                                        selectedForHire[officialId] = false;
                                      }
                                    });
                                  },
                                  activeColor: efficialsYellow,
                                  checkColor: efficialsBlack,
                                );
                              }).toList(),
                            ),
                          if (interestedOfficials.isNotEmpty) ...[
                            const SizedBox(height: 10),
                            Center(
                              child: ElevatedButton(
                                onPressed: _confirmHires,
                                style: elevatedButtonStyle(),
                                child: const Text('Confirm Hire(s)',
                                    style: signInButtonTextStyle),
                              ),
                            ),
                          ],
                        ],
                      ],
                      const SizedBox(height: 20),
                    ],
                    Text(
                        args['method'] == 'hire_crew'
                            ? 'Selected Crews'
                            : 'Selected Officials',
                        style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: efficialsYellow)),
                    const SizedBox(height: 10),
                    _buildSelectedOfficialsSection(),
                    const SizedBox(height: 20),
                    Center(
                      child: ElevatedButton(
                        onPressed: _showDeleteConfirmationDialog,
                        style: elevatedButtonStyle(backgroundColor: Colors.red),
                        child: const Text('Delete Game',
                            style: signInButtonTextStyle),
                      ),
                    ),
                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoOfficialsMessage() {
    final gameId = args['id'];

    // Check if this is a SharedPreferences game (large timestamp ID)
    bool isSharedPrefsGame = false;
    if (gameId is int && gameId > 1000000000000) {
      isSharedPrefsGame = true;
    } else if (gameId is String) {
      final parsedId = int.tryParse(gameId);
      if (parsedId != null && parsedId > 1000000000000) {
        isSharedPrefsGame = true;
      }
    }

    if (isSharedPrefsGame) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Express interest is not available for this game.',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          Text(
            'This game was created using the legacy system. To enable express interest functionality, please recreate this game through the current game creation process.',
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
        ],
      );
    } else {
      return const Text(
        'No officials have expressed interest yet.',
        style: TextStyle(fontSize: 16, color: Colors.grey),
      );
    }
  }

  Widget _buildNoCrewsMessage() {
    final gameId = args['id'];

    // Check if this is a SharedPreferences game (large timestamp ID)
    bool isSharedPrefsGame = false;
    if (gameId is int && gameId > 1000000000000) {
      isSharedPrefsGame = true;
    } else if (gameId is String) {
      final parsedId = int.tryParse(gameId);
      if (parsedId != null && parsedId > 1000000000000) {
        isSharedPrefsGame = true;
      }
    }

    if (isSharedPrefsGame) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Crew interest is not available for this game.',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          Text(
            'This game was created using the legacy system. To enable crew interest functionality, please recreate this game through the current game creation process.',
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
        ],
      );
    } else {
      return const Text(
        'No crews have expressed interest yet.',
        style: TextStyle(fontSize: 16, color: Colors.grey),
      );
    }
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

class _LinkGamesDialog extends StatefulWidget {
  final int currentGameId;
  final List<Map<String, dynamic>> eligibleGames;
  final bool isCurrentlyLinked;
  final GameService gameService;
  final VoidCallback onLinkCreated;

  const _LinkGamesDialog({
    required this.currentGameId,
    required this.eligibleGames,
    required this.isCurrentlyLinked,
    required this.gameService,
    required this.onLinkCreated,
  });

  @override
  State<_LinkGamesDialog> createState() => _LinkGamesDialogState();
}

class _LinkGamesDialogState extends State<_LinkGamesDialog> {
  final Set<int> selectedGameIds = {};
  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: darkSurface,
      title: Text(
        widget.isCurrentlyLinked ? 'Manage Game Links' : 'Link Games',
        style: const TextStyle(
          color: efficialsYellow,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      content: SizedBox(
        width: double.maxFinite,
        height: 400,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.isCurrentlyLinked) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: efficialsYellow.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: efficialsYellow.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.link, color: efficialsYellow, size: 20),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'This game is already linked with other games',
                        style: TextStyle(color: efficialsYellow, fontSize: 14),
                      ),
                    ),
                    TextButton(
                      onPressed: _unlinkGame,
                      child: const Text(
                        'Unlink',
                        style: TextStyle(color: Colors.red, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            Text(
              widget.eligibleGames.isEmpty
                  ? 'No other games found at the same location and date.'
                  : 'Select games to link together (same location & date):',
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
            const SizedBox(height: 12),
            if (widget.eligibleGames.isEmpty)
              const Expanded(
                child: Center(
                  child: Text(
                    'Games must be at the same location on the same date to be linked.',
                    style: TextStyle(color: Colors.grey, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                ),
              )
            else
              Expanded(
                child: ListView.builder(
                  itemCount: widget.eligibleGames.length,
                  itemBuilder: (context, index) {
                    final game = widget.eligibleGames[index];
                    final gameId = game['id'] as int;
                    final isSelected = selectedGameIds.contains(gameId);

                    return CheckboxListTile(
                      title: Text(
                        '${game['time']} - ${game['opponent'] ?? 'vs TBD'}',
                        style: const TextStyle(color: Colors.white, fontSize: 16),
                      ),
                      subtitle: Text(
                        '${game['level_of_competition']} ${game['gender']} • ${game['officials_required']} officials',
                        style: const TextStyle(color: Colors.grey, fontSize: 14),
                      ),
                      value: isSelected,
                      onChanged: (value) {
                        setState(() {
                          if (value == true) {
                            selectedGameIds.add(gameId);
                          } else {
                            selectedGameIds.remove(gameId);
                          }
                        });
                      },
                      activeColor: efficialsYellow,
                      checkColor: efficialsBlack,
                    );
                  },
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel', style: TextStyle(color: efficialsYellow)),
        ),
        if (widget.eligibleGames.isNotEmpty && !widget.isCurrentlyLinked)
          ElevatedButton(
            onPressed: selectedGameIds.isEmpty || isLoading ? null : _createLink,
            style: ElevatedButton.styleFrom(
              backgroundColor: efficialsYellow,
              foregroundColor: efficialsBlack,
            ),
            child: isLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(efficialsBlack),
                    ),
                  )
                : const Text('Link Games'),
          ),
      ],
    );
  }

  Future<void> _createLink() async {
    setState(() {
      isLoading = true;
    });

    try {
      final gameIds = [widget.currentGameId, ...selectedGameIds];
      final linkId = await widget.gameService.createGameLink(gameIds);

      if (linkId != null) {
        widget.onLinkCreated();
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Successfully linked ${gameIds.length} games'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to create game link'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating link: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> _unlinkGame() async {
    setState(() {
      isLoading = true;
    });

    try {
      final success = await widget.gameService.unlinkGame(widget.currentGameId);

      if (success) {
        widget.onLinkCreated();
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Game unlinked successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to unlink game'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error unlinking game: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }
}
