import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/database_models.dart';
import 'repositories/game_repository.dart';
import 'repositories/game_template_repository.dart';
import 'repositories/user_repository.dart';
import 'repositories/schedule_repository.dart';
import 'repositories/location_repository.dart';
import 'repositories/sport_repository.dart';

class GameService {
  static final GameService _instance = GameService._internal();
  GameService._internal();
  factory GameService() => _instance;

  final GameRepository _gameRepository = GameRepository();
  final GameTemplateRepository _templateRepository = GameTemplateRepository();
  final UserRepository _userRepository = UserRepository();
  final ScheduleRepository _scheduleRepository = ScheduleRepository();
  final LocationRepository _locationRepository = LocationRepository();
  final SportRepository _sportRepository = SportRepository();

  // Get current user ID (for database operations)
  Future<int> _getCurrentUserId() async {
    final user = await _userRepository.getCurrentUser();
    if (user != null) {
      return user.id!;
    }
    
    // If no user exists, create a default Athletic Director user
    try {
      final defaultUser = User(
        schedulerType: 'Athletic Director',
        setupCompleted: true,
        schoolName: 'Edwardsville',
        mascot: 'Tigers',
      );
      final userId = await _userRepository.createUser(defaultUser);
      debugPrint('Created default user with ID: $userId');
      return userId;
    } catch (e) {
      debugPrint('Error creating default user: $e');
      return 1; // Fallback to ID 1
    }
  }

  // GAME OPERATIONS

  // Get all games for the current user
  Future<List<Game>> getGames({String? status}) async {
    try {
      final userId = await _getCurrentUserId();
      final games = await _gameRepository.getGamesByUser(userId, status: status);
      
      // Return Game objects directly - no conversion needed
      return games;
    } catch (e) {
      debugPrint('Error getting games: $e');
      return [];
    }
  }

  // Get published games
  Future<List<Game>> getPublishedGames() async {
    return await getGames(status: 'Published');
  }

  // Get unpublished games
  Future<List<Game>> getUnpublishedGames() async {
    return await getGames(status: 'Unpublished');
  }

  // Get games by schedule ID
  Future<List<Map<String, dynamic>>> getGamesBySchedule(int scheduleId) async {
    try {
      final games = await _gameRepository.getGamesBySchedule(scheduleId);
      return games.map((game) => _gameToMap(game)).toList();
    } catch (e) {
      debugPrint('Error getting games by schedule: $e');
      return [];
    }
  }

  // Get games by schedule name
  Future<List<Map<String, dynamic>>> getGamesByScheduleName(String scheduleName) async {
    try {
      final userId = await _getCurrentUserId();
      final allGames = await _gameRepository.getGamesByUser(userId);
      
      // Filter games for this schedule that have dates
      final games = allGames.where((game) {
        final matchesSchedule = game.scheduleName == scheduleName;
        final hasDate = game.date != null;
        return matchesSchedule && hasDate;
      }).toList();

      return games.map((game) => _gameToMap(game)).toList();
    } catch (e) {
      debugPrint('Error getting games by schedule name: $e');
      return [];
    }
  }

  // Get games by team (opponent name)
  Future<List<Map<String, dynamic>>> getGamesByTeam(String teamName) async {
    try {
      final userId = await _getCurrentUserId();
      final allGames = await _gameRepository.getGamesByUser(userId);
      
      // Filter games for this team that have dates
      final games = allGames.where((game) {
        final matchesTeam = game.opponent == teamName ||
            (game.scheduleName != null && game.scheduleName!.contains(teamName));
        final hasDate = game.date != null;
        return matchesTeam && hasDate;
      }).toList();

      // Convert to maps and parse date/time
      return games.map((game) {
        final gameMap = _gameToMap(game);
        // Ensure date and time are properly formatted
        if (game.date != null) {
          gameMap['date'] = game.date;
        }
        if (game.time != null) {
          gameMap['time'] = game.time;
        }
        return gameMap;
      }).toList();
    } catch (e) {
      debugPrint('Error getting games by team: $e');
      return [];
    }
  }

