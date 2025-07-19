import 'package:flutter/material.dart';
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
      debugPrint('Found current user with ID: ${user.id}');
      return user.id!;
    }
    
    // If no user exists, create a default Athletic Director user
    debugPrint('No user found, creating default user');
    try {
      final defaultUser = User(
        schedulerType: 'Athletic Director',
        setupCompleted: true,
        schoolName: 'Default School',
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
  Future<List<Map<String, dynamic>>> getGames({String? status}) async {
    try {
      final userId = await _getCurrentUserId();
      final games = await _gameRepository.getGamesByUser(userId, status: status);
      
      // Convert to the format expected by the UI
      return games.map((game) => _gameToMap(game)).toList();
    } catch (e) {
      debugPrint('Error getting games: $e');
      return [];
    }
  }

  // Get published games
  Future<List<Map<String, dynamic>>> getPublishedGames() async {
    return await getGames(status: 'Published');
  }

  // Get unpublished games
  Future<List<Map<String, dynamic>>> getUnpublishedGames() async {
    return await getGames(status: 'Unpublished');
  }

  // Get filtered games
  Future<List<Map<String, dynamic>>> getFilteredGames({
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
      
      return games.map((game) => _gameToMap(game)).toList();
    } catch (e) {
      debugPrint('Error getting filtered games: $e');
      return [];
    }
  }

  // Create a new game
  Future<Map<String, dynamic>?> createGame(Map<String, dynamic> gameData) async {
    try {
      debugPrint('Creating game with data: $gameData');
      final userId = await _getCurrentUserId();
      
      // Get sport ID
      final sportId = await _getSportId(gameData['sport']);
      if (sportId == null) {
        debugPrint('Sport not found: ${gameData['sport']}');
        return null;
      }
      debugPrint('Found sport ID: $sportId for sport: ${gameData['sport']}');

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
        hireAutomatically: gameData['hireAutomatically'] ?? false,
        method: gameData['method'],
        status: gameData['status'] ?? 'Unpublished',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final gameId = await _gameRepository.createGame(game);
      debugPrint('Game created with database ID: $gameId');
      final createdGame = await _gameRepository.getGameById(gameId);
      
      if (createdGame != null) {
        debugPrint('Successfully retrieved created game from database');
        return _gameToMap(createdGame);
      } else {
        debugPrint('Failed to retrieve created game from database');
        return null;
      }
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
        debugPrint('Sport not found: ${gameData['sport']}');
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
      
      return templates.map((template) => _templateToMap(template)).toList();
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
      
      return templates.map((template) => _templateToMap(template)).toList();
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
        officialsListId: templateData['officialsListId'],
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
      final createdTemplate = await _templateRepository.getTemplateById(templateId);
      
      return createdTemplate != null ? _templateToMap(createdTemplate) : null;
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
      
      debugPrint('Cleared ${templates.length} templates for user $userId');
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

      final templateId = int.parse(data['id'].toString());
      final userId = await _getCurrentUserId();
      
      // Get sport ID
      final sportId = await _getSportId(data['sport']);
      if (sportId == null) {
        debugPrint('Sport not found: ${data['sport']}');
        return false;
      }

      // Get location ID if provided
      int? locationId;
      if (data['location'] != null) {
        locationId = await _getLocationId(data['location']);
      }

      final template = GameTemplate(
        id: templateId,
        name: data['name'],
        sportId: sportId,
        userId: userId,
        scheduleName: data['scheduleName'],
        date: data['date'] != null ? DateTime.parse(data['date']) : null,
        time: data['time'] != null ? TimeOfDay.fromDateTime(DateTime.parse('2000-01-01 ${data['time']}')) : null,
        locationId: locationId,
        opponent: data['opponent'],
        isAwayGame: data['isAwayGame'] ?? false,
        levelOfCompetition: data['levelOfCompetition'],
        gender: data['gender'],
        officialsRequired: data['officialsRequired'],
        gameFee: data['gameFee'],
        hireAutomatically: data['hireAutomatically'],
        selectedOfficials: data['selectedOfficials'],
        officialsListName: data['officialsListName'],
        method: data['method'],
        includeSport: data['includeSport'] ?? false,
        includeScheduleName: data['includeScheduleName'] ?? false,
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

      await _templateRepository.updateGameTemplate(template);
      return true;
    } catch (e) {
      debugPrint('Error updating template: $e');
      return false;
    }
  }

  // Create game from template
  Future<Map<String, dynamic>?> createGameFromTemplate(int templateId) async {
    try {
      final template = await _templateRepository.getTemplateById(templateId);
      if (template == null) return null;

      final gameData = await _templateRepository.createGameFromTemplate(template);
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
    final schedule = await _scheduleRepository.getScheduleByName(userId, scheduleName, sportId);
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
      'hireAutomatically': game.hireAutomatically,
      'method': game.method,
      'status': game.status,
      'createdAt': game.createdAt,
      'updatedAt': game.updatedAt,
    };
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
    };
  }
}