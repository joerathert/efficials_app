import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'theme.dart';

class UnpublishedGamesScreen extends StatefulWidget {
  const UnpublishedGamesScreen({super.key});

  @override
  State<UnpublishedGamesScreen> createState() => _UnpublishedGamesScreenState();
}

class _UnpublishedGamesScreenState extends State<UnpublishedGamesScreen> {
  List<Map<String, dynamic>> unpublishedGames = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUnpublishedGames();
  }

  Future<void> _fetchUnpublishedGames() async {
    final prefs = await SharedPreferences.getInstance();
    final String? gamesJson = prefs.getString('unpublished_games');
    setState(() {
      if (gamesJson != null && gamesJson.isNotEmpty) {
        try {
          unpublishedGames = List<Map<String, dynamic>>.from(jsonDecode(gamesJson));
          // Ensure proper type casting for nested objects
          for (var game in unpublishedGames) {
            if (game['selectedOfficials'] != null) {
              game['selectedOfficials'] = (game['selectedOfficials'] as List<dynamic>)
                  .map((official) => Map<String, dynamic>.from(official as Map))
                  .toList();
            }
            if (game['date'] != null) {
              game['date'] = DateTime.parse(game['date'] as String);
            }
            if (game['time'] != null) {
              final timeParts = (game['time'] as String).split(':');
              game['time'] = TimeOfDay(
                hour: int.parse(timeParts[0]),
                minute: int.parse(timeParts[1]),
              );
            }
          }
        } catch (e) {
          unpublishedGames = [];
          print('Error loading unpublished games: $e');
        }
      }
      isLoading = false;
    });
  }

  Future<void> _deleteGame(int gameId) async {
    final prefs = await SharedPreferences.getInstance();
    unpublishedGames.removeWhere((game) => game['id'] == gameId);
    await prefs.setString('unpublished_games', jsonEncode(unpublishedGames));
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Game deleted!')),
    );
  }

  Future<void> _saveUnpublishedGames() async {
    final prefs = await SharedPreferences.getInstance();
    // Convert DateTime and TimeOfDay back to strings before saving
    final gamesToSave = unpublishedGames.map((game) {
      final gameCopy = Map<String, dynamic>.from(game);
      if (gameCopy['date'] != null) {
        gameCopy['date'] = (gameCopy['date'] as DateTime).toIso8601String();
      }
      if (gameCopy['time'] != null) {
        final time = gameCopy['time'] as TimeOfDay;
        gameCopy['time'] = '${time.hour}:${time.minute}';
      }
      return gameCopy;
    }).toList();
    await prefs.setString('unpublished_games', jsonEncode(gamesToSave));
  }

  void _showDeleteConfirmationDialog(int gameId, String gameTitle) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: Text('Are you sure you want to delete "$gameTitle"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: efficialsBlue)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteGame(gameId);
            },
            child: const Text('Delete', style: TextStyle(color: efficialsBlue)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: efficialsBlue,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, size: 36, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Unpublished Games',
          style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: isLoading
                ? const CircularProgressIndicator()
                : unpublishedGames.isEmpty
                    ? const Center(
                        child: Text(
                          'No unpublished games.',
                          style: TextStyle(fontSize: 18, color: Colors.grey),
                          textAlign: TextAlign.center,
                        ),
                      )
                    : ListView.builder(
                        itemCount: unpublishedGames.length,
                        itemBuilder: (context, index) {
                          final game = unpublishedGames[index];
                          final gameTitle = '${game['sport']} - ${game['scheduleName']}';
                          final gameDate = game['date'] != null
                              ? DateFormat('MMMM d, yyyy').format(game['date'] as DateTime)
                              : 'Not set';
                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 8),
                            child: ListTile(
                              title: Text(gameTitle),
                              subtitle: Text('Date: $gameDate'),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _showDeleteConfirmationDialog(game['id'] as int, gameTitle),
                              ),
                              onTap: () {
                                Navigator.pushNamed(
                                  context,
                                  '/review_game_info',
                                  arguments: game,
                                ).then((result) {
                                  if (result != null && result is Map<String, dynamic>) {
                                    // Update the game in unpublished_games if edited
                                    setState(() {
                                      final index = unpublishedGames.indexWhere((g) => g['id'] == game['id']);
                                      if (index != -1) {
                                        unpublishedGames[index] = result;
                                      }
                                    });
                                    _saveUnpublishedGames();
                                  }
                                });
                              },
                            ),
                          );
                        },
                      ),
          ),
        ),
      ),
    );
  }
}