import 'lib/shared/services/repositories/game_assignment_repository.dart';

/// Script to fix home team data for existing Athletic Director games
void main() async {
  final gameRepo = GameAssignmentRepository();
  
  print('=== FIXING HOME TEAM DATA FOR AD GAMES ===\n');
  
  try {
    // 1. Find AD games with missing or empty home_team
    final adGamesWithMissingHomeTeam = await gameRepo.rawQuery('''
      SELECT g.id, g.opponent, g.home_team, u.id as user_id, 
             u.first_name, u.last_name, u.school_name, u.mascot
      FROM games g
      JOIN users u ON g.user_id = u.id  
      WHERE u.scheduler_type = 'Athletic Director' 
        AND (g.home_team IS NULL OR g.home_team = '' OR g.home_team = 'Home Team' OR g.home_team = 'null')
        AND u.school_name IS NOT NULL 
        AND u.mascot IS NOT NULL
        AND u.school_name != ''
        AND u.mascot != ''
      ORDER BY g.created_at DESC
    ''');

    print('📋 AD GAMES WITH MISSING HOME TEAM:');
    if (adGamesWithMissingHomeTeam.isEmpty) {
      print('  ✅ No AD games found with missing home team data');
    } else {
      print('  Found ${adGamesWithMissingHomeTeam.length} games to fix:');
      
      for (final game in adGamesWithMissingHomeTeam) {
        final gameId = game['id'];
        final schoolName = game['school_name'] as String;
        final mascot = game['mascot'] as String;
        final newHomeTeam = '$schoolName $mascot';
        
        print('    - Game $gameId: "${game['opponent']}" @ "${game['home_team']}" -> "$newHomeTeam"');
        
        // Update the game with correct home team
        try {
          await gameRepo.rawQuery('''
            UPDATE games 
            SET home_team = ?, updated_at = ?
            WHERE id = ?
          ''', [newHomeTeam, DateTime.now().toIso8601String(), gameId]);
          
          print('      ✅ Updated successfully');
        } catch (e) {
          print('      ❌ Failed to update: $e');
        }
      }
    }

    // 2. Verify the fixes
    print('\n📋 VERIFICATION - RECENT AD GAMES AFTER FIX:');
    final verificationGames = await gameRepo.rawQuery('''
      SELECT g.id, g.opponent, g.home_team, u.first_name, u.last_name
      FROM games g
      JOIN users u ON g.user_id = u.id  
      WHERE u.scheduler_type = 'Athletic Director' 
        AND g.status = 'Published'
      ORDER BY g.created_at DESC
      LIMIT 5
    ''');

    if (verificationGames.isEmpty) {
      print('  ❌ No published AD games found for verification');
    } else {
      for (final game in verificationGames) {
        print('  - Game ${game['id']}: "${game['opponent']}" @ "${game['home_team']}"');
      }
    }

    // 3. Check for ADs with missing school info
    print('\n📋 ATHLETIC DIRECTORS WITH MISSING SCHOOL INFO:');
    final adsWithMissingInfo = await gameRepo.rawQuery('''
      SELECT id, first_name, last_name, school_name, mascot
      FROM users 
      WHERE scheduler_type = 'Athletic Director'
        AND (school_name IS NULL OR school_name = '' OR mascot IS NULL OR mascot = '')
    ''');

    if (adsWithMissingInfo.isEmpty) {
      print('  ✅ All Athletic Directors have complete school information');
    } else {
      print('  ⚠️  Found ${adsWithMissingInfo.length} ADs with missing school info:');
      for (final ad in adsWithMissingInfo) {
        print('    - ${ad['first_name']} ${ad['last_name']} (ID: ${ad['id']})');
        print('      School: "${ad['school_name']}", Mascot: "${ad['mascot']}"');
      }
    }

  } catch (e) {
    print('❌ Error: $e');
  }
  
  print('\n=== FIX COMPLETE ===');
}