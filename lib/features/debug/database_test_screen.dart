import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import '../../shared/theme.dart';
import '../../shared/services/migration_service.dart';
import '../../shared/services/repositories/user_repository.dart';
import '../../shared/services/database_helper.dart';
import '../../shared/services/auth_service.dart';
import '../../shared/models/database_models.dart';
import '../../shared/utils/database_cleanup.dart';
import '../../create_officials_from_csv.dart';

class DatabaseTestScreen extends StatefulWidget {
  const DatabaseTestScreen({super.key});

  @override
  State<DatabaseTestScreen> createState() => _DatabaseTestScreenState();
}

class _DatabaseTestScreenState extends State<DatabaseTestScreen> {
  Map<String, dynamic> migrationStatus = {};
  bool isLoading = true;
  String testResult = '';

  @override
  void initState() {
    super.initState();
    _loadMigrationStatus();
  }

  Future<void> _loadMigrationStatus() async {
    try {
      final status = await MigrationService().getMigrationStatus();
      setState(() {
        migrationStatus = status;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        testResult = 'Error loading migration status: $e';
        isLoading = false;
      });
    }
  }

  Future<void> _testDatabase() async {
    setState(() {
      isLoading = true;
      testResult = 'Testing database functionality...';
    });

    try {
      final success = await MigrationService().testDatabaseFunctionality();
      setState(() {
        testResult = success
            ? 'Database test completed successfully!'
            : 'Database test failed!';
        isLoading = false;
      });

      // Reload status after test
      await _loadMigrationStatus();
    } catch (e) {
      setState(() {
        testResult = 'Database test error: $e';
        isLoading = false;
      });
    }
  }

  Future<void> _forceMigration() async {
    setState(() {
      isLoading = true;
      testResult = 'Running migration...';
    });

    try {
      await MigrationService().forceMigration();
      setState(() {
        testResult = 'Migration completed successfully!';
        isLoading = false;
      });

      // Reload status after migration
      await _loadMigrationStatus();
    } catch (e) {
      setState(() {
        testResult = 'Migration error: $e';
        isLoading = false;
      });
    }
  }

  Future<void> _cleanupDuplicateGames() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cleanup Duplicate Games'),
        content: const Text(
            'This will remove duplicate games and fix missing home team information. This action cannot be undone. Continue?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Cleanup'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() {
        isLoading = true;
        testResult = 'Cleaning up duplicate games...';
      });

