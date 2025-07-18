import 'package:flutter/material.dart';
import '../models/database_models.dart';
import 'repositories/schedule_repository.dart';
import 'repositories/user_repository.dart';
import 'repositories/sport_repository.dart';

class ScheduleService {
  static final ScheduleService _instance = ScheduleService._internal();
  ScheduleService._internal();
  factory ScheduleService() => _instance;

  final ScheduleRepository _scheduleRepository = ScheduleRepository();
  final UserRepository _userRepository = UserRepository();
  final SportRepository _sportRepository = SportRepository();

  // Get current user ID (for database operations)
  Future<int> _getCurrentUserId() async {
    final user = await _userRepository.getCurrentUser();
    return user?.id ?? 1; // Default to 1 if no user found
  }

  // SCHEDULE OPERATIONS

  // Get all schedules for the current user
  Future<List<Map<String, dynamic>>> getSchedules() async {
    try {
      final userId = await _getCurrentUserId();
      final schedules = await _scheduleRepository.getSchedulesByUser(userId);
      
      // Convert to the format expected by the UI
      return schedules.map((schedule) => _scheduleToMap(schedule)).toList();
    } catch (e) {
      debugPrint('Error getting schedules: $e');
      return [];
    }
  }

  // Get schedules by sport
  Future<List<Map<String, dynamic>>> getSchedulesBySport(String sportName) async {
    try {
      final userId = await _getCurrentUserId();
      final sport = await _sportRepository.getSportByName(sportName);
      if (sport == null) return [];

      final schedules = await _scheduleRepository.getSchedulesBySport(userId, sport.id!);
      
      return schedules.map((schedule) => _scheduleToMap(schedule)).toList();
    } catch (e) {
      debugPrint('Error getting schedules by sport: $e');
      return [];
    }
  }

  // Get schedule by ID
  Future<Map<String, dynamic>?> getScheduleById(int scheduleId) async {
    try {
      final schedule = await _scheduleRepository.getScheduleById(scheduleId);
      return schedule != null ? _scheduleToMap(schedule) : null;
    } catch (e) {
      debugPrint('Error getting schedule by ID: $e');
      return null;
    }
  }

  // Create a new schedule
  Future<Map<String, dynamic>?> createSchedule({
    required String name,
    required String sportName,
  }) async {
    try {
      final userId = await _getCurrentUserId();
      
      // Get or create sport
      final sport = await _sportRepository.getOrCreateSport(sportName);
      
      // Check if schedule already exists
      final exists = await _scheduleRepository.doesScheduleExist(userId, name, sport.id!);
      if (exists) {
        debugPrint('Schedule with name "$name" already exists for sport "$sportName"');
        return null;
      }

      final schedule = Schedule(
        name: name,
        sportId: sport.id!,
        userId: userId,
        createdAt: DateTime.now(),
      );

      final scheduleId = await _scheduleRepository.createSchedule(schedule);
      final createdSchedule = await _scheduleRepository.getScheduleById(scheduleId);
      
      return createdSchedule != null ? _scheduleToMap(createdSchedule) : null;
    } catch (e) {
      debugPrint('Error creating schedule: $e');
      return null;
    }
  }

  // Update an existing schedule
  Future<Map<String, dynamic>?> updateSchedule({
    required int scheduleId,
    required String name,
    required String sportName,
  }) async {
    try {
      final userId = await _getCurrentUserId();
      
      // Get or create sport
      final sport = await _sportRepository.getOrCreateSport(sportName);
      
      // Check if schedule name already exists (excluding current schedule)
      final exists = await _scheduleRepository.doesScheduleExist(
        userId, 
        name, 
        sport.id!, 
        excludeId: scheduleId
      );
      if (exists) {
        debugPrint('Schedule with name "$name" already exists for sport "$sportName"');
        return null;
      }

      final schedule = Schedule(
        id: scheduleId,
        name: name,
        sportId: sport.id!,
        userId: userId,
        createdAt: DateTime.now(), // This will be overwritten by existing created_at
      );

      await _scheduleRepository.updateSchedule(schedule);
      final updatedSchedule = await _scheduleRepository.getScheduleById(scheduleId);
      
      return updatedSchedule != null ? _scheduleToMap(updatedSchedule) : null;
    } catch (e) {
      debugPrint('Error updating schedule: $e');
      return null;
    }
  }

  // Delete a schedule
  Future<bool> deleteSchedule(int scheduleId) async {
    try {
      await _scheduleRepository.deleteSchedule(scheduleId);
      return true;
    } catch (e) {
      debugPrint('Error deleting schedule: $e');
      return false;
    }
  }

  // Search schedules by name
  Future<List<Map<String, dynamic>>> searchSchedules(String searchTerm) async {
    try {
      final userId = await _getCurrentUserId();
      final schedules = await _scheduleRepository.searchSchedulesByName(userId, searchTerm);
      
      return schedules.map((schedule) => _scheduleToMap(schedule)).toList();
    } catch (e) {
      debugPrint('Error searching schedules: $e');
      return [];
    }
  }

