import 'package:sqflite/sqflite.dart';
import '../database_helper.dart';
import '../../models/database_models.dart';
import '../../models/custom_error.dart';

class EndorsementRepository {
  final DatabaseHelper _databaseHelper = DatabaseHelper();

  Future<Database> get _db async => await _databaseHelper.database;

  /// Add an endorsement for an official
  Future<void> addEndorsement({
    required int endorsedOfficialId,
    required int endorserUserId,
    required String endorserType,
  }) async {
    try {
      final db = await _db;
      
      final endorsement = OfficialEndorsement(
        endorsedOfficialId: endorsedOfficialId,
        endorserUserId: endorserUserId,
        endorserType: endorserType,
        createdAt: DateTime.now(),
      );
      
      await db.insert(
        'official_endorsements',
        endorsement.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
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
}