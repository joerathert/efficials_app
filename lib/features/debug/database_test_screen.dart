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
          firstName: 'Sam',
          lastName: 'Assigner',
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
            onPressed: _resetDatabase,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Reset Database'),
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
