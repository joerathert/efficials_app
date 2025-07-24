import 'package:flutter/material.dart';
import '../../models/database_models.dart';
import 'base_repository.dart';

class GameRepository extends BaseRepository {
  static const String tableName = 'games';

  // Create a new game
  Future<int> createGame(Game game) async {
    final gameMap = game.toMap();
    return await insert(tableName, gameMap);
  }

  // Update an existing game
  Future<int> updateGame(Game game) async {
    if (game.id == null) throw ArgumentError('Game ID cannot be null for update');
    
    final updatedGame = game.copyWith(updatedAt: DateTime.now());
    return await update(
      tableName,
      updatedGame.toMap(),
      'id = ?',
      [game.id],
    );
  }

  // Delete a game
  Future<int> deleteGame(int gameId) async {
    // First delete game officials relationships
    await delete('game_officials', 'game_id = ?', [gameId]);
    
    // Then delete the game
    return await delete(tableName, 'id = ?', [gameId]);
  }

  // Get game by ID with joined data
  Future<Game?> getGameById(int gameId) async {
    final results = await rawQuery('''
      SELECT g.id, g.schedule_id, g.sport_id, g.location_id, g.user_id,
             g.date, g.time, g.is_away, g.level_of_competition, g.gender,
             g.officials_required, g.officials_hired, g.game_fee, g.opponent,
             g.home_team, g.hire_automatically, g.method, g.status,
             g.created_at, g.updated_at,
             s.name as schedule_name,
             sp.name as sport_name,
             l.name as location_name
      FROM games g
      LEFT JOIN schedules s ON g.schedule_id = s.id
      LEFT JOIN sports sp ON g.sport_id = sp.id
      LEFT JOIN locations l ON g.location_id = l.id
      WHERE g.id = ?
    ''', [gameId]);

    if (results.isEmpty) return null;

    final game = Game.fromMap(results.first);
    
    // Load assigned officials
    final officials = await getGameOfficials(gameId);
    
    return game.copyWith(assignedOfficials: officials);
  }

  // Get all games for a user
  Future<List<Game>> getGamesByUser(int userId, {String? status}) async {
    String whereClause = 'g.user_id = ?';
    List<dynamic> whereArgs = [userId];

    if (status != null) {
      whereClause += ' AND g.status = ?';
      whereArgs.add(status);
    }

    final results = await rawQuery('''
      SELECT g.id, g.schedule_id, g.sport_id, g.location_id, g.user_id,
             g.date, g.time, g.is_away, g.level_of_competition, g.gender,
             g.officials_required, g.officials_hired, g.game_fee, g.opponent,
             g.home_team, g.hire_automatically, g.method, g.status,
             g.created_at, g.updated_at,
             s.name as schedule_name,
             sp.name as sport_name,
             l.name as location_name
      FROM games g
      LEFT JOIN schedules s ON g.schedule_id = s.id
      LEFT JOIN sports sp ON g.sport_id = sp.id
      LEFT JOIN locations l ON g.location_id = l.id
      WHERE $whereClause
      ORDER BY g.date ASC, g.time ASC
    ''', whereArgs);

    return results.map((map) => Game.fromMap(map)).toList();
  }

  // Get games by schedule
  Future<List<Game>> getGamesBySchedule(int scheduleId) async {
    final results = await rawQuery('''
      SELECT g.*, 
             s.name as schedule_name,
             sp.name as sport_name,
             l.name as location_name
      FROM games g
      LEFT JOIN schedules s ON g.schedule_id = s.id
      LEFT JOIN sports sp ON g.sport_id = sp.id
      LEFT JOIN locations l ON g.location_id = l.id
      WHERE g.schedule_id = ?
      ORDER BY g.date ASC, g.time ASC
    ''', [scheduleId]);

    return results.map((map) => Game.fromMap(map)).toList();
  }

