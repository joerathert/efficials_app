import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'lib/shared/services/repositories/advanced_method_repository.dart';

/// Script to sync SharedPreferences list data to database tables
class ListDataSyncer {
  final AdvancedMethodRepository _repo = AdvancedMethodRepository();

  /// Sync saved_lists from SharedPreferences to database
  Future<void> syncListsToDatabase() async {
    try {
      print('=== SYNCING LISTS FROM SHAREDPREFERENCES TO DATABASE ===');
      
      // 1. Read from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final String? listsJson = prefs.getString('saved_lists');
      
      if (listsJson == null || listsJson.isEmpty) {
        print('❌ No saved_lists found in SharedPreferences');
        return;
      }

      final List<Map<String, dynamic>> savedLists = 
          List<Map<String, dynamic>>.from(jsonDecode(listsJson));
      
      print('📋 Found ${savedLists.length} lists in SharedPreferences:');
      for (final list in savedLists) {
        final name = list['name'] as String;
        final officials = list['officials'] as List<dynamic>? ?? [];
        print('  - $name: ${officials.length} officials');
      }

      // 2. Process each list
      for (final listData in savedLists) {
        await _syncSingleList(listData);
      }

      print('\\n✅ Sync completed successfully!');
      
    } catch (e) {
      print('❌ Error syncing lists: $e');
    }
  }

  /// Sync a single list to database
  Future<void> _syncSingleList(Map<String, dynamic> listData) async {
    try {
      final listName = listData['name'] as String;
      final officials = List<Map<String, dynamic>>.from(listData['officials'] ?? []);
      
      print('\\n🔄 Syncing list: $listName');
      
      // Find or create the official_list record
      int listId = await _findOrCreateOfficialList(listName);
      
      print('  📋 List ID: $listId');
      
      // Clear existing memberships for this list
      await _repo.rawDelete('''
        DELETE FROM official_list_members WHERE list_id = ?
      ''', [listId]);
      
      print('  🧹 Cleared existing memberships');
      
      // Add all officials to the list
      int addedCount = 0;
      for (final official in officials) {
        final officialId = official['id'] as int;
        final officialName = official['name'] as String;
        
        try {
          await _repo.rawInsert('''
            INSERT INTO official_list_members (official_id, list_id)
            VALUES (?, ?)
          ''', [officialId, listId]);
          
          addedCount++;
          print('    ✅ Added $officialName (ID: $officialId)');
        } catch (e) {
          print('    ❌ Failed to add $officialName: $e');
        }
      }
      
      print('  📊 Added $addedCount/$officials.length} officials to database');
      
    } catch (e) {
      print('  ❌ Error syncing list ${listData['name']}: $e');
    }
  }

  /// Find or create an official_list record
  Future<int> _findOrCreateOfficialList(String listName) async {
    // Try to find existing list
    final existing = await _repo.rawQuery('''
      SELECT id FROM official_lists WHERE name = ?
    ''', [listName]);
    
    if (existing.isNotEmpty) {
      return existing.first['id'] as int;
    }
    
    // Create new list (need to determine sport_id)
    // For now, let's assume Basketball (sport_id = 1)
    // In production, you'd need better logic to determine the sport
    final sportId = await _getDefaultSportId();
    
    final listId = await _repo.rawInsert('''
      INSERT INTO official_lists (name, sport_id)
      VALUES (?, ?)
    ''', [listName, sportId]);
    
    print('  🆕 Created new official_list: $listName (ID: $listId, Sport: $sportId)');
    return listId;
  }

  /// Get default sport ID (Basketball = 1, or first available sport)
  Future<int> _getDefaultSportId() async {
    final sports = await _repo.rawQuery('SELECT id FROM sports ORDER BY id LIMIT 1');
    return sports.isNotEmpty ? sports.first['id'] as int : 1;
  }

  /// Verify the sync results
  Future<void> verifySync() async {
    try {
      print('\\n=== VERIFYING SYNC RESULTS ===');
      
      // Check database state
      final lists = await _repo.rawQuery('''
        SELECT ol.id, ol.name, COUNT(olm.official_id) as member_count
        FROM official_lists ol
        LEFT JOIN official_list_members olm ON ol.id = olm.list_id
        GROUP BY ol.id, ol.name
        ORDER BY ol.name
      ''');
      
      print('📋 Official lists in database:');
      for (final list in lists) {
        print('  - List ${list['id']}: ${list['name']} (${list['member_count']} members)');
      }
      
      // Test Sarah Johnson specifically
      print('\\n👤 Testing Sarah Johnson (Official ID 2):');
      final sarahMemberships = await _repo.rawQuery('''
        SELECT olm.list_id, ol.name as list_name
        FROM official_list_members olm
        INNER JOIN official_lists ol ON olm.list_id = ol.id
        WHERE olm.official_id = 2
      ''');
      
      if (sarahMemberships.isEmpty) {
        print('  ❌ Still no memberships found for Official ID 2');
      } else {
        print('  ✅ Found ${sarahMemberships.length} memberships:');
        for (final membership in sarahMemberships) {
          print('    - List ${membership['list_id']}: ${membership['list_name']}');
        }
      }
      
    } catch (e) {
      print('Error verifying sync: $e');
    }
  }

  /// Show SharedPreferences data for debugging
  Future<void> showSharedPreferencesData() async {
    try {
      print('=== SHAREDPREFERENCES DATA ===');
      
      final prefs = await SharedPreferences.getInstance();
      final String? listsJson = prefs.getString('saved_lists');
      
      if (listsJson == null) {
        print('No saved_lists found in SharedPreferences');
        return;
      }
      
      final List<Map<String, dynamic>> savedLists = 
          List<Map<String, dynamic>>.from(jsonDecode(listsJson));
      
      print('Raw data:');
      print(listsJson);
      
      print('\\nParsed data:');
      for (final list in savedLists) {
        print('List: ${list['name']}');
        final officials = list['officials'] as List<dynamic>? ?? [];
        for (final official in officials) {
          print('  - ${official['name']} (ID: ${official['id']})');
        }
      }
      
    } catch (e) {
      print('Error showing SharedPreferences data: $e');
    }
  }
}

/// Usage:
/// final syncer = ListDataSyncer();
/// await syncer.showSharedPreferencesData();
/// await syncer.syncListsToDatabase();
/// await syncer.verifySync();