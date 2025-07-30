import 'package:flutter/foundation.dart';
import 'lib/shared/services/repositories/advanced_method_repository.dart';

/// Debug script to investigate data consistency between UI and database
class DataConsistencyDebugger {
  final AdvancedMethodRepository _repo = AdvancedMethodRepository();

  /// Comprehensive debug for Official ID 2 and Rookie Refs list
  Future<void> debugOfficialListConsistency() async {
    try {
      print('=== DATA CONSISTENCY DEBUG ===');
      print('Official ID: 2 (Sarah Johnson)');
      print('Expected List: Rookie Refs');
      
      // 1. Verify the official exists
      final official = await _repo.rawQuery('''
        SELECT * FROM officials WHERE id = 2
      ''');
      
      print('\\n👤 OFFICIAL VERIFICATION:');
      if (official.isEmpty) {
        print('❌ Official ID 2 not found in database!');
        return;
      } else {
        print('✅ Official found: ${official.first['name']} (ID: ${official.first['id']})');
      }

      // 2. Find all lists named "Rookie Refs"
      final rookieRefsList = await _repo.rawQuery('''
        SELECT ol.*, s.name as sport_name 
        FROM official_lists ol
        LEFT JOIN sports s ON ol.sport_id = s.id
        WHERE ol.name LIKE '%Rookie%' OR ol.name LIKE '%rookie%'
        ORDER BY ol.name ASC
      ''');
      
      print('\\n📋 ROOKIE LISTS FOUND:');
      if (rookieRefsList.isEmpty) {
        print('❌ No lists with "Rookie" in the name found!');
      } else {
        for (final list in rookieRefsList) {
          print('  - List ${list['id']}: "${list['name']}" (Sport: ${list['sport_name']}, Sport ID: ${list['sport_id']})');
        }
      }

      // 3. Check direct membership in official_list_members table
      final directMemberships = await _repo.rawQuery('''
        SELECT olm.*, ol.name as list_name, s.name as sport_name
        FROM official_list_members olm
        INNER JOIN official_lists ol ON olm.list_id = ol.id
        LEFT JOIN sports s ON ol.sport_id = s.id
        WHERE olm.official_id = 2
        ORDER BY ol.name ASC
      ''');
      
      print('\\n🔗 DIRECT LIST MEMBERSHIPS FOR OFFICIAL ID 2:');
      if (directMemberships.isEmpty) {
        print('❌ No memberships found in official_list_members table!');
        print('💡 This explains why the Advanced Method query returns empty.');
      } else {
        print('✅ Found ${directMemberships.length} memberships:');
        for (final membership in directMemberships) {
          print('  - List ${membership['list_id']}: "${membership['list_name']}" (Sport: ${membership['sport_name']})');
        }
      }

      // 4. Check recent Advanced Method games and their list requirements
      final recentGames = await _repo.rawQuery('''
        SELECT g.id, s.name as sport_name, s.id as sport_id
        FROM games g
        LEFT JOIN sports s ON g.sport_id = s.id
        WHERE g.method = 'advanced' AND g.id IN (18, 17, 16, 15)
        ORDER BY g.id DESC
      ''');

      print('\\n🎮 RECENT ADVANCED METHOD GAMES:');
      for (final game in recentGames) {
        print('  Game ${game['id']}: ${game['sport_name']} (Sport ID: ${game['sport_id']})');
        
        // Check quotas for this game
        final quotas = await _repo.rawQuery('''
          SELECT glq.*, ol.name as list_name
          FROM game_list_quotas glq
          INNER JOIN official_lists ol ON glq.list_id = ol.id
          WHERE glq.game_id = ?
        ''', [game['id']]);
        
        if (quotas.isNotEmpty) {
          print('    Quotas:');
          for (final quota in quotas) {
            print('      - List ${quota['list_id']} ("${quota['list_name']}"): ${quota['min_officials']}-${quota['max_officials']}');
          }
          
          // Check if any quota list matches official's memberships
          if (directMemberships.isNotEmpty) {
            final matchingLists = quotas.where((q) => 
              directMemberships.any((m) => m['list_id'] == q['list_id'])
            ).toList();
            
            if (matchingLists.isNotEmpty) {
              print('    ✅ Official has matching list memberships');
            } else {
              print('    ❌ Official not on any quota lists for this game');
            }
          }
        }
      }

      // 5. Test the exact query used by the Advanced Method
      print('\\n🔍 TESTING ADVANCED METHOD QUERY:');
      for (final game in recentGames) {
        final gameId = game['id'];
        final testQuery = await _repo.rawQuery('''
          SELECT DISTINCT olm.list_id
          FROM official_list_members olm
          INNER JOIN official_lists ol ON olm.list_id = ol.id
          INNER JOIN games g ON ol.sport_id = g.sport_id
          WHERE olm.official_id = ? AND g.id = ?
        ''', [2, gameId]);
        
        print('  Game $gameId query result: ${testQuery.length} lists found');
        if (testQuery.isNotEmpty) {
          for (final result in testQuery) {
            print('    - List ID: ${result['list_id']}');
          }
        }
      }

      // 6. Diagnose potential issues
      print('\\n🩺 DIAGNOSIS:');
      if (directMemberships.isEmpty) {
        print('🔥 ROOT CAUSE: Official ID 2 has NO entries in official_list_members table');
        print('📝 SOLUTIONS:');
        print('   1. Check if the UI is reading from a different data source');
        print('   2. Verify that adding officials to lists actually saves to official_list_members');
        print('   3. Check if there are any database transaction issues');
        print('   4. Look for any data migration issues');
      } else if (rookieRefsList.isEmpty) {
        print('🔥 ISSUE: No "Rookie" lists found in official_lists table');
      } else {
        print('✅ Official has list memberships, checking sport matching...');
      }

      print('\\n=== END DIAGNOSIS ===');
      
    } catch (e) {
      print('❌ Debug error: $e');
    }
  }

  /// Check what the UI might be reading from
  Future<void> debugUIDataSource() async {
    try {
      print('\\n=== UI DATA SOURCE DEBUG ===');
      
      // Check if there are any alternative tables or data structures
      final tables = await _repo.rawQuery('''
        SELECT name FROM sqlite_master WHERE type='table' AND name LIKE '%official%'
      ''');
      
      print('Official-related tables:');
      for (final table in tables) {
        print('  - ${table['name']}');
        
        // Get row counts
        final count = await _repo.rawQuery('SELECT COUNT(*) as count FROM ${table['name']}');
        print('    Rows: ${count.first['count']}');
      }
      
    } catch (e) {
      print('Error debugging UI data source: $e');
    }
  }
}

/// Usage:
/// final debugger = DataConsistencyDebugger();
/// await debugger.debugOfficialListConsistency();
/// await debugger.debugUIDataSource();