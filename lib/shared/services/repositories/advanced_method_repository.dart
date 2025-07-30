import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import '../../models/database_models.dart';
import 'base_repository.dart';

// Custom exception for advanced method repository operations
class AdvancedMethodRepositoryException implements Exception {
  final String message;
  AdvancedMethodRepositoryException(this.message);
  
  @override
  String toString() => 'AdvancedMethodRepositoryException: $message';
}

class AdvancedMethodRepository extends BaseRepository {
  
  // ============================================================================
  // GAME LIST QUOTAS MANAGEMENT
  // ============================================================================
  
  /// Create or update quota for a specific list in a game
  Future<int> setGameListQuota({
    required int gameId,
    required int listId,
    required int minOfficials,
    required int maxOfficials,
  }) async {
    try {
      // Check if quota already exists
      final existing = await query(
        'game_list_quotas',
        where: 'game_id = ? AND list_id = ?',
        whereArgs: [gameId, listId],
      );

      final quotaData = {
        'game_id': gameId,
        'list_id': listId,
        'min_officials': minOfficials,
        'max_officials': maxOfficials,
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (existing.isNotEmpty) {
        // Update existing quota
        final existingId = existing.first['id'] as int;
        await update(
          'game_list_quotas',
          quotaData,
          'id = ?',
          [existingId],
        );
        return existingId;
      } else {
        // Create new quota
        quotaData['current_officials'] = 0;
        return await insert('game_list_quotas', quotaData);
      }
    } catch (e) {
      debugPrint('Error setting game list quota: $e');
      throw AdvancedMethodRepositoryException('Failed to set game list quota: $e');
    }
  }

  /// Get all quotas for a specific game
  Future<List<GameListQuota>> getGameListQuotas(int gameId) async {
    try {
      final results = await rawQuery('''
        SELECT glq.*, 
               ol.name as list_name,
               s.name as sport_name
        FROM game_list_quotas glq
        LEFT JOIN official_lists ol ON glq.list_id = ol.id
        LEFT JOIN sports s ON ol.sport_id = s.id
        WHERE glq.game_id = ?
        ORDER BY ol.name ASC
      ''', [gameId]);

      return results.map((map) => GameListQuota.fromMap(map)).toList();
    } catch (e) {
      debugPrint('Error getting game list quotas for game $gameId: $e');
      throw AdvancedMethodRepositoryException('Failed to get game list quotas: $e');
    }
  }

  /// Get specific quota for a game and list combination
  Future<GameListQuota?> getGameListQuota(int gameId, int listId) async {
    try {
      final results = await rawQuery('''
        SELECT glq.*, 
               ol.name as list_name,
               s.name as sport_name
        FROM game_list_quotas glq
        LEFT JOIN official_lists ol ON glq.list_id = ol.id
        LEFT JOIN sports s ON ol.sport_id = s.id
        WHERE glq.game_id = ? AND glq.list_id = ?
      ''', [gameId, listId]);

      if (results.isEmpty) return null;
      return GameListQuota.fromMap(results.first);
    } catch (e) {
      debugPrint('Error getting game list quota for game $gameId, list $listId: $e');
      throw AdvancedMethodRepositoryException('Failed to get game list quota: $e');
    }
  }

  /// Delete all quotas for a game
  Future<void> deleteGameListQuotas(int gameId) async {
    try {
      await delete('game_list_quotas', 'game_id = ?', [gameId]);
    } catch (e) {
      debugPrint('Error deleting game list quotas for game $gameId: $e');
      throw AdvancedMethodRepositoryException('Failed to delete game list quotas: $e');
    }
  }

  /// Delete specific quota for a game and list
  Future<void> deleteGameListQuota(int gameId, int listId) async {
    try {
      await delete('game_list_quotas', 'game_id = ? AND list_id = ?', [gameId, listId]);
    } catch (e) {
      debugPrint('Error deleting game list quota for game $gameId, list $listId: $e');
      throw AdvancedMethodRepositoryException('Failed to delete game list quota: $e');
    }
  }

  // ============================================================================
  // OFFICIAL LIST ASSIGNMENTS MANAGEMENT
  // ============================================================================

  /// Assign an official to a game from a specific list
  Future<int> assignOfficialFromList({
    required int gameId,
    required int officialId,
    required int listId,
  }) async {
    try {
      int assignmentId = 0;
      
      await withTransaction((txn) async {
        // Check if official is already assigned to this game
        final existingAssignment = await txn.query(
          'official_list_assignments',
          where: 'game_id = ? AND official_id = ?',
          whereArgs: [gameId, officialId],
        );

        if (existingAssignment.isNotEmpty) {
          // Update existing assignment (change which list they're assigned from)
          assignmentId = existingAssignment.first['id'] as int;
          final oldListId = existingAssignment.first['list_id'] as int;
          
          await txn.update(
            'official_list_assignments',
            {
              'list_id': listId,
              'assigned_at': DateTime.now().toIso8601String(),
            },
            where: 'id = ?',
            whereArgs: [assignmentId],
          );

          // Update quota counts
          await _updateQuotaCount(txn, gameId, oldListId, -1); // Decrease old list
          await _updateQuotaCount(txn, gameId, listId, 1);     // Increase new list
        } else {
          // Create new assignment
          assignmentId = await txn.insert('official_list_assignments', {
            'game_id': gameId,
            'official_id': officialId,
            'list_id': listId,
          });

          // Update quota count
          await _updateQuotaCount(txn, gameId, listId, 1);
        }

        // Also add to game_officials table for compatibility
        await txn.insert('game_officials', {
          'game_id': gameId,
          'official_id': officialId,
        }, conflictAlgorithm: ConflictAlgorithm.ignore);

        // Create game_assignments record for UI compatibility
        await txn.insert('game_assignments', {
          'game_id': gameId,
          'official_id': officialId,
          'status': 'accepted',
          'assigned_by': officialId,
          'assigned_at': DateTime.now().toIso8601String(),
          'responded_at': DateTime.now().toIso8601String(),
        }, conflictAlgorithm: ConflictAlgorithm.ignore);

        // Update game's officials_hired count
        await _updateGameOfficialsHired(txn, gameId);
      });

      return assignmentId;
    } catch (e) {
      debugPrint('Error assigning official $officialId from list $listId to game $gameId: $e');
      throw AdvancedMethodRepositoryException('Failed to assign official from list: $e');
    }
  }

  /// Remove an official from a game and update quotas
  Future<void> removeOfficialFromGame(int gameId, int officialId) async {
    try {
      await withTransaction((txn) async {
        // Get the list assignment to know which quota to update
        final assignment = await txn.query(
          'official_list_assignments',
          where: 'game_id = ? AND official_id = ?',
          whereArgs: [gameId, officialId],
        );

        if (assignment.isNotEmpty) {
          final listId = assignment.first['list_id'] as int;

          // Remove from official_list_assignments
          await txn.delete(
            'official_list_assignments',
            where: 'game_id = ? AND official_id = ?',
            whereArgs: [gameId, officialId],
          );

          // Update quota count
          await _updateQuotaCount(txn, gameId, listId, -1);
        }

        // Remove from game_officials table
        await txn.delete(
          'game_officials',
          where: 'game_id = ? AND official_id = ?',
          whereArgs: [gameId, officialId],
        );

        // Update game's officials_hired count
        await _updateGameOfficialsHired(txn, gameId);
      });
    } catch (e) {
      debugPrint('Error removing official $officialId from game $gameId: $e');
      throw AdvancedMethodRepositoryException('Failed to remove official from game: $e');
    }
  }

  /// Get all list assignments for a game
  Future<List<OfficialListAssignment>> getGameListAssignments(int gameId) async {
    try {
      final results = await rawQuery('''
        SELECT ola.*, 
               o.name as official_name,
               ol.name as list_name
        FROM official_list_assignments ola
        LEFT JOIN officials o ON ola.official_id = o.id
        LEFT JOIN official_lists ol ON ola.list_id = ol.id
        WHERE ola.game_id = ?
        ORDER BY ola.assigned_at ASC
      ''', [gameId]);

      return results.map((map) => OfficialListAssignment.fromMap(map)).toList();
    } catch (e) {
      debugPrint('Error getting game list assignments for game $gameId: $e');
      throw AdvancedMethodRepositoryException('Failed to get game list assignments: $e');
    }
  }

  /// Get which list an official was assigned from for a specific game
  Future<OfficialListAssignment?> getOfficialListAssignment(int gameId, int officialId) async {
    try {
      final results = await rawQuery('''
        SELECT ola.*, 
               o.name as official_name,
               ol.name as list_name
        FROM official_list_assignments ola
        LEFT JOIN officials o ON ola.official_id = o.id
        LEFT JOIN official_lists ol ON ola.list_id = ol.id
        WHERE ola.game_id = ? AND ola.official_id = ?
      ''', [gameId, officialId]);

      if (results.isEmpty) return null;
      return OfficialListAssignment.fromMap(results.first);
    } catch (e) {
      debugPrint('Error getting official list assignment for game $gameId, official $officialId: $e');
      throw AdvancedMethodRepositoryException('Failed to get official list assignment: $e');
    }
  }

  // ============================================================================
  // AVAILABLE GAMES VISIBILITY LOGIC
  // ============================================================================

  /// Check if a game should be visible to an official based on quota logic
  Future<bool> isGameVisibleToOfficial(int gameId, int officialId) async {
    try {
      // Get all quotas for this game
      final quotas = await getGameListQuotas(gameId);
      
      if (quotas.isEmpty) {
        // No quotas defined, use traditional method - game is visible
        return true;
      }

      // Get all lists this official belongs to for this game's sport
      final officialLists = await _getOfficialListsForGame(gameId, officialId);
      
      if (officialLists.isEmpty) {
        // Official is not on any relevant lists - game is not visible
        return false;
      }

      // Check if any of the official's lists have remaining capacity
      for (final listId in officialLists) {
        // Look for a quota that matches this list
        GameListQuota? quota;
        try {
          quota = quotas.firstWhere((q) => q.listId == listId);
        } catch (e) {
          // No quota found for this list - skip it
          continue;
        }

        // If quota exists for this list and can accept more officials
        if (quota.canAcceptMore) {
          return true; // At least one list can accept more officials
        }
      }

      return false; // No lists have remaining capacity
    } catch (e) {
      // Default to visible on error to avoid blocking access
      return true;
    }
  }

  /// Get all officials who should see a specific game based on quota logic
  Future<List<int>> getEligibleOfficialsForGame(int gameId) async {
    try {
      final quotas = await getGameListQuotas(gameId);
      
      if (quotas.isEmpty) {
        // No quotas defined, return all officials for this sport
        final gameInfo = await rawQuery('''
          SELECT sport_id FROM games WHERE id = ?
        ''', [gameId]);
        
        if (gameInfo.isEmpty) return [];
        
        final sportId = gameInfo.first['sport_id'] as int;
        final officials = await rawQuery('''
          SELECT DISTINCT o.id
          FROM officials o
          INNER JOIN official_list_members olm ON o.id = olm.official_id
          INNER JOIN official_lists ol ON olm.list_id = ol.id
          WHERE ol.sport_id = ?
        ''', [sportId]);
        
        return officials.map((row) => row['id'] as int).toList();
      }

      final eligibleOfficials = <int>{};

      // For each quota that can accept more officials
      for (final quota in quotas.where((q) => q.canAcceptMore)) {
        final officials = await rawQuery('''
          SELECT DISTINCT olm.official_id
          FROM official_list_members olm
          WHERE olm.list_id = ?
        ''', [quota.listId]);

        for (final official in officials) {
          eligibleOfficials.add(official['official_id'] as int);
        }
      }

      return eligibleOfficials.toList();
    } catch (e) {
      debugPrint('Error getting eligible officials for game $gameId: $e');
      return [];
    }
  }

  // ============================================================================
  // HELPER METHODS
  // ============================================================================

  /// Update quota count for a specific list in a game
  Future<void> _updateQuotaCount(Transaction txn, int gameId, int listId, int delta) async {
    await txn.rawUpdate('''
      UPDATE game_list_quotas 
      SET current_officials = MAX(0, current_officials + ?),
          updated_at = ?
      WHERE game_id = ? AND list_id = ?
    ''', [delta, DateTime.now().toIso8601String(), gameId, listId]);
  }

  /// Update the game's officials_hired count
  Future<void> _updateGameOfficialsHired(Transaction txn, int gameId) async {
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
  }

  /// Get all list IDs that an official belongs to for a specific game's sport
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

  // ============================================================================
  // DEBUG METHODS
  // ============================================================================

  /// Debug method to help troubleshoot game visibility issues
  Future<Map<String, dynamic>> debugGameVisibility(int gameId, int officialId) async {
    try {
      final debugInfo = <String, dynamic>{};
      
      // 1. Check if quotas exist for this game
      final quotas = await getGameListQuotas(gameId);
      debugInfo['quotas_found'] = quotas.length;
      debugInfo['quotas'] = quotas.map((q) => {
        'list_id': q.listId,
        'list_name': q.listName,
        'min': q.minOfficials,
        'max': q.maxOfficials,
        'current': q.currentOfficials,
        'can_accept_more': q.canAcceptMore,
      }).toList();
      
      // 2. Check which lists the official belongs to for this game's sport
      final officialLists = await _getOfficialListsForGame(gameId, officialId);
      debugInfo['official_lists'] = officialLists;
      
      // 3. Check game details
      final gameInfo = await rawQuery('''
        SELECT g.*, s.name as sport_name
        FROM games g
        LEFT JOIN sports s ON g.sport_id = s.id
        WHERE g.id = ?
      ''', [gameId]);
      debugInfo['game_info'] = gameInfo.isNotEmpty ? gameInfo.first : null;
      
      // 4. Check official's list memberships in detail
      final officialListDetails = await rawQuery('''
        SELECT olm.list_id, ol.name as list_name, ol.sport_id, s.name as sport_name
        FROM official_list_members olm
        INNER JOIN official_lists ol ON olm.list_id = ol.id
        LEFT JOIN sports s ON ol.sport_id = s.id
        WHERE olm.official_id = ?
      ''', [officialId]);
      debugInfo['official_list_details'] = officialListDetails;
      
      // 5. Calculate final visibility
      debugInfo['should_be_visible'] = await isGameVisibleToOfficial(gameId, officialId);
      
      return debugInfo;
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  // ============================================================================
  // BATCH OPERATIONS
  // ============================================================================

  /// Set multiple quotas for a game at once
  Future<void> setGameListQuotas(int gameId, List<Map<String, dynamic>> quotas) async {
    try {
      await withTransaction((txn) async {
        // Clear existing quotas for this game
        await txn.delete('game_list_quotas', where: 'game_id = ?', whereArgs: [gameId]);

        // Insert new quotas
        for (final quota in quotas) {
          final quotaData = {
            'game_id': gameId,
            'list_id': quota['listId'],
            'min_officials': quota['minOfficials'],
            'max_officials': quota['maxOfficials'],
            'current_officials': 0,
          };
          
          await txn.insert('game_list_quotas', quotaData);
        }
      });
    } catch (e) {
      debugPrint('Error setting game list quotas for game $gameId: $e');
      throw AdvancedMethodRepositoryException('Failed to set game list quotas: $e');
    }
  }

  /// Get quota summary for a game (useful for UI display)
  Future<Map<String, dynamic>> getGameQuotaSummary(int gameId) async {
    try {
      final quotas = await getGameListQuotas(gameId);
      
      int totalMinRequired = 0;
      int totalMaxAllowed = 0;
      int totalCurrentAssigned = 0;
      int listsWithUnmetMinimums = 0;
      int listsAtCapacity = 0;

      for (final quota in quotas) {
        totalMinRequired += quota.minOfficials;
        totalMaxAllowed += quota.maxOfficials;
        totalCurrentAssigned += quota.currentOfficials;
        
        if (!quota.isMinimumSatisfied) {
          listsWithUnmetMinimums++;
        }
        
        if (quota.isAtMaximum) {
          listsAtCapacity++;
        }
      }

      return {
        'totalLists': quotas.length,
        'totalMinRequired': totalMinRequired,
        'totalMaxAllowed': totalMaxAllowed,
        'totalCurrentAssigned': totalCurrentAssigned,
        'listsWithUnmetMinimums': listsWithUnmetMinimums,
        'listsAtCapacity': listsAtCapacity,
        'allMinimumsStated': listsWithUnmetMinimums == 0,
        'gameFullyStaffed': totalCurrentAssigned >= totalMinRequired,
        'gameAtCapacity': totalCurrentAssigned >= totalMaxAllowed,
      };
    } catch (e) {
      debugPrint('Error getting game quota summary for game $gameId: $e');
      throw AdvancedMethodRepositoryException('Failed to get game quota summary: $e');
    }
  }
}