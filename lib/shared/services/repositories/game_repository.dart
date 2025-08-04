import 'package:flutter/foundation.dart';
import '../../models/database_models.dart';
import 'base_repository.dart';

// Custom exception for game repository operations
class GameRepositoryException implements Exception {
  final String message;
  GameRepositoryException(this.message);
  
  @override
  String toString() => 'GameRepositoryException: $message';
}

class GameRepository extends BaseRepository {
  static const String tableName = 'games';

  // Create a new game with transaction support
  Future<int> createGame(Game game) async {
    try {
      final gameMap = game.toMap();
      return await insert(tableName, gameMap);
    } catch (e) {
      debugPrint('Error creating game: $e');
      throw GameRepositoryException('Failed to create game: $e');
    }
  }

  // Batch create multiple games
  Future<List<int>> batchCreateGames(List<Game> games) async {
    try {
      final gamesData = games.map((g) => g.toMap()).toList();
      return await batchInsert(tableName, gamesData);
    } catch (e) {
      debugPrint('Error batch creating games: $e');
      throw GameRepositoryException('Failed to batch create games: $e');
    }
  }

  // Update an existing game
  Future<int> updateGame(Game game) async {
    if (game.id == null) throw ArgumentError('Game ID cannot be null for update');
    
    try {
      final updatedGame = game.copyWith(updatedAt: DateTime.now());
      return await update(
        tableName,
        updatedGame.toMap(),
        'id = ?',
        [game.id],
      );
    } catch (e) {
      debugPrint('Error updating game ${game.id}: $e');
      throw GameRepositoryException('Failed to update game: $e');
    }
  }

  // Delete a game with transaction support
  Future<int> deleteGame(int gameId) async {
    try {
      int deletedRows = 0;
      await withTransaction((txn) async {
        // First delete game officials relationships
        await txn.delete('game_officials', where: 'game_id = ?', whereArgs: [gameId]);
        
        // Then delete the game
        deletedRows = await txn.delete(tableName, where: 'id = ?', whereArgs: [gameId]);
        
        if (deletedRows == 0) {
          throw GameRepositoryException('Game with ID $gameId not found');
        }
      });
      return deletedRows;
    } catch (e) {
      debugPrint('Error deleting game $gameId: $e');
      if (e is GameRepositoryException) rethrow;
      throw GameRepositoryException('Failed to delete game: $e');
    }
  }