  // Get filtered games
  Future<List<Game>> getFilteredGames({
    bool? showAwayGames,
    bool? showFullyCoveredGames,
    Map<String, Map<String, bool>>? scheduleFilters,
    String? status,
  }) async {
    try {
      final userId = await _getCurrentUserId();
      final games = await _gameRepository.getFilteredGames(
        userId,
        showAwayGames: showAwayGames,
        showFullyCoveredGames: showFullyCoveredGames,
        scheduleFilters: scheduleFilters,
        status: status,
      );
      
      return games;
    } catch (e) {
      debugPrint('Error getting filtered games: $e');
      return [];
    }
  }

  // Get a single game by ID
  Future<Map<String, dynamic>?> getGameById(int gameId) async {
    try {
      final game = await _gameRepository.getGameById(gameId);
      return game != null ? _gameToMap(game) : null;
    } catch (e) {
      debugPrint('Error getting game by ID: $e');
      return null;
    }
  }

  // Get a single game by ID with officials selection data reconstructed
  Future<Map<String, dynamic>?> getGameByIdWithOfficials(int gameId) async {
    try {
      final game = await _gameRepository.getGameById(gameId);
      return game != null ? await _gameToMapWithOfficials(game) : null;
    } catch (e) {
      debugPrint('Error fetching game with officials: $e');
      return null;
    }
  }

