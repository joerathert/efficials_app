import 'package:flutter/material.dart';
import '../../models/database_models.dart';
import 'base_repository.dart';

class TeamRepository extends BaseRepository {
  static const String tableName = 'teams';

  // Get all teams for a user
  Future<List<String>> getTeamsByUser(int userId) async {
    try {
      final results = await query(
        tableName,
        where: 'user_id = ?',
        whereArgs: [userId],
        orderBy: 'name ASC',
      );
      
      return results.map((map) => map['name'] as String).toList();
    } catch (e) {
      debugPrint('Error getting teams for user $userId: $e');
      return [];
    }
  }

  // Get all team objects for a user
  Future<List<Team>> getTeamObjectsByUser(int userId) async {
    try {
      final results = await query(
        tableName,
        where: 'user_id = ?',
        whereArgs: [userId],
        orderBy: 'name ASC',
      );
      
      return results.map((map) => Team.fromMap(map)).toList();
    } catch (e) {
      debugPrint('Error getting team objects for user $userId: $e');
      return [];
    }
  }

  // Create a new team
  Future<int> createTeam(String name, int userId) async {
    try {
      // Check if team already exists
      final existing = await query(
        tableName,
        where: 'user_id = ? AND name = ?',
        whereArgs: [userId, name],
        limit: 1,
      );

      if (existing.isNotEmpty) {
        return existing.first['id'] as int;
      }

      final team = Team(
        name: name,
        userId: userId,
        createdAt: DateTime.now(),
      );

      return await insert(tableName, team.toMap());
    } catch (e) {
      debugPrint('Error creating team "$name" for user $userId: $e');
      rethrow;
    }
  }

  // Get team by ID
  Future<Team?> getTeamById(int teamId) async {
    try {
      final results = await query(
        tableName,
        where: 'id = ?',
        whereArgs: [teamId],
        limit: 1,
      );

      if (results.isEmpty) return null;
      return Team.fromMap(results.first);
    } catch (e) {
      debugPrint('Error getting team by ID $teamId: $e');
      return null;
    }
  }

  // Get team by name and user
  Future<Team?> getTeamByName(String name, int userId) async {
    try {
      final results = await query(
        tableName,
        where: 'user_id = ? AND name = ?',
        whereArgs: [userId, name],
        limit: 1,
      );

      if (results.isEmpty) return null;
      return Team.fromMap(results.first);
    } catch (e) {
      debugPrint('Error getting team by name "$name" for user $userId: $e');
      return null;
    }
  }

  // Update a team
  Future<int> updateTeam(Team team) async {
    if (team.id == null) throw ArgumentError('Team ID cannot be null for update');
    
    return await update(
      tableName,
      team.toMap(),
      'id = ?',
      [team.id],
    );
  }

  // Delete a team
  Future<int> deleteTeam(int teamId) async {
    return await delete(tableName, 'id = ?', [teamId]);
  }

  // Check if team exists by name for user
  Future<bool> teamExists(String name, int userId) async {
    final results = await query(
      tableName,
      where: 'user_id = ? AND name = ?',
      whereArgs: [userId, name],
      limit: 1,
    );

    return results.isNotEmpty;
  }

  // Get teams count for user
  Future<int> getTeamsCount(int userId) async {
    final results = await rawQuery(
      'SELECT COUNT(*) as count FROM $tableName WHERE user_id = ?',
      [userId],
    );
    return results.first['count'] as int;
  }

  // Search teams by name for user
  Future<List<Team>> searchTeams(int userId, String searchTerm) async {
    final results = await query(
      tableName,
      where: 'user_id = ? AND name LIKE ?',
      whereArgs: [userId, '%$searchTerm%'],
      orderBy: 'name ASC',
    );

    return results.map((map) => Team.fromMap(map)).toList();
  }
}