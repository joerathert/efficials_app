import 'lib/shared/services/repositories/game_assignment_repository.dart';

/// Debug script to check specific game data
void main() async {
  final gameRepo = GameAssignmentRepository();
  
  print('=== DEBUGGING SPECIFIC GAME ISSUE ===\n');
  
  try {
    // Find the specific game showing "Collinsville Kahoks @     "
    final problematicGame = await gameRepo.rawQuery('''
      SELECT g.*, u.first_name, u.last_name, u.scheduler_type, 
             u.school_name, u.mascot, u.setup_completed
      FROM games g
      JOIN users u ON g.user_id = u.id  
      WHERE g.opponent LIKE '%Collinsville%'
        OR g.opponent LIKE '%Kahoks%'
      ORDER BY g.created_at DESC
      LIMIT 1
    ''');

    if (problematicGame.isNotEmpty) {
      final game = problematicGame.first;
      print('🔍 FOUND PROBLEMATIC GAME:');
      print('  Game ID: ${game['id']}');
      print('  Opponent: "${game['opponent']}"');
      print('  Home Team: "${game['home_team']}"');
      print('  Status: ${game['status']}');
      print('  Method: ${game['method']}');
      print('  Created by: ${game['first_name']} ${game['last_name']} (${game['scheduler_type']})');
      print('  AD School: "${game['school_name']}"');
      print('  AD Mascot: "${game['mascot']}"');
      print('  Setup Complete: ${game['setup_completed']}');
      
      // Check what the home team should be
      final expectedHomeTeam = '${game['school_name']} ${game['mascot']}';
      print('  Expected Home Team: "$expectedHomeTeam"');
      
      // Fix this specific game if needed
      if (game['home_team'] == null || 
          game['home_team'].toString().trim().isEmpty || 
          game['home_team'] == 'Home Team') {
        
        print('\\n🔧 FIXING THIS GAME:');
        try {
          await gameRepo.rawQuery('''
            UPDATE games 
            SET home_team = ?, updated_at = ?
            WHERE id = ?
          ''', [expectedHomeTeam, DateTime.now().toIso8601String(), game['id']]);
          
          print('  ✅ Updated game ${game['id']} home_team to "$expectedHomeTeam"');
          
          // Verify the fix
          final verifyGame = await gameRepo.rawQuery('''
            SELECT home_team FROM games WHERE id = ?
          ''', [game['id']]);
          
          if (verifyGame.isNotEmpty) {
            print('  ✅ Verified: home_team is now "${verifyGame.first['home_team']}"');
          }
        } catch (e) {
          print('  ❌ Failed to update: $e');
        }
      } else {
        print('  ✅ Home team already set correctly');
      }
    } else {
      print('❌ No game found with "Collinsville" or "Kahoks" in opponent field');
      
      // Show all recent AD games instead
      final recentAdGames = await gameRepo.rawQuery('''
        SELECT g.id, g.opponent, g.home_team, u.first_name, u.last_name, 
               u.school_name, u.mascot
        FROM games g
        JOIN users u ON g.user_id = u.id  
        WHERE u.scheduler_type = 'Athletic Director' 
          AND g.status = 'Published'
        ORDER BY g.created_at DESC
        LIMIT 5
      ''');
      
      print('\\n📋 RECENT AD GAMES:');
      for (final game in recentAdGames) {
        print('  - Game ${game['id']}: "${game['opponent']}" @ "${game['home_team']}"');
        print('    Expected: "${game['school_name']} ${game['mascot']}"');
      }
    }

    // Also check the available games query specifically
    print('\\n📋 AVAILABLE GAMES QUERY TEST:');
    final availableGames = await gameRepo.rawQuery('''
      SELECT g.id, g.opponent, g.home_team, 
             sch.home_team_name as schedule_home_team_name
      FROM games g
      LEFT JOIN schedules sch ON g.schedule_id = sch.id
      LEFT JOIN users u ON g.user_id = u.id
      WHERE g.status = 'Published' 
        AND u.scheduler_type = 'Athletic Director'
        AND (g.opponent LIKE '%Collinsville%' OR g.opponent LIKE '%Kahoks%')
      LIMIT 1
    ''');

    if (availableGames.isNotEmpty) {
      final game = availableGames.first;
      print('  Available Games Data:');
      print('    opponent: "${game['opponent']}"');
      print('    home_team: "${game['home_team']}"');
      print('    schedule_home_team_name: "${game['schedule_home_team_name']}"');
      
      final finalHomeTeam = game['schedule_home_team_name'] ?? game['home_team'] ?? 'Home Team';
      print('    Final home team (using fallback logic): "$finalHomeTeam"');
      print('    Display would be: "${game['opponent']}" @ "$finalHomeTeam"');
    }

  } catch (e) {
    print('❌ Error: $e');
  }
  
  print('\\n=== END DEBUG ===');
}