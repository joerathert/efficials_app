import 'package:flutter/material.dart';
import '../theme.dart';
import '../services/game_service.dart';
import '../utils/utils.dart';

class LinkedGamesList extends StatefulWidget {
  final List<Map<String, dynamic>> games;
  final Function(Map<String, dynamic>) onGameTap;
  final String? emptyMessage;
  final IconData? emptyIcon;

  const LinkedGamesList({
    super.key,
    required this.games,
    required this.onGameTap,
    this.emptyMessage,
    this.emptyIcon,
  });

  @override
  State<LinkedGamesList> createState() => _LinkedGamesListState();
}

class _LinkedGamesListState extends State<LinkedGamesList> {
  final GameService _gameService = GameService();
  List<Map<String, dynamic>> _processedGames = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _processGamesWithLinkInfo();
  }

  @override
  void didUpdateWidget(LinkedGamesList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.games != widget.games) {
      _processGamesWithLinkInfo();
    }
  }

  Future<void> _processGamesWithLinkInfo() async {
    setState(() => _isLoading = true);
    
    try {
      final gamesWithLinkInfo = <Map<String, dynamic>>[];
      final processedGameIds = <int>{};
      
      for (final game in widget.games) {
        final gameId = game['id'] as int?;
        if (gameId == null || processedGameIds.contains(gameId)) continue;
        
        final gameMap = Map<String, dynamic>.from(game);
        gameMap['isLinked'] = false;
        gameMap['linkedGames'] = <Map<String, dynamic>>[];
        
        // Check if this game is linked to others
        try {
          final isLinked = await _gameService.isGameLinked(gameId);
          if (isLinked) {
            final linkedGames = await _gameService.getLinkedGames(gameId);
            
            // Filter linked games to only include those that are also in our original list
            final linkedGamesInList = <Map<String, dynamic>>[];
            
            for (final linkedGame in linkedGames) {
              final linkedGameId = linkedGame['id'] as int?;
              if (linkedGameId == null) continue;
              
              // Find the corresponding game in our original list
              final originalLinkedGame = widget.games.where(
                (g) => (g['id'] as int?) == linkedGameId,
              );
              
              if (originalLinkedGame.isNotEmpty) {
                linkedGamesInList.add(Map<String, dynamic>.from(originalLinkedGame.first));
                processedGameIds.add(linkedGameId);
              }
            }
            
            if (linkedGamesInList.isNotEmpty) {
              gameMap['isLinked'] = true;
              gameMap['linkedGames'] = linkedGamesInList;
            }
          }
        } catch (e) {
          debugPrint('Error checking if game $gameId is linked: $e');
        }
        
        gamesWithLinkInfo.add(gameMap);
        processedGameIds.add(gameId);
      }
      
      if (mounted) {
        setState(() {
          _processedGames = gamesWithLinkInfo;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error processing games with link info: $e');
      if (mounted) {
        setState(() {
          _processedGames = widget.games;
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: efficialsYellow),
      );
    }

    if (_processedGames.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      itemCount: _processedGames.length,
      itemBuilder: (context, index) {
        final game = _processedGames[index];
        try {
          if (game['isLinked'] == true && 
              game['linkedGames'] != null && 
              (game['linkedGames'] as List).isNotEmpty) {
            return _buildLinkedGamesCard(game);
          } else {
            return _buildRegularGameCard(game);
          }
        } catch (e) {
          debugPrint('Error building game card for game ${game['id']}: $e');
          return _buildRegularGameCard(game);
        }
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            widget.emptyIcon ?? Icons.sports,
            size: 64,
            color: Colors.grey[600],
          ),
          const SizedBox(height: 16),
          Text(
            widget.emptyMessage ?? 'No games available',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLinkedGamesCard(Map<String, dynamic> primaryGame) {
    final linkedGames = primaryGame['linkedGames'] as List<Map<String, dynamic>>;
    if (linkedGames.isEmpty) return _buildRegularGameCard(primaryGame);
    
    final allGames = [primaryGame, ...linkedGames];
    
    // Sort by time if available
    allGames.sort((a, b) {
      final timeA = _getTimeOfDayValue(a, 'time');
      final timeB = _getTimeOfDayValue(b, 'time');
      if (timeA == null && timeB == null) return 0;
      if (timeA == null) return 1;
      if (timeB == null) return -1;
      final minutesA = timeA.hour * 60 + timeA.minute;
      final minutesB = timeB.hour * 60 + timeB.minute;
      return minutesA.compareTo(minutesB);
    });
    
    // For linked games, the same officials work both games
    // So we just need to show the requirement from one game
    final officialsRequired = _getIntValue(primaryGame, 'officialsRequired') ?? 
                             _getIntValue(primaryGame, 'officials_required') ?? 0;
    final officialsHired = _getIntValue(primaryGame, 'officialsHired') ?? 
                          _getIntValue(primaryGame, 'officials_hired') ?? 0;
    final officialsNeeded = officialsRequired - officialsHired;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Stack(
        children: [
          // Two cards stacked with minimal gap and shared border
          Column(
            children: [
              // Top card
              Container(
                decoration: BoxDecoration(
                  color: darkSurface,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                    bottomLeft: Radius.circular(2),
                    bottomRight: Radius.circular(2),
                  ),
                  border: Border.all(color: Colors.orange.withOpacity(0.3), width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      spreadRadius: 1,
                      blurRadius: 3,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: _buildLinkedGameContent(
                  allGames[0], 
                  showNeedBadge: false, 
                  onTap: () => widget.onGameTap(allGames[0])
                ),
              ),
              // Minimal gap
              Container(
                height: 2,
                margin: const EdgeInsets.symmetric(horizontal: 1),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.2),
                ),
              ),
              // Bottom card
              Container(
                decoration: BoxDecoration(
                  color: darkSurface,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(2),
                    topRight: Radius.circular(2),
                    bottomLeft: Radius.circular(12),
                    bottomRight: Radius.circular(12),
                  ),
                  border: Border.all(color: Colors.orange.withOpacity(0.3), width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      spreadRadius: 1,
                      blurRadius: 3,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: _buildLinkedGameContent(
                  allGames[1], 
                  showNeedBadge: false, 
                  onTap: () => widget.onGameTap(allGames[1])
                ),
              ),
            ],
          ),
          // Shared "Need X" badge in top-right
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.orange,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Need $officialsNeeded',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          // Small link indicator in top-left  
          Positioned(
            top: 8,
            left: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: BoxDecoration(
                color: efficialsYellow.withOpacity(0.2),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: efficialsYellow, width: 1),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.link, color: efficialsYellow, size: 8),
                  const SizedBox(width: 2),
                  Text(
                    'Linked',
                    style: const TextStyle(
                      fontSize: 7,
                      color: efficialsYellow,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLinkedGameContent(
    Map<String, dynamic> game, {
    bool showNeedBadge = true, 
    required VoidCallback onTap
  }) {
    final time = _getTimeOfDayValue(game, 'time');
    final officialsRequired = _getIntValue(game, 'officialsRequired') ?? 
                             _getIntValue(game, 'officials_required') ?? 0;
    final officialsHired = _getIntValue(game, 'officialsHired') ?? 
                          _getIntValue(game, 'officials_hired') ?? 0;
    final officialsNeeded = officialsRequired - officialsHired;
    
    String timeText = '';
    if (time != null) {
      final hour = time.hour == 0 ? 12 : (time.hour > 12 ? time.hour - 12 : time.hour);
      final minute = time.minute.toString().padLeft(2, '0');
      final period = time.hour >= 12 ? 'PM' : 'AM';
      timeText = '$hour:$minute $period';
    }

    // Get game details with flexible field names
    final opponent = game['opponent'] ?? 'TBD';
    final homeTeam = game['schedule_home_team_name'] ?? 
                    game['home_team'] ?? 
                    game['homeTeam'] ?? 
                    'Home Team';
    final scheduleName = game['schedule_name'] ?? 
                        game['scheduleName'] ?? 
                        'Unknown Schedule';
    final sportName = game['sport_name'] ?? 
                     game['sport'] ?? 
                     'Unknown';
    final locationName = game['location_name'] ?? 
                        game['location'] ?? 
                        'TBD';
    final isAway = game['is_away'] == 1 || game['isAway'] == true;

    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  getSportIcon(sportName),
                  color: efficialsYellow,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isAway ? '$homeTeam @ $opponent' : '$opponent @ $homeTeam',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: primaryTextColor,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Text(
                            scheduleName,
                            style: const TextStyle(
                              fontSize: 12,
                              color: secondaryTextColor,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                          if (timeText.isNotEmpty) ...[
                            const SizedBox(width: 8),
                            Text(
                              timeText,
                              style: const TextStyle(
                                fontSize: 12,
                                color: efficialsYellow,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                if (showNeedBadge)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orange,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Need $officialsNeeded',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '$officialsHired of $officialsRequired officials confirmed',
              style: const TextStyle(
                fontSize: 12,
                color: secondaryTextColor,
              ),
            ),
            if (locationName != 'TBD') ...[
              const SizedBox(height: 4),
              Text(
                locationName,
                style: const TextStyle(
                  fontSize: 11,
                  color: secondaryTextColor,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRegularGameCard(Map<String, dynamic> game) {
    final date = _getDateTimeValue(game, 'date');
    final time = _getTimeOfDayValue(game, 'time');
    
    // Handle different field name variations across screens
    final officialsRequired = _getIntValue(game, 'officialsRequired') ?? 
                             _getIntValue(game, 'officials_required') ?? 0;
    final officialsHired = _getIntValue(game, 'officialsHired') ?? 
                          _getIntValue(game, 'officials_hired') ?? 0;
    final officialsNeeded = officialsRequired - officialsHired;

    String dateText = 'TBD';
    if (date != null) {
      dateText = '${date.month}/${date.day}/${date.year}';
      if (time != null) {
        final hour = time.hour == 0 ? 12 : (time.hour > 12 ? time.hour - 12 : time.hour);
        final minute = time.minute.toString().padLeft(2, '0');
        final period = time.hour >= 12 ? 'PM' : 'AM';
        final timeText = '$hour:$minute $period';
        dateText += ' at $timeText';
      }
    }

    // Get game details with flexible field names
    final opponent = game['opponent'] ?? 'TBD';
    final homeTeam = game['schedule_home_team_name'] ?? 
                    game['home_team'] ?? 
                    game['homeTeam'] ?? 
                    'Home Team';
    final scheduleName = game['schedule_name'] ?? 
                        game['scheduleName'] ?? 
                        'Unknown Schedule';
    final sportName = game['sport_name'] ?? 
                     game['sport'] ?? 
                     'Unknown';
    final locationName = game['location_name'] ?? 
                        game['location'] ?? 
                        'TBD';
    final isAway = game['is_away'] == 1 || game['isAway'] == true;

    return GestureDetector(
      onTap: () => widget.onGameTap(game),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: darkSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.orange.withOpacity(0.3)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              spreadRadius: 1,
              blurRadius: 3,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  getSportIcon(sportName),
                  color: efficialsYellow,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isAway ? '$homeTeam @ $opponent' : '$opponent @ $homeTeam',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: primaryTextColor,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        scheduleName,
                        style: const TextStyle(
                          fontSize: 12,
                          color: secondaryTextColor,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Need $officialsNeeded',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              dateText,
              style: const TextStyle(
                fontSize: 14,
                color: secondaryTextColor,
              ),
            ),
            if (locationName != 'TBD') ...[
              const SizedBox(height: 4),
              Text(
                locationName,
                style: const TextStyle(
                  fontSize: 14,
                  color: secondaryTextColor,
                ),
              ),
            ],
            const SizedBox(height: 8),
            Text(
              '$officialsHired of $officialsRequired officials confirmed',
              style: const TextStyle(
                fontSize: 12,
                color: secondaryTextColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper function to safely get integer values from different field names
  int? _getIntValue(Map<String, dynamic> map, String key) {
    final value = map[key];
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    if (value is double) return value.toInt();
    return null;
  }

  // Helper function to safely get DateTime values
  DateTime? _getDateTimeValue(Map<String, dynamic> map, String key) {
    final value = map[key];
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (e) {
        debugPrint('Error parsing DateTime from string "$value": $e');
        return null;
      }
    }
    return null;
  }

  // Helper function to safely get TimeOfDay values
  TimeOfDay? _getTimeOfDayValue(Map<String, dynamic> map, String key) {
    final value = map[key];
    if (value == null) return null;
    if (value is TimeOfDay) return value;
    if (value is DateTime) {
      return TimeOfDay.fromDateTime(value);
    }
    if (value is String) {
      try {
        // Try to parse as DateTime first
        final dateTime = DateTime.parse(value);
        return TimeOfDay.fromDateTime(dateTime);
      } catch (e) {
        // Try to parse as time string (e.g., "14:30", "2:30 PM")
        try {
          final timeParts = value.split(':');
          if (timeParts.length >= 2) {
            final hour = int.parse(timeParts[0]);
            final minutePart = timeParts[1].split(' ')[0]; // Remove AM/PM if present
            final minute = int.parse(minutePart);
            return TimeOfDay(hour: hour, minute: minute);
          }
        } catch (e2) {
          debugPrint('Error parsing TimeOfDay from string "$value": $e2');
        }
        return null;
      }
    }
    return null;
  }
}