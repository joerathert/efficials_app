import 'lib/shared/services/repositories/game_assignment_repository.dart';

/// Check what Athletic Director profile data is actually stored
void main() async {
  final gameRepo = GameAssignmentRepository();
  
  print('=== CHECKING AD PROFILE DATA ===\n');
  
  try {
    // Get all Athletic Director users and their profile data
    final adUsers = await gameRepo.rawQuery('''
      SELECT id, first_name, last_name, email, 
             school_name, mascot, school_address,
             setup_completed, created_at
      FROM users 
      WHERE scheduler_type = 'Athletic Director'
      ORDER BY created_at DESC
    ''');

    print('📋 ATHLETIC DIRECTOR USERS:');
    if (adUsers.isEmpty) {
      print('  ❌ No Athletic Directors found in database');
    } else {
      print('  Found ${adUsers.length} Athletic Director(s):');
      
      for (int i = 0; i < adUsers.length; i++) {
        final ad = adUsers[i];
        print('\\n  ${i + 1}. ${ad['first_name']} ${ad['last_name']} (ID: ${ad['id']})');
        print('     Email: ${ad['email']}');
        print('     School Name: "${ad['school_name']}"');
        print('     Mascot: "${ad['mascot']}"');
        print('     School Address: "${ad['school_address']}"');
        print('     Setup Completed: ${ad['setup_completed']}');
        print('     Created: ${ad['created_at']}');
        
        // Expected home team
        if (ad['school_name'] != null && ad['mascot'] != null) {
          final expectedHomeTeam = '${ad['school_name']} ${ad['mascot']}';
          print('     Expected Home Team: "$expectedHomeTeam"');
        } else {
          print('     ⚠️  Missing school name or mascot - cannot generate home team');
        }
      }
    }

    // Check games created by Athletic Directors
    print('\\n📋 GAMES CREATED BY ATHLETIC DIRECTORS:');
    final adGames = await gameRepo.rawQuery('''
      SELECT g.id, g.opponent, g.home_team, g.status,
             u.first_name, u.last_name, u.school_name, u.mascot
      FROM games g
      JOIN users u ON g.user_id = u.id  
      WHERE u.scheduler_type = 'Athletic Director'
      ORDER BY g.created_at DESC
      LIMIT 10
    ''');

    if (adGames.isEmpty) {
      print('  ❌ No games found created by Athletic Directors');
    } else {
      for (final game in adGames) {
        print('  - Game ${game['id']} (${game['status']}): "${game['opponent']}" @ "${game['home_team']}"');
        print('    Created by: ${game['first_name']} ${game['last_name']}');
        print('    AD Profile: School="${game['school_name']}", Mascot="${game['mascot']}"');
        
        if (game['home_team'] == null || game['home_team'].toString().trim().isEmpty) {
          print('    ❌ Home team is empty!');
        }
      }
    }

    // Check if there are any user session or authentication issues
    print('\\n📋 ALL USERS (for reference):');
    final allUsers = await gameRepo.rawQuery('''
      SELECT id, first_name, last_name, scheduler_type, setup_completed
      FROM users 
      ORDER BY created_at DESC
      LIMIT 5
    ''');

    for (final user in allUsers) {
      print('  - ${user['first_name']} ${user['last_name']} (${user['scheduler_type']}, ID: ${user['id']}, Setup: ${user['setup_completed']})');
    }

  } catch (e) {
    print('❌ Error: $e');
  }
  
  print('\\n=== END CHECK ===');
}