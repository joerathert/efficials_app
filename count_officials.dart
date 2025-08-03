import 'dart:io';
import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

void main() async {
  await countFootballOfficials();
}

Future<void> countFootballOfficials() async {
  print('🔍 Counting Football officials with specified parameters...');

  try {
    // Get the database path
    final databasePath = await getDatabasesPath();
    final path = join(databasePath, 'efficials.db');

    // Open the database
    final db = await openDatabase(path);

    // Query to count Football officials who are IHSA Registered and officiate Underclass
    final results = await db.rawQuery('''
      SELECT COUNT(DISTINCT o.id) as official_count
      FROM officials o
      JOIN official_sports os ON o.id = os.official_id
      JOIN sports s ON os.sport_id = s.id
      WHERE s.name = 'Football'
        AND os.certification_level = 'IHSA Registered'
        AND os.competition_levels LIKE '%Underclass%'
    ''');

    final count = results.first['official_count'] as int? ?? 0;

    print('📊 Results:');
    print(
        'Football officials who are IHSA Registered and officiate Underclass: $count');

    // Also get detailed results for verification
    final detailedResults = await db.rawQuery('''
      SELECT 
        o.id,
        o.name,
        o.city,
        o.state,
        os.certification_level,
        os.competition_levels,
        os.years_experience,
        s.name as sport_name
      FROM officials o
      JOIN official_sports os ON o.id = os.official_id
      JOIN sports s ON os.sport_id = s.id
      WHERE s.name = 'Football'
        AND os.certification_level = 'IHSA Registered'
        AND os.competition_levels LIKE '%Underclass%'
      ORDER BY o.name
    ''');

    print('\n📋 Detailed list of matching officials:');
    for (final official in detailedResults) {
      print(
          '  - ${official['name']} (${official['city']}, ${official['state']}) - ${official['competition_levels']}');
    }

    // Also check total Football officials for comparison
    final totalFootballResults = await db.rawQuery('''
      SELECT COUNT(DISTINCT o.id) as total_football_count
      FROM officials o
      JOIN official_sports os ON o.id = os.official_id
      JOIN sports s ON os.sport_id = s.id
      WHERE s.name = 'Football'
    ''');

    final totalFootballCount =
        totalFootballResults.first['total_football_count'] as int? ?? 0;
    print('\n📈 Comparison:');
    print('Total Football officials: $totalFootballCount');
    print('Matching your criteria: $count');
    print(
        'Percentage: ${totalFootballCount > 0 ? (count / totalFootballCount * 100).toStringAsFixed(1) : 0}%');

    await db.close();
  } catch (e) {
    print('❌ Error counting officials: $e');
  }
}
