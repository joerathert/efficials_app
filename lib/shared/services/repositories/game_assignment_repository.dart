import 'base_repository.dart';
import '../../models/database_models.dart';

class GameAssignmentRepository extends BaseRepository {
  
  // Get all assignments for a specific official
  Future<List<GameAssignment>> getAssignmentsForOfficial(int officialId) async {
    final results = await rawQuery('''
      SELECT ga.*, g.date, g.time, g.opponent, g.home_team, g.game_fee, g.level_of_competition,
             l.name as location_name, l.address as location_address,
             s.name as sport_name
      FROM game_assignments ga
      JOIN games g ON ga.game_id = g.id
      LEFT JOIN locations l ON g.location_id = l.id
      LEFT JOIN sports s ON g.sport_id = s.id
      WHERE ga.official_id = ?
      ORDER BY g.date ASC, g.time ASC
    ''', [officialId]);
    
    return results.map((data) => GameAssignment.fromMap(data)).toList();
  }
  
  // Get assignments by status for a specific official
  Future<List<GameAssignment>> getAssignmentsByStatus(int officialId, String status) async {
    final results = await rawQuery('''
      SELECT ga.*, g.date, g.time, g.opponent, g.home_team, g.game_fee, g.level_of_competition,
             l.name as location_name, l.address as location_address,
             s.name as sport_name
      FROM game_assignments ga
      JOIN games g ON ga.game_id = g.id
      LEFT JOIN locations l ON g.location_id = l.id
      LEFT JOIN sports s ON g.sport_id = s.id
      WHERE ga.official_id = ? AND ga.status = ?
      ORDER BY g.date ASC, g.time ASC
    ''', [officialId, status]);
    
    return results.map((data) => GameAssignment.fromMap(data)).toList();
  }
  
  // Get available games for an official (games that match their sports/criteria but aren't assigned yet)
  Future<List<Map<String, dynamic>>> getAvailableGamesForOfficial(int officialId) async {
    final results = await rawQuery('''
      SELECT DISTINCT g.*, l.name as location_name, l.address as location_address,
             s.name as sport_name, u.first_name, u.last_name,
             'available' as assignment_status
      FROM games g
      LEFT JOIN locations l ON g.location_id = l.id
      LEFT JOIN sports s ON g.sport_id = s.id
      LEFT JOIN users u ON g.user_id = u.id
      WHERE g.id NOT IN (
        SELECT ga.game_id 
        FROM game_assignments ga 
        WHERE ga.official_id = ?
      )
      AND g.status = 'Published'
      AND g.date >= date('now')
      AND g.officials_required > g.officials_hired
      ORDER BY g.date ASC, g.time ASC
    ''', [officialId]);
    
    return results;
  }
  
  // Create a new assignment
  Future<int> createAssignment(GameAssignment assignment) async {
    return await insert('game_assignments', assignment.toMap());
  }
  
  // Update assignment status (accept/decline)
  Future<int> updateAssignmentStatus(int assignmentId, String status, {String? responseNotes}) async {
    final data = {
      'status': status,
      'responded_at': DateTime.now().toIso8601String(),
    };
    
    if (responseNotes != null) {
      data['response_notes'] = responseNotes;
    }
    
    return await update('game_assignments', data, 'id = ?', [assignmentId]);
  }
  
  // Get assignment by game and official
  Future<GameAssignment?> getAssignmentByGameAndOfficial(int gameId, int officialId) async {
    final results = await query(
      'game_assignments',
      where: 'game_id = ? AND official_id = ?',
      whereArgs: [gameId, officialId],
    );
    
    if (results.isEmpty) return null;
    return GameAssignment.fromMap(results.first);
  }
  
  // Express interest in a game (create pending assignment)
  Future<int> expressInterest(int gameId, int officialId, double? feeAmount) async {
    final assignment = GameAssignment(
      gameId: gameId,
      officialId: officialId,
      status: 'pending',
      assignedBy: officialId, // Official is expressing interest, so they're the one initiating
      assignedAt: DateTime.now(),
      feeAmount: feeAmount,
    );
    
    return await createAssignment(assignment);
  }

