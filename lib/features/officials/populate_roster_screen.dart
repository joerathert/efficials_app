import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import '../../shared/theme.dart';
import '../../shared/services/database_helper.dart';

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
        
        // Hide Save List button when creating a new list during game creation
        // (coming from Use List -> Create New List flow where list name is already provided)
        if (args['fromGameCreation'] == true && args['listName'] != null) {
          showSaveListButton = false;
        }

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
    
    try {
      final db = await DatabaseHelper().database;
      final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>? ?? {'sport': 'Football'};
      final sport = args['sport'] as String? ?? 'Football';
      
      // Get sport_id for the requested sport
      final sportResult = await db.query('sports', where: 'name = ?', whereArgs: [sport]);
      if (sportResult.isEmpty) {
        setState(() {
          officials = [];
          filteredOfficials = [];
          filteredOfficialsWithoutSearch = [];
          isLoading = false;
        });
        return;
      }
      final sportId = sportResult.first['id'] as int;
      
      // Query officials with their sport certifications
      final query = '''
        SELECT DISTINCT 
          o.id,
          o.name,
          o.email,
          o.phone,
          os.certification_level,
          os.years_experience,
          os.competition_levels,
          os.is_primary
        FROM officials o
        JOIN official_sports os ON o.id = os.official_id
        WHERE os.sport_id = ?
      ''';
      
      final results = await db.rawQuery(query, [sportId]);
      
      List<Map<String, dynamic>> newOfficials = results.map((row) {
        // Parse certification level to determine IHSA flags
        final certLevel = row['certification_level'] as String? ?? '';
        final competitionLevels = (row['competition_levels'] as String? ?? '').split(',');
        
        return {
          'id': row['id'],
          'name': row['name'],
          'cityState': 'Chicago, IL', // TODO: Replace with actual address from officials table
          'distance': 10.0 + (row['id'] as int) * 2.5, // TODO: Calculate actual distance
          'yearsExperience': row['years_experience'] ?? 0,
          // Hierarchical IHSA certification flags - higher levels include lower levels
          'ihsaRegistered': certLevel == 'IHSA Registered' || certLevel == 'IHSA Recognized' || certLevel == 'IHSA Certified',
          'ihsaRecognized': certLevel == 'IHSA Recognized' || certLevel == 'IHSA Certified', 
          'ihsaCertified': certLevel == 'IHSA Certified',
          'level': competitionLevels.isNotEmpty ? competitionLevels.first : 'Varsity',
          'competitionLevels': competitionLevels,
          'sports': [sport], // Single sport for this query
        };
      }).toList();
      
      if (filterSettings != null) {
        final locationData = filterSettings!['locationData'] as Map<String, dynamic>?;
        final isAwayGame = args['isAwayGame'] as bool? ?? false;
        Map<String, dynamic>? defaultLocationData = locationData;

        // If no game location is provided, use AD's school address as default
        if (!isAwayGame && locationData == null) {
          try {
            // Get current AD's school address from database
            final adResult = await db.query(
              'users', 
              columns: ['school_address', 'school_name'],
              where: 'scheduler_type = ? AND school_address IS NOT NULL',
              whereArgs: ['athletic_director'],
              limit: 1
            );
            
            if (adResult.isNotEmpty && adResult.first['school_address'] != null) {
              defaultLocationData = {
                'name': adResult.first['school_name'] ?? 'School Location',
                'address': adResult.first['school_address'],
              };
            }
          } catch (e) {
            print('Could not load AD school address: $e');
          }
        }

        if (!isAwayGame && (locationData != null || defaultLocationData != null)) {
          // TODO: Replace with geolocation API call when implemented
          // For now, use hardcoded distances; later, calculate from locationData['address'] or defaultLocationData['address'] to official['address']
        }

        newOfficials = newOfficials.where((official) {
          bool matches = true;
          
          // Check IHSA certifications (hierarchical - higher levels include lower levels)
          final wantsRegistered = filterSettings!['ihsaRegistered'] ?? false;
          final wantsRecognized = filterSettings!['ihsaRecognized'] ?? false;
          final wantsCertified = filterSettings!['ihsaCertified'] ?? false;
          
          final isRegistered = official['ihsaRegistered'] ?? false;
          final isRecognized = official['ihsaRecognized'] ?? false;
          final isCertified = official['ihsaCertified'] ?? false;
          
          // If they want Registered: accept Registered, Recognized, or Certified
          if (wantsRegistered && !(isRegistered || isRecognized || isCertified)) {
            matches = false;
          }
          
          // If they want Recognized: accept Recognized or Certified (not just Registered)
          if (wantsRecognized && !(isRecognized || isCertified)) {
            matches = false;
          }
          
          // If they want Certified: only accept Certified
          if (wantsCertified && !isCertified) {
            matches = false;
          }
          
          // Check minimum years experience
          if ((filterSettings!['minYears'] ?? 0) > (official['yearsExperience'] ?? 0)) {
            matches = false;
          }
          
          // Check competition levels - official must match at least one selected level
          final selectedLevels = filterSettings!['levels'] as List<String>? ?? [];
          if (selectedLevels.isNotEmpty) {
            final officialLevels = official['competitionLevels'] as List<String>? ?? [];
            bool hasMatchingLevel = false;
            for (String level in selectedLevels) {
              if (officialLevels.contains(level)) {
                hasMatchingLevel = true;
                break;
              }
            }
            if (!hasMatchingLevel) {
              matches = false;
            }
          }
          
          // Check distance radius
          if (!isAwayGame &&
              filterSettings!['radius'] != null &&
              filterSettings!['radius'] < (official['distance'] ?? double.infinity)) {
            matches = false;
          }
          
          return matches;
        }).toList();
      }
      
      setState(() {
        // Replace officials with the filtered results
        officials = List.from(newOfficials);
        filteredOfficials = List.from(newOfficials);
        filteredOfficialsWithoutSearch = List.from(newOfficials);
        isLoading = false;
      });
      
    } catch (e) {
      print('Error loading officials: $e');
      setState(() {
        officials = [];
        filteredOfficials = [];
        filteredOfficialsWithoutSearch = [];
        isLoading = false;
      });
    }
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
    final sport = args['sport'] as String? ?? 'Football';

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
                  .map((list) => (list['id'] as int?) ?? 0)
                  .reduce((a, b) => a > b ? a : b) +
              1),
    };

    if (existingLists.any((list) => list['name'] == name)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('A list with this name already exists!')),
        );
      }
      return;
    }

    existingLists.add(newList);
    await prefs.setString('saved_lists', jsonEncode(existingLists));

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('List created!'), duration: Duration(seconds: 2)),
      );
    }
    setState(() => showSaveListButton = false);
  }

  @override
  Widget build(BuildContext context) {
    final args =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    final sport = args['sport'] as String? ?? 'Football';
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
                                    return OfficialListItem(
                                      key: ValueKey(officialId),
                                      official: official,
                                      isSelected: selectedOfficials[officialId] ?? false,
                                      onToggleSelection: () {
                                        setState(() {
                                          selectedOfficials[officialId] =
                                              !(selectedOfficials[officialId] ?? false);
                                          if (selectedOfficials[officialId] == false) {
                                            selectedOfficials.remove(officialId);
                                          }
                                        });
                                      },
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
                                // Determine the correct route based on the flow:
                                // - If creating a new list during game creation (fromGameCreation=true + listName provided) -> review_list
                                // - If using standard method from game creation (method=standard) -> review_game_info
                                // - Otherwise -> review_list
                                String targetRoute;
                                if (args['fromGameCreation'] == true && args['listName'] != null) {
                                  // Creating a new list during game creation flow
                                  targetRoute = '/review_list';
                                } else if (args['method'] == 'standard') {
                                  // Standard method from select officials screen
                                  targetRoute = '/review_game_info';
                                } else {
                                  // Default to review list
                                  targetRoute = '/review_list';
                                }
                                
                                final result = await Navigator.pushNamed(
                                  context,
                                  targetRoute,
                                  arguments: updatedArgs,
                                );
                                
                                // If we got a result, pop back with it
                                if (result != null && mounted) {
                                  // ignore: use_build_context_synchronously
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

// Optimized list item widget with const constructor and ValueKey
class OfficialListItem extends StatelessWidget {
  final Map<String, dynamic> official;
  final bool isSelected;
  final VoidCallback onToggleSelection;

  const OfficialListItem({
    required Key key,
    required this.official,
    required this.isSelected,
    required this.onToggleSelection,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: IconButton(
        icon: Icon(
          isSelected ? Icons.check_circle : Icons.add_circle,
          color: isSelected ? Colors.green : efficialsBlue,
          size: 36,
        ),
        onPressed: onToggleSelection,
      ),
      title: Text(
        '${official['name']} (${official['cityState'] ?? 'Unknown'})',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        'Distance: ${official['distance']?.toStringAsFixed(1) ?? '0.0'} mi, Experience: ${official['yearsExperience'] ?? 0} yrs',
        style: const TextStyle(
          color: Colors.grey,
          fontSize: 14,
        ),
      ),
    );
  }
}
