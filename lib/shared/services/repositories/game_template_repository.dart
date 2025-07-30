import 'package:flutter/material.dart';
import '../../models/database_models.dart';
import 'base_repository.dart';

class GameTemplateRepository extends BaseRepository {
  static const String tableName = 'game_templates';

  // Create a new game template
  Future<int> createGameTemplate(GameTemplate template) async {
    return await insert(tableName, template.toMap());
  }

  // Update an existing game template
  Future<int> updateGameTemplate(GameTemplate template) async {
    if (template.id == null)
      throw ArgumentError('Template ID cannot be null for update');

    return await update(
      tableName,
      template.toMap(),
      'id = ?',
      [template.id],
    );
  }

  // Delete a game template
  Future<int> deleteGameTemplate(int templateId) async {
    return await delete(tableName, 'id = ?', [templateId]);
  }

  // Get template by ID with joined data
  Future<GameTemplate?> getTemplateById(int templateId) async {
    final results = await rawQuery('''
      SELECT gt.*, 
             sp.name as sport_name,
             l.name as location_name,
             ol.name as officials_list_name,
             gt.selected_lists as selected_lists
      FROM game_templates gt
      LEFT JOIN sports sp ON gt.sport_id = sp.id
      LEFT JOIN locations l ON gt.location_id = l.id
      LEFT JOIN official_lists ol ON gt.officials_list_id = ol.id
      WHERE gt.id = ?
    ''', [templateId]);

    if (results.isEmpty) return null;

    return GameTemplate.fromMap(results.first);
  }

  // Get all templates for a user
  Future<List<GameTemplate>> getTemplatesByUser(int userId) async {
    final results = await rawQuery('''
      SELECT gt.*, 
             sp.name as sport_name,
             l.name as location_name,
             ol.name as officials_list_name,
             gt.selected_lists as selected_lists
      FROM game_templates gt
      LEFT JOIN sports sp ON gt.sport_id = sp.id
      LEFT JOIN locations l ON gt.location_id = l.id
      LEFT JOIN official_lists ol ON gt.officials_list_id = ol.id
      WHERE gt.user_id = ?
      ORDER BY gt.name ASC
    ''', [userId]);

    return results.map((map) => GameTemplate.fromMap(map)).toList();
  }

  // Get templates by sport for a user
  Future<List<GameTemplate>> getTemplatesBySport(
      int userId, int sportId) async {
    final results = await rawQuery('''
      SELECT gt.*, 
             sp.name as sport_name,
             l.name as location_name,
             ol.name as officials_list_name,
             gt.selected_lists as selected_lists
      FROM game_templates gt
      LEFT JOIN sports sp ON gt.sport_id = sp.id
      LEFT JOIN locations l ON gt.location_id = l.id
      LEFT JOIN official_lists ol ON gt.officials_list_id = ol.id
      WHERE gt.user_id = ? AND gt.sport_id = ?
      ORDER BY gt.name ASC
    ''', [userId, sportId]);

    return results.map((map) => GameTemplate.fromMap(map)).toList();
  }

  // Get templates by name search (kept for backward compatibility)
  Future<List<GameTemplate>> searchTemplatesByName(
      int userId, String searchTerm) async {
    // Use the enhanced search method
    return await getTemplatesByNameSearch(userId, searchTerm);
  }

  // Check if template name already exists for user
  Future<bool> doesTemplateExist(int userId, String name,
      {int? excludeId}) async {
    String whereClause = 'user_id = ? AND name = ?';
    List<dynamic> whereArgs = [userId, name];

    if (excludeId != null) {
      whereClause += ' AND id != ?';
      whereArgs.add(excludeId);
    }

    final results = await query(
      tableName,
      where: whereClause,
      whereArgs: whereArgs,
      limit: 1,
    );

    return results.isNotEmpty;
  }

  // Get template count for a user
  Future<int> getTemplateCount(int userId) async {
    final results = await rawQuery('''
      SELECT COUNT(*) as count
      FROM game_templates 
      WHERE user_id = ?
    ''', [userId]);

    return results.first['count'] as int;
  }

