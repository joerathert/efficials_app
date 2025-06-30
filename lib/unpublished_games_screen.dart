import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'theme.dart';
import 'utils.dart';

class UnpublishedGamesScreen extends StatefulWidget {
  const UnpublishedGamesScreen({super.key});

  @override
  State<UnpublishedGamesScreen> createState() => _UnpublishedGamesScreenState();
}

class _UnpublishedGamesScreenState extends State<UnpublishedGamesScreen> {
  List<Map<String, dynamic>> unpublishedGames = [];
  bool isLoading = true;
  String? userRole;
  String unpublishedGamesKey = 'ad_unpublished_games'; // Default to AD

  @override
  void initState() {
    super.initState();
    _loadUserRole();
  }

  Future<void> _loadUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      // Check for each role type
      if (prefs.getString('assigner_sport') != null) {
        userRole = 'assigner';
        unpublishedGamesKey = 'assigner_unpublished_games';
      } else if (prefs.getString('coach_team') != null) {
        userRole = 'coach';
        unpublishedGamesKey = 'coach_unpublished_games';
      } else {
        userRole = 'ad'; // Default to athletic director
        unpublishedGamesKey = 'ad_unpublished_games';
      }
      _fetchUnpublishedGames();
    });
  }

  Future<void> _fetchUnpublishedGames() async {
    final prefs = await SharedPreferences.getInstance();
    final String? gamesJson = prefs.getString(unpublishedGamesKey);
    setState(() {
      if (gamesJson != null && gamesJson.isNotEmpty) {
        try {
          unpublishedGames =
              List<Map<String, dynamic>>.from(jsonDecode(gamesJson));
          // Ensure proper type casting for nested objects
          for (var game in unpublishedGames) {
            if (game['selectedOfficials'] != null) {
              game['selectedOfficials'] = (game['selectedOfficials']
                      as List<dynamic>)
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
    // Convert DateTime and TimeOfDay to strings before saving
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
    await prefs.setString(unpublishedGamesKey, jsonEncode(gamesToSave));
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
    await prefs.setString(unpublishedGamesKey, jsonEncode(gamesToSave));
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
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: efficialsBlue,
        title: const Icon(
          Icons.sports,
          color: Colors.white,
          size: 32,
        ),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context, true),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Draft Games',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Review and publish your draft games',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : unpublishedGames.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.edit_note,
                                  size: 80,
                                  color: Colors.grey[400],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No draft games',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'All your games have been published',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey[500],
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            itemCount: unpublishedGames.length,
                            itemBuilder: (context, index) {
                              final game = unpublishedGames[index];
                              final sport =
                                  game['sport'] as String? ?? 'Unknown';
                              final scheduleName =
                                  game['scheduleName'] as String? ?? 'Unknown';
                              final gameDate = game['date'] != null
                                  ? DateFormat('EEEE, MMM d, yyyy')
                                      .format(game['date'] as DateTime)
                                  : 'Date not set';
                              final gameTime = game['time'] != null
                                  ? (game['time'] as TimeOfDay).format(context)
                                  : 'Time not set';
                              final location = game['location'] as String? ??
                                  'Location not set';
                              final opponent = game['opponent'] as String?;
                              final isAway = game['isAway'] as bool? ?? false;
                              final sportIcon = getSportIcon(sport);
                              final opponentDisplay = opponent != null
                                  ? (isAway ? '@ $opponent' : 'vs $opponent')
                                  : null;

                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12.0),
                                child: GestureDetector(
                                  onTap: () {
                                    Navigator.pushNamed(
                                      context,
                                      '/review_game_info',
                                      arguments: game,
                                    ).then((result) {
                                      if (result != null &&
                                          result is Map<String, dynamic>) {
                                        // Update the game in unpublished_games if edited
                                        setState(() {
                                          final index =
                                              unpublishedGames.indexWhere(
                                                  (g) => g['id'] == game['id']);
                                          if (index != -1) {
                                            unpublishedGames[index] = result;
                                          }
                                        });
                                        _saveUnpublishedGames();
                                      }
                                    });
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.grey.withOpacity(0.1),
                                          spreadRadius: 1,
                                          blurRadius: 3,
                                          offset: const Offset(0, 1),
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: getSportIconColor(sport)
                                                .withOpacity(0.1),
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          child: Icon(
                                            sportIcon,
                                            color: getSportIconColor(sport),
                                            size: 24,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                gameDate,
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.black,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                opponentDisplay != null
                                                    ? '$gameTime $opponentDisplay'
                                                    : '$gameTime - $scheduleName',
                                                style: const TextStyle(
                                                    fontSize: 16,
                                                    color: Colors.black),
                                              ),
                                              if (opponentDisplay != null) ...[
                                                const SizedBox(height: 4),
                                                Text(
                                                  scheduleName,
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    color: Colors.grey[700],
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ],
                                              const SizedBox(height: 4),
                                              Text(
                                                location,
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  color: Colors.grey[600],
                                                ),
                                              ),
                                              const SizedBox(height: 8),
                                              Row(
                                                children: [
                                                  Container(
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                        horizontal: 8,
                                                        vertical: 4),
                                                    decoration: BoxDecoration(
                                                      color: Colors.orange
                                                          .withOpacity(0.1),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              12),
                                                    ),
                                                    child: Row(
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                                      children: [
                                                        Icon(
                                                          Icons.edit,
                                                          size: 12,
                                                          color: Colors
                                                              .orange.shade700,
                                                        ),
                                                        const SizedBox(
                                                            width: 4),
                                                        Text(
                                                          'Draft',
                                                          style: TextStyle(
                                                            fontSize: 12,
                                                            color: Colors.orange
                                                                .shade700,
                                                            fontWeight:
                                                                FontWeight.w600,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  const Spacer(),
                                                  GestureDetector(
                                                    onTap: () =>
                                                        _showDeleteConfirmationDialog(
                                                            game['id'] as int,
                                                            '$sport - $scheduleName'),
                                                    child: Container(
                                                      padding:
                                                          const EdgeInsets.all(
                                                              8),
                                                      decoration: BoxDecoration(
                                                        color: Colors.red
                                                            .withOpacity(0.1),
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(8),
                                                      ),
                                                      child: Icon(
                                                        Icons.delete_outline,
                                                        size: 20,
                                                        color:
                                                            Colors.red.shade600,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        const Icon(
                                          Icons.arrow_forward_ios,
                                          color: Colors.grey,
                                          size: 16,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
