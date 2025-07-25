import 'package:sqflite/sqflite.dart';
import '../database_helper.dart';
import '../../models/database_models.dart';

class EndorsementRepository {
  final DatabaseHelper _databaseHelper = DatabaseHelper();

  Future<Database> get _db async => await _databaseHelper.database;

  /// Add an endorsement for an official
  Future<void> addEndorsement({
    required int endorsedOfficialId,
    required int endorserUserId,
    required String endorserType,
  }) async {
    final db = await _db;
    
    final endorsement = OfficialEndorsement(
      endorsedOfficialId: endorsedOfficialId,
      endorserUserId: endorserUserId,
      endorserType: endorserType,
    );
    
    await db.insert(
      'official_endorsements',
      endorsement.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Remove an endorsement for an official
  Future<void> removeEndorsement({
    required int endorsedOfficialId,
    required int endorserUserId,
  }) async {
    final db = await _db;
    
    await db.delete(
      'official_endorsements',
      where: 'endorsed_official_id = ? AND endorser_user_id = ?',
      whereArgs: [endorsedOfficialId, endorserUserId],
    );
  }

  /// Check if a user has endorsed an official
  Future<bool> hasUserEndorsedOfficial({
    required int endorsedOfficialId,
    required int endorserUserId,
  }) async {
    final db = await _db;
    
    final result = await db.query(
      'official_endorsements',
      where: 'endorsed_official_id = ? AND endorser_user_id = ?',
      whereArgs: [endorsedOfficialId, endorserUserId],
      limit: 1,
    );
    
    return result.isNotEmpty;
  }

  /// Get endorsement counts for an official
  Future<Map<String, int>> getEndorsementCounts(int officialId) async {
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
  }

  /// Get all endorsements for an official
  Future<List<OfficialEndorsement>> getEndorsementsForOfficial(int officialId) async {
    final db = await _db;
    
    final result = await db.query(
      'official_endorsements',
      where: 'endorsed_official_id = ?',
      whereArgs: [officialId],
      orderBy: 'created_at DESC',
    );
    
    return result.map((map) => OfficialEndorsement.fromMap(map)).toList();
  }

  /// Get all endorsements made by a user
  Future<List<OfficialEndorsement>> getEndorsementsByUser(int userId) async {
    final db = await _db;
    
    final result = await db.query(
      'official_endorsements',
      where: 'endorser_user_id = ?',
      whereArgs: [userId],
      orderBy: 'created_at DESC',
    );
    
    return result.map((map) => OfficialEndorsement.fromMap(map)).toList();
  }
}