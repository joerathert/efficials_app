import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'base_repository.dart';
import '../../models/database_models.dart';
import 'notification_repository.dart';
import 'advanced_method_repository.dart';
import 'package:flutter/foundation.dart'; // Added for debugPrint

/// Exception thrown when there's a soft conflict that requires user confirmation
class SoftConflictException implements Exception {
  final String message;
  final List<Map<String, dynamic>> conflictingGames;

  SoftConflictException(this.message, this.conflictingGames);

  @override
  String toString() => message;
}

class GameAssignmentRepository extends BaseRepository {
  final AdvancedMethodRepository _advancedMethodRepo =
      AdvancedMethodRepository();

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
  Future<List<GameAssignment>> getAssignmentsByStatus(
      int officialId, String status) async {
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

  // Optimized batch method to get all assignment data for home screen
  Future<Map<String, dynamic>> getOfficialHomeData(int officialId) async {
    // Get accepted games
    final acceptedResults = await rawQuery('''
      SELECT 
        ga.id, ga.game_id, ga.official_id, ga.position, ga.status,
        ga.assigned_by, ga.assigned_at, ga.responded_at, ga.response_notes,
        ga.backed_out_at, ga.back_out_reason, ga.excused_backout,
        ga.excused_at, ga.excused_by, ga.excuse_reason,
        CASE 
          WHEN ga.fee_amount IS NOT NULL AND ga.fee_amount > 0 THEN ga.fee_amount 
          ELSE g.game_fee 
        END as fee_amount,
        g.date, g.time, g.opponent, g.level_of_competition,
        sch.home_team_name as schedule_home_team_name,
        u.first_name, u.last_name,
        -- Dynamic home team: prioritize schedule_home_team_name for Assigners, then AD profile, then stored home_team
        CASE 
          WHEN sch.home_team_name IS NOT NULL AND sch.home_team_name != '' AND sch.home_team_name != 'Home Team'
          THEN sch.home_team_name
          WHEN g.home_team IS NOT NULL AND g.home_team != '' AND g.home_team != 'Home Team' 
          THEN g.home_team
          WHEN u.scheduler_type = 'Athletic Director' AND u.school_name IS NOT NULL AND u.mascot IS NOT NULL
          THEN u.school_name || ' ' || u.mascot
          ELSE COALESCE(g.home_team, 'Home Team')
        END as home_team,
        l.name as location_name, l.address as location_address,
        s.name as sport_name,
        sch.name as schedule_name
      FROM game_assignments ga
      JOIN games g ON ga.game_id = g.id
      LEFT JOIN locations l ON g.location_id = l.id
      LEFT JOIN sports s ON g.sport_id = s.id
      LEFT JOIN schedules sch ON g.schedule_id = sch.id
      LEFT JOIN users u ON g.user_id = u.id
      WHERE ga.official_id = ? AND ga.status = 'accepted'
      ORDER BY g.date ASC, g.time ASC
    ''', [officialId]);

    // Get pending games
    final pendingResults = await rawQuery('''
      SELECT ga.id, ga.game_id, ga.official_id, ga.position, ga.status,
             ga.assigned_by, ga.assigned_at, ga.responded_at, ga.response_notes,
             ga.backed_out_at, ga.back_out_reason, ga.excused_backout,
             ga.excused_at, ga.excused_by, ga.excuse_reason,
             ga.fee_amount,
             g.date, g.time, g.opponent, g.level_of_competition, g.game_fee,
             sch.home_team_name as schedule_home_team_name,
             u.first_name, u.last_name,
             -- Dynamic home team: prioritize schedule_home_team_name for Assigners, then AD profile, then stored home_team
             CASE 
               WHEN sch.home_team_name IS NOT NULL AND sch.home_team_name != '' AND sch.home_team_name != 'Home Team'
               THEN sch.home_team_name
               WHEN g.home_team IS NOT NULL AND g.home_team != '' AND g.home_team != 'Home Team' 
               THEN g.home_team
               WHEN u.scheduler_type = 'Athletic Director' AND u.school_name IS NOT NULL AND u.mascot IS NOT NULL
               THEN u.school_name || ' ' || u.mascot
               ELSE COALESCE(g.home_team, 'Home Team')
             END as home_team,
             l.name as location_name, l.address as location_address,
             s.name as sport_name,
             sch.name as schedule_name
      FROM game_assignments ga
      JOIN games g ON ga.game_id = g.id
      LEFT JOIN locations l ON g.location_id = l.id
      LEFT JOIN sports s ON g.sport_id = s.id
      LEFT JOIN schedules sch ON g.schedule_id = sch.id
      LEFT JOIN users u ON g.user_id = u.id
      WHERE ga.official_id = ? AND ga.status = 'pending'
      ORDER BY g.date ASC, g.time ASC
    ''', [officialId]);

    // Get available games using Advanced Method filtering
    final availableResults =
        await _getAvailableGamesWithAdvancedFiltering(officialId);

    // Transform data
    final acceptedGames = acceptedResults
        .map((data) {
          try {
            return GameAssignment.fromMap(data);
          } catch (e) {
            print('Error mapping accepted game: $e');
            return null;
          }
        })
        .whereType<GameAssignment>()
        .toList();

    final pendingGames = pendingResults
        .map((data) {
          try {
            return GameAssignment.fromMap(data);
          } catch (e) {
            print('Error mapping pending game: $e');
            return null;
          }
        })
        .whereType<GameAssignment>()
        .toList();

    // Transform available games with scheduler info
    final availableGames = availableResults.map((game) {
      final firstName = game['first_name'] ?? '';
      final lastName = game['last_name'] ?? '';
      final scheduler = '$firstName $lastName'.trim();

      return Map<String, dynamic>.from(game)..['scheduler'] = scheduler;
    }).toList();

    return {
      'accepted': acceptedGames,
      'pending': pendingGames,
      'available': availableGames,
    };
  }

  // Get available games for an official (games that match their sports/criteria but aren't assigned yet)
  Future<List<Map<String, dynamic>>> getAvailableGamesForOfficial(
      int officialId) async {
    return await _getAvailableGamesWithAdvancedFiltering(officialId);
  }

  // Create a new assignment
  Future<int> createAssignment(GameAssignment assignment) async {
    return await insert('game_assignments', assignment.toMap());
  }

  // Update assignment status (accept/decline)
  Future<int> updateAssignmentStatus(int assignmentId, String status,
      {String? responseNotes}) async {
    final data = {
      'status': status,
      'responded_at': DateTime.now().toIso8601String(),
    };

    if (responseNotes != null) {
      data['response_notes'] = responseNotes;
    }

    final result =
        await update('game_assignments', data, 'id = ?', [assignmentId]);

    // If status is 'accepted', handle conflict detection and removal
    if (status == 'accepted') {
      final assignment = await rawQuery('''
        SELECT official_id, game_id FROM game_assignments WHERE id = ?
      ''', [assignmentId]);

      if (assignment.isNotEmpty) {
        final officialId = assignment.first['official_id'];
        final gameId = assignment.first['game_id'];

        // Remove from conflicting games
        await _removeFromConflictingGames(officialId, gameId);

        await rawQuery('''
          UPDATE officials 
          SET total_accepted_games = total_accepted_games + 1
          WHERE id = ?
        ''', [officialId]);

        // Recalculate follow-through rate
        await _updateOfficialFollowThroughRate(officialId);
      }
    }

    return result;
  }

  // Get assignment by game and official
  Future<GameAssignment?> getAssignmentByGameAndOfficial(
      int gameId, int officialId) async {
    final results = await query(
      'game_assignments',
      where: 'game_id = ? AND official_id = ?',
      whereArgs: [gameId, officialId],
    );

    if (results.isEmpty) return null;
    return GameAssignment.fromMap(results.first);
  }

  // Express interest in a game (create pending assignment)
  Future<int> expressInterest(
      int gameId, int officialId, double? feeAmount) async {
    // Note: This method now only checks for crew hiring and basic validation
    // For conflict checking, use expressInterestWithConflictCheck instead

    // Check if this is a crew hiring game and if the official is a crew chief
    final gameResult = await rawQuery('''
      SELECT method FROM games WHERE id = ?
    ''', [gameId]);

    if (gameResult.isNotEmpty && gameResult.first['method'] == 'hire_crew') {
      // Check if the official is a crew chief
      final isCrewChief = await _isOfficialCrewChief(officialId);
      if (isCrewChief) {
        // Handle crew-level interest instead of individual interest
        return await _expressCrewInterest(gameId, officialId, feeAmount);
      }
    }

    // Regular individual interest
    final assignment = GameAssignment(
      gameId: gameId,
      officialId: officialId,
      status: 'pending',
      assignedBy:
          officialId, // Official is expressing interest, so they're the one initiating
      assignedAt: DateTime.now(),
      feeAmount: feeAmount,
    );

    return await createAssignment(assignment);
  }

  // Express crew-level interest in a hire_crew game
  Future<int> _expressCrewInterest(
      int gameId, int crewChiefId, double? feeAmount) async {
    // Get the crew that this official is chief of
    final crewResult = await rawQuery('''
      SELECT id, name FROM crews 
      WHERE crew_chief_id = ? AND is_active = 1
      ORDER BY created_at DESC
      LIMIT 1
    ''', [crewChiefId]);

    if (crewResult.isEmpty) {
      throw Exception('No active crew found for this crew chief');
    }

    final crewId = crewResult.first['id'] as int;
    final crewName = crewResult.first['name'] as String;

    // Check if a crew assignment already exists
    final existingAssignment = await rawQuery('''
      SELECT id FROM crew_assignments 
      WHERE game_id = ? AND crew_id = ?
    ''', [gameId, crewId]);

    int crewAssignmentId;
    if (existingAssignment.isNotEmpty) {
      // Update existing crew assignment to mark that crew chief has responded
      crewAssignmentId = existingAssignment.first['id'] as int;
      await update(
          'crew_assignments',
          {
            'responded_at': DateTime.now().toIso8601String(),
            'crew_chief_response_required': 1,
          },
          'id = ?',
          [crewAssignmentId]);

      debugPrint(
          'Updated existing crew assignment $crewAssignmentId with responded_at timestamp');
    } else {
      // Create a new crew assignment record
      crewAssignmentId = await insert('crew_assignments', {
        'game_id': gameId,
        'crew_id': crewId,
        'crew_chief_id': crewChiefId,
        'status': 'pending',
        'assigned_by': crewChiefId,
        'assigned_at': DateTime.now().toIso8601String(),
        'responded_at': DateTime.now().toIso8601String(),
        'crew_chief_response_required': 1,
      });

      debugPrint('Created new crew assignment $crewAssignmentId');
    }

    // Check if individual assignment for crew chief already exists
    final existingIndividualAssignment =
        await getAssignmentByGameAndOfficial(gameId, crewChiefId);

    if (existingIndividualAssignment == null) {
      // Create individual assignment for the crew chief for compatibility
      final assignment = GameAssignment(
        gameId: gameId,
        officialId: crewChiefId,
        status: 'pending',
        assignedBy: crewChiefId,
        assignedAt: DateTime.now(),
        feeAmount: feeAmount,
        position: 'Crew Chief',
        responseNotes: 'Crew "$crewName" expressed interest',
      );

      await createAssignment(assignment);
      debugPrint('Created individual assignment for crew chief $crewChiefId');
    } else {
      // Update existing individual assignment
      await update(
          'game_assignments',
          {
            'responded_at': DateTime.now().toIso8601String(),
            'response_notes': 'Crew "$crewName" expressed interest',
          },
          'id = ?',
          [existingIndividualAssignment.id]);

      debugPrint(
          'Updated existing individual assignment for crew chief $crewChiefId');
    }

    return crewAssignmentId;
  }

  // Claim a game (create accepted assignment and increment officials_hired)
  Future<int> claimGame(int gameId, int officialId, double? feeAmount) async {
    try {
      // Check for hard conflicts with confirmed games before allowing claim
      final hardConflicts = await checkForHardConflicts(officialId, gameId);
      if (hardConflicts.isNotEmpty) {
        final conflictGame = hardConflicts.first;
        final opponent =
            conflictGame['opponent'] ?? conflictGame['home_team'] ?? 'TBD';
        final timeDiff = conflictGame['time_difference_minutes'] as int;
        throw Exception(
            'Cannot claim game: You have a confirmed game too close in time (${timeDiff} minutes away) against $opponent at ${conflictGame['time']}. Games must be at least 1 hour apart.');
      }

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

      // Remove from conflicting games
      await _removeFromConflictingGames(officialId, gameId);

      // Increment the officials_hired count for the game
      await rawQuery('''
        UPDATE games 
        SET officials_hired = officials_hired + 1 
        WHERE id = ?
      ''', [gameId]);

      // Increment official's accepted games count
      await rawQuery('''
        UPDATE officials 
        SET total_accepted_games = total_accepted_games + 1
        WHERE id = ?
      ''', [officialId]);

      // Recalculate follow-through rate (though it should stay the same since no backouts yet)
      await _updateOfficialFollowThroughRate(officialId);

      return assignmentId;
    } catch (e) {
      print('Error claiming game: $e');
      throw Exception('Failed to claim game: ${e.toString()}');
    }
  }

  // Withdraw interest in a game
  Future<int> withdrawInterest(int gameId, int officialId) async {
    return await delete(
        'game_assignments',
        'game_id = ? AND official_id = ? AND status = ?',
        [gameId, officialId, 'pending']);
  }

  // Get all interested officials for a specific game (pending assignments)
  Future<List<Map<String, dynamic>>> getInterestedOfficialsForGame(
      int gameId) async {
    // First check if this is a hire_crew game
    final gameResult = await rawQuery('''
      SELECT method FROM games WHERE id = ?
    ''', [gameId]);

    String whereClause = 'ga.game_id = ? AND ga.status = ?';
    if (gameResult.isNotEmpty && gameResult.first['method'] == 'hire_crew') {
      // For hire_crew games, exclude crew chief assignments (those with crew response notes)
      whereClause +=
          ' AND (ga.response_notes IS NULL OR ga.response_notes NOT LIKE \'Crew "%" expressed interest\')';
    }

    final results = await rawQuery('''
      SELECT o.id, o.name, o.phone, o.email, o.experience_years,
             ga.assigned_at, ga.fee_amount,
             COALESCE(0, 0) as distance
      FROM game_assignments ga
      JOIN officials o ON ga.official_id = o.id
      WHERE $whereClause
      ORDER BY ga.assigned_at ASC
    ''', [gameId, 'pending']);

    return results;
  }

  // Get all interested crews for a specific game (crews that have actually expressed interest)
  Future<List<Map<String, dynamic>>> getInterestedCrewsForGame(
      int gameId) async {
    final results = await rawQuery('''
      SELECT ca.id as crew_assignment_id, ca.crew_id, ca.assigned_at,
             c.name as crew_name, c.crew_chief_id,
             o.name as crew_chief_name,
             COUNT(cm.id) as member_count,
             ct.required_officials
      FROM crew_assignments ca
      JOIN crews c ON ca.crew_id = c.id
      JOIN officials o ON c.crew_chief_id = o.id
      JOIN crew_types ct ON c.crew_type_id = ct.id
      LEFT JOIN crew_members cm ON c.id = cm.crew_id AND cm.status = 'active'
      WHERE ca.game_id = ? AND ca.status = 'pending' AND ca.responded_at IS NOT NULL
      GROUP BY ca.id, ca.crew_id, ca.assigned_at, c.name, c.crew_chief_id, o.name, ct.required_officials
      ORDER BY ca.assigned_at ASC
    ''', [gameId]);

    return results;
  }

  // Get all crews offered a game but haven't expressed interest yet
  Future<List<Map<String, dynamic>>> getOfferedCrewsForGame(int gameId) async {
    final results = await rawQuery('''
      SELECT ca.id as crew_assignment_id, ca.crew_id, ca.assigned_at,
             c.name as crew_name, c.crew_chief_id,
             o.name as crew_chief_name,
             COUNT(cm.id) as member_count,
             ct.required_officials
      FROM crew_assignments ca
      JOIN crews c ON ca.crew_id = c.id
      JOIN officials o ON c.crew_chief_id = o.id
      JOIN crew_types ct ON c.crew_type_id = ct.id
      LEFT JOIN crew_members cm ON c.id = cm.crew_id AND cm.status = 'active'
      WHERE ca.game_id = ? AND ca.status = 'pending' AND ca.responded_at IS NULL
      GROUP BY ca.id, ca.crew_id, ca.assigned_at, c.name, c.crew_chief_id, o.name, ct.required_officials
      ORDER BY ca.assigned_at ASC
    ''', [gameId]);

    return results;
  }

  // Get crew members for a specific crew
  Future<List<Map<String, dynamic>>> getCrewMembersForDisplay(
      int crewId) async {
    final results = await rawQuery('''
      SELECT cm.official_id, o.name, cm.position, cm.game_position
      FROM crew_members cm
      JOIN officials o ON cm.official_id = o.id
      WHERE cm.crew_id = ? AND cm.status = 'active'
      ORDER BY 
        CASE WHEN cm.position = 'crew_chief' THEN 0 ELSE 1 END,
        o.name
    ''', [crewId]);

    return results;
  }

  // Get all confirmed officials for a specific game (accepted assignments)
  Future<List<Map<String, dynamic>>> getConfirmedOfficialsForGame(
      int gameId) async {
    final results = await rawQuery('''
      SELECT o.id, o.name, o.phone, o.email, o.experience_years, o.city, o.state,
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

  // Create initial assignments for officials when a game is published with a list
  Future<void> createInitialAssignmentsFromList(
      int gameId, List<Map<String, dynamic>> officials, int schedulerId) async {
    for (final official in officials) {
      final officialId = official['id'] as int;

      // Check if assignment already exists
      final existingAssignment =
          await getAssignmentByGameAndOfficial(gameId, officialId);
      if (existingAssignment == null) {
        // Create pending assignment
        final assignment = GameAssignment(
          gameId: gameId,
          officialId: officialId,
          status: 'pending',
          assignedBy: schedulerId,
          assignedAt: DateTime.now(),
        );
        await createAssignment(assignment);
      }
    }
  }

  // Update assignments when game list is changed
  Future<void> updateAssignmentsForListChange(
      int gameId,
      List<Map<String, dynamic>> oldOfficials,
      List<Map<String, dynamic>> newOfficials,
      int schedulerId) async {
    // Get current assignments for this game
    final currentAssignments = await rawQuery('''
      SELECT * FROM game_assignments WHERE game_id = ?
    ''', [gameId]);

    final oldOfficialIds = oldOfficials.map((o) => o['id'] as int).toSet();
    final newOfficialIds = newOfficials.map((o) => o['id'] as int).toSet();
    final currentAssignmentsByOfficial = <int, Map<String, dynamic>>{};

    for (final assignment in currentAssignments) {
      currentAssignmentsByOfficial[assignment['official_id'] as int] =
          assignment;
    }

    // Remove assignments for officials no longer in the list (but preserve confirmed officials)
    final officialsToRemove = oldOfficialIds.difference(newOfficialIds);
    for (final officialId in officialsToRemove) {
      final assignment = currentAssignmentsByOfficial[officialId];
      if (assignment != null && assignment['status'] == 'pending') {
        // Only remove pending assignments, preserve confirmed ones
        await delete(
            'game_assignments',
            'game_id = ? AND official_id = ? AND status = ?',
            [gameId, officialId, 'pending']);
      }
      // Confirmed officials (status = 'accepted') are preserved even if removed from list
    }

    // Add assignments for new officials in the list
    final officialsToAdd = newOfficialIds.difference(oldOfficialIds);
    for (final officialId in officialsToAdd) {
      if (!currentAssignmentsByOfficial.containsKey(officialId)) {
        // Create pending assignment for new official
        final assignment = GameAssignment(
          gameId: gameId,
          officialId: officialId,
          status: 'pending',
          assignedBy: schedulerId,
          assignedAt: DateTime.now(),
        );
        await createAssignment(assignment);
      }
    }
  }

  // Remove official from game (for manual removal by scheduler)
  Future<bool> removeOfficialFromGame(int gameId, int officialId) async {
    try {
      // Get the assignment
      final assignment =
          await getAssignmentByGameAndOfficial(gameId, officialId);
      if (assignment == null) return false;

      // Delete the assignment
      await delete('game_assignments', 'game_id = ? AND official_id = ?',
          [gameId, officialId]);

      // If the official was confirmed, decrement officials_hired count
      if (assignment.status == 'accepted') {
        await rawQuery('''
          UPDATE games 
          SET officials_hired = officials_hired - 1 
          WHERE id = ?
        ''', [gameId]);

        // Also decrement official's accepted games count
        await rawQuery('''
          UPDATE officials 
          SET total_accepted_games = total_accepted_games - 1
          WHERE id = ?
        ''', [officialId]);

        // Recalculate follow-through rate
        await _updateOfficialFollowThroughRate(officialId);
      }

      return true;
    } catch (e) {
      print('Error removing official from game: $e');
      return false;
    }
  }

  // Back out of a game (for confirmed assignments)
  Future<int> backOutOfGame(int assignmentId, String reason) async {
    try {
      // Get assignment details before updating
      final assignmentDetails = await rawQuery('''
        SELECT ga.*, g.user_id as scheduler_id, g.sport_id, g.date, g.time, g.opponent, g.home_team, g.method,
               o.id as official_id, o.name as official_name, s.name as sport_name
        FROM game_assignments ga
        JOIN games g ON ga.game_id = g.id
        JOIN officials o ON ga.official_id = o.id
        LEFT JOIN sports s ON g.sport_id = s.id
        WHERE ga.id = ?
      ''', [assignmentId]);

      if (assignmentDetails.isEmpty) {
        throw Exception('Assignment not found');
      }

      final assignment = assignmentDetails.first;
      final gameId = assignment['game_id'];
      final officialId = assignment['official_id'];
      final schedulerId = assignment['scheduler_id'];
      final gameMethod = assignment['method'] as String?;
      final backedOutAt = DateTime.now();

      // Check if this is a backout due to game changes within 24 hours
      final isGameChangeBackout = await _isGameChangeRelatedBackout(
        gameId: gameId,
        officialId: officialId,
        reason: reason,
        backedOutAt: backedOutAt,
      );

      // Update the assignment status
      final data = {
        'status': 'backed_out',
        'backed_out_at': backedOutAt.toIso8601String(),
        'back_out_reason': reason,
        'excused_backout': isGameChangeBackout
            ? 1
            : 0, // Mark as excused if due to game changes within 24 hours
      };

      final result =
          await update('game_assignments', data, 'id = ?', [assignmentId]);

      // If this is an Advanced Method game, update the quotas
      if (gameMethod == 'advanced') {
        try {
          await _advancedMethodRepo.removeOfficialFromGame(gameId, officialId);
          print(
              'Updated Advanced Method quotas for game $gameId after official $officialId backed out');
        } catch (e) {
          print(
              'Warning: Failed to update Advanced Method quotas after back out: $e');
          // Don't fail the entire back out if quota update fails
        }
      }

      // Create backout notification using the proper notification system
      final notificationRepo = NotificationRepository();
      await notificationRepo.createBackoutNotification(
        schedulerId: schedulerId,
        officialName: assignment['official_name'] ?? 'Unknown Official',
        gameSport: assignment['sport_name'] ?? 'Game',
        gameOpponent:
            assignment['opponent'] ?? assignment['home_team'] ?? 'TBD',
        gameDate: DateTime.parse(assignment['date']),
        gameTime: assignment['time'] ?? 'TBD',
        reason: reason,
        additionalData: {
          'assignment_id': assignmentId,
          'official_id': officialId,
          'game_id': gameId,
          'backed_out_at': backedOutAt.toIso8601String(),
          'is_game_change_backout': isGameChangeBackout,
        },
      );

      // Only impact follow-through rate if it's NOT a game change backout
      if (!isGameChangeBackout) {
        // Update official's stats (increase backed out games count)
        await rawQuery('''
          UPDATE officials 
          SET total_backed_out_games = total_backed_out_games + 1
          WHERE id = ?
        ''', [officialId]);

        // Recalculate follow-through rate
        await _updateOfficialFollowThroughRate(officialId);
      }

      // Decrease the officials_hired count for the game to allow position to be refilled
      await rawQuery('''
        UPDATE games 
        SET officials_hired = CASE 
          WHEN officials_hired > 0 THEN officials_hired - 1 
          ELSE 0 
        END 
        WHERE id = ?
      ''', [gameId]);

      return result;
    } catch (e) {
      print('Error backing out of game: $e');
      throw Exception('Failed to back out of game: ${e.toString()}');
    }
  }

  // Helper method to determine if a backout is due to game changes within 24 hours
  Future<bool> _isGameChangeRelatedBackout({
    required int gameId,
    required int officialId,
    required String reason,
    required DateTime backedOutAt,
  }) async {
    // Check if the reason text contains game change keywords
    final hasChangeKeywords = _hasGameChangeKeywords(reason);

    // If no change keywords in reason, check for recent game change notifications
    if (!hasChangeKeywords) {
      // Look for game change notifications sent to this official within the last 24 hours
      final recentGameChanges = await rawQuery('''
        SELECT created_at, type, data
        FROM notifications 
        WHERE recipient_id = ? 
          AND type IN ('game_date_change', 'game_time_change', 'game_location_change', 'game_change')
          AND data LIKE ?
          AND created_at >= ?
        ORDER BY created_at DESC
      ''', [
        officialId,
        '%"game_id":$gameId%', // Check if notification is about this specific game
        backedOutAt.subtract(const Duration(hours: 24)).toIso8601String(),
      ]);

      // If there are recent game change notifications for this game, it's excused
      if (recentGameChanges.isNotEmpty) {
        print(
            '🔍 Found recent game change notification within 24 hours for official $officialId, game $gameId');
        return true;
      }
    }

    // If reason contains change keywords, also check if it's within 24 hours of any game changes
    if (hasChangeKeywords) {
      // Look for any game change notifications for this game within 24 hours
      final recentGameChanges = await rawQuery('''
        SELECT created_at, type, data
        FROM notifications 
        WHERE type IN ('game_date_change', 'game_time_change', 'game_location_change', 'game_change')
          AND data LIKE ?
          AND created_at >= ?
        ORDER BY created_at DESC
      ''', [
        '%"game_id":$gameId%',
        backedOutAt.subtract(const Duration(hours: 24)).toIso8601String(),
      ]);

      if (recentGameChanges.isNotEmpty) {
        print(
            '🔍 Found game change keywords AND recent notification within 24 hours for game $gameId');
        return true;
      }

      // Even without notifications, if keywords are present, we'll excuse it
      // This handles cases where the system might have missed creating notifications
      print(
          '🔍 Found game change keywords in reason for game $gameId, excusing backout');
      return true;
    }

    return false;
  }

  // Helper method to check if reason contains game change keywords
  bool _hasGameChangeKeywords(String reason) {
    final lowerReason = reason.toLowerCase();
    return lowerReason.contains('date changed') ||
        lowerReason.contains('time changed') ||
        lowerReason.contains('location changed') ||
        lowerReason.contains('game date') ||
        lowerReason.contains('game time') ||
        lowerReason.contains('game location') ||
        lowerReason.contains('schedule change') ||
        lowerReason.contains('rescheduled') ||
        lowerReason.contains('moved to') ||
        lowerReason.contains('venue change') ||
        lowerReason.contains('game changed') ||
        lowerReason.contains('schedule modified');
  }

  // Helper method to update official's follow-through rate
  Future<void> _updateOfficialFollowThroughRate(int officialId) async {
    // Get current stats
    final stats = await rawQuery('''
      SELECT total_accepted_games, total_backed_out_games 
      FROM officials 
      WHERE id = ?
    ''', [officialId]);

    if (stats.isNotEmpty) {
      final totalAccepted = stats.first['total_accepted_games'] ?? 0;
      final totalBackedOut = stats.first['total_backed_out_games'] ?? 0;

      // Calculate follow-through rate: (accepted - backed_out) / accepted * 100
      // If no games accepted yet, rate stays at 100%
      double followThroughRate = 100.0;
      if (totalAccepted > 0) {
        final successfulGames = totalAccepted - totalBackedOut;
        followThroughRate = (successfulGames / totalAccepted) * 100.0;

        // Ensure rate is between 0 and 100
        followThroughRate = followThroughRate.clamp(0.0, 100.0);
      }

      await rawQuery('''
        UPDATE officials 
        SET follow_through_rate = ?
        WHERE id = ?
      ''', [followThroughRate, officialId]);
    }
  }

  // Get pending backout notifications for a scheduler
  Future<List<Map<String, dynamic>>> getPendingBackoutNotifications(
      int schedulerId) async {
    return await rawQuery('''
      SELECT obn.*, o.name as official_name, s.name as sport_name,
             g.date, g.time, g.opponent, g.home_team
      FROM official_backout_notifications obn
      JOIN officials o ON obn.official_id = o.id
      JOIN games g ON obn.game_id = g.id
      LEFT JOIN sports s ON g.sport_id = s.id
      WHERE obn.scheduler_id = ? AND obn.excused_at IS NULL
      ORDER BY obn.backed_out_at DESC
    ''', [schedulerId]);
  }

  // Excuse an official's backout
  Future<int> excuseOfficialBackout(
      int notificationId, int excusedBy, String excuseReason) async {
    try {
      final excusedAt = DateTime.now();

      // Get the notification details from the modern notifications table
      final notification = await rawQuery('''
        SELECT * FROM notifications WHERE id = ?
      ''', [notificationId]);

      if (notification.isEmpty) {
        throw Exception('Notification not found');
      }

      final notificationData = notification.first;

      // Parse the JSON data field to get assignment details
      final dataJson = notificationData['data'] as String?;
      if (dataJson == null) {
        throw Exception('Notification has no data field');
      }

      final data = Map<String, dynamic>.from(json.decode(dataJson));
      final officialId = data['official_id'] as int?;
      final assignmentId = data['assignment_id'] as int?;

      if (officialId == null || assignmentId == null) {
        throw Exception(
            'Invalid notification data: missing official_id or assignment_id');
      }

      // Mark the notification as read since it's being actioned
      await update(
          'notifications',
          {
            'is_read': 1,
            'read_at': excusedAt.toIso8601String(),
          },
          'id = ?',
          [notificationId]);

      // Update the game assignment to mark as excused
      await update(
          'game_assignments',
          {
            'excused_backout': 1,
            'excused_at': excusedAt.toIso8601String(),
            'excused_by': excusedBy,
            'excuse_reason': excuseReason,
          },
          'id = ?',
          [assignmentId]);

      // Decrease both the backed out games count AND the total accepted games count
      // When a backout is excused, the game should not count toward follow-through calculation at all
      await rawQuery('''
        UPDATE officials 
        SET total_backed_out_games = CASE 
          WHEN total_backed_out_games > 0 THEN total_backed_out_games - 1 
          ELSE 0 
        END,
        total_accepted_games = CASE 
          WHEN total_accepted_games > 0 THEN total_accepted_games - 1 
          ELSE 0 
        END 
        WHERE id = ?
      ''', [officialId]);

      // Recalculate follow-through rate
      await _updateOfficialFollowThroughRate(officialId);

      // Get game and scheduler details for the notification
      final gameDetails = await rawQuery('''
        SELECT g.*, s.name as sport_name, u.first_name, u.last_name, o.name as official_name
        FROM game_assignments ga
        JOIN games g ON ga.game_id = g.id
        JOIN users u ON g.user_id = u.id
        JOIN officials o ON ga.official_id = o.id
        LEFT JOIN sports s ON g.sport_id = s.id
        WHERE ga.id = ?
      ''', [assignmentId]);

      if (gameDetails.isNotEmpty) {
        final gameInfo = gameDetails.first;
        final schedulerFirstName = gameInfo['first_name'] as String? ?? '';
        final schedulerLastName = gameInfo['last_name'] as String? ?? '';
        final schedulerName = '$schedulerFirstName $schedulerLastName'.trim();
        if (schedulerName.isEmpty) {
          // Fallback to "Scheduler" if no name available
        }

        final sportName = gameInfo['sport_name'] as String? ?? 'Game';
        final opponent = (gameInfo['opponent'] as String?) ??
            (gameInfo['home_team'] as String?) ??
            'TBD';
        final gameDate = DateTime.parse(gameInfo['date'] as String);
        final gameTime = gameInfo['time'] as String? ?? 'TBD';

        // Create excuse notification for the official
        final notificationRepo = NotificationRepository();
        try {
          await notificationRepo.createBackoutExcuseNotification(
            officialId: officialId,
            schedulerName:
                schedulerName.isNotEmpty ? schedulerName : 'Scheduler',
            gameSport: sportName,
            gameOpponent: opponent,
            gameDate: gameDate,
            gameTime: gameTime,
            excuseReason: excuseReason,
            additionalData: {
              'game_id': gameInfo['id'],
              'assignment_id': assignmentId,
              'excused_by': excusedBy,
              'excused_at': excusedAt.toIso8601String(),
            },
          );
          print('✅ Created excuse notification for official $officialId');
        } catch (notificationError) {
          print('⚠️ Failed to create excuse notification: $notificationError');
          // Don't fail the entire operation if notification creation fails
        }
      }

      return 1;
    } catch (e) {
      print('Error excusing official backout: $e');
      throw Exception('Failed to excuse official backout: ${e.toString()}');
    }
  }

  // Mark notification as read
  Future<int> markNotificationAsRead(int notificationId) async {
    return await update(
        'official_backout_notifications',
        {
          'notification_read_at': DateTime.now().toIso8601String(),
        },
        'id = ?',
        [notificationId]);
  }

  // Get backout notification by ID
  Future<Map<String, dynamic>?> getBackoutNotification(
      int notificationId) async {
    final results = await rawQuery('''
      SELECT obn.*, o.name as official_name, s.name as sport_name,
             g.date, g.time, g.opponent, g.home_team, g.location_id,
             l.name as location_name
      FROM official_backout_notifications obn
      JOIN officials o ON obn.official_id = o.id
      JOIN games g ON obn.game_id = g.id
      LEFT JOIN sports s ON g.sport_id = s.id
      LEFT JOIN locations l ON g.location_id = l.id
      WHERE obn.id = ?
    ''', [notificationId]);

    return results.isNotEmpty ? results.first : null;
  }

  // Helper method to get available games with Advanced Method filtering
  Future<List<Map<String, dynamic>>> _getAvailableGamesWithAdvancedFiltering(
      int officialId) async {
    try {
      // Check if the official is a crew chief of any active crew
      final isCrewChief = await _isOfficialCrewChief(officialId);
      print('🔍 DEBUG: Official $officialId isCrewChief: $isCrewChief');

      // First, get all potentially available games (basic filtering)
      String gameQuery = '''
        SELECT DISTINCT 
          g.id, g.sport_id, g.location_id, g.user_id,
          g.date, g.time, g.is_away, g.level_of_competition,
          g.gender, g.officials_required, g.officials_hired,
          g.game_fee, g.opponent, g.hire_automatically,
          g.method, g.status, g.created_at, g.updated_at,
          l.name as location_name, l.address as location_address,
          s.name as sport_name,
          sch.name as schedule_name,
          sch.home_team_name as schedule_home_team_name,
          u.first_name, u.last_name,
          -- Dynamic home team: prioritize schedule_home_team_name for Assigners, then AD profile, then stored home_team
          CASE 
            WHEN sch.home_team_name IS NOT NULL AND sch.home_team_name != '' AND sch.home_team_name != 'Home Team'
            THEN sch.home_team_name
            WHEN g.home_team IS NOT NULL AND g.home_team != '' AND g.home_team != 'Home Team' 
            THEN g.home_team
            WHEN u.scheduler_type = 'Athletic Director' AND u.school_name IS NOT NULL AND u.mascot IS NOT NULL
            THEN u.school_name || ' ' || u.mascot
            ELSE COALESCE(g.home_team, 'Home Team')
          END as home_team,
          'available' as assignment_status
        FROM games g
        LEFT JOIN locations l ON g.location_id = l.id
        LEFT JOIN sports s ON g.sport_id = s.id
        LEFT JOIN schedules sch ON g.schedule_id = sch.id
        LEFT JOIN users u ON g.user_id = u.id
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
      ''';

      // If the official is NOT a crew chief, exclude hire_crew games
      if (!isCrewChief) {
        gameQuery += " AND g.method != 'hire_crew'";
        print(
            '🔍 DEBUG: Adding filter to exclude hire_crew games for non-crew-chief');
      } else {
        // If the official IS a crew chief, show them ALL hire_crew games (they can express interest in any)
        // No additional filtering needed - crew chiefs should see all hire_crew games
        print('🔍 DEBUG: Crew chief can see all hire_crew games');
      }

      gameQuery += " ORDER BY g.date ASC, g.time ASC";

      // Build parameter list
      List<dynamic> params = [
        officialId,
        officialId
      ]; // For game_assignments and game_dismissals exclusions
      // No extra parameter needed since crew chiefs now see all hire_crew games

      final basicResults = await rawQuery(gameQuery, params);

      // DEBUG: Log what we got from the query
      print('🔍 DEBUG Available Games Query Results for official $officialId:');
      print('🔍 DEBUG Query: $gameQuery');
      print('🔍 DEBUG Params: $params');
      print('🔍 DEBUG Results count: ${basicResults.length}');

      // DEBUG: Check what crew assignments exist for this official
      if (isCrewChief) {
        final crewAssignments = await rawQuery('''
          SELECT ca.game_id, ca.status, c.name as crew_name, g.opponent, g.status as game_status, 
                 g.date, g.officials_required, g.officials_hired, g.method
          FROM crew_assignments ca
          JOIN crews c ON ca.crew_id = c.id
          LEFT JOIN games g ON ca.game_id = g.id
          WHERE c.crew_chief_id = ?
        ''', [officialId]);
        print(
            '🔍 DEBUG: Found ${crewAssignments.length} crew assignments for official $officialId:');
        for (final ca in crewAssignments) {
          print(
              '  - Game ${ca['game_id']} (${ca['opponent']}): assignment_status=${ca['status']}, crew=${ca['crew_name']}');
          print(
              '    Game details: status=${ca['game_status']}, date=${ca['date']}, officials=${ca['officials_hired']}/${ca['officials_required']}, method=${ca['method']}');
        }

        // Also test the subquery directly
        final subqueryTest = await rawQuery('''
          SELECT ca.game_id 
          FROM crew_assignments ca
          JOIN crews c ON ca.crew_id = c.id
          WHERE c.crew_chief_id = ? AND ca.status = 'pending'
        ''', [officialId]);
        print(
            '🔍 DEBUG: Subquery test - Found ${subqueryTest.length} game IDs from pending assignments:');
        for (final result in subqueryTest) {
          print('  - Game ID: ${result['game_id']}');
        }
      }

      for (final game in basicResults) {
        print(
            '  Game ${game['id']}: opponent="${game['opponent']}", home_team="${game['home_team']}", method="${game['method']}"');
      }

      // Apply Advanced Method filtering for each game
      final filteredResults = <Map<String, dynamic>>[];

      for (final gameData in basicResults) {
        final gameId = gameData['id'] as int?;
        final gameMethod = gameData['method'] as String?;

        if (gameId != null) {
          if (gameMethod == 'advanced') {
            // Use Advanced Method logic to determine visibility
            final isVisible = await _advancedMethodRepo.isGameVisibleToOfficial(
                gameId, officialId);
            if (isVisible) {
              filteredResults.add(gameData);
            }
          } else {
            // Traditional method - game is visible
            filteredResults.add(gameData);
          }
        } else {}
      }

      return filteredResults;
    } catch (e) {
      print('Error filtering available games with Advanced Method: $e');
      // Fallback to basic filtering if Advanced Method fails
      // Check if this official is a crew chief for fallback filtering
      final isCrewChief = await _isOfficialCrewChief(officialId);

      String fallbackQuery = '''
        SELECT DISTINCT 
               g.id, g.sport_id, g.location_id, g.user_id,
               g.date, g.time, g.is_away, g.level_of_competition,
               g.gender, g.officials_required, g.officials_hired,
               g.game_fee, g.opponent, g.hire_automatically,
               g.method, g.status, g.created_at, g.updated_at,
               l.name as location_name, l.address as location_address,
               s.name as sport_name,
               sch.name as schedule_name,
               sch.home_team_name as schedule_home_team_name,
               u.first_name, u.last_name,
               -- Dynamic home team: prioritize schedule_home_team_name for Assigners, then AD profile, then stored home_team
               CASE 
                 WHEN sch.home_team_name IS NOT NULL AND sch.home_team_name != '' AND sch.home_team_name != 'Home Team'
                 THEN sch.home_team_name
                 WHEN g.home_team IS NOT NULL AND g.home_team != '' AND g.home_team != 'Home Team' 
                 THEN g.home_team
                 WHEN u.scheduler_type = 'Athletic Director' AND u.school_name IS NOT NULL AND u.mascot IS NOT NULL
                 THEN u.school_name || ' ' || u.mascot
                 ELSE COALESCE(g.home_team, 'Home Team')
               END as home_team,
               'available' as assignment_status
        FROM games g
        LEFT JOIN locations l ON g.location_id = l.id
        LEFT JOIN sports s ON g.sport_id = s.id
        LEFT JOIN schedules sch ON g.schedule_id = sch.id
        LEFT JOIN users u ON g.user_id = u.id
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
        AND g.officials_required > g.officials_hired''';

      // Apply hire_crew filtering consistent with main query
      if (!isCrewChief) {
        fallbackQuery += " AND g.method != 'hire_crew'";
      }
      // If is crew chief, show all games including hire_crew (no additional filter needed)

      fallbackQuery += " ORDER BY g.date ASC, g.time ASC";

      return await rawQuery(fallbackQuery, [officialId, officialId]);
    }
  }

  // Claim a game for an official using Advanced Method logic
  Future<bool> claimGameForOfficial(int gameId, int officialId) async {
    try {
      // Get the game to check its method
      final gameResults = await rawQuery('''
        SELECT method FROM games WHERE id = ?
      ''', [gameId]);

      if (gameResults.isEmpty) {
        print('Game $gameId not found');
        return false;
      }

      final gameMethod = gameResults.first['method'] as String?;

      // Check if this is a crew hiring method and if the official is a crew chief
      if (gameMethod == 'hire_crew') {
        return await _handleCrewChiefClaim(gameId, officialId);
      } else if (gameMethod == 'advanced') {
        // Use Advanced Method logic
        final isVisible = await _advancedMethodRepo.isGameVisibleToOfficial(
            gameId, officialId);
        if (!isVisible) {
          print('Game $gameId is no longer available to official $officialId');
          return false;
        }

        // Determine which list to assign from and assign
        final assignmentListId =
            await _determineAssignmentList(gameId, officialId);
        if (assignmentListId == null) {
          print(
              'No eligible list found for official $officialId in game $gameId');
          return false;
        }

        await _advancedMethodRepo.assignOfficialFromList(
          gameId: gameId,
          officialId: officialId,
          listId: assignmentListId,
        );
      } else {
        // Traditional method - just assign directly
        await withTransaction((txn) async {
          // Get the game fee first
          final gameFeeResult = await txn.rawQuery('''
            SELECT game_fee FROM games WHERE id = ?
          ''', [gameId]);

          final gameFee = gameFeeResult.isNotEmpty
              ? double.tryParse(
                  gameFeeResult.first['game_fee']?.toString() ?? '0')
              : 0.0;

          // Create assignment with fee
          final assignmentId = await txn.insert('game_assignments', {
            'game_id': gameId,
            'official_id': officialId,
            'status': 'accepted',
            'assigned_by': officialId, // Official claimed it themselves
            'assigned_at': DateTime.now().toIso8601String(),
            'responded_at': DateTime.now().toIso8601String(),
            'fee_amount': gameFee, // Add the fee amount
          });

          // Add to game_officials table
          await txn.insert(
              'game_officials',
              {
                'game_id': gameId,
                'official_id': officialId,
              },
              conflictAlgorithm: ConflictAlgorithm.ignore);

          // Update game's officials_hired count
          await txn.rawUpdate('''
            UPDATE games 
            SET officials_hired = (
              SELECT COUNT(*) 
              FROM game_officials 
              WHERE game_id = ?
            ),
            updated_at = ?
            WHERE id = ?
          ''', [gameId, DateTime.now().toIso8601String(), gameId]);
        });
      }

      print('Successfully claimed game $gameId for official $officialId');
      return true;
    } catch (e) {
      print('Error claiming game for official: $e');
      return false;
    }
  }

  // Handle crew chief claiming a game - assigns entire crew
  Future<bool> _handleCrewChiefClaim(int gameId, int officialId) async {
    try {
      print(
          '🚢 _handleCrewChiefClaim: Starting claim process for game $gameId, official $officialId');

      // First, verify this official is a crew chief for a crew that was selected for this game
      // Look in crew_assignments table to see if there's a pending crew assignment
      print(
          '🚢 _handleCrewChiefClaim: Looking for crew_assignments where game_id=$gameId AND crew_chief_id=$officialId AND status=pending');

      final crewAssignmentResult = await rawQuery('''
        SELECT ca.crew_id, ca.status, c.name as crew_name, c.crew_chief_id
        FROM crew_assignments ca
        JOIN crews c ON ca.crew_id = c.id
        WHERE ca.game_id = ? AND c.crew_chief_id = ? AND ca.status = 'pending'
      ''', [gameId, officialId]);

      print(
          '🚢 _handleCrewChiefClaim: Found ${crewAssignmentResult.length} crew assignments');
      for (var result in crewAssignmentResult) {
        print(
            '🚢   - Crew: ${result['crew_name']}, ID: ${result['crew_id']}, Status: ${result['status']}');
      }

      if (crewAssignmentResult.isEmpty) {
        print(
            '🚢 _handleCrewChiefClaim: Official $officialId is not a crew chief for any crew assigned to game $gameId');
        return false;
      }

      final crewId = crewAssignmentResult.first['crew_id'] as int;
      final crewName = crewAssignmentResult.first['crew_name'] as String;

      // Get all crew members
      final crewMembersResult = await rawQuery('''
        SELECT cm.official_id, o.name as official_name
        FROM crew_members cm
        JOIN officials o ON cm.official_id = o.id
        WHERE cm.crew_id = ? AND cm.status = 'active'
      ''', [crewId]);

      if (crewMembersResult.isEmpty) {
        print('No active members found for crew $crewId');
        return false;
      }

      // Get game fee
      final gameFeeResult = await rawQuery('''
        SELECT game_fee FROM games WHERE id = ?
      ''', [gameId]);

      final gameFee = gameFeeResult.isNotEmpty
          ? double.tryParse(gameFeeResult.first['game_fee']?.toString() ?? '0')
          : 0.0;

      await withTransaction((txn) async {
        // Update the crew assignment to accepted
        await txn.update(
          'crew_assignments',
          {
            'status': 'accepted',
            'responded_at': DateTime.now().toIso8601String(),
            'response_notes': 'Crew chief accepted - crew $crewName assigned',
          },
          where: 'game_id = ? AND crew_id = ?',
          whereArgs: [gameId, crewId],
        );

        // Create assignments for all crew members (including chief)
        for (final member in crewMembersResult) {
          final memberId = member['official_id'] as int;
          final memberName = member['official_name'] as String;

          // Skip if assignment already exists
          final existingAssignment = await txn.query(
            'game_assignments',
            where: 'game_id = ? AND official_id = ?',
            whereArgs: [gameId, memberId],
          );

          if (existingAssignment.isEmpty) {
            // Create new assignment for crew member
            await txn.insert('game_assignments', {
              'game_id': gameId,
              'official_id': memberId,
              'status': 'accepted',
              'assigned_by': officialId, // Assigned by crew chief
              'assigned_at': DateTime.now().toIso8601String(),
              'responded_at': DateTime.now().toIso8601String(),
              'fee_amount': gameFee,
              'position': memberId == officialId ? 'Crew Chief' : 'Crew Member',
              'response_notes': 'Assigned as part of crew $crewName',
            });
          }

          // Add to game_officials table
          await txn.insert(
            'game_officials',
            {
              'game_id': gameId,
              'official_id': memberId,
            },
            conflictAlgorithm: ConflictAlgorithm.ignore,
          );
        }

        // Update game's officials_hired count
        await txn.rawUpdate('''
          UPDATE games 
          SET officials_hired = (
            SELECT COUNT(*) 
            FROM game_officials 
            WHERE game_id = ?
          ),
          updated_at = ?
          WHERE id = ?
        ''', [gameId, DateTime.now().toIso8601String(), gameId]);
      });

      print(
          'Successfully assigned crew $crewName (${crewMembersResult.length} members) to game $gameId');
      return true;
    } catch (e) {
      print('Error handling crew chief claim: $e');
      return false;
    }
  }

  // Helper method to determine which list to assign an official from
  Future<int?> _determineAssignmentList(int gameId, int officialId) async {
    try {
      // Get all quotas for this game
      final quotas = await _advancedMethodRepo.getGameListQuotas(gameId);

      // Get all lists this official belongs to for this game's sport
      final officialLists = await _getOfficialListsForGame(gameId, officialId);

      // Filter quotas to only those where the official is a member and can accept more
      final eligibleQuotas = quotas
          .where((quota) =>
              officialLists.contains(quota.listId) && quota.canAcceptMore)
          .toList();

      if (eligibleQuotas.isEmpty) {
        return null;
      }

      // Prioritize lists that haven't met their minimum requirements
      final unmetMinimums =
          eligibleQuotas.where((quota) => !quota.isMinimumSatisfied).toList();

      if (unmetMinimums.isNotEmpty) {
        // Sort by urgency (highest shortfall first)
        unmetMinimums.sort((a, b) => b.shortfall.compareTo(a.shortfall));
        return unmetMinimums.first.listId;
      }

      // If all minimums are met, assign to the list with the most remaining capacity
      eligibleQuotas
          .sort((a, b) => b.remainingSlots.compareTo(a.remainingSlots));
      return eligibleQuotas.first.listId;
    } catch (e) {
      print('Error determining assignment list: $e');
      return null;
    }
  }

  // Get all list IDs that an official belongs to for a specific game's sport
  Future<List<int>> _getOfficialListsForGame(int gameId, int officialId) async {
    final results = await rawQuery('''
      SELECT DISTINCT olm.list_id
      FROM official_list_members olm
      INNER JOIN official_lists ol ON olm.list_id = ol.id
      INNER JOIN games g ON ol.sport_id = g.sport_id
      WHERE olm.official_id = ? AND g.id = ?
    ''', [officialId, gameId]);

    return results.map((row) => row['list_id'] as int).toList();
  }

  // Helper method to check if an official is a crew chief
  Future<bool> _isOfficialCrewChief(int officialId) async {
    final results = await rawQuery('''
      SELECT 1 FROM crews 
      WHERE crew_chief_id = ? AND is_active = 1
      LIMIT 1
    ''', [officialId]);

    return results.isNotEmpty;
  }

  // Confirm crew hire (accept crew assignment and create individual assignments for all members)
  Future<bool> confirmCrewHire(int crewAssignmentId, int schedulerId) async {
    try {
      print(
          'Starting crew hire confirmation for assignment ID: $crewAssignmentId, scheduler ID: $schedulerId');

      return await withTransaction((txn) async {
        // Get crew assignment details
        final crewAssignmentResult = await txn.rawQuery('''
          SELECT ca.*, c.name as crew_name, g.game_fee
          FROM crew_assignments ca
          JOIN crews c ON ca.crew_id = c.id
          JOIN games g ON ca.game_id = g.id
          WHERE ca.id = ?
        ''', [crewAssignmentId]);

        if (crewAssignmentResult.isEmpty) {
          print('ERROR: Crew assignment not found for ID: $crewAssignmentId');
          throw Exception('Crew assignment not found');
        }

        final crewAssignment = crewAssignmentResult.first;
        final gameId = crewAssignment['game_id'] as int;
        final crewId = crewAssignment['crew_id'] as int;
        final crewName = crewAssignment['crew_name'] as String;
        final gameFeeRaw = crewAssignment['game_fee'];
        final gameFee =
            gameFeeRaw != null ? double.tryParse(gameFeeRaw.toString()) : null;

        print(
            'Crew hire details - Game ID: $gameId, Crew ID: $crewId, Crew Name: $crewName, Game Fee: $gameFee');

        // Update crew assignment to accepted
        await txn.update(
          'crew_assignments',
          {
            'status': 'accepted',
            'responded_at': DateTime.now().toIso8601String(),
            'crew_chief_response_required': 0,
          },
          where: 'id = ?',
          whereArgs: [crewAssignmentId],
        );
        print('Updated crew assignment status to accepted');

        // Get all crew members
        final crewMembers = await txn.rawQuery('''
          SELECT cm.official_id, cm.position, cm.game_position, o.name
          FROM crew_members cm
          JOIN officials o ON cm.official_id = o.id
          WHERE cm.crew_id = ? AND cm.status = 'active'
        ''', [crewId]);

        print('Found ${crewMembers.length} active crew members');

        // Create or update assignments for all crew members
        for (final member in crewMembers) {
          final officialId = member['official_id'] as int;
          final position = member['position'] as String?;
          final gamePosition = member['game_position'] as String?;
          final officialName = member['name'] as String;

          print(
              'Processing crew member: $officialName (ID: $officialId, Position: $position)');

          // Check if assignment already exists
          final existingAssignment = await txn.query(
            'game_assignments',
            where: 'game_id = ? AND official_id = ?',
            whereArgs: [gameId, officialId],
          );

          if (existingAssignment.isNotEmpty) {
            print('Updating existing assignment for official $officialId');
            // Update existing assignment
            await txn.update(
              'game_assignments',
              {
                'status': 'accepted',
                'responded_at': DateTime.now().toIso8601String(),
                'response_notes': 'Hired as part of crew "$crewName"',
                'fee_amount': gameFee,
                'position':
                    position == 'crew_chief' ? 'Crew Chief' : 'Crew Member',
              },
              where: 'game_id = ? AND official_id = ?',
              whereArgs: [gameId, officialId],
            );
          } else {
            print('Creating new assignment for official $officialId');
            // Create new assignment
            await txn.insert('game_assignments', {
              'game_id': gameId,
              'official_id': officialId,
              'status': 'accepted',
              'assigned_by': schedulerId,
              'assigned_at': DateTime.now().toIso8601String(),
              'responded_at': DateTime.now().toIso8601String(),
              'fee_amount': gameFee,
              'position':
                  position == 'crew_chief' ? 'Crew Chief' : 'Crew Member',
              'response_notes': 'Hired as part of crew "$crewName"',
            });
          }

          print('Adding official $officialId to game_officials table');
          // Add to game_officials table
          await txn.insert(
            'game_officials',
            {
              'game_id': gameId,
              'official_id': officialId,
            },
            conflictAlgorithm: ConflictAlgorithm.ignore,
          );
        }

        // Update game's officials_hired count
        await txn.rawUpdate('''
          UPDATE games 
          SET officials_hired = (
            SELECT COUNT(*) 
            FROM game_officials 
            WHERE game_id = ?
          ),
          updated_at = ?
          WHERE id = ?
        ''', [gameId, DateTime.now().toIso8601String(), gameId]);

        print(
            'Successfully updated game officials_hired count for game $gameId');
        print('Crew hire confirmation completed successfully');
        return true;
      });
    } catch (e) {
      print('Error confirming crew hire: $e');
      print('Stack trace: ${StackTrace.current}');
      return false;
    }
  }

  // ===== GAME DISMISSAL METHODS =====

  /// Dismiss a game for an official (official doesn't want to officiate it)
  Future<int> dismissGame(int gameId, int officialId, String? reason) async {
    try {
      final dismissal = GameDismissal(
        gameId: gameId,
        officialId: officialId,
        reason: reason,
      );

      return await insert('game_dismissals', dismissal.toMap());
    } catch (e) {
      print('Error dismissing game: $e');
      throw Exception('Failed to dismiss game: ${e.toString()}');
    }
  }

  /// Get all dismissed games for an official
  Future<List<GameDismissal>> getDismissedGamesForOfficial(
      int officialId) async {
    final results = await rawQuery('''
      SELECT gd.*, g.date, g.time, g.opponent, g.home_team,
             l.name as location_name, s.name as sport_name
      FROM game_dismissals gd
      JOIN games g ON gd.game_id = g.id
      LEFT JOIN locations l ON g.location_id = l.id
      LEFT JOIN sports s ON g.sport_id = s.id
      WHERE gd.official_id = ?
      ORDER BY gd.dismissed_at DESC
    ''', [officialId]);

    return results.map((data) => GameDismissal.fromMap(data)).toList();
  }

  /// Get all dismissals for a specific game (scheduler view)
  Future<List<Map<String, dynamic>>> getGameDismissals(int gameId) async {
    final results = await rawQuery('''
      SELECT gd.*, o.name as official_name, o.phone, o.email,
             gd.reason, gd.dismissed_at
      FROM game_dismissals gd
      JOIN officials o ON gd.official_id = o.id
      WHERE gd.game_id = ?
      ORDER BY gd.dismissed_at DESC
    ''', [gameId]);

    return results;
  }

  /// Check if an official has dismissed a specific game
  Future<bool> hasOfficialDismissedGame(int gameId, int officialId) async {
    final results = await query(
      'game_dismissals',
      where: 'game_id = ? AND official_id = ?',
      whereArgs: [gameId, officialId],
    );

    return results.isNotEmpty;
  }

  /// Remove a dismissal (allow official to see game again)
  Future<int> undismissGame(int gameId, int officialId) async {
    return await delete(
      'game_dismissals',
      'game_id = ? AND official_id = ?',
      [gameId, officialId],
    );
  }

  /// Get dismissal statistics for a game (for scheduler analytics)
  Future<Map<String, dynamic>> getGameDismissalStats(int gameId) async {
    final results = await rawQuery('''
      SELECT 
        COUNT(*) as total_dismissals,
        COUNT(CASE WHEN reason IS NOT NULL THEN 1 END) as dismissals_with_reason,
        GROUP_CONCAT(DISTINCT reason) as reasons
      FROM game_dismissals 
      WHERE game_id = ?
    ''', [gameId]);

    if (results.isNotEmpty) {
      final row = results.first;
      return {
        'total_dismissals': row['total_dismissals'] ?? 0,
        'dismissals_with_reason': row['dismissals_with_reason'] ?? 0,
        'reasons': row['reasons'] != null
            ? (row['reasons'] as String)
                .split(',')
                .where((r) => r.trim().isNotEmpty)
                .toList()
            : <String>[],
      };
    }

    return {
      'total_dismissals': 0,
      'dismissals_with_reason': 0,
      'reasons': <String>[],
    };
  }

  // ===== CONFLICT DETECTION METHODS =====

  /// Remove official from conflicting games when they confirm a game
  Future<void> _removeFromConflictingGames(
      int officialId, int acceptedGameId) async {
    try {
      // Get the accepted game's date and time
      final acceptedGameResult = await rawQuery('''
        SELECT date, time FROM games WHERE id = ?
      ''', [acceptedGameId]);

      if (acceptedGameResult.isEmpty) {
        print('Warning: Could not find accepted game $acceptedGameId');
        return;
      }

      final acceptedGameData = acceptedGameResult.first;
      final acceptedDate = acceptedGameData['date'] as String;
      final acceptedTime = acceptedGameData['time'] as String?;

      if (acceptedTime == null) {
        print(
            'Warning: Accepted game $acceptedGameId has no time set, skipping conflict detection');
        return;
      }

      // Parse the accepted game's datetime
      final acceptedDateTime = _parseGameDateTime(acceptedDate, acceptedTime);
      if (acceptedDateTime == null) {
        print(
            'Warning: Could not parse datetime for accepted game $acceptedGameId');
        return;
      }

      // Find conflicting games (games the official has pending interest in)
      final conflictingAssignments = await rawQuery('''
        SELECT ga.id as assignment_id, ga.game_id, g.date, g.time, g.opponent, g.home_team,
               s.name as sport_name, l.name as location_name
        FROM game_assignments ga
        JOIN games g ON ga.game_id = g.id
        LEFT JOIN sports s ON g.sport_id = s.id
        LEFT JOIN locations l ON g.location_id = l.id
        WHERE ga.official_id = ? 
          AND ga.status = 'pending'
          AND ga.game_id != ?
          AND g.date = ?
          AND g.time IS NOT NULL
      ''', [officialId, acceptedGameId, acceptedDate]);

      int removedCount = 0;

      for (final conflict in conflictingAssignments) {
        final conflictGameId = conflict['game_id'] as int;
        final conflictTime = conflict['time'] as String;
        final conflictDateTime = _parseGameDateTime(acceptedDate, conflictTime);

        if (conflictDateTime != null &&
            _hasTimeConflict(acceptedDateTime, conflictDateTime)) {
          // Remove the conflicting assignment
          final assignmentId = conflict['assignment_id'] as int;
          await delete('game_assignments', 'id = ?', [assignmentId]);

          removedCount++;
          print(
              '🚫 Removed official $officialId from conflicting game $conflictGameId (${conflict['opponent'] ?? conflict['home_team']}) due to confirmation of game $acceptedGameId');
        }
      }

      if (removedCount > 0) {
        print(
            '✅ Removed official $officialId from $removedCount conflicting games');
      }
    } catch (e) {
      print('Error removing from conflicting games: $e');
      // Don't throw - this is a best-effort operation that shouldn't break the confirmation
    }
  }

  /// Check if two game times have a hard conflict (< 1 hour separation)
  bool _hasHardConflict(DateTime game1, DateTime game2) {
    final timeDifference = (game1.difference(game2)).abs();
    return timeDifference.inMinutes < 60;
  }

  /// Check if two game times have a soft conflict (1-4 hours separation)
  bool _hasSoftConflict(DateTime game1, DateTime game2) {
    final timeDifference = (game1.difference(game2)).abs();
    return timeDifference.inHours >= 1 && timeDifference.inHours <= 4;
  }

  /// Check if two game times conflict (with buffer) - legacy method for auto-removal
  bool _hasTimeConflict(DateTime game1, DateTime game2) {
    // 2-hour buffer around each game (1 hour before + 1 hour after)
    const bufferHours = 2;
    final buffer = Duration(hours: bufferHours);

    final game1Start = game1.subtract(buffer);
    final game1End = game1.add(buffer);
    final game2Start = game2.subtract(buffer);
    final game2End = game2.add(buffer);

    // Check if the buffered time windows overlap
    return game1Start.isBefore(game2End) && game2Start.isBefore(game1End);
  }

  /// Get conflict type between two games
  String? _getConflictType(DateTime game1, DateTime game2) {
    if (_hasHardConflict(game1, game2)) {
      return 'hard';
    } else if (_hasSoftConflict(game1, game2)) {
      return 'soft';
    }
    return null;
  }

  /// Parse game date and time into DateTime object
  DateTime? _parseGameDateTime(String date, String time) {
    try {
      // Parse date (format: YYYY-MM-DD)
      final dateParts = date.split('-');
      if (dateParts.length != 3) return null;

      final year = int.parse(dateParts[0]);
      final month = int.parse(dateParts[1]);
      final day = int.parse(dateParts[2]);

      // Parse time (format: HH:MM or HH:MM:SS)
      final timeParts = time.split(':');
      if (timeParts.length < 2) return null;

      final hour = int.parse(timeParts[0]);
      final minute = int.parse(timeParts[1]);

      return DateTime(year, month, day, hour, minute);
    } catch (e) {
      print('Error parsing game datetime: $e');
      return null;
    }
  }

  /// Validate that accepting a game doesn't conflict with existing confirmed games
  /// Returns conflicts with severity information
  Future<List<Map<String, dynamic>>> checkForConflicts(
      int officialId, int gameId) async {
    try {
      // Get the game being considered
      final gameResult = await rawQuery('''
        SELECT date, time, opponent, home_team FROM games WHERE id = ?
      ''', [gameId]);

      if (gameResult.isEmpty) return [];

      final gameData = gameResult.first;
      final gameDate = gameData['date'] as String;
      final gameTime = gameData['time'] as String?;

      if (gameTime == null) return [];

      final gameDateTime = _parseGameDateTime(gameDate, gameTime);
      if (gameDateTime == null) return [];

      // Find confirmed games on the same date
      final confirmedGames = await rawQuery('''
        SELECT g.id, g.date, g.time, g.opponent, g.home_team,
               s.name as sport_name, l.name as location_name
        FROM game_assignments ga
        JOIN games g ON ga.game_id = g.id
        LEFT JOIN sports s ON g.sport_id = s.id
        LEFT JOIN locations l ON g.location_id = l.id
        WHERE ga.official_id = ? 
          AND ga.status = 'accepted'
          AND g.date = ?
          AND g.time IS NOT NULL
      ''', [officialId, gameDate]);

      final conflicts = <Map<String, dynamic>>[];

      for (final confirmedGame in confirmedGames) {
        final confirmedTime = confirmedGame['time'] as String;
        final confirmedDateTime = _parseGameDateTime(gameDate, confirmedTime);

        if (confirmedDateTime != null) {
          final conflictType =
              _getConflictType(gameDateTime, confirmedDateTime);
          if (conflictType != null) {
            final conflictData = Map<String, dynamic>.from(confirmedGame);
            conflictData['conflict_type'] = conflictType;
            conflictData['time_difference_minutes'] =
                (gameDateTime.difference(confirmedDateTime)).abs().inMinutes;
            conflicts.add(conflictData);
          }
        }
      }

      return conflicts;
    } catch (e) {
      print('Error checking for conflicts: $e');
      return [];
    }
  }

  /// Check specifically for hard conflicts (< 1 hour) - used for blocking actions
  Future<List<Map<String, dynamic>>> checkForHardConflicts(
      int officialId, int gameId) async {
    final allConflicts = await checkForConflicts(officialId, gameId);
    return allConflicts
        .where((conflict) => conflict['conflict_type'] == 'hard')
        .toList();
  }

  /// Check specifically for soft conflicts (1-4 hours) - used for warnings
  Future<List<Map<String, dynamic>>> checkForSoftConflicts(
      int officialId, int gameId) async {
    final allConflicts = await checkForConflicts(officialId, gameId);
    return allConflicts
        .where((conflict) => conflict['conflict_type'] == 'soft')
        .toList();
  }

  /// Express interest with soft conflict checking
  /// Throws SoftConflictException if there are soft conflicts that need user confirmation
  Future<int> expressInterestWithConflictCheck(
      int gameId, int officialId, double? feeAmount,
      {bool ignoreSoftConflicts = false}) async {
    // Check for hard conflicts first (always block)
    final hardConflicts = await checkForHardConflicts(officialId, gameId);
    if (hardConflicts.isNotEmpty) {
      final conflictGame = hardConflicts.first;
      final opponent =
          conflictGame['opponent'] ?? conflictGame['home_team'] ?? 'TBD';
      final timeDiff = conflictGame['time_difference_minutes'] as int;
      throw Exception(
          'Cannot express interest: You have a confirmed game too close in time (${timeDiff} minutes away) against $opponent at ${conflictGame['time']}. Games must be at least 1 hour apart.');
    }

    // Check for soft conflicts (need user confirmation)
    if (!ignoreSoftConflicts) {
      final softConflicts = await checkForSoftConflicts(officialId, gameId);
      if (softConflicts.isNotEmpty) {
        throw SoftConflictException(
          'You have confirmed games on this day that may conflict with this game time.',
          softConflicts,
        );
      }
    }

    // Proceed with normal express interest logic
    return await expressInterest(gameId, officialId, feeAmount);
  }

  /// Claim game with soft conflict checking
  /// Throws SoftConflictException if there are soft conflicts that need user confirmation
  Future<int> claimGameWithConflictCheck(
      int gameId, int officialId, double? feeAmount,
      {bool ignoreSoftConflicts = false}) async {
    // Check for hard conflicts first (always block)
    final hardConflicts = await checkForHardConflicts(officialId, gameId);
    if (hardConflicts.isNotEmpty) {
      final conflictGame = hardConflicts.first;
      final opponent =
          conflictGame['opponent'] ?? conflictGame['home_team'] ?? 'TBD';
      final timeDiff = conflictGame['time_difference_minutes'] as int;
      throw Exception(
          'Cannot claim game: You have a confirmed game too close in time (${timeDiff} minutes away) against $opponent at ${conflictGame['time']}. Games must be at least 1 hour apart.');
    }

    // Check for soft conflicts (need user confirmation)
    if (!ignoreSoftConflicts) {
      final softConflicts = await checkForSoftConflicts(officialId, gameId);
      if (softConflicts.isNotEmpty) {
        throw SoftConflictException(
          'You have confirmed games on this day that may conflict with this game time.',
          softConflicts,
        );
      }
    }

    // Proceed with normal claim logic
    return await claimGame(gameId, officialId, feeAmount);
  }

  // Get linked game assignments for an official based on a specific assignment
  Future<List<GameAssignment>> getLinkedAssignments(int assignmentId) async {
    try {
      debugPrint(
          '🔍 Checking for linked assignments for assignment ID: $assignmentId');

      // First get the assignment and its game details
      final assignmentDetails = await rawQuery('''
        SELECT ga.*, g.id as game_id
        FROM game_assignments ga
        JOIN games g ON ga.game_id = g.id
        WHERE ga.id = ?
      ''', [assignmentId]);

      if (assignmentDetails.isEmpty) {
        debugPrint('❌ Assignment not found for ID: $assignmentId');
        return [];
      }

      final assignment = assignmentDetails.first;
      final gameId = assignment['game_id'] as int;
      final officialId = assignment['official_id'] as int;

      debugPrint(
          '📋 Found assignment: Game ID $gameId, Official ID $officialId');

      // Get all linked games for this game
      final linkedGamesResults = await rawQuery('''
        SELECT g.id as linked_game_id
        FROM games g
        JOIN game_link_members glm ON g.id = glm.game_id
        WHERE glm.link_id IN (
          SELECT glm2.link_id 
          FROM game_link_members glm2 
          WHERE glm2.game_id = ?
        )
        AND g.id != ?
      ''', [gameId, gameId]);

      debugPrint(
          '🔗 Found ${linkedGamesResults.length} linked games for game $gameId');

      if (linkedGamesResults.isEmpty) {
        debugPrint('ℹ️ No linked games found, showing regular back out dialog');
        return [];
      }

      final linkedGameIds = linkedGamesResults
          .map((row) => row['linked_game_id'] as int)
          .toList();

      debugPrint('🔗 Linked game IDs: $linkedGameIds');

      // Get assignments for this official to any of the linked games
      final placeholders = linkedGameIds.map((_) => '?').join(',');
      final linkedAssignments = await rawQuery('''
        SELECT ga.*, g.date, g.time, g.opponent, g.home_team, 
               s.name as sport_name, l.name as location_name
        FROM game_assignments ga
        JOIN games g ON ga.game_id = g.id
        LEFT JOIN sports s ON g.sport_id = s.id
        LEFT JOIN locations l ON g.location_id = l.id
        WHERE ga.official_id = ? 
          AND ga.game_id IN ($placeholders)
          AND ga.status = 'accepted'
      ''', [officialId, ...linkedGameIds]);

      debugPrint(
          '✅ Found ${linkedAssignments.length} linked assignments for official $officialId');

      if (linkedAssignments.isNotEmpty) {
        debugPrint('🚨 Will show linked games back out dialog');
      }

      return linkedAssignments
          .map((row) => GameAssignment.fromMap(row))
          .toList();
    } catch (e) {
      debugPrint('Error getting linked assignments: $e');
      return [];
    }
  }

  // Back out of multiple linked game assignments
  Future<void> backOutOfLinkedGames(
      List<int> assignmentIds, String reason) async {
    if (assignmentIds.isEmpty) return;

    debugPrint(
        '🔄 Starting backOutOfLinkedGames for ${assignmentIds.length} assignments');

    try {
      // First, get all assignment details outside the transaction
      final List<Map<String, dynamic>> assignmentDetailsList = [];

      for (final assignmentId in assignmentIds) {
        final assignmentDetails = await rawQuery('''
          SELECT ga.*, g.user_id as scheduler_id, g.sport_id, g.date, g.time, g.opponent, g.home_team, g.method,
                 o.id as official_id, o.name as official_name, s.name as sport_name
          FROM game_assignments ga
          JOIN games g ON ga.game_id = g.id
          JOIN officials o ON ga.official_id = o.id
          LEFT JOIN sports s ON g.sport_id = s.id
          WHERE ga.id = ?
        ''', [assignmentId]);

        if (assignmentDetails.isEmpty) {
          throw Exception('Assignment $assignmentId not found');
        }

        assignmentDetailsList.add(assignmentDetails.first);
      }

      debugPrint(
          '📋 Retrieved ${assignmentDetailsList.length} assignment details');

      // Process each assignment and check for game changes outside transaction
      final List<Map<String, dynamic>> processedAssignments = [];

      for (int i = 0; i < assignmentDetailsList.length; i++) {
        final assignment = assignmentDetailsList[i];
        final assignmentId = assignmentIds[i];
        final gameId = assignment['game_id'] as int;
        final officialId = assignment['official_id'] as int;
        final backedOutAt = DateTime.now();

        debugPrint(
            '🔍 Processing assignment $assignmentId for game $gameId, official $officialId');

        // Check if this is a backout due to game changes within 24 hours (outside transaction)
        final isGameChangeBackout = await _isGameChangeRelatedBackout(
          gameId: gameId,
          officialId: officialId,
          reason: reason,
          backedOutAt: backedOutAt,
        );

        processedAssignments.add({
          ...assignment,
          'assignment_id': assignmentId,
          'backed_out_at': backedOutAt,
          'is_game_change_backout': isGameChangeBackout,
        });
      }

      debugPrint('✅ Processed all assignments, starting transaction');

      // Now perform all database updates in a single transaction
      await withTransaction((txn) async {
        for (final processed in processedAssignments) {
          final assignmentId = processed['assignment_id'] as int;
          final gameId = processed['game_id'] as int;
          final officialId = processed['official_id'] as int;
          final backedOutAt = processed['backed_out_at'] as DateTime;
          final isGameChangeBackout =
              processed['is_game_change_backout'] as bool;

          // Update the assignment status
          await txn.update(
            'game_assignments',
            {
              'status': 'backed_out',
              'backed_out_at': backedOutAt.toIso8601String(),
              'back_out_reason': reason,
              'excused_backout': isGameChangeBackout ? 1 : 0,
            },
            where: 'id = ?',
            whereArgs: [assignmentId],
          );

          // Only impact follow-through rate if it's NOT a game change backout
          if (!isGameChangeBackout) {
            // Update official's stats (increase backed out games count)
            await txn.rawUpdate('''
              UPDATE officials 
              SET total_backed_out_games = total_backed_out_games + 1
              WHERE id = ?
            ''', [officialId]);
          }

          // Decrease the officials_hired count for the game to allow position to be refilled
          await txn.rawUpdate('''
            UPDATE games 
            SET officials_hired = CASE 
              WHEN officials_hired > 0 THEN officials_hired - 1 
              ELSE 0 
            END 
            WHERE id = ?
          ''', [gameId]);
        }
      });

      debugPrint('💾 Transaction completed successfully');

      // Handle post-transaction operations (notifications, advanced method cleanup)
      for (final processed in processedAssignments) {
        final assignmentId = processed['assignment_id'] as int;
        final gameId = processed['game_id'] as int;
        final officialId = processed['official_id'] as int;
        final schedulerId = processed['scheduler_id'] as int;
        final gameMethod = processed['method'] as String?;
        final backedOutAt = processed['backed_out_at'] as DateTime;
        final isGameChangeBackout = processed['is_game_change_backout'] as bool;

        // If this is an Advanced Method game, update the quotas (outside transaction)
        if (gameMethod == 'advanced') {
          try {
            await _advancedMethodRepo.removeOfficialFromGame(
                gameId, officialId);
            debugPrint(
                'Updated Advanced Method quotas for game $gameId after official $officialId backed out');
          } catch (e) {
            debugPrint(
                'Warning: Failed to update Advanced Method quotas after back out: $e');
            // Don't fail the entire back out if quota update fails
          }
        }

        // Create backout notification (outside transaction)
        try {
          final notificationRepo = NotificationRepository();
          await notificationRepo.createBackoutNotification(
            schedulerId: schedulerId,
            officialName:
                processed['official_name'] as String? ?? 'Unknown Official',
            gameSport: processed['sport_name'] as String? ?? 'Game',
            gameOpponent: (processed['opponent'] as String?) ??
                (processed['home_team'] as String?) ??
                'TBD',
            gameDate: DateTime.parse(processed['date'] as String),
            gameTime: processed['time'] as String? ?? 'TBD',
            reason: reason,
            additionalData: {
              'assignment_id': assignmentId,
              'official_id': officialId,
              'game_id': gameId,
              'backed_out_at': backedOutAt.toIso8601String(),
              'is_game_change_backout': isGameChangeBackout,
              'is_linked_game_backout': true,
              'total_linked_games_backed_out': assignmentIds.length,
            },
          );
          debugPrint('📨 Created notification for assignment $assignmentId');
        } catch (e) {
          debugPrint(
              'Warning: Failed to create notification for assignment $assignmentId: $e');
          // Don't fail the entire back out if notification fails
        }
      }

      // Recalculate follow-through rate for the official (outside transaction)
      if (processedAssignments.isNotEmpty) {
        try {
          final officialId = processedAssignments.first['official_id'] as int;
          await _updateOfficialFollowThroughRate(officialId);
          debugPrint('📊 Updated follow-through rate for official $officialId');
        } catch (e) {
          debugPrint('Warning: Failed to update follow-through rate: $e');
        }
      }

      debugPrint(
          '🎉 Successfully backed out of all ${assignmentIds.length} linked games');
    } catch (e) {
      debugPrint('❌ Error backing out of linked games: $e');
      throw Exception('Failed to back out of linked games: ${e.toString()}');
    }
  }
}