  // Create a new game
  Future<Map<String, dynamic>?> createGame(Map<String, dynamic> gameData) async {
    try {
      
      // DUPLICATE PREVENTION: Check if a similar game already exists
      final userId = await _getCurrentUserId();
      
      // Check for potential duplicates within the last 2 minutes
      final recentGames = await _gameRepository.getGamesByUser(userId);
      final now = DateTime.now();
      final twoMinutesAgo = now.subtract(const Duration(minutes: 2));
      
      final potentialDuplicate = recentGames.where((game) {
        if (game.createdAt.isBefore(twoMinutesAgo)) return false;
        
        // Check if key fields match (opponent, date, sport)
        final sameOpponent = (game.opponent?.trim() ?? '') == (gameData['opponent']?.toString().trim() ?? '');
        final sameDate = game.date?.toIso8601String().split('T')[0] == 
                        (gameData['date'] as DateTime?)?.toIso8601String().split('T')[0];
        final sameSport = (game.sportName?.trim() ?? '') == (gameData['sport']?.toString().trim() ?? '');
        
        // Additional check for schedule if both have it
        bool sameSchedule = true;
        if (game.scheduleName != null && gameData['scheduleName'] != null) {
          sameSchedule = (game.scheduleName?.trim() ?? '') == (gameData['scheduleName']?.toString().trim() ?? '');
        }
        
        return sameOpponent && sameDate && sameSport && sameSchedule;
      }).toList();
      
      if (potentialDuplicate.isNotEmpty) {
        return _gameToMap(potentialDuplicate.first);
      }
      
      // Get sport ID
      final sportId = await _getSportId(gameData['sport']);
      if (sportId == null) {
        return null;
      }

      // Get schedule ID if provided
      int? scheduleId;
      if (gameData['scheduleName'] != null) {
        scheduleId = await _getScheduleId(gameData['scheduleName'], sportId);
      }

      // Get location ID if provided
      int? locationId;
      if (gameData['location'] != null) {
        locationId = await _getLocationId(gameData['location']);
      }

      // Get Athletic Director's school information for home team
      String? homeTeam;
      try {
        final currentUser = await _userRepository.getCurrentUser();
        if (currentUser != null && currentUser.schoolName != null && currentUser.mascot != null) {
          homeTeam = '${currentUser.schoolName} ${currentUser.mascot}';
        }
      } catch (e) {
        debugPrint('Error getting AD school info: $e');
      }
      
      // Ensure homeTeam is never null or empty
      if (homeTeam == null || homeTeam.trim().isEmpty || homeTeam.toLowerCase() == 'null') {
        homeTeam = 'Home Team';
      }

      final game = Game(
        scheduleId: scheduleId,
        sportId: sportId,
        locationId: locationId,
        userId: userId,
        date: gameData['date'],
        time: gameData['time'],
        isAway: gameData['isAway'] ?? false,
        levelOfCompetition: gameData['levelOfCompetition'],
        gender: gameData['gender'],
        officialsRequired: gameData['officialsRequired'] ?? 0,
        officialsHired: gameData['officialsHired'] ?? 0,
        gameFee: gameData['gameFee'],
        opponent: gameData['opponent'],
        homeTeam: homeTeam,
        hireAutomatically: gameData['hireAutomatically'] ?? false,
        method: gameData['method'],
        status: gameData['status'] ?? 'Unpublished',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final gameId = await _gameRepository.createGame(game);
      final createdGame = await _gameRepository.getGameById(gameId);
      
      return createdGame != null ? _gameToMap(createdGame) : null;
    } catch (e) {
      debugPrint('Error creating game: $e');
      return null;
    }
  }

  // Update an existing game
  Future<Map<String, dynamic>?> updateGame(int gameId, Map<String, dynamic> gameData) async {
    try {
      final existingGame = await _gameRepository.getGameById(gameId);
      if (existingGame == null) return null;

      // Get sport ID
      final sportId = await _getSportId(gameData['sport']);
      if (sportId == null) {
        return null;
      }

      // Get schedule ID if provided
      int? scheduleId;
      if (gameData['scheduleName'] != null) {
        scheduleId = await _getScheduleId(gameData['scheduleName'], sportId);
      }

      // Get location ID if provided
      int? locationId;
      if (gameData['location'] != null) {
        locationId = await _getLocationId(gameData['location']);
      }

      final updatedGame = existingGame.copyWith(
        scheduleId: scheduleId,
        sportId: sportId,
        locationId: locationId,
        date: gameData['date'],
        time: gameData['time'],
        isAway: gameData['isAway'],
        levelOfCompetition: gameData['levelOfCompetition'],
        gender: gameData['gender'],
        officialsRequired: gameData['officialsRequired'],
        officialsHired: gameData['officialsHired'],
        gameFee: gameData['gameFee'],
        opponent: gameData['opponent'],
        hireAutomatically: gameData['hireAutomatically'],
        method: gameData['method'],
        status: gameData['status'],
        updatedAt: DateTime.now(),
      );

      await _gameRepository.updateGame(updatedGame);
      final updated = await _gameRepository.getGameById(gameId);
      
      return updated != null ? _gameToMap(updated) : null;
    } catch (e) {
      debugPrint('Error updating game: $e');
      return null;
    }
  }

  // Update officials hired count only
  Future<bool> updateOfficialsHired(int gameId, int officialsHired) async {
    try {
      await _gameRepository.updateOfficialsHired(gameId, officialsHired);
      return true;
    } catch (e) {
      debugPrint('Error updating officials hired count: $e');
      return false;
    }
  }

  // Delete a game
  Future<bool> deleteGame(int gameId) async {
    try {
      await _gameRepository.deleteGame(gameId);
      return true;
    } catch (e) {
      debugPrint('Error deleting game: $e');
      return false;
    }
  }

  // Publish games
  Future<bool> publishGames(List<int> gameIds) async {
    try {
      await _gameRepository.bulkUpdateGameStatus(gameIds, 'Published');
      return true;
    } catch (e) {
      debugPrint('Error publishing games: $e');
      return false;
    }
  }

  // Unpublish games
  Future<bool> unpublishGames(List<int> gameIds) async {
    try {
      await _gameRepository.bulkUpdateGameStatus(gameIds, 'Unpublished');
      return true;
    } catch (e) {
      debugPrint('Error unpublishing games: $e');
      return false;
    }
  }

  // GAME TEMPLATE OPERATIONS

  // Get all templates for the current user
  Future<List<Map<String, dynamic>>> getTemplates() async {
    try {
      final userId = await _getCurrentUserId();
      final templates = await _templateRepository.getTemplatesByUser(userId);
      
      // Fix templates that have officialsListId but no officialsListName due to JOIN issues
      final fixedTemplates = await _fixTemplatesWithMissingListNames(templates);
      
      // Convert templates to map and add selectedLists data
      final templateMaps = <Map<String, dynamic>>[];
      for (final template in fixedTemplates) {
        final templateMap = _templateToMap(template);
        // Add selectedLists data for advanced method templates
        if (template.method == 'advanced') {
          templateMap['selectedLists'] = await _getTemplateSelectedLists(template.id!);
        }
        templateMaps.add(templateMap);
      }
      
      return templateMaps;
    } catch (e) {
      debugPrint('Error getting templates: $e');
      return [];
    }
  }

  // Get templates by sport
  Future<List<Map<String, dynamic>>> getTemplatesBySport(String sportName) async {
    try {
      final userId = await _getCurrentUserId();
      final sportId = await _getSportId(sportName);
      if (sportId == null) return [];

      final templates = await _templateRepository.getTemplatesBySport(userId, sportId);
      
      // Convert templates to map and add selectedLists data
      final templateMaps = <Map<String, dynamic>>[];
      for (final template in templates) {
        final templateMap = _templateToMap(template);
        // Add selectedLists data for advanced method templates
        if (template.method == 'advanced') {
          templateMap['selectedLists'] = await _getTemplateSelectedLists(template.id!);
        }
        templateMaps.add(templateMap);
      }
      
      return templateMaps;
    } catch (e) {
      debugPrint('Error getting templates by sport: $e');
      return [];
    }
  }

  // Create a new template
  Future<Map<String, dynamic>?> createTemplate(Map<String, dynamic> templateData) async {
    try {
      final userId = await _getCurrentUserId();
      
      // Check if template name already exists
      final exists = await _templateRepository.doesTemplateExist(userId, templateData['name']);
      if (exists) {
        return null;
      }

      // Get sport ID
      final sportId = await _getSportId(templateData['sport']);
      if (sportId == null) {
        return null;
      }

      // Get location ID if provided
      int? locationId;
      if (templateData['location'] != null) {
        locationId = await _getLocationId(templateData['location']);
      }

      // Get officials list ID if provided by name
      int? officialsListId = templateData['officialsListId'];
      if (officialsListId == null && templateData['officialsListName'] != null) {
        officialsListId = await _getOfficialsListId(templateData['officialsListName']);
      }

      final template = GameTemplate(
        name: templateData['name'],
        sportId: sportId,
        userId: userId,
        scheduleName: templateData['scheduleName'],
        date: templateData['date'],
        time: templateData['time'],
        locationId: locationId,
        isAwayGame: templateData['isAwayGame'] ?? false,
        levelOfCompetition: templateData['levelOfCompetition'],
        gender: templateData['gender'],
        officialsRequired: templateData['officialsRequired'],
        gameFee: templateData['gameFee'],
        opponent: templateData['opponent'],
        hireAutomatically: templateData['hireAutomatically'] ?? false,
        method: templateData['method'],
        officialsListId: officialsListId,
        includeScheduleName: templateData['includeScheduleName'] ?? false,
        includeSport: templateData['includeSport'] ?? false,
        includeDate: templateData['includeDate'] ?? false,
        includeTime: templateData['includeTime'] ?? false,
        includeLocation: templateData['includeLocation'] ?? false,
        includeIsAwayGame: templateData['includeIsAwayGame'] ?? false,
        includeLevelOfCompetition: templateData['includeLevelOfCompetition'] ?? false,
        includeGender: templateData['includeGender'] ?? false,
        includeOfficialsRequired: templateData['includeOfficialsRequired'] ?? false,
        includeGameFee: templateData['includeGameFee'] ?? false,
        includeOpponent: templateData['includeOpponent'] ?? false,
        includeHireAutomatically: templateData['includeHireAutomatically'] ?? false,
        includeSelectedOfficials: templateData['includeSelectedOfficials'] ?? false,
        includeOfficialsList: templateData['includeOfficialsList'] ?? false,
        createdAt: DateTime.now(),
      );

      final templateId = await _templateRepository.createGameTemplate(template);
      
      // Store selectedLists data separately if it exists
      if (templateData['selectedLists'] != null && templateData['method'] == 'advanced') {
        await _storeTemplateSelectedLists(templateId, templateData['selectedLists']);
      }
      
      final createdTemplate = await _templateRepository.getTemplateById(templateId);
      
      if (createdTemplate != null) {
        // Manually set the officialsListName if it was provided in templateData
        // This bypasses the database JOIN issue since lists are stored in SharedPreferences
        if (templateData['officialsListName'] != null) {
          final templateWithName = GameTemplate(
            id: createdTemplate.id,
            name: createdTemplate.name,
            sportId: createdTemplate.sportId,
            userId: createdTemplate.userId,
            scheduleName: createdTemplate.scheduleName,
            date: createdTemplate.date,
            time: createdTemplate.time,
            locationId: createdTemplate.locationId,
            isAwayGame: createdTemplate.isAwayGame,
            levelOfCompetition: createdTemplate.levelOfCompetition,
            gender: createdTemplate.gender,
            officialsRequired: createdTemplate.officialsRequired,
            gameFee: createdTemplate.gameFee,
            opponent: createdTemplate.opponent,
            hireAutomatically: createdTemplate.hireAutomatically,
            method: createdTemplate.method,
            officialsListId: createdTemplate.officialsListId,
            selectedOfficials: createdTemplate.selectedOfficials,
            includeScheduleName: createdTemplate.includeScheduleName,
            includeSport: createdTemplate.includeSport,
            includeDate: createdTemplate.includeDate,
            includeTime: createdTemplate.includeTime,
            includeLocation: createdTemplate.includeLocation,
            includeIsAwayGame: createdTemplate.includeIsAwayGame,
            includeLevelOfCompetition: createdTemplate.includeLevelOfCompetition,
            includeGender: createdTemplate.includeGender,
            includeOfficialsRequired: createdTemplate.includeOfficialsRequired,
            includeGameFee: createdTemplate.includeGameFee,
            includeOpponent: createdTemplate.includeOpponent,
            includeHireAutomatically: createdTemplate.includeHireAutomatically,
            includeSelectedOfficials: createdTemplate.includeSelectedOfficials,
            includeOfficialsList: createdTemplate.includeOfficialsList,
            createdAt: createdTemplate.createdAt,
            sportName: createdTemplate.sportName,
            locationName: createdTemplate.locationName,
            officialsListName: templateData['officialsListName'] as String?, // Set manually
          );
          return _templateToMap(templateWithName);
        }
        return _templateToMap(createdTemplate);
      }
      return null;
    } catch (e) {
      debugPrint('Error creating template: $e');
      return null;
    }
  }

  // Delete a template
  Future<bool> deleteTemplate(int templateId) async {
    try {
      await _templateRepository.deleteGameTemplate(templateId);
      return true;
    } catch (e) {
      debugPrint('Error deleting template: $e');
      return false;
    }
  }

  // Clear all templates for current user (safe - doesn't affect officials)
  Future<bool> clearAllTemplates() async {
    try {
      final userId = await _getCurrentUserId();
      final templates = await _templateRepository.getTemplatesByUser(userId);
      
      for (final template in templates) {
        await _templateRepository.deleteGameTemplate(template.id!);
      }
      
      return true;
    } catch (e) {
      debugPrint('Error clearing templates: $e');
      return false;
    }
  }

  // Update a template
  Future<bool> updateTemplate(dynamic templateData) async {
    try {
      // Convert templateData to Map if it's a GameTemplate object
      Map<String, dynamic> data;
      if (templateData is Map<String, dynamic>) {
        data = templateData;
      } else {
        // Assume it's a GameTemplate object with toJson method
        data = templateData.toJson();
      }

      debugPrint('UpdateTemplate - Data: $data');
      
      final templateId = int.parse(data['id'].toString());
      final userId = await _getCurrentUserId();
      
      // Get sport ID
      final sportId = await _getSportId(data['sport']);
      if (sportId == null) {
        debugPrint('UpdateTemplate - Failed to get sport ID for: ${data['sport']}');
        return false;
      }

      // Get location ID if provided
      int? locationId;
      if (data['location'] != null) {
        locationId = await _getLocationId(data['location']);
      }

      // Parse time correctly - it could be a Map with hour/minute or a string
      TimeOfDay? parsedTime;
      if (data['time'] != null) {
        if (data['time'] is Map) {
          final timeMap = data['time'] as Map<String, dynamic>;
          parsedTime = TimeOfDay(
            hour: timeMap['hour'] as int,
            minute: timeMap['minute'] as int,
          );
        } else if (data['time'] is String) {
          // Handle string format like "14:30"
          final parts = (data['time'] as String).split(':');
          if (parts.length == 2) {
            parsedTime = TimeOfDay(
              hour: int.parse(parts[0]),
              minute: int.parse(parts[1]),
            );
          }
        }
      }

      // Get officials list ID if provided by name
      int? officialsListId;
      if (data['officialsListName'] != null) {
        officialsListId = await _getOfficialsListId(data['officialsListName']);
      }

      final template = GameTemplate(
        id: templateId,
        name: data['name'],
        sportId: sportId,
        userId: userId,
        scheduleName: data['scheduleName'],
        date: data['date'] != null ? DateTime.parse(data['date']) : null,
        time: parsedTime,
        locationId: locationId,
        opponent: data['opponent'],
        isAwayGame: data['isAwayGame'] ?? false,
        levelOfCompetition: data['levelOfCompetition'],
        gender: data['gender'],
        officialsRequired: data['officialsRequired'],
        gameFee: data['gameFee'],
        hireAutomatically: data['hireAutomatically'],
        method: data['method'],
        officialsListId: officialsListId,
        selectedOfficials: data['selectedOfficials'],
        officialsListName: data['officialsListName'],
        includeScheduleName: data['includeScheduleName'] ?? false,
        includeSport: data['includeSport'] ?? false,
        includeDate: data['includeDate'] ?? false,
        includeTime: data['includeTime'] ?? false,
        includeLocation: data['includeLocation'] ?? false,
        includeIsAwayGame: data['includeIsAwayGame'] ?? false,
        includeLevelOfCompetition: data['includeLevelOfCompetition'] ?? false,
        includeGender: data['includeGender'] ?? false,
        includeOfficialsRequired: data['includeOfficialsRequired'] ?? false,
        includeGameFee: data['includeGameFee'] ?? false,
        includeOpponent: data['includeOpponent'] ?? false,
        includeHireAutomatically: data['includeHireAutomatically'] ?? false,
        includeSelectedOfficials: data['includeSelectedOfficials'] ?? false,
        includeOfficialsList: data['includeOfficialsList'] ?? false,
        createdAt: DateTime.now(),
      );

      debugPrint('UpdateTemplate - About to call updateGameTemplate with template: ${template.name}, id: ${template.id}');
      await _templateRepository.updateGameTemplate(template);
      debugPrint('UpdateTemplate - Successfully updated template');
      return true;
    } catch (e) {
      debugPrint('Error updating template: $e');
      debugPrint('Error stack trace: ${StackTrace.current}');
      return false;
    }
  }

  // Create game from template
  Future<Map<String, dynamic>?> createGameFromTemplate(int templateId, int userId) async {
    try {
      final template = await _templateRepository.getTemplateById(templateId);
      if (template == null) {
        return null;
      }

      final gameData = await _templateRepository.createGameFromTemplate(template, userId);
      return await createGame(gameData);
    } catch (e) {
      debugPrint('Error creating game from template: $e');
      return null;
    }
  }

  // HELPER METHODS

  // Get sport ID by name
  Future<int?> _getSportId(String? sportName) async {
    if (sportName == null) return null;
    final sport = await _sportRepository.getSportByName(sportName);
    return sport?.id;
  }

  // Get schedule ID by name and sport
  Future<int?> _getScheduleId(String scheduleName, int sportId) async {
    final userId = await _getCurrentUserId();
    var schedule = await _scheduleRepository.getScheduleByName(userId, scheduleName, sportId);
    
    // If schedule doesn't exist, create it
    if (schedule == null) {
      try {
        final newSchedule = Schedule(
          name: scheduleName,
          sportId: sportId,
          userId: userId,
          createdAt: DateTime.now(),
        );
        final scheduleId = await _scheduleRepository.createSchedule(newSchedule);
        schedule = await _scheduleRepository.getScheduleById(scheduleId);
        debugPrint('Created new schedule: $scheduleName with ID: $scheduleId');
      } catch (e) {
        debugPrint('Error creating schedule: $e');
        return null;
      }
    }
    
    return schedule?.id;
  }

  // Get location ID by name
  Future<int?> _getLocationId(String locationName) async {
    final userId = await _getCurrentUserId();
    final locations = await _locationRepository.getLocationsByUser(userId);
    final location = locations.firstWhere(
      (loc) => loc.name == locationName,
      orElse: () => locations.first,
    );
    return location.id;
  }

  // Get officials list ID by name from SharedPreferences
  Future<int?> _getOfficialsListId(String listName) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? listsJson = prefs.getString('saved_lists');
      
      if (listsJson == null || listsJson.isEmpty) {
        return null;
      }
      
      final List<dynamic> lists = jsonDecode(listsJson);
      
      for (final list in lists) {
        if (list['name'] == listName && list['id'] != null) {
          return (list['id'] as int?) ?? 0;
        }
      }
      
      return null;
    } catch (e) {
      debugPrint('Error getting officials list ID: $e');
      return null;
    }
  }

  // Convert Game model to Map for UI
  Map<String, dynamic> _gameToMap(Game game) {
    return {
      'id': game.id,
      'scheduleName': game.scheduleName,
      'sport': game.sportName,
      'date': game.date,
      'time': game.time,
      'location': game.locationName,
      'isAway': game.isAway,
      'levelOfCompetition': game.levelOfCompetition,
      'gender': game.gender,
      'officialsRequired': game.officialsRequired,
      'officialsHired': game.officialsHired,
      'gameFee': game.gameFee,
      'opponent': game.opponent,
      'homeTeam': game.homeTeam,
      'hireAutomatically': game.hireAutomatically,
      'method': game.method,
      'status': game.status,
      'createdAt': game.createdAt,
      'updatedAt': game.updatedAt,
    };
  }

  // Enhanced version that includes officials selection data
  Future<Map<String, dynamic>> _gameToMapWithOfficials(Game game) async {
    final gameMap = _gameToMap(game);
    
    // Try to reconstruct officials selection data based on method
    if (game.method != null) {
      try {
        if (game.method == 'use_list') {
          // For use_list method, try to find the most likely list that was used
          final prefs = await SharedPreferences.getInstance();
          final String? listsJson = prefs.getString('saved_lists');
          if (listsJson != null && listsJson.isNotEmpty) {
            final List<Map<String, dynamic>> savedLists = 
                List<Map<String, dynamic>>.from(jsonDecode(listsJson));
            
            // Try to find the most appropriate list
            Map<String, dynamic>? bestList;
            
            // Look for lists that match the sport and have enough officials
            for (var list in savedLists) {
              final officials = List<Map<String, dynamic>>.from(list['officials'] ?? []);
              
              // Check if the list has enough officials for this game
              if (officials.length >= (game.officialsRequired ?? 1)) {
                // TODO: In a future update, we could also check if the sport matches
                bestList = list;
                break;
              }
            }
            
            // Fallback to first available list if none match criteria
            bestList ??= savedLists.isNotEmpty ? savedLists.first : null;
            
            if (bestList != null) {
              gameMap['selectedListName'] = bestList['name'];
              gameMap['selectedOfficials'] = List<Map<String, dynamic>>.from(
                bestList['officials'] ?? []
              );
            }
          }
        } else if (game.method == 'advanced') {
          // For advanced method, try to reconstruct from the most recent creation
          // Check SharedPreferences for recently used advanced selection data
          final prefs = await SharedPreferences.getInstance();
          final String? recentAdvancedData = prefs.getString('recent_advanced_selection_${game.id}');
          if (recentAdvancedData != null) {
            try {
              final data = jsonDecode(recentAdvancedData);
              gameMap['selectedLists'] = data['selectedLists'] ?? [];
              gameMap['selectedOfficials'] = data['selectedOfficials'] ?? [];
            } catch (e) {
              debugPrint('Error parsing recent advanced selection data: $e');
              gameMap['selectedLists'] = [];
            }
          } else {
            gameMap['selectedLists'] = [];
          }
        } else if (game.method == 'manual') {
          // For manual method, we could load officials from game_officials relationship
          gameMap['selectedOfficials'] = [];
        }
      } catch (e) {
        debugPrint('Error reconstructing officials data: $e');
      }
    }
    
    // Ensure these fields exist (even if empty) to prevent null errors
    gameMap['selectedOfficials'] ??= <Map<String, dynamic>>[];
    gameMap['selectedLists'] ??= <Map<String, dynamic>>[];
    
    return gameMap;
  }

  // Fix templates that have officialsListId but missing officialsListName
  Future<List<GameTemplate>> _fixTemplatesWithMissingListNames(List<GameTemplate> templates) async {
    try {
      // Load officials lists from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final String? listsJson = prefs.getString('saved_lists');
      
      if (listsJson == null || listsJson.isEmpty) {
        return templates; // No lists to fix with
      }
      
      final List<dynamic> lists = jsonDecode(listsJson);
      final Map<int, String> listIdToName = {};
      
      // Create a mapping of list ID to list name
      for (final list in lists) {
        if (list['id'] != null && list['name'] != null) {
          listIdToName[list['id'] as int] = list['name'] as String;
        }
      }
      
      // Fix templates with missing list names
      return templates.map((template) {
        if (template.officialsListId != null && 
            (template.officialsListName == null || template.officialsListName == 'null')) {
          final listName = listIdToName[template.officialsListId!];
          if (listName != null) {
            return GameTemplate(
              id: template.id,
              name: template.name,
              sportId: template.sportId,
              userId: template.userId,
              scheduleName: template.scheduleName,
              date: template.date,
              time: template.time,
              locationId: template.locationId,
              isAwayGame: template.isAwayGame,
              levelOfCompetition: template.levelOfCompetition,
              gender: template.gender,
              officialsRequired: template.officialsRequired,
              gameFee: template.gameFee,
              opponent: template.opponent,
              hireAutomatically: template.hireAutomatically,
              method: template.method,
              officialsListId: template.officialsListId,
              selectedOfficials: template.selectedOfficials,
              includeScheduleName: template.includeScheduleName,
              includeSport: template.includeSport,
              includeDate: template.includeDate,
              includeTime: template.includeTime,
              includeLocation: template.includeLocation,
              includeIsAwayGame: template.includeIsAwayGame,
              includeLevelOfCompetition: template.includeLevelOfCompetition,
              includeGender: template.includeGender,
              includeOfficialsRequired: template.includeOfficialsRequired,
              includeGameFee: template.includeGameFee,
              includeOpponent: template.includeOpponent,
              includeHireAutomatically: template.includeHireAutomatically,
              includeSelectedOfficials: template.includeSelectedOfficials,
              includeOfficialsList: template.includeOfficialsList,
              createdAt: template.createdAt,
              sportName: template.sportName,
              locationName: template.locationName,
              officialsListName: listName, // Fix the missing name
            );
          }
        }
        return template; // Return unchanged if no fix needed
      }).toList();
    } catch (e) {
      debugPrint('Error fixing template list names: $e');
      return templates; // Return original templates if fixing fails
    }
  }

  // Convert GameTemplate model to Map for UI
  Map<String, dynamic> _templateToMap(GameTemplate template) {
    return {
      'id': template.id?.toString(), // Convert int to string for UI
      'name': template.name,
      'sport': template.sportName, // Use sportName from database model
      'scheduleName': template.scheduleName,
      'date': template.date?.toIso8601String(), // Convert DateTime to string
      'time': template.time != null ? '${template.time!.hour.toString().padLeft(2, '0')}:${template.time!.minute.toString().padLeft(2, '0')}' : null, // Convert TimeOfDay to string
      'location': template.locationName, // Use locationName from database model
      'isAwayGame': template.isAwayGame,
      'levelOfCompetition': template.levelOfCompetition,
      'gender': template.gender,
      'officialsRequired': template.officialsRequired,
      'gameFee': template.gameFee,
      'opponent': template.opponent,
      'hireAutomatically': template.hireAutomatically,
      'method': template.method,
      'officialsListName': template.officialsListName, // Add this for UI compatibility
      'includeScheduleName': template.includeScheduleName,
      'includeSport': template.includeSport,
      'includeDate': template.includeDate,
      'includeTime': template.includeTime,
      'includeLocation': template.includeLocation,
      'includeIsAwayGame': template.includeIsAwayGame,
      'includeLevelOfCompetition': template.includeLevelOfCompetition,
      'includeGender': template.includeGender,
      'includeOfficialsRequired': template.includeOfficialsRequired,
      'includeGameFee': template.includeGameFee,
      'includeOpponent': template.includeOpponent,
      'includeHireAutomatically': template.includeHireAutomatically,
      'includeSelectedOfficials': template.includeSelectedOfficials,
      'includeOfficialsList': template.includeOfficialsList,
      'createdAt': template.createdAt?.toIso8601String(),
      'selectedOfficials': template.selectedOfficials,
    };
  }

  // Store selectedLists data for a template
  Future<void> _storeTemplateSelectedLists(int templateId, List<dynamic> selectedLists) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'template_selectedLists_$templateId';
      await prefs.setString(key, jsonEncode(selectedLists));
    } catch (e) {
      debugPrint('Error storing template selectedLists: $e');
    }
  }

  // Retrieve selectedLists data for a template
  Future<List<Map<String, dynamic>>?> _getTemplateSelectedLists(int templateId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'template_selectedLists_$templateId';
      final data = prefs.getString(key);
      if (data != null) {
        return List<Map<String, dynamic>>.from(jsonDecode(data));
      }
    } catch (e) {
      debugPrint('Error retrieving template selectedLists: $e');
    }
    return null;
  }
}