  // Claim a game (create accepted assignment and increment officials_hired)
  Future<int> claimGame(int gameId, int officialId, double? feeAmount) async {
    try {
      // Start a transaction to ensure consistency
      final assignment = GameAssignment(
        gameId: gameId,
        officialId: officialId,
        status: 'accepted',
        assignedBy: officialId, // Official is claiming the game
        assignedAt: DateTime.now(),
        respondedAt: DateTime.now(),
        feeAmount: feeAmount,
      );
      
      // Create the assignment
      final assignmentId = await createAssignment(assignment);
      
      // Increment the officials_hired count for the game
      await rawQuery('''
        UPDATE games 
        SET officials_hired = officials_hired + 1 
        WHERE id = ?
      ''', [gameId]);
      
      return assignmentId;
    } catch (e) {
      print('Error claiming game: $e');
      throw Exception('Failed to claim game: ${e.toString()}');
    }
  }
  
  // Withdraw interest in a game
  Future<int> withdrawInterest(int gameId, int officialId) async {
    return await delete('game_assignments', 'game_id = ? AND official_id = ? AND status = ?', 
                      [gameId, officialId, 'pending']);
  }
  
  // Get all interested officials for a specific game (pending assignments)
  Future<List<Map<String, dynamic>>> getInterestedOfficialsForGame(int gameId) async {
    final results = await rawQuery('''
      SELECT o.id, o.name, o.phone, o.email, o.experience_years,
             ga.assigned_at, ga.fee_amount,
             COALESCE(0, 0) as distance
      FROM game_assignments ga
      JOIN officials o ON ga.official_id = o.id
      WHERE ga.game_id = ? AND ga.status = 'pending'
      ORDER BY ga.assigned_at ASC
    ''', [gameId]);
    
    return results;
  }

  // Get all confirmed officials for a specific game (accepted assignments)
  Future<List<Map<String, dynamic>>> getConfirmedOfficialsForGame(int gameId) async {
    final results = await rawQuery('''
      SELECT o.id, o.name, o.phone, o.email, o.experience_years,
             ga.assigned_at, ga.responded_at, ga.fee_amount,
             COALESCE(0, 0) as distance
      FROM game_assignments ga
      JOIN officials o ON ga.official_id = o.id
      WHERE ga.game_id = ? AND ga.status = 'accepted'
      ORDER BY ga.responded_at ASC
    ''', [gameId]);
    
    return results;
  }

  // Get scheduler information for a specific game
  Future<Map<String, dynamic>?> getSchedulerForGame(int gameId) async {
    final results = await rawQuery('''
      SELECT u.id, u.first_name, u.last_name, u.email, u.phone,
             COALESCE(u.first_name || ' ' || u.last_name, u.first_name, u.last_name, 'Unknown') as name
      FROM games g
      JOIN users u ON g.user_id = u.id
      WHERE g.id = ?
      LIMIT 1
    ''', [gameId]);
    
    return results.isNotEmpty ? results.first : null;
  }

  // Back out of a game (for confirmed assignments)
  Future<int> backOutOfGame(int assignmentId, String reason) async {
    try {
      final data = {
        'status': 'backed_out',
        'backed_out_at': DateTime.now().toIso8601String(),
        'back_out_reason': reason,
      };
      
      final result = await update('game_assignments', data, 'id = ?', [assignmentId]);
      
      // Decrease the officials_hired count for the game to allow position to be refilled
      final assignment = await rawQuery('''
        SELECT game_id FROM game_assignments WHERE id = ?
      ''', [assignmentId]);
      
      if (assignment.isNotEmpty) {
        final gameId = assignment.first['game_id'];
        await rawQuery('''
          UPDATE games 
          SET officials_hired = CASE 
            WHEN officials_hired > 0 THEN officials_hired - 1 
            ELSE 0 
          END 
          WHERE id = ?
        ''', [gameId]);
      }
      
      return result;
    } catch (e) {
      print('Error backing out of game: $e');
      throw Exception('Failed to back out of game: ${e.toString()}');
    }
  }
}