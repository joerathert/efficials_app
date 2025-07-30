import 'package:flutter/foundation.dart';
import 'lib/shared/services/repositories/advanced_method_repository.dart';

/// Debug script to check official list memberships
class OfficialListsDebugger {
  final AdvancedMethodRepository _repo = AdvancedMethodRepository();

  /// Debug official list memberships and game sports
  Future<void> debugOfficialListMembership(int officialId) async {
    try {
      print('=== DEBUGGING OFFICIAL LIST MEMBERSHIP ===');
      print('Official ID: $officialId');
      
      // 1. Check if official exists
      final officialInfo = await _repo.rawQuery('''
        SELECT * FROM officials WHERE id = ?
      ''', [officialId]);

      if (officialInfo.isEmpty) {
        print('❌ Official $officialId not found!');
        return;
      }

      final official = officialInfo.first;
      print('\\n👤 OFFICIAL INFO:');
      print('  - ID: ${official['id']}');
      print('  - Name: ${official['name']}');

      // 2. Check ALL list memberships for this official (regardless of sport)
      final allMemberships = await _repo.rawQuery('''
        SELECT olm.list_id, ol.name as list_name, ol.sport_id, s.name as sport_name
        FROM official_list_members olm
        INNER JOIN official_lists ol ON olm.list_id = ol.id
        LEFT JOIN sports s ON ol.sport_id = s.id
        WHERE olm.official_id = ?
        ORDER BY s.name ASC, ol.name ASC
      ''', [officialId]);

      print('\\n📋 ALL LIST MEMBERSHIPS:');
      if (allMemberships.isEmpty) {
        print('  ❌ Official is not on ANY lists!');
        print('  💡 This is why Advanced Method games are not visible.');
        print('  🔧 SOLUTION: Add the official to the appropriate official lists.');
      } else {
        print('  ✅ Found ${allMemberships.length} list memberships:');
        final sportGroups = <String, List<Map<String, Object?>>>{};
        
        for (final membership in allMemberships) {
          final sportName = membership['sport_name'] as String? ?? 'Unknown Sport';
          if (!sportGroups.containsKey(sportName)) {
            sportGroups[sportName] = [];
          }
          sportGroups[sportName]!.add(membership);
        }
        
        for (final sportName in sportGroups.keys) {
          print('    🏀 $sportName:');
          for (final membership in sportGroups[sportName]!) {
            print('      - ${membership['list_name']} (List ID: ${membership['list_id']})');
          }
        }
      }

      // 3. Check recent Advanced Method games and their sports
      print('\\n🎮 RECENT ADVANCED METHOD GAMES:');
      final recentGames = await _repo.rawQuery('''
        SELECT g.id, g.method, s.name as sport_name, s.id as sport_id,
               COUNT(glq.id) as quota_count
        FROM games g
        LEFT JOIN sports s ON g.sport_id = s.id
        LEFT JOIN game_list_quotas glq ON g.id = glq.game_id
        WHERE g.method = 'advanced' AND g.status = 'Published'
        GROUP BY g.id
        ORDER BY g.id DESC
        LIMIT 5
      ''');

      if (recentGames.isEmpty) {
        print('  No Advanced Method games found.');
      } else {
        for (final game in recentGames) {
          print('  - Game ${game['id']}: ${game['sport_name']} (Sport ID: ${game['sport_id']}) - ${game['quota_count']} quotas');
          
          // Check if official is on any lists for this game's sport
          if (allMemberships.isNotEmpty) {
            final relevantLists = allMemberships.where((m) => m['sport_id'] == game['sport_id']).toList();
            if (relevantLists.isEmpty) {
              print('    ❌ Official not on any lists for this sport');
            } else {
              print('    ✅ Official on ${relevantLists.length} lists for this sport: ${relevantLists.map((l) => l['list_name']).join(', ')}');
            }
          }
        }
      }

      // 4. Show available sports and their lists
      print('\\n🏆 AVAILABLE SPORTS AND LISTS:');
      final sportsAndLists = await _repo.rawQuery('''
        SELECT s.name as sport_name, s.id as sport_id,
               ol.name as list_name, ol.id as list_id,
               COUNT(olm.official_id) as member_count
        FROM sports s
        LEFT JOIN official_lists ol ON s.id = ol.sport_id
        LEFT JOIN official_list_members olm ON ol.id = olm.list_id
        GROUP BY s.id, ol.id
        ORDER BY s.name ASC, ol.name ASC
      ''');

      final sportGroups = <String, List<Map<String, Object?>>>{};
      for (final item in sportsAndLists) {
        final sportName = item['sport_name'] as String;
        if (!sportGroups.containsKey(sportName)) {
          sportGroups[sportName] = [];
        }
        if (item['list_name'] != null) {
          sportGroups[sportName]!.add(item);
        }
      }

      for (final sportName in sportGroups.keys) {
        print('  🏀 $sportName:');
        for (final list in sportGroups[sportName]!) {
          final isOfficialMember = allMemberships.any((m) => m['list_id'] == list['list_id']);
          final memberIndicator = isOfficialMember ? '✅' : '  ';
          print('    $memberIndicator ${list['list_name']} (${list['member_count']} members)');
        }
      }

      print('\\n=== SUMMARY ===');
      if (allMemberships.isEmpty) {
        print('🔥 ISSUE: Official $officialId is not on any official lists.');
        print('📝 ACTION NEEDED: Add the official to appropriate lists using the admin interface.');
      } else {
        print('✅ Official $officialId is on ${allMemberships.length} lists.');
        print('🔍 Check if the Advanced Method games are for sports where the official has list membership.');
      }

      print('=== END DEBUG ===');
      
    } catch (e) {
      print('❌ Debug error: $e');
    }
  }

  /// List all officials and their list counts
  Future<void> listAllOfficials() async {
    try {
      print('=== ALL OFFICIALS AND THEIR LIST MEMBERSHIPS ===');
      
      final officials = await _repo.rawQuery('''
        SELECT o.id, o.name, COUNT(olm.list_id) as list_count
        FROM officials o
        LEFT JOIN official_list_members olm ON o.id = olm.official_id
        GROUP BY o.id, o.name
        ORDER BY o.name ASC
      ''');

      for (final official in officials) {
        print('Official ${official['id']}: ${official['name']} (on ${official['list_count']} lists)');
      }
      
    } catch (e) {
      print('Error listing officials: $e');
    }
  }
}

/// Usage:
/// final debugger = OfficialListsDebugger();
/// await debugger.debugOfficialListMembership(2);
/// await debugger.listAllOfficials();