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
}