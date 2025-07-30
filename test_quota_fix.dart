import 'dart:convert';
import 'lib/shared/services/repositories/advanced_method_repository.dart';

/// Test script to verify quota creation fix
class QuotaFixTester {
  final AdvancedMethodRepository _repo = AdvancedMethodRepository();

  /// Test the quota creation from selectedLists data structure
  Future<void> testQuotaCreation() async {
    try {
      print('=== TESTING QUOTA CREATION FIX ===');
      
      // Simulate the selectedLists data structure that comes from templates
      final selectedLists = [
        {
          'id': 1,
          'name': 'Rookie Umps',
          'minOfficials': 0,
          'maxOfficials': 1,
          'officials': [
            {'id': 2, 'name': 'John Doe'},
            {'id': 3, 'name': 'Jane Smith'},
          ]
        },
        {
          'id': 2,
          'name': 'Veteran Umps',
          'minOfficials': 1,
          'maxOfficials': 2,
          'officials': [
            {'id': 4, 'name': 'Bob Wilson'},
            {'id': 5, 'name': 'Alice Johnson'},
          ]
        }
      ];

      // Convert to the format our quota creation code expects
      final quotas = selectedLists.map((list) => {
        'listId': list['id'] as int,
        'minOfficials': list['minOfficials'] as int,
        'maxOfficials': list['maxOfficials'] as int,
      }).toList();

      print('📊 QUOTA DATA TO CREATE:');
      for (final quota in quotas) {
        print('  - List ${quota['listId']}: ${quota['minOfficials']}-${quota['maxOfficials']} officials');
      }

      // Test game ID (use a test ID that won't conflict)
      const testGameId = 999;

      // Create quotas using the same logic as in review_game_info_screen.dart
      print('\\n🔄 CREATING QUOTAS...');
      await _repo.setGameListQuotas(testGameId, quotas);
      print('✅ Created ${quotas.length} quota records for game $testGameId');

      // Verify quotas were created correctly
      print('\\n🔍 VERIFYING CREATED QUOTAS...');
      final createdQuotas = await _repo.getGameListQuotas(testGameId);
      
      if (createdQuotas.length == quotas.length) {
        print('✅ Correct number of quotas created: ${createdQuotas.length}');
        
        for (final createdQuota in createdQuotas) {
          print('  - ${createdQuota.listName}: ${createdQuota.currentOfficials}/${createdQuota.maxOfficials} (min: ${createdQuota.minOfficials})');
        }
      } else {
        print('❌ Wrong number of quotas created: expected ${quotas.length}, got ${createdQuotas.length}');
      }

      // Test game visibility logic
      print('\\n🎯 TESTING GAME VISIBILITY...');
      const testOfficialId = 2; // Should be on Rookie Umps list
      final isVisible = await _repo.isGameVisibleToOfficial(testGameId, testOfficialId);
      print('Game $testGameId visible to official $testOfficialId: $isVisible');

      // Clean up
      print('\\n🧹 CLEANING UP...');
      await _repo.deleteGameListQuotas(testGameId);
      print('✅ Cleaned up test data');

      print('\\n=== TEST COMPLETED SUCCESSFULLY ===');
      
    } catch (e) {
      print('❌ Test failed with error: $e');
    }
  }

  /// Test the template-to-game workflow simulation
  Future<void> testTemplateWorkflow() async {
    try {
      print('\\n=== TESTING TEMPLATE WORKFLOW SIMULATION ===');
      
      // Simulate game data that would come from a template
      final gameData = {
        'method': 'advanced',
        'selectedLists': [
          {
            'id': 1,
            'name': 'Rookie Refs',
            'minOfficials': 0,
            'maxOfficials': 1,
            'officials': []
          },
          {
            'id': 2,
            'name': 'Veteran Refs',
            'minOfficials': 1,
            'maxOfficials': 2,
            'officials': []
          }
        ]
      };

      const gameId = 1000;
      print('📋 Simulating game creation with ID: $gameId');
      print('   Method: ${gameData['method']}');
      
      // Simulate the quota creation code from review_game_info_screen.dart
      if (gameData['method'] == 'advanced' && gameData['selectedLists'] != null) {
        final selectedLists = gameData['selectedLists'] as List<dynamic>;
        final quotas = selectedLists.map((list) => {
          'listId': list['id'] as int,
          'minOfficials': list['minOfficials'] as int,
          'maxOfficials': list['maxOfficials'] as int,
        }).toList();
        
        print('🔄 Creating quotas from template data...');
        await _repo.setGameListQuotas(gameId, quotas);
        print('✅ Created ${quotas.length} quota records from template');
        
        // Verify the quotas
        final verifyQuotas = await _repo.getGameListQuotas(gameId);
        print('🔍 Verification: ${verifyQuotas.length} quotas found in database');
        
        for (final quota in verifyQuotas) {
          print('   - ${quota.listName}: ${quota.minOfficials}-${quota.maxOfficials}');
        }
        
        // Clean up
        await _repo.deleteGameListQuotas(gameId);
        print('🧹 Cleaned up test data');
      }
      
      print('✅ Template workflow test completed');
      
    } catch (e) {
      print('❌ Template workflow test failed: $e');
    }
  }
}

/// Usage:
/// final tester = QuotaFixTester();
/// await tester.testQuotaCreation();
/// await tester.testTemplateWorkflow();