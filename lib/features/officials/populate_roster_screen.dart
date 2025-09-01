import 'package:flutter/material.dart';
import '../../shared/theme.dart';
import '../../shared/services/repositories/official_repository.dart';
import '../../shared/services/repositories/list_repository.dart';
import '../../shared/models/database_models.dart';

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

  // Map specific age groups to their broader categories for official matching
  final Map<String, List<String>> ageGroupToCategoryMapping = {
    '6U': ['Grade School'],
    '7U': ['Grade School'],
    '8U': ['Grade School'],
    '9U': ['Grade School'],
    '10U': ['Grade School'],
    '11U': ['Grade School', 'Middle School'],
    '12U': ['Middle School'],
    '13U': ['Middle School'],
    '14U': ['Middle School'],
    '15U': ['Underclass'],
    '16U': ['Underclass', 'JV'],
    '17U': ['JV', 'Varsity'],
    '18U': ['Varsity'],
    'Grade School': ['Grade School'],
    'Middle School': ['Middle School'],
    'Underclass': ['Underclass'],
    'JV': ['JV'],
    'Varsity': ['Varsity'],
    'College': ['College'],
    'Adult': ['Adult'],
  };

  String _getLastName(String fullName) {
    final parts = fullName.trim().split(' ');
    return parts.isNotEmpty ? parts.last : fullName;
  }

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
        isFromGameCreation =
            args['method'] == 'standard' || args['fromGameCreation'] == true;
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
      final officialRepository = OfficialRepository();
      final args =
          ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>? ??
              {'sport': 'Football'};
      final sport = args['sport'] as String? ?? 'Football';

      // Get sport_id for the requested sport
      print('🏈 SPORT DEBUG: Looking for sport: $sport');
      final sportResult = await officialRepository
          .rawQuery('SELECT id FROM sports WHERE name = ?', [sport]);
      print(
          '🏈 SPORT DEBUG: Found ${sportResult.length} sports matching "$sport"');
      if (sportResult.isEmpty) {
        print('❌ SPORT DEBUG: No sport found with name "$sport"');
        // Let's see what sports exist
        final allSports = await officialRepository
            .rawQuery('SELECT id, name FROM sports ORDER BY name');
        print('📊 All available sports:');
        for (final s in allSports) {
          print('  - ${s['id']}: ${s['name']}');
        }
        setState(() {
          officials = [];
          filteredOfficials = [];
          filteredOfficialsWithoutSearch = [];
          isLoading = false;
        });
        return;
      }
      final sportId = sportResult.first['id'] as int;
      print('🏈 SPORT DEBUG: Using sport_id: $sportId for sport: $sport');

      // Use the repository method with filters
      List<Map<String, dynamic>> newOfficials = await officialRepository
          .getOfficialsBySport(sportId, filters: filterSettings);

      // Apply additional distance filtering for away games if needed
      if (filterSettings != null) {
        final isAwayGame = args['isAwayGame'] as bool? ?? false;

        if (!isAwayGame && filterSettings!['radius'] != null) {
          newOfficials = newOfficials.where((official) {
            return filterSettings!['radius'] >=
                (official['distance'] ?? double.infinity);
          }).toList();
        }
      }

      setState(() {
        officials = List.from(newOfficials);
        filteredOfficials = List.from(newOfficials);
        filteredOfficialsWithoutSearch = List.from(newOfficials);

        // Sort all lists alphabetically by last name
        officials.sort((a, b) => _getLastName(a['name'].toString())
            .toLowerCase()
            .compareTo(_getLastName(b['name'].toString()).toLowerCase()));
        filteredOfficials.sort((a, b) => _getLastName(a['name'].toString())
            .toLowerCase()
            .compareTo(_getLastName(b['name'].toString()).toLowerCase()));
        filteredOfficialsWithoutSearch.sort((a, b) =>
            _getLastName(a['name'].toString())
                .toLowerCase()
                .compareTo(_getLastName(b['name'].toString()).toLowerCase()));

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
        // Sort alphabetically by last name
        filteredOfficials.sort((a, b) => _getLastName(a['name'].toString())
            .toLowerCase()
            .compareTo(_getLastName(b['name'].toString()).toLowerCase()));
      }
    });
  }

  void _promptSaveList() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: darkSurface,
        title: const Text('Name Your List',
            style: TextStyle(
                color: efficialsYellow,
                fontSize: 20,
                fontWeight: FontWeight.bold)),
        content: TextField(
          controller: _listNameController,
          decoration: textFieldDecoration('List Name'),
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child:
                const Text('Cancel', style: TextStyle(color: efficialsYellow)),
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
    try {
      final selected =
          officials.where((o) => selectedOfficials[o['id']] ?? false).toList();
      final args =
          ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
      final sport = args['sport'] as String? ?? 'Football';

      final listRepository = ListRepository();

      // Check if list name already exists
      final userResult = await listRepository.rawQuery(
          'SELECT id FROM users WHERE scheduler_type IS NOT NULL LIMIT 1');
      if (userResult.isEmpty) {
        throw Exception('No user found');
      }
      final userId = userResult.first['id'] as int;

      final nameExists = await listRepository.listNameExists(name, userId);
      if (nameExists) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('A list with this name already exists!')),
          );
        }
        return;
      }

      // Convert selected officials to Official objects
      final selectedOfficialsObjects = selected
          .map((officialData) => Official(
                id: officialData['id'],
                name: officialData['name'],
                email: officialData['email'],
                phone: officialData['phone'],
                userId: userId, // Required field
              ))
          .toList();

      // Create the list
      await listRepository.createList(name, sport, selectedOfficialsObjects);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('List created!'), duration: Duration(seconds: 2)),
        );
      }
      setState(() => showSaveListButton = false);
    } catch (e) {
      print('Error saving list: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving list: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final args =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
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
                                      isSelected:
                                          selectedOfficials[officialId] ??
                                              false,
                                      onToggleSelection: () {
                                        setState(() {
                                          selectedOfficials[officialId] =
                                              !(selectedOfficials[officialId] ??
                                                  false);
                                          if (selectedOfficials[officialId] ==
                                              false) {
                                            selectedOfficials
                                                .remove(officialId);
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
          child:
              const Icon(Icons.filter_list, size: 30, color: efficialsYellow),
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
                                if (args['fromGameCreation'] == true &&
                                    args['listName'] != null) {
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
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text('Continue',
                              style: signInButtonTextStyle),
                    ),
                  ),
                  if (isFromGameCreation && showSaveListButton) ...[
                    const SizedBox(height: 8),
                    SizedBox(
                      width: 250,
                      child: ElevatedButton(
                        onPressed: selectedCount > 0 ? _promptSaveList : null,
                        style: elevatedButtonStyle(),
                        child: const Text('Save List',
                            style: signInButtonTextStyle),
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
