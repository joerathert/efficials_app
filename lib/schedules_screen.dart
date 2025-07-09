import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'theme.dart';

class SchedulesScreen extends StatefulWidget {
  const SchedulesScreen({super.key});

  @override
  State<SchedulesScreen> createState() => _SchedulesScreenState();
}

class _SchedulesScreenState extends State<SchedulesScreen> {
  String? selectedSchedule;
  List<Map<String, dynamic>> schedules = [];
  List<String> scheduleNames = [];
  Map<String, List<Map<String, dynamic>>> groupedSchedules = {};
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSchedules();
  }

  Future<void> _loadSchedules() async {
    final prefs = await SharedPreferences.getInstance();
    final String? unpublishedGamesJson =
        prefs.getString('ad_unpublished_games');
    final String? publishedGamesJson = prefs.getString('ad_published_games');

    Set<String> scheduleNameSet = {};
    List<Map<String, dynamic>> allGames = [];
    Map<String, Set<String>> sportGenders = {}; // Track genders per sport
    Map<String, Map<String, dynamic>> scheduleDetails =
        {}; // Store schedule details

    try {
      if (unpublishedGamesJson != null && unpublishedGamesJson.isNotEmpty) {
        final unpublished =
            List<Map<String, dynamic>>.from(jsonDecode(unpublishedGamesJson));
        allGames.addAll(unpublished);
      }
      if (publishedGamesJson != null && publishedGamesJson.isNotEmpty) {
        final published =
            List<Map<String, dynamic>>.from(jsonDecode(publishedGamesJson));
        allGames.addAll(published);
      }

      // Process games to extract schedule info and track sports/genders
      for (var game in allGames) {
        if (game['scheduleName'] != null) {
          final scheduleName = game['scheduleName'] as String;
          scheduleNameSet.add(scheduleName);

          final sport = game['sport'] as String? ?? 'Unknown';
          final gender = game['gender'] as String? ?? 'Unknown';

          // Track genders per sport (exclude "Unknown" genders from consideration)
          if (!sportGenders.containsKey(sport)) {
            sportGenders[sport] = <String>{};
          }
          if (gender.toLowerCase() != 'unknown') {
            sportGenders[sport]!.add(gender);
          }

          // Store schedule details
          scheduleDetails[scheduleName] = {
            'sport': sport,
            'gender': gender,
            'scheduleName': scheduleName,
          };
        }
      }
    } catch (e) {
      print('Error loading schedules: $e');
    }

    // Group schedules by sport and create display names
    Map<String, List<Map<String, dynamic>>> grouped = {};

    for (var scheduleName in scheduleNameSet) {
      if (scheduleDetails.containsKey(scheduleName)) {
        final details = scheduleDetails[scheduleName]!;
        final sport = details['sport'] as String;
        final gender = details['gender'] as String;

        // Determine if we need to show gender - only if multiple genders exist for this sport
        // (excluding "Unknown" genders from the count)
        final gendersForSport = sportGenders[sport] ?? <String>{};
        final showGender = gendersForSport.length > 1;

        // Create display name
        String displayName;
        if (showGender) {
          // Only show gender prefix when multiple genders exist for the same sport
          final genderDisplay = gender.toLowerCase() == 'boys'
              ? 'Boys'
              : gender.toLowerCase() == 'girls'
                  ? 'Girls'
                  : gender.toLowerCase() == 'men'
                      ? 'Men'
                      : gender.toLowerCase() == 'women'
                          ? 'Women'
                          : gender.toLowerCase() == 'co-ed'
                              ? 'Co-ed'
                              : gender;
          displayName = '$genderDisplay $sport';
        } else {
          // When only one gender exists for this sport, just use the sport name
          displayName = sport;
        }

        if (!grouped.containsKey(displayName)) {
          grouped[displayName] = [];
        }

        grouped[displayName]!.add({
          'scheduleName': scheduleName,
          'sport': sport,
          'gender': gender,
          'displayName': displayName,
        });
      }
    }

    setState(() {
      scheduleNames = scheduleNameSet.toList()..sort();
      groupedSchedules = grouped;
      isLoading = false;
    });
  }

  Future<Map<String, int>> _getGameCounts(String scheduleName) async {
    final prefs = await SharedPreferences.getInstance();
    final String? unpublishedGamesJson =
        prefs.getString('ad_unpublished_games');
    final String? publishedGamesJson = prefs.getString('ad_published_games');

    int published = 0;
    int unpublished = 0;

    try {
      if (unpublishedGamesJson != null && unpublishedGamesJson.isNotEmpty) {
        final unpublishedGames =
            List<Map<String, dynamic>>.from(jsonDecode(unpublishedGamesJson));
        unpublished = unpublishedGames
            .where((game) => game['scheduleName'] == scheduleName)
            .length;
      }
      if (publishedGamesJson != null && publishedGamesJson.isNotEmpty) {
        final publishedGames =
            List<Map<String, dynamic>>.from(jsonDecode(publishedGamesJson));
        published = publishedGames
            .where((game) => game['scheduleName'] == scheduleName)
            .length;
      }
    } catch (e) {
      print('Error getting game counts: $e');
    }

    return {'published': published, 'unpublished': unpublished};
  }

  Future<Map<String, int>> _getGroupGameCounts(
      List<Map<String, dynamic>> schedules) async {
    int totalPublished = 0;
    int totalUnpublished = 0;

    for (var schedule in schedules) {
      final counts = await _getGameCounts(schedule['scheduleName'] as String);
      totalPublished += counts['published']!;
      totalUnpublished += counts['unpublished']!;
    }

    return {'published': totalPublished, 'unpublished': totalUnpublished};
  }

  Future<void> _deleteSchedule(String scheduleName, int scheduleId) async {
    final prefs = await SharedPreferences.getInstance();
    final String? unpublishedGamesJson =
        prefs.getString('ad_unpublished_games');
    final String? publishedGamesJson = prefs.getString('ad_published_games');

    List<Map<String, dynamic>> unpublishedGames = [];
    List<Map<String, dynamic>> publishedGames = [];

    if (unpublishedGamesJson != null && unpublishedGamesJson.isNotEmpty) {
      unpublishedGames =
          List<Map<String, dynamic>>.from(jsonDecode(unpublishedGamesJson));
      unpublishedGames
          .removeWhere((game) => game['scheduleName'] == scheduleName);
      await prefs.setString(
          'ad_unpublished_games', jsonEncode(unpublishedGames));
    }

    if (publishedGamesJson != null && publishedGamesJson.isNotEmpty) {
      publishedGames =
          List<Map<String, dynamic>>.from(jsonDecode(publishedGamesJson));
      publishedGames
          .removeWhere((game) => game['scheduleName'] == scheduleName);
      await prefs.setString('ad_published_games', jsonEncode(publishedGames));
    }

    // Refresh the schedule list
    await _loadSchedules();
  }

  void _showFirstDeleteConfirmationDialog(String scheduleName, int scheduleId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: darkSurface,
        title: const Text('Confirm Delete', style: TextStyle(color: efficialsYellow, fontSize: 20, fontWeight: FontWeight.bold)),
        content: Text('Are you sure you want to delete "$scheduleName"?', style: TextStyle(color: Colors.white)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: efficialsYellow)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _showSecondDeleteConfirmationDialog(scheduleName, scheduleId);
            },
            child: const Text('Delete', style: TextStyle(color: efficialsYellow)),
          ),
        ],
      ),
    );
  }

  void _showSecondDeleteConfirmationDialog(
      String scheduleName, int scheduleId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: darkSurface,
        title: const Text('Final Confirmation', style: TextStyle(color: efficialsYellow, fontSize: 20, fontWeight: FontWeight.bold)),
        content: const Text(
          'Deleting a schedule will erase all games associated with the schedule. Are you sure you want to delete this schedule?',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: efficialsYellow)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deleteSchedule(scheduleName, scheduleId);
              setState(() {
                selectedSchedule =
                    scheduleNames.isNotEmpty ? scheduleNames[0] : null;
              });
            },
            child: const Text('Delete', style: TextStyle(color: efficialsYellow)),
          ),
        ],
      ),
    );
  }

  void _showScheduleSelectionDialog(
      String groupName, List<Map<String, dynamic>> schedules) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: darkSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: efficialsYellow.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.sports,
                color: efficialsYellow,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Select $groupName Schedule',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: primaryTextColor,
                ),
              ),
            ),
          ],
        ),
        contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 400),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: schedules.map((schedule) {
                final scheduleName = schedule['scheduleName'] as String;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.pushNamed(
                          context,
                          '/schedule_details',
                          arguments: {
                            'scheduleName': scheduleName,
                            'scheduleId': scheduleName.hashCode,
                          },
                        ).then((result) {
                          if (result == true) {
                            _loadSchedules();
                          }
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: darkSurface,
                          border:
                              Border.all(color: Colors.grey[700]!, width: 1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: efficialsYellow.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Icon(
                                Icons.schedule,
                                color: efficialsYellow,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                scheduleName,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: primaryTextColor,
                                ),
                              ),
                            ),
                            const Icon(
                              Icons.arrow_forward_ios,
                              color: efficialsYellow,
                              size: 16,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text(
              'Cancel',
              style: TextStyle(
                color: efficialsBlue,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'My Schedules',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: primaryTextColor,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Manage your game schedules',
                style: TextStyle(
                  fontSize: 16,
                  color: secondaryTextColor,
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : groupedSchedules.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.schedule,
                                  size: 80,
                                  color: Colors.grey[400],
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  'No schedules found',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: secondaryTextColor,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Create a game to start your first schedule',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey[500],
                                  ),
                                ),
                                const SizedBox(height: 24),
                                ElevatedButton(
                                  onPressed: () {
                                    Navigator.pushNamed(
                                            context, '/select_sport')
                                        .then((result) {
                                      if (result == true) {
                                        _loadSchedules();
                                      }
                                    });
                                  },
                                  style: elevatedButtonStyle(),
                                  child: const Text('Create New Schedule',
                                      style: signInButtonTextStyle),
                                ),
                              ],
                            ),
                          )
                        : Column(
                            children: [
                              Expanded(
                                child: ListView.builder(
                                  itemCount: groupedSchedules.keys.length,
                                  itemBuilder: (context, index) {
                                    final groupName =
                                        groupedSchedules.keys.elementAt(index);
                                    final schedules =
                                        groupedSchedules[groupName]!;

                                    return FutureBuilder<Map<String, int>>(
                                      future: _getGroupGameCounts(schedules),
                                      builder: (context, snapshot) {
                                        if (!snapshot.hasData) {
                                          return Padding(
                                            padding: const EdgeInsets.only(
                                                bottom: 12.0),
                                            child: Container(
                                              padding: const EdgeInsets.all(16),
                                              decoration: BoxDecoration(
                                                color: darkSurface,
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: Colors.grey
                                                        .withOpacity(0.1),
                                                    spreadRadius: 1,
                                                    blurRadius: 3,
                                                    offset: const Offset(0, 1),
                                                  ),
                                                ],
                                              ),
                                              child: Row(
                                                children: [
                                                  Container(
                                                    padding:
                                                        const EdgeInsets.all(
                                                            12),
                                                    decoration: BoxDecoration(
                                                      color: efficialsBlue
                                                          .withOpacity(0.1),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              8),
                                                    ),
                                                    child: const Icon(
                                                      Icons.sports,
                                                      color: efficialsBlue,
                                                      size: 24,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 16),
                                                  Expanded(
                                                    child: Text(
                                                      groupName,
                                                      style: const TextStyle(
                                                        fontSize: 18,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color: primaryTextColor,
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(
                                                    width: 20,
                                                    height: 20,
                                                    child:
                                                        CircularProgressIndicator(
                                                            strokeWidth: 2),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          );
                                        }

                                        final counts = snapshot.data!;
                                        final publishedGames =
                                            counts['published']!;
                                        final unpublishedGames =
                                            counts['unpublished']!;
                                        final totalGames =
                                            publishedGames + unpublishedGames;

                                        return Padding(
                                          padding: const EdgeInsets.only(
                                              bottom: 12.0),
                                          child: GestureDetector(
                                            onTap: () {
                                              // If there's only one schedule in the group, navigate directly to it
                                              if (schedules.length == 1) {
                                                final scheduleName = schedules
                                                        .first['scheduleName']
                                                    as String;
                                                Navigator.pushNamed(
                                                  context,
                                                  '/schedule_details',
                                                  arguments: {
                                                    'scheduleName':
                                                        scheduleName,
                                                    'scheduleId':
                                                        scheduleName.hashCode,
                                                  },
                                                ).then((result) {
                                                  if (result == true) {
                                                    _loadSchedules();
                                                  }
                                                });
                                              } else {
                                                // Show selection dialog for multiple schedules
                                                _showScheduleSelectionDialog(
                                                    groupName, schedules);
                                              }
                                            },
                                            child: Container(
                                              padding: const EdgeInsets.all(16),
                                              decoration: BoxDecoration(
                                                color: darkSurface,
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: Colors.grey
                                                        .withOpacity(0.1),
                                                    spreadRadius: 1,
                                                    blurRadius: 3,
                                                    offset: const Offset(0, 1),
                                                  ),
                                                ],
                                              ),
                                              child: Row(
                                                children: [
                                                  Container(
                                                    padding:
                                                        const EdgeInsets.all(
                                                            12),
                                                    decoration: BoxDecoration(
                                                      color: efficialsBlue
                                                          .withOpacity(0.1),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              8),
                                                    ),
                                                    child: const Icon(
                                                      Icons.sports,
                                                      color: efficialsBlue,
                                                      size: 24,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 16),
                                                  Expanded(
                                                    child: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        Row(
                                                          children: [
                                                            Text(
                                                              groupName,
                                                              style:
                                                                  const TextStyle(
                                                                fontSize: 18,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                                color:
                                                                    primaryTextColor,
                                                              ),
                                                            ),
                                                            if (schedules
                                                                    .length >
                                                                1) ...[
                                                              const SizedBox(
                                                                  width: 8),
                                                              Container(
                                                                padding: const EdgeInsets
                                                                    .symmetric(
                                                                    horizontal:
                                                                        6,
                                                                    vertical:
                                                                        2),
                                                                decoration:
                                                                    BoxDecoration(
                                                                  color: Colors
                                                                      .grey
                                                                      .withOpacity(
                                                                          0.2),
                                                                  borderRadius:
                                                                      BorderRadius
                                                                          .circular(
                                                                              8),
                                                                ),
                                                                child: Text(
                                                                  '${schedules.length}',
                                                                  style:
                                                                      const TextStyle(
                                                                    fontSize:
                                                                        12,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w600,
                                                                  ),
                                                                ),
                                                              ),
                                                            ],
                                                          ],
                                                        ),
                                                        const SizedBox(
                                                            height: 4),
                                                        Text(
                                                          '$totalGames total games',
                                                          style:
                                                              const TextStyle(
                                                            fontSize: 14,
                                                            color:
                                                                secondaryTextColor,
                                                          ),
                                                        ),
                                                        if (publishedGames >
                                                                0 ||
                                                            unpublishedGames >
                                                                0) ...[
                                                          const SizedBox(
                                                              height: 8),
                                                          Row(
                                                            children: [
                                                              if (publishedGames >
                                                                  0) ...[
                                                                Container(
                                                                  padding: const EdgeInsets
                                                                      .symmetric(
                                                                      horizontal:
                                                                          8,
                                                                      vertical:
                                                                          4),
                                                                  decoration:
                                                                      BoxDecoration(
                                                                    color: Colors
                                                                        .green
                                                                        .withOpacity(
                                                                            0.1),
                                                                    borderRadius:
                                                                        BorderRadius.circular(
                                                                            12),
                                                                  ),
                                                                  child: Text(
                                                                    '$publishedGames published',
                                                                    style:
                                                                        TextStyle(
                                                                      fontSize:
                                                                          12,
                                                                      color: Colors
                                                                          .green
                                                                          .shade700,
                                                                    ),
                                                                  ),
                                                                ),
                                                                if (unpublishedGames >
                                                                    0)
                                                                  const SizedBox(
                                                                      width: 8),
                                                              ],
                                                              if (unpublishedGames >
                                                                  0)
                                                                GestureDetector(
                                                                  onTap: () {
                                                                    Navigator.pushNamed(
                                                                            context,
                                                                            '/unpublished_games')
                                                                        .then(
                                                                            (result) {
                                                                      if (result ==
                                                                          true) {
                                                                        _loadSchedules();
                                                                      }
                                                                    });
                                                                  },
                                                                  child:
                                                                      Container(
                                                                    padding: const EdgeInsets
                                                                        .symmetric(
                                                                        horizontal:
                                                                            8,
                                                                        vertical:
                                                                            4),
                                                                    decoration:
                                                                        BoxDecoration(
                                                                      color: Colors
                                                                          .orange
                                                                          .withOpacity(
                                                                              0.1),
                                                                      borderRadius:
                                                                          BorderRadius.circular(
                                                                              12),
                                                                      border: Border.all(
                                                                          color: Colors.orange.withOpacity(
                                                                              0.3),
                                                                          width:
                                                                              1),
                                                                    ),
                                                                    child: Row(
                                                                      mainAxisSize:
                                                                          MainAxisSize
                                                                              .min,
                                                                      children: [
                                                                        Text(
                                                                          '$unpublishedGames draft',
                                                                          style:
                                                                              TextStyle(
                                                                            fontSize:
                                                                                12,
                                                                            color:
                                                                                Colors.orange.shade700,
                                                                            fontWeight:
                                                                                FontWeight.w600,
                                                                          ),
                                                                        ),
                                                                        const SizedBox(
                                                                            width:
                                                                                4),
                                                                        Icon(
                                                                          Icons
                                                                              .arrow_forward,
                                                                          size:
                                                                              12,
                                                                          color: Colors
                                                                              .orange
                                                                              .shade700,
                                                                        ),
                                                                      ],
                                                                    ),
                                                                  ),
                                                                ),
                                                            ],
                                                          ),
                                                        ],
                                                      ],
                                                    ),
                                                  ),
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
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(height: 16),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: () {
                                    Navigator.pushNamed(
                                            context, '/select_sport')
                                        .then((result) {
                                      if (result == true) {
                                        _loadSchedules();
                                      }
                                    });
                                  },
                                  style: elevatedButtonStyle(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 15),
                                  ),
                                  child: const Text('Create New Schedule',
                                      style: signInButtonTextStyle),
                                ),
                              ),
                            ],
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
