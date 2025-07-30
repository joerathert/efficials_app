import 'package:flutter/foundation.dart';
import 'lib/shared/services/repositories/advanced_method_repository.dart';
import 'lib/shared/services/repositories/game_assignment_repository.dart';

/// Debug script to check why Advanced Method games aren't appearing in Available Games
class AvailableGamesDebugger {
  final AdvancedMethodRepository _advancedRepo = AdvancedMethodRepository();
  final GameAssignmentRepository _assignmentRepo = GameAssignmentRepository();

  /// Debug a specific game and official combination
  Future<void> debugGameVisibility(int gameId, int officialId) async {
    try {
      print('=== DEBUGGING AVAILABLE GAMES ISSUE ===');
      print('Game ID: $gameId, Official ID: $officialId');
      
      // 1. Check if game exists and its method
      final gameInfo = await _advancedRepo.rawQuery('''
        SELECT g.*, s.name as sport_name
        FROM games g
        LEFT JOIN sports s ON g.sport_id = s.id
        WHERE g.id = ?
      ''', [gameId]);

      if (gameInfo.isEmpty) {
        print('❌ Game $gameId not found!');
        return;
      }

      final game = gameInfo.first;
      print('\\n📋 GAME INFO:');
      print('  - Method: ${game['method']}');
      print('  - Sport: ${game['sport_name']} (ID: ${game['sport_id']})');\n      print('  - Status: ${game['status']}');
      print('  - Hire Automatically: ${game['hire_automatically']}');

      // 2. Check for existing assignments
      final assignments = await _advancedRepo.rawQuery('''
        SELECT ga.*, o.name as official_name
        FROM game_assignments ga
        LEFT JOIN officials o ON ga.official_id = o.id
        WHERE ga.game_id = ?
      ''', [gameId]);

      print('\\n📬 ASSIGNMENTS:');
      if (assignments.isEmpty) {
        print('  ✅ No assignments found - game should appear in Available Games');
      } else {
        print('  ❌ Found ${assignments.length} assignments - this prevents game from appearing in Available Games:');
        for (final assignment in assignments) {
          print('    - ${assignment['official_name']}: ${assignment['status']}');
        }
      }

      // 3. Check quotas (if Advanced Method)
      if (game['method'] == 'advanced') {
        final quotas = await _advancedRepo.getGameListQuotas(gameId);
        print('\\n📊 QUOTAS:');
        if (quotas.isEmpty) {
          print('  ❌ No quotas found for Advanced Method game!');
        } else {
          print('  ✅ Found ${quotas.length} quotas:');
          for (final quota in quotas) {
            print('    - ${quota.listName}: ${quota.currentOfficials}/${quota.maxOfficials} (min: ${quota.minOfficials}, canAcceptMore: ${quota.canAcceptMore})');
          }
        }

        // 4. Check official's list memberships
        final officialLists = await _advancedRepo.rawQuery('''
          SELECT olm.list_id, ol.name as list_name, ol.sport_id
          FROM official_list_members olm
          INNER JOIN official_lists ol ON olm.list_id = ol.id
          WHERE olm.official_id = ? AND ol.sport_id = ?
        ''', [officialId, game['sport_id']]);

        print('\\n👤 OFFICIAL LIST MEMBERSHIPS (for this sport):');
        if (officialLists.isEmpty) {
          print('  ❌ Official is not on any lists for this sport!');
        } else {
          for (final membership in officialLists) {
            print('    - ${membership['list_name']} (ID: ${membership['list_id']})');
          }
        }

        // 5. Test visibility logic
        final isVisible = await _advancedRepo.isGameVisibleToOfficial(gameId, officialId);
        print('\\n🎯 VISIBILITY RESULT: $isVisible');
      }

      // 6. Check official's home data to see what games they see
      print('\\n🏠 CHECKING OFFICIAL HOME DATA...');
      try {
        final homeData = await _assignmentRepo.getOfficialHomeData(officialId);
        final availableGames = homeData['availableGames'] as List<Map<String, dynamic>>?;
        
        if (availableGames != null) {
          final gameFound = availableGames.any((g) => g['id'] == gameId);
          print('  Available Games count: ${availableGames.length}');
          print('  Game $gameId found in Available Games: $gameFound');
          
          if (!gameFound && availableGames.isNotEmpty) {
            print('  Other available games:');
            for (final g in availableGames.take(3)) {
              print('    - Game ${g['id']}: ${g['method']} method');
            }
          }
        }
      } catch (e) {
        print('  Error getting home data: $e');
      }

      print('\\n=== END DEBUG ===');
      
    } catch (e) {
      print('❌ Debug error: $e');
    }
  }

  /// List all recent Advanced Method games
  Future<void> listAdvancedMethodGames() async {
    try {
      print('=== RECENT ADVANCED METHOD GAMES ===');
      
      final games = await _advancedRepo.rawQuery('''
        SELECT g.id, g.method, g.status, s.name as sport_name,
               COUNT(ga.id) as assignment_count,
               COUNT(glq.id) as quota_count
        FROM games g
        LEFT JOIN sports s ON g.sport_id = s.id
        LEFT JOIN game_assignments ga ON g.id = ga.game_id
        LEFT JOIN game_list_quotas glq ON g.id = glq.game_id
        WHERE g.method = 'advanced'
        GROUP BY g.id
        ORDER BY g.id DESC
        LIMIT 5
      ''');

      for (final game in games) {
        print('Game ${game['id']}: ${game['sport_name']}, ${game['assignment_count']} assignments, ${game['quota_count']} quotas');
      }
      
      print('=== END GAMES ===\\n');
    } catch (e) {
      print('Error listing games: $e');
    }
  }
}

/// Usage:
/// final debugger = AvailableGamesDebugger();
/// await debugger.listAdvancedMethodGames();
/// await debugger.debugGameVisibility(GAME_ID, OFFICIAL_ID);