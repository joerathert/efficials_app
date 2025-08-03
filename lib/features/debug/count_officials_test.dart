import 'package:flutter/material.dart';
import '../../shared/services/database_helper.dart';
import '../../shared/theme.dart';

class CountOfficialsTest extends StatefulWidget {
  const CountOfficialsTest({super.key});

  @override
  State<CountOfficialsTest> createState() => _CountOfficialsTestState();
}

class _CountOfficialsTestState extends State<CountOfficialsTest> {
  String result = 'Loading...';
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _runQuery();
  }

  Future<void> _runQuery() async {
    try {
      final dbHelper = DatabaseHelper();
      final db = await dbHelper.database;

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

      setState(() {
        result = '''
📊 Results:

Football officials who are IHSA Registered and officiate Underclass: $count

📋 Detailed list of matching officials:
${detailedResults.map((official) => '  - ${official['name']} (${official['city']}, ${official['state']}) - ${official['competition_levels']}').join('\n')}

📈 Comparison:
Total Football officials: $totalFootballCount
Matching your criteria: $count
Percentage: ${totalFootballCount > 0 ? (count / totalFootballCount * 100).toStringAsFixed(1) : 0}%
        ''';
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        result = '❌ Error: $e';
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
        title: const Text('Count Officials Test',
            style: TextStyle(color: efficialsWhite)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: efficialsWhite),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Query Parameters:',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: efficialsYellow,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '• Sport: Football\n'
              '• Certification: IHSA Registered\n'
              '• Competition Level: Underclass\n'
              '• Distance: 100 miles from Edwardsville, IL',
              style: TextStyle(color: efficialsWhite, fontSize: 16),
            ),
            const SizedBox(height: 20),
            const Text(
              'Results:',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: efficialsYellow,
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: darkSurface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[700]!),
                ),
                child: isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : SingleChildScrollView(
                        child: Text(
                          result,
                          style: const TextStyle(
                            color: efficialsWhite,
                            fontSize: 14,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _runQuery,
                style: elevatedButtonStyle(),
                child:
                    const Text('Run Query Again', style: signInButtonTextStyle),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
