import 'package:flutter/material.dart';
import '../../shared/services/database_helper.dart';
import '../../shared/theme.dart';

class OfficialStatsScreen extends StatefulWidget {
  const OfficialStatsScreen({super.key});

  @override
  State<OfficialStatsScreen> createState() => _OfficialStatsScreenState();
}

class _OfficialStatsScreenState extends State<OfficialStatsScreen> {
  Map<String, dynamic> stats = {};
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    try {
      final db = await DatabaseHelper().database;

      // 1. Total Football officials
      final totalFootball = await db.rawQuery('''
        SELECT COUNT(DISTINCT o.id) as count
        FROM officials o
        JOIN official_sports os ON o.id = os.official_id
        JOIN sports s ON os.sport_id = s.id
        WHERE s.name = 'Football'
      ''');

      // 2. IHSA Registered Football officials
      final ihsaRegistered = await db.rawQuery('''
        SELECT COUNT(DISTINCT o.id) as count
        FROM officials o
        JOIN official_sports os ON o.id = os.official_id
        JOIN sports s ON os.sport_id = s.id
        WHERE s.name = 'Football'
          AND os.certification_level IN ('IHSA Registered', 'IHSA Recognized', 'IHSA Certified')
      ''');

      // 3. Underclass competition level
      final underclass = await db.rawQuery('''
        SELECT COUNT(DISTINCT o.id) as count
        FROM officials o
        JOIN official_sports os ON o.id = os.official_id
        JOIN sports s ON os.sport_id = s.id
        WHERE s.name = 'Football'
          AND os.competition_levels LIKE '%Underclass%'
      ''');

      // 4. Combined filters
      final combined = await db.rawQuery('''
        SELECT COUNT(DISTINCT o.id) as count
        FROM officials o
        JOIN official_sports os ON o.id = os.official_id
        JOIN sports s ON os.sport_id = s.id
        WHERE s.name = 'Football'
          AND os.certification_level IN ('IHSA Registered', 'IHSA Recognized', 'IHSA Certified')
          AND os.competition_levels LIKE '%Underclass%'
      ''');

      // 5. Sample data
      final sample = await db.rawQuery('''
        SELECT o.name, os.certification_level, os.competition_levels
        FROM officials o
        JOIN official_sports os ON o.id = os.official_id
        JOIN sports s ON os.sport_id = s.id
        WHERE s.name = 'Football'
        LIMIT 10
      ''');

      // 6. All certification levels
      final certLevels = await db.rawQuery('''
        SELECT os.certification_level, COUNT(*) as count
        FROM officials o
        JOIN official_sports os ON o.id = os.official_id
        JOIN sports s ON os.sport_id = s.id
        WHERE s.name = 'Football'
        GROUP BY os.certification_level
      ''');

      // 7. All competition levels
      final compLevels = await db.rawQuery('''
        SELECT os.competition_levels, COUNT(*) as count
        FROM officials o
        JOIN official_sports os ON o.id = os.official_id
        JOIN sports s ON os.sport_id = s.id
        WHERE s.name = 'Football'
        GROUP BY os.competition_levels
      ''');

      setState(() {
        stats = {
          'totalFootball': totalFootball.first['count'],
          'ihsaRegistered': ihsaRegistered.first['count'],
          'underclass': underclass.first['count'],
          'combined': combined.first['count'],
          'sample': sample,
          'certLevels': certLevels,
          'compLevels': compLevels,
        };
        isLoading = false;
      });
    } catch (e) {
      print('Error loading stats: $e');
      setState(() {
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
        title: const Icon(
          Icons.analytics,
          color: efficialsYellow,
          size: 32,
        ),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: efficialsWhite),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: efficialsYellow),
                )
              : SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Football Official Statistics',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: efficialsYellow,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Basic counts
                      _buildStatCard('Total Football Officials',
                          '${stats['totalFootball']}'),
                      _buildStatCard('IHSA Registered Officials',
                          '${stats['ihsaRegistered']}'),
                      _buildStatCard('Officials with Underclass',
                          '${stats['underclass']}'),
                      _buildStatCard(
                          'Combined Filters Result', '${stats['combined']}',
                          isHighlighted: true),

                      const SizedBox(height: 20),

                      // Certification levels
                      const Text(
                        'Certification Levels',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: efficialsYellow,
                        ),
                      ),
                      const SizedBox(height: 10),
                      ...(stats['certLevels'] as List).map(
                        (level) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Text(
                            '${level['certification_level']}: ${level['count']}',
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Competition levels
                      const Text(
                        'Competition Levels',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: efficialsYellow,
                        ),
                      ),
                      const SizedBox(height: 10),
                      ...(stats['compLevels'] as List).map(
                        (level) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Text(
                            '${level['competition_levels']}: ${level['count']}',
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Sample data
                      const Text(
                        'Sample Officials',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: efficialsYellow,
                        ),
                      ),
                      const SizedBox(height: 10),
                      ...(stats['sample'] as List).map(
                        (official) => Container(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: darkSurface,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Name: ${official['name']}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'Certification: ${official['certification_level']}',
                                style: const TextStyle(color: Colors.white70),
                              ),
                              Text(
                                'Competition Levels: ${official['competition_levels']}',
                                style: const TextStyle(color: Colors.white70),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value,
      {bool isHighlighted = false}) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isHighlighted ? Colors.red.withOpacity(0.2) : darkSurface,
        borderRadius: BorderRadius.circular(12),
        border: isHighlighted ? Border.all(color: Colors.red, width: 2) : null,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              color: isHighlighted ? Colors.red : Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: isHighlighted ? Colors.red : efficialsYellow,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
