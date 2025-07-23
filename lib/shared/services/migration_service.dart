import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'database_helper.dart';
import 'repositories/user_repository.dart';
import 'repositories/location_repository.dart';
import 'repositories/game_repository.dart';

class MigrationService {
  static final MigrationService _instance = MigrationService._internal();
  MigrationService._internal();
  factory MigrationService() => _instance;

  final DatabaseHelper _databaseHelper = DatabaseHelper();
  final UserRepository _userRepository = UserRepository();
  final LocationRepository _locationRepository = LocationRepository();
  final GameRepository _gameRepository = GameRepository();

  // Initialize database and run migration if needed
  Future<void> initializeDatabase() async {
    try {
      // Initialize database (creates tables if needed)
      await _databaseHelper.database;
      
      // Check if migration is needed
      final prefs = await SharedPreferences.getInstance();
      final migrationCompleted = prefs.getBool('database_migration_completed') ?? false;
      
      if (!migrationCompleted) {
        await runMigration();
      }
      
      debugPrint('Database initialization completed');
    } catch (e) {
      debugPrint('Database initialization failed: $e');
      rethrow;
    }
  }

  // Run the complete migration process
  Future<void> runMigration() async {
    try {
      debugPrint('Starting database migration...');
      
      // Run the automated migration from DatabaseHelper
      await _databaseHelper.migrateFromSharedPreferences();
      
      debugPrint('Database migration completed successfully');
    } catch (e) {
      debugPrint('Database migration failed: $e');
      rethrow;
    }
  }

  // Test database functionality
  Future<bool> testDatabaseFunctionality() async {
    try {
      debugPrint('Testing database functionality...');
      
      // Test user operations
      final hasUser = await _userRepository.hasAnyUser();
      debugPrint('Has user: $hasUser');
      
      if (hasUser) {
        final user = await _userRepository.getCurrentUser();
        debugPrint('Current user: ${user?.schedulerType}');
        
        if (user != null) {
          // Test settings
          await _userRepository.setSetting(user.id!, 'test_key', 'test_value');
          final testValue = await _userRepository.getSetting(user.id!, 'test_key');
          debugPrint('Test setting value: $testValue');
          
          // Test location operations
          final locations = await _locationRepository.getLocationsByUser(user.id!);
          debugPrint('User locations count: ${locations.length}');
          
          // Test game operations
          final games = await _gameRepository.getGamesByUser(user.id!);
          debugPrint('User games count: ${games.length}');
          
          // Clean up test setting
          await _userRepository.deleteSetting(user.id!, 'test_key');
        }
      }
      
      debugPrint('Database functionality test completed successfully');
      return true;
    } catch (e) {
      debugPrint('Database functionality test failed: $e');
      return false;
    }
  }

  // Get migration status
  Future<Map<String, dynamic>> getMigrationStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final migrationCompleted = prefs.getBool('database_migration_completed') ?? false;
    
    final spKeys = <String, bool>{};

    // Check for existing SharedPreferences data
    final keys = [
      'schedulerType',
      'ad_published_games',
      'coach_published_games',
      'assigner_published_games',
      'saved_locations',
      'game_templates',
      'saved_lists',
    ];

    for (String key in keys) {
      final value = prefs.getString(key);
      spKeys[key] = value != null && value.isNotEmpty;
    }

    final status = {
      'migration_completed': migrationCompleted,
      'has_user': await _userRepository.hasAnyUser(),
      'shared_preferences_keys': spKeys,
    };

    return status;
  }

  // Force re-migration (for testing purposes)
  Future<void> forceMigration() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('database_migration_completed', false);
    await runMigration();
  }

  // Reset database (for testing purposes)
  Future<void> resetDatabase() async {
    try {
      await _databaseHelper.deleteDatabase();
      final prefs = await SharedPreferences.getInstance();
      
      // Clear all SharedPreferences data that gets migrated back to database
      await prefs.remove('saved_locations');
      await prefs.remove('game_templates');
      await prefs.remove('saved_lists');
      await prefs.remove('ad_published_games');
      await prefs.remove('ad_unpublished_games');
      await prefs.remove('coach_published_games');
      await prefs.remove('assigner_published_games');
      
      await prefs.setBool('database_migration_completed', false);
      debugPrint('Database reset completed');
    } catch (e) {
      debugPrint('Database reset failed: $e');
      rethrow;
    }
  }

  // Clear only templates (preserves officials and other data)
  Future<void> clearTemplatesOnly() async {
    try {
      // Clear templates from database
      final db = await _databaseHelper.database;
      await db.delete('game_templates');
      
      // Clear templates from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('game_templates');
      
      debugPrint('Templates cleared successfully (officials preserved)');
    } catch (e) {
      debugPrint('Template clearing failed: $e');
      rethrow;
    }
  }

  // Backup current data to SharedPreferences (safety measure)
  Future<void> backupToSharedPreferences() async {
    try {
      final user = await _userRepository.getCurrentUser();
      if (user == null) return;

      final prefs = await SharedPreferences.getInstance();
      
      // Backup games
      final games = await _gameRepository.getGamesByUser(user.id!);
      final gamesJson = games.map((game) => {
        'id': game.id,
        'scheduleName': game.scheduleName,
        'sport': game.sportName,
        'date': game.date?.toIso8601String(),
        'time': game.time != null ? '${game.time!.hour}:${game.time!.minute}' : null,
        'location': game.locationName,
        'isAway': game.isAway,
        'levelOfCompetition': game.levelOfCompetition,
        'gender': game.gender,
        'officialsRequired': game.officialsRequired,
        'officialsHired': game.officialsHired,
        'gameFee': game.gameFee,
        'opponent': game.opponent,
        'hireAutomatically': game.hireAutomatically,
        'method': game.method,
        'status': game.status,
      }).toList();

      String backupKey = '';
      switch (user.schedulerType) {
        case 'Athletic Director':
          backupKey = 'ad_published_games_backup';
          break;
        case 'Coach':
          backupKey = 'coach_published_games_backup';
          break;
        case 'Assigner':
          backupKey = 'assigner_published_games_backup';
          break;
      }

      if (backupKey.isNotEmpty) {
        await prefs.setString(backupKey, gamesJson.toString());
      }

      // Backup locations
      final locations = await _locationRepository.getLocationsByUser(user.id!);
      final locationsJson = locations.map((location) => {
        'name': location.name,
        'address': location.address,
        'notes': location.notes,
      }).toList();

      await prefs.setString('saved_locations_backup', locationsJson.toString());
      
      debugPrint('Data backup to SharedPreferences completed');
    } catch (e) {
      debugPrint('Data backup failed: $e');
    }
  }
}