  // Get template count by sport for a user
  Future<Map<String, int>> getTemplateCountBySport(int userId) async {
    final results = await rawQuery('''
      SELECT sp.name as sport_name, COUNT(*) as count
      FROM game_templates gt
      LEFT JOIN sports sp ON gt.sport_id = sp.id
      WHERE gt.user_id = ?
      GROUP BY sp.name
      ORDER BY sp.name ASC
    ''', [userId]);

    final counts = <String, int>{};
    for (var result in results) {
      counts[result['sport_name'] as String] = result['count'] as int;
    }

    return counts;
  }

  // Create game from template with transaction and database insertion
  Future<Map<String, dynamic>> createGameFromTemplate(
      GameTemplate template, int userId) async {
    Map<String, dynamic>? gameResult;

    await withTransaction((txn) async {
      // Prepare game data for database insertion
      final gameData = <String, dynamic>{
        'user_id': userId,
        'sport_id': template.sportId,
        'status': 'Unpublished',
        'is_away':
            template.includeIsAwayGame ? (template.isAwayGame ? 1 : 0) : 0,
        'officials_required': template.includeOfficialsRequired
            ? (template.officialsRequired ?? 1)
            : 1,
        'officials_hired': 0,
        'created_at': DateTime.now().toIso8601String(),
      };

      // Add fields based on template includes
      if (template.includeScheduleName && template.scheduleName != null) {
        gameData['schedule_name'] = template.scheduleName;
      }

      if (template.includeDate && template.date != null) {
        gameData['date'] = template.date!.toIso8601String();
      }

      if (template.includeTime && template.time != null) {
        // Store time as minutes since midnight for database
        final timeMinutes = template.time!.hour * 60 + template.time!.minute;
        gameData['time'] = timeMinutes;
      }

      if (template.includeLocation && template.locationId != null) {
        gameData['location_id'] = template.locationId;
      }

      if (template.includeLevelOfCompetition &&
          template.levelOfCompetition != null) {
        gameData['level_of_competition'] = template.levelOfCompetition;
      }

      if (template.includeGender && template.gender != null) {
        gameData['gender'] = template.gender;
      }

      if (template.includeGameFee && template.gameFee != null) {
        gameData['game_fee'] = template.gameFee;
      }

      if (template.includeOpponent && template.opponent != null) {
        gameData['opponent'] = template.opponent;
      }

      // Note: homeTeam not available in GameTemplate model

      if (template.includeHireAutomatically) {
        gameData['hire_automatically'] =
            (template.hireAutomatically ?? false) ? 1 : 0;
      }

      // Always include the method if it exists
      if (template.method != null) {
        gameData['method'] = template.method;
      }

      // Insert game into database
      final gameId = await txn.insert('games', gameData);

      // Fetch the complete game record with joined data
      final gameResults = await txn.rawQuery('''
        SELECT g.*, 
               sp.name as sport_name,
               l.name as location_name,
               l.address as location_address
        FROM games g
        LEFT JOIN sports sp ON g.sport_id = sp.id
        LEFT JOIN locations l ON g.location_id = l.id
        WHERE g.id = ?
      ''', [gameId]);

      if (gameResults.isNotEmpty) {
        gameResult = Map<String, dynamic>.from(gameResults.first);
        gameResult!['id'] = gameId;

        // Convert time back to TimeOfDay format for display
        if (gameResult!['time'] != null) {
          final timeMinutes = gameResult!['time'] as int;
          final hour = timeMinutes ~/ 60;
          final minute = timeMinutes % 60;
          gameResult!['time'] = TimeOfDay(hour: hour, minute: minute);
        }

        // Convert date string back to DateTime
        if (gameResult!['date'] != null) {
          gameResult!['date'] = DateTime.parse(gameResult!['date'] as String);
        }
      }
    });

    if (gameResult == null) {
      throw Exception('Failed to create game from template');
    }

    return gameResult!;
  }

