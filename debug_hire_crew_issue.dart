import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';

Future<void> main() async {
  // Initialize FFI
  sqfliteCommonFfiInit();
  databaseFactory = databaseFactoryFfi;
  
  final dbPath = join('lib', 'shared', 'database', 'efficials.db');
  final db = await openDatabase(dbPath);
  
  print('🔍 DEBUG: Hire a Crew Issue Investigation');
  print('=' * 60);
  
  // 1. Check for hire_crew games
  final hireCrew GamesResults = await db.rawQuery('''
    SELECT g.id, g.opponent, g.home_team, g.method, g.status, g.officials_required, g.officials_hired,
           u.first_name, u.last_name
    FROM games g
    LEFT JOIN users u ON g.user_id = u.id
    WHERE g.method = 'hire_crew' AND g.status = 'Published'
    ORDER BY g.created_at DESC
    LIMIT 5
  ''');
  
  print('📝 Recent hire_crew games:');
  if (hireCrewGamesResults.isEmpty) {
    print('  No hire_crew games found in Published status');
  } else {
    for (var game in hireCrewGamesResults) {
      print('  Game ${game['id']}: ${game['opponent']} @ ${game['home_team']}');
      print('    Status: ${game['status']}, Officials: ${game['officials_hired']}/${game['officials_required']}');
      print('    Scheduler: ${game['first_name']} ${game['last_name']}');
    }
  }
  print('');
  
  // 2. Check for crew assignments related to these games
  if (hireCrewGamesResults.isNotEmpty) {
    final gameIds = hireCrewGamesResults.map((g) => g['id']).join(',');
    final crewAssignmentsResults = await db.rawQuery('''
      SELECT ca.game_id, ca.crew_id, ca.crew_chief_id, ca.status, ca.assigned_at, ca.responded_at,
             c.name as crew_name, o.name as crew_chief_name
      FROM crew_assignments ca
      JOIN crews c ON ca.crew_id = c.id
      JOIN officials o ON c.crew_chief_id = o.id
      WHERE ca.game_id IN ($gameIds)
    ''');
    
    print('📋 Crew assignments for these games:');
    if (crewAssignmentsResults.isEmpty) {
      print('  No crew assignments found for these hire_crew games - THIS IS THE PROBLEM!');
    } else {
      for (var assignment in crewAssignmentsResults) {
        print('  Game ${assignment['game_id']}: ${assignment['crew_name']} (Chief: ${assignment['crew_chief_name']})');
        print('    Status: ${assignment['status']}, Assigned: ${assignment['assigned_at']}, Responded: ${assignment['responded_at']}');
      }
    }
    print('');
  }
  
  // 3. Check for active crews and their chiefs
  final activeCrewsResults = await db.rawQuery('''
    SELECT c.id, c.name, c.crew_chief_id, o.name as crew_chief_name, c.is_active,
           COUNT(cm.id) as member_count
    FROM crews c
    JOIN officials o ON c.crew_chief_id = o.id
    LEFT JOIN crew_members cm ON c.id = cm.crew_id AND cm.status = 'active'
    WHERE c.is_active = 1
    GROUP BY c.id, c.name, c.crew_chief_id, o.name, c.is_active
    ORDER BY c.created_at DESC
  ''');
  
  print('👥 Active crews:');
  if (activeCrewsResults.isEmpty) {
    print('  No active crews found');
  } else {
    for (var crew in activeCrewsResults) {
      print('  Crew ${crew['id']}: ${crew['name']} (Chief: ${crew['crew_chief_name']})');
      print('    Active: ${crew['is_active']}, Members: ${crew['member_count']}');
    }
  }
  print('');
  
  // 4. Check what happens when we run the available games query for a crew chief
  if (activeCrewsResults.isNotEmpty) {
    final crewChiefId = activeCrewsResults.first['crew_chief_id'] as int;
    final crewChiefName = activeCrewsResults.first['crew_chief_name'] as String;
    
    print('🎯 Testing available games query for crew chief: $crewChiefName (ID: $crewChiefId)');
    
    // First, check if they are identified as a crew chief
    final isCrewChiefResults = await db.rawQuery('''
      SELECT 1 FROM crews 
      WHERE crew_chief_id = ? AND is_active = 1
      LIMIT 1
    ''', [crewChiefId]);
    
    print('  Is crew chief: ${isCrewChiefResults.isNotEmpty}');
    
    // Check for hire_crew games they should see
    final availableHireCrewGames = await db.rawQuery('''
      SELECT g.id, g.opponent, g.home_team, g.method, g.status
      FROM games g
      WHERE g.id NOT IN (
        SELECT ga.game_id 
        FROM game_assignments ga 
        WHERE ga.official_id = ?
      )
      AND g.id NOT IN (
        SELECT gd.game_id 
        FROM game_dismissals gd 
        WHERE gd.official_id = ?
      )
      AND g.status = 'Published'
      AND g.date >= date('now')
      AND g.officials_required > g.officials_hired
      AND g.method = 'hire_crew'
      AND g.id IN (
        SELECT ca.game_id 
        FROM crew_assignments ca
        JOIN crews c ON ca.crew_id = c.id
        WHERE c.crew_chief_id = ? AND ca.status = 'pending'
      )
    ''', [crewChiefId, crewChiefId, crewChiefId]);
    
    print('  Available hire_crew games for this chief: ${availableHireCrewGames.length}');
    for (var game in availableHireCrewGames) {
      print('    Game ${game['id']}: ${game['opponent']} @ ${game['home_team']}');
    }
  }
  
  await db.close();
}