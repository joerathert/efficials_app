import 'dart:io';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';

void main() async {
  // Initialize FFI for desktop
  if (Platform.isLinux || Platform.isWindows || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }
  
  try {
    final dbPath = join(Directory.current.path, 'efficials.db');
    print('Opening database at: $dbPath');
    
    final db = await openDatabase(dbPath);
    
    print('\n=== DEBUGGING GAME CLAIM ISSUE ===');
    
    // Test parameters - you may need to adjust these
    const officialId = 1;
    const gameId = 1; // Use the actual game ID you're testing with
    
    print('\n1. Check if game exists:');
    final games = await db.rawQuery('''
      SELECT id, method, status, officials_required, officials_hired, game_fee 
      FROM games WHERE id = ?
    ''', [gameId]);
    
    if (games.isEmpty) {
      print('❌ No game found with ID $gameId');
      return;
    }
    
    print('✅ Game found: ${games.first}');
    
    print('\n2. Check existing assignments for this official/game:');
    final existingAssignments = await db.rawQuery('''
      SELECT * FROM game_assignments WHERE game_id = ? AND official_id = ?
    ''', [gameId, officialId]);
    
    print('Found ${existingAssignments.length} existing assignments:');
    for (var assignment in existingAssignments) {
      print('  - Assignment: ${assignment}');
    }
    
    print('\n3. Check available games query:');
    final availableGames = await db.rawQuery('''
      SELECT DISTINCT g.id, g.method, g.status, g.officials_required, g.officials_hired, 
             s.name as sport_name, g.game_fee
      FROM games g
      LEFT JOIN sports s ON g.sport_id = s.id
      WHERE g.id NOT IN (
        SELECT ga.game_id 
        FROM game_assignments ga 
        WHERE ga.official_id = ?
      )
      AND g.status = 'Published'
      AND g.officials_required > g.officials_hired
      AND g.id = ?
    ''', [officialId, gameId]);
    
    print('Available games matching ID $gameId for official $officialId:');
    for (var game in availableGames) {
      print('  - Available game: ${game}');
    }
    
    print('\n4. Check accepted games query:');
    final acceptedGames = await db.rawQuery('''
      SELECT ga.*, g.date, g.time, g.opponent, g.home_team, g.game_fee as fee_amount, 
             s.name as sport_name
      FROM game_assignments ga
      JOIN games g ON ga.game_id = g.id
      LEFT JOIN sports s ON g.sport_id = s.id
      WHERE ga.official_id = ? AND ga.status = 'accepted' AND ga.game_id = ?
    ''', [officialId, gameId]);
    
    print('Accepted games matching ID $gameId for official $officialId:');
    for (var assignment in acceptedGames) {
      print('  - Accepted assignment: ${assignment}');
    }
    
    await db.close();
    print('\n✅ Debug complete!');
    
  } catch (e, stackTrace) {
    print('❌ Error: $e');
    print('Stack trace: $stackTrace');
  }
}