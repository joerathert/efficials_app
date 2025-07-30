import 'package:flutter/foundation.dart';
import 'lib/shared/services/repositories/advanced_method_repository.dart';

/// Quick script to check the specific membership issue
class QuickMembershipChecker {
  final AdvancedMethodRepository _repo = AdvancedMethodRepository();

  /// Quick check for the specific issue
  Future<void> checkSarahJohnsonMembership() async {
    try {
      print('=== QUICK SARAH JOHNSON MEMBERSHIP CHECK ===');
      
      print('1. Checking if Official ID 2 exists:');
      final official = await _repo.rawQuery('SELECT * FROM officials WHERE id = 2');
      print('   Result: ${official.isNotEmpty ? "✅ Found ${official.first['name']}" : "❌ Not found"}');
      
      print('\\n2. Checking all list memberships for Official ID 2:');
      final memberships = await _repo.rawQuery('''
        SELECT olm.list_id, ol.name as list_name 
        FROM official_list_members olm
        INNER JOIN official_lists ol ON olm.list_id = ol.id
        WHERE olm.official_id = 2
      ''');
      print('   Found ${memberships.length} memberships:');
      for (final m in memberships) {
        print('     - List ${m['list_id']}: ${m['list_name']}');
      }
      
      print('\\n3. Finding all "Rookie" lists:');
      final rookieLists = await _repo.rawQuery('''
        SELECT id, name, sport_id FROM official_lists 
        WHERE name LIKE '%ookie%' 
        ORDER BY name
      ''');
      print('   Found ${rookieLists.length} rookie lists:');
      for (final list in rookieLists) {
        print('     - List ${list['id']}: ${list['name']} (Sport ${list['sport_id']})');
      }
      
      print('\\n4. Checking Game 18 quotas:');
      final quotas = await _repo.rawQuery('''
        SELECT glq.list_id, ol.name as list_name
        FROM game_list_quotas glq
        INNER JOIN official_lists ol ON glq.list_id = ol.id
        WHERE glq.game_id = 18
      ''');
      print('   Game 18 has quotas for ${quotas.length} lists:');
      for (final q in quotas) {
        print('     - List ${q['list_id']}: ${q['list_name']}');
      }
      
      print('\\n5. THE PROBLEM:');
      if (memberships.isEmpty) {
        print('   🔥 Official ID 2 has NO memberships in official_list_members table');
        print('   💡 Even though UI shows them on Rookie Refs list');
        print('   📝 ACTION: Need to manually add the membership record');
      } else if (quotas.isEmpty) {
        print('   🔥 Game 18 has no quotas in database');
      } else {
        final hasMatchingList = memberships.any((m) => 
          quotas.any((q) => q['list_id'] == m['list_id']));
        if (!hasMatchingList) {
          print('   🔥 Official is on lists, but not the ones with quotas for Game 18');
        } else {
          print('   🤔 Official should be able to see the game - investigating further...');
        }
      }
      
    } catch (e) {
      print('Error: $e');
    }
  }

  /// Add the missing membership if needed
  Future<void> addMissingMembership() async {
    try {
      print('\\n=== ATTEMPTING TO FIX THE ISSUE ===');
      
      // Find the first Rookie list
      final rookieList = await _repo.rawQuery('''
        SELECT id, name FROM official_lists 
        WHERE name LIKE '%ookie%' 
        LIMIT 1
      ''');
      
      if (rookieList.isEmpty) {
        print('❌ No Rookie list found to add membership to');
        return;
      }
      
      final listId = rookieList.first['id'] as int;
      final listName = rookieList.first['name'] as String;
      
      print('Found Rookie list: $listName (ID: $listId)');
      
      // Check if membership already exists
      final existing = await _repo.rawQuery('''
        SELECT * FROM official_list_members 
        WHERE official_id = 2 AND list_id = ?
      ''', [listId]);
      
      if (existing.isNotEmpty) {
        print('✅ Membership already exists');
      } else {
        print('Adding membership...');
        await _repo.rawInsert('''
          INSERT INTO official_list_members (official_id, list_id)
          VALUES (2, ?)
        ''', [listId]);
        print('✅ Added Official ID 2 to $listName');
        
        // Verify the addition
        final verify = await _repo.rawQuery('''
          SELECT * FROM official_list_members 
          WHERE official_id = 2 AND list_id = ?
        ''', [listId]);
        
        print('Verification: ${verify.isNotEmpty ? "✅ Success" : "❌ Failed"}');
      }
      
    } catch (e) {
      print('Error adding membership: $e');
    }
  }
}

/// Usage:
/// final checker = QuickMembershipChecker();
/// await checker.checkSarahJohnsonMembership();
/// await checker.addMissingMembership();