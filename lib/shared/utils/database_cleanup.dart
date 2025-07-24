import '../services/database_helper.dart';
import '../services/repositories/user_repository.dart';

/// Utility class for cleaning up database inconsistencies
class DatabaseCleanup {
  static final DatabaseHelper _db = DatabaseHelper();
  static final UserRepository _userRepo = UserRepository();

  /// Remove games with null home_team values and fix missing home_team fields
  static Future<void> cleanupDuplicateGames() async {
    print('Starting duplicate games cleanup...');
    
    try {
      final database = await _db.database;
      
      // Get current user info to set home_team
      final currentUser = await _userRepo.getCurrentUser();
      String? homeTeam;
      
      if (currentUser != null && 
          currentUser.schoolName != null && 
          currentUser.mascot != null) {
        homeTeam = '${currentUser.schoolName} ${currentUser.mascot}';
      }
      
      // Step 1: Find games with missing home_team and fill them
      if (homeTeam != null) {
        // First count how many need updating
        final countResult = await database.rawQuery('''
          SELECT COUNT(*) as count 
          FROM games 
          WHERE home_team IS NULL OR home_team = '' OR home_team = 'null'
        ''');
        final toUpdateCount = countResult.first['count'] as int;
        
        if (toUpdateCount > 0) {
          await database.execute('''
            UPDATE games 
            SET home_team = ? 
            WHERE home_team IS NULL OR home_team = '' OR home_team = 'null'
          ''', [homeTeam]);
          print('Updated $toUpdateCount games with missing home_team');
        } else {
          print('No games found with missing home_team');
        }
      }
      
      // Step 2: Find and remove duplicate games
      // Get all games grouped by their key fields to identify duplicates
      final duplicateResults = await database.rawQuery('''
        SELECT 
          opponent, date, time, sport_id, user_id,
          COUNT(*) as count,
          GROUP_CONCAT(id) as ids
        FROM games 
        WHERE status = 'Published'
        GROUP BY opponent, date, time, sport_id, user_id
        HAVING COUNT(*) > 1
      ''');
      
      int duplicatesRemoved = 0;
      
      for (final row in duplicateResults) {
        final count = row['count'] as int;
        final idsString = row['ids'] as String;
        final ids = idsString.split(',').map(int.parse).toList();
        
        print('Found ${count} duplicate games: ${row['opponent']} on ${row['date']} at ${row['time']}');
        
        // Keep the first game (lowest ID) and remove the rest
        final idsToRemove = ids.skip(1).toList();
        
        for (final id in idsToRemove) {
          // First remove any game assignments for these duplicate games
          await database.execute('''
            DELETE FROM game_assignments WHERE game_id = ?
          ''', [id]);
          
          // Then remove the duplicate game
          await database.execute('''
            DELETE FROM games WHERE id = ?
          ''', [id]);
          
          duplicatesRemoved++;
          print('Removed duplicate game with ID: $id');
        }
      }
      
      print('Cleanup completed. Removed $duplicatesRemoved duplicate games.');
      
    } catch (e) {
      print('Error during cleanup: $e');
      rethrow;
    }
  }

  /// Check for potential duplicates without removing them
  static Future<List<Map<String, dynamic>>> findPotentialDuplicates() async {
    final database = await _db.database;
    
    final results = await database.rawQuery('''
      SELECT 
        opponent, home_team, date, time, sport_id, user_id,
        COUNT(*) as count,
        GROUP_CONCAT(id) as ids,
        GROUP_CONCAT(status) as statuses
      FROM games 
      GROUP BY opponent, date, time, sport_id, user_id
      HAVING COUNT(*) > 1
      ORDER BY count DESC
    ''');
    
    return results;
  }
  
  /// Get all games for debugging
  static Future<List<Map<String, dynamic>>> getAllGames() async {
    final database = await _db.database;
    
    final results = await database.rawQuery('''
      SELECT g.*, s.name as sport_name
      FROM games g
      LEFT JOIN sports s ON g.sport_id = s.id
      ORDER BY g.created_at DESC
    ''');
    
    return results;
  }
  
  /// Get games that might be duplicates based on similar content
  static Future<List<Map<String, dynamic>>> getRecentGamesWithDetails() async {
    final database = await _db.database;
    
    final results = await database.rawQuery('''
      SELECT g.id, g.opponent, g.home_team, g.date, g.time, g.status, 
             g.created_at, g.updated_at, s.name as sport_name,
             l.name as location_name, u.first_name, u.last_name
      FROM games g
      LEFT JOIN sports s ON g.sport_id = s.id
      LEFT JOIN locations l ON g.location_id = l.id
      LEFT JOIN users u ON g.user_id = u.id
      WHERE g.created_at >= datetime('now', '-1 hour')
      ORDER BY g.created_at DESC
    ''');
    
    return results;
  }
  
  /// Debug info for a specific game
  static Future<Map<String, dynamic>?> getGameDebugInfo(int gameId) async {
    final database = await _db.database;
    
    final results = await database.rawQuery('''
      SELECT g.*, s.name as sport_name, l.name as location_name,
             u.first_name, u.last_name, u.school_name, u.mascot
      FROM games g
      LEFT JOIN sports s ON g.sport_id = s.id
      LEFT JOIN locations l ON g.location_id = l.id
      LEFT JOIN users u ON g.user_id = u.id
      WHERE g.id = ?
    ''', [gameId]);
    
    return results.isNotEmpty ? results.first : null;
  }
  
  /// Remove games with null or empty home_team values
  static Future<void> removeGamesWithNullHomeTeam() async {
    print('Removing games with null home_team...');
    
    try {
      final database = await _db.database;
      
      // First, find games with null home_team
      final nullHomeTeamGames = await database.rawQuery('''
        SELECT id, opponent, date, time, home_team
        FROM games 
        WHERE home_team IS NULL OR home_team = '' OR home_team = 'null'
      ''');
      
      print('Found ${nullHomeTeamGames.length} games with null home_team:');
      for (final game in nullHomeTeamGames) {
        print('  Game ID ${game['id']}: "${game['opponent']}" on ${game['date']} (home_team: ${game['home_team']})');
      }
      
      if (nullHomeTeamGames.isNotEmpty) {
        // Remove game assignments for these games first
        for (final game in nullHomeTeamGames) {
          await database.execute('''
            DELETE FROM game_assignments WHERE game_id = ?
          ''', [game['id']]);
        }
        
        // Then remove the games themselves
        await database.execute('''
          DELETE FROM games 
          WHERE home_team IS NULL OR home_team = '' OR home_team = 'null'
        ''');
        
        print('Removed ${nullHomeTeamGames.length} games with null home_team');
      } else {
        print('No games with null home_team found');
      }
      
    } catch (e) {
      print('Error removing games with null home_team: $e');
      rethrow;
    }
  }
}