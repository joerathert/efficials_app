import 'lib/shared/services/repositories/game_assignment_repository.dart';

/// Test the home team generation SQL query directly
void main() async {
  final gameRepo = GameAssignmentRepository();
  
  print('=== TESTING HOME TEAM QUERY ===\n');
  
  try {
    // Test our CASE statement SQL directly on AD games
    final testQuery = await gameRepo.rawQuery('''
      SELECT 
        g.id,
        g.opponent,
        g.home_team as stored_home_team,
        u.first_name,
        u.last_name,
        u.scheduler_type,
        u.school_name,
        u.mascot,
        -- Our CASE statement logic
        CASE 
          WHEN g.home_team IS NOT NULL AND g.home_team != '' AND g.home_team != 'Home Team' 
          THEN g.home_team
          WHEN u.scheduler_type = 'Athletic Director' AND u.school_name IS NOT NULL AND u.mascot IS NOT NULL
          THEN u.school_name || ' ' || u.mascot
          ELSE COALESCE(g.home_team, 'Home Team')
        END as calculated_home_team
      FROM games g
      LEFT JOIN users u ON g.user_id = u.id
      WHERE u.scheduler_type = 'Athletic Director'
        AND g.status = 'Published'
      ORDER BY g.created_at DESC
      LIMIT 5
    ''');

    print('📋 HOME TEAM CALCULATION TEST:');
    if (testQuery.isEmpty) {
      print('  ❌ No published AD games found');
    } else {
      for (final game in testQuery) {
        print('\\n  Game ${game['id']}:');
        print('    Opponent: "${game['opponent']}"');
        print('    Stored home_team: "${game['stored_home_team']}"');
        print('    AD: ${game['first_name']} ${game['last_name']}');
        print('    Scheduler Type: ${game['scheduler_type']}');
        print('    School Name: "${game['school_name']}"');
        print('    Mascot: "${game['mascot']}"');
        print('    Calculated home_team: "${game['calculated_home_team']}"');
        print('    Expected display: "${game['opponent']}" @ "${game['calculated_home_team']}"');
        
        // Check for issues
        if (game['calculated_home_team'] == null || game['calculated_home_team'].toString().trim().isEmpty) {
          print('    ❌ ISSUE: Calculated home team is empty!');
        } else if (game['calculated_home_team'] == 'Home Team') {
          print('    ⚠️  WARNING: Using fallback home team');
        }
      }
    }

    // Also test the actual available games query structure
    print('\\n📋 TESTING AVAILABLE GAMES QUERY STRUCTURE:');
    final availableGamesTest = await gameRepo.rawQuery('''
      SELECT DISTINCT 
        g.id, g.opponent,
        -- Test our CASE statement in the actual query context
        CASE 
          WHEN g.home_team IS NOT NULL AND g.home_team != '' AND g.home_team != 'Home Team' 
          THEN g.home_team
          WHEN u.scheduler_type = 'Athletic Director' AND u.school_name IS NOT NULL AND u.mascot IS NOT NULL
          THEN u.school_name || ' ' || u.mascot
          ELSE COALESCE(g.home_team, 'Home Team')
        END as home_team,
        u.scheduler_type
      FROM games g
      LEFT JOIN users u ON g.user_id = u.id
      WHERE g.status = 'Published' 
        AND u.scheduler_type = 'Athletic Director'
      ORDER BY g.created_at DESC
      LIMIT 3
    ''');

    if (availableGamesTest.isEmpty) {
      print('  ❌ No results from available games query structure');
    } else {
      for (final game in availableGamesTest) {
        print('  - Game ${game['id']}: "${game['opponent']}" @ "${game['home_team']}"');
      }
    }

  } catch (e) {
    print('❌ Error: $e');
    print('❌ Stack trace: ${e.toString()}');
  }
  
  print('\\n=== TEST COMPLETE ===');
}