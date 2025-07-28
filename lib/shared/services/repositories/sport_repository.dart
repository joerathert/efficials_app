import 'package:flutter/material.dart';
import '../../models/database_models.dart';
import 'base_repository.dart';

class SportRepository extends BaseRepository {
  static const String tableName = 'sports';

  // Get all sports
  Future<List<Sport>> getAllSports() async {
    final results = await query(tableName, orderBy: 'name ASC');
    return results.map((map) => Sport.fromMap(map)).toList();
  }

  // Get sport by ID
  Future<Sport?> getSportById(int sportId) async {
    final results = await query(
      tableName,
      where: 'id = ?',
      whereArgs: [sportId],
      limit: 1,
    );

    if (results.isEmpty) return null;
    return Sport.fromMap(results.first);
  }

  // Get sport by name
  Future<Sport?> getSportByName(String name) async {
    final results = await query(
      tableName,
      where: 'name = ?',
      whereArgs: [name],
      limit: 1,
    );

    if (results.isEmpty) return null;
    return Sport.fromMap(results.first);
  }

  // Create a new sport
  Future<int> createSport(Sport sport) async {
    return await insert(tableName, sport.toMap());
  }

  // Update an existing sport
  Future<int> updateSport(Sport sport) async {
    if (sport.id == null) throw ArgumentError('Sport ID cannot be null for update');
    
    return await update(
      tableName,
      sport.toMap(),
      'id = ?',
      [sport.id],
    );
  }

  // Delete a sport
  Future<int> deleteSport(int sportId) async {
    return await delete(tableName, 'id = ?', [sportId]);
  }

  // Check if sport exists by name
  Future<bool> sportExists(String name) async {
    final results = await query(
      tableName,
      where: 'name = ?',
      whereArgs: [name],
      limit: 1,
    );

    return results.isNotEmpty;
  }

  // Get sports count
  Future<int> getSportsCount() async {
    final results = await rawQuery('SELECT COUNT(*) as count FROM $tableName');
    return results.first['count'] as int;
  }

  // Search sports by name
  Future<List<Sport>> searchSports(String searchTerm) async {
    final results = await query(
      tableName,
      where: 'name LIKE ?',
      whereArgs: ['%$searchTerm%'],
      orderBy: 'name ASC',
    );

    return results.map((map) => Sport.fromMap(map)).toList();
  }

  // Get or create sport by name
  Future<Sport> getOrCreateSport(String name) async {
    final existingSport = await getSportByName(name);
    if (existingSport != null) {
      return existingSport;
    }

    final sport = Sport(name: name, createdAt: DateTime.now());
    final sportId = await createSport(sport);
    return sport.copyWith(id: sportId);
  }

  // Sport defaults methods
  
  // Get sport defaults by user and sport
  Future<SportDefaults?> getSportDefaultsByUserAndSport(int userId, String sportName) async {
    final sport = await getSportByName(sportName);
    if (sport == null) return null;
    
    final results = await query(
      'sport_defaults',
      where: 'user_id = ? AND sport_id = ?',
      whereArgs: [userId, sport.id],
      limit: 1,
    );
    
    if (results.isEmpty) return null;
    
    final map = results.first;
    return SportDefaults(
      id: map['id'],
      userId: map['user_id'],
      sportId: sport.id,
      sportName: sport.name,
      gender: map['gender'],
      officialsRequired: map['officials_required'],
      gameFee: map['game_fee'],
      levelOfCompetition: map['level_of_competition'],
    );
  }
  
  // Validate sport defaults
  Map<String, String> validateDefaults(SportDefaults sportDefaults) {
    final errors = <String, String>{};
    
    // Validate game fee format using regex
    if (sportDefaults.gameFee != null && sportDefaults.gameFee!.isNotEmpty) {
      final feeRegex = RegExp(r'^\d+(\.\d{1,2})?$');
      if (!feeRegex.hasMatch(sportDefaults.gameFee!)) {
        errors['gameFee'] = 'Game fee must be a valid amount (e.g., 25.00)';
      }
    }
    
    // Check required fields (you can customize which fields are required)
    if (sportDefaults.gender == null || sportDefaults.gender!.isEmpty) {
      errors['gender'] = 'Gender is required';
    }
    
    if (sportDefaults.officialsRequired == null) {
      errors['officialsRequired'] = 'Number of officials is required';
    }
    
    if (sportDefaults.levelOfCompetition == null || sportDefaults.levelOfCompetition!.isEmpty) {
      errors['levelOfCompetition'] = 'Competition level is required';
    }
    
    return errors;
  }

  // Save sport defaults
  Future<void> saveSportDefaults(SportDefaults sportDefaults) async {
    await withTransaction((txn) async {
      final sport = await getOrCreateSport(sportDefaults.sportName);
      
      final data = {
        'user_id': sportDefaults.userId,
        'sport_id': sport.id,
        'gender': sportDefaults.gender,
        'officials_required': sportDefaults.officialsRequired,
        'game_fee': sportDefaults.gameFee,
        'level_of_competition': sportDefaults.levelOfCompetition,
      };
      
      // Check if defaults already exist
      final existing = await query(
        'sport_defaults',
        where: 'user_id = ? AND sport_id = ?',
        whereArgs: [sportDefaults.userId, sport.id],
        limit: 1,
      );
      
      if (existing.isNotEmpty) {
        // Update existing
        await update(
          'sport_defaults',
          data,
          'user_id = ? AND sport_id = ?',
          [sportDefaults.userId, sport.id],
        );
      } else {
        // Create new
        await insert('sport_defaults', data);
      }
    });
  }
  
  // Delete sport defaults
  Future<void> deleteSportDefaults(int userId, String sportName) async {
    final sport = await getSportByName(sportName);
    if (sport == null) return;
    
    await delete(
      'sport_defaults',
      'user_id = ? AND sport_id = ?',
      [userId, sport.id],
    );
  }
}