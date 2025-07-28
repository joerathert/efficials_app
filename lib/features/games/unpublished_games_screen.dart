import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../shared/theme.dart';
import '../../shared/utils/utils.dart';
import '../../shared/services/game_service.dart';
import '../../shared/services/repositories/user_repository.dart';

class UnpublishedGamesScreen extends StatefulWidget {
  const UnpublishedGamesScreen({super.key});

  @override
  State<UnpublishedGamesScreen> createState() => _UnpublishedGamesScreenState();
}

class _UnpublishedGamesScreenState extends State<UnpublishedGamesScreen> {
  List<Map<String, dynamic>> unpublishedGames = [];
  Set<int> selectedGameIds = {};
  bool isLoading = true;
  String? userRole;
  final GameService _gameService = GameService();
  final UserRepository _userRepository = UserRepository();

  @override
  void initState() {
    super.initState();
    _loadUserRole();
  }

  Future<void> _loadUserRole() async {
    try {
      final user = await _userRepository.getCurrentUser();
      setState(() {
        userRole = user?.schedulerType.toLowerCase() ?? 'ad';
        _fetchUnpublishedGames();
      });
    } catch (e) {
      debugPrint('Error loading user role: $e');
      setState(() {
        userRole = 'ad'; // Default fallback
        _fetchUnpublishedGames();
      });
    }
  }

  Future<void> _fetchUnpublishedGames() async {
    try {
      debugPrint('Fetching unpublished games from database...');
      final games = await _gameService.getUnpublishedGames();
      debugPrint('Retrieved ${games.length} unpublished games from database');
      
      setState(() {
        // Convert Game objects to maps for this screen's existing logic
        unpublishedGames = games.map((game) => {
          'id': game.id,
          'scheduleName': game.scheduleName,
          'sport': game.sportName,
          'date': game.date,
          'time': game.time,
          'location': game.locationName,
          'isAway': game.isAway,
          'levelOfCompetition': game.levelOfCompetition,
          'gender': game.gender,
          'officialsRequired': game.officialsRequired,
          'officialsHired': game.officialsHired,
          'gameFee': game.gameFee,
          'opponent': game.opponent,
          'homeTeam': game.homeTeam,
          'hireAutomatically': game.hireAutomatically,
          'method': game.method,
          'status': game.status,
          'createdAt': game.createdAt,
          'updatedAt': game.updatedAt,
        }).toList();
        
        isLoading = false;
      });
    } catch (e) {
      debugPrint('Error fetching unpublished games from database: $e');
      setState(() {
        unpublishedGames = [];
        isLoading = false;
      });
    }
  }


  Future<void> _deleteGame(int gameId) async {
    try {
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
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to delete game')),
          );
        }
      }
    } catch (e) {
      debugPrint('Error deleting game: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error deleting game')),
        );
      }
    }
  }

  Future<void> _publishSelectedGames() async {
    final gamesToPublish = unpublishedGames
        .where((game) => selectedGameIds.contains(game['id']))
        .toList();
    
    if (gamesToPublish.isEmpty) return;

    try {
      debugPrint('Publishing ${gamesToPublish.length} games to database...');
      final gameIds = gamesToPublish.map((game) => game['id'] as int).toList();
      final success = await _gameService.publishGames(gameIds);
      
      if (success) {
        debugPrint('Successfully published ${gamesToPublish.length} games to database');
        setState(() {
          unpublishedGames.removeWhere((game) => selectedGameIds.contains(game['id']));
          selectedGameIds.clear();
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  '${gamesToPublish.length} game${gamesToPublish.length == 1 ? '' : 's'} published successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to publish games')),
          );
        }
      }
    } catch (e) {
      debugPrint('Error publishing games to database: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error publishing games')),
        );
      }
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
                  if (unpublishedGames.isNotEmpty)
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
