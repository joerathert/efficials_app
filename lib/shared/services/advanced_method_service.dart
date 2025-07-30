import 'package:flutter/foundation.dart';
import '../models/database_models.dart';
import 'repositories/advanced_method_repository.dart';
import 'repositories/game_repository.dart';
import 'repositories/official_repository.dart';

/// Service for managing Advanced Method (Multiple Lists) functionality
class AdvancedMethodService {
  final AdvancedMethodRepository _advancedMethodRepository = AdvancedMethodRepository();
  final GameRepository _gameRepository = GameRepository();
  final OfficialRepository _officialRepository = OfficialRepository();

  // ============================================================================
  // GAME QUOTA MANAGEMENT
  // ============================================================================

  /// Set up quotas for a game using the Advanced Method
  Future<void> setupGameQuotas({
    required int gameId,
    required List<Map<String, dynamic>> listQuotas,
  }) async {
    try {
      // Validate quotas
      _validateQuotas(listQuotas);
      
      // Set quotas in database
      await _advancedMethodRepository.setGameListQuotas(gameId, listQuotas);
      
      // Update game method to 'advanced'
      await _gameRepository.update(
        'games',
        {
          'method': 'advanced',
          'updated_at': DateTime.now().toIso8601String(),
        },
        'id = ?',
        [gameId],
      );

      debugPrint('Game quotas set up successfully for game $gameId');
    } catch (e) {
      debugPrint('Error setting up game quotas: $e');
      rethrow;
    }
  }

  /// Get available games for an official with Advanced Method filtering
  Future<List<Game>> getAvailableGamesForOfficial(int officialUserId) async {
    try {
      // Get the official record
      final official = await _officialRepository.getOfficialByOfficialUserId(officialUserId);
      if (official == null) {
        debugPrint('Official not found for user ID $officialUserId');
        return [];
      }

      // Get all published games
      final allGames = await _gameRepository.rawQuery('''
        SELECT g.*, 
               s.name as schedule_name,
               sp.name as sport_name,
               l.name as location_name
        FROM games g
        LEFT JOIN schedules s ON g.schedule_id = s.id
        LEFT JOIN sports sp ON g.sport_id = sp.id
        LEFT JOIN locations l ON g.location_id = l.id
        WHERE g.status = 'Published'
        ORDER BY g.date ASC, g.time ASC
      ''', []);

      final games = allGames.map((map) => Game.fromMap(map)).toList();
      final availableGames = <Game>[];

      // Filter games based on Advanced Method logic
      for (final game in games) {
        if (game.id == null) continue;

        final isVisible = await _advancedMethodRepository.isGameVisibleToOfficial(
          game.id!,
          official.id!,
        );

        if (isVisible) {
          availableGames.add(game);
        }
      }

      return availableGames;
    } catch (e) {
      debugPrint('Error getting available games for official $officialUserId: $e');
      return [];
    }
  }

  /// Claim a game for an official using Advanced Method logic
  Future<bool> claimGameForOfficial({
    required int gameId,
    required int officialUserId,
  }) async {
    try {
      // Get the official record
      final official = await _officialRepository.getOfficialByOfficialUserId(officialUserId);
      if (official == null) {
        debugPrint('Official not found for user ID $officialUserId');
        return false;
      }

      // Check if game is still visible/available to this official
      final isVisible = await _advancedMethodRepository.isGameVisibleToOfficial(
        gameId,
        official.id!,
      );

      if (!isVisible) {
        debugPrint('Game $gameId is no longer available to official ${official.id}');
        return false;
      }

      // Determine which list to assign from
      final assignmentListId = await _determineAssignmentList(gameId, official.id!);
      if (assignmentListId == null) {
        debugPrint('No eligible list found for official ${official.id} in game $gameId');
        return false;
      }

      // Assign official from the determined list
      await _advancedMethodRepository.assignOfficialFromList(
        gameId: gameId,
        officialId: official.id!,
        listId: assignmentListId,
      );

      debugPrint('Successfully claimed game $gameId for official ${official.id} from list $assignmentListId');
      return true;
    } catch (e) {
      debugPrint('Error claiming game for official: $e');
      return false;
    }
  }

  /// Remove an official from a game (for schedulers)
  Future<void> removeOfficialFromGame(int gameId, int officialId) async {
    try {
      await _advancedMethodRepository.removeOfficialFromGame(gameId, officialId);
      debugPrint('Successfully removed official $officialId from game $gameId');
    } catch (e) {
      debugPrint('Error removing official from game: $e');
      rethrow;
    }
  }

  // ============================================================================
  // QUOTA INFORMATION & REPORTING
  // ============================================================================

  /// Get detailed quota information for a game
  Future<Map<String, dynamic>> getGameQuotaDetails(int gameId) async {
    try {
      final quotas = await _advancedMethodRepository.getGameListQuotas(gameId);
      final assignments = await _advancedMethodRepository.getGameListAssignments(gameId);
      final summary = await _advancedMethodRepository.getGameQuotaSummary(gameId);

      return {
        'quotas': quotas,
        'assignments': assignments,
        'summary': summary,
      };
    } catch (e) {
      debugPrint('Error getting game quota details: $e');
      rethrow;
    }
  }

