import 'package:flutter/material.dart';
import '../../shared/theme.dart';
import '../../shared/services/repositories/game_assignment_repository.dart';

class ADProfileDebugScreen extends StatefulWidget {
  const ADProfileDebugScreen({super.key});

  @override
  State<ADProfileDebugScreen> createState() => _ADProfileDebugScreenState();
}

class _ADProfileDebugScreenState extends State<ADProfileDebugScreen> {
  final GameAssignmentRepository _gameRepo = GameAssignmentRepository();
  List<Map<String, dynamic>> _adUsers = [];
  List<Map<String, dynamic>> _adGames = [];
  bool _isLoading = true;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      setState(() {
        _isLoading = true;
        _error = '';
      });

      // Get all Athletic Director users
      final adUsers = await _gameRepo.rawQuery('''
        SELECT id, first_name, last_name, email, 
               school_name, mascot, school_address,
               setup_completed, created_at
        FROM users 
        WHERE scheduler_type = 'Athletic Director'
        ORDER BY created_at DESC
      ''');

      // Get games created by Athletic Directors
      final adGames = await _gameRepo.rawQuery('''
        SELECT g.id, g.opponent, g.home_team, g.status,
               u.first_name, u.last_name, u.school_name, u.mascot,
               -- Test our CASE statement
               CASE 
                 WHEN g.home_team IS NOT NULL AND g.home_team != '' AND g.home_team != 'Home Team' 
                 THEN g.home_team
                 WHEN u.scheduler_type = 'Athletic Director' AND u.school_name IS NOT NULL AND u.mascot IS NOT NULL
                 THEN u.school_name || ' ' || u.mascot
                 ELSE COALESCE(g.home_team, 'Home Team')
               END as calculated_home_team
        FROM games g
        JOIN users u ON g.user_id = u.id  
        WHERE u.scheduler_type = 'Athletic Director'
        ORDER BY g.created_at DESC
        LIMIT 10
      ''');

      setState(() {
        _adUsers = adUsers;
        _adGames = adGames;
        _isLoading = false;
      });

    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: darkBackground,
      appBar: AppBar(
        backgroundColor: efficialsBlack,
        title: const Text('AD Profile Debug', style: TextStyle(color: efficialsWhite)),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: efficialsWhite),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: efficialsYellow),
                  SizedBox(height: 16),
                  Text('Loading AD profile data...', style: TextStyle(color: efficialsWhite)),
                ],
              ),
            )
          : _error.isNotEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error, color: Colors.red, size: 48),
                      const SizedBox(height: 16),
                      Text('Error: $_error', 
                           style: const TextStyle(color: Colors.red),
                           textAlign: TextAlign.center),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadData,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadData,
                  color: efficialsYellow,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildUsersSection(),
                        const SizedBox(height: 24),
                        _buildGamesSection(),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildUsersSection() {
    return Card(
      color: darkSurface,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Athletic Director Users',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: efficialsYellow,
              ),
            ),
            const SizedBox(height: 12),
            if (_adUsers.isEmpty)
              const Text(
                'No Athletic Directors found',
                style: TextStyle(color: Colors.orange),
              )
            else
              ..._adUsers.map((ad) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: darkBackground,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${ad['first_name']} ${ad['last_name']} (ID: ${ad['id']})',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: efficialsWhite,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text('Email: ${ad['email']}', style: const TextStyle(color: efficialsWhite)),
                      Text('School Name: "${ad['school_name']}"', style: const TextStyle(color: efficialsWhite)),
                      Text('Mascot: "${ad['mascot']}"', style: const TextStyle(color: efficialsWhite)),
                      Text('Setup Completed: ${ad['setup_completed'] == 1 ? 'Yes' : 'No'}', 
                           style: TextStyle(color: ad['setup_completed'] == 1 ? Colors.green : Colors.orange)),
                      if (ad['school_name'] != null && ad['mascot'] != null)
                        Text(
                          'Expected Home Team: "${ad['school_name']} ${ad['mascot']}"',
                          style: const TextStyle(color: efficialsYellow, fontWeight: FontWeight.bold),
                        ),
                    ],
                  ),
                ),
              )),
          ],
        ),
      ),
    );
  }

  Widget _buildGamesSection() {
    return Card(
      color: darkSurface,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Athletic Director Games',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: efficialsYellow,
              ),
            ),
            const SizedBox(height: 12),
            if (_adGames.isEmpty)
              const Text(
                'No games found created by Athletic Directors',
                style: TextStyle(color: Colors.orange),
              )
            else
              ..._adGames.map((game) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: darkBackground,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Game ${game['id']} (${game['status']})',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: efficialsWhite,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text('Opponent: "${game['opponent']}"', style: const TextStyle(color: efficialsWhite)),
                      Text('Stored Home Team: "${game['home_team']}"', 
                           style: TextStyle(color: game['home_team']?.toString().trim().isEmpty == true ? Colors.red : efficialsWhite)),
                      Text('Calculated Home Team: "${game['calculated_home_team']}"', 
                           style: const TextStyle(color: efficialsYellow, fontWeight: FontWeight.bold)),
                      Text('Created by: ${game['first_name']} ${game['last_name']}', style: const TextStyle(color: efficialsWhite)),
                      Text('AD School: "${game['school_name']}"', style: const TextStyle(color: efficialsWhite)),
                      Text('AD Mascot: "${game['mascot']}"', style: const TextStyle(color: efficialsWhite)),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: efficialsYellow.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'Display: "${game['opponent']}" @ "${game['calculated_home_team']}"',
                          style: const TextStyle(color: efficialsYellow, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
              )),
          ],
        ),
      ),
    );
  }
}