  // Get games by sport for a user
  Future<List<Game>> getGamesBySport(int userId, int sportId, {String? status}) async {
    String whereClause = 'g.user_id = ? AND g.sport_id = ?';
    List<dynamic> whereArgs = [userId, sportId];

    if (status != null) {
      whereClause += ' AND g.status = ?';
      whereArgs.add(status);
    }

    final results = await rawQuery('''
      SELECT g.*, 
             s.name as schedule_name,
             sp.name as sport_name,
             l.name as location_name
      FROM games g
      LEFT JOIN schedules s ON g.schedule_id = s.id
      LEFT JOIN sports sp ON g.sport_id = sp.id
      LEFT JOIN locations l ON g.location_id = l.id
      WHERE $whereClause
      ORDER BY g.date ASC, g.time ASC
    ''', whereArgs);

    return results.map((map) => Game.fromMap(map)).toList();
  }

  // Get upcoming games for a user
  Future<List<Game>> getUpcomingGames(int userId) async {
    final today = DateTime.now();
    final todayString = DateTime(today.year, today.month, today.day).toIso8601String();

    final results = await rawQuery('''
      SELECT g.*, 
             s.name as schedule_name,
             sp.name as sport_name,
             l.name as location_name
      FROM games g
      LEFT JOIN schedules s ON g.schedule_id = s.id
      LEFT JOIN sports sp ON g.sport_id = sp.id
      LEFT JOIN locations l ON g.location_id = l.id
      WHERE g.user_id = ? AND g.date >= ? AND g.status = 'Published'
      ORDER BY g.date ASC, g.time ASC
    ''', [userId, todayString]);

    return results.map((map) => Game.fromMap(map)).toList();
  }

  // Get past games for a user
  Future<List<Game>> getPastGames(int userId) async {
    final today = DateTime.now();
    final todayString = DateTime(today.year, today.month, today.day).toIso8601String();

    final results = await rawQuery('''
      SELECT g.*, 
             s.name as schedule_name,
             sp.name as sport_name,
             l.name as location_name
      FROM games g
      LEFT JOIN schedules s ON g.schedule_id = s.id
      LEFT JOIN sports sp ON g.sport_id = sp.id
      LEFT JOIN locations l ON g.location_id = l.id
      WHERE g.user_id = ? AND g.date < ? AND g.status = 'Published'
      ORDER BY g.date DESC, g.time DESC
    ''', [userId, todayString]);

    return results.map((map) => Game.fromMap(map)).toList();
  }

  // Get games with filtering options
  Future<List<Game>> getFilteredGames(
    int userId, {
    bool? showAwayGames,
    bool? showFullyCoveredGames,
    Map<String, Map<String, bool>>? scheduleFilters,
    String? status,
  }) async {
    String whereClause = 'g.user_id = ?';
    List<dynamic> whereArgs = [userId];

    if (status != null) {
      whereClause += ' AND g.status = ?';
      whereArgs.add(status);
    }

    if (showAwayGames == false) {
      whereClause += ' AND g.is_away = 0';
    }

    if (showFullyCoveredGames == false) {
      whereClause += ' AND g.officials_hired < g.officials_required';
    }

    final results = await rawQuery('''
      SELECT g.*, 
             s.name as schedule_name,
             sp.name as sport_name,
             l.name as location_name
      FROM games g
      LEFT JOIN schedules s ON g.schedule_id = s.id
      LEFT JOIN sports sp ON g.sport_id = sp.id
      LEFT JOIN locations l ON g.location_id = l.id
      WHERE $whereClause
      ORDER BY g.date ASC, g.time ASC
    ''', whereArgs);

    List<Game> games = results.map((map) => Game.fromMap(map)).toList();

    // Apply schedule filters if provided
    if (scheduleFilters != null && scheduleFilters.isNotEmpty) {
      games = games.where((game) {
        if (game.scheduleName == null || game.sportName == null) return false;
        
        final sportFilters = scheduleFilters[game.sportName!];
        if (sportFilters == null) return false;
        
        return sportFilters[game.scheduleName!] == true;
      }).toList();
    }

    return games;
  }

