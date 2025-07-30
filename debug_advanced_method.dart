import 'package:flutter/foundation.dart';
import 'lib/shared/services/repositories/advanced_method_repository.dart';

/// Debug script to help troubleshoot Advanced Method visibility issues
class AdvancedMethodDebugger {
  final AdvancedMethodRepository _repo = AdvancedMethodRepository();

  /// Debug a specific game and official combination
  Future<void> debugGameVisibility(int gameId, int officialId) async {
    try {
      print('=== DEBUGGING ADVANCED METHOD VISIBILITY ===');
      print('Game ID: $gameId, Official ID: $officialId\n');

      final debugInfo = await _repo.debugGameVisibility(gameId, officialId);

      if (debugInfo.containsKey('error')) {
        print('ERROR: ${debugInfo['error']}');
        return;
      }

      // Print game info
      final gameInfo = debugInfo['game_info'];
      if (gameInfo != null) {
        print('GAME INFO:');
        print('  - Sport: ${gameInfo['sport_name'] ?? 'Unknown'}');
        print('  - Method: ${gameInfo['method'] ?? 'traditional'}');
        print('  - Status: ${gameInfo['status'] ?? 'Unknown'}');
        print('  - Date: ${gameInfo['date'] ?? 'Unknown'}');
        print('  - Officials Required: ${gameInfo['officials_required'] ?? 0}');
        print('  - Officials Hired: ${gameInfo['officials_hired'] ?? 0}');
      } else {
        print('GAME INFO: Game not found!');
        return;
      }

      // Print quotas
      final quotasFound = debugInfo['quotas_found'] ?? 0;
      print('\nQUOTAS FOUND: $quotasFound');
      
      if (quotasFound > 0) {
        final quotas = debugInfo['quotas'] as List<dynamic>;
        for (int i = 0; i < quotas.length; i++) {
          final quota = quotas[i];
          print('  Quota ${i + 1}:');
          print('    - List: ${quota['list_name']} (ID: ${quota['list_id']})');
          print('    - Min: ${quota['min']}, Max: ${quota['max']}, Current: ${quota['current']}');
          print('    - Can Accept More: ${quota['can_accept_more']}');
        }
      } else {
        print('  No quotas found - should use traditional method');
      }

      // Print official's list memberships
      final officialLists = debugInfo['official_lists'] as List<dynamic>? ?? [];
      print('\nOFFICIAL\'S RELEVANT LISTS: ${officialLists.length}');
      print('  List IDs: $officialLists');

      final officialListDetails = debugInfo['official_list_details'] as List<dynamic>? ?? [];
      print('\nOFFICIAL\'S ALL LIST MEMBERSHIPS: ${officialListDetails.length}');
      for (final detail in officialListDetails) {
        print('  - ${detail['list_name']} (ID: ${detail['list_id']}, Sport: ${detail['sport_name']})');
      }

      // Print final result
      final shouldBeVisible = debugInfo['should_be_visible'] ?? false;
      print('\nFINAL RESULT: Game should ${shouldBeVisible ? 'BE VISIBLE' : 'NOT BE VISIBLE'}');

      // Analysis
      print('\n=== ANALYSIS ===');
      if (quotasFound == 0) {
        print('✓ No quotas found - game should be visible (traditional method)');
      } else if (officialLists.isEmpty) {
        print('✗ Official is not on any lists for this game\'s sport');
        print('  - Check if official is added to the correct lists');
        print('  - Check if lists are for the correct sport');
      } else {
        print('✓ Official is on ${officialLists.length} relevant list(s)');
        
        bool hasCapacity = false;
        final quotas = debugInfo['quotas'] as List<dynamic>;
        for (final quota in quotas) {
          if (officialLists.contains(quota['list_id']) && quota['can_accept_more'] == true) {
            hasCapacity = true;
            print('✓ List "${quota['list_name']}" has capacity: ${quota['current']}/${quota['max']}');
          }
        }
        
        if (!hasCapacity) {
          print('✗ No lists with available capacity for this official');
        }
      }

      print('\n=== END DEBUG ===');

    } catch (e) {
      print('DEBUG ERROR: $e');
    }
  }

  /// List all games using Advanced Method
  Future<void> listAdvancedMethodGames() async {
    try {
      final games = await _repo.rawQuery('''
        SELECT g.id, g.date, g.time, g.opponent, g.home_team, s.name as sport_name,
               COUNT(glq.id) as quota_count
        FROM games g
        LEFT JOIN sports s ON g.sport_id = s.id
        LEFT JOIN game_list_quotas glq ON g.id = glq.game_id
        WHERE g.method = 'advanced'
        GROUP BY g.id
        ORDER BY g.date ASC
      ''');

      print('=== ADVANCED METHOD GAMES ===');
      if (games.isEmpty) {
        print('No games found using Advanced Method');
      } else {
        for (final game in games) {
          print('Game ID ${game['id']}: ${game['sport_name']} - ${game['opponent'] ?? game['home_team']} (${game['date']})');
          print('  Quotas: ${game['quota_count']}');
        }
      }
      print('=== END LIST ===\n');
    } catch (e) {
      print('ERROR listing games: $e');
    }
  }

  /// List all officials and their list memberships
  Future<void> listOfficialMemberships() async {
    try {
      final memberships = await _repo.rawQuery('''
        SELECT o.id, o.name as official_name, ol.name as list_name, s.name as sport_name
        FROM officials o
        INNER JOIN official_list_members olm ON o.id = olm.official_id
        INNER JOIN official_lists ol ON olm.list_id = ol.id
        LEFT JOIN sports s ON ol.sport_id = s.id
        ORDER BY o.name, ol.name
      ''');

      print('=== OFFICIAL LIST MEMBERSHIPS ===');
      String currentOfficial = '';
      for (final membership in memberships) {
        if (membership['official_name'] != currentOfficial) {
          currentOfficial = membership['official_name'];
          print('\n${currentOfficial} (ID: ${membership['id']}):');
        }
        print('  - ${membership['list_name']} (${membership['sport_name']})');
      }
      print('\n=== END MEMBERSHIPS ===\n');
    } catch (e) {
      print('ERROR listing memberships: $e');
    }
  }
}

/// Usage example:
/// 
/// final debugger = AdvancedMethodDebugger();
/// 
/// // Debug specific game and official
/// await debugger.debugGameVisibility(gameId, officialId);
/// 
/// // List all advanced method games
/// await debugger.listAdvancedMethodGames();
/// 
/// // List all official memberships
/// await debugger.listOfficialMemberships();