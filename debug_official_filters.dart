import 'package:flutter/material.dart';
import 'lib/shared/services/database_helper.dart';
import 'lib/shared/services/repositories/official_repository.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await debugOfficialFilters();
}

Future<void> debugOfficialFilters() async {
  print('🔍 DEBUGGING OFFICIAL FILTERS');
  print('=' * 50);

  try {
    final dbHelper = DatabaseHelper();
    final db = await dbHelper.database;
    final officialRepo = OfficialRepository();

    // 1. Check total Football officials
    print('\n📊 1. TOTAL FOOTBALL OFFICIALS:');
    final totalFootball = await db.rawQuery('''
      SELECT COUNT(DISTINCT o.id) as count
      FROM officials o
      JOIN official_sports os ON o.id = os.official_id
      JOIN sports s ON os.sport_id = s.id
      WHERE s.name = 'Football'
    ''');
    print('Total Football officials: ${totalFootball.first['count']}');

    // 2. Check IHSA Registered Football officials
    print('\n📊 2. IHSA REGISTERED FOOTBALL OFFICIALS:');
    final ihsaRegistered = await db.rawQuery('''
      SELECT COUNT(DISTINCT o.id) as count
      FROM officials o
      JOIN official_sports os ON o.id = os.official_id
      JOIN sports s ON os.sport_id = s.id
      WHERE s.name = 'Football'
        AND os.certification_level IN ('IHSA Registered', 'IHSA Recognized', 'IHSA Certified')
    ''');
    print(
        'IHSA Registered Football officials: ${ihsaRegistered.first['count']}');

    // 3. Check Underclass competition level
    print('\n📊 3. UNDERCLASS COMPETITION LEVEL:');
    final underclass = await db.rawQuery('''
      SELECT COUNT(DISTINCT o.id) as count
      FROM officials o
      JOIN official_sports os ON o.id = os.official_id
      JOIN sports s ON os.sport_id = s.id
      WHERE s.name = 'Football'
        AND os.competition_levels LIKE '%Underclass%'
    ''');
    print('Football officials with Underclass: ${underclass.first['count']}');

    // 4. Check combined filters
    print('\n📊 4. COMBINED FILTERS (IHSA Registered + Underclass):');
    final combined = await db.rawQuery('''
      SELECT COUNT(DISTINCT o.id) as count
      FROM officials o
      JOIN official_sports os ON o.id = os.official_id
      JOIN sports s ON os.sport_id = s.id
      WHERE s.name = 'Football'
        AND os.certification_level IN ('IHSA Registered', 'IHSA Recognized', 'IHSA Certified')
        AND os.competition_levels LIKE '%Underclass%'
    ''');
    print('Football officials with both filters: ${combined.first['count']}');

    // 5. Show sample data
    print('\n📊 5. SAMPLE OFFICIAL DATA:');
    final sample = await db.rawQuery('''
      SELECT o.name, os.certification_level, os.competition_levels
      FROM officials o
      JOIN official_sports os ON o.id = os.official_id
      JOIN sports s ON os.sport_id = s.id
      WHERE s.name = 'Football'
      LIMIT 10
    ''');

    for (final row in sample) {
      print('Name: ${row['name']}');
      print('  Certification: ${row['certification_level']}');
      print('  Competition Levels: ${row['competition_levels']}');
      print('  ---');
    }

    // 6. Check all certification levels
    print('\n📊 6. ALL CERTIFICATION LEVELS FOR FOOTBALL:');
    final certLevels = await db.rawQuery('''
      SELECT os.certification_level, COUNT(*) as count
      FROM officials o
      JOIN official_sports os ON o.id = os.official_id
      JOIN sports s ON os.sport_id = s.id
      WHERE s.name = 'Football'
      GROUP BY os.certification_level
    ''');

    for (final row in certLevels) {
      print('${row['certification_level']}: ${row['count']}');
    }

    // 7. Check all competition levels
    print('\n📊 7. ALL COMPETITION LEVELS FOR FOOTBALL:');
    final compLevels = await db.rawQuery('''
      SELECT os.competition_levels, COUNT(*) as count
      FROM officials o
      JOIN official_sports os ON o.id = os.official_id
      JOIN sports s ON os.sport_id = s.id
      WHERE s.name = 'Football'
      GROUP BY os.competition_levels
    ''');

    for (final row in compLevels) {
      print('${row['competition_levels']}: ${row['count']}');
    }
  } catch (e) {
    print('❌ Error: $e');
  }
}
