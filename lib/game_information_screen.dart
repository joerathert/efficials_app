import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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
    final confirmedOfficials = (args['selectedOfficials'] as List<dynamic>? ?? [])
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
                          'isEdit': true, // Pass isEdit flag
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
                            print('GameInformationScreen Edit callback - Updated Args: $args');
                          });
                          Navigator.pop(context, result); // Return updated args to HomeScreen
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
                                // Placeholder for future official profile linking
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
                    if (args['selectedOfficials'] == null || (args['selectedOfficials'] as List).isEmpty)
                      const Text('No officials selected.', style: TextStyle(fontSize: 16, color: Colors.grey))
                    else if (args['method'] == 'advanced' && args['selectedLists'] != null) ...[
                      ...((args['selectedLists'] as List<Map<String, dynamic>>).map(
                        (list) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Text(
                            '${list['name']}: Min ${list['minOfficials']}, Max ${list['maxOfficials']}',
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                      )),
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
                      ...((args['selectedOfficials'] as List<Map<String, dynamic>>).map(
                        (official) => ListTile(
                          title: Text(official['name'] as String),
                          subtitle: Text('Distance: ${(official['distance'] as num?)?.toStringAsFixed(1) ?? '0.0'} mi'),
                        ),
                      )),
                    ],
                    const SizedBox(height: 100),
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