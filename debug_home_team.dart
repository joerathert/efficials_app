import 'lib/shared/services/repositories/game_assignment_repository.dart';

/// Debug script to investigate home team display issue
void main() async {
  final gameRepo = GameAssignmentRepository();
  
  print('=== DEBUGGING HOME TEAM DISPLAY ISSUE ===\n');
  
  try {
    // 1. Check recent AD games and their home team data
    final adGames = await gameRepo.rawQuery('''
      SELECT g.id, g.opponent, g.home_team, u.first_name, u.last_name, 
             u.school_name, u.mascot, g.created_at
      FROM games g
      JOIN users u ON g.user_id = u.id  
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
        print('  - Game ${game['id']}: "${game['opponent']}" @ "${game['home_team']}"');
        print('    AD: ${game['first_name']} ${game['last_name']}');
        print('    School: "${game['school_name']}", Mascot: "${game['mascot']}"');
        print('    Expected home team: "${game['school_name']} ${game['mascot']}"');
        print('');
      }
    }

    // 2. Check the available games query to see how home team appears
    print('📋 AVAILABLE GAMES QUERY RESULTS:');
    final availableGames = await gameRepo.rawQuery('''
      SELECT DISTINCT 
        g.id, g.opponent, g.home_team, 
        sch.home_team_name as schedule_home_team_name,
        u.first_name, u.last_name
      FROM games g
      LEFT JOIN schedules sch ON g.schedule_id = sch.id
      LEFT JOIN users u ON g.user_id = u.id
      WHERE g.status = 'Published' 
        AND u.scheduler_type = 'Athletic Director'
      ORDER BY g.created_at DESC
      LIMIT 5
    ''');

    if (availableGames.isEmpty) {
      print('  ❌ No available AD games found');
    } else {
      for (final game in availableGames) {
        print('  - Game ${game['id']}:');
        print('    opponent: "${game['opponent']}"');
        print('    home_team: "${game['home_team']}"');
        print('    schedule_home_team_name: "${game['schedule_home_team_name']}"');
        print('    Expected display: "${game['opponent']}" @ "${game['schedule_home_team_name'] ?? game['home_team'] ?? 'Home Team'}"');
        print('');
      }
    }

    // 3. Check Athletic Director profiles
    print('📋 ATHLETIC DIRECTOR PROFILES:');
    final adProfiles = await gameRepo.rawQuery('''
      SELECT id, first_name, last_name, school_name, mascot
      FROM users 
      WHERE scheduler_type = 'Athletic Director'
      LIMIT 5
    ''');

    if (adProfiles.isEmpty) {
      print('  ❌ No Athletic Directors found');
    } else {
      for (final ad in adProfiles) {
        print('  - ${ad['first_name']} ${ad['last_name']} (ID: ${ad['id']})');
        print('    School: "${ad['school_name']}", Mascot: "${ad['mascot']}"');
        print('    Expected home team: "${ad['school_name']} ${ad['mascot']}"');
        print('');
      }
    }

  } catch (e) {
    print('❌ Error: $e');
  }
  
  print('=== END DEBUG ===');
}