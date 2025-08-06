import 'lib/shared/services/repositories/game_assignment_repository.dart';
import 'lib/shared/services/repositories/user_repository.dart';

/// Debug script to investigate Athletic Director game visibility issue
void main() async {
  final gameRepo = GameAssignmentRepository();
  final userRepo = UserRepository();
  
  print('=== DEBUGGING AD GAME VISIBILITY ===\n');
  
  try {
    // 1. Find recent games by Athletic Directors
    final adGames = await gameRepo.rawQuery('''
      SELECT g.id, g.method, g.status, u.first_name, u.last_name, u.scheduler_type,
             s.name as sport_name, g.created_at
      FROM games g
      JOIN users u ON g.user_id = u.id  
      LEFT JOIN sports s ON g.sport_id = s.id
      WHERE u.scheduler_type = 'Athletic Director' 
        AND g.status = 'Published'
      ORDER BY g.created_at DESC
      LIMIT 5
    ''');

    print('📋 RECENT AD GAMES:');
    if (adGames.isEmpty) {
      print('  ❌ No published games by Athletic Directors found');
    } else {
      for (final game in adGames) {
        print('  - Game ${game['id']}: ${game['sport_name']} by ${game['first_name']} ${game['last_name']}');
        print('    Method: ${game['method']}, Status: ${game['status']}');
      }
    }

    print('\n📋 RECENT ASSIGNER GAMES:');
    // 2. Compare with Assigner games
    final assignerGames = await gameRepo.rawQuery('''
      SELECT g.id, g.method, g.status, u.first_name, u.last_name, u.scheduler_type,
             s.name as sport_name, g.created_at
      FROM games g
      JOIN users u ON g.user_id = u.id  
      LEFT JOIN sports s ON g.sport_id = s.id
      WHERE u.scheduler_type = 'Assigner' 
        AND g.status = 'Published'
      ORDER BY g.created_at DESC
      LIMIT 5
    ''');

    if (assignerGames.isEmpty) {
      print('  ❌ No published games by Assigners found');
    } else {
      for (final game in assignerGames) {
        print('  - Game ${game['id']}: ${game['sport_name']} by ${game['first_name']} ${game['last_name']}');
        print('    Method: ${game['method']}, Status: ${game['status']}');
      }
    }

    // 3. Find crew chiefs
    print('\n👥 CREW CHIEFS:');
    final crewChiefs = await gameRepo.rawQuery('''
      SELECT o.id, o.name, o.official_user_id
      FROM officials o
      JOIN crews c ON o.id = c.crew_chief_id
      WHERE c.is_active = 1
      LIMIT 5
    ''');

    if (crewChiefs.isEmpty) {
      print('  ❌ No active crew chiefs found');
    } else {
      for (final chief in crewChiefs) {
        print('  - ${chief['name']} (ID: ${chief['id']})');
        
        // Test available games for this crew chief
        final availableGames = await gameRepo.getAvailableGamesForOfficial(chief['id']);
        print('    Available games: ${availableGames.length}');
        
        // Show methods of available games
        final methodCounts = <String, int>{};
        for (final game in availableGames) {
          final method = game['method'] as String? ?? 'null';
          methodCounts[method] = (methodCounts[method] ?? 0) + 1;
        }
        print('    By method: $methodCounts');
      }
    }

    // 4. Check if crew chief filtering logic is working
    print('\n🔍 TESTING CREW CHIEF FILTERING:');
    if (crewChiefs.isNotEmpty && adGames.isNotEmpty) {
      final testChief = crewChiefs.first;
      final testGame = adGames.first;
      
      print('Testing Chief ${testChief['name']} (ID: ${testChief['id']}) with Game ${testGame['id']}');
      
      // Check if the official is recognized as crew chief
      final isCrewChief = await gameRepo.rawQuery('''
        SELECT 1 FROM crews 
        WHERE crew_chief_id = ? AND is_active = 1
        LIMIT 1
      ''', [testChief['id']]);
      
      print('  - Is crew chief: ${isCrewChief.isNotEmpty}');
      
      // Check if game is in their available games
      final availableForChief = await gameRepo.getAvailableGamesForOfficial(testChief['id']);
      final gameFound = availableForChief.any((g) => g['id'] == testGame['id']);
      print('  - Game found in available: $gameFound');
      
      if (!gameFound) {
        // Check if game has assignments already
        final assignments = await gameRepo.rawQuery('''
          SELECT ga.id, ga.status, o.name as official_name
          FROM game_assignments ga
          LEFT JOIN officials o ON ga.official_id = o.id
          WHERE ga.game_id = ?
        ''', [testGame['id']]);
        
        if (assignments.isNotEmpty) {
          print('  - Game has assignments (prevents visibility):');
          for (final assignment in assignments) {
            print('    * ${assignment['official_name']}: ${assignment['status']}');
          }
        } else {
          print('  - Game has no assignments - should be visible');
        }

        // Check dismissals
        final dismissals = await gameRepo.rawQuery('''
          SELECT gd.id, gd.reason
          FROM game_dismissals gd
          WHERE gd.game_id = ? AND gd.official_id = ?
        ''', [testGame['id'], testChief['id']]);
        
        if (dismissals.isNotEmpty) {
          print('  - Game was dismissed by this official');
        }
      }
    }

  } catch (e) {
    print('❌ Error: $e');
  }
  
  print('\n=== END DEBUG ===');
}