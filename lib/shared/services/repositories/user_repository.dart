import '../../models/database_models.dart';
import 'base_repository.dart';
import '../user_session_service.dart';
import 'dart:convert';

class UserRepository extends BaseRepository {
  static const String tableName = 'users';
  static const String settingsTableName = 'user_settings';

  // User cache for performance
  final Map<int, AppUser> _userCache = {};

  // Clear cache method
  void _clearCache() {
    _userCache.clear();
  }

  // Clear specific user from cache
  void _clearUserFromCache(int userId) {
    _userCache.remove(userId);
  }

  // Create a new user
  Future<int> createUser(AppUser user) async {
    // Validate required fields
    if (user.schedulerType.isEmpty) {
      throw ArgumentError('schedulerType cannot be empty');
    }

    // Check for duplicate email if provided
    if (user.email != null && user.email!.isNotEmpty) {
      final existingUser = await _getUserByEmail(user.email!);
      if (existingUser != null) {
        throw ArgumentError('User with email ${user.email} already exists');
      }
    }

    final userId = await insert(tableName, user.toMap());
    
    // Cache the new user with the generated ID
    if (userId > 0) {
      final userWithId = AppUser(
        id: userId,
        schedulerType: user.schedulerType,
        setupCompleted: user.setupCompleted,
        schoolName: user.schoolName,
        mascot: user.mascot,
        schoolAddress: user.schoolAddress,
        teamName: user.teamName,
        sport: user.sport,
        grade: user.grade,
        gender: user.gender,
        leagueName: user.leagueName,
        userType: user.userType,
        email: user.email,
        passwordHash: user.passwordHash,
        firstName: user.firstName,
        lastName: user.lastName,
        phone: user.phone,
        createdAt: user.createdAt,
      );
      _userCache[userId] = userWithId;
    }
    
    return userId;
  }

  // Helper method to get user by email
  Future<AppUser?> _getUserByEmail(String email) async {
    final results = await query(
      tableName,
      where: 'email = ?',
      whereArgs: [email],
      limit: 1,
    );

    if (results.isEmpty) return null;
    return AppUser.fromMap(results.first);
  }

  // Update an existing user
  Future<int> updateUser(AppUser user) async {
    if (user.id == null) throw ArgumentError('User ID cannot be null for update');
    
    // Validate required fields
    if (user.schedulerType.isEmpty) {
      throw ArgumentError('schedulerType cannot be empty');
    }

    // Check for duplicate email if provided and different from current
    if (user.email != null && user.email!.isNotEmpty) {
      final existingUser = await _getUserByEmail(user.email!);
      if (existingUser != null && existingUser.id != user.id) {
        throw ArgumentError('User with email ${user.email} already exists');
      }
    }
    
    final result = await update(
      tableName,
      user.toMap(),
      'id = ?',
      [user.id],
    );
    
    // Update cache
    if (result > 0) {
      _userCache[user.id!] = user;
    }
    
    return result;
  }

  // Get user by ID with caching
  Future<AppUser?> getUserById(int userId) async {
    // Check cache first
    if (_userCache.containsKey(userId)) {
      return _userCache[userId];
    }

    final results = await query(
      tableName,
      where: 'id = ?',
      whereArgs: [userId],
    );

    if (results.isEmpty) return null;
    
    final user = AppUser.fromMap(results.first);
    // Cache the user
    _userCache[userId] = user;
    
    return user;
  }

  // Get current user (from session)
  Future<AppUser?> getCurrentUser() async {
    final currentUserId = await UserSessionService.instance.getCurrentUserId();
    final userType = await UserSessionService.instance.getCurrentUserType();
    
    // Only return scheduler users from this method
    if (currentUserId == null || userType != 'scheduler') return null;
    
    return await getUserById(currentUserId);
  }

  // Get user by scheduler type
  Future<AppUser?> getUserBySchedulerType(String schedulerType) async {
    final results = await query(
      tableName,
      where: 'scheduler_type = ?',
      whereArgs: [schedulerType],
      orderBy: 'created_at ASC',
      limit: 1,
    );

    if (results.isEmpty) return null;
    return AppUser.fromMap(results.first);
  }

  // Check if any user exists
  Future<bool> hasAnyUser() async {
    final results = await query(
      tableName,
      columns: ['id'],
      limit: 1,
    );

    return results.isNotEmpty;
  }

  // Update user setup completion
  Future<int> updateSetupCompletion(int userId, bool completed) async {
    return await update(
      tableName,
      {'setup_completed': completed ? 1 : 0},
      'id = ?',
      [userId],
    );
  }

  // User Settings Methods

  // Set user setting
  Future<void> setSetting(int userId, String key, String value) async {
    final existing = await query(
      settingsTableName,
      where: 'user_id = ? AND key = ?',
      whereArgs: [userId, key],
    );

    if (existing.isNotEmpty) {
      // Update existing setting
      await update(
        settingsTableName,
        {'value': value},
        'user_id = ? AND key = ?',
        [userId, key],
      );
    } else {
      // Insert new setting
      await insert(settingsTableName, {
        'user_id': userId,
        'key': key,
        'value': value,
      });
    }
  }

  // Get user setting
  Future<String?> getSetting(int userId, String key) async {
    final results = await query(
      settingsTableName,
      columns: ['value'],
      where: 'user_id = ? AND key = ?',
      whereArgs: [userId, key],
    );

    if (results.isEmpty) return null;
    return results.first['value'] as String?;
  }

