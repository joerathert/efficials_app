import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'theme.dart';

class PopulateRosterScreen extends StatefulWidget {
  const PopulateRosterScreen({super.key});

  @override
  State<PopulateRosterScreen> createState() => _PopulateRosterScreenState();
}

class _PopulateRosterScreenState extends State<PopulateRosterScreen> {
  String searchQuery = '';
  List<Map<String, dynamic>> officials = [];
  List<Map<String, dynamic>> filteredOfficials = [];
  List<Map<String, dynamic>> filteredOfficialsWithoutSearch = [];
  bool filtersApplied = false;
  bool isLoading = false;
  Map<int, bool> selectedOfficials = {};
  Map<String, dynamic>? filterSettings;
  List<Map<String, dynamic>> initialOfficials = [];
  bool isInitialized = false;
  bool showSaveListButton = true;
  bool isFromGameCreation = false;
  bool isEdit = false;
  bool isNavigating = false;
  final TextEditingController _listNameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    selectedOfficials = {};
    initialOfficials = [];
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!isInitialized) {
      final args =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (args != null) {
        initialOfficials =
            (args['selectedOfficials'] as List<dynamic>?)?.map((item) {
                  return Map<String, dynamic>.from(item as Map);
                }).toList() ??
                [];
        isFromGameCreation = args['method'] == 'standard' || args['fromGameCreation'] == true;
        isEdit = args['isEdit'] == true;

        for (var official in initialOfficials) {
          final officialId = official['id'];
          if (officialId is int) {
            selectedOfficials[officialId] = true;
          } else {
            official['id'] = DateTime.now().millisecondsSinceEpoch +
                initialOfficials.indexOf(official);
            selectedOfficials[official['id'] as int] = true;
          }
        }

        if (initialOfficials.isNotEmpty) {
          officials = List.from(initialOfficials);
          filteredOfficials = List.from(initialOfficials);
          filteredOfficialsWithoutSearch = List.from(initialOfficials);
          filtersApplied = true;
        }
      }
      isInitialized = true;
      if (initialOfficials.isEmpty) {
        _loadOfficials();
      }
    }
  }

  Future<void> _loadOfficials() async {
    setState(() => isLoading = true);
    // Placeholder for real official data with addresses
    List<Map<String, dynamic>> newOfficials = [
      {
        'id': 1,
        'name': 'John Doe',
        'cityState': 'Chicago, IL',
        'distance': 5.2,
        'yearsExperience': 10,
        'ihsaRegistered': true,
        'ihsaRecognized': false,
        'ihsaCertified': false,
        'level': 'Varsity',
        'sports': ['Football', 'Basketball']
      },
      {
        'id': 2,
        'name': 'Jane Smith',
        'cityState': 'Naperville, IL',
        'distance': 15.7,
        'yearsExperience': 8,
        'ihsaRegistered': false,
        'ihsaRecognized': true,
        'ihsaCertified': false,
        'level': 'Varsity',
        'sports': ['Basketball', 'Soccer']
      },
      {
        'id': 3,
        'name': 'Mike Johnson',
        'cityState': 'Aurora, IL',
        'distance': 10.0,
        'yearsExperience': 12,
        'ihsaRegistered': true,
        'ihsaRecognized': true,
        'ihsaCertified': true,
        'level': 'Varsity',
        'sports': ['Football', 'Baseball']
      },
      {
        'id': 4,
        'name': 'Sarah Lee',
        'cityState': 'Evanston, IL',
        'distance': 8.5,
        'yearsExperience': 6,
        'ihsaRegistered': true,
        'ihsaRecognized': false,
        'ihsaCertified': false,
        'level': 'Varsity',
        'sports': ['Soccer', 'Volleyball']
      },
      {
        'id': 5,
        'name': 'Tom Brown',
        'cityState': 'Joliet, IL',
        'distance': 20.1,
        'yearsExperience': 15,
        'ihsaRegistered': false,
        'ihsaRecognized': true,
        'ihsaCertified': true,
        'level': 'Varsity',
        'sports': ['Football', 'Basketball']
      },
      {
        'id': 6,
        'name': 'Emily Davis',
        'cityState': 'Schaumburg, IL',
        'distance': 12.3,
        'yearsExperience': 9,
        'ihsaRegistered': true,
        'ihsaRecognized': false,
        'ihsaCertified': false,
        'level': 'Varsity',
        'sports': ['Baseball', 'Soccer']
      },
      {
        'id': 7,
        'name': 'Chris Wilson',
        'cityState': 'Peoria, IL',
        'distance': 25.0,
        'yearsExperience': 11,
        'ihsaRegistered': false,
        'ihsaRecognized': true,
        'ihsaCertified': false,
        'level': 'Varsity',
        'sports': ['Basketball', 'Volleyball']
      },
      {
        'id': 8,
        'name': 'Lisa Adams',
        'cityState': 'Rockford, IL',
        'distance': 30.2,
        'yearsExperience': 7,
        'ihsaRegistered': true,
        'ihsaRecognized': true,
        'ihsaCertified': false,
        'level': 'Varsity',
        'sports': ['Football', 'Soccer']
      },
      {
        'id': 9,
        'name': 'David Kim',
        'cityState': 'Springfield, IL',
        'distance': 18.9,
        'yearsExperience': 13,
        'ihsaRegistered': false,
        'ihsaRecognized': false,
        'ihsaCertified': true,
        'level': 'Varsity',
        'sports': ['Baseball', 'Basketball']
      },
      {
        'id': 10,
        'name': 'Rachel Patel',
        'cityState': 'Elgin, IL',
        'distance': 14.6,
        'yearsExperience': 5,
        'ihsaRegistered': true,
        'ihsaRecognized': false,
        'ihsaCertified': false,
        'level': 'Varsity',
        'sports': ['Volleyball', 'Football']
      },
    ];

    if (filterSettings != null) {
      final args =
          ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>? ??
              {'sport': 'Football'};
      final sport = args['sport'] as String? ?? 'Football';
      final locationData =
          filterSettings!['locationData'] as Map<String, dynamic>?;
      final isAwayGame = args['isAwayGame'] as bool? ?? false;

      if (!isAwayGame && locationData != null) {
        // TODO: Replace with geolocation API call when implemented
        // For now, use hardcoded distances; later, calculate from locationData['address'] to official['address']
      }

      newOfficials = newOfficials.where((official) {
        bool matches = true;
        if (filterSettings!['ihsaRegistered'] &&
            !(official['ihsaRegistered'] ?? false)) {
          matches = false;
        }
        if (filterSettings!['ihsaRecognized'] &&
            !(official['ihsaRecognized'] ?? false)) {
          matches = false;
        }
        if (filterSettings!['ihsaCertified'] &&
            !(official['ihsaCertified'] ?? false)) {
          matches = false;
        }
        if (filterSettings!['minYears'] > (official['yearsExperience'] ?? 0)) {
          matches = false;
        }
        if (filterSettings!['levels'].isNotEmpty &&
            !filterSettings!['levels'].contains(official['level'])) {
          matches = false;
        }
        if (!isAwayGame &&
            filterSettings!['radius'] != null &&
            filterSettings!['radius'] <
                (official['distance'] ?? double.infinity)) {
          matches = false;
        }
        if (!(official['sports'] as List).contains(sport)) matches = false;
        return matches;
      }).toList();
    }

    setState(() {
      for (var newOfficial in newOfficials) {
        if (!officials.any((o) => o['id'] == newOfficial['id'])) {
          officials.add(newOfficial);
        }
      }
      filteredOfficials = List.from(officials);
      filteredOfficialsWithoutSearch = List.from(officials);
      isLoading = false;
    });
  }

  void _applyFiltersWithSettings(Map<String, dynamic> settings) {
    setState(() {
      filterSettings = settings;
      filtersApplied = true;
      _loadOfficials();
    });
  }

  void filterOfficials(String query) {
    setState(() {
      searchQuery = query;
      if (filtersApplied) {
        filteredOfficials = List.from(filteredOfficialsWithoutSearch);
        if (query.isNotEmpty) {
          filteredOfficials = filteredOfficials
              .where((o) => o['name']
                  .toString()
                  .toLowerCase()
                  .contains(query.toLowerCase()))
              .toList();
        }
      }
    });
  }

  void _promptSaveList() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: darkSurface,
        title: const Text('Name Your List', 
            style: TextStyle(color: efficialsYellow, fontSize: 20, fontWeight: FontWeight.bold)),
        content: TextField(
          controller: _listNameController,
          decoration: textFieldDecoration('List Name'),
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: efficialsYellow)),
          ),
          TextButton(
            onPressed: () {
              final name = _listNameController.text.trim();
              if (name.isNotEmpty) {
                Navigator.pop(context);
                _saveList(name);
              }
            },
            child: const Text('Save', style: TextStyle(color: efficialsYellow)),
          ),
        ],
      ),
    );
  }

  void _saveList(String name) async {
    final selected =
        officials.where((o) => selectedOfficials[o['id']] ?? false).toList();
    final args =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    final sport = args['sport'] as String;

    final prefs = await SharedPreferences.getInstance();
    final String? listsJson = prefs.getString('saved_lists');
    List<Map<String, dynamic>> existingLists = [];
    if (listsJson != null && listsJson.isNotEmpty) {
      existingLists = List<Map<String, dynamic>>.from(jsonDecode(listsJson));
    }

    final newList = {
      'name': name,
      'sport': sport,
      'officials': selected,
      'id': existingLists.isEmpty
          ? 1
          : (existingLists
                  .map((list) => list['id'] as int)
                  .reduce((a, b) => a > b ? a : b) +
              1),
    };

    if (existingLists.any((list) => list['name'] == name)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('A list with this name already exists!')),
      );
      return;
    }

    existingLists.add(newList);
    await prefs.setString('saved_lists', jsonEncode(existingLists));

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('List created!'), duration: Duration(seconds: 2)),
    );
    setState(() => showSaveListButton = false);
  }

  @override
  Widget build(BuildContext context) {
    final args =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    final sport = args['sport'] as String;
    final listName = args['listName'] as String?;
    final int selectedCount =
        selectedOfficials.values.where((selected) => selected).length;

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
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          if (isLoading) ...[
            const Expanded(child: Center(child: CircularProgressIndicator())),
          ] else if (!filtersApplied && initialOfficials.isEmpty) ...[
            const Expanded(
              child: Center(
                child: Text(
                  'Apply filters to populate the roster.',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ] else ...[
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: TextField(
                  decoration: textFieldDecoration('Search Officials'),
                  style: const TextStyle(fontSize: 18),
                  onChanged: filterOfficials,
                ),
              ),
            ),
            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: filteredOfficials.isEmpty
                        ? const Center(
                            child: Text('No officials found.',
                                style: TextStyle(
                                    fontSize: 18, color: Colors.grey)))
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Checkbox(
                                    value: filteredOfficials.every((o) {
                                      final officialId = o['id'];
                                      return officialId is int &&
                                          (selectedOfficials[officialId] ??
                                              false);
                                    }),
                                    onChanged: (value) {
                                      setState(() {
                                        if (value == true) {
                                          for (final o in filteredOfficials) {
                                            final officialId = o['id'];
                                            if (officialId is int) {
                                              selectedOfficials[officialId] =
                                                  true;
                                            }
                                          }
                                        } else {
                                          for (final o in filteredOfficials) {
                                            final officialId = o['id'];
                                            if (officialId is int) {
                                              selectedOfficials
                                                  .remove(officialId);
                                            }
                                          }
                                        }
                                      });
                                    },
                                    activeColor: Colors.green,
                                    checkColor: Colors.black,
                                  ),
                                  const Text('Select all',
                                      style: TextStyle(fontSize: 18)),
                                ],
                              ),
                              Expanded(
                                child: ListView.builder(
                                  itemCount: filteredOfficials.length,
                                  itemBuilder: (context, index) {
                                    final official = filteredOfficials[index];
                                    final officialId = official['id'];
                                    if (officialId == null ||
                                        officialId is! int) {
                                      return const SizedBox.shrink();
                                    }
                                    return ListTile(
                                      leading: IconButton(
                                        icon: Icon(
                                          selectedOfficials[officialId] ?? false
                                              ? Icons.check_circle
                                              : Icons.add_circle,
                                          color:
                                              selectedOfficials[officialId] ??
                                                      false
                                                  ? Colors.green
                                                  : efficialsBlue,
                                          size: 36,
                                        ),
                                        onPressed: () {
                                          setState(() {
                                            selectedOfficials[officialId] =
                                                !(selectedOfficials[
                                                        officialId] ??
                                                    false);
                                            if (selectedOfficials[officialId] ==
                                                false) {
                                              selectedOfficials
                                                  .remove(officialId);
                                            }
                                          });
                                        },
                                      ),
                                      title: Text(
                                          '${official['name']} (${official['cityState'] ?? 'Unknown'})',
                                          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500)),
                                      subtitle: Text(
                                        'Distance: ${official['distance']?.toStringAsFixed(1) ?? '0.0'} mi, Experience: ${official['yearsExperience'] ?? 0} yrs',
                                        style: const TextStyle(color: Colors.grey, fontSize: 14),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
      floatingActionButton: Padding(
        padding: filtersApplied
            ? const EdgeInsets.only(bottom: 0)
            : const EdgeInsets.only(bottom: 106),
        child: FloatingActionButton(
          onPressed: () =>
              Navigator.pushNamed(context, '/filter_settings', arguments: args)
                  .then((result) {
            if (result != null) {
              _loadOfficials().then((_) =>
                  _applyFiltersWithSettings(result as Map<String, dynamic>));
            }
          }),
          backgroundColor: Colors.grey[600],
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: const Icon(Icons.filter_list, size: 30, color: efficialsYellow),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: filtersApplied || initialOfficials.isNotEmpty
          ? Container(
              color: efficialsBlack,
              padding: EdgeInsets.only(
                left: 32,
                right: 32,
                top: 32,
                bottom: MediaQuery.of(context).padding.bottom + 32,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('($selectedCount) Selected',
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: 250,
                    child: ElevatedButton(
                      onPressed: selectedCount > 0 && !isNavigating
                          ? () async {
                              if (isNavigating) return;
                              
                              setState(() {
                                isNavigating = true;
                              });
                              
                              final selected = officials.where((o) {
                                final officialId = o['id'];
                                return officialId is int &&
                                    (selectedOfficials[officialId] ?? false);
                              }).toList();
                              final updatedArgs = {
                                ...args,
                                'selectedOfficials': selected,
                                'isEdit': isEdit, // Preserve the isEdit flag
                                'isFromGameInfo':
                                    isFromGameCreation, // Preserve the game creation context
                                'listId': args['listId'], // Preserve the listId
                                'listName':
                                    args['listName'], // Preserve the listName
                              };
                              
                              try {
                                final result = await Navigator.pushNamed(
                                  context,
                                  isFromGameCreation
                                      ? '/review_game_info'
                                      : '/review_list',
                                  arguments: updatedArgs,
                                );
                                
                                // If we got a result, pop back with it
                                if (result != null && mounted) {
                                  Navigator.pop(context, result);
                                }
                              } finally {
                                if (mounted) {
                                  setState(() {
                                    isNavigating = false;
                                  });
                                }
                              }
                            }
                          : null,
                      style: elevatedButtonStyle(),
                      child: isNavigating 
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text('Continue', style: signInButtonTextStyle),
                    ),
                  ),
                  if (isFromGameCreation && showSaveListButton) ...[
                    const SizedBox(height: 8),
                    SizedBox(
                      width: 250,
                      child: ElevatedButton(
                        onPressed: selectedCount > 0 ? _promptSaveList : null,
                        style: elevatedButtonStyle(),
                        child:
                            const Text('Save List', style: signInButtonTextStyle),
                      ),
                    ),
                  ],
                ],
              ),
            )
          : null,
    );
  }

  @override
  void dispose() {
    _listNameController.dispose();
    super.dispose();
  }
}
