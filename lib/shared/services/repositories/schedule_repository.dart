import 'package:flutter/material.dart';
import '../../models/database_models.dart';
import 'base_repository.dart';

class ScheduleRepository extends BaseRepository {
  static const String tableName = 'schedules';

  // Create a new schedule
  Future<int> createSchedule(Schedule schedule) async {
    return await insert(tableName, schedule.toMap());
  }

  // Update an existing schedule
  Future<int> updateSchedule(Schedule schedule) async {
    if (schedule.id == null) throw ArgumentError('Schedule ID cannot be null for update');
    
    return await update(
      tableName,
      schedule.toMap(),
      'id = ?',
      [schedule.id],
    );
  }

  // Delete a schedule
  Future<int> deleteSchedule(int scheduleId) async {
    return await delete(tableName, 'id = ?', [scheduleId]);
  }

  // Get schedule by ID with joined data
  Future<Schedule?> getScheduleById(int scheduleId) async {
    final results = await rawQuery('''
      SELECT s.*, sp.name as sport_name
      FROM schedules s
      LEFT JOIN sports sp ON s.sport_id = sp.id
      WHERE s.id = ?
    ''', [scheduleId]);

    if (results.isEmpty) return null;
    return Schedule.fromMap(results.first);
  }

  // Get all schedules for a user
  Future<List<Schedule>> getSchedulesByUser(int userId) async {
    final results = await rawQuery('''
      SELECT s.*, sp.name as sport_name
      FROM schedules s
      LEFT JOIN sports sp ON s.sport_id = sp.id
      WHERE s.user_id = ?
      ORDER BY s.name ASC
    ''', [userId]);

    return results.map((map) => Schedule.fromMap(map)).toList();
  }

  // Get schedules by sport for a user
  Future<List<Schedule>> getSchedulesBySport(int userId, int sportId) async {
    final results = await rawQuery('''
      SELECT s.*, sp.name as sport_name
      FROM schedules s
      LEFT JOIN sports sp ON s.sport_id = sp.id
      WHERE s.user_id = ? AND s.sport_id = ?
      ORDER BY s.name ASC
    ''', [userId, sportId]);

    return results.map((map) => Schedule.fromMap(map)).toList();
  }

  // Get schedule by name, sport, and user
  Future<Schedule?> getScheduleByName(int userId, String name, int sportId) async {
    final results = await rawQuery('''
      SELECT s.*, sp.name as sport_name
      FROM schedules s
      LEFT JOIN sports sp ON s.sport_id = sp.id
      WHERE s.user_id = ? AND s.name = ? AND s.sport_id = ?
      LIMIT 1
    ''', [userId, name, sportId]);

    if (results.isEmpty) return null;
    return Schedule.fromMap(results.first);
  }

  // Check if schedule exists for user
  Future<bool> doesScheduleExist(int userId, String name, int sportId, {int? excludeId}) async {
    String whereClause = 'user_id = ? AND name = ? AND sport_id = ?';
    List<dynamic> whereArgs = [userId, name, sportId];

    if (excludeId != null) {
      whereClause += ' AND id != ?';
      whereArgs.add(excludeId);
    }

    final results = await query(
      tableName,
      where: whereClause,
      whereArgs: whereArgs,
      limit: 1,
    );

    return results.isNotEmpty;
  }

  // Search schedules by name
  Future<List<Schedule>> searchSchedulesByName(int userId, String searchTerm) async {
    final results = await rawQuery('''
      SELECT s.*, sp.name as sport_name
      FROM schedules s
      LEFT JOIN sports sp ON s.sport_id = sp.id
      WHERE s.user_id = ? AND s.name LIKE ?
      ORDER BY s.name ASC
    ''', [userId, '%$searchTerm%']);

    return results.map((map) => Schedule.fromMap(map)).toList();
  }

  // Get schedule count for a user
  Future<int> getScheduleCount(int userId) async {
    final results = await rawQuery('''
      SELECT COUNT(*) as count
      FROM schedules 
      WHERE user_id = ?
    ''', [userId]);

    return results.first['count'] as int;
  }

  // Get schedule count by sport for a user
  Future<Map<String, int>> getScheduleCountBySport(int userId) async {
    final results = await rawQuery('''
      SELECT sp.name as sport_name, COUNT(*) as count
      FROM schedules s
      LEFT JOIN sports sp ON s.sport_id = sp.id
      WHERE s.user_id = ?
      GROUP BY sp.name
      ORDER BY sp.name ASC
    ''', [userId]);

    final counts = <String, int>{};
    for (var result in results) {
      counts[result['sport_name'] as String] = result['count'] as int;
    }

    return counts;
  }

  // Get or create schedule
  Future<Schedule> getOrCreateSchedule(int userId, String name, int sportId) async {
    final existingSchedule = await getScheduleByName(userId, name, sportId);
    if (existingSchedule != null) {
      return existingSchedule;
    }

    final schedule = Schedule(
      name: name,
      sportId: sportId,
      userId: userId,
      createdAt: DateTime.now(),
    );
    
    final scheduleId = await createSchedule(schedule);
    return schedule.copyWith(id: scheduleId);
  }

  // Get schedules with game counts
  Future<List<Map<String, dynamic>>> getSchedulesWithGameCounts(int userId) async {
    final results = await rawQuery('''
      SELECT s.*, sp.name as sport_name, COUNT(g.id) as game_count
      FROM schedules s
      LEFT JOIN sports sp ON s.sport_id = sp.id
      LEFT JOIN games g ON s.id = g.schedule_id
      WHERE s.user_id = ?
      GROUP BY s.id, s.name, s.sport_id, sp.name
      ORDER BY s.name ASC
    ''', [userId]);

    return results.map((map) => {
      'schedule': Schedule.fromMap(map),
      'game_count': map['game_count'] as int,
    }).toList();
  }

  // Bulk delete schedules
  Future<void> bulkDeleteSchedules(List<int> scheduleIds) async {
    if (scheduleIds.isEmpty) return;

    final placeholders = scheduleIds.map((_) => '?').join(',');
    await rawDelete('''
      DELETE FROM schedules 
      WHERE id IN ($placeholders)
    ''', scheduleIds);
  }

  // Get recent schedules (last 10 created)
  Future<List<Schedule>> getRecentSchedules(int userId) async {
    final results = await rawQuery('''
      SELECT s.*, sp.name as sport_name
      FROM schedules s
      LEFT JOIN sports sp ON s.sport_id = sp.id
      WHERE s.user_id = ?
      ORDER BY s.created_at DESC
      LIMIT 10
    ''', [userId]);

    return results.map((map) => Schedule.fromMap(map)).toList();
  }
}