import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../shared/theme.dart';
import '../../shared/utils/utils.dart';
import '../../shared/services/game_service.dart';

class UnpublishedGamesScreen extends StatefulWidget {
  const UnpublishedGamesScreen({super.key});

  @override
  State<UnpublishedGamesScreen> createState() => _UnpublishedGamesScreenState();
}

class _UnpublishedGamesScreenState extends State<UnpublishedGamesScreen> {
  List<Map<String, dynamic>> unpublishedGames = [];
  Set<int> selectedGameIds = {}; // Track selected game IDs
  bool isLoading = true;
  String? userRole;
  String unpublishedGamesKey = 'ad_unpublished_games'; // Default to AD
  final GameService _gameService = GameService();

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
    try {
      // Try to get games from database first
      final games = await _gameService.getUnpublishedGames();
      setState(() {
        unpublishedGames = games;
        // Convert string dates and times to proper types for UI
        for (var game in unpublishedGames) {
          if (game['date'] != null && game['date'] is String) {
            game['date'] = DateTime.parse(game['date'] as String);
          }
          if (game['time'] != null && game['time'] is String) {
            final timeParts = (game['time'] as String).split(':');
            game['time'] = TimeOfDay(
              hour: int.parse(timeParts[0]),
              minute: int.parse(timeParts[1]),
            );
          }
        }
        isLoading = false;
      });
    } catch (e) {
      // Fallback to SharedPreferences if database fails
      await _fetchUnpublishedGamesFromPrefs();
    }
  }

  Future<void> _fetchUnpublishedGamesFromPrefs() async {
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
        }
      }
      isLoading = false;
    });
  }

  Future<void> _deleteGame(int gameId) async {
    try {
      // Try to delete from database first
      final success = await _gameService.deleteGame(gameId);
      if (success) {
        setState(() {
          unpublishedGames.removeWhere((game) => game['id'] == gameId);
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Game deleted!')),
          );
        }
      } else {
        // Fallback to SharedPreferences
        await _deleteGameFromPrefs(gameId);
      }
    } catch (e) {
      // Fallback to SharedPreferences
      await _deleteGameFromPrefs(gameId);
    }
  }

  Future<void> _deleteGameFromPrefs(int gameId) async {
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
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Game deleted!')),
      );
    }
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

  Future<void> _publishSelectedGames() async {
    final gamesToPublish = unpublishedGames
        .where((game) => selectedGameIds.contains(game['id']))
        .toList();
    
    if (gamesToPublish.isEmpty) return;

    try {
      // Try to publish games using database service
      final gameIds = gamesToPublish.map((game) => game['id'] as int).toList();
      final success = await _gameService.publishGames(gameIds);
      
      if (success) {
        setState(() {
          unpublishedGames.removeWhere((game) => selectedGameIds.contains(game['id']));
          selectedGameIds.clear();
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  '${gamesToPublish.length} game${gamesToPublish.length == 1 ? '' : 's'} published successfully!'),
            ),
          );
        }
      } else {
        // Fallback to SharedPreferences
        await _publishSelectedGamesWithPrefs(gamesToPublish);
      }
    } catch (e) {
      // Fallback to SharedPreferences
      await _publishSelectedGamesWithPrefs(gamesToPublish);
    }
  }

  Future<void> _publishSelectedGamesWithPrefs(List<Map<String, dynamic>> gamesToPublish) async {
    final prefs = await SharedPreferences.getInstance();

    // Determine the correct published games storage key based on user role
    String publishedGamesKey;
    switch (userRole) {
      case 'coach':
        publishedGamesKey = 'coach_published_games';
        break;
      case 'assigner':
        publishedGamesKey = 'assigner_published_games';
        break;
      case 'ad':
      default:
        publishedGamesKey = 'ad_published_games';
        break;
    }

    // Get existing published games
    final String? publishedGamesJson = prefs.getString(publishedGamesKey);
    List<Map<String, dynamic>> publishedGames = [];
    if (publishedGamesJson != null && publishedGamesJson.isNotEmpty) {
      publishedGames =
          List<Map<String, dynamic>>.from(jsonDecode(publishedGamesJson));
    }

    // Add selected games to published games
    for (var game in gamesToPublish) {
      final gameCopy = Map<String, dynamic>.from(game);
      if (gameCopy['date'] != null) {
        gameCopy['date'] = (gameCopy['date'] as DateTime).toIso8601String();
      }
      if (gameCopy['time'] != null) {
        final time = gameCopy['time'] as TimeOfDay;
        gameCopy['time'] = '${time.hour}:${time.minute}';
      }
      gameCopy['status'] = 'Published';
      gameCopy['createdAt'] = DateTime.now().toIso8601String();
      publishedGames.add(gameCopy);
    }

    // Save updated published games
    await prefs.setString(publishedGamesKey, jsonEncode(publishedGames));

    // Remove published games from unpublished list
    unpublishedGames
        .removeWhere((game) => selectedGameIds.contains(game['id']));
    await _saveUnpublishedGames();

    setState(() {
      selectedGameIds.clear();
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              '${gamesToPublish.length} game${gamesToPublish.length == 1 ? '' : 's'} published successfully!'),
        ),
      );
    }
  }

  void _showDeleteConfirmationDialog(int gameId, String gameTitle) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: darkSurface,
        title: const Text(
          'Confirm Delete',
          style: TextStyle(
            color: efficialsYellow,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Are you sure you want to delete "$gameTitle"?',
          style: const TextStyle(
            color: primaryTextColor,
            fontSize: 16,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(
                color: efficialsYellow,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteGame(gameId);
            },
            child: const Text(
              'Delete',
              style: TextStyle(
                color: efficialsYellow,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasSelectedGames = selectedGameIds.isNotEmpty;

    return Scaffold(
      backgroundColor: darkBackground,
      appBar: AppBar(
        backgroundColor: efficialsBlack,
        title: const Icon(
          Icons.sports,
          color: darkSurface,
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Draft Games',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: primaryTextColor,
                    ),
                  ),
                  if (!unpublishedGames.isEmpty)
                    Row(
                      children: [
                        Checkbox(
                          value: selectedGameIds.length ==
                                  unpublishedGames.length &&
                              unpublishedGames.isNotEmpty,
                          onChanged: (bool? value) {
                            setState(() {
                              if (value == true) {
                                selectedGameIds = unpublishedGames
                                    .map((g) => g['id'] as int)
                                    .toSet();
                              } else {
                                selectedGameIds.clear();
                              }
                            });
                          },
                          activeColor: efficialsYellow,
                          checkColor: efficialsBlack,
                        ),
                        const Text(
                          'Select All',
                          style: TextStyle(
                            color: primaryTextColor,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
              const SizedBox(height: 10),
              const Text(
                'Review and publish your draft games',
                style: TextStyle(
                  fontSize: 16,
                  color: secondaryTextColor,
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
                                const Text(
                                  'No draft games',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: secondaryTextColor,
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
                              final gameId = game['id'] as int;
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
                                      color: darkSurface,
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
                                        Checkbox(
                                          value:
                                              selectedGameIds.contains(gameId),
                                          onChanged: (bool? value) {
                                            setState(() {
                                              if (value == true) {
                                                selectedGameIds.add(gameId);
                                              } else {
                                                selectedGameIds.remove(gameId);
                                              }
                                            });
                                          },
                                          activeColor: efficialsYellow,
                                          checkColor: efficialsBlack,
                                        ),
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
                                                  color: primaryTextColor,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                opponentDisplay != null
                                                    ? '$gameTime $opponentDisplay'
                                                    : '$gameTime - $scheduleName',
                                                style: const TextStyle(
                                                    fontSize: 16,
                                                    color: primaryTextColor),
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
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                  color: secondaryTextColor,
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
      floatingActionButton: hasSelectedGames
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              margin: EdgeInsets.only(
                  bottom: MediaQuery.of(context).padding.bottom + 16),
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _publishSelectedGames,
                style: ElevatedButton.styleFrom(
                  backgroundColor: efficialsYellow,
                  foregroundColor: efficialsBlack,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Publish ${selectedGameIds.length} Game${selectedGameIds.length == 1 ? '' : 's'}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
