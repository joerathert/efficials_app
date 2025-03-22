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
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (args != null) {
        initialOfficials = (args['selectedOfficials'] as List<dynamic>?)?.map((item) {
          return Map<String, dynamic>.from(item as Map);
        }).toList() ?? [];
        isFromGameCreation = args['method'] == 'standard';
        isEdit = args['isEdit'] == true;

        // Ensure initialOfficials have valid IDs and populate selectedOfficials
        for (var official in initialOfficials) {
          final officialId = official['id'];
          if (officialId is int) {
            selectedOfficials[officialId] = true;
          } else {
            // If ID is invalid, assign a temporary one to avoid issues
            official['id'] = DateTime.now().millisecondsSinceEpoch + initialOfficials.indexOf(official);
            selectedOfficials[official['id'] as int] = true;
          }
        }

        // Initialize officials lists with initialOfficials if they exist
        if (initialOfficials.isNotEmpty) {
          officials = List.from(initialOfficials);
          filteredOfficials = List.from(initialOfficials);
          filteredOfficialsWithoutSearch = List.from(initialOfficials);
          filtersApplied = true; // Treat as if filters are applied to show the list
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
    List<Map<String, dynamic>> newOfficials = [
      {'id': 1, 'name': 'John Doe', 'cityState': 'Chicago, IL', 'distance': 5.2, 'yearsExperience': 10},
      {'id': 2, 'name': 'Jane Smith', 'cityState': 'Naperville, IL', 'distance': 15.7, 'yearsExperience': 8},
      {'id': 3, 'name': 'Mike Johnson', 'cityState': 'Aurora, IL', 'distance': 10.0, 'yearsExperience': 12},
    ];
    setState(() {
      // Merge new officials with initial officials, avoiding duplicates
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
      _loadOfficials(); // Reload officials with new filters
    });
  }

  void filterOfficials(String query) {
    setState(() {
      searchQuery = query;
      if (filtersApplied) {
        filteredOfficials = List.from(filteredOfficialsWithoutSearch);
        if (query.isNotEmpty) {
          filteredOfficials = filteredOfficials
              .where((o) => o['name'].toString().toLowerCase().contains(query.toLowerCase()))
              .toList();
        }
      }
    });
  }

  void _promptSaveList() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Name Your List'),
        content: TextField(
          controller: _listNameController,
          decoration: textFieldDecoration('List Name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: efficialsBlue)),
          ),
          TextButton(
            onPressed: () {
              final name = _listNameController.text.trim();
              if (name.isNotEmpty) {
                Navigator.pop(context);
                _saveList(name);
              }
            },
            child: const Text('Save', style: TextStyle(color: efficialsBlue)),
          ),
        ],
      ),
    );
  }

  void _saveList(String name) async {
    final selected = officials.where((o) => selectedOfficials[o['id']] ?? false).toList();
    final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    final sport = args['sport'] as String;

    // Save the list to shared_preferences
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
      'id': existingLists.isEmpty ? 1 : (existingLists.map((list) => list['id'] as int).reduce((a, b) => a > b ? a : b) + 1),
    };

    // Check for duplicate names
    if (existingLists.any((list) => list['name'] == name)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('A list with this name already exists!')),
      );
      return;
    }

    existingLists.add(newList);
    await prefs.setString('saved_lists', jsonEncode(existingLists));

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('List created!'), duration: Duration(seconds: 2)),
    );
    setState(() => showSaveListButton = false);
  }

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    final sport = args['sport'] as String;
    final listName = args['listName'] as String;
    final int selectedCount = selectedOfficials.values.where((selected) => selected).length;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: efficialsBlue,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, size: 36, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          isEdit ? 'Edit Selected Officials' : (isFromGameCreation ? 'Select Officials for Game' : 'Find Officials'),
          style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
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
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                        ? const Center(child: Text('No officials found.', style: TextStyle(fontSize: 18, color: Colors.grey)))
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Checkbox(
                                    value: filteredOfficials.every((o) {
                                      final officialId = o['id'];
                                      return officialId is int && (selectedOfficials[officialId] ?? false);
                                    }),
                                    onChanged: (value) {
                                      setState(() {
                                        if (value == true) {
                                          for (final o in filteredOfficials) {
                                            final officialId = o['id'];
                                            if (officialId is int) {
                                              selectedOfficials[officialId] = true;
                                            }
                                          }
                                        } else {
                                          for (final o in filteredOfficials) {
                                            final officialId = o['id'];
                                            if (officialId is int) {
                                              selectedOfficials.remove(officialId);
                                            }
                                          }
                                        }
                                      });
                                    },
                                    activeColor: efficialsBlue,
                                  ),
                                  const Text('Select all', style: TextStyle(fontSize: 18)),
                                ],
                              ),
                              Expanded(
                                child: ListView.builder(
                                  itemCount: filteredOfficials.length,
                                  itemBuilder: (context, index) {
                                    final official = filteredOfficials[index];
                                    final officialId = official['id'];
                                    if (officialId == null || officialId is! int) {
                                      return const SizedBox.shrink(); // Skip invalid entries
                                    }
                                    return ListTile(
                                      leading: IconButton(
                                        icon: Icon(
                                          selectedOfficials[officialId] ?? false ? Icons.check_circle : Icons.add_circle,
                                          color: selectedOfficials[officialId] ?? false ? Colors.green : efficialsBlue,
                                          size: 36,
                                        ),
                                        onPressed: () {
                                          setState(() {
                                            selectedOfficials[officialId] = !(selectedOfficials[officialId] ?? false);
                                            if (selectedOfficials[officialId] == false) selectedOfficials.remove(officialId);
                                          });
                                        },
                                      ),
                                      title: Text('${official['name']} (${official['cityState'] ?? 'Unknown'})'),
                                      subtitle: Text(
                                        'Distance: ${official['distance']?.toStringAsFixed(1) ?? '0.0'} mi, Experience: ${official['yearsExperience'] ?? 0} yrs',
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
        padding: filtersApplied ? const EdgeInsets.only(bottom: 0) : const EdgeInsets.only(bottom: 106),
        child: FloatingActionButton(
          onPressed: () => Navigator.pushNamed(context, '/filter_settings', arguments: sport).then((result) {
            if (result != null) _loadOfficials().then((_) => _applyFiltersWithSettings(result as Map<String, dynamic>));
          }),
          backgroundColor: efficialsBlue,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: const Icon(Icons.filter_list, size: 30, color: Colors.white),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: filtersApplied || initialOfficials.isNotEmpty
          ? Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('($selectedCount) Selected', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: selectedCount > 0
                        ? () {
                            final selected = officials.where((o) {
                              final officialId = o['id'];
                              return officialId is int && (selectedOfficials[officialId] ?? false);
                            }).toList();
                            Navigator.pushNamed(
                              context,
                              isFromGameCreation ? '/review_game_info' : '/review_list',
                              arguments: {...args, 'selectedOfficials': selected},
                            ).then((result) {
                              if (result != null) {
                                Navigator.pop(context, result);
                              }
                            });
                          }
                        : null,
                    style: elevatedButtonStyle(),
                    child: const Text('Continue', style: signInButtonTextStyle),
                  ),
                  if (isFromGameCreation && showSaveListButton) ...[
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: selectedCount > 0 ? _promptSaveList : null,
                      style: elevatedButtonStyle(),
                      child: const Text('Save List', style: signInButtonTextStyle),
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