  // Get schedule count
  Future<int> getScheduleCount() async {
    try {
      final userId = await _getCurrentUserId();
      return await _scheduleRepository.getScheduleCount(userId);
    } catch (e) {
      debugPrint('Error getting schedule count: $e');
      return 0;
    }
  }

  // Get schedule count by sport
  Future<Map<String, int>> getScheduleCountBySport() async {
    try {
      final userId = await _getCurrentUserId();
      return await _scheduleRepository.getScheduleCountBySport(userId);
    } catch (e) {
      debugPrint('Error getting schedule count by sport: $e');
      return {};
    }
  }

  // Get schedules with game counts
  Future<List<Map<String, dynamic>>> getSchedulesWithGameCounts() async {
    try {
      final userId = await _getCurrentUserId();
      final results = await _scheduleRepository.getSchedulesWithGameCounts(userId);
      
      return results.map((result) => {
        'schedule': _scheduleToMap(result['schedule'] as Schedule),
        'gameCount': result['game_count'] as int,
      }).toList();
    } catch (e) {
      debugPrint('Error getting schedules with game counts: $e');
      return [];
    }
  }

  // Get recent schedules
  Future<List<Map<String, dynamic>>> getRecentSchedules() async {
    try {
      final userId = await _getCurrentUserId();
      final schedules = await _scheduleRepository.getRecentSchedules(userId);
      
      return schedules.map((schedule) => _scheduleToMap(schedule)).toList();
    } catch (e) {
      debugPrint('Error getting recent schedules: $e');
      return [];
    }
  }

  // Get or create schedule by name and sport
  Future<Map<String, dynamic>?> getOrCreateSchedule({
    required String name,
    required String sportName,
  }) async {
    try {
      final userId = await _getCurrentUserId();
      
      // Get or create sport
      final sport = await _sportRepository.getOrCreateSport(sportName);
      
      // Get or create schedule
      final schedule = await _scheduleRepository.getOrCreateSchedule(userId, name, sport.id!);
      
      return _scheduleToMap(schedule);
    } catch (e) {
      debugPrint('Error getting or creating schedule: $e');
      return null;
    }
  }

  // Bulk delete schedules
  Future<bool> bulkDeleteSchedules(List<int> scheduleIds) async {
    try {
      await _scheduleRepository.bulkDeleteSchedules(scheduleIds);
      return true;
    } catch (e) {
      debugPrint('Error bulk deleting schedules: $e');
      return false;
    }
  }

  // Get schedule names (for dropdowns and filters)
  Future<List<String>> getScheduleNames() async {
    try {
      final schedules = await getSchedules();
      return schedules.map((schedule) => schedule['name'] as String).toList();
    } catch (e) {
      debugPrint('Error getting schedule names: $e');
      return [];
    }
  }

  // Get schedule names by sport (for filtered dropdowns)
  Future<List<String>> getScheduleNamesBySport(String sportName) async {
    try {
      final schedules = await getSchedulesBySport(sportName);
      return schedules.map((schedule) => schedule['name'] as String).toList();
    } catch (e) {
      debugPrint('Error getting schedule names by sport: $e');
      return [];
    }
  }

  // Check if schedule exists
  Future<bool> scheduleExists(String name, String sportName) async {
    try {
      final userId = await _getCurrentUserId();
      final sport = await _sportRepository.getSportByName(sportName);
      if (sport == null) return false;

      return await _scheduleRepository.doesScheduleExist(userId, name, sport.id!);
    } catch (e) {
      debugPrint('Error checking if schedule exists: $e');
      return false;
    }
  }

  // HELPER METHODS

  // Convert Schedule model to Map for UI
  Map<String, dynamic> _scheduleToMap(Schedule schedule) {
    return {
      'id': schedule.id,
      'name': schedule.name,
      'sport': schedule.sportName,
      'sportId': schedule.sportId,
      'userId': schedule.userId,
      'createdAt': schedule.createdAt,
    };
  }

  // Create schedule from game data (for migration compatibility)
  Future<Map<String, dynamic>?> createScheduleFromGame(Map<String, dynamic> gameData) async {
    final scheduleName = gameData['scheduleName'] as String?;
    final sportName = gameData['sport'] as String?;
    
    if (scheduleName == null || sportName == null) {
      return null;
    }

    return await getOrCreateSchedule(
      name: scheduleName,
      sportName: sportName,
    );
  }

  // Get schedule names from games (for migration compatibility)
  Future<List<String>> getScheduleNamesFromGames(List<Map<String, dynamic>> games) async {
    final scheduleNames = <String>{};
    
    for (final game in games) {
      final scheduleName = game['scheduleName'] as String?;
      if (scheduleName != null && scheduleName.isNotEmpty) {
        scheduleNames.add(scheduleName);
      }
    }
    
    return scheduleNames.toList();
  }
}