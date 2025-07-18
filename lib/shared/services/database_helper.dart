import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  DatabaseHelper._internal();

  factory DatabaseHelper() => _instance;

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'efficials.db');
    
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await _createTables(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Handle database upgrades here
    if (oldVersion < newVersion) {
      // Add migration logic for future versions
    }
  }

  Future<void> _createTables(Database db) async {
    // Users table
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        scheduler_type TEXT NOT NULL,
        setup_completed BOOLEAN DEFAULT FALSE,
        school_name TEXT,
        mascot TEXT,
        team_name TEXT,
        sport TEXT,
        grade TEXT,
        gender TEXT,
        league_name TEXT,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // User settings table
    await db.execute('''
      CREATE TABLE user_settings (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER REFERENCES users(id),
        key TEXT NOT NULL,
        value TEXT,
        UNIQUE(user_id, key)
      )
    ''');

    // Sports table
    await db.execute('''
      CREATE TABLE sports (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT UNIQUE NOT NULL,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // Schedules table
    await db.execute('''
      CREATE TABLE schedules (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        sport_id INTEGER REFERENCES sports(id),
        user_id INTEGER REFERENCES users(id),
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        UNIQUE(name, sport_id, user_id)
      )
    ''');

    // Locations table
    await db.execute('''
      CREATE TABLE locations (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        address TEXT,
        notes TEXT,
        user_id INTEGER REFERENCES users(id),
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // Officials table
    await db.execute('''
      CREATE TABLE officials (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        sport_id INTEGER REFERENCES sports(id),
        rating TEXT,
        user_id INTEGER REFERENCES users(id),
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // Official lists
    await db.execute('''
      CREATE TABLE official_lists (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        sport_id INTEGER REFERENCES sports(id),
        user_id INTEGER REFERENCES users(id),
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    await db.execute('''
      CREATE TABLE official_list_members (
        list_id INTEGER REFERENCES official_lists(id),
        official_id INTEGER REFERENCES officials(id),
        PRIMARY KEY (list_id, official_id)
      )
    ''');

    // Games table
    await db.execute('''
      CREATE TABLE games (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        schedule_id INTEGER REFERENCES schedules(id),
        sport_id INTEGER REFERENCES sports(id),
        location_id INTEGER REFERENCES locations(id),
        user_id INTEGER REFERENCES users(id),
        date DATE,
        time TIME,
        is_away BOOLEAN DEFAULT FALSE,
        level_of_competition TEXT,
        gender TEXT,
        officials_required INTEGER DEFAULT 0,
        officials_hired INTEGER DEFAULT 0,
        game_fee TEXT,
        opponent TEXT,
        hire_automatically BOOLEAN DEFAULT FALSE,
        method TEXT,
        status TEXT DEFAULT 'Unpublished',
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // Game officials (many-to-many)
    await db.execute('''
      CREATE TABLE game_officials (
        game_id INTEGER REFERENCES games(id),
        official_id INTEGER REFERENCES officials(id),
        PRIMARY KEY (game_id, official_id)
      )
    ''');

    // Game templates
    await db.execute('''
      CREATE TABLE game_templates (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        sport_id INTEGER REFERENCES sports(id),
        user_id INTEGER REFERENCES users(id),
        schedule_name TEXT,
        date DATE,
        time TIME,
        location_id INTEGER REFERENCES locations(id),
        is_away_game BOOLEAN DEFAULT FALSE,
        level_of_competition TEXT,
        gender TEXT,
        officials_required INTEGER,
        game_fee TEXT,
        opponent TEXT,
        hire_automatically BOOLEAN,
        method TEXT,
        officials_list_id INTEGER REFERENCES official_lists(id),
        include_schedule_name BOOLEAN DEFAULT FALSE,
        include_sport BOOLEAN DEFAULT FALSE,
        include_date BOOLEAN DEFAULT FALSE,
        include_time BOOLEAN DEFAULT FALSE,
        include_location BOOLEAN DEFAULT FALSE,
        include_is_away_game BOOLEAN DEFAULT FALSE,
        include_level_of_competition BOOLEAN DEFAULT FALSE,
        include_gender BOOLEAN DEFAULT FALSE,
        include_officials_required BOOLEAN DEFAULT FALSE,
        include_game_fee BOOLEAN DEFAULT FALSE,
        include_opponent BOOLEAN DEFAULT FALSE,
        include_hire_automatically BOOLEAN DEFAULT FALSE,
        include_selected_officials BOOLEAN DEFAULT FALSE,
        include_officials_list BOOLEAN DEFAULT FALSE,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // Sport defaults (per user)
    await db.execute('''
      CREATE TABLE sport_defaults (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER REFERENCES users(id),
        sport_id INTEGER REFERENCES sports(id),
        gender TEXT,
        officials_required INTEGER,
        game_fee TEXT,
        level_of_competition TEXT,
        UNIQUE(user_id, sport_id)
      )
    ''');

    // Teams (for assigners)
    await db.execute('''
      CREATE TABLE teams (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        sport_id INTEGER REFERENCES sports(id),
        grade TEXT,
        gender TEXT,
        user_id INTEGER REFERENCES users(id),
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // Create indexes for better performance
    await _createIndexes(db);
    
    // Insert default sports
    await _insertDefaultSports(db);
  }

  Future<void> _createIndexes(Database db) async {
    await db.execute('CREATE INDEX idx_games_user_id ON games(user_id)');
    await db.execute('CREATE INDEX idx_games_schedule_id ON games(schedule_id)');
    await db.execute('CREATE INDEX idx_games_date ON games(date)');
    await db.execute('CREATE INDEX idx_games_sport_id ON games(sport_id)');
    await db.execute('CREATE INDEX idx_schedules_user_id ON schedules(user_id)');
    await db.execute('CREATE INDEX idx_locations_user_id ON locations(user_id)');
    await db.execute('CREATE INDEX idx_officials_user_id ON officials(user_id)');
  }

  Future<void> _insertDefaultSports(Database db) async {
    final sports = [
      'Football',
      'Basketball',
      'Baseball',
      'Softball',
      'Soccer',
      'Volleyball',
      'Tennis',
      'Track & Field',
      'Swimming',
      'Wrestling',
      'Cross Country',
      'Golf',
      'Hockey',
      'Lacrosse',
    ];

    for (String sport in sports) {
      await db.insert('sports', {'name': sport});
    }
  }

  // Migration utilities
  Future<void> migrateFromSharedPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final db = await database;

    // Check if migration has already been done
    final migrationCompleted = prefs.getBool('database_migration_completed') ?? false;
    if (migrationCompleted) {
      return;
    }

    try {
      await db.transaction((txn) async {
        await _migrateUserData(txn, prefs);
        await _migrateLocations(txn, prefs);
        await _migrateGames(txn, prefs);
        await _migrateTemplates(txn, prefs);
        await _migrateSettings(txn, prefs);
      });

      // Mark migration as completed
      await prefs.setBool('database_migration_completed', true);
      debugPrint('Database migration completed successfully');
    } catch (e) {
      debugPrint('Database migration failed: $e');
      rethrow;
    }
  }

  Future<void> _migrateUserData(Transaction txn, SharedPreferences prefs) async {
    final schedulerType = prefs.getString('schedulerType');
    if (schedulerType == null) return;

    final userData = <String, dynamic>{
      'scheduler_type': schedulerType,
      'setup_completed': false,
    };

    // Add role-specific data
    switch (schedulerType) {
      case 'Athletic Director':
        userData['school_name'] = prefs.getString('ad_school_name');
        userData['mascot'] = prefs.getString('ad_mascot');
        userData['setup_completed'] = prefs.getBool('ad_setup_completed') ?? false;
        break;
      case 'Coach':
        userData['team_name'] = prefs.getString('team_name');
        userData['sport'] = prefs.getString('sport');
        userData['grade'] = prefs.getString('grade');
        userData['gender'] = prefs.getString('gender');
        userData['setup_completed'] = prefs.getBool('team_setup_completed') ?? false;
        break;
      case 'Assigner':
        userData['sport'] = prefs.getString('assigner_sport');
        userData['league_name'] = prefs.getString('league_name');
        userData['setup_completed'] = prefs.getBool('assigner_setup_completed') ?? false;
        break;
    }

    await txn.insert('users', userData);
  }

  Future<void> _migrateLocations(Transaction txn, SharedPreferences prefs) async {
    final locationsJson = prefs.getString('saved_locations');
    if (locationsJson == null || locationsJson.isEmpty) return;

    try {
      final List<dynamic> locations = jsonDecode(locationsJson);
      for (var location in locations) {
        await txn.insert('locations', {
          'name': location['name'],
          'address': location['address'],
          'notes': location['notes'],
          'user_id': 1, // Assuming first user for migration
        });
      }
    } catch (e) {
      debugPrint('Error migrating locations: $e');
    }
  }

  Future<void> _migrateGames(Transaction txn, SharedPreferences prefs) async {
    // Migrate published games
    await _migrateGamesList(txn, prefs, 'ad_published_games', 'Published');
    await _migrateGamesList(txn, prefs, 'coach_published_games', 'Published');
    await _migrateGamesList(txn, prefs, 'assigner_published_games', 'Published');
    
    // Migrate unpublished games
    await _migrateGamesList(txn, prefs, 'ad_unpublished_games', 'Unpublished');
    await _migrateGamesList(txn, prefs, 'coach_unpublished_games', 'Unpublished');
    await _migrateGamesList(txn, prefs, 'assigner_unpublished_games', 'Unpublished');
  }

  Future<void> _migrateGamesList(Transaction txn, SharedPreferences prefs, String key, String status) async {
    final gamesJson = prefs.getString(key);
    if (gamesJson == null || gamesJson.isEmpty) return;

    try {
      final List<dynamic> games = jsonDecode(gamesJson);
      for (var game in games) {
        // Get or create sport
        final sportId = await _getOrCreateSport(txn, game['sport'] ?? 'Football');
        
        // Get or create schedule
        final scheduleId = await _getOrCreateSchedule(txn, game['scheduleName'], sportId);
        
        // Get or create location
        final locationId = await _getOrCreateLocation(txn, game['location']);

        final gameData = <String, dynamic>{
          'schedule_id': scheduleId,
          'sport_id': sportId,
          'location_id': locationId,
          'user_id': 1, // Assuming first user for migration
          'date': game['date'],
          'time': game['time'],
          'is_away': game['isAway'] ?? false,
          'level_of_competition': game['levelOfCompetition'],
          'gender': game['gender'],
          'officials_required': game['officialsRequired'] ?? 0,
          'officials_hired': game['officialsHired'] ?? 0,
          'game_fee': game['gameFee'],
          'opponent': game['opponent'],
          'hire_automatically': game['hireAutomatically'] ?? false,
          'method': game['method'],
          'status': status,
        };

        await txn.insert('games', gameData);
      }
    } catch (e) {
      debugPrint('Error migrating games from $key: $e');
    }
  }

  Future<int> _getOrCreateSport(Transaction txn, String sportName) async {
    final existing = await txn.query(
      'sports',
      where: 'name = ?',
      whereArgs: [sportName],
    );

    if (existing.isNotEmpty) {
      return existing.first['id'] as int;
    }

    return await txn.insert('sports', {'name': sportName});
  }

  Future<int?> _getOrCreateSchedule(Transaction txn, String? scheduleName, int sportId) async {
    if (scheduleName == null || scheduleName.isEmpty) return null;

    final existing = await txn.query(
      'schedules',
      where: 'name = ? AND sport_id = ? AND user_id = ?',
      whereArgs: [scheduleName, sportId, 1],
    );

    if (existing.isNotEmpty) {
      return existing.first['id'] as int;
    }

    return await txn.insert('schedules', {
      'name': scheduleName,
      'sport_id': sportId,
      'user_id': 1,
    });
  }

  Future<int?> _getOrCreateLocation(Transaction txn, String? locationName) async {
    if (locationName == null || locationName.isEmpty) return null;

    final existing = await txn.query(
      'locations',
      where: 'name = ? AND user_id = ?',
      whereArgs: [locationName, 1],
    );

    if (existing.isNotEmpty) {
      return existing.first['id'] as int;
    }

    return await txn.insert('locations', {
      'name': locationName,
      'user_id': 1,
    });
  }

  Future<void> _migrateTemplates(Transaction txn, SharedPreferences prefs) async {
    final templatesJson = prefs.getString('game_templates');
    if (templatesJson == null || templatesJson.isEmpty) return;

    try {
      final List<dynamic> templates = jsonDecode(templatesJson);
      for (var template in templates) {
        final sportId = await _getOrCreateSport(txn, template['sport'] ?? 'Football');
        final locationId = await _getOrCreateLocation(txn, template['location']);

        await txn.insert('game_templates', {
          'name': template['name'],
          'sport_id': sportId,
          'user_id': 1,
          'schedule_name': template['scheduleName'],
          'date': template['date'],
          'time': template['time'],
          'location_id': locationId,
          'is_away_game': template['isAwayGame'] ?? false,
          'level_of_competition': template['levelOfCompetition'],
          'gender': template['gender'],
          'officials_required': template['officialsRequired'],
          'game_fee': template['gameFee'],
          'opponent': template['opponent'],
          'hire_automatically': template['hireAutomatically'],
          'method': template['method'],
          'include_schedule_name': template['includeScheduleName'] ?? false,
          'include_sport': template['includeSport'] ?? false,
          'include_date': template['includeDate'] ?? false,
          'include_time': template['includeTime'] ?? false,
          'include_location': template['includeLocation'] ?? false,
          'include_is_away_game': template['includeIsAwayGame'] ?? false,
          'include_level_of_competition': template['includeLevelOfCompetition'] ?? false,
          'include_gender': template['includeGender'] ?? false,
          'include_officials_required': template['includeOfficialsRequired'] ?? false,
          'include_game_fee': template['includeGameFee'] ?? false,
          'include_opponent': template['includeOpponent'] ?? false,
          'include_hire_automatically': template['includeHireAutomatically'] ?? false,
          'include_selected_officials': template['includeSelectedOfficials'] ?? false,
          'include_officials_list': template['includeOfficialsList'] ?? false,
        });
      }
    } catch (e) {
      debugPrint('Error migrating templates: $e');
    }
  }

  Future<void> _migrateSettings(Transaction txn, SharedPreferences prefs) async {
    final settings = <String, dynamic>{
      'showAwayGames': prefs.getBool('showAwayGames'),
      'showFullyCoveredGames': prefs.getBool('showFullyCoveredGames'),
      'scheduleFilters': prefs.getString('scheduleFilters'),
      'dont_ask_create_template': prefs.getBool('dont_ask_create_template'),
    };

    for (var entry in settings.entries) {
      if (entry.value != null) {
        await txn.insert('user_settings', {
          'user_id': 1,
          'key': entry.key,
          'value': entry.value.toString(),
        });
      }
    }
  }

  // Utility methods
  Future<void> close() async {
    final db = await database;
    await db.close();
  }

  Future<void> deleteDatabase() async {
    String path = join(await getDatabasesPath(), 'efficials.db');
    await databaseFactory.deleteDatabase(path);
    _database = null;
  }
}