      try {
        // First, let's check what duplicates exist
        final duplicates = await DatabaseCleanup.findPotentialDuplicates();

        if (duplicates.isEmpty) {
          setState(() {
            testResult = 'No duplicate games found.';
            isLoading = false;
          });
          return;
        }

        // Show the duplicates found
        StringBuffer result = StringBuffer();
        result.writeln(
            'Found ${duplicates.length} sets of potential duplicates:');
        for (var duplicate in duplicates) {
          result.writeln(
              '- ${duplicate['opponent']} on ${duplicate['date']} (${duplicate['count']} copies)');
        }
        result.writeln('\nPerforming cleanup...');

        // Perform the cleanup
        await DatabaseCleanup.cleanupDuplicateGames();

        result.writeln('Cleanup completed successfully!');

        setState(() {
          testResult = result.toString();
          isLoading = false;
        });

        // Reload migration status
        await _loadMigrationStatus();
      } catch (e) {
        setState(() {
          testResult = 'Error during cleanup: $e';
          isLoading = false;
        });
      }
    }
  }

  Future<void> _showRecentGames() async {
    setState(() {
      isLoading = true;
      testResult = 'Loading recent games...';
    });

    try {
      print('DEBUG: Starting to fetch recent games...');
      final recentGames = await DatabaseCleanup.getRecentGamesWithDetails();
      print('DEBUG: Fetched ${recentGames.length} recent games');

      StringBuffer result = StringBuffer();
      result.writeln('=== RECENT GAMES (Last Hour) ===');
      result.writeln('Found ${recentGames.length} games:\n');

      for (int i = 0; i < recentGames.length; i++) {
        final game = recentGames[i];
        result.writeln('${i + 1}. Game ID: ${game['id']}');
        result.writeln('   Sport: ${game['sport_name']}');
        result.writeln('   Opponent: "${game['opponent']}"');
        result.writeln('   Home Team: "${game['home_team']}"');
        result.writeln('   Date: ${game['date']}');
        result.writeln('   Time: ${game['time']}');
        result.writeln('   Status: ${game['status']}');
        result.writeln('   Location: ${game['location_name']}');
        result.writeln(
            '   Posted by: ${game['first_name']} ${game['last_name']}');
        result.writeln('   Created: ${game['created_at']}');
        result.writeln('');
      }

      // Check for potential duplicates
      final duplicates = <String, List<Map<String, dynamic>>>{};
      for (final game in recentGames) {
        final key =
            '${game['opponent']}_${game['date']}_${game['time']}_${game['sport_name']}';
        duplicates[key] ??= [];
        duplicates[key]!.add(game);
      }

      final actualDuplicates =
          duplicates.entries.where((entry) => entry.value.length > 1).toList();
      if (actualDuplicates.isNotEmpty) {
        result.writeln('⚠️ POTENTIAL DUPLICATES DETECTED:');
        for (final duplicate in actualDuplicates) {
          result.writeln(
              '- ${duplicate.value.length} games with same opponent/date/time:');
          for (final game in duplicate.value) {
            result.writeln(
                '  ID ${game['id']}: opponent="${game['opponent']}", home_team="${game['home_team']}"');
          }
        }
      } else {
        result.writeln('✅ No duplicates detected in recent games.');
      }

      setState(() {
        testResult = result.toString();
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        testResult = 'Error loading recent games: $e';
        isLoading = false;
      });
    }
  }

  Future<void> _showAllGames() async {
    setState(() {
      isLoading = true;
      testResult = 'Loading all games...';
    });

    try {
      print('DEBUG: Starting to fetch all games...');
      final db = await DatabaseHelper().database;

      final allGames = await db.rawQuery('''
        SELECT g.id, g.opponent, g.home_team, g.date, g.time, g.status, 
               g.created_at, s.name as sport_name
        FROM games g
        LEFT JOIN sports s ON g.sport_id = s.id
        ORDER BY g.created_at DESC
        LIMIT 20
      ''');

      print('DEBUG: Fetched ${allGames.length} games');

      StringBuffer result = StringBuffer();
      result.writeln('=== ALL GAMES (Last 20) ===');
      result.writeln('Found ${allGames.length} games:\n');

      for (int i = 0; i < allGames.length; i++) {
        final game = allGames[i];
        result.writeln('${i + 1}. ID: ${game['id']}');
        result.writeln('   Sport: ${game['sport_name']}');
        result.writeln('   Opponent: "${game['opponent']}"');
        result.writeln('   Home Team: "${game['home_team']}"');
        result.writeln('   Status: ${game['status']}');
        result.writeln('   Created: ${game['created_at']}');
        result.writeln('');
      }

      setState(() {
        testResult = result.toString();
        isLoading = false;
      });
    } catch (e) {
      print('DEBUG: Error in _showAllGames: $e');
      setState(() {
        testResult = 'Error loading games: $e';
        isLoading = false;
      });
    }
  }

  Future<void> _removeNullHomeTeamGames() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Invalid Games'),
        content: const Text(
            'This will remove games that have null or empty home team values. These games appear as duplicates to officials. Continue?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() {
        isLoading = true;
        testResult = 'Removing games with null home team...';
      });

      try {
        await DatabaseCleanup.removeGamesWithNullHomeTeam();

        setState(() {
          testResult =
              'Successfully removed games with null home team. Check the console for details.';
          isLoading = false;
        });

        // Reload migration status
        await _loadMigrationStatus();
      } catch (e) {
        setState(() {
          testResult = 'Error removing games: $e';
          isLoading = false;
        });
      }
    }
  }

  Future<void> _resetDatabase() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Database'),
        content:
            const Text('This will delete all database data. Are you sure?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Reset'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() {
        isLoading = true;
        testResult = 'Resetting database...';
      });

      try {
        await MigrationService().resetDatabase();
        setState(() {
          testResult = 'Database reset completed!';
          isLoading = false;
        });

        // Reload status after reset
        await _loadMigrationStatus();
      } catch (e) {
        setState(() {
          testResult = 'Database reset error: $e';
          isLoading = false;
        });
      }
    }
  }

  Future<void> _clearTemplatesOnly() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Templates Only'),
        content: const Text(
            'This will delete only game templates while preserving officials and other data. Are you sure?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Clear Templates'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() {
        isLoading = true;
        testResult = 'Clearing templates...';
      });

      try {
        await MigrationService().clearTemplatesOnly();
        setState(() {
          testResult = 'Templates cleared successfully! (Officials preserved)';
          isLoading = false;
        });

        // Reload status after clearing
        await _loadMigrationStatus();
      } catch (e) {
        setState(() {
          testResult = 'Template clearing error: $e';
          isLoading = false;
        });
      }
    }
  }

  Future<void> _fixDatabaseSchema() async {
    setState(() {
      isLoading = true;
      testResult = 'Fixing database schema...';
    });

    try {
      await DatabaseHelper().fixDatabaseSchema();
      setState(() {
        testResult =
            '✅ Database schema fixed successfully!\n\nMissing columns and tables have been added.';
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        testResult = '❌ Error fixing database schema: $e';
        isLoading = false;
      });
    }
  }

  Future<void> _showDatabasePath() async {
    setState(() {
      isLoading = true;
      testResult = 'Finding database path...';
    });

    try {
      final db = await DatabaseHelper().database;
      final dbPath = db.path;

      setState(() {
        testResult = '=== DATABASE LOCATION ===\n\n'
            'Database File: efficials.db\n'
            'Full Path: $dbPath\n\n'
            'You can use SQLite tools like:\n'
            '• DB Browser for SQLite\n'
            '• SQLite Expert\n'
            '• SQLiteStudio\n'
            '• VS Code SQLite extension\n\n'
            'to view and edit this database directly.';
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        testResult = 'Error finding database path: $e';
        isLoading = false;
      });
    }
  }

  Future<void> _viewAllOfficials() async {
    setState(() {
      isLoading = true;
      testResult = 'Loading all officials...';
    });

    try {
      final db = await DatabaseHelper().database;

      // First check database version
      final dbVersion = await db.getVersion();

      final officials = await db.rawQuery('''
        SELECT 
          o.id,
          o.name,
          o.email,
          o.phone,
          o.city,
          o.state,
          o.availability_status,
          o.created_at
        FROM officials o
        ORDER BY o.email ASC
      ''');

      String result = '=== ALL OFFICIALS (${officials.length}) ===\n';
      result += 'Database Version: $dbVersion\n\n';

      for (int i = 0; i < officials.length; i++) {
        final official = officials[i];
        final num = (i + 1).toString().padLeft(3, ' ');

        result += '$num. ${official['name']}\n';
        result += '     Email: ${official['email'] ?? 'Not provided'}\n';
        result += '     Phone: ${official['phone'] ?? 'Not provided'}\n';

        final city = official['city'];
        final state = official['state'];
        String location = 'Not provided';
        if (city != null && city.toString().isNotEmpty && city != 'null') {
          location = city.toString();
          if (state != null && state.toString().isNotEmpty && state != 'null') {
            location += ', $state';
          }
        }
        result += '     Location: $location\n';
        result +=
            '     Status: ${official['availability_status'] ?? 'Unknown'}\n\n';
      }

      setState(() {
        testResult = result;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        testResult = 'Error loading officials: $e';
        isLoading = false;
      });
    }
  }

  Future<void> _createSchedulersAndFootballOfficials() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Schedulers + Football Officials'),
        content: const Text(
            'This will create 3 Scheduler users (AD, Assigner, Coach) and 123 real Football Officials from your CSV data. All will have password "test123". Continue?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Create Users'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      setState(() {
        isLoading = true;
        testResult = 'Creating schedulers and football officials...';
      });
      try {
        final result = await _generateSchedulersAndFootballOfficials();
        setState(() {
          testResult = result;
          isLoading = false;
        });
        // Reload status after creating users
        await _loadMigrationStatus();
      } catch (e) {
        setState(() {
          testResult = 'User creation error: $e';
          isLoading = false;
        });
      }
    }
  }

  Future<void> _createTestUsers() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Test Users'),
        content: const Text(
            'This will create 3 Scheduler users and 100 Official users for testing. All will have password "test123". Continue?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Create Users'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() {
        isLoading = true;
        testResult = 'Creating test users...';
      });

      try {
        final result = await _generateTestUsers();
        setState(() {
          testResult = result;
          isLoading = false;
        });

        // Reload status after creating users
        await _loadMigrationStatus();
      } catch (e) {
        setState(() {
          testResult = 'Test user creation error: $e';
          isLoading = false;
        });
      }
    }
  }

  String _hashPassword(String password) {
    return AuthService.hashPassword(password);
  }

  Map<String, String> _getRandomIllinoisLocation(int index) {
    // Illinois cities within 100 miles of Edwardsville, IL
    final illinoisLocations = [
      {'city': 'Edwardsville', 'state': 'IL'},
      {'city': 'St. Louis', 'state': 'MO'},
      {'city': 'Alton', 'state': 'IL'},
      {'city': 'Belleville', 'state': 'IL'},
      {'city': 'Granite City', 'state': 'IL'},
      {'city': 'Collinsville', 'state': 'IL'},
      {'city': 'Glen Carbon', 'state': 'IL'},
      {'city': 'Wood River', 'state': 'IL'},
      {'city': 'Bethalto', 'state': 'IL'},
      {'city': 'Godfrey', 'state': 'IL'},
      {'city': 'Troy', 'state': 'IL'},
      {'city': 'Maryville', 'state': 'IL'},
      {'city': 'Highland', 'state': 'IL'},
      {'city': 'Greenville', 'state': 'IL'},
      {'city': 'Jerseyville', 'state': 'IL'},
      {'city': 'Carlinville', 'state': 'IL'},
      {'city': 'Litchfield', 'state': 'IL'},
      {'city': 'Staunton', 'state': 'IL'},
      {'city': 'Gillespie', 'state': 'IL'},
      {'city': 'Mount Olive', 'state': 'IL'},
      {'city': 'Hillsboro', 'state': 'IL'},
      {'city': 'Taylorville', 'state': 'IL'},
      {'city': 'Springfield', 'state': 'IL'},
      {'city': 'Decatur', 'state': 'IL'},
      {'city': 'Champaign', 'state': 'IL'},
      {'city': 'Urbana', 'state': 'IL'},
      {'city': 'Effingham', 'state': 'IL'},
      {'city': 'Mattoon', 'state': 'IL'},
      {'city': 'Charleston', 'state': 'IL'},
      {'city': 'Vandalia', 'state': 'IL'},
      {'city': 'Centralia', 'state': 'IL'},
      {'city': 'Salem', 'state': 'IL'},
      {'city': 'Mount Vernon', 'state': 'IL'},
      {'city': 'Carbondale', 'state': 'IL'},
      {'city': 'Marion', 'state': 'IL'},
      {'city': 'O\'Fallon', 'state': 'IL'},
      {'city': 'Fairview Heights', 'state': 'IL'},
      {'city': 'Swansea', 'state': 'IL'},
      {'city': 'Mascoutah', 'state': 'IL'},
      {'city': 'Lebanon', 'state': 'IL'},
      {'city': 'Breese', 'state': 'IL'},
      {'city': 'Trenton', 'state': 'IL'},
      {'city': 'Nashville', 'state': 'IL'},
      {'city': 'Red Bud', 'state': 'IL'},
      {'city': 'Waterloo', 'state': 'IL'},
      {'city': 'Columbia', 'state': 'IL'},
      {'city': 'Dupo', 'state': 'IL'},
      {'city': 'East St. Louis', 'state': 'IL'},
      {'city': 'Washington', 'state': 'MO'},
      {'city': 'Union', 'state': 'MO'},
    ];

    // Use index to get consistent location for each official
    return illinoisLocations[index % illinoisLocations.length];
  }

  Map<String, String> _getCorrectEdwardsvilleLocation(int index) {
    // CORRECT Illinois cities within 100 miles of Edwardsville, IL
    final edwardsvilleAreaLocations = [
      {'city': 'Edwardsville', 'state': 'IL'}, // 0 miles - the center point
      {'city': 'Alton', 'state': 'IL'}, // ~15 miles
      {'city': 'Collinsville', 'state': 'IL'}, // ~20 miles
      {'city': 'Belleville', 'state': 'IL'}, // ~25 miles
      {'city': 'O\'Fallon', 'state': 'IL'}, // ~30 miles
      {'city': 'Glen Carbon', 'state': 'IL'}, // ~8 miles
      {'city': 'Granite City', 'state': 'IL'}, // ~18 miles
      {'city': 'Wood River', 'state': 'IL'}, // ~12 miles
      {'city': 'Godfrey', 'state': 'IL'}, // ~20 miles
      {'city': 'Bethalto', 'state': 'IL'}, // ~10 miles
      {'city': 'Highland', 'state': 'IL'}, // ~35 miles
      {'city': 'Greenville', 'state': 'IL'}, // ~45 miles
      {'city': 'Vandalia', 'state': 'IL'}, // ~60 miles
      {'city': 'Centralia', 'state': 'IL'}, // ~75 miles
      {'city': 'Effingham', 'state': 'IL'}, // ~85 miles
      {'city': 'Mattoon', 'state': 'IL'}, // ~95 miles
      {'city': 'Charleston', 'state': 'IL'}, // ~90 miles
      {'city': 'Taylorville', 'state': 'IL'}, // ~80 miles
      {'city': 'Pana', 'state': 'IL'}, // ~70 miles
      {'city': 'Hillsboro', 'state': 'IL'}, // ~65 miles
      {'city': 'Litchfield', 'state': 'IL'}, // ~50 miles
      {'city': 'Carlinville', 'state': 'IL'}, // ~40 miles
      {'city': 'Springfield', 'state': 'IL'}, // ~95 miles
      {'city': 'Shelbyville', 'state': 'IL'}, // ~85 miles
      {'city': 'Salem', 'state': 'IL'}, // ~80 miles
      {'city': 'Mount Vernon', 'state': 'IL'}, // ~90 miles
      {'city': 'Chester', 'state': 'IL'}, // ~75 miles
      {'city': 'Red Bud', 'state': 'IL'}, // ~45 miles
      {'city': 'Waterloo', 'state': 'IL'}, // ~40 miles
      {'city': 'Columbia', 'state': 'IL'}, // ~35 miles
    ];

    // Use index to get consistent location for each official
    return edwardsvilleAreaLocations[index % edwardsvilleAreaLocations.length];
  }

  Future<void> _updateOfficialsWithLocations() async {
    setState(() {
      isLoading = true;
      testResult = 'Updating officials with location data...';
    });

    try {
      final db = await DatabaseHelper().database;

      // Get all officials without proper location data
      final officialsNeedingUpdate = await db.rawQuery('''
        SELECT id, name FROM officials 
        WHERE city IS NULL OR city = '' OR city = 'null' OR state IS NULL OR state = '' OR state = 'null'
      ''');

      int updateCount = 0;

      for (int i = 0; i < officialsNeedingUpdate.length; i++) {
        final official = officialsNeedingUpdate[i];
        final location = _getRandomIllinoisLocation(i);

        await db.update(
          'officials',
          {
            'city': location['city'],
            'state': location['state'],
          },
          where: 'id = ?',
          whereArgs: [official['id']],
        );

        updateCount++;
      }

      setState(() {
        testResult = '''✅ OFFICIALS LOCATION UPDATE COMPLETE!

Updated $updateCount officials with location data.

Your officials now have cities/states like:
• Edwardsville, IL
• St. Louis, MO  
• Alton, IL
• Belleville, IL
• Collinsville, IL
... and more Illinois/Missouri locations

Click "View All Officials" to see the updated locations!''';
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        testResult = 'Error updating official locations: $e';
        isLoading = false;
      });
    }
  }

  Future<void> _debugLocationData() async {
    setState(() {
      isLoading = true;
      testResult = 'Debugging location data...';
    });

    try {
      final db = await DatabaseHelper().database;
      final dbVersion = await db.getVersion();

      // Check location data distribution
      final locationStats = await db.rawQuery('''
        SELECT 
          CASE 
            WHEN city IS NULL OR city = '' OR city = 'null' THEN 'Empty/Null'
            ELSE 'Has Location'
          END as location_status,
          COUNT(*) as count
        FROM officials
        GROUP BY location_status
      ''');

      // Sample officials with location data
      final sampleWithLocations = await db.rawQuery('''
        SELECT id, name, city, state, created_at
        FROM officials 
        WHERE city IS NOT NULL AND city != '' AND city != 'null'
        ORDER BY id ASC
        LIMIT 5
      ''');

      // Sample officials without location data
      final sampleWithoutLocations = await db.rawQuery('''
        SELECT id, name, city, state, created_at
        FROM officials 
        WHERE city IS NULL OR city = '' OR city = 'null'
        ORDER BY id ASC
        LIMIT 5
      ''');

      String result = '=== LOCATION DATA DEBUG ===\n\n';
      result += 'Database Version: $dbVersion\n';
      result +=
          'Expected: Version 25 (includes Edwardsville area locations)\n\n';

      result += 'LOCATION STATUS:\n';
      for (final stat in locationStats) {
        result += '• ${stat['location_status']}: ${stat['count']} officials\n';
      }

      if (sampleWithLocations.isNotEmpty) {
        result += '\nSAMPLE OFFICIALS WITH LOCATIONS:\n';
        for (final official in sampleWithLocations) {
          result +=
              '• ${official['name']}: ${official['city']}, ${official['state']}\n';
        }
      }

      if (sampleWithoutLocations.isNotEmpty) {
        result += '\nSAMPLE OFFICIALS WITHOUT LOCATIONS:\n';
        for (final official in sampleWithoutLocations) {
          result +=
              '• ${official['name']}: city="${official['city']}", state="${official['state']}"\n';
        }

        result += '\n🔍 DIAGNOSIS:\n';
        if (dbVersion < 25) {
          result +=
              '❌ Database not fully migrated! Run migration to version 25.\n';
        } else {
          result +=
              '⚠️ Officials created after migration without location data.\n';
          result +=
              'The "Create Test Users" function bypassed location assignment.\n';
        }
      }

      setState(() {
        testResult = result;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        testResult = 'Error debugging location data: $e';
        isLoading = false;
      });
    }
  }

  Future<void> _applyCorrectEdwardsvilleLocations() async {
    setState(() {
      isLoading = true;
      testResult = 'Applying correct Edwardsville-area locations...';
    });

    try {
      final db = await DatabaseHelper().database;

      // Get all officials
      final officials = await db.query('officials');

      // CORRECT Illinois cities within 100 miles of Edwardsville, IL
      // (Edwardsville is in southwestern Illinois, near St. Louis)
      final edwardsvilleAreaLocations = [
        {'city': 'Edwardsville', 'state': 'IL'}, // 0 miles - the center point
        {'city': 'Alton', 'state': 'IL'}, // ~15 miles
        {'city': 'Collinsville', 'state': 'IL'}, // ~20 miles
        {'city': 'Belleville', 'state': 'IL'}, // ~25 miles
        {'city': 'O\'Fallon', 'state': 'IL'}, // ~30 miles
        {'city': 'Glen Carbon', 'state': 'IL'}, // ~8 miles
        {'city': 'Granite City', 'state': 'IL'}, // ~18 miles
        {'city': 'Wood River', 'state': 'IL'}, // ~12 miles
        {'city': 'Godfrey', 'state': 'IL'}, // ~20 miles
        {'city': 'Bethalto', 'state': 'IL'}, // ~10 miles
        {'city': 'Highland', 'state': 'IL'}, // ~35 miles
        {'city': 'Greenville', 'state': 'IL'}, // ~45 miles
        {'city': 'Vandalia', 'state': 'IL'}, // ~60 miles
        {'city': 'Centralia', 'state': 'IL'}, // ~75 miles
        {'city': 'Effingham', 'state': 'IL'}, // ~85 miles
        {'city': 'Mattoon', 'state': 'IL'}, // ~95 miles
        {'city': 'Charleston', 'state': 'IL'}, // ~90 miles
        {'city': 'Taylorville', 'state': 'IL'}, // ~80 miles
        {'city': 'Pana', 'state': 'IL'}, // ~70 miles
        {'city': 'Hillsboro', 'state': 'IL'}, // ~65 miles
        {'city': 'Litchfield', 'state': 'IL'}, // ~50 miles
        {'city': 'Carlinville', 'state': 'IL'}, // ~40 miles
        {'city': 'Springfield', 'state': 'IL'}, // ~95 miles
        {'city': 'Shelbyville', 'state': 'IL'}, // ~85 miles
        {'city': 'Salem', 'state': 'IL'}, // ~80 miles
        {'city': 'Mount Vernon', 'state': 'IL'}, // ~90 miles
        {'city': 'Chester', 'state': 'IL'}, // ~75 miles
        {'city': 'Red Bud', 'state': 'IL'}, // ~45 miles
        {'city': 'Waterloo', 'state': 'IL'}, // ~40 miles
        {'city': 'Columbia', 'state': 'IL'}, // ~35 miles
      ];

      int updateCount = 0;

      // Update all officials with CORRECT Edwardsville-area locations
      for (int i = 0; i < officials.length; i++) {
        final official = officials[i];
        final location =
            edwardsvilleAreaLocations[i % edwardsvilleAreaLocations.length];

        await db.update(
          'officials',
          {
            'city': location['city'],
            'state': location['state'],
          },
          where: 'id = ?',
          whereArgs: [official['id']],
        );

        updateCount++;
      }

      setState(() {
        testResult = '''✅ CORRECT EDWARDSVILLE LOCATIONS APPLIED!

Updated $updateCount officials with proper locations within 100 miles of Edwardsville, IL.

Your officials now have CORRECT locations like:
• Edwardsville, IL (0 miles)
• Alton, IL (~15 miles)
• Collinsville, IL (~20 miles)  
• Belleville, IL (~25 miles)
• Glen Carbon, IL (~8 miles)
• Highland, IL (~35 miles)
• Greenville, IL (~45 miles)
• Litchfield, IL (~50 miles)
... and more within 100 miles

❌ REMOVED incorrect distant locations like:
• Chicago, IL (300+ miles)
• Milwaukee, WI (350+ miles) 
• Madison, WI (300+ miles)

Click "View All Officials" to see the corrected locations!''';
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        testResult = 'Error applying Edwardsville locations: $e';
        isLoading = false;
      });
    }
  }

  Future<void> _fixOfficialProfileData() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Fix Official Profile Data'),
        content: const Text(
            'This will link existing officials with their official_users for proper profile display. This is safe to run multiple times. Continue?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Fix Data'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      isLoading = true;
      testResult = 'Fixing official profile data links...';
    });

    try {
      final db = await DatabaseHelper().database;

      // Find officials that don't have official_user_id set but have matching official_users
      final unlinkedOfficials = await db.rawQuery('''
        SELECT o.id as official_id, o.email, ou.id as official_user_id
        FROM officials o
        JOIN official_users ou ON o.email = ou.email
        WHERE o.official_user_id IS NULL
      ''');

      int fixedCount = 0;

      for (final row in unlinkedOfficials) {
        await db.update(
          'officials',
          {'official_user_id': row['official_user_id']},
          where: 'id = ?',
          whereArgs: [row['official_id']],
        );
        fixedCount++;
      }

      setState(() {
        testResult = '''✅ OFFICIAL PROFILE DATA FIXED!

Fixed $fixedCount official records with missing official_user_id links.

The officials should now display their correct profile information including:
• Name and experience years
• Email, phone, and location  
• Proper verification status
• Max travel distance set to 999 miles by default

Try logging in as an official now - the profile should display correctly!''';
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        testResult = 'Error fixing official profile data: $e';
        isLoading = false;
      });
    }
  }

  Future<void> _forceWriteToDatabase() async {
    setState(() {
      isLoading = true;
      testResult = 'Forcing database write to update file timestamp...';
    });

    try {
      final db = await DatabaseHelper().database;

      // Make a small change to force database file update (using availability_status which exists)
      final currentStatus = await db.rawQuery(
          'SELECT availability_status FROM officials WHERE id = 1 LIMIT 1');
      if (currentStatus.isNotEmpty) {
        // Just update the same value to force file write
        await db.execute(
            'UPDATE officials SET availability_status = ? WHERE id = 1',
            [currentStatus.first['availability_status']]);
      }

      // Close and reopen database to force file sync
      await db.close();
      final freshDb = await DatabaseHelper().database;

      final dbPath = freshDb.path;
      final timestamp = DateTime.now().toString();

      setState(() {
        testResult = '''✅ DATABASE FILE FORCED UPDATE!

Database Path: $dbPath
Timestamp: $timestamp

The database file should now have an updated timestamp.
You can re-download it from Android Studio Device File Explorer.

Check Device File Explorer - the timestamp should be newer now!''';
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        testResult = 'Error forcing database write: $e';
        isLoading = false;
      });
    }
  }

  Future<void> _compareDatabaseContent() async {
    setState(() {
      isLoading = true;
      testResult = 'Analyzing database content...';
    });

    try {
      final db = await DatabaseHelper().database;

      // Get sample officials with exact data the app sees
      final sampleOfficials = await db.rawQuery('''
        SELECT id, name, city, state, created_at
        FROM officials 
        ORDER BY id ASC
        LIMIT 10
      ''');

      // Get location distribution
      final locationStats = await db.rawQuery('''
        SELECT city, state, COUNT(*) as count
        FROM officials 
        WHERE city IS NOT NULL AND city != '' AND city != 'null'
        GROUP BY city, state
        ORDER BY count DESC
        LIMIT 10
      ''');

      // Get total counts
      final totalCount =
          (await db.rawQuery('SELECT COUNT(*) as count FROM officials'))
              .first['count'];

      String result = '''🔍 LIVE DATABASE CONTENT (What App Sees):

TOTAL OFFICIALS: $totalCount

FIRST 10 OFFICIALS:
''';

      for (final official in sampleOfficials) {
        final location = official['city'] != null &&
                official['city'] != '' &&
                official['city'] != 'null'
            ? '${official['city']}, ${official['state']}'
            : 'No location';
        result += '• ${official['name']}: $location\n';
      }

      result += '\nTOP LOCATIONS:\n';
      for (final loc in locationStats) {
        result +=
            '• ${loc['city']}, ${loc['state']}: ${loc['count']} officials\n';
      }

      result += '''

📋 INSTRUCTIONS:
1. Compare this with your SQLite Browser data
2. If they differ, the database file is outdated
3. Note exactly which locations/names are different
4. This shows what's ACTUALLY in the live database

💡 If SQLite Browser shows different data:
- The file you downloaded is from an earlier state
- Try stopping/restarting your app
- Or we need to find why the file isn't updating''';

      setState(() {
        testResult = result;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        testResult = 'Error analyzing database: $e';
        isLoading = false;
      });
    }
  }

  Future<String> _generateSchedulersAndFootballOfficials() async {
    final userRepo = UserRepository();
    final officialCreator = OfficialCreator();
    int schedulerCount = 0;
    int officialCount = 0;

    try {
      // Create 3 Scheduler users (same as existing method)
      final schedulerUsers = [
        User(
          schedulerType: 'athletic_director',
          email: 'ad@test.com',
          passwordHash: _hashPassword('test123'),
          firstName: 'Alex',
          lastName: 'Director',
          phone: '555-0101',
          setupCompleted: true,
          schoolName: 'Edwardsville',
          mascot: 'Tigers',
          schoolAddress: '6161 Center Grove Road, Edwardsville, IL 62025',
        ),
        User(
          schedulerType: 'assigner',
          email: 'assigner@test.com',
          passwordHash: _hashPassword('test123'),
          firstName: 'Jason',
          lastName: 'Unverzagt',
          phone: '555-0102',
          setupCompleted: true,
          leagueName: 'SAOA Football',
          sport: 'Football',
        ),
        User(
          schedulerType: 'coach',
          email: 'coach@test.com',
          passwordHash: _hashPassword('test123'),
          firstName: 'Pat',
          lastName: 'Coach',
          phone: '555-0103',
          setupCompleted: true,
          schoolName: 'East High School',
          mascot: 'Panthers',
          teamName: 'East Panthers Football',
          sport: 'Football',
          grade: 'Varsity',
          gender: 'Boys',
        ),
      ];

      for (var user in schedulerUsers) {
        await userRepo.createUser(user);
        schedulerCount++;
      }

      // Create 123 Football Officials from CSV data
      final csvData =
          '''Level of Certification,Years of Experience,Last Name,First Name,Address,City,ZIP,Cell Phone
Certified,8,Aldridge,Brandon,2627 Columbia Lakes Drive Unit 2D,Columbia,62236,618-719-4373
Registered,3,Angleton,Darrell,800 Alton St,Alton,62002,618-792-9995
Recognized,11,Baird,Robert,1217 W Woodfield Dr,Alton,62002,618-401-4016
Certified,12,Barczewski,Paul,414 E Park Ln.,Nashville,62263,618-314-5349
Certified,36,Belcher,Brian,PO Box 166,Coulterville,62237,618-967-5081
Certified,16,Bicanic,Louis,4 Ridgefield Ct,Maryville,62062,618-973-9484
Registered,26,Bishop,David,P.O. Box 412,Greenfield,62044,217-370-2851
Registered,2,Blacharczyk,Matt,17 Bourdelais Drive,Belleville,62226,618-830-4165
Recognized,8,Blakemore,Michael,PO Box 94,O'Fallon,62269,618-363-4625
Registered,3,Boykin,Theatrice,387 Sweetwater Lane,O'Fallon,62269,314-749-8245
Certified,28,Broadway,James,4502  Broadway Acres Dr.,Glen Carbon,62034,618-781-7110
Registered,2,Brown,Keyshawn,168 Liberty Dr,Belleville,62226,618-509-7375
Recognized,4,Brunstein,Nick,364 Jubaka Dr,Fairview Heights,62208,618-401-5301
Certified,30,Buckley,James,2723 Bryden Ct.,Alton,62002,618-606-2217
Certified,19,Bundy,Ryan,1405 Stonebrooke Drive,Edwardsville,62025,618-210-0257
Certified,41,Bussey,William,12703 Meadowdale Dr,St. Louis,63138,314-406-8685
Certified,8,Carmack,Jay,116 Brackett Street,Swansea,62226,618-541-0012
Certified,8,Carmack,Jeff,112 Westview Drive,Freeburg,62243,618-580-1310
Certified,7,Carpenter,Don,233 Cedar St,Eldred,62027,217-248-4489
Certified,44,Chapman,Ralph,6563 State Rt 127,Pinckneyville,62274,618-923-0733
Registered,13,Clark,James,3056 Indian Medows Lane,Edwardsville,62025,618-558-5095
Certified,6,Clymer,Roger,144 N 1400 E Road,Nokomis,62075,618-409-1868
Registered,3,Colbert,Aiden,920 Hamburg Ln,Millstadt,62260,618-606-1924
Registered,2,Colbert,Craig,22 Rose Ct,Glen Carbon,62034,618-660-5455
Certified,14,Cole,Bobby,119 Fox Creek Road,Belleville,62223,618-974-0035
Recognized,9,Cornell,Curtis,912 Stone Creek Ln,Belleville,62223,314-306-0453
Certified,18,Cowan,Clint,317 North Meadow Lane,Steeleville,62288,618-615-1079
Registered,21,Crain,Daniel,721 N. Main St.,Breese,62230,618-550-8152
Certified,29,Curtis,Raymond,609 Marian Street,Dupo,62239,618-477-0590
Certified,11,Dalman,Patrick,218 Shoreline Dr Unit 3,O'Fallon,62269,618-520-0440
Certified,24,Davis,Chad,Po  Box 133,Maryville,62062,618-799-3496
Registered,8,DeClue,Wayman,440 Miranda Dr.,Dupo,62239,618-980-3368
Registered,3,Dederich,Peter,1001 S. Wood St.,Staunton,62088,309-530-9920
Registered,3,Dintelmann,Paul,112 Lake Forest Dr,Belleville,62220,619-415-3786
Registered,4,Dooley,Chad,607 N Jackson St,Litchfield,62056,217-556-4096
Recognized,5,Dunevant,Keith,405 Adams Drive,Waterloo,62298,618-340-8578
Registered,14,Dunnette,Brian,2720 Stone Valley Drive,Maryville,62062,618-514-9897
Certified,26,Eaves,Michael,2548 Stratford Ln.,Granite City,62040,618-830-5829
Certified,27,Ferguson,Eric,701 Clinton St,Gillespie,62033,217-276-3314
Registered,3,Fox,Malcolm,6 Clinton Hill Dr,Swansea,62226,314-240-6115
Certified,21,George,Louis,106 West Cherry,Hartford,62048,618-789-6553
Registered,2,George,Peyton,203 Arrowhead Dr,Troy,62294,618-960-1421
Certified,30,George,Ricky,203 Arrowhead Dr.,Troy,62294,618-567-6862
Certified,10,Gerlach,Andy,505 Ridge Ave.,Steeleville,62288,618-534-2429
Certified,29,Gray,Jason,3405 Amber Meadows Court,Swansea,62226,618-550-8663
Certified,12,Greenfield,Beaux,204 Wild Cherry Ln.,Swansea,62226,618-540-8911
Certified,12,Greenfield,Derek,9 Josiah Ln.,Millstadt,62260,618-604-6944
Certified,51,Harre,Larry,597 E. Fairview Ln.,Nashville,62263,
Certified,26,Harris,Jeffrey,103 North 41st St.,Belleville,62226,618-979-8209
Certified,21,Harris,Nathan,2551 London Lane,Belleville,62221,618-791-2945
Registered,3,Harshbarger,Andrew,2309 Woodlawn Ave,Granite City,62040,618-910-7492
Recognized,5,Haywood,Kim,218 Locust Dr.,Shiloh,62269,618-960-2627
Certified,7,Hennessey,James,313 Sleeping Indian Dr.,Freeburg,62243,618-623-5759
Registered,2,Henry,Tim,117 Rhinegarten Dr,Hazelwood,63031,618-558-4923
Recognized,9,Heyen,Matthew,1615 N State St,Litchfield,62056,217-313-4421
Certified,32,Hinkamper,Roy,14 Fox Trotter Ct,High Ridge,63049,314-606-8598
Certified,14,Holder,David,805 Charles Court,Steeleville,62288,618-615-1663
Certified,43,Holshouser,Robert,1083 Prestonwood Dr.,Edwardsville,62025,618-407-1824
Registered,4,Holtkamp,Jacob,336 Lincolnshire Blvd,Belleville,62221,618-322-8966
Registered,4,Hudson,Lamont,341 Frey Lane,Fairview Heights,62208,708-724-8642
Certified,22,Hughes,Ramonn,748 North 40th St.,East St. Louis,62205,314-651-2010
Certified,11,Jackson,Brian,1137 Hampshire Lane,Shiloh,62221,618-301-0975
Certified,20,Jenkins,Darren,8825 Wendell Creek Dr.,St. Jacob,62281,618-977-9311
Certified,27,Johnson,Emric,245 Americana Circle,Fairview Heights,62208,618-979-7221
Recognized,18,Kaiser,Joseph,302 Bridle Ridge,Collinsville,62234,618-616-6632
Certified,15,Kamp,Jeffrey,958 Auer Landing Rd,Golden Eagle,62036,618-467-6060
Certified,36,Kampwerth,Daniel,900 Pioneer Ct.,Breese,62230,618-363-0685
Certified,47,Lang,Louis,612 E. Main St.,Coffeen,62017,217-246-2549
Certified,25,Lashmett,Dan,1834 Lakamp Rd,Roodhouse,62082,217-473-2046
Registered,3,Lentz,James,3811 State Route 160,Highland,62249,618-444-1773
Recognized,9,Leonard,Bill,249 SE 200 Ave,Carrollton,62016,618-946-2266
Certified,36,Levan,Scott,72 Heatherway Dr,Wood River,62095,618-444-0256
Certified,29,Lewis,Willie,1100 Summit Ave,East St. Louis,62201,618-407-5733
Recognized,11,Lutz,Michael,1307 Allendale,Chester,62233,618-615-1194
Registered,8,McAnulty,William,1123 Eagle LN,Grafton,62037,618-610-9344
Registered,2,McCracken,Shane,1106 North Idler Lane,Greenville,62246,618-699-9063
Recognized,8,McKay,Geoffery,1516 Gedern Drive,Columbia,62236,314-973-9561
Registered,7,Middleton,Timothy,900 Ottawa Ct,Mascoutah,62258,850-758-7278
Certified,14,Modarelli,Michael,7920 West A Streeet,Belleville,62223,314-322-9359
Registered,3,Morris,Ranesha,5710 Cates Ave,Saint Louis,63112,314-458-4245
Certified,40,Morrisey,James,106 Oakridge Estates Dr.,Glen Carbon,62034,618-444-0232
Certified,24,Mueller,Larry,2745 Otten Rd,Millstadt,62260,618-660-9394
Certified,23,Murray,Johnny,2 Madonna Ct,Belleville,62223,618-235-5196
Certified,10,Nichols,Kevin,224 Centennial St,White Hall,62092,217-248-8745
Certified,16,Ohren,Blake,115 Baneberry Dr.,Highland,62249,618-971-9037
Registered,4,Owens,Jacoy,143 Perrottet Dr,Mascoutah,62258,580-301-2646
Certified,11,Pearce,Allan,303 Quarry Street,Staunton,62088,847-217-0922
Registered,2,Phillips,Arthur,1595 Paddock Dr.,Florissant,63033,402-981-5532
Certified,19,Phillips,Jacob,510 Florence Avenue ,Dupo,62239,618-830-6378
Certified,32,Phillips,Michael,"4539 Little Rock Rd., Apt. K",St. Louis,63128,314-805-8381
Registered,3,Pizzo,Isaac,618 N. Franklin St,Litchfield,62056,217-851-1890
Recognized,5,Powell,John,629 Solomon St.,Chester,62233,815-641-6074
Certified,30,Purcell,Trent,1110 Madison Dr.,Carlyle,62231,618-401-1950
Certified,17,Raney,Michael,50 Cheshire Dr ,Belleville,62223,618-402-5717
Certified,21,Rathert,Charles,3138 Bluff Rd,Edwardsville,62025,314-303-8044
Certified,13,Rathert,Joe,3120 Bluff Road,Edwardsville,62025,555-555-5555
Certified,21,Reif,Timothy,333 9th Street,Carrollton,62016,217-473-9321
Certified,16,Roberts,Nathan,525 N Main St,White Hall,62092,217-473-2906
Registered,14,Roundtree,Shawn,11 Jennifer Dr,Glen Carbon,62034,618-789-2451
Registered,6,Royer,Justin,317 W South St,Mascoutah,62258,618-401-8671
Registered,2,Royer,Riley,317 W South St.,Mascoutah,62258,618-406-4748
Certified,37,Schaaf,Donald,1462 South Lake Drive,Carrollton,62016,618-535-6435
Certified,14,Schipper,Dennis,2424 Persimmon Wood Dr,Belleville,62221,618-772-9909
Recognized,14,Schmitz,Jason,85 Sunfish Dr.,Highland,62249,618-792-2923
Registered,5,Scroggins,Louie,29 Scroggins Lane,Hillsboro,62049,217-556-0403
Certified,15,Seibert,Tracy,9903 Old Lincoln Trail,Fairview Heights,62208,618-531-0029
Certified,27,Sheff,Ronald,363 East Airline Dr.,East Alton,62024,618-610-7117
Recognized,12,Shofner,Alan,1878 Franklin Hill RD,Batchtown,62006,618-535-9590
Certified,20,Silas,Andre,520 Washington St.,Venice,62090,217-341-0597
Registered,10,Smail,Donovan,500 W Fairground Avenue,Hillsboro,62049,217-820-1550
Certified,24,Speciale,Andrew,5B Villa Ct.,Edwardsville,62025,314-587-9902
Certified,20,Stinemetz,Douglas,616 W Bottom Ave.,Columbia,62236,618-719-6173
Recognized,4,Stuller,Nathan,303 Collinsville Road,Troy,62294,618-304-4011
Certified,14,Swank,Shawn,301 W Spruce,Gillespie,62033,217-556-5066
Certified,29,Thomas,Carl,228 Springdale Dr,Belleville,62223,618-781-8225
Certified,31,Tolle,Richard,511 N. Main,Witt,62094,217-556-9441
Certified,21,Trotter,Benjamin,1228 Conrad Ln,O'Fallon,62269,618-779-4372
Certified,26,Unverzagt,Jason,307 N. 39 St,Belleville,62226,
Certified,11,Walters,Chris,1211 Marshal Ct,O'Fallon,62269,217-549-8844
Certified,26,Webster,Vincent,2 Lakeshire Dr.,Fairview Hts.,62208,618-660-7107
Certified,6,Womack,Paul,811 S Polk St.,Millstadt,62260,618-567-7609
Recognized,7,Wood,William,2764 Staunton Road,Troy,62294,618-593-5617
Certified,17,Wooten,Edward,801 Chancellor Dr,Edwardsville,62025,618-560-1502''';

      final officialIds = await officialCreator.createOfficialsFromCsv(csvData);
      officialCount = officialIds.length;
      
      // Also fix any existing officials that might not have competition levels
      final fixedCount = await officialCreator.fixExistingOfficialsCompetitionLevels();

      return '''✅ SUCCESS! Created all users!

SCHEDULERS ($schedulerCount):
• Athletic Director: ad@test.com / test123
• Assigner: assigner@test.com / test123  
• Coach: coach@test.com / test123

FOOTBALL OFFICIALS ($officialCount):
All $officialCount officials created with proper:
• Male names only (validated)
• Locations within 100 miles of Edwardsville, IL
• Email format: firstletter+lastname@test.com
• Football sport certification with Underclass, JV, Varsity levels
• Password: test123
${fixedCount > 0 ? '\n🔧 Also fixed $fixedCount existing officials to have competition levels!' : ''}

Examples:
• baldridge@test.com / test123 (Brandon Aldridge)
• dangleton@test.com / test123 (Darrell Angleton)
• rbaird@test.com / test123 (Robert Baird)
... and ${officialCount - 3} more officials

All ready for testing!''';
    } catch (e) {
      return 'Error creating users: $e';
    }
  }

  Future<String> _generateTestUsers() async {
    final userRepo = UserRepository();
    final db = await DatabaseHelper().database;
    int schedulerCount = 0;
    int officialCount = 0;

    try {
      // Create 3 Scheduler users
      final schedulerUsers = [
        User(
          schedulerType: 'athletic_director',
          email: 'ad@test.com',
          passwordHash: _hashPassword('test123'),
          firstName: 'Alex',
          lastName: 'Director',
          phone: '555-0101',
          setupCompleted: true,
          schoolName: 'Edwardsville',
          mascot: 'Tigers',
          schoolAddress: '6161 Center Grove Road, Edwardsville, IL 62025',
        ),
        User(
          schedulerType: 'assigner',
          email: 'assigner@test.com',
          passwordHash: _hashPassword('test123'),
          firstName: 'Jason',
          lastName: 'Unverzagt',
          phone: '555-0102',
          setupCompleted: true,
          leagueName: 'SAOA Football',
          sport: 'Football',
        ),
        User(
          schedulerType: 'coach',
          email: 'coach@test.com',
          passwordHash: _hashPassword('test123'),
          firstName: 'Pat',
          lastName: 'Coach',
          phone: '555-0103',
          setupCompleted: true,
          schoolName: 'East High School',
          mascot: 'Panthers',
          teamName: 'East Panthers Football',
          sport: 'Football',
          grade: 'Varsity',
          gender: 'Boys',
        ),
      ];

      for (var user in schedulerUsers) {
        await userRepo.createUser(user);
        schedulerCount++;
      }

      // No need for SharedPreferences setup - using database setupCompleted field

      // Create exactly 100 Official users - ALL MEN'S NAMES
      final officialNames = [
        // First 10 officials (for Quick Access buttons)
        ['David', 'Davis'], ['David', 'Miller'], ['Mike', 'Williams'],
        ['John', 'Smith'],
        ['Robert', 'Jones'], ['James', 'Brown'], ['Chris', 'Johnson'],
        ['William', 'Garcia'],
        ['Richard', 'Rodriguez'], ['Joseph', 'Wilson'],
        // Additional 90 officials
        ['Thomas', 'Anderson'], ['Charles', 'Thompson'],
        ['Christopher', 'Martinez'], ['Daniel', 'Taylor'],
        ['Matthew', 'Moore'], ['Anthony', 'Jackson'], ['Mark', 'White'],
        ['Donald', 'Harris'],
        ['Steven', 'Clark'], ['Paul', 'Lewis'], ['Andrew', 'Walker'],
        ['Joshua', 'Hall'],
        ['Kenneth', 'Allen'], ['Kevin', 'Young'], ['Brian', 'King'],
        ['George', 'Wright'],
        ['Timothy', 'Lopez'], ['Ronald', 'Hill'], ['Jason', 'Scott'],
        ['Edward', 'Green'],
        ['Jeffrey', 'Adams'], ['Ryan', 'Baker'], ['Jacob', 'Gonzalez'],
        ['Gary', 'Nelson'],
        ['Nicholas', 'Carter'], ['Eric', 'Mitchell'], ['Jonathan', 'Perez'],
        ['Stephen', 'Roberts'],
        ['Larry', 'Turner'], ['Justin', 'Phillips'], ['Scott', 'Campbell'],
        ['Brandon', 'Parker'],
        ['Benjamin', 'Evans'], ['Samuel', 'Edwards'], ['Gregory', 'Collins'],
        ['Frank', 'Stewart'],
        ['Raymond', 'Sanchez'], ['Alexander', 'Morris'], ['Patrick', 'Rogers'],
        ['Jack', 'Reed'],
        ['Dennis', 'Cook'], ['Jerry', 'Morgan'], ['Tyler', 'Bell'],
        ['Aaron', 'Murphy'],
        ['Jose', 'Bailey'], ['Henry', 'Rivera'], ['Adam', 'Richardson'],
        ['Douglas', 'Cooper'],
        ['Nathan', 'Cox'], ['Peter', 'Howard'], ['Zachary', 'Ward'],
        ['Kyle', 'Torres'],
        ['Walter', 'Peterson'], ['Harold', 'Gray'], ['Jeremy', 'Ramirez'],
        ['Carl', 'James'],
        ['Arthur', 'Watson'], ['Lawrence', 'Brooks'], ['Sean', 'Kelly'],
        ['Christian', 'Sanders'],
        ['Albert', 'Price'], ['Wayne', 'Bennett'], ['Ralph', 'Wood'],
        ['Roy', 'Barnes'],
        ['Eugene', 'Ross'], ['Louis', 'Henderson'], ['Philip', 'Coleman'],
        ['Bobby', 'Jenkins'],
        ['Johnny', 'Perry'], ['Mason', 'Powell'], ['Wayne', 'Long'],
        ['Ralph', 'Patterson'],
        ['Mason', 'Hughes'], ['Eugene', 'Flores'], ['Louis', 'Washington'],
        ['Philip', 'Butler'],
        ['Bobby', 'Simmons'], ['Johnny', 'Foster'], ['Willie', 'Gonzales'],
        ['Wayne', 'Bryant'],
        ['Ralph', 'Alexander'], ['Mason', 'Russell'], ['Eugene', 'Griffin'],
        ['Louis', 'Diaz'],
        ['Philip', 'Hayes'], ['Bobby', 'Myers'], ['Johnny', 'Ford'],
        ['Willie', 'Hamilton'],
        ['Wayne', 'Graham'], ['Ralph', 'Sullivan']
      ];

      for (int i = 0; i < officialNames.length; i++) {
        final official = OfficialUser(
          email: 'official${(i + 1).toString().padLeft(3, '0')}@test.com',
          passwordHash: _hashPassword('test123'),
          firstName: officialNames[i][0],
          lastName: officialNames[i][1],
          phone: '555-02${i.toString().padLeft(2, '0')}',
          profileVerified: true,
          emailVerified: true,
          phoneVerified: true,
          status: 'active',
        );

        final officialUserId =
            await db.insert('official_users', official.toMap());
        officialCount++;

        // Get a location within 100 miles of Edwardsville, IL (use correct locations)
        final location = _getCorrectEdwardsvilleLocation(i);

        // Create Official profile record
        final officialProfileData = {
          'name': '${officialNames[i][0]} ${officialNames[i][1]}',
          'official_user_id': officialUserId,
          'email': 'official${(i + 1).toString().padLeft(3, '0')}@test.com',
          'phone': '555-02${i.toString().padLeft(2, '0')}',
          'city': location['city'],
          'state': location['state'],
          'availability_status': 'available',
        };

        final officialId = await db.insert('officials', officialProfileData);

        // Add sport certifications based on predefined assignments
        await _createOfficialSportsCertifications(db, officialId, i + 1);
      }

      return '''Test users created successfully!

SCHEDULERS ($schedulerCount):
• Athletic Director: ad@test.com / test123
• Assigner: assigner@test.com / test123  
• Coach: coach@test.com / test123

OFFICIALS ($officialCount):
Total $officialCount officials created with emails:
• official1@test.com through official$officialCount@test.com

Sample officials:
• official1@test.com / test123 (John Smith)
• official2@test.com / test123 (Sarah Johnson)
• official3@test.com / test123 (Mike Williams)
... and 97 more officials

All officials have various sport combinations from:
Football, Basketball, Baseball, Softball, Volleyball

All users have password: test123''';
    } catch (e) {
      return 'Error creating test users: $e';
    }
  }

  Future<void> _createOfficialSportsCertifications(
      Database db, int officialId, int officialNumber) async {
    // Sport IDs: Football=1, Basketball=2, Baseball=3, Softball=4, Volleyball=6
    // Define sport combinations and attributes for each of the 100 officials

    // For officials 1-10, use the detailed predefined data
    if (officialNumber <= 10) {
      final officialSportsData = [
        // Official 1: John Smith - Basketball & Baseball specialist, some Football
        [
          {
            'sport_id': 2,
            'certification_level': 'IHSA Certified',
            'years_experience': 8,
            'competition_levels': 'JV,Varsity',
            'is_primary': true
          },
          {
            'sport_id': 3,
            'certification_level': 'IHSA Recognized',
            'years_experience': 5,
            'competition_levels': 'Middle School,Underclass,JV',
            'is_primary': false
          },
          {
            'sport_id': 1,
            'certification_level': 'IHSA Registered',
            'years_experience': 3,
            'competition_levels': 'JV',
            'is_primary': false
          },
        ],
        // Official 2: Sarah Johnson - All four sports, volleyball primary
        [
          {
            'sport_id': 6,
            'certification_level': 'IHSA Certified',
            'years_experience': 10,
            'competition_levels': 'Underclass,JV,Varsity,College',
            'is_primary': true
          },
          {
            'sport_id': 2,
            'certification_level': 'IHSA Recognized',
            'years_experience': 6,
            'competition_levels': 'Middle School,Underclass,JV',
            'is_primary': false
          },
          {
            'sport_id': 3,
            'certification_level': 'IHSA Registered',
            'years_experience': 3,
            'competition_levels': 'Middle School,Underclass',
            'is_primary': false
          },
          {
            'sport_id': 1,
            'certification_level': 'IHSA Recognized',
            'years_experience': 7,
            'competition_levels': 'JV,Varsity',
            'is_primary': false
          },
        ],
        // Official 3: Mike Williams - Baseball specialist with Football experience
        [
          {
            'sport_id': 3,
            'certification_level': 'IHSA Certified',
            'years_experience': 12,
            'competition_levels': 'JV,Varsity,College',
            'is_primary': true
          },
          {
            'sport_id': 1,
            'certification_level': 'IHSA Certified',
            'years_experience': 10,
            'competition_levels': 'Varsity,College',
            'is_primary': false
          },
        ],
        // Official 4: Lisa Brown - Basketball & Volleyball
        [
          {
            'sport_id': 2,
            'certification_level': 'IHSA Recognized',
            'years_experience': 7,
            'competition_levels': 'Middle School,Underclass,JV,Varsity',
            'is_primary': true
          },
          {
            'sport_id': 6,
            'certification_level': 'IHSA Registered',
            'years_experience': 4,
            'competition_levels': 'Middle School,Underclass,JV',
            'is_primary': false
          },
        ],
        // Official 5: David Jones - Basketball specialist with Football background
        [
          {
            'sport_id': 2,
            'certification_level': 'IHSA Certified',
            'years_experience': 15,
            'competition_levels': 'JV,Varsity,College,Adult',
            'is_primary': true
          },
          {
            'sport_id': 1,
            'certification_level': 'IHSA Recognized',
            'years_experience': 12,
            'competition_levels': 'Varsity,College',
            'is_primary': false
          },
        ],
        // Official 6: Amy Miller - Multi-sport including Football
        [
          {
            'sport_id': 2,
            'certification_level': 'IHSA Certified',
            'years_experience': 9,
            'competition_levels': 'Underclass,JV,Varsity',
            'is_primary': true
          },
          {
            'sport_id': 3,
            'certification_level': 'IHSA Recognized',
            'years_experience': 6,
            'competition_levels': 'Middle School,Underclass,JV,Varsity',
            'is_primary': false
          },
          {
            'sport_id': 6,
            'certification_level': 'IHSA Recognized',
            'years_experience': 7,
            'competition_levels': 'JV,Varsity',
            'is_primary': false
          },
          {
            'sport_id': 1,
            'certification_level': 'IHSA Registered',
            'years_experience': 4,
            'competition_levels': 'Underclass,JV',
            'is_primary': false
          },
        ],
        // Official 7: Chris Davis - Volleyball & Baseball
        [
          {
            'sport_id': 6,
            'certification_level': 'IHSA Recognized',
            'years_experience': 8,
            'competition_levels': 'Middle School,Underclass,JV,Varsity',
            'is_primary': true
          },
          {
            'sport_id': 3,
            'certification_level': 'IHSA Registered',
            'years_experience': 4,
            'competition_levels': 'Middle School,Underclass',
            'is_primary': false
          },
        ],
        // Official 8: Jennifer Garcia - Basketball, Volleyball & Football
        [
          {
            'sport_id': 2,
            'certification_level': 'IHSA Registered',
            'years_experience': 5,
            'competition_levels': 'Grade School,Middle School,Underclass',
            'is_primary': true
          },
          {
            'sport_id': 6,
            'certification_level': 'IHSA Certified',
            'years_experience': 11,
            'competition_levels': 'JV,Varsity,College',
            'is_primary': false
          },
          {
            'sport_id': 1,
            'certification_level': 'IHSA Registered',
            'years_experience': 6,
            'competition_levels': 'Middle School,Underclass,JV',
            'is_primary': false
          },
        ],
        // Official 9: Robert Rodriguez - Baseball, Basketball & Football veteran
        [
          {
            'sport_id': 3,
            'certification_level': 'IHSA Certified',
            'years_experience': 13,
            'competition_levels': 'Varsity,College,Adult',
            'is_primary': true
          },
          {
            'sport_id': 2,
            'certification_level': 'IHSA Recognized',
            'years_experience': 8,
            'competition_levels': 'JV,Varsity',
            'is_primary': false
          },
          {
            'sport_id': 1,
            'certification_level': 'IHSA Certified',
            'years_experience': 15,
            'competition_levels': 'Varsity,College,Adult',
            'is_primary': false
          },
        ],
        // Official 10: Michelle Wilson - Volleyball specialist
        [
          {
            'sport_id': 6,
            'certification_level': 'IHSA Recognized',
            'years_experience': 6,
            'competition_levels': 'Grade School,Middle School,Underclass,JV',
            'is_primary': true
          },
        ],
      ];

      final sportsForOfficial = officialSportsData[officialNumber - 1];
      for (final sportData in sportsForOfficial) {
        await db.insert('official_sports', {
          'official_id': officialId,
          'sport_id': sportData['sport_id'],
          'certification_level': sportData['certification_level'],
          'years_experience': sportData['years_experience'],
          'competition_levels': sportData['competition_levels'],
          'is_primary': sportData['is_primary'] == true ? 1 : 0,
        });
      }
    } else {
      // For officials 11-100, generate randomized sport combinations
      final sportIds = [
        1,
        2,
        3,
        4,
        6
      ]; // Football, Basketball, Baseball, Softball, Volleyball
      final certificationLevels = [
        'IHSA Registered',
        'IHSA Recognized',
        'IHSA Certified'
      ];
      final competitionLevelOptions = [
        ['Grade School', 'Middle School'],
        ['Middle School', 'Underclass', 'JV'],
        ['Underclass', 'JV', 'Varsity'],
        ['JV', 'Varsity'],
        ['Varsity', 'College'],
        ['College', 'Adult'],
        ['Grade School', 'Middle School', 'Underclass'],
        ['Middle School', 'Underclass', 'JV', 'Varsity'],
        ['JV', 'Varsity', 'College'],
      ];

      // Use officialNumber as seed for consistent randomization
      final random =
          officialNumber * 17 + 42; // Simple deterministic "random" seed

      // Each official gets 1-3 sports
      final numSports = (random % 3) + 1;
      final selectedSports = <int>{};

      // Select sports
      for (int i = 0; i < numSports; i++) {
        int sportIndex = (random + i * 7) % sportIds.length;
        selectedSports.add(sportIds[sportIndex]);
      }

      bool isFirst = true;
      for (int sportId in selectedSports) {
        final certIndex = (random + sportId) % certificationLevels.length;
        final levelIndex =
            (random + sportId * 3) % competitionLevelOptions.length;
        final experience = 2 + ((random + sportId * 5) % 18); // 2-20 years

        await db.insert('official_sports', {
          'official_id': officialId,
          'sport_id': sportId,
          'certification_level': certificationLevels[certIndex],
          'years_experience': experience,
          'competition_levels': competitionLevelOptions[levelIndex].join(','),
          'is_primary': isFirst ? 1 : 0,
        });
        isFirst = false;
      }
    }
  }

  Future<void> _debugADProfiles() async {
    setState(() {
      isLoading = true;
      testResult = 'Loading Athletic Director profile data...';
    });

    try {
      final db = await DatabaseHelper().database;

      // First, check ALL users to see what scheduler_type values exist
      final allUsers = await db.rawQuery('''
        SELECT id, first_name, last_name, email, scheduler_type,
               school_name, mascot, school_address,
               setup_completed, created_at
        FROM users 
        ORDER BY created_at DESC
        LIMIT 10
      ''');

      // Get all Athletic Director users (both possible formats)
      final adUsers = await db.rawQuery('''
        SELECT id, first_name, last_name, email, 
               school_name, mascot, school_address,
               setup_completed, created_at
        FROM users 
        WHERE scheduler_type = 'Athletic Director' OR scheduler_type = 'athletic_director'
        ORDER BY created_at DESC
      ''');

      // Get games created by Athletic Directors
      final adGames = await db.rawQuery('''
        SELECT g.id, g.opponent, g.home_team, g.status,
               u.first_name, u.last_name, u.school_name, u.mascot,
               -- Test our CASE statement
               CASE 
                 WHEN g.home_team IS NOT NULL AND g.home_team != '' AND g.home_team != 'Home Team' 
                 THEN g.home_team
                 WHEN (u.scheduler_type = 'Athletic Director' OR u.scheduler_type = 'athletic_director') AND u.school_name IS NOT NULL AND u.mascot IS NOT NULL
                 THEN u.school_name || ' ' || u.mascot
                 ELSE COALESCE(g.home_team, 'Home Team')
               END as calculated_home_team
        FROM games g
        JOIN users u ON g.user_id = u.id  
        WHERE (u.scheduler_type = 'Athletic Director' OR u.scheduler_type = 'athletic_director')
        ORDER BY g.created_at DESC
        LIMIT 10
      ''');

      String result = '=== ATHLETIC DIRECTOR PROFILE DEBUG ===\n\n';
      
      result += '👥 ALL USERS (${allUsers.length}):\n';
      if (allUsers.isEmpty) {
        result += '  ❌ No users found in database\n\n';
      } else {
        for (int i = 0; i < allUsers.length; i++) {
          final user = allUsers[i];
          result += '  ${i + 1}. ${user['first_name']} ${user['last_name']} (ID: ${user['id']})\n';
          result += '     Email: ${user['email']}\n';
          result += '     Type: "${user['scheduler_type']}"\n';
          result += '     School: "${user['school_name']}", Mascot: "${user['mascot']}"\n';
          result += '     Setup: ${user['setup_completed'] == 1 ? 'Yes' : 'No'}\n\n';
        }
      }
      
      result += '📋 ATHLETIC DIRECTORS (${adUsers.length}):\n';
      if (adUsers.isEmpty) {
        result += '  ❌ No Athletic Directors found\n\n';
      } else {
        for (int i = 0; i < adUsers.length; i++) {
          final ad = adUsers[i];
          result += '  ${i + 1}. ${ad['first_name']} ${ad['last_name']} (ID: ${ad['id']})\n';
          result += '     Email: ${ad['email']}\n';
          result += '     School Name: "${ad['school_name']}"\n';
          result += '     Mascot: "${ad['mascot']}"\n';
          result += '     Setup Completed: ${ad['setup_completed'] == 1 ? 'Yes' : 'No'}\n';
          
          if (ad['school_name'] != null && ad['mascot'] != null) {
            result += '     Expected Home Team: "${ad['school_name']} ${ad['mascot']}"\n';
          } else {
            result += '     ⚠️  Missing school name or mascot!\n';
          }
          result += '\n';
        }
      }

      result += '🏈 AD GAMES (${adGames.length}):\n';
      if (adGames.isEmpty) {
        result += '  ❌ No games found created by Athletic Directors\n\n';
      } else {
        for (final game in adGames) {
          result += '  Game ${game['id']} (${game['status']}):\n';
          result += '    Opponent: "${game['opponent']}"\n';
          result += '    Stored Home Team: "${game['home_team']}"\n';
          result += '    Calculated Home Team: "${game['calculated_home_team']}"\n';
          result += '    Display: "${game['opponent']}" @ "${game['calculated_home_team']}"\n';
          result += '    Created by: ${game['first_name']} ${game['last_name']}\n';
          
          if (game['calculated_home_team'] == null || game['calculated_home_team'].toString().trim().isEmpty) {
            result += '    ❌ ISSUE: Calculated home team is empty!\n';
          } else if (game['calculated_home_team'] == 'Home Team') {
            result += '    ⚠️  WARNING: Using fallback home team\n';
          }
          result += '\n';
        }
      }

      setState(() {
        testResult = result;
        isLoading = false;
      });

    } catch (e) {
      setState(() {
        testResult = 'Error debugging AD profiles: $e';
        isLoading = false;
      });
    }
  }

  Future<void> _debugAvailableGamesQuery() async {
    setState(() {
      isLoading = true;
      testResult = 'Testing Available Games Query...';
    });

    try {
      final db = await DatabaseHelper().database;

      // Get a crew chief to test with
      final crewChief = await db.rawQuery('''
        SELECT o.id, o.name
        FROM officials o
        JOIN crews c ON o.id = c.crew_chief_id
        WHERE c.is_active = 1
        LIMIT 1
      ''');

      if (crewChief.isEmpty) {
        setState(() {
          testResult = 'No crew chiefs found to test with. Please create crews first.';
          isLoading = false;
        });
        return;
      }

      final officialId = crewChief.first['id'] as int;
      final officialName = crewChief.first['name'] as String;

      // Test the exact available games query from the repository
      final availableGames = await db.rawQuery('''
        SELECT DISTINCT 
          g.id, g.sport_id, g.location_id, g.user_id,
          g.date, g.time, g.is_away, g.level_of_competition,
          g.gender, g.officials_required, g.officials_hired,
          g.game_fee, g.opponent, g.hire_automatically,
          g.method, g.status, g.created_at, g.updated_at,
          l.name as location_name, l.address as location_address,
          s.name as sport_name,
          sch.home_team_name as schedule_home_team_name,
          u.first_name, u.last_name,
          -- Dynamic home team: use stored home_team if not empty, otherwise build from AD profile
          CASE 
            WHEN g.home_team IS NOT NULL AND g.home_team != '' AND g.home_team != 'Home Team' 
            THEN g.home_team
            WHEN (u.scheduler_type = 'Athletic Director' OR u.scheduler_type = 'athletic_director') AND u.school_name IS NOT NULL AND u.mascot IS NOT NULL
            THEN u.school_name || ' ' || u.mascot
            ELSE COALESCE(g.home_team, 'Home Team')
          END as home_team,
          'available' as assignment_status
        FROM games g
        LEFT JOIN locations l ON g.location_id = l.id
        LEFT JOIN sports s ON g.sport_id = s.id
        LEFT JOIN schedules sch ON g.schedule_id = sch.id
        LEFT JOIN users u ON g.user_id = u.id
        WHERE g.id NOT IN (
          SELECT ga.game_id 
          FROM game_assignments ga 
          WHERE ga.official_id = ?
        )
        AND g.id NOT IN (
          SELECT gd.game_id 
          FROM game_dismissals gd 
          WHERE gd.official_id = ?
        )
        AND g.id NOT IN (
          -- Exclude hire_crew games where the official's crew already has an assignment
          SELECT ca.game_id 
          FROM crew_assignments ca
          JOIN crews c ON ca.crew_id = c.id
          WHERE c.crew_chief_id = ? AND g.method = 'hire_crew'
        )
        AND g.status = 'Published'
        AND g.date >= date('now')
        AND g.officials_required > g.officials_hired
        ORDER BY g.date ASC, g.time ASC
      ''', [officialId, officialId, officialId]);

      String result = '=== AVAILABLE GAMES QUERY DEBUG ===\n\n';
      result += 'Testing with crew chief: $officialName (ID: $officialId)\n\n';
      
      result += '🎮 AVAILABLE GAMES (${availableGames.length}):\n';
      if (availableGames.isEmpty) {
        result += '  ❌ No available games found\n\n';
      } else {
        for (final game in availableGames) {
          result += '  Game ${game['id']}:\n';
          result += '    Raw opponent: "${game['opponent']}"\n';
          result += '    Raw home_team: "${game['home_team']}"\n';
          result += '    Raw schedule_home_team_name: "${game['schedule_home_team_name']}"\n';
          result += '    Creator: ${game['first_name']} ${game['last_name']}\n';
          result += '    Method: ${game['method']}\n';
          result += '    Status: ${game['status']}\n';
          
          // Test the _formatGameTitle logic here
          final opponent = game['opponent'] as String?;
          final homeTeam = (game['schedule_home_team_name'] ?? game['home_team'] ?? 'Home Team') as String;
          
          result += '    Calculated homeTeam (using display logic): "$homeTeam"\n';
          
          if (opponent != null && homeTeam.trim().isNotEmpty && homeTeam != 'Home Team') {
            final displayResult = '$opponent @ $homeTeam';
            result += '    Final display: "$displayResult"\n';
          } else if (opponent != null) {
            result += '    Final display: "$opponent" (opponent only)\n';
          } else {
            result += '    Final display: "TBD"\n';
          }
          
          // Check for issues
          if (homeTeam.trim().isEmpty) {
            result += '    ❌ ISSUE: Home team is empty!\n';
          } else if (homeTeam == 'Home Team') {
            result += '    ⚠️  WARNING: Using fallback home team\n';
          }
          result += '\n';
        }
      }

      // Also test with a different query to see raw game data
      result += '📋 RAW GAME DATA COMPARISON:\n';
      final rawGames = await db.rawQuery('''
        SELECT g.id, g.opponent, g.home_team, g.method, g.status,
               u.first_name, u.last_name, u.scheduler_type, u.school_name, u.mascot
        FROM games g
        JOIN users u ON g.user_id = u.id
        WHERE g.status = 'Published'
        ORDER BY g.created_at DESC
        LIMIT 3
      ''');

      for (final game in rawGames) {
        result += '  Game ${game['id']} (${game['method']}):\n';
        result += '    opponent: "${game['opponent']}"\n';
        result += '    stored home_team: "${game['home_team']}"\n';
        result += '    creator type: "${game['scheduler_type']}"\n';
        result += '    school_name: "${game['school_name']}"\n';
        result += '    mascot: "${game['mascot']}"\n';
        result += '    expected home_team: "${game['school_name']} ${game['mascot']}"\n\n';
      }

      setState(() {
        testResult = result;
        isLoading = false;
      });

    } catch (e) {
      setState(() {
        testResult = 'Error testing available games query: $e';
        isLoading = false;
      });
    }
  }

  Future<void> _testCaseStatement() async {
    setState(() {
      isLoading = true;
      testResult = 'Testing SQL CASE statement...';
    });

    try {
      final db = await DatabaseHelper().database;

      // Test each part of our CASE statement separately
      final testResults = await db.rawQuery('''
        SELECT 
          g.id,
          g.opponent,
          g.home_team as stored_home_team,
          u.scheduler_type,
          u.school_name,
          u.mascot,
          -- Test each condition separately
          (g.home_team IS NOT NULL) as condition1_not_null,
          (g.home_team != '') as condition2_not_empty,
          (g.home_team != 'Home Team') as condition3_not_fallback,
          (u.scheduler_type = 'Athletic Director') as condition4_ad_exact,
          (u.scheduler_type = 'athletic_director') as condition5_ad_snake,
          (u.school_name IS NOT NULL) as condition6_school_not_null,
          (u.mascot IS NOT NULL) as condition7_mascot_not_null,
          -- Our full CASE statement
          CASE 
            WHEN g.home_team IS NOT NULL AND g.home_team != '' AND g.home_team != 'Home Team' 
            THEN g.home_team
            WHEN (u.scheduler_type = 'Athletic Director' OR u.scheduler_type = 'athletic_director') AND u.school_name IS NOT NULL AND u.mascot IS NOT NULL
            THEN u.school_name || ' ' || u.mascot
            ELSE COALESCE(g.home_team, 'Home Team')
          END as case_result
        FROM games g
        JOIN users u ON g.user_id = u.id
        WHERE g.status = 'Published'
        ORDER BY g.created_at DESC
        LIMIT 3
      ''');

      String result = '=== SQL CASE STATEMENT DEBUG ===\n\n';
      
      for (final game in testResults) {
        result += 'Game ${game['id']} - "${game['opponent']}":\n';
        result += '  stored_home_team: "${game['stored_home_team']}"\n';
        result += '  scheduler_type: "${game['scheduler_type']}"\n';
        result += '  school_name: "${game['school_name']}"\n';
        result += '  mascot: "${game['mascot']}"\n';
        result += '  \n';
        result += '  CASE Conditions:\n';
        result += '    1. home_team NOT NULL: ${game['condition1_not_null'] == 1}\n';
        result += '    2. home_team != "": ${game['condition2_not_empty'] == 1}\n';
        result += '    3. home_team != "Home Team": ${game['condition3_not_fallback'] == 1}\n';
        result += '    4. scheduler_type = "Athletic Director": ${game['condition4_ad_exact'] == 1}\n';
        result += '    5. scheduler_type = "athletic_director": ${game['condition5_ad_snake'] == 1}\n';
        result += '    6. school_name NOT NULL: ${game['condition6_school_not_null'] == 1}\n';
        result += '    7. mascot NOT NULL: ${game['condition7_mascot_not_null'] == 1}\n';
        result += '  \n';
        result += '  CASE RESULT: "${game['case_result']}"\n';
        result += '  EXPECTED: "${game['school_name']} ${game['mascot']}"\n';
        result += '  \n';
        
        // Analyze why CASE failed
        if (game['case_result'] == game['stored_home_team'] && 
            (game['stored_home_team'] == null || game['stored_home_team'] == '' || game['stored_home_team'] == 'Home Team')) {
          result += '  ❌ CASE took first branch (stored home_team) but it\'s empty!\n';
        } else if (game['case_result'] != '${game['school_name']} ${game['mascot']}' && 
                   game['condition4_ad_exact'] == 0 && game['condition5_ad_snake'] == 0) {
          result += '  ❌ CASE failed because scheduler_type doesn\'t match!\n';
        } else if (game['case_result'] != '${game['school_name']} ${game['mascot']}' && 
                   (game['condition6_school_not_null'] == 0 || game['condition7_mascot_not_null'] == 0)) {
          result += '  ❌ CASE failed because school_name or mascot is NULL!\n';
        }
        
        result += '  \n';
      }

      setState(() {
        testResult = result;
        isLoading = false;
      });

    } catch (e) {
      setState(() {
        testResult = 'Error testing CASE statement: $e';
        isLoading = false;
      });
    }
  }

  Future<void> _testGameFiltering() async {
    setState(() {
      isLoading = true;
      testResult = 'Testing game filtering logic...';
    });

    try {
      final db = await DatabaseHelper().database;

      // Get a crew chief to test with
      final crewChief = await db.rawQuery('''
        SELECT o.id, o.name
        FROM officials o
        JOIN crews c ON o.id = c.crew_chief_id
        WHERE c.is_active = 1
        LIMIT 1
      ''');

      if (crewChief.isEmpty) {
        setState(() {
          testResult = 'No crew chiefs found to test with.';
          isLoading = false;
        });
        return;
      }

      final officialId = crewChief.first['id'] as int;
      final officialName = crewChief.first['name'] as String;

      // Test each filter condition separately for game ID 4
      final gameId = 4;

      final gameAssignments = await db.rawQuery('''
        SELECT ga.game_id, ga.official_id, ga.status
        FROM game_assignments ga 
        WHERE ga.game_id = ? AND ga.official_id = ?
      ''', [gameId, officialId]);

      final gameDismissals = await db.rawQuery('''
        SELECT gd.game_id, gd.official_id, gd.reason
        FROM game_dismissals gd 
        WHERE gd.game_id = ? AND gd.official_id = ?
      ''', [gameId, officialId]);

      final crewAssignments = await db.rawQuery('''
        SELECT ca.game_id, ca.crew_id, ca.status, c.crew_chief_id, g.method
        FROM crew_assignments ca
        JOIN crews c ON ca.crew_id = c.id
        JOIN games g ON ca.game_id = g.id
        WHERE ca.game_id = ? AND c.crew_chief_id = ? AND g.method = 'hire_crew'
      ''', [gameId, officialId]);

      // Test basic game info
      final gameInfo = await db.rawQuery('''
        SELECT g.id, g.opponent, g.home_team, g.method, g.status,
               g.officials_required, g.officials_hired, g.date,
               u.scheduler_type, u.school_name, u.mascot
        FROM games g
        JOIN users u ON g.user_id = u.id
        WHERE g.id = ?
      ''', [gameId]);

      String result = '=== GAME FILTERING DEBUG ===\n\n';
      result += 'Testing with crew chief: $officialName (ID: $officialId)\n';
      result += 'Testing game ID: $gameId\n\n';

      if (gameInfo.isNotEmpty) {
        final game = gameInfo.first;
        result += '📋 GAME INFO:\n';
        result += '  opponent: "${game['opponent']}"\n';
        result += '  home_team: "${game['home_team']}"\n';
        result += '  method: ${game['method']}\n';
        result += '  status: ${game['status']}\n';
        result += '  officials_required: ${game['officials_required']}\n';
        result += '  officials_hired: ${game['officials_hired']}\n';
        result += '  date: ${game['date']}\n';
        result += '  creator: ${game['scheduler_type']}\n\n';

        result += '🚫 FILTER RESULTS:\n';
        
        result += '  1. Game Assignments (${gameAssignments.length}):\n';
        if (gameAssignments.isEmpty) {
          result += '    ✅ No assignments - game should be visible\n';
        } else {
          result += '    ❌ Has assignments - game will be filtered out:\n';
          for (final assignment in gameAssignments) {
            result += '      - Official ${assignment['official_id']}: ${assignment['status']}\n';
          }
        }

        result += '  2. Game Dismissals (${gameDismissals.length}):\n';
        if (gameDismissals.isEmpty) {
          result += '    ✅ No dismissals - game should be visible\n';
        } else {
          result += '    ❌ Has dismissals - game will be filtered out:\n';
          for (final dismissal in gameDismissals) {
            result += '      - Official ${dismissal['official_id']}: ${dismissal['reason']}\n';
          }
        }

        result += '  3. Crew Assignments (${crewAssignments.length}):\n';
        if (crewAssignments.isEmpty) {
          result += '    ✅ No crew assignments - game should be visible\n';
        } else {
          result += '    ❌ Has crew assignments - game will be filtered out:\n';
          for (final assignment in crewAssignments) {
            result += '      - Crew ${assignment['crew_id']}: ${assignment['status']}\n';
          }
        }

        // Check other conditions
        result += '  4. Other Conditions:\n';
        result += '    Status = "Published": ${game['status'] == 'Published' ? '✅' : '❌'}\n';
        
        final gameDate = game['date'] as String?;
        final officialsRequired = (game['officials_required'] as int?) ?? 0;
        final officialsHired = (game['officials_hired'] as int?) ?? 0;
        
        final dateCondition = gameDate != null && DateTime.parse(gameDate).isAfter(DateTime.now().subtract(Duration(days: 1)));
        final officialCondition = officialsRequired > officialsHired;
        
        result += '    Date >= today: ${dateCondition ? '✅' : '❌'}\n';
        result += '    officials_required ($officialsRequired) > officials_hired ($officialsHired): ${officialCondition ? '✅' : '❌'}\n';

        // Final verdict
        final isFiltered = gameAssignments.isNotEmpty || gameDismissals.isNotEmpty || crewAssignments.isNotEmpty;
        final meetsOtherConditions = game['status'] == 'Published' && dateCondition && officialCondition;

        result += '\n🎯 FINAL VERDICT:\n';
        if (isFiltered) {
          result += '  ❌ Game will be FILTERED OUT due to existing assignments/dismissals\n';
        } else if (!meetsOtherConditions) {
          result += '  ❌ Game will be FILTERED OUT due to status/date/hiring conditions\n';
        } else {
          result += '  ✅ Game SHOULD BE VISIBLE in Available Games\n';
          result += '  🚨 If not visible, there\'s a bug in the display logic!\n';
        }
      } else {
        result += '❌ Game ID $gameId not found\n';
      }

      setState(() {
        testResult = result;
        isLoading = false;
      });

    } catch (e) {
      setState(() {
        testResult = 'Error testing game filtering: $e';
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: darkBackground,
      appBar: AppBar(
        backgroundColor: efficialsBlack,
        title: const Text(
          'Database Test',
          style: TextStyle(color: efficialsWhite),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: efficialsWhite),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Database Migration Status',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: efficialsYellow,
                ),
              ),
              const SizedBox(height: 20),
              if (isLoading)
                const Center(
                    child: CircularProgressIndicator(color: efficialsBlue))
              else
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildStatusCard(),
                        const SizedBox(height: 20),
                        _buildSharedPreferencesCard(),
                        const SizedBox(height: 20),
                        _buildActionButtons(),
                        if (testResult.isNotEmpty) ...[
                          const SizedBox(height: 20),
                          _buildTestResultCard(),
                        ],
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: darkSurface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Migration Status',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: primaryTextColor,
            ),
          ),
          const SizedBox(height: 12),
          _buildStatusRow(
            'Migration Completed',
            migrationStatus['migration_completed'] == true,
          ),
          _buildStatusRow(
            'Has User',
            migrationStatus['has_user'] == true,
          ),
        ],
      ),
    );
  }

  Widget _buildSharedPreferencesCard() {
    final spKeys =
        migrationStatus['shared_preferences_keys'] as Map<String, dynamic>? ??
            {};

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: darkSurface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'SharedPreferences Data',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: primaryTextColor,
            ),
          ),
          const SizedBox(height: 12),
          ...spKeys.entries.map((entry) => _buildStatusRow(
                entry.key,
                entry.value == true,
              )),
        ],
      ),
    );
  }

  Widget _buildStatusRow(String label, bool isTrue) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            isTrue ? Icons.check_circle : Icons.cancel,
            color: isTrue ? Colors.green : Colors.red,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(color: primaryTextColor),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _testDatabase,
            style: elevatedButtonStyle(),
            child: const Text('Test Database Functionality'),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _forceMigration,
            style: elevatedButtonStyle(),
            child: const Text('Force Migration'),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => Navigator.pushNamed(context, '/create_officials'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: const Text('👨‍💼 Create Football Officials from CSV'),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => Navigator.pushNamed(context, '/update_addresses'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('🏠 Update Official Addresses'),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _fixDatabaseSchema,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
            child: const Text('Fix Database Schema'),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _createTestUsers,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('Create Test Users'),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _viewAllOfficials,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
            child: const Text('View All Officials'),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _showDatabasePath,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple,
              foregroundColor: Colors.white,
            ),
            child: const Text('Show Database Path'),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _updateOfficialsWithLocations,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('Fix Official Locations'),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _fixOfficialProfileData,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal,
              foregroundColor: Colors.white,
            ),
            child: const Text('🔧 Fix Official Profile Data Links'),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _debugLocationData,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: const Text('Debug Location Data'),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _applyCorrectEdwardsvilleLocations,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Apply Correct Edwardsville Locations'),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _forceWriteToDatabase,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal,
              foregroundColor: Colors.white,
            ),
            child: const Text('Force Database Write (Test)'),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _compareDatabaseContent,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.indigo,
              foregroundColor: Colors.white,
            ),
            child: const Text('Compare: What App Sees vs File'),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _clearTemplatesOnly,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: const Text('Clear Templates Only'),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _debugInterestIssue,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
            child: const Text('Debug Interest Issue'),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _cleanupDuplicateGames,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple,
              foregroundColor: Colors.white,
            ),
            child: const Text('Cleanup Duplicate Games'),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _showRecentGames,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal,
              foregroundColor: Colors.white,
            ),
            child: const Text('Show Recent Games (Debug)'),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _showAllGames,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.indigo,
              foregroundColor: Colors.white,
            ),
            child: const Text('Show All Games (Simple)'),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _removeNullHomeTeamGames,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Remove Games with Null Home Team'),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _viewOfficialSportsDetails,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.cyan,
              foregroundColor: Colors.white,
            ),
            child: const Text('View Officials Sports Details'),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => Navigator.pushNamed(context, '/official_stats'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: const Text('View Official Statistics'),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _updateAssignerToSAOAFootball,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber,
              foregroundColor: Colors.black,
            ),
            child: const Text('Update Assigner to SAOA Football'),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _createSchedulersAndFootballOfficials,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurple,
              foregroundColor: Colors.white,
            ),
            child: const Text(
                '🏈 Create AD + Assigner + Coach + 123 Football Officials'),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _resetDatabase,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Reset Database'),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _debugADProfiles,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurple,
              foregroundColor: Colors.white,
            ),
            child: const Text('🔍 Debug Athletic Director Profiles'),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _debugAvailableGamesQuery,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.indigo,
              foregroundColor: Colors.white,
            ),
            child: const Text('🎯 Debug Available Games Query'),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _testCaseStatement,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('🔬 Test SQL CASE Statement'),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _testGameFiltering,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.pink,
              foregroundColor: Colors.white,
            ),
            child: const Text('🚫 Test Game Filtering Logic'),
          ),
        ),
      ],
    );
  }

  Future<void> _viewOfficialSportsDetails() async {
    setState(() {
      isLoading = true;
      testResult = 'Loading officials sports details...';
    });

    try {
      final db = await DatabaseHelper().database;

      // Get officials with their sports data, ordered by email
      final officials = await db.rawQuery('''
        SELECT 
          o.id,
          o.name,
          o.email,
          o.city,
          o.state,
          s.name as sport_name,
          os.certification_level,
          os.years_experience,
          os.competition_levels,
          os.is_primary
        FROM officials o
        LEFT JOIN official_sports os ON o.id = os.official_id
        LEFT JOIN sports s ON os.sport_id = s.id
        ORDER BY o.email ASC, os.is_primary DESC, s.name ASC
      ''');

      Map<String, List<Map<String, dynamic>>> officialGroups = {};

      // Group sports by official
      for (final row in officials) {
        final key = '${row['email']}';
        if (!officialGroups.containsKey(key)) {
          officialGroups[key] = [];
        }
        if (row['sport_name'] != null) {
          officialGroups[key]!.add(row);
        }
      }

      String result =
          '=== OFFICIALS SPORTS DETAILS (${officialGroups.length} Officials) ===\n\n';

      int count = 1;
      for (final entry in officialGroups.entries) {
        if (entry.value.isEmpty) continue;

        final firstRow = entry.value.first;
        result += '$count. ${firstRow['name']} (${entry.key})\n';
        result += '   Location: ${firstRow['city']}, ${firstRow['state']}\n';
        result += '   Sports:\n';

        for (final sport in entry.value) {
          final isPrimary = sport['is_primary'] == 1 ? ' ⭐PRIMARY' : '';
          result += '   • ${sport['sport_name']}$isPrimary\n';
          result += '     - Level: ${sport['certification_level']}\n';
          result += '     - Experience: ${sport['years_experience']} years\n';
          result += '     - Levels: ${sport['competition_levels']}\n';
        }
        result += '\n';
        count++;

        // Limit to first 20 to avoid too much text
        if (count > 20) {
          result += '... and ${officialGroups.length - 20} more officials\n';
          result += '\n(Showing first 20 officials only)';
          break;
        }
      }

      setState(() {
        testResult = result;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        testResult = 'Error loading sports details: $e';
        isLoading = false;
      });
    }
  }

  Future<void> _updateAssignerToSAOAFootball() async {
    setState(() {
      isLoading = true;
      testResult = 'Updating assigner to SAOA Football...';
    });

    try {
      final db = await DatabaseHelper().database;

      // Find the assigner user (email: assigner@test.com)
      final assignerUsers = await db.query(
        'users',
        where: 'email = ? AND scheduler_type = ?',
        whereArgs: ['assigner@test.com', 'assigner'],
      );

      if (assignerUsers.isEmpty) {
        setState(() {
          testResult = '❌ No assigner user found with email assigner@test.com';
          isLoading = false;
        });
        return;
      }

      // Update the assigner user
      await db.update(
        'users',
        {
          'league_name': 'SAOA Football',
          'sport': 'Football',
        },
        where: 'email = ? AND scheduler_type = ?',
        whereArgs: ['assigner@test.com', 'assigner'],
      );

      setState(() {
        testResult = '''✅ ASSIGNER UPDATED SUCCESSFULLY!

Changed:
• League Name: Metro League → SAOA Football  
• Sport: Basketball → Football

The assigner home screen will now show:
"SAOA Football"
"Football Assigner"

You can go back to the assigner home screen to see the changes!''';
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        testResult = 'Error updating assigner: $e';
        isLoading = false;
      });
    }
  }

  Future<void> _debugInterestIssue() async {
    setState(() {
      isLoading = true;
      testResult = 'Debugging interest issue...';
    });

    try {
      final db = await DatabaseHelper().database;
      StringBuffer debug = StringBuffer();

      // Check games table
      final games = await db.query('games', orderBy: 'id DESC', limit: 5);
      debug.writeln('=== RECENT GAMES ===');
      for (var game in games) {
        debug.writeln(
            'Game ID: ${game['id']} (Type: ${game['id'].runtimeType})');
        debug.writeln('  Sport: ${game['sport_id']}');
        debug.writeln('  Status: ${game['status']}');
        debug.writeln('  Created: ${game['created_at']}');
        debug.writeln('');
      }

      // Check officials table
      final officials = await db.query('officials', limit: 3);
      debug.writeln('=== OFFICIALS ===');
      for (var official in officials) {
        debug.writeln('Official ID: ${official['id']} - ${official['name']}');
      }
      debug.writeln('');

      // Check game assignments
      final assignments = await db.query('game_assignments',
          orderBy: 'assigned_at DESC', limit: 10);
      debug.writeln('=== GAME ASSIGNMENTS (EXPRESS INTEREST) ===');
      if (assignments.isEmpty) {
        debug.writeln('NO GAME ASSIGNMENTS FOUND!');
        debug.writeln(
            'This means no official has successfully expressed interest.');
      } else {
        debug.writeln('Found ${assignments.length} assignments:');
        var pendingCount = 0;
        var acceptedCount = 0;
        var declinedCount = 0;

        for (var assignment in assignments) {
          final status = assignment['status'] as String;
          switch (status) {
            case 'pending':
              pendingCount++;
              break;
            case 'accepted':
              acceptedCount++;
              break;
            case 'declined':
              declinedCount++;
              break;
          }

          debug.writeln('Assignment ID: ${assignment['id']}');
          debug.writeln('  Game ID: ${assignment['game_id']}');
          debug.writeln('  Official ID: ${assignment['official_id']}');
          debug.writeln('  Status: ${assignment['status']}');
          debug.writeln('  Assigned At: ${assignment['assigned_at']}');
          debug.writeln(
              '  Responded At: ${assignment['responded_at'] ?? 'N/A'}');
          debug.writeln('');
        }

        debug.writeln('STATUS SUMMARY:');
        debug.writeln('  Pending: $pendingCount');
        debug.writeln('  Accepted: $acceptedCount');
        debug.writeln('  Declined: $declinedCount');
        debug.writeln('');
      }

      // Test the specific query used by game information screen
      if (games.isNotEmpty) {
        final gameId = games.first['id'];
        final interestedQuery = await db.rawQuery('''
          SELECT o.id, o.name, o.phone, o.email, o.experience_years,
                 ga.assigned_at, ga.fee_amount,
                 COALESCE(0, 0) as distance
          FROM game_assignments ga
          JOIN officials o ON ga.official_id = o.id
          WHERE ga.game_id = ? AND ga.status = 'pending'
          ORDER BY ga.assigned_at ASC
        ''', [gameId]);

        debug.writeln('=== INTERESTED OFFICIALS FOR GAME $gameId ===');
        if (interestedQuery.isEmpty) {
          debug.writeln('NO INTERESTED OFFICIALS FOUND for game $gameId');
        } else {
          for (var official in interestedQuery) {
            debug.writeln('${official['name']} (ID: ${official['id']})');
          }
        }
      }

      setState(() {
        testResult = debug.toString();
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        testResult = 'Debug error: $e';
        isLoading = false;
      });
    }
  }

  Widget _buildTestResultCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: darkSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: testResult.contains('error') || testResult.contains('failed')
              ? Colors.red
              : Colors.green,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Test Result',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: primaryTextColor,
            ),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            child: Text(
              testResult,
              style: const TextStyle(
                color: primaryTextColor,
                fontFamily: 'monospace',
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