  /// Check if a game is using Advanced Method
  Future<bool> isGameUsingAdvancedMethod(int gameId) async {
    try {
      final game = await _gameRepository.getGameById(gameId);
      return game?.method == 'advanced';
    } catch (e) {
      debugPrint('Error checking if game uses advanced method: $e');
      return false;
    }
  }

  /// Get games that need attention (unmet minimums, close to game time, etc.)
  Future<List<Map<String, dynamic>>> getGamesNeedingAttention(int userId) async {
    try {
      final results = await _gameRepository.rawQuery('''
        SELECT g.id, g.date, g.time, g.opponent, g.home_team,
               sp.name as sport_name,
               COUNT(glq.id) as total_quotas,
               SUM(CASE WHEN glq.current_officials < glq.min_officials THEN 1 ELSE 0 END) as unmet_quotas
        FROM games g
        INNER JOIN game_list_quotas glq ON g.id = glq.game_id
        LEFT JOIN sports sp ON g.sport_id = sp.id
        WHERE g.user_id = ? AND g.status = 'Published'
        GROUP BY g.id
        HAVING unmet_quotas > 0
        ORDER BY g.date ASC, g.time ASC
      ''', [userId]);

      return results;
    } catch (e) {
      debugPrint('Error getting games needing attention: $e');
      return [];
    }
  }

  // ============================================================================
  // HELPER METHODS
  // ============================================================================

  /// Validate quota configuration
  void _validateQuotas(List<Map<String, dynamic>> quotas) {
    for (final quota in quotas) {
      final minOfficials = quota['minOfficials'] as int? ?? 0;
      final maxOfficials = quota['maxOfficials'] as int? ?? 0;

      if (minOfficials < 0) {
        throw ArgumentError('Minimum officials cannot be negative');
      }

      if (maxOfficials < minOfficials) {
        throw ArgumentError('Maximum officials cannot be less than minimum officials');
      }

      if (quota['listId'] == null) {
        throw ArgumentError('List ID is required for each quota');
      }
    }
  }

  /// Determine which list to assign an official from based on current quotas
  Future<int?> _determineAssignmentList(int gameId, int officialId) async {
    try {
      // Get all quotas for this game
      final quotas = await _advancedMethodRepository.getGameListQuotas(gameId);
      
      // Get all lists this official belongs to for this game's sport
      final officialLists = await _getOfficialListsForGame(gameId, officialId);
      
      // Filter quotas to only those where the official is a member and can accept more
      final eligibleQuotas = quotas
          .where((quota) => 
              officialLists.contains(quota.listId) && 
              quota.canAcceptMore)
          .toList();

      if (eligibleQuotas.isEmpty) {
        return null;
      }

      // Prioritize lists that haven't met their minimum requirements
      final unmetMinimums = eligibleQuotas
          .where((quota) => !quota.isMinimumSatisfied)
          .toList();

      if (unmetMinimums.isNotEmpty) {
        // Sort by urgency (highest shortfall first)
        unmetMinimums.sort((a, b) => b.shortfall.compareTo(a.shortfall));
        return unmetMinimums.first.listId;
      }

      // If all minimums are met, assign to the list with the most remaining capacity
      eligibleQuotas.sort((a, b) => b.remainingSlots.compareTo(a.remainingSlots));
      return eligibleQuotas.first.listId;
    } catch (e) {
      debugPrint('Error determining assignment list: $e');
      return null;
    }
  }

  /// Get all list IDs that an official belongs to for a specific game's sport
  Future<List<int>> _getOfficialListsForGame(int gameId, int officialId) async {
    final results = await _gameRepository.rawQuery('''
      SELECT DISTINCT olm.list_id
      FROM official_list_members olm
      INNER JOIN official_lists ol ON olm.list_id = ol.id
      INNER JOIN games g ON ol.sport_id = g.sport_id
      WHERE olm.official_id = ? AND g.id = ?
    ''', [officialId, gameId]);

    return results.map((row) => row['list_id'] as int).toList();
  }

  // ============================================================================
  // MIGRATION & CONVERSION HELPERS
  // ============================================================================

  /// Convert a regular game to use Advanced Method with default quotas
  Future<void> convertGameToAdvancedMethod({
    required int gameId,
    required List<int> listIds,
    required int defaultMinPerList,
    required int defaultMaxPerList,
  }) async {
    try {
      final quotas = listIds.map((listId) => {
        'listId': listId,
        'minOfficials': defaultMinPerList,
        'maxOfficials': defaultMaxPerList,
      }).toList();

      await setupGameQuotas(gameId: gameId, listQuotas: quotas);
      
      debugPrint('Converted game $gameId to Advanced Method');
    } catch (e) {
      debugPrint('Error converting game to Advanced Method: $e');
      rethrow;
    }
  }

  /// Convert Advanced Method game back to simple method
  Future<void> convertGameFromAdvancedMethod(int gameId) async {
    try {
      // Remove all quotas
      await _advancedMethodRepository.deleteGameListQuotas(gameId);
      
      // Update game method
      await _gameRepository.update(
        'games',
        {
          'method': null, // or whatever the default method should be
          'updated_at': DateTime.now().toIso8601String(),
        },
        'id = ?',
        [gameId],
      );

      debugPrint('Converted game $gameId from Advanced Method to simple method');
    } catch (e) {
      debugPrint('Error converting game from Advanced Method: $e');
      rethrow;
    }
  }
}