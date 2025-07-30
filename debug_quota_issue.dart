import 'package:flutter/foundation.dart';
import 'lib/shared/services/repositories/advanced_method_repository.dart';

/// Quick debug script to check game and official data
class QuotaDebugger {
  final AdvancedMethodRepository _repo = AdvancedMethodRepository();

  /// Check if game has quotas and if official is on correct lists
  Future<void> debugGameAndOfficial(int gameId, int officialId) async {
    try {
      print('=== DEBUGGING GAME $gameId AND OFFICIAL $officialId ===');

      // Check game details
      final gameInfo = await _repo.rawQuery('''
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
      print('📋 GAME INFO:');
      print('  - ID: ${game['id']}');
      print('  - Method: ${game['method']}');
      print('  - Sport: ${game['sport_name']} (ID: ${game['sport_id']})');
      print('  - Status: ${game['status']}');
      print('  - Officials Required: ${game['officials_required']}');
      print('  - Officials Hired: ${game['officials_hired']}');

      // Check quotas
      final quotas = await _repo.rawQuery('''
        SELECT glq.*, ol.name as list_name
        FROM game_list_quotas glq
        LEFT JOIN official_lists ol ON glq.list_id = ol.id
        WHERE glq.game_id = ?
        ORDER BY ol.name ASC
      ''', [gameId]);

      print('\n📊 QUOTAS:');
      if (quotas.isEmpty) {
        print('  ❌ No quotas found for this game!');
      } else {
        for (final quota in quotas) {
          print('  - ${quota['list_name']}: ${quota['current_officials']}/${quota['max_officials']} (min: ${quota['min_officials']})');
        }
      }

      // Check official details
      final officialInfo = await _repo.rawQuery('''
        SELECT * FROM officials WHERE id = ?
      ''', [officialId]);

      if (officialInfo.isEmpty) {
        print('\n❌ Official $officialId not found!');
        return;
      }

      final official = officialInfo.first;
      print('\n👤 OFFICIAL INFO:');
      print('  - ID: ${official['id']}');
      print('  - Name: ${official['name']}');

      // Check official's list memberships
      final listMemberships = await _repo.rawQuery('''
        SELECT olm.list_id, ol.name as list_name, ol.sport_id, s.name as sport_name
        FROM official_list_members olm
        INNER JOIN official_lists ol ON olm.list_id = ol.id
        LEFT JOIN sports s ON ol.sport_id = s.id
        WHERE olm.official_id = ?
        ORDER BY ol.name ASC
      ''', [officialId]);

      print('\n📋 OFFICIAL LIST MEMBERSHIPS:');
      if (listMemberships.isEmpty) {
        print('  ❌ Official is not on any lists!');
      } else {
        for (final membership in listMemberships) {
          print('  - ${membership['list_name']} (${membership['sport_name']}, sport_id: ${membership['sport_id']})');
        }
      }

      // Check lists for this game's sport
      final relevantLists = await _repo.rawQuery('''
        SELECT DISTINCT olm.list_id, ol.name as list_name
        FROM official_list_members olm
        INNER JOIN official_lists ol ON olm.list_id = ol.id
        INNER JOIN games g ON ol.sport_id = g.sport_id
        WHERE olm.official_id = ? AND g.id = ?
      ''', [officialId, gameId]);

      print('\n🎯 RELEVANT LISTS FOR THIS GAME:');
      if (relevantLists.isEmpty) {
        print('  ❌ Official is not on any lists for this game\'s sport!');
        print('  💡 This is why the game is not visible through Advanced Method logic');
      } else {
        for (final list in relevantLists) {
          print('  - ${list['list_name']} (ID: ${list['list_id']})');
        }
      }

      // Check if the game should be visible
      final debugInfo = await _repo.debugGameVisibility(gameId, officialId);
      print('\n🔍 VISIBILITY DEBUG:');
      print('  Should be visible: ${debugInfo['should_be_visible']}');

      print('\n=== END DEBUG ===');

    } catch (e) {
      print('❌ Debug error: $e');
    }
  }

  /// List all games with their methods and quota counts
  Future<void> listAllGames() async {
    try {
      print('=== ALL GAMES ===');
      
      final games = await _repo.rawQuery('''
        SELECT g.id, g.method, g.status, s.name as sport_name,
               COUNT(glq.id) as quota_count
        FROM games g
        LEFT JOIN sports s ON g.sport_id = s.id
        LEFT JOIN game_list_quotas glq ON g.id = glq.game_id
        GROUP BY g.id
        ORDER BY g.id DESC
        LIMIT 10
      ''');

      for (final game in games) {
        print('Game ${game['id']}: ${game['method']} method, ${game['quota_count']} quotas (${game['sport_name']})');
      }
      
      print('=== END GAMES ===\n');
    } catch (e) {
      print('Error listing games: $e');
    }
  }
}

/// Usage:
/// final debugger = QuotaDebugger();
/// await debugger.listAllGames();
/// await debugger.debugGameAndOfficial(14, 2); // Replace with actual IDs