import 'package:sqflite/sqflite.dart';
import '../database_helper.dart';
import '../../models/database_models.dart';
import '../../models/custom_error.dart';
import 'notification_repository.dart';

class EndorsementRepository {
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  final NotificationRepository _notificationRepository = NotificationRepository();

  Future<Database> get _db async => await _databaseHelper.database;

  /// Add an endorsement for an official
  Future<void> addEndorsement({
    required int endorsedOfficialId,
    required int endorserUserId,
    required String endorserType,
  }) async {
    try {
      final db = await _db;
      
      // Prevent self-endorsement: check if the endorser is trying to endorse themselves
      // Only check official_user_id as that's the proper link for official accounts
      final officialResult = await db.query(
        'officials',
        where: 'id = ? AND official_user_id = ?',
        whereArgs: [endorsedOfficialId, endorserUserId],
      );
      
      if (officialResult.isNotEmpty) {
        throw CustomError('You cannot endorse yourself');
      }
      
      final endorsement = OfficialEndorsement(
        endorsedOfficialId: endorsedOfficialId,
        endorserUserId: endorserUserId,
        endorserType: endorserType,
        createdAt: DateTime.now(),
      );
      
      await db.insert(
        'official_endorsements',
        endorsement.toMap(),
        conflictAlgorithm: ConflictAlgorithm.abort,
      );

      // Send notification to the endorsed official
      await _sendEndorsementNotification(
        endorsedOfficialId: endorsedOfficialId,
        endorserUserId: endorserUserId,
        endorserType: endorserType,
      );
    } catch (e) {
      throw CustomError('Failed to add endorsement: ${e.toString()}');
    }
  }

  /// Remove an endorsement for an official
  Future<void> removeEndorsement({
    required int endorsedOfficialId,
    required int endorserUserId,
  }) async {
    try {
      final db = await _db;
      
      await db.delete(
        'official_endorsements',
        where: 'endorsed_official_id = ? AND endorser_user_id = ?',
        whereArgs: [endorsedOfficialId, endorserUserId],
      );
    } catch (e) {
      throw CustomError('Failed to remove endorsement: ${e.toString()}');
    }
  }

  /// Check if a user has endorsed an official
  Future<bool> hasUserEndorsedOfficial({
    required int endorsedOfficialId,
    required int endorserUserId,
  }) async {
    try {
      final db = await _db;
      
      final result = await db.query(
        'official_endorsements',
        where: 'endorsed_official_id = ? AND endorser_user_id = ?',
        whereArgs: [endorsedOfficialId, endorserUserId],
        limit: 1,
      );
      
      return result.isNotEmpty;
    } catch (e) {
      throw CustomError('Failed to check endorsement status: ${e.toString()}');
    }
  }

  /// Get endorsement counts for an official
  Future<Map<String, int>> getEndorsementCounts(int officialId) async {
    try {
      final db = await _db;
      
      // Get scheduler endorsements count
      final schedulerResult = await db.rawQuery('''
        SELECT COUNT(*) as count 
        FROM official_endorsements 
        WHERE endorsed_official_id = ? AND endorser_type = 'scheduler'
      ''', [officialId]);
      
      // Get official endorsements count
      final officialResult = await db.rawQuery('''
        SELECT COUNT(*) as count 
        FROM official_endorsements 
        WHERE endorsed_official_id = ? AND endorser_type = 'official'
      ''', [officialId]);
      
      return {
        'schedulerEndorsements': schedulerResult.first['count'] as int,
        'officialEndorsements': officialResult.first['count'] as int,
      };
    } catch (e) {
      throw CustomError('Failed to get endorsement counts: ${e.toString()}');
    }
  }

  /// Get all endorsements for an official
  Future<List<OfficialEndorsement>> getEndorsementsForOfficial(int officialId) async {
    try {
      final db = await _db;
      
      final result = await db.query(
        'official_endorsements',
        where: 'endorsed_official_id = ?',
        whereArgs: [officialId],
        orderBy: 'created_at DESC',
      );
      
      return result.map((map) => OfficialEndorsement.fromMap(map)).toList();
    } catch (e) {
      throw CustomError('Failed to get endorsements for official: ${e.toString()}');
    }
  }

  /// Get all endorsements made by a user
  Future<List<OfficialEndorsement>> getEndorsementsByUser(int userId) async {
    try {
      final db = await _db;
      
      final result = await db.query(
        'official_endorsements',
        where: 'endorser_user_id = ?',
        whereArgs: [userId],
        orderBy: 'created_at DESC',
      );
      
      return result.map((map) => OfficialEndorsement.fromMap(map)).toList();
    } catch (e) {
      throw CustomError('Failed to get endorsements by user: ${e.toString()}');
    }
  }

  /// Send notification to endorsed official
  Future<void> _sendEndorsementNotification({
    required int endorsedOfficialId,
    required int endorserUserId,
    required String endorserType,
  }) async {
    try {
      final db = await _db;
      
      // Get official information
      final officialResult = await db.query(
        'officials',
        where: 'id = ?',
        whereArgs: [endorsedOfficialId],
      );
      
      if (officialResult.isEmpty) return;
      
      final official = Official.fromMap(officialResult.first);
      
      // Get endorser information
      String endorserName = 'Unknown';
      
      if (endorserType == 'scheduler') {
        // Get scheduler name from users table
        final userResult = await db.query(
          'users',
          columns: ['first_name', 'last_name'],
          where: 'id = ?',
          whereArgs: [endorserUserId],
        );
        
        if (userResult.isNotEmpty) {
          final firstName = userResult.first['first_name'] as String? ?? '';
          final lastName = userResult.first['last_name'] as String? ?? '';
          endorserName = '$firstName $lastName'.trim();
          if (endorserName.isEmpty) endorserName = 'Scheduler';
        }
      } else if (endorserType == 'official') {
        // Get official name from officials table
        final officialResult = await db.query(
          'officials',
          columns: ['name'],
          where: 'user_id = ? OR official_user_id = ?',
          whereArgs: [endorserUserId, endorserUserId],
        );
        
        if (officialResult.isNotEmpty) {
          endorserName = officialResult.first['name'] as String? ?? 'Official';
        }
      }
      
      // Only send notification if the official has an account (official_user_id is not null)
      if (official.officialUserId != null) {
        await _notificationRepository.createOfficialNotification(
          officialId: official.officialUserId!,
          type: 'endorsement',
          title: 'You\'ve been endorsed!',
          message: 'You have been endorsed by $endorserName${endorserType == 'scheduler' ? ' (Scheduler)' : ' (Official)'}.',
        );
      }
    } catch (e) {
      // Don't let notification failures break the endorsement process
    }
  }
}