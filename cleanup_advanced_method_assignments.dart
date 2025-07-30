import 'package:flutter/foundation.dart';
import 'lib/shared/services/repositories/advanced_method_repository.dart';

/// Cleanup script to remove incorrect assignments from Advanced Method games
class AdvancedMethodCleanup {
  final AdvancedMethodRepository _repo = AdvancedMethodRepository();

  /// Remove all assignments from Advanced Method games that shouldn't have them
  Future<void> cleanupAdvancedMethodAssignments() async {
    try {
      print('=== CLEANING UP ADVANCED METHOD ASSIGNMENTS ===');
      
      // Find all Advanced Method games that have assignments
      final gamesWithAssignments = await _repo.rawQuery('''
        SELECT DISTINCT g.id, g.method, COUNT(ga.id) as assignment_count
        FROM games g
        INNER JOIN game_assignments ga ON g.id = ga.game_id
        WHERE g.method = 'advanced'
        GROUP BY g.id
        ORDER BY g.id DESC
      ''');

      if (gamesWithAssignments.isEmpty) {
        print('✅ No Advanced Method games with assignments found.');
        return;
      }

      print('Found ${gamesWithAssignments.length} Advanced Method games with assignments:');
      for (final game in gamesWithAssignments) {
        print('  - Game ${game['id']}: ${game['assignment_count']} assignments');
      }

      print('\\n🧹 REMOVING ASSIGNMENTS...');
      
      int totalRemoved = 0;
      for (final game in gamesWithAssignments) {
        final gameId = game['id'] as int;
        final assignmentCount = game['assignment_count'] as int;
        
        // Remove all assignments for this game
        final removed = await _repo.rawDelete('''
          DELETE FROM game_assignments WHERE game_id = ?
        ''', [gameId]);
        
        print('  - Game $gameId: Removed $removed assignments');
        totalRemoved += removed;
      }

      print('\\n✅ Cleanup completed: Removed $totalRemoved total assignments');
      print('📢 Advanced Method games should now appear in Available Games for eligible officials');
      
    } catch (e) {
      print('❌ Cleanup error: $e');
    }
  }

  /// Verify cleanup results
  Future<void> verifyCleanup() async {
    try {
      print('\\n=== VERIFYING CLEANUP ===');
      
      final remainingAssignments = await _repo.rawQuery('''
        SELECT g.id, COUNT(ga.id) as assignment_count
        FROM games g
        INNER JOIN game_assignments ga ON g.id = ga.game_id
        WHERE g.method = 'advanced'
        GROUP BY g.id
      ''');

      if (remainingAssignments.isEmpty) {
        print('✅ Success: No Advanced Method games have assignments anymore');
      } else {
        print('❌ Warning: Some Advanced Method games still have assignments:');
        for (final game in remainingAssignments) {
          print('  - Game ${game['id']}: ${game['assignment_count']} assignments');
        }
      }
      
    } catch (e) {
      print('Error verifying cleanup: $e');
    }
  }

  /// Show current status of Advanced Method games
  Future<void> showStatus() async {
    try {
      print('=== ADVANCED METHOD GAMES STATUS ===');
      
      final games = await _repo.rawQuery('''
        SELECT g.id, g.method, g.status, s.name as sport_name,
               COUNT(DISTINCT ga.id) as assignment_count,
               COUNT(DISTINCT glq.id) as quota_count
        FROM games g
        LEFT JOIN sports s ON g.sport_id = s.id
        LEFT JOIN game_assignments ga ON g.id = ga.game_id
        LEFT JOIN game_list_quotas glq ON g.id = glq.game_id
        WHERE g.method = 'advanced'
        GROUP BY g.id, g.method, g.status, s.name
        ORDER BY g.id DESC
        LIMIT 10
      ''');

      print('Recent Advanced Method games:');
      for (final game in games) {
        print('  Game ${game['id']} (${game['sport_name']}): ${game['assignment_count']} assignments, ${game['quota_count']} quotas');
      }
      
    } catch (e) {
      print('Error showing status: $e');
    }
  }
}

/// Usage:
/// final cleanup = AdvancedMethodCleanup();
/// await cleanup.showStatus();
/// await cleanup.cleanupAdvancedMethodAssignments();
/// await cleanup.verifyCleanup();