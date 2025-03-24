import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'theme.dart';

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
  late String officialsRequired;
  late String gameFee;
  late bool hireAutomatically;
  late List<Map<String, dynamic>> selectedOfficials;
  late List<Map<String, dynamic>> selectedLists; // Add this to store safely casted lists

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final newArgs = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    setState(() {
      args = Map<String, dynamic>.from(newArgs);
      sport = args['sport'] as String? ?? 'Unknown';
      scheduleName = args['scheduleName'] as String? ?? 'Unnamed';
      location = args['location'] as String? ?? 'Not set';
      selectedDate = args['date'] as DateTime?;
      selectedTime = args['time'] as TimeOfDay?;
      levelOfCompetition = args['levelOfCompetition'] as String? ?? 'Not set';
      gender = args['gender'] as String? ?? 'Not set';
      officialsRequired = args['officialsRequired'] as String? ?? '0';
      gameFee = args['gameFee'] as String? ?? 'Not set';
      hireAutomatically = args['hireAutomatically'] as bool? ?? false;
      // Safely cast selectedOfficials
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
        print('Error casting selectedOfficials: $e');
      }
      // Safely cast selectedLists
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
        print('Error casting selectedLists: $e');
      }
      print('GameInformationScreen didChangeDependencies - Args: $args');
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
    officialsRequired = '0';
    gameFee = 'Not set';
    hireAutomatically = false;
    selectedOfficials = [];
    selectedLists = [];
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
    final String? gamesJson = prefs.getString('published_games');
    if (gamesJson != null && gamesJson.isNotEmpty) {
      try {
        List<Map<String, dynamic>> publishedGames = List<Map<String, dynamic>>.from(jsonDecode(gamesJson));
        publishedGames.removeWhere((game) => game['id'] == gameId);
        await prefs.setString('published_games', jsonEncode(publishedGames));
        print('Game deleted - ID: $gameId');
        Navigator.pop(context, true); // Return true to indicate deletion
      } catch (e) {
        print('Error deleting game: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error deleting game')),
        );
      }
    }
  }

  void _showDeleteConfirmationDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: const Text('Are you sure you want to delete this game?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: efficialsBlue)),
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

  @override
  Widget build(BuildContext context) {
    final isAdultLevel = levelOfCompetition.toLowerCase() == 'college' || levelOfCompetition.toLowerCase() == 'adult';
    final displayGender = isAdultLevel
        ? {'boys': 'Men', 'girls': 'Women', 'co-ed': 'Co-ed'}[gender.toLowerCase()] ?? gender
        : gender;

    final gameDetails = {
      'Sport': sport,
      'Schedule Name': scheduleName,
      'Date': selectedDate != null ? DateFormat('MMMM d, yyyy').format(selectedDate!) : 'Not set',
      'Time': selectedTime != null ? selectedTime!.format(context) : 'Not set',
      'Location': location,
      'Officials Required': officialsRequired,
      'Game Fee per Official': gameFee != 'Not set' ? '\$$gameFee' : 'Not set',
      'Gender': displayGender,
      'Competition Level': levelOfCompetition,
      'Hire Automatically': hireAutomatically ? 'Yes' : 'No',
    };

    final requiredOfficials = int.parse(officialsRequired);
    final hiredOfficials = args['officialsHired'] as int? ?? 0;
    final confirmedOfficials = selectedOfficials
        .take(hiredOfficials)
        .map((official) => official['name'] as String)
        .toList();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: efficialsBlue,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, size: 36, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Game Information', style: appBarTextStyle),
      ),
      body: CustomScrollView(
        slivers: [
          SliverPersistentHeader(
            pinned: true,
            delegate: _SliverHeaderDelegate(
              child: Container(
                color: Colors.white,
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Game Details', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    TextButton(
                      onPressed: () => Navigator.pushNamed(
                        context,
                        '/edit_game_info',
                        arguments: {
                          ...args,
                          'isEdit': true,
                        },
                      ).then((result) {
                        if (result != null && result is Map<String, dynamic>) {
                          setState(() {
                            args = result;
                            sport = args['sport'] as String? ?? sport;
                            scheduleName = args['scheduleName'] as String? ?? scheduleName;
                            location = args['location'] as String? ?? location;
                            selectedDate = args['date'] as DateTime? ?? selectedDate;
                            selectedTime = args['time'] as TimeOfDay? ?? selectedTime;
                            levelOfCompetition = args['levelOfCompetition'] as String? ?? levelOfCompetition;
                            gender = args['gender'] as String? ?? gender;
                            officialsRequired = args['officialsRequired'] as String? ?? officialsRequired;
                            gameFee = args['gameFee'] as String? ?? gameFee;
                            hireAutomatically = args['hireAutomatically'] as bool? ?? hireAutomatically;
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
                              print('Error casting selectedOfficials after edit: $e');
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
                              print('Error casting selectedLists after edit: $e');
                            }
                            print('GameInformationScreen Edit callback - Updated Args: $args');
                          });
                          Navigator.pop(context, result);
                        }
                      }),
                      child: const Text('Edit', style: TextStyle(color: efficialsBlue, fontSize: 18)),
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
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ...gameDetails.entries.map(
                      (e) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Text('${e.key}: ${e.value}', style: const TextStyle(fontSize: 16)),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Confirmed Officials ($hiredOfficials/$requiredOfficials)',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
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
                                  color: Colors.blue,
                                  decoration: TextDecoration.underline,
                                  decorationColor: Colors.blue,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    const SizedBox(height: 20),
                    const Text('Selected Officials', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    if (selectedOfficials.isEmpty)
                      const Text('No officials selected.', style: TextStyle(fontSize: 16, color: Colors.grey))
                    else if (args['method'] == 'advanced' && args['selectedLists'] != null) ...[
                      ...selectedLists.map(
                        (list) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Text(
                            '${list['name']}: Min ${list['minOfficials']}, Max ${list['maxOfficials']}',
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                      ),
                    ]
                    else if (args['method'] == 'use_list' && args['selectedListName'] != null) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Text(
                          'List Used: ${args['selectedListName']}',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    ]
                    else ...[
                      ...selectedOfficials.map(
                        (official) => ListTile(
                          title: Text(official['name'] as String),
                          subtitle: Text('Distance: ${(official['distance'] as num?)?.toStringAsFixed(1) ?? '0.0'} mi'),
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