  // Get game by ID with joined data
  Future<Game?> getGameById(int gameId) async {
    try {
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
    } catch (e) {
      debugPrint('Error getting game by ID $gameId: $e');
      throw GameRepositoryException('Failed to get game: $e');
    }
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
             s.home_team_name as schedule_home_team_name,
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
        
        final baseSportName = game.sportName!;
        String sportKey = baseSportName;
        
        // For basketball, use gender-specific sport names to match filter keys
        if (baseSportName.toLowerCase() == 'basketball' && game.gender != null) {
          if (game.gender!.toLowerCase() == 'boys' || game.gender!.toLowerCase() == 'male') {
            sportKey = 'Boys Basketball';
          } else if (game.gender!.toLowerCase() == 'girls' || game.gender!.toLowerCase() == 'female') {
            sportKey = 'Girls Basketball';
          }
        }
        
        final sportFilters = scheduleFilters[sportKey];
        if (sportFilters == null) {
          // If sport is not in filters, hide the game - all filters should be explicit
          return false;
        }
        
        final scheduleFilter = sportFilters[game.scheduleName!];
        if (scheduleFilter == null) {
          // If schedule is not in filters, hide the game - all filters should be explicit
          return false;
        }
        
        return scheduleFilter == true;
      }).toList();
    }

    return games;
  }

  // Assign official to game with transaction support
  Future<void> assignOfficialToGame(int gameId, int officialId) async {
    try {
      await withTransaction((txn) async {
        // Check if assignment already exists
        final existing = await txn.query(
          'game_officials',
          where: 'game_id = ? AND official_id = ?',
          whereArgs: [gameId, officialId],
        );
        
        if (existing.isNotEmpty) {
          throw GameRepositoryException('Official $officialId is already assigned to game $gameId');
        }

        // Insert the assignment
        await txn.insert('game_officials', {
          'game_id': gameId,
          'official_id': officialId,
        });

        // Update officials hired count
        await txn.rawUpdate('''
          UPDATE games 
          SET officials_hired = (
            SELECT COUNT(*) 
            FROM game_officials 
            WHERE game_id = ?
          ),
          updated_at = ?
          WHERE id = ?
        ''', [gameId, DateTime.now().toIso8601String(), gameId]);
      });
    } catch (e) {
      debugPrint('Error assigning official $officialId to game $gameId: $e');
      if (e is GameRepositoryException) rethrow;
      throw GameRepositoryException('Failed to assign official to game: $e');
    }
  }

  // Remove official from game with transaction support
  Future<void> removeOfficialFromGame(int gameId, int officialId) async {
    try {
      await withTransaction((txn) async {
        // Delete the assignment
        final deletedRows = await txn.delete(
          'game_officials', 
          where: 'game_id = ? AND official_id = ?', 
          whereArgs: [gameId, officialId]
        );
        
        if (deletedRows == 0) {
          throw GameRepositoryException('Official $officialId is not assigned to game $gameId');
        }

        // Update officials hired count
        await txn.rawUpdate('''
          UPDATE games 
          SET officials_hired = (
            SELECT COUNT(*) 
            FROM game_officials 
            WHERE game_id = ?
          ),
          updated_at = ?
          WHERE id = ?
        ''', [gameId, DateTime.now().toIso8601String(), gameId]);
      });
    } catch (e) {
      debugPrint('Error removing official $officialId from game $gameId: $e');
      if (e is GameRepositoryException) rethrow;
      throw GameRepositoryException('Failed to remove official from game: $e');
    }
  }

  // Get officials assigned to a game
  Future<List<Official>> getGameOfficials(int gameId) async {
    try {
      final results = await rawQuery('''
        SELECT o.*, sp.name as sport_name
        FROM officials o
        LEFT JOIN sports sp ON o.sport_id = sp.id
        INNER JOIN game_officials go ON o.id = go.official_id
        WHERE go.game_id = ?
        ORDER BY o.name ASC
      ''', [gameId]);

      return results.map((map) => Official.fromMap(map)).toList();
    } catch (e) {
      debugPrint('Error getting game officials for game $gameId: $e');
      throw GameRepositoryException('Failed to get game officials: $e');
    }
  }

  // Batch assign multiple officials to a game
  Future<void> batchAssignOfficialsToGame(int gameId, List<int> officialIds) async {
    try {
      await withTransaction((txn) async {
        for (final officialId in officialIds) {
          // Check if assignment already exists
          final existing = await txn.query(
            'game_officials',
            where: 'game_id = ? AND official_id = ?',
            whereArgs: [gameId, officialId],
          );
          
          if (existing.isEmpty) {
            // Insert the assignment
            await txn.insert('game_officials', {
              'game_id': gameId,
              'official_id': officialId,
            });
          }
        }

        // Update officials hired count
        await txn.rawUpdate('''
          UPDATE games 
          SET officials_hired = (
            SELECT COUNT(*) 
            FROM game_officials 
            WHERE game_id = ?
          ),
          updated_at = ?
          WHERE id = ?
        ''', [gameId, DateTime.now().toIso8601String(), gameId]);
      });
    } catch (e) {
      debugPrint('Error batch assigning officials to game $gameId: $e');
      throw GameRepositoryException('Failed to batch assign officials to game: $e');
    }
  }

  // Update game status
  Future<int> updateGameStatus(int gameId, String status) async {
    try {
      return await update(
        tableName,
        {
          'status': status,
          'updated_at': DateTime.now().toIso8601String(),
        },
        'id = ?',
        [gameId],
      );
    } catch (e) {
      debugPrint('Error updating game status for game $gameId: $e');
      throw GameRepositoryException('Failed to update game status: $e');
    }
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

  // Bulk update games status with transaction support
  Future<void> bulkUpdateGameStatus(List<int> gameIds, String status) async {
    if (gameIds.isEmpty) return;

    try {
      await withTransaction((txn) async {
        final placeholders = gameIds.map((_) => '?').join(',');
        await txn.rawUpdate('''
          UPDATE games 
          SET status = ?, updated_at = ?
          WHERE id IN ($placeholders)
        ''', [status, DateTime.now().toIso8601String(), ...gameIds]);
      });
    } catch (e) {
      debugPrint('Error bulk updating game status for games $gameIds: $e');
      throw GameRepositoryException('Failed to bulk update game status: $e');
    }
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