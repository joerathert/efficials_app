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
      version: 8,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await _createTables(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Handle database upgrades here
    if (oldVersion < 2) {
      // Add new tables for Official user functionality
      await db.execute('''
        CREATE TABLE official_users (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          email TEXT UNIQUE NOT NULL,
          password_hash TEXT NOT NULL,
          phone TEXT,
          first_name TEXT NOT NULL,
          last_name TEXT NOT NULL,
          profile_verified BOOLEAN DEFAULT FALSE,
          email_verified BOOLEAN DEFAULT FALSE,
          phone_verified BOOLEAN DEFAULT FALSE,
          status TEXT DEFAULT 'active',
          created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
          updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
        )
      ''');

      await db.execute('''
        CREATE TABLE game_assignments (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          game_id INTEGER REFERENCES games(id),
          official_id INTEGER REFERENCES officials(id),
          position TEXT,
          status TEXT DEFAULT 'pending',
          assigned_by INTEGER REFERENCES users(id),
          assigned_at DATETIME DEFAULT CURRENT_TIMESTAMP,
          responded_at DATETIME,
          response_notes TEXT,
          fee_amount DECIMAL(10,2),
          UNIQUE(game_id, official_id)
        )
      ''');

      await db.execute('''
        CREATE TABLE official_availability (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          official_id INTEGER REFERENCES officials(id),
          date DATE NOT NULL,
          start_time TIME,
          end_time TIME,
          status TEXT DEFAULT 'available',
          notes TEXT,
          created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
          UNIQUE(official_id, date, start_time)
        )
      ''');

      await db.execute('''
        CREATE TABLE official_sports (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          official_id INTEGER REFERENCES officials(id),
          sport_id INTEGER REFERENCES sports(id),
          certification_level TEXT,
          years_experience INTEGER,
          is_primary BOOLEAN DEFAULT FALSE,
          created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
          UNIQUE(official_id, sport_id)
        )
      ''');

      await db.execute('''
        CREATE TABLE official_notifications (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          official_id INTEGER REFERENCES officials(id),
          type TEXT NOT NULL,
          title TEXT NOT NULL,
          message TEXT NOT NULL,
          related_game_id INTEGER REFERENCES games(id),
          read_at DATETIME,
          created_at DATETIME DEFAULT CURRENT_TIMESTAMP
        )
      ''');

      await db.execute('''
        CREATE TABLE official_settings (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          official_id INTEGER REFERENCES officials(id),
          setting_key TEXT NOT NULL,
          setting_value TEXT,
          UNIQUE(official_id, setting_key)
        )
      ''');

      // Add new columns to existing officials table
      await db.execute('ALTER TABLE officials ADD COLUMN official_user_id INTEGER REFERENCES official_users(id)');
      await db.execute('ALTER TABLE officials ADD COLUMN email TEXT');
      await db.execute('ALTER TABLE officials ADD COLUMN phone TEXT');
      await db.execute('ALTER TABLE officials ADD COLUMN availability_status TEXT DEFAULT "available"');
      await db.execute('ALTER TABLE officials ADD COLUMN profile_image_url TEXT');
      await db.execute('ALTER TABLE officials ADD COLUMN bio TEXT');
      await db.execute('ALTER TABLE officials ADD COLUMN experience_years INTEGER');
      await db.execute('ALTER TABLE officials ADD COLUMN certification_level TEXT');
      await db.execute('ALTER TABLE officials ADD COLUMN is_user_account BOOLEAN DEFAULT FALSE');

      // Add new columns to existing users table
      await db.execute('ALTER TABLE users ADD COLUMN user_type TEXT DEFAULT "scheduler"');
      await db.execute('ALTER TABLE users ADD COLUMN email TEXT');
      await db.execute('ALTER TABLE users ADD COLUMN password_hash TEXT');
      await db.execute('ALTER TABLE users ADD COLUMN first_name TEXT');
      await db.execute('ALTER TABLE users ADD COLUMN last_name TEXT');
      await db.execute('ALTER TABLE users ADD COLUMN phone TEXT');

      // Add indexes for new tables
      await db.execute('CREATE INDEX idx_official_users_email ON official_users(email)');
      await db.execute('CREATE INDEX idx_game_assignments_game_id ON game_assignments(game_id)');
      await db.execute('CREATE INDEX idx_game_assignments_official_id ON game_assignments(official_id)');
      await db.execute('CREATE INDEX idx_game_assignments_status ON game_assignments(status)');
      await db.execute('CREATE INDEX idx_official_availability_official_id ON official_availability(official_id)');
      await db.execute('CREATE INDEX idx_official_availability_date ON official_availability(date)');
      await db.execute('CREATE INDEX idx_official_sports_official_id ON official_sports(official_id)');
      await db.execute('CREATE INDEX idx_official_sports_sport_id ON official_sports(sport_id)');
      await db.execute('CREATE INDEX idx_official_notifications_official_id ON official_notifications(official_id)');
      await db.execute('CREATE INDEX idx_official_settings_official_id ON official_settings(official_id)');
    }
    
    if (oldVersion < 3) {
      // Add home_team column to games table
      await db.execute('ALTER TABLE games ADD COLUMN home_team TEXT');
      
      // Try to populate home_team for existing games
      // Get Athletic Director's school info from SharedPreferences if available
      try {
        final prefs = await SharedPreferences.getInstance();
        
        // Update test data to use Edwardsville Tigers instead of Test School Eagles
        final currentSchoolName = prefs.getString('ad_school_name');
        final currentMascot = prefs.getString('ad_mascot');
        
        String schoolName = 'Edwardsville';
        String mascot = 'Tigers';
        
        // Use existing school info if available, otherwise default to Edwardsville Tigers
        if (currentSchoolName != null && currentMascot != null && 
            currentSchoolName != 'Test School' && currentSchoolName != 'Default School' && currentSchoolName != 'Central High School') {
          schoolName = currentSchoolName;
          mascot = currentMascot;
        }
        // Note: Don't update SharedPreferences here - version 5 migration will handle moving to database
        
        final homeTeam = '$schoolName $mascot';
        await db.execute(
          'UPDATE games SET home_team = ? WHERE home_team IS NULL OR home_team = ? OR home_team = ? OR home_team = ?',
          [homeTeam, 'Test School Eagles', 'Default School Eagles', 'Central High School Eagles']
        );
        
        // Also update users table with correct school info
        await db.execute(
          'UPDATE users SET school_name = ?, mascot = ? WHERE (school_name = ? OR school_name = ? OR school_name = ?) AND scheduler_type = ?',
          [schoolName, mascot, 'Test School', 'Default School', 'Central High School', 'Athletic Director']
        );
        
      } catch (e) {
        // If we can't get prefs or update, just continue - the column is added
        print('Could not populate home_team for existing games: $e');
      }
    }
    
    if (oldVersion < 4) {
      // Update existing test data to use Edwardsville Tigers
      try {
        // Force update to Edwardsville Tigers for any remaining test data
        
        // Update all games with test school names to use Edwardsville Tigers
        await db.execute(
          'UPDATE games SET home_team = ? WHERE home_team = ? OR home_team = ? OR home_team = ? OR home_team LIKE ?',
          ['Edwardsville Tigers', 'Test School Eagles', 'Default School Eagles', 'Central High School Eagles', '%Test%']
        );
        
        // Update users table as well
        await db.execute(
          'UPDATE users SET school_name = ?, mascot = ? WHERE scheduler_type = ? AND (school_name LIKE ? OR school_name = ? OR school_name = ?)',
          ['Edwardsville', 'Tigers', 'Athletic Director', '%Test%', 'Default School', 'Central High School']
        );
        
      } catch (e) {
        print('Could not update test data to Edwardsville Tigers: $e');
      }
    }
    
    if (oldVersion < 5) {
      // Migrate Athletic Director school information from SharedPreferences to database
      try {
        final prefs = await SharedPreferences.getInstance();
        final schoolName = prefs.getString('ad_school_name');
        final mascot = prefs.getString('ad_mascot');
        final setupCompleted = prefs.getBool('ad_setup_completed') ?? false;
        
        if (schoolName != null && mascot != null) {
          // Update any Athletic Director users with the school information
          await db.execute(
            'UPDATE users SET school_name = ?, mascot = ?, setup_completed = ? WHERE scheduler_type = ?',
            [schoolName, mascot, setupCompleted ? 1 : 0, 'Athletic Director']
          );
          
          // Clean up the SharedPreferences entries since they're now in the database
          await prefs.remove('ad_school_name');
          await prefs.remove('ad_mascot');
          await prefs.remove('ad_setup_completed');
          
          print('Successfully migrated AD school info from SharedPreferences to database');
        }
      } catch (e) {
        print('Could not migrate AD school info from SharedPreferences: $e');
      }
    }
    
    if (oldVersion < 6) {
      // Add user sessions table
      await db.execute('''
        CREATE TABLE user_sessions (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          user_id INTEGER NOT NULL,
          user_type TEXT NOT NULL,
          email TEXT NOT NULL,
          created_at DATETIME DEFAULT CURRENT_TIMESTAMP
        )
      ''');
      
      // Add indexes for user sessions
      await db.execute('CREATE INDEX idx_user_sessions_user_id ON user_sessions(user_id)');
      await db.execute('CREATE INDEX idx_user_sessions_created_at ON user_sessions(created_at)');
    }
    
    if (oldVersion < 7) {
      // Add back out functionality columns to game_assignments table
      await db.execute('ALTER TABLE game_assignments ADD COLUMN backed_out_at DATETIME');
      await db.execute('ALTER TABLE game_assignments ADD COLUMN back_out_reason TEXT');
    }
    
    if (oldVersion < 8) {
      // Add school_address column to users table
      await db.execute('ALTER TABLE users ADD COLUMN school_address TEXT');
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
        school_address TEXT,
        team_name TEXT,
        sport TEXT,
        grade TEXT,
        gender TEXT,
        league_name TEXT,
        user_type TEXT DEFAULT 'scheduler',
        email TEXT,
        password_hash TEXT,
        first_name TEXT,
        last_name TEXT,
        phone TEXT,
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
        official_user_id INTEGER REFERENCES official_users(id),
        email TEXT,
        phone TEXT,
        availability_status TEXT DEFAULT 'available',
        profile_image_url TEXT,
        bio TEXT,
        experience_years INTEGER,
        certification_level TEXT,
        is_user_account BOOLEAN DEFAULT FALSE,
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
        home_team TEXT,
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

    // Official user authentication table
    await db.execute('''
      CREATE TABLE official_users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        email TEXT UNIQUE NOT NULL,
        password_hash TEXT NOT NULL,
        phone TEXT,
        first_name TEXT NOT NULL,
        last_name TEXT NOT NULL,
        profile_verified BOOLEAN DEFAULT FALSE,
        email_verified BOOLEAN DEFAULT FALSE,
        phone_verified BOOLEAN DEFAULT FALSE,
        status TEXT DEFAULT 'active',
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // Game assignments table for tracking assignment status
    await db.execute('''
      CREATE TABLE game_assignments (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        game_id INTEGER REFERENCES games(id),
        official_id INTEGER REFERENCES officials(id),
        position TEXT,
        status TEXT DEFAULT 'pending',
        assigned_by INTEGER REFERENCES users(id),
        assigned_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        responded_at DATETIME,
        response_notes TEXT,
        fee_amount DECIMAL(10,2),
        backed_out_at DATETIME,
        back_out_reason TEXT,
        UNIQUE(game_id, official_id)
      )
    ''');

    // Official availability table
    await db.execute('''
      CREATE TABLE official_availability (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        official_id INTEGER REFERENCES officials(id),
        date DATE NOT NULL,
        start_time TIME,
        end_time TIME,
        status TEXT DEFAULT 'available',
        notes TEXT,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        UNIQUE(official_id, date, start_time)
      )
    ''');

    // Official sports and certifications
    await db.execute('''
      CREATE TABLE official_sports (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        official_id INTEGER REFERENCES officials(id),
        sport_id INTEGER REFERENCES sports(id),
        certification_level TEXT,
        years_experience INTEGER,
        competition_levels TEXT,
        is_primary BOOLEAN DEFAULT FALSE,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        UNIQUE(official_id, sport_id)
      )
    ''');

    // Official notifications
    await db.execute('''
      CREATE TABLE official_notifications (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        official_id INTEGER REFERENCES officials(id),
        type TEXT NOT NULL,
        title TEXT NOT NULL,
        message TEXT NOT NULL,
        related_game_id INTEGER REFERENCES games(id),
        read_at DATETIME,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // Official settings
    await db.execute('''
      CREATE TABLE official_settings (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        official_id INTEGER REFERENCES officials(id),
        setting_key TEXT NOT NULL,
        setting_value TEXT,
        UNIQUE(official_id, setting_key)
      )
    ''');

    // User sessions table (for authentication state)
    await db.execute('''
      CREATE TABLE user_sessions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        user_type TEXT NOT NULL,
        email TEXT NOT NULL,
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
    
    // Indexes for new official tables
    await db.execute('CREATE INDEX idx_official_users_email ON official_users(email)');
    await db.execute('CREATE INDEX idx_game_assignments_game_id ON game_assignments(game_id)');
    await db.execute('CREATE INDEX idx_game_assignments_official_id ON game_assignments(official_id)');
    await db.execute('CREATE INDEX idx_game_assignments_status ON game_assignments(status)');
    await db.execute('CREATE INDEX idx_official_availability_official_id ON official_availability(official_id)');
    await db.execute('CREATE INDEX idx_official_availability_date ON official_availability(date)');
    await db.execute('CREATE INDEX idx_official_sports_official_id ON official_sports(official_id)');
    await db.execute('CREATE INDEX idx_official_sports_sport_id ON official_sports(sport_id)');
    await db.execute('CREATE INDEX idx_official_notifications_official_id ON official_notifications(official_id)');
    await db.execute('CREATE INDEX idx_official_settings_official_id ON official_settings(official_id)');
    
    // Indexes for user sessions
    await db.execute('CREATE INDEX idx_user_sessions_user_id ON user_sessions(user_id)');
    await db.execute('CREATE INDEX idx_user_sessions_created_at ON user_sessions(created_at)');
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
        await _migrateOfficials(txn, prefs);
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

    // Check if user already exists
    final existingUsers = await txn.query('users', limit: 1);
    if (existingUsers.isNotEmpty) {
      debugPrint('User already exists, skipping user migration');
      return;
    }

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

  Future<void> _migrateOfficials(Transaction txn, SharedPreferences prefs) async {
    final listsJson = prefs.getString('saved_lists');
    if (listsJson == null || listsJson.isEmpty) return;

    try {
      final List<dynamic> officialLists = jsonDecode(listsJson);
      for (var list in officialLists) {
        final listName = list['name'];
        final sport = list['sport'];
        
        if (listName == null || sport == null) continue;

        // Get or create sport
        final sportId = await _getOrCreateSport(txn, sport);
        
        // Create official list
        final listId = await txn.insert('official_lists', {
          'name': listName,
          'sport_id': sportId,
          'user_id': 1,
        });

        // Add officials to the list
        final officials = list['officials'];
        if (officials != null && officials is List) {
          for (var official in officials) {
            String officialName;
            if (official is String) {
              officialName = official;
            } else if (official is Map && official['name'] != null) {
              officialName = official['name'];
            } else {
              continue;
            }

            // Create official
            final officialId = await txn.insert('officials', {
              'name': officialName,
              'sport_id': sportId,
              'user_id': 1,
            });

            // Add to list
            await txn.insert('official_list_members', {
              'list_id': listId,
              'official_id': officialId,
            });
          }
        }
      }
    } catch (e) {
      debugPrint('Error migrating officials: $e');
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
    // Only migrate business-related settings, not UI preferences
    final settings = <String, dynamic>{
      'scheduleFilters': prefs.getString('scheduleFilters'),
    };

    for (var entry in settings.entries) {
      if (entry.value != null) {
        // Check if setting already exists
        final existing = await txn.query(
          'user_settings',
          where: 'user_id = ? AND key = ?',
          whereArgs: [1, entry.key],
        );

        if (existing.isNotEmpty) {
          // Update existing setting
          await txn.update(
            'user_settings',
            {'value': entry.value.toString()},
            where: 'user_id = ? AND key = ?',
            whereArgs: [1, entry.key],
          );
        } else {
          // Insert new setting
          await txn.insert('user_settings', {
            'user_id': 1,
            'key': entry.key,
            'value': entry.value.toString(),
          });
        }
      }
    }
    
    // Clean up only the business settings that were migrated from SharedPreferences
    try {
      await prefs.remove('scheduleFilters');
      // UI preferences (showAwayGames, showFullyCoveredGames, etc.) stay in SharedPreferences
    } catch (e) {
      debugPrint('Could not clean up SharedPreferences settings: $e');
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