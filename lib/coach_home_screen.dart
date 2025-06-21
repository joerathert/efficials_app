import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'theme.dart';
import 'utils.dart';
import 'athletic_director_home_screen.dart'; // For Game class

class CoachHomeScreen extends StatefulWidget {
  const CoachHomeScreen({super.key});

  @override
  State<CoachHomeScreen> createState() => _CoachHomeScreenState();
}

class _CoachHomeScreenState extends State<CoachHomeScreen> {
  List<Game> publishedGames = [];
  bool isLoading = true;
  static const team = 'Springfield Jets Baseball (11U)'; // Fixed: static const

  @override
  void initState() {
    super.initState();
    _fetchGames();
  }

  Future<void> _fetchGames() async {
    final prefs = await SharedPreferences.getInstance();
    final String? gamesJson = prefs.getString('published_games');

    setState(() {
      if (gamesJson != null && gamesJson.isNotEmpty) {
        try {
          publishedGames = List<Map<String, dynamic>>.from(jsonDecode(gamesJson))
              .map(Game.fromJson)
              .where((game) => game.scheduleName == team)
              .toList();
        } catch (e) {
          publishedGames = [];
          print('Error loading published games: $e');
        }
      } else {
        publishedGames = [];
      }
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)!.settings.arguments as Map<String, String>? ?? {};
    final coachName = args['firstName'] ?? 'Coach'; // Use args
    final double statusBarHeight = MediaQuery.of(context).padding.top;
    const double appBarHeight = kToolbarHeight;
    final double totalBannerHeight = statusBarHeight + appBarHeight;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: efficialsBlue,
        title: const Text('Coach Home', style: appBarTextStyle),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, color: Colors.white),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            Container(
              height: totalBannerHeight,
              decoration: const BoxDecoration(color: efficialsBlue),
              child: Padding(
                padding: EdgeInsets.only(top: statusBarHeight + 8.0, bottom: 8.0, left: 16.0, right: 16.0),
                child: const Text(
                  'Menu',
                  style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.schedule),
              title: const Text('Team Schedule'),
              onTap: () {
                Navigator.pop(context);
                _fetchGames();
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Settings'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Settings not implemented yet')),
                );
              },
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              Text('Welcome, $coachName! Team: $team', style: const TextStyle(fontSize: 24)),
              const SizedBox(height: 10),
              Expanded(
                child: isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : publishedGames.isEmpty
                        ? const Center(child: Text('No games scheduled.', style: homeTextStyle))
                        : ListView.builder(
                            itemCount: publishedGames.length,
                            itemBuilder: (context, index) {
                              final game = publishedGames[index];
                              return _buildGameTile(game);
                            },
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGameTile(Game game) {
    final gameTitle = game.scheduleName;
    final gameDate = game.date != null ? DateFormat('EEEE, MMM d, yyyy').format(game.date!) : 'Not set';
    final gameTime = game.time != null ? game.time!.format(context) : 'Not set';
    final requiredOfficials = game.officialsRequired;
    final hiredOfficials = game.officialsHired;
    final isFullyHired = hiredOfficials >= requiredOfficials;
    final sport = game.sport;
    final sportIcon = getSportIcon(sport);
    final isAway = game.isAway;

    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(context, '/game_information', arguments: game.toJson());
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(gameDate, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text('$gameTime - $gameTitle', style: const TextStyle(fontSize: 16, color: Colors.black)),
                      const SizedBox(width: 8),
                      Icon(sportIcon, color: efficialsBlue, size: 24),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (isAway)
                        const Text('Away game', style: TextStyle(fontSize: 14, color: Colors.grey))
                      else ...[
                        Text('$hiredOfficials/$requiredOfficials Official(s)',
                            style: TextStyle(fontSize: 14, color: isFullyHired ? Colors.green : Colors.red)),
                        if (!isFullyHired) ...[
                          const SizedBox(width: 8),
                          const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 16),
                        ],
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}