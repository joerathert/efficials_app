import 'package:sqflite/sqflite.dart';
import 'base_repository.dart';
import '../../models/database_models.dart';
import 'notification_repository.dart';
import 'advanced_method_repository.dart';
import 'package:flutter/foundation.dart'; // Added for debugPrint

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
        g.date, g.time, g.opponent, g.home_team, g.level_of_competition,
        l.name as location_name, l.address as location_address,
        s.name as sport_name
      FROM game_assignments ga
      JOIN games g ON ga.game_id = g.id
      LEFT JOIN locations l ON g.location_id = l.id
      LEFT JOIN sports s ON g.sport_id = s.id
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
             g.date, g.time, g.opponent, g.home_team, g.level_of_competition, g.game_fee,
             l.name as location_name, l.address as location_address,
             s.name as sport_name
      FROM game_assignments ga
      JOIN games g ON ga.game_id = g.id
      LEFT JOIN locations l ON g.location_id = l.id
      LEFT JOIN sports s ON g.sport_id = s.id
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

    // If status is 'accepted', increment the official's accepted games count
    if (status == 'accepted') {
      final assignment = await rawQuery('''
        SELECT official_id FROM game_assignments WHERE id = ?
      ''', [assignmentId]);

      if (assignment.isNotEmpty) {
        final officialId = assignment.first['official_id'];
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
  Future<List<Map<String, dynamic>>> getConfirmedOfficialsForGame(
      int gameId) async {
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

      // Update the assignment status
      final data = {
        'status': 'backed_out',
        'backed_out_at': backedOutAt.toIso8601String(),
        'back_out_reason': reason,
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
        },
      );

      // Update official's stats (increase backed out games count)
      await rawQuery('''
        UPDATE officials 
        SET total_backed_out_games = total_backed_out_games + 1
        WHERE id = ?
      ''', [officialId]);

      // Recalculate follow-through rate
      await _updateOfficialFollowThroughRate(officialId);

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

      // Get the notification details
      final notification = await rawQuery('''
        SELECT * FROM official_backout_notifications WHERE id = ?
      ''', [notificationId]);

      if (notification.isEmpty) {
        throw Exception('Notification not found');
      }

      final officialId = notification.first['official_id'];
      final assignmentId = notification.first['assignment_id'];

      // Update the notification as excused
      await update(
          'official_backout_notifications',
          {
            'excused_at': excusedAt.toIso8601String(),
            'excused_by': excusedBy,
            'excuse_reason': excuseReason,
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

      // Decrease the official's backed out games count
      await rawQuery('''
        UPDATE officials 
        SET total_backed_out_games = CASE 
          WHEN total_backed_out_games > 0 THEN total_backed_out_games - 1 
          ELSE 0 
        END 
        WHERE id = ?
      ''', [officialId]);

      // Recalculate follow-through rate
      await _updateOfficialFollowThroughRate(officialId);

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

      // First, get all potentially available games (basic filtering)
      final basicResults = await rawQuery('''
        SELECT DISTINCT 
          g.id, g.sport_id, g.location_id, g.user_id,
          g.date, g.time, g.is_away, g.level_of_competition,
          g.gender, g.officials_required, g.officials_hired,
          g.game_fee, g.opponent, g.home_team, g.hire_automatically,
          g.method, g.status, g.created_at, g.updated_at,
          l.name as location_name, l.address as location_address,
          s.name as sport_name,
          u.first_name, u.last_name,
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
        } else {
        }
      }

      return filteredResults;
    } catch (e) {
      print('Error filtering available games with Advanced Method: $e');
      // Fallback to basic filtering if Advanced Method fails
      return await rawQuery('''
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

      if (gameMethod == 'advanced') {
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
}
