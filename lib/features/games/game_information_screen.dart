import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../shared/theme.dart';
import '../../shared/services/repositories/game_assignment_repository.dart';
import '../../shared/services/game_service.dart';

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
  List<Map<String, dynamic>> confirmedOfficialsFromDB = [];
  Map<int, bool> selectedForHire = {};
  
  // Repository for fetching real interested officials data
  final GameAssignmentRepository _gameAssignmentRepo = GameAssignmentRepository();
  
  // Service for database game operations
  final GameService _gameService = GameService();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final newArgs = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    setState(() {
      args = Map<String, dynamic>.from(newArgs);
      
      // Debug logging to see what data we have
      print('=== GAME INFORMATION DEBUG ===');
      print('method: ${args['method']}');
      print('selectedListName: ${args['selectedListName']}');
      print('selectedLists: ${args['selectedLists']}');
      print('selectedOfficials: ${args['selectedOfficials']}');
      print('isAwayGame: ${args['isAwayGame']}');
      print('sport: ${args['sport']}');
      print('sportName: ${args['sportName']}');
      print('All args keys: ${args.keys.toList()}');
      print('==============================');
      sport = args['sport'] as String? ?? args['sportName'] as String? ?? 'Unknown';
      scheduleName = args['scheduleName'] as String? ?? 'Unnamed';
      location = args['location'] as String? ?? 'Not set';
      selectedDate = args['date'] != null
          ? (args['date'] is String ? DateTime.parse(args['date'] as String) : args['date'] as DateTime)
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
      officialsRequired = args['officialsRequired'] != null ? int.tryParse(args['officialsRequired'].toString()) : null;
      gameFee = args['gameFee']?.toString() ?? 'Not set';
      hireAutomatically = args['hireAutomatically'] as bool? ?? false;
      isAwayGame = args['isAwayGame'] as bool? ?? false;
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

  // Load real interested officials from database
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
        print('Loading interested officials for database game ID: $databaseGameId');
        final interestedOfficials = await _gameAssignmentRepo.getInterestedOfficialsForGame(databaseGameId);
        final confirmedOfficials = await _gameAssignmentRepo.getConfirmedOfficialsForGame(databaseGameId);
        
        setState(() {
          // Create mutable copies of the query results
          this.interestedOfficials = List<Map<String, dynamic>>.from(interestedOfficials);
          confirmedOfficialsFromDB = List<Map<String, dynamic>>.from(confirmedOfficials);
          selectedForHire = {};
          for (var official in this.interestedOfficials) {
            selectedForHire[official['id'] as int] = false;
          }
        });
      } else {
        print('SharedPreferences game detected (ID: $gameId) - express interest not supported');
        // For SharedPreferences games, interested officials feature is not supported
        // as they use a different storage system
        setState(() {
          interestedOfficials = [];
          selectedForHire = {};
        });
      }
    } catch (e) {
      print('Error loading interested officials: $e');
      setState(() {
        interestedOfficials = [];
        selectedForHire = {};
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
        print('Deleting database game ID: $databaseGameId');
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
        print('Deleting SharedPreferences game ID: $gameId');
        await _deleteSharedPreferencesGame(gameId);
      }
    } catch (e) {
      print('Error deleting game: $e');
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
        List<Map<String, dynamic>> publishedGames = List<Map<String, dynamic>>.from(jsonDecode(gamesJson));
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
    if (selectedCount == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one official to confirm')),
      );
      return;
    }

    final newTotalHired = officialsHired + selectedCount;
    if (newTotalHired > (officialsRequired ?? 0)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Cannot hire more than $officialsRequired officials')),
      );
      return;
    }

    if (args['method'] == 'advanced' && args['selectedLists'] != null) {
      final listCounts = <String, int>{};
      final selectedIds = selectedForHire.entries.where((e) => e.value).map((e) => e.key).toList();
      final hiredOfficials = interestedOfficials.where((o) => selectedIds.contains(o['id'])).toList();

      final prefs = await SharedPreferences.getInstance();
      final String? listsJson = prefs.getString('saved_lists');
      final List<Map<String, dynamic>> savedListsRaw = listsJson != null && listsJson.isNotEmpty
          ? List<Map<String, dynamic>>.from(jsonDecode(listsJson))
          : [];
      final Map<String, List<Map<String, dynamic>>> savedLists = {
        for (var list in savedListsRaw) list['name'] as String: List<Map<String, dynamic>>.from(list['officials'] ?? [])
      };

      for (var official in hiredOfficials) {
        final listName = (args['selectedLists'] as List<dynamic>)
            .map((list) => Map<String, dynamic>.from(list as Map))
            .firstWhere(
              (list) => (savedLists[list['name']] ?? []).any((o) => o['id'] == official['id']),
              orElse: () => {'name': 'Unknown'},
            )['name'];
        listCounts[listName] = (listCounts[listName] ?? 0) + 1;
      }

      for (var official in selectedOfficials) {
        final listName = (args['selectedLists'] as List<dynamic>)
            .map((list) => Map<String, dynamic>.from(list as Map))
            .firstWhere(
              (list) => (savedLists[list['name']] ?? []).any((o) => o['id'] == official['id']),
              orElse: () => {'name': 'Unknown'},
            )['name'];
        listCounts[listName] = (listCounts[listName] ?? 0) + 1;
      }

      for (var list in (args['selectedLists'] as List<dynamic>).map((list) => Map<String, dynamic>.from(list as Map))) {
        final count = listCounts[list['name']] ?? 0;
        if (count > list['maxOfficials']) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Cannot exceed max (${list['maxOfficials']}) for ${list['name']}')),
            );
          }
          return;
        }
      }
    }

    final hiredIds = selectedForHire.entries.where((e) => e.value).map((e) => e.key).toList();
    final hiredOfficials = interestedOfficials.where((o) => hiredIds.contains(o['id'])).toList();

    setState(() {
      officialsHired += selectedCount;
      args['officialsHired'] = officialsHired;
      selectedOfficials.addAll(hiredOfficials);
      // Create a new mutable list instead of modifying the read-only query result
      interestedOfficials = interestedOfficials.where((o) => !hiredIds.contains(o['id'])).toList();
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
        print('Updating officials hired count for database game ID: $databaseGameId');
        
        // Update the officials hired count in database
        final updateResult = await _gameService.updateOfficialsHired(databaseGameId, officialsHired);
        
        // Update GameAssignment status from 'pending' to 'accepted' for hired officials
        for (final officialId in hiredIds) {
          try {
            final assignmentId = await _getAssignmentId(databaseGameId, officialId);
            if (assignmentId > 0) {
              await _gameAssignmentRepo.updateAssignmentStatus(assignmentId, 'accepted');
              print('Updated assignment $assignmentId for official $officialId to accepted');
            } else {
              print('ERROR: Could not find assignment for game $databaseGameId, official $officialId');
            }
          } catch (e) {
            print('ERROR updating assignment status for official $officialId: $e');
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
        print('Updating officials hired count for SharedPreferences game ID: $gameId');
        await _updateSharedPreferencesGame();
      }
    } catch (e) {
      print('Error updating game: $e');
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
      List<Map<String, dynamic>> publishedGames = List<Map<String, dynamic>>.from(jsonDecode(gamesJson));
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
    final assignment = await _gameAssignmentRepo.getAssignmentByGameAndOfficial(gameId, officialId);
    return assignment?.id ?? 0;
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
                 1 as showCareerStats
          FROM officials o 
          WHERE o.id = ?
        ''', [officialId]);
        
        if (officialData.isNotEmpty && mounted) {
          final official = officialData.first;
          
          // Create profile data compatible with OfficialProfileScreen
          final profileData = {
            'id': official['id'],
            'name': official['name'],
            'email': official['email'] ?? 'N/A',
            'phone': official['phone'] ?? 'N/A',
            'location': 'N/A', // Not available in officials table
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
      print('Error navigating to official profile: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error loading official profile')),
        );
      }
    }
  }

  void _showListOfficials(String listName) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? listsJson = prefs.getString('saved_lists');
      final List<Map<String, dynamic>> savedListsRaw = listsJson != null && listsJson.isNotEmpty
          ? List<Map<String, dynamic>>.from(jsonDecode(listsJson))
          : [];
      
      final savedLists = {
        for (var list in savedListsRaw) list['name'] as String: List<Map<String, dynamic>>.from(list['officials'] ?? [])
      };
      
      // Get the full original list
      final fullOfficialsList = savedLists[listName] ?? [];
      
      // Get the game-specific officials for this list (the ones actually selected for this game)
      List<Map<String, dynamic>> gameSpecificOfficials = [];
      
      if (args['method'] == 'advanced' && selectedLists.isNotEmpty) {
        // For advanced method, get officials from the specific list in selectedLists
        debugPrint('=== ADVANCED METHOD DEBUG ===');
        debugPrint('Looking for list: $listName');
        debugPrint('Available selectedLists: ${selectedLists.map((l) => l['name']).toList()}');
        
        final gameList = selectedLists.firstWhere(
          (list) => list['name'] == listName,
          orElse: () => <String, dynamic>{},
        );
        
        debugPrint('Found gameList: ${gameList.keys.toList()}');
        debugPrint('Officials in gameList: ${gameList['officials']}');
        
        gameSpecificOfficials = List<Map<String, dynamic>>.from(gameList['officials'] ?? []);
        debugPrint('Game-specific officials count: ${gameSpecificOfficials.length}');
      } else if (args['method'] == 'use_list' && args['selectedListName'] == listName) {
        // For use_list method, all selected officials are from this list
        gameSpecificOfficials = selectedOfficials;
      }
      
      // Get the names of officials actually selected for this game
      final gameOfficialNames = gameSpecificOfficials.map((o) => o['name'] as String?).toSet();
      
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: darkSurface,
            title: Text(
              'Officials in "$listName"',
              style: const TextStyle(color: efficialsYellow, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            content: SizedBox(
              width: double.maxFinite,
              height: 400,
              child: fullOfficialsList.isEmpty
                  ? const Text('No officials in this list.', style: TextStyle(color: Colors.white))
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (gameSpecificOfficials.isNotEmpty) ...[
                          Text(
                            'Legend: Normal text = selected for game, Strikethrough = removed from game',
                            style: TextStyle(fontSize: 12, color: Colors.grey[400], fontStyle: FontStyle.italic),
                          ),
                          const SizedBox(height: 8),
                        ],
                        Expanded(
                          child: ListView.builder(
                            itemCount: fullOfficialsList.length,
                            itemBuilder: (context, index) {
                              final official = fullOfficialsList[index];
                              final officialName = official['name'] as String? ?? 'Unknown Official';
                              final isSelectedForGame = gameOfficialNames.contains(officialName);
                              
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4),
                                child: Text(
                                  '• $officialName (${official['distance']?.toStringAsFixed(1) ?? '0.0'} mi)',
                                  style: TextStyle(
                                    color: isSelectedForGame ? Colors.white : Colors.grey,
                                    fontSize: 16,
                                    decoration: isSelectedForGame 
                                        ? TextDecoration.none 
                                        : TextDecoration.lineThrough,
                                    decorationColor: Colors.grey,
                                    decorationThickness: 2.0,
                                  ),
                                ),
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
                child: const Text('Close', style: TextStyle(color: efficialsYellow)),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      print('Error loading list officials: $e');
    }
  }

  Widget _buildSelectedOfficialsSection() {
    print('Building Selected Officials Section:');
    print('  isAwayGame: $isAwayGame');
    print('  method: ${args['method']}');
    print('  selectedListName: ${args['selectedListName']}');
    print('  selectedLists length: ${selectedLists.length}');
    print('  selectedOfficials length: ${selectedOfficials.length}');
    
    if (isAwayGame) {
      return const Text('No officials needed for away games.', style: TextStyle(fontSize: 16, color: Colors.grey));
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
        children: selectedLists.map((list) => Padding(
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
        )).toList(),
      );
    }

    // For manual selection, show individual officials
    if (selectedOfficials.isNotEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: selectedOfficials.map((official) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Text(
            '• ${official['name']} (${(official['distance'] as num?)?.toStringAsFixed(1) ?? '0.0'} mi)',
            style: const TextStyle(fontSize: 16, color: Colors.white),
          ),
        )).toList(),
      );
    }

    return const Text('No officials selected.', style: TextStyle(fontSize: 16, color: Colors.grey));
  }

  void _showDeleteConfirmationDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: darkSurface,
        title: const Text('Confirm Delete', 
            style: TextStyle(color: efficialsYellow, fontSize: 20, fontWeight: FontWeight.bold)),
        content: const Text('Are you sure you want to delete this game?',
            style: TextStyle(color: Colors.white)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: efficialsYellow)),
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

  Map<String, int> _getSelectedCounts(Map<String, List<Map<String, dynamic>>> savedLists) {
    final listCounts = <String, int>{};
    final selectedIds = selectedForHire.entries.where((e) => e.value).map((e) => e.key).toList();
    final selectedOfficials = interestedOfficials.where((o) => selectedIds.contains(o['id'])).toList();

    for (var official in selectedOfficials) {
      final listName = (args['selectedLists'] as List<dynamic>)
          .map((list) => Map<String, dynamic>.from(list as Map))
          .firstWhere(
            (list) => (savedLists[list['name']] ?? []).any((o) => o['id'] == official['id']),
            orElse: () => {'name': 'Unknown'},
          )['name'];
      listCounts[listName] = (listCounts[listName] ?? 0) + 1;
    }
    return listCounts;
  }

  @override
  Widget build(BuildContext context) {
    final isAdultLevel = levelOfCompetition.toLowerCase() == 'college' || levelOfCompetition.toLowerCase() == 'adult';
    final displayGender = isAdultLevel
        ? {'boys': 'Men', 'girls': 'Women', 'co-ed': 'Co-ed'}[gender.toLowerCase()] ?? gender
        : gender;

    final gameDetails = <String, String>{
      'Sport': sport,
      'Schedule Name': scheduleName,
      'Date': selectedDate != null ? DateFormat('MMMM d, yyyy').format(selectedDate!) : 'Not set',
      'Time': selectedTime != null ? selectedTime!.format(context) : 'Not set',
      'Location': location,
      if (!isAwayGame) ...{
        'Officials Required': officialsRequired?.toString() ?? '0',
        'Fee per Official': gameFee != 'Not set' ? '\$$gameFee' : 'Not set',
        'Gender': displayGender,
        'Competition Level': levelOfCompetition,
        'Hire Automatically': hireAutomatically ? 'Yes' : 'No',
      },
      'Opponent': opponent,
    };

    final requiredOfficials = officialsRequired ?? 0;
    
    // Only show database confirmed officials (actual claims/assignments)
    // Do NOT include selectedOfficials as those are just pre-selected during game creation
    final confirmedOfficials = confirmedOfficialsFromDB.map((official) => official['name'] as String).toList();

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
              'time': selectedTime != null ? '${selectedTime!.hour}:${selectedTime!.minute}' : null,
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
                    const Text('Game Details', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: efficialsYellow)),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          onPressed: _createTemplateFromGame,
                          icon: const Icon(Icons.link, color: efficialsYellow),
                          tooltip: 'Create Template from Game',
                        ),
                        TextButton(
                          onPressed: () => Navigator.pushNamed(
                            context,
                            '/edit_game_info',
                            arguments: {
                              ...args,
                              'isEdit': true,
                              'isFromGameInfo': true,
                            },
                          ).then((result) {
                        if (result != null && result is Map<String, dynamic>) {
                          setState(() {
                            args = result;
                            sport = args['sport'] as String? ?? sport;
                            scheduleName = args['scheduleName'] as String? ?? scheduleName;
                            location = args['location'] as String? ?? location;
                            selectedDate = args['date'] != null
                                ? (args['date'] is String ? DateTime.parse(args['date'] as String) : args['date'] as DateTime)
                                : selectedDate;
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
                                : selectedTime;
                            levelOfCompetition = args['levelOfCompetition'] as String? ?? levelOfCompetition;
                            gender = args['gender'] as String? ?? gender;
                            officialsRequired = args['officialsRequired'] != null ? int.tryParse(args['officialsRequired'].toString()) : officialsRequired;
                            gameFee = args['gameFee']?.toString() ?? gameFee;
                            hireAutomatically = args['hireAutomatically'] as bool? ?? hireAutomatically;
                            isAwayGame = args['isAwayGame'] as bool? ?? isAwayGame;
                            opponent = args['opponent'] as String? ?? opponent;
                            officialsHired = args['officialsHired'] as int? ?? officialsHired;
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
                          Navigator.pop(context, result);
                        }
                      }),
                      child: const Text('Edit', style: TextStyle(color: efficialsYellow, fontSize: 18)),
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
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.white),
                              ),
                            ),
                            Expanded(
                              child: e.key == 'Schedule Name' 
                                ? GestureDetector(
                                    onTap: () async {
                                      final prefs = await SharedPreferences.getInstance();
                                      final schedulerType = prefs.getString('schedulerType');
                                      
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
                                            'focusDate': selectedDate,
                                          };
                                          break;
                                        case 'assigner':
                                        default:
                                          route = '/assigner_manage_schedules';
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
                                    style: const TextStyle(fontSize: 16, color: Colors.white),
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    if (!isAwayGame) ...[
                      Text(
                        'Confirmed Officials (${confirmedOfficials.length}/$requiredOfficials)',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: efficialsYellow),
                      ),
                      const SizedBox(height: 10),
                      if (confirmedOfficials.isEmpty)
                        const Text('No officials confirmed.', style: TextStyle(fontSize: 16, color: Colors.grey))
                      else
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: confirmedOfficials.map((name) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 2),
                              child: GestureDetector(
                                onTap: () {
                                  _navigateToOfficialProfile(name);
                                },
                                child: Text(
                                  name,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: efficialsYellow,
                                    decoration: TextDecoration.underline,
                                    decorationColor: efficialsYellow,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      if (!hireAutomatically && officialsHired < requiredOfficials) ...[
                        const SizedBox(height: 20),
                        const Text(
                          'Interested Officials',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: efficialsYellow),
                        ),
                        const SizedBox(height: 10),
                        if (interestedOfficials.isEmpty)
                          _buildNoOfficialsMessage()
                        else
                          Column(
                            children: interestedOfficials.map((official) {
                              final officialId = official['id'] as int;
                              return CheckboxListTile(
                                title: Text(official['name'] as String, style: const TextStyle(color: Colors.white)),
                                subtitle: Text('Distance: ${(official['distance'] as num?)?.toStringAsFixed(1) ?? '0.0'} mi', style: const TextStyle(color: Colors.grey)),
                                value: selectedForHire[officialId] ?? false,
                                onChanged: (value) {
                                  setState(() {
                                    final currentSelected = selectedForHire.values.where((v) => v).length;
                                    if (value == true && currentSelected < requiredOfficials) {
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
                              child: const Text('Confirm Hire(s)', style: signInButtonTextStyle),
                            ),
                          ),
                        ],
                      ],
                      const SizedBox(height: 20),
                    ],
                    const Text('Selected Officials', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: efficialsYellow)),
                    const SizedBox(height: 10),
                    _buildSelectedOfficialsSection(),
                    const SizedBox(height: 20),
                    Center(
                      child: ElevatedButton(
                        onPressed: _showDeleteConfirmationDialog,
                        style: elevatedButtonStyle(backgroundColor: Colors.red),
                        child: const Text('Delete Game', style: signInButtonTextStyle),
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
}

class _SliverHeaderDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;

  _SliverHeaderDelegate({required this.child});

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return child;
  }

  @override
  double get maxExtent => 80;

  @override
  double get minExtent => 80;

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) => true;
}