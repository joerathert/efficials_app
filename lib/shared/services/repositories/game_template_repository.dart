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
    if (template.id == null) throw ArgumentError('Template ID cannot be null for update');
    
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
             ol.name as officials_list_name
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
             ol.name as officials_list_name
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
  Future<List<GameTemplate>> getTemplatesBySport(int userId, int sportId) async {
    final results = await rawQuery('''
      SELECT gt.*, 
             sp.name as sport_name,
             l.name as location_name,
             ol.name as officials_list_name
      FROM game_templates gt
      LEFT JOIN sports sp ON gt.sport_id = sp.id
      LEFT JOIN locations l ON gt.location_id = l.id
      LEFT JOIN official_lists ol ON gt.officials_list_id = ol.id
      WHERE gt.user_id = ? AND gt.sport_id = ?
      ORDER BY gt.name ASC
    ''', [userId, sportId]);

    return results.map((map) => GameTemplate.fromMap(map)).toList();
  }

  // Get templates by name search
  Future<List<GameTemplate>> searchTemplatesByName(int userId, String searchTerm) async {
    final results = await rawQuery('''
      SELECT gt.*, 
             sp.name as sport_name,
             l.name as location_name,
             ol.name as officials_list_name
      FROM game_templates gt
      LEFT JOIN sports sp ON gt.sport_id = sp.id
      LEFT JOIN locations l ON gt.location_id = l.id
      LEFT JOIN official_lists ol ON gt.officials_list_id = ol.id
      WHERE gt.user_id = ? AND gt.name LIKE ?
      ORDER BY gt.name ASC
    ''', [userId, '%$searchTerm%']);

    return results.map((map) => GameTemplate.fromMap(map)).toList();
  }

  // Check if template name already exists for user
  Future<bool> doesTemplateExist(int userId, String name, {int? excludeId}) async {
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

  // Create game from template
  Future<Map<String, dynamic>> createGameFromTemplate(GameTemplate template) async {
    final gameData = <String, dynamic>{
      'sport_id': template.sportId,
      'user_id': template.userId,
      'status': 'Unpublished',
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    };

    // Add fields based on template includes
    if (template.includeScheduleName && template.scheduleName != null) {
      // Note: Would need to look up or create schedule
      gameData['schedule_name'] = template.scheduleName;
    }

    if (template.includeDate && template.date != null) {
      gameData['date'] = template.date;
    }

    if (template.includeTime && template.time != null) {
      gameData['time'] = template.time?.format(null);
    }

    if (template.includeLocation && template.locationId != null) {
      gameData['location_id'] = template.locationId;
    }

    if (template.includeIsAwayGame) {
      gameData['is_away'] = template.isAwayGame;
    }

    if (template.includeLevelOfCompetition && template.levelOfCompetition != null) {
      gameData['level_of_competition'] = template.levelOfCompetition;
    }

    if (template.includeGender && template.gender != null) {
      gameData['gender'] = template.gender;
    }

    if (template.includeOfficialsRequired && template.officialsRequired != null) {
      gameData['officials_required'] = template.officialsRequired;
    }

    if (template.includeGameFee && template.gameFee != null) {
      gameData['game_fee'] = template.gameFee;
    }

    if (template.includeOpponent && template.opponent != null) {
      gameData['opponent'] = template.opponent;
    }

    if (template.includeHireAutomatically) {
      gameData['hire_automatically'] = template.hireAutomatically;
    }

    return gameData;
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
             ol.name as officials_list_name
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
}