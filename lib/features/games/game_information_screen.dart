import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../shared/theme.dart';

class GameInformationScreen extends StatefulWidget {
  const GameInformationScreen({super.key});

  @override
  State<GameInformationScreen> createState() => _GameInformationScreenState();
}

class _GameInformationScreenState extends State<GameInformationScreen> {
  late Map<String, dynamic> args;
  late String sport;
  late String scheduleName;
  late String location;
  late DateTime? selectedDate;
  late TimeOfDay? selectedTime;
  late String levelOfCompetition;
  late String gender;
  late int? officialsRequired;
  late String gameFee;
  late bool hireAutomatically;
  late List<Map<String, dynamic>> selectedOfficials;
  late List<Map<String, dynamic>> selectedLists;
  late bool isAwayGame;
  late String opponent;
  late int officialsHired;
  List<Map<String, dynamic>> interestedOfficials = [];
  Map<int, bool> selectedForHire = {};

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final newArgs = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    setState(() {
      args = Map<String, dynamic>.from(newArgs);
      sport = args['sport'] as String? ?? 'Unknown';
      scheduleName = args['scheduleName'] as String? ?? 'Unnamed';
      location = args['location'] as String? ?? 'Not set';
      selectedDate = args['date'] != null
          ? (args['date'] is String ? DateTime.parse(args['date'] as String) : args['date'] as DateTime)
          : null;
      selectedTime = args['time'] != null
          ? (args['time'] is String
              ? () {
                  final timeParts = (args['time'] as String).split(':');
                  return TimeOfDay(
                    hour: int.parse(timeParts[0]),
                    minute: int.parse(timeParts[1]),
                  );
                }()
              : args['time'] as TimeOfDay)
          : null;
      levelOfCompetition = args['levelOfCompetition'] as String? ?? 'Not set';
      gender = args['gender'] as String? ?? 'Not set';
      officialsRequired = args['officialsRequired'] != null ? int.tryParse(args['officialsRequired'].toString()) : null;
      gameFee = args['gameFee']?.toString() ?? 'Not set';
      hireAutomatically = args['hireAutomatically'] as bool? ?? false;
      isAwayGame = args['isAwayGame'] as bool? ?? false;
      opponent = args['opponent'] as String? ?? 'Not set';
      officialsHired = args['officialsHired'] as int? ?? 0;
      try {
        final officialsRaw = args['selectedOfficials'] as List<dynamic>? ?? [];
        selectedOfficials = officialsRaw.map((official) {
          if (official is Map) {
            return Map<String, dynamic>.from(official);
          }
          return <String, dynamic>{'name': 'Unknown Official', 'distance': 0.0};
        }).toList();
      } catch (e) {
        selectedOfficials = [];
      }
      try {
        final listsRaw = args['selectedLists'] as List<dynamic>? ?? [];
        selectedLists = listsRaw.map((list) {
          if (list is Map) {
            return Map<String, dynamic>.from(list);
          }
          return <String, dynamic>{'name': 'Unknown List', 'minOfficials': 0, 'maxOfficials': 0};
        }).toList();
      } catch (e) {
        selectedLists = [];
      }
      if (!isAwayGame && !hireAutomatically && selectedOfficials.isNotEmpty && officialsHired < (officialsRequired ?? 0)) {
        final random = Random();
        final interestCount = random.nextInt(4) + 3;
        final availableOfficials = selectedOfficials
            .where((o) => !selectedOfficials.take(officialsHired).any((h) => h['id'] == o['id']))
            .toList()
          ..shuffle(random);
        interestedOfficials = availableOfficials.take(interestCount.clamp(0, availableOfficials.length)).toList();
        selectedForHire = {};
        for (var official in interestedOfficials) {
          selectedForHire[official['id'] as int] = false;
        }
      } else {
        interestedOfficials = [];
        selectedForHire = {};
      }
    });
  }

  @override
  void initState() {
    super.initState();
    args = {};
    sport = 'Unknown';
    scheduleName = 'Unnamed';
    location = 'Not set';
    selectedDate = null;
    selectedTime = null;
    levelOfCompetition = 'Not set';
    gender = 'Not set';
    officialsRequired = null;
    gameFee = 'Not set';
    hireAutomatically = false;
    selectedOfficials = [];
    selectedLists = [];
    isAwayGame = false;
    opponent = 'Not set';
    officialsHired = 0;
  }

  Future<void> _deleteGame() async {
    final gameId = args['id'];
    if (gameId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: Game ID not found')),
      );
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    
    // Determine which storage key to use based on user role
    final schedulerType = prefs.getString('schedulerType');
    String publishedGamesKey;
    
    switch (schedulerType?.toLowerCase()) {
      case 'coach':
        publishedGamesKey = 'coach_published_games';
        break;
      case 'assigner':
        publishedGamesKey = 'assigner_published_games';
        break;
      case 'athletic director':
      case 'athleticdirector':
      case 'ad':
      default:
        publishedGamesKey = 'ad_published_games';
        break;
    }
    
    
    final String? gamesJson = prefs.getString(publishedGamesKey);
    if (gamesJson != null && gamesJson.isNotEmpty) {
      try {
        List<Map<String, dynamic>> publishedGames = List<Map<String, dynamic>>.from(jsonDecode(gamesJson));
        final initialCount = publishedGames.length;
        publishedGames.removeWhere((game) => game['id'] == gameId);
        final finalCount = publishedGames.length;
        
        await prefs.setString(publishedGamesKey, jsonEncode(publishedGames));
        
        if (initialCount > finalCount) {
          if (mounted) {
            Navigator.pop(context, true);
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Game not found in storage')),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Error deleting game')),
          );
        }
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No games found in storage')),
        );
      }
    }
  }

  Future<void> _createTemplateFromGame() async {
    // Navigate to the create game template screen with the game data pre-filled
    final result = await Navigator.pushNamed(
      context,
      '/create_game_template',
      arguments: {
        'scheduleName': scheduleName,
        'sport': sport,
        'time': selectedTime, // TimeOfDay object
        'location': location,
        'locationData': args['locationData'], // Location details if available
        'levelOfCompetition': levelOfCompetition,
        'gender': gender,
        'officialsRequired': officialsRequired,
        'gameFee': gameFee != 'Not set' ? gameFee : null,
        'hireAutomatically': hireAutomatically,
        'selectedListName': args['selectedListName'] as String?,
        'method': args['method'] as String?,
        'isAway': isAwayGame,
      },
    );

    if (result != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Game template created successfully!')),
      );
    }
  }

  Future<void> _confirmHires() async {
    final selectedCount = selectedForHire.values.where((v) => v).length;
    if (selectedCount == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one official to confirm')),
      );
      return;
    }

    final newTotalHired = officialsHired + selectedCount;
    if (newTotalHired > (officialsRequired ?? 0)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Cannot hire more than $officialsRequired officials')),
      );
      return;
    }

    if (args['method'] == 'advanced' && args['selectedLists'] != null) {
      final listCounts = <String, int>{};
      final selectedIds = selectedForHire.entries.where((e) => e.value).map((e) => e.key).toList();
      final hiredOfficials = interestedOfficials.where((o) => selectedIds.contains(o['id'])).toList();

      final prefs = await SharedPreferences.getInstance();
      final String? listsJson = prefs.getString('saved_lists');
      final List<Map<String, dynamic>> savedListsRaw = listsJson != null && listsJson.isNotEmpty
          ? List<Map<String, dynamic>>.from(jsonDecode(listsJson))
          : [];
      final Map<String, List<Map<String, dynamic>>> savedLists = {
        for (var list in savedListsRaw) list['name'] as String: List<Map<String, dynamic>>.from(list['officials'] ?? [])
      };

      for (var official in hiredOfficials) {
        final listName = (args['selectedLists'] as List<dynamic>)
            .map((list) => Map<String, dynamic>.from(list as Map))
            .firstWhere(
              (list) => (savedLists[list['name']] ?? []).any((o) => o['id'] == official['id']),
              orElse: () => {'name': 'Unknown'},
            )['name'];
        listCounts[listName] = (listCounts[listName] ?? 0) + 1;
      }

      for (var official in selectedOfficials) {
        final listName = (args['selectedLists'] as List<dynamic>)
            .map((list) => Map<String, dynamic>.from(list as Map))
            .firstWhere(
              (list) => (savedLists[list['name']] ?? []).any((o) => o['id'] == official['id']),
              orElse: () => {'name': 'Unknown'},
            )['name'];
        listCounts[listName] = (listCounts[listName] ?? 0) + 1;
      }

      for (var list in (args['selectedLists'] as List<dynamic>).map((list) => Map<String, dynamic>.from(list as Map))) {
        final count = listCounts[list['name']] ?? 0;
        if (count > list['maxOfficials']) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Cannot exceed max (${list['maxOfficials']}) for ${list['name']}')),
            );
          }
          return;
        }
      }
    }

    final hiredIds = selectedForHire.entries.where((e) => e.value).map((e) => e.key).toList();
    final hiredOfficials = interestedOfficials.where((o) => hiredIds.contains(o['id'])).toList();

    setState(() {
      officialsHired += selectedCount;
      args['officialsHired'] = officialsHired;
      selectedOfficials.addAll(hiredOfficials);
      interestedOfficials.removeWhere((o) => hiredIds.contains(o['id']));
      selectedForHire.clear();
      if (officialsHired < (officialsRequired ?? 0)) {
        final random = Random();
        final interestCount = random.nextInt(4) + 3;
        final remainingOfficials = selectedOfficials
            .where((o) => !hiredOfficials.any((h) => h['id'] == o['id']))
            .toList()
          ..shuffle(random);
        interestedOfficials = remainingOfficials.take(interestCount.clamp(0, remainingOfficials.length)).toList();
        for (var official in interestedOfficials) {
          selectedForHire[official['id'] as int] = false;
        }
      }
    });

    final prefs = await SharedPreferences.getInstance();
    
    // Determine which storage key to use based on user role
    final schedulerType = prefs.getString('schedulerType');
    String publishedGamesKey;
    
    switch (schedulerType?.toLowerCase()) {
      case 'coach':
        publishedGamesKey = 'coach_published_games';
        break;
      case 'assigner':
        publishedGamesKey = 'assigner_published_games';
        break;
      case 'athletic director':
      case 'athleticdirector':
      case 'ad':
      default:
        publishedGamesKey = 'ad_published_games';
        break;
    }
    
    final String? gamesJson = prefs.getString(publishedGamesKey);
    if (gamesJson != null && gamesJson.isNotEmpty) {
      List<Map<String, dynamic>> publishedGames = List<Map<String, dynamic>>.from(jsonDecode(gamesJson));
      final index = publishedGames.indexWhere((g) => g['id'] == args['id']);
      if (index != -1) {
        publishedGames[index] = {
          ...publishedGames[index],
          'officialsHired': officialsHired,
          'selectedOfficials': selectedOfficials,
        };
        await prefs.setString(publishedGamesKey, jsonEncode(publishedGames));
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Officials hired successfully!')),
          );
          final returnArgs = {
            ...args,
            'date': selectedDate?.toIso8601String(),
            'time': selectedTime != null ? '${selectedTime!.hour}:${selectedTime!.minute}' : null,
            'officialsRequired': officialsRequired,
            'selectedOfficials': selectedOfficials,
            'selectedLists': selectedLists,
          };
          Navigator.pop(context, returnArgs);
        }
      }
    }
  }

  void _showDeleteConfirmationDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: darkSurface,
        title: const Text('Confirm Delete', 
            style: TextStyle(color: efficialsYellow, fontSize: 20, fontWeight: FontWeight.bold)),
        content: const Text('Are you sure you want to delete this game?',
            style: TextStyle(color: Colors.white)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: efficialsYellow)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteGame();
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Map<String, int> _getSelectedCounts(Map<String, List<Map<String, dynamic>>> savedLists) {
    final listCounts = <String, int>{};
    final selectedIds = selectedForHire.entries.where((e) => e.value).map((e) => e.key).toList();
    final selectedOfficials = interestedOfficials.where((o) => selectedIds.contains(o['id'])).toList();

    for (var official in selectedOfficials) {
      final listName = (args['selectedLists'] as List<dynamic>)
          .map((list) => Map<String, dynamic>.from(list as Map))
          .firstWhere(
            (list) => (savedLists[list['name']] ?? []).any((o) => o['id'] == official['id']),
            orElse: () => {'name': 'Unknown'},
          )['name'];
      listCounts[listName] = (listCounts[listName] ?? 0) + 1;
    }
    return listCounts;
  }

  @override
  Widget build(BuildContext context) {
    final isAdultLevel = levelOfCompetition.toLowerCase() == 'college' || levelOfCompetition.toLowerCase() == 'adult';
    final displayGender = isAdultLevel
        ? {'boys': 'Men', 'girls': 'Women', 'co-ed': 'Co-ed'}[gender.toLowerCase()] ?? gender
        : gender;

    final gameDetails = <String, String>{
      'Sport': sport,
      'Schedule Name': scheduleName,
      'Date': selectedDate != null ? DateFormat('MMMM d, yyyy').format(selectedDate!) : 'Not set',
      'Time': selectedTime != null ? selectedTime!.format(context) : 'Not set',
      'Location': location,
      if (!isAwayGame) ...{
        'Officials Required': officialsRequired?.toString() ?? '0',
        'Fee per Official': gameFee != 'Not set' ? '\$$gameFee' : 'Not set',
        'Gender': displayGender,
        'Competition Level': levelOfCompetition,
        'Hire Automatically': hireAutomatically ? 'Yes' : 'No',
      },
      'Opponent': opponent,
    };

    final requiredOfficials = officialsRequired ?? 0;
    final confirmedOfficials = selectedOfficials
        .take(officialsHired)
        .map((official) => official['name'] as String)
        .toList();

    return Scaffold(
      backgroundColor: darkBackground,
      appBar: AppBar(
        backgroundColor: efficialsBlack,
        title: const Icon(
          Icons.sports,
          color: efficialsYellow,
          size: 32,
        ),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: efficialsWhite),
          onPressed: () {
            final returnArgs = {
              ...args,
              'date': selectedDate?.toIso8601String(),
              'time': selectedTime != null ? '${selectedTime!.hour}:${selectedTime!.minute}' : null,
              'officialsRequired': officialsRequired,
              'selectedOfficials': selectedOfficials,
              'selectedLists': selectedLists,
            };
            Navigator.pop(context, returnArgs);
          },
        ),
      ),
      body: CustomScrollView(
        slivers: [
          SliverPersistentHeader(
            pinned: true,
            delegate: _SliverHeaderDelegate(
              child: Container(
                color: darkSurface,
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Game Details', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: efficialsYellow)),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          onPressed: _createTemplateFromGame,
                          icon: const Icon(Icons.link, color: efficialsYellow),
                          tooltip: 'Create Template from Game',
                        ),
                        TextButton(
                          onPressed: () => Navigator.pushNamed(
                            context,
                            '/edit_game_info',
                            arguments: {
                              ...args,
                              'isEdit': true,
                              'isFromGameInfo': true,
                            },
                          ).then((result) {
                        if (result != null && result is Map<String, dynamic>) {
                          setState(() {
                            args = result;
                            sport = args['sport'] as String? ?? sport;
                            scheduleName = args['scheduleName'] as String? ?? scheduleName;
                            location = args['location'] as String? ?? location;
                            selectedDate = args['date'] != null
                                ? (args['date'] is String ? DateTime.parse(args['date'] as String) : args['date'] as DateTime)
                                : selectedDate;
                            selectedTime = args['time'] != null
                                ? (args['time'] is String
                                    ? () {
                                        final timeParts = (args['time'] as String).split(':');
                                        return TimeOfDay(
                                          hour: int.parse(timeParts[0]),
                                          minute: int.parse(timeParts[1]),
                                        );
                                      }()
                                    : args['time'] as TimeOfDay)
                                : selectedTime;
                            levelOfCompetition = args['levelOfCompetition'] as String? ?? levelOfCompetition;
                            gender = args['gender'] as String? ?? gender;
                            officialsRequired = args['officialsRequired'] != null ? int.tryParse(args['officialsRequired'].toString()) : officialsRequired;
                            gameFee = args['gameFee']?.toString() ?? gameFee;
                            hireAutomatically = args['hireAutomatically'] as bool? ?? hireAutomatically;
                            isAwayGame = args['isAwayGame'] as bool? ?? isAwayGame;
                            opponent = args['opponent'] as String? ?? opponent;
                            officialsHired = args['officialsHired'] as int? ?? officialsHired;
                            try {
                              final officialsRaw = args['selectedOfficials'] as List<dynamic>? ?? [];
                              selectedOfficials = officialsRaw.map((official) {
                                if (official is Map) {
                                  return Map<String, dynamic>.from(official);
                                }
                                return <String, dynamic>{'name': 'Unknown Official', 'distance': 0.0};
                              }).toList();
                            } catch (e) {
                              selectedOfficials = [];
                            }
                            try {
                              final listsRaw = args['selectedLists'] as List<dynamic>? ?? [];
                              selectedLists = listsRaw.map((list) {
                                if (list is Map) {
                                  return Map<String, dynamic>.from(list);
                                }
                                return <String, dynamic>{'name': 'Unknown List', 'minOfficials': 0, 'maxOfficials': 0};
                              }).toList();
                            } catch (e) {
                              selectedLists = [];
                            }
                            if (!isAwayGame && !hireAutomatically && selectedOfficials.isNotEmpty && officialsHired < (officialsRequired ?? 0)) {
                              final random = Random();
                              final interestCount = random.nextInt(4) + 3;
                              final shuffledOfficials = List<Map<String, dynamic>>.from(selectedOfficials)..shuffle(random);
                              interestedOfficials = shuffledOfficials.take(interestCount.clamp(0, selectedOfficials.length)).toList();
                              selectedForHire = {};
                              for (var official in interestedOfficials) {
                                selectedForHire[official['id'] as int] = false;
                              }
                            } else {
                              interestedOfficials = [];
                              selectedForHire = {};
                            }
                          });
                          Navigator.pop(context, result);
                        }
                      }),
                      child: const Text('Edit', style: TextStyle(color: efficialsYellow, fontSize: 18)),
                    ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ...gameDetails.entries.map(
                      (e) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              width: 150,
                              child: Text(
                                '${e.key}:',
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.white),
                              ),
                            ),
                            Expanded(
                              child: e.key == 'Schedule Name' 
                                ? GestureDetector(
                                    onTap: () {
                                      Navigator.pushNamed(
                                        context,
                                        '/assigner_manage_schedules',
                                        arguments: {
                                          'selectedTeam': scheduleName,
                                          'focusDate': selectedDate,
                                        },
                                      );
                                    },
                                    child: Text(
                                      e.value,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        color: efficialsYellow,
                                        decoration: TextDecoration.underline,
                                        decorationColor: efficialsYellow,
                                      ),
                                    ),
                                  )
                                : Text(
                                    e.value,
                                    style: const TextStyle(fontSize: 16, color: Colors.white),
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    if (!isAwayGame) ...[
                      Text(
                        'Confirmed Officials ($officialsHired/$requiredOfficials)',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: efficialsYellow),
                      ),
                      const SizedBox(height: 10),
                      if (confirmedOfficials.isEmpty)
                        const Text('No officials confirmed.', style: TextStyle(fontSize: 16, color: Colors.grey))
                      else
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: confirmedOfficials.map((name) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 2),
                              child: GestureDetector(
                                onTap: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Official profiles not implemented yet')),
                                  );
                                },
                                child: Text(
                                  name,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: efficialsYellow,
                                    decoration: TextDecoration.underline,
                                    decorationColor: efficialsYellow,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      if (!hireAutomatically && officialsHired < requiredOfficials) ...[
                        const SizedBox(height: 20),
                        const Text(
                          'Interested Officials',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: efficialsYellow),
                        ),
                        const SizedBox(height: 10),
                        if (interestedOfficials.isEmpty)
                          const Text('No officials have expressed interest yet.', style: TextStyle(fontSize: 16, color: Colors.grey))
                        else
                          Column(
                            children: interestedOfficials.map((official) {
                              final officialId = official['id'] as int;
                              return CheckboxListTile(
                                title: Text(official['name'] as String, style: const TextStyle(color: Colors.white)),
                                subtitle: Text('Distance: ${(official['distance'] as num?)?.toStringAsFixed(1) ?? '0.0'} mi', style: const TextStyle(color: Colors.grey)),
                                value: selectedForHire[officialId] ?? false,
                                onChanged: (value) {
                                  setState(() {
                                    final currentSelected = selectedForHire.values.where((v) => v).length;
                                    if (value == true && currentSelected < requiredOfficials) {
                                      selectedForHire[officialId] = true;
                                    } else if (value == false) {
                                      selectedForHire[officialId] = false;
                                    }
                                  });
                                },
                                activeColor: efficialsYellow,
                                checkColor: efficialsBlack,
                              );
                            }).toList(),
                          ),
                        if (interestedOfficials.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          Center(
                            child: ElevatedButton(
                              onPressed: _confirmHires,
                              style: elevatedButtonStyle(),
                              child: const Text('Confirm Hire(s)', style: signInButtonTextStyle),
                            ),
                          ),
                        ],
                      ],
                      const SizedBox(height: 20),
                    ],
                    const Text('Selected Officials', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: efficialsYellow)),
                    const SizedBox(height: 10),
                    if (isAwayGame)
                      const Text('No officials needed for away games.', style: TextStyle(fontSize: 16, color: Colors.grey))
                    else if (selectedOfficials.isEmpty)
                      const Text('No officials selected.', style: TextStyle(fontSize: 16, color: Colors.grey))
                    else if (args['method'] == 'advanced' && args['selectedLists'] != null && !hireAutomatically && officialsHired < requiredOfficials) ...[
                      FutureBuilder<Map<String, List<Map<String, dynamic>>>>(
                        future: Future<Map<String, List<Map<String, dynamic>>>>.sync(() async {
                          final prefs = await SharedPreferences.getInstance();
                          final String? listsJson = prefs.getString('saved_lists');
                          final List<Map<String, dynamic>> savedListsRaw = listsJson != null && listsJson.isNotEmpty
                              ? List<Map<String, dynamic>>.from(jsonDecode(listsJson))
                              : [];
                          return {
                            for (var list in savedListsRaw) list['name'] as String: List<Map<String, dynamic>>.from(list['officials'] ?? [])
                          };
                        }),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) {
                            return const CircularProgressIndicator();
                          }
                          final savedLists = snapshot.data!;
                          final selectedCounts = _getSelectedCounts(savedLists);
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: selectedLists.map((list) {
                              final listName = list['name'] as String;
                              final min = list['minOfficials'] as int;
                              final max = list['maxOfficials'] as int;
                              final currentCount = selectedCounts[listName] ?? 0;
                              final textColor = currentCount > max || currentCount < min ? Colors.red : Colors.white;
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4),
                                child: Text(
                                  '$listName: $currentCount/$max selected (min $min, max $max)',
                                  style: TextStyle(fontSize: 16, color: textColor),
                                ),
                              );
                            }).toList(),
                          );
                        },
                      ),
                    ]
                    else if (args['method'] == 'advanced' && args['selectedLists'] != null) ...[
                      ...selectedLists.map(
                        (list) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Text(
                            '${list['name']}: Min ${list['minOfficials']}, Max ${list['maxOfficials']}',
                            style: const TextStyle(fontSize: 16, color: Colors.white),
                          ),
                        ),
                      ),
                    ]
                    else if (args['method'] == 'use_list' && args['selectedListName'] != null) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Text(
                          'List Used: ${args['selectedListName']}',
                          style: const TextStyle(fontSize: 16, color: Colors.white),
                        ),
                      ),
                    ]
                    else ...[
                      ...selectedOfficials.map(
                        (official) => ListTile(
                          title: Text(official['name'] as String, style: const TextStyle(color: Colors.white)),
                          subtitle: Text('Distance: ${(official['distance'] as num?)?.toStringAsFixed(1) ?? '0.0'} mi', style: const TextStyle(color: Colors.grey)),
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                    Center(
                      child: ElevatedButton(
                        onPressed: _showDeleteConfirmationDialog,
                        style: elevatedButtonStyle(backgroundColor: Colors.red),
                        child: const Text('Delete Game', style: signInButtonTextStyle),
                      ),
                    ),
                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SliverHeaderDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;

  _SliverHeaderDelegate({required this.child});

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return child;
  }

  @override
  double get maxExtent => 80;

  @override
  double get minExtent => 80;

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) => true;
}