  // Assign official to game
  Future<void> assignOfficialToGame(int gameId, int officialId) async {
    await insert('game_officials', {
      'game_id': gameId,
      'official_id': officialId,
    });

    // Update officials hired count
    await rawUpdate('''
      UPDATE games 
      SET officials_hired = (
        SELECT COUNT(*) 
        FROM game_officials 
        WHERE game_id = ?
      ),
      updated_at = ?
      WHERE id = ?
    ''', [gameId, DateTime.now().toIso8601String(), gameId]);
  }

  // Remove official from game
  Future<void> removeOfficialFromGame(int gameId, int officialId) async {
    await delete('game_officials', 'game_id = ? AND official_id = ?', [gameId, officialId]);

    // Update officials hired count
    await rawUpdate('''
      UPDATE games 
      SET officials_hired = (
        SELECT COUNT(*) 
        FROM game_officials 
        WHERE game_id = ?
      ),
      updated_at = ?
      WHERE id = ?
    ''', [gameId, DateTime.now().toIso8601String(), gameId]);
  }

  // Get officials assigned to a game
  Future<List<Official>> getGameOfficials(int gameId) async {
    final results = await rawQuery('''
      SELECT o.*, sp.name as sport_name
      FROM officials o
      LEFT JOIN sports sp ON o.sport_id = sp.id
      INNER JOIN game_officials go ON o.id = go.official_id
      WHERE go.game_id = ?
      ORDER BY o.name ASC
    ''', [gameId]);

    return results.map((map) => Official.fromMap(map)).toList();
  }

  // Update game status
  Future<int> updateGameStatus(int gameId, String status) async {
    return await update(
      tableName,
      {
        'status': status,
        'updated_at': DateTime.now().toIso8601String(),
      },
      'id = ?',
      [gameId],
    );
  }

  // Update officials hired count
  Future<int> updateOfficialsHired(int gameId, int officialsHired) async {
    return await update(
      tableName,
      {
        'officials_hired': officialsHired,
        'updated_at': DateTime.now().toIso8601String(),
      },
      'id = ?',
      [gameId],
    );
  }

  // Bulk update games status
  Future<void> bulkUpdateGameStatus(List<int> gameIds, String status) async {
    if (gameIds.isEmpty) return;

    final placeholders = gameIds.map((_) => '?').join(',');
    await rawUpdate('''
      UPDATE games 
      SET status = ?, updated_at = ?
      WHERE id IN ($placeholders)
    ''', [status, DateTime.now().toIso8601String(), ...gameIds]);
  }

  // Get game statistics for a user
  Future<Map<String, int>> getGameStatistics(int userId) async {
    final results = await rawQuery('''
      SELECT 
        status,
        COUNT(*) as count
      FROM games 
      WHERE user_id = ?
      GROUP BY status
    ''', [userId]);

    final stats = <String, int>{};
    for (var result in results) {
      stats[result['status'] as String] = result['count'] as int;
    }

    return stats;
  }

  // Search games by various criteria
  Future<List<Game>> searchGames(
    int userId,
    String searchTerm, {
    String? status,
  }) async {
    String whereClause = '''
      g.user_id = ? AND (
        s.name LIKE ? OR 
        sp.name LIKE ? OR 
        l.name LIKE ? OR 
        g.opponent LIKE ?
      )
    ''';
    
    List<dynamic> whereArgs = [
      userId,
      '%$searchTerm%',
      '%$searchTerm%',
      '%$searchTerm%',
      '%$searchTerm%',
    ];

    if (status != null) {
      whereClause += ' AND g.status = ?';
      whereArgs.add(status);
    }

    final results = await rawQuery('''
      SELECT g.*, 
             s.name as schedule_name,
             sp.name as sport_name,
             l.name as location_name
      FROM games g
      LEFT JOIN schedules s ON g.schedule_id = s.id
      LEFT JOIN sports sp ON g.sport_id = sp.id
      LEFT JOIN locations l ON g.location_id = l.id
      WHERE $whereClause
      ORDER BY g.date ASC, g.time ASC
    ''', whereArgs);

    return results.map((map) => Game.fromMap(map)).toList();
  }
}