  // Get boolean setting
  Future<bool> getBoolSetting(int userId, String key, {bool defaultValue = false}) async {
    final value = await getSetting(userId, key);
    if (value == null) return defaultValue;
    return value.toLowerCase() == 'true' || value == '1';
  }

  // Set boolean setting
  Future<void> setBoolSetting(int userId, String key, bool value) async {
    await setSetting(userId, key, value.toString());
  }

  // Get integer setting
  Future<int?> getIntSetting(int userId, String key) async {
    final value = await getSetting(userId, key);
    if (value == null) return null;
    return int.tryParse(value);
  }

  // Get JSON setting (for complex objects like scheduleFilters)
  Future<Map<String, dynamic>?> getJsonSetting(int userId, String key) async {
    final value = await getSetting(userId, key);
    if (value == null) return null;
    try {
      return jsonDecode(value) as Map<String, dynamic>;
    } catch (e) {
      return null;
    }
  }

  // Get double setting
  Future<double?> getDoubleSetting(int userId, String key) async {
    final value = await getSetting(userId, key);
    if (value == null) return null;
    return double.tryParse(value);
  }

  // Get list setting
  Future<List<dynamic>?> getListSetting(int userId, String key) async {
    final value = await getSetting(userId, key);
    if (value == null) return null;
    try {
      return jsonDecode(value) as List<dynamic>;
    } catch (e) {
      return null;
    }
  }

  // Set JSON setting
  Future<void> setJsonSetting(int userId, String key, Map<String, dynamic> value) async {
    await setSetting(userId, key, jsonEncode(value));
  }

  // Set list setting
  Future<void> setListSetting(int userId, String key, List<dynamic> value) async {
    await setSetting(userId, key, jsonEncode(value));
  }

  // Get all settings for a user
  Future<Map<String, String>> getAllSettings(int userId) async {
    final results = await query(
      settingsTableName,
      columns: ['key', 'value'],
      where: 'user_id = ?',
      whereArgs: [userId],
    );

    final settings = <String, String>{};
    for (var result in results) {
      settings[result['key'] as String] = result['value'] as String;
    }

    return settings;
  }

  // Delete user setting
  Future<int> deleteSetting(int userId, String key) async {
    return await delete(
      settingsTableName,
      'user_id = ? AND key = ?',
      [userId, key],
    );
  }

  // Delete all settings for a user
  Future<int> deleteAllSettings(int userId) async {
    return await delete(
      settingsTableName,
      'user_id = ?',
      [userId],
    );
  }

  // Batch insert settings using new batch functionality
  Future<List<int>> batchInsertSettings(int userId, Map<String, String> settings) async {
    final settingsData = settings.entries.map((entry) => {
      'user_id': userId,
      'key': entry.key,
      'value': entry.value,
    }).toList();
    
    return await batchInsert(settingsTableName, settingsData);
  }

  // Bulk set settings using new transaction wrapper
  Future<void> bulkSetSettings(int userId, Map<String, String> settings) async {
    await withTransaction((txn) async {
      for (var entry in settings.entries) {
        final existing = await txn.query(
          settingsTableName,
          where: 'user_id = ? AND key = ?',
          whereArgs: [userId, entry.key],
        );

        if (existing.isNotEmpty) {
          // Update existing setting
          await txn.update(
            settingsTableName,
            {'value': entry.value},
            where: 'user_id = ? AND key = ?',
            whereArgs: [userId, entry.key],
          );
        } else {
          // Insert new setting
          await txn.insert(settingsTableName, {
            'user_id': userId,
            'key': entry.key,
            'value': entry.value,
          });
        }
      }
    });
  }

  // Get user with settings
  Future<Map<String, dynamic>?> getUserWithSettings(int userId) async {
    final user = await getUserById(userId);
    if (user == null) return null;

    final settings = await getAllSettings(userId);

    return {
      'user': user,
      'settings': settings,
    };
  }

  // Delete user and all related data using new transaction wrapper
  Future<void> deleteUserCompletely(int userId) async {
    await withTransaction((txn) async {
      // Delete user settings
      await txn.delete(settingsTableName, where: 'user_id = ?', whereArgs: [userId]);
      
      // Delete game officials relationships for user's games
      await txn.rawDelete('''
        DELETE FROM game_officials 
        WHERE game_id IN (SELECT id FROM games WHERE user_id = ?)
      ''', [userId]);
      
      // Delete games
      await txn.delete('games', where: 'user_id = ?', whereArgs: [userId]);
      
      // Delete game templates
      await txn.delete('game_templates', where: 'user_id = ?', whereArgs: [userId]);
      
      // Delete schedules
      await txn.delete('schedules', where: 'user_id = ?', whereArgs: [userId]);
      
      // Delete locations
      await txn.delete('locations', where: 'user_id = ?', whereArgs: [userId]);
      
      // Delete official list members for user's lists
      await txn.rawDelete('''
        DELETE FROM official_list_members 
        WHERE list_id IN (SELECT id FROM official_lists WHERE user_id = ?)
      ''', [userId]);
      
      // Delete official lists
      await txn.delete('official_lists', where: 'user_id = ?', whereArgs: [userId]);
      
      // Delete officials
      await txn.delete('officials', where: 'user_id = ?', whereArgs: [userId]);
      
      // Delete sport defaults
      await txn.delete('sport_defaults', where: 'user_id = ?', whereArgs: [userId]);
      
      // Delete teams
      await txn.delete('teams', where: 'user_id = ?', whereArgs: [userId]);
      
      // Finally delete the user
      await txn.delete(tableName, where: 'id = ?', whereArgs: [userId]);
    });
    
    // Clear user from cache
    _clearUserFromCache(userId);
  }
}