  // Bulk delete templates
  Future<void> bulkDeleteTemplates(List<int> templateIds) async {
    if (templateIds.isEmpty) return;

    final placeholders = templateIds.map((_) => '?').join(',');
    await rawDelete('''
      DELETE FROM game_templates 
      WHERE id IN ($placeholders)
    ''', templateIds);
  }

  // Get recent templates (last 10 used)
  Future<List<GameTemplate>> getRecentTemplates(int userId) async {
    final results = await rawQuery('''
      SELECT gt.*, 
             sp.name as sport_name,
             l.name as location_name,
             ol.name as officials_list_name,
             gt.selected_lists as selected_lists
      FROM game_templates gt
      LEFT JOIN sports sp ON gt.sport_id = sp.id
      LEFT JOIN locations l ON gt.location_id = l.id
      LEFT JOIN official_lists ol ON gt.officials_list_id = ol.id
      WHERE gt.user_id = ?
      ORDER BY gt.created_at DESC
      LIMIT 10
    ''', [userId]);

    return results.map((map) => GameTemplate.fromMap(map)).toList();
  }

  // Batch create templates using base repository batchInsert
  Future<List<int>> batchCreateTemplates(List<GameTemplate> templates) async {
    if (templates.isEmpty) return [];

    // Convert templates to maps
    final templateMaps = templates.map((template) => template.toMap()).toList();

    return await batchInsert(tableName, templateMaps);
  }

  // Enhanced search by name and sport
  Future<List<GameTemplate>> getTemplatesByNameSearch(
      int userId, String term) async {
    final results = await rawQuery('''
      SELECT gt.*, 
             sp.name as sport_name,
             l.name as location_name,
             ol.name as officials_list_name,
             gt.selected_lists as selected_lists
      FROM game_templates gt
      LEFT JOIN sports sp ON gt.sport_id = sp.id
      LEFT JOIN locations l ON gt.location_id = l.id
      LEFT JOIN official_lists ol ON gt.officials_list_id = ol.id
      WHERE gt.user_id = ? 
        AND (gt.name LIKE ? OR sp.name LIKE ?)
      ORDER BY gt.name ASC
    ''', [userId, '%$term%', '%$term%']);

    return results.map((map) => GameTemplate.fromMap(map)).toList();
  }

  // Enhanced search with multiple filters
  Future<List<GameTemplate>> searchTemplates({
    required int userId,
    String? nameFilter,
    int? sportId,
    String? levelOfCompetition,
    bool? isAwayGame,
  }) async {
    String whereClause = 'gt.user_id = ?';
    List<dynamic> whereArgs = [userId];

    if (nameFilter != null && nameFilter.isNotEmpty) {
      whereClause += ' AND (gt.name LIKE ? OR sp.name LIKE ?)';
      whereArgs.addAll(['%$nameFilter%', '%$nameFilter%']);
    }

    if (sportId != null) {
      whereClause += ' AND gt.sport_id = ?';
      whereArgs.add(sportId);
    }

    if (levelOfCompetition != null && levelOfCompetition.isNotEmpty) {
      whereClause += ' AND gt.level_of_competition = ?';
      whereArgs.add(levelOfCompetition);
    }

    if (isAwayGame != null) {
      whereClause += ' AND gt.is_away_game = ?';
      whereArgs.add(isAwayGame ? 1 : 0);
    }

    final results = await rawQuery('''
      SELECT gt.*, 
             sp.name as sport_name,
             l.name as location_name,
             ol.name as officials_list_name,
             gt.selected_lists as selected_lists
      FROM game_templates gt
      LEFT JOIN sports sp ON gt.sport_id = sp.id
      LEFT JOIN locations l ON gt.location_id = l.id
      LEFT JOIN official_lists ol ON gt.officials_list_id = ol.id
      WHERE $whereClause
      ORDER BY gt.name ASC
    ''', whereArgs);

    return results.map((map) => GameTemplate.fromMap(map)).toList();
  }
}
