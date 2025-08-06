import 'lib/shared/services/repositories/game_assignment_repository.dart';

/// One-time migration to fix home team data for all Athletic Director games
void main() async {
  final gameRepo = GameAssignmentRepository();
  
  print('=== MIGRATING HOME TEAM DATA FOR ALL AD GAMES ===\n');
  
  try {
    // Update all AD games with missing home team data
    final result = await gameRepo.rawQuery('''
      UPDATE games 
      SET home_team = (
        SELECT u.school_name || ' ' || u.mascot 
        FROM users u 
        WHERE u.id = games.user_id
          AND u.scheduler_type = 'Athletic Director'
          AND u.school_name IS NOT NULL 
          AND u.school_name != ''
          AND u.mascot IS NOT NULL 
          AND u.mascot != ''
      ),
      updated_at = ?
      WHERE user_id IN (
        SELECT u.id 
        FROM users u 
        WHERE u.scheduler_type = 'Athletic Director'
          AND u.school_name IS NOT NULL 
          AND u.school_name != ''
          AND u.mascot IS NOT NULL 
          AND u.mascot != ''
      )
      AND (
        home_team IS NULL 
        OR home_team = '' 
        OR home_team = 'Home Team' 
        OR home_team = 'null'
      )
    ''', [DateTime.now().toIso8601String()]);

    print('✅ Migration completed successfully');
    
    // Verify the migration
    final verificationGames = await gameRepo.rawQuery('''
      SELECT g.id, g.opponent, g.home_team, u.first_name, u.last_name,
             u.school_name, u.mascot
      FROM games g
      JOIN users u ON g.user_id = u.id  
      WHERE u.scheduler_type = 'Athletic Director' 
        AND g.status = 'Published'
      ORDER BY g.created_at DESC
      LIMIT 10
    ''');

    print('\\n📋 VERIFICATION - AD GAMES AFTER MIGRATION:');
    if (verificationGames.isEmpty) {
      print('  ❌ No published AD games found for verification');
    } else {
      for (final game in verificationGames) {
        print('  - Game ${game['id']}: "${game['opponent']}" @ "${game['home_team']}"');
        print('    AD: ${game['first_name']} ${game['last_name']} (${game['school_name']} ${game['mascot']})');
        
        if (game['home_team'] == null || game['home_team'].toString().trim().isEmpty) {
          print('    ⚠️  Still missing home team!');
        }
      }
    }

    // Check for any remaining issues
    final stillMissingHomeTeam = await gameRepo.rawQuery('''
      SELECT COUNT(*) as count
      FROM games g
      JOIN users u ON g.user_id = u.id  
      WHERE u.scheduler_type = 'Athletic Director' 
        AND g.status = 'Published'
        AND (g.home_team IS NULL OR g.home_team = '' OR g.home_team = 'Home Team')
    ''');

    final missingCount = stillMissingHomeTeam.first['count'] as int;
    if (missingCount > 0) {
      print('\\n⚠️  WARNING: $missingCount AD games still have missing home team data');
      print('   This may indicate ADs with incomplete profile information');
    } else {
      print('\\n✅ All AD games now have home team data');
    }

  } catch (e) {
    print('❌ Migration failed: $e');
  }
  
  print('\\n=== MIGRATION COMPLETE ===');
}