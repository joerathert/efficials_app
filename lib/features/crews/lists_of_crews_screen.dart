import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../shared/theme.dart';
import '../../shared/utils/utils.dart';

class ListsOfCrewsScreen extends StatefulWidget {
  const ListsOfCrewsScreen({super.key});

  @override
  State<ListsOfCrewsScreen> createState() => _ListsOfCrewsScreenState();
}

class _ListsOfCrewsScreenState extends State<ListsOfCrewsScreen> {
  String? selectedListName;
  List<Map<String, dynamic>> crewLists = [];
  bool isLoading = true;
  bool isFromTemplateCreation = false;

  @override
  void initState() {
    super.initState();
    crewLists = [
      {'name': 'No saved crew lists', 'id': -1},
      {'name': '+ Create new crew list', 'id': 0},
    ];
    _fetchCrewLists();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null) {
      setState(() {
        isFromTemplateCreation = args['fromTemplateCreation'] == true;
      });

      // Handle new list creation from review_crew_list_screen
      if (args['newCrewListCreated'] != null) {
        final newListData = args['newCrewListCreated'] as Map<String, dynamic>;
        _handleNewCrewListFromReview(newListData);
      } else if (crewLists.length <= 2 && crewLists[0]['name'] == 'No saved crew lists') {
        _fetchCrewLists();
      }
    }
  }

  Future<void> _fetchCrewLists() async {
    final prefs = await SharedPreferences.getInstance();
    final String? listsJson = prefs.getString('saved_crew_lists');
    setState(() {
      crewLists.clear();
      if (listsJson != null && listsJson.isNotEmpty) {
        try {
          final decodedLists = jsonDecode(listsJson) as List<dynamic>;
          crewLists = decodedLists.map((list) {
            final listMap = Map<String, dynamic>.from(list as Map);
            if (listMap['crews'] != null) {
              listMap['crews'] = (listMap['crews'] as List<dynamic>)
                  .map((crew) => Map<String, dynamic>.from(crew as Map))
                  .toList();
            } else {
              listMap['crews'] = [];
            }
            return listMap;
          }).toList();
        } catch (e) {
          crewLists = [];
        }
      }
      if (crewLists.isEmpty) {
        crewLists.add({'name': 'No saved crew lists', 'id': -1});
      }
      crewLists.add({'name': '+ Create new crew list', 'id': 0});
      isLoading = false;
    });
  }

  Future<void> _saveCrewLists() async {
    final prefs = await SharedPreferences.getInstance();
    final listsToSave = crewLists.where((list) => list['id'] != 0 && list['id'] != -1).toList();
    await prefs.setString('saved_crew_lists', jsonEncode(listsToSave));
  }

  void _showDeleteConfirmationDialog(String listName, int listId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: darkSurface,
        title: const Text('Confirm Delete', style: TextStyle(color: efficialsWhite)),
        content: Text('Are you sure you want to delete "$listName"?', style: const TextStyle(color: efficialsWhite)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: efficialsYellow)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                crewLists.removeWhere((list) => list['id'] == listId);
                if (crewLists.isEmpty || (crewLists.length == 1 && crewLists[0]['id'] == 0)) {
                  crewLists.insert(0, {'name': 'No saved crew lists', 'id': -1});
                }
                selectedListName = null; // Reset to show hint after deletion
                _saveCrewLists();
              });
            },
            child: const Text('Delete', style: TextStyle(color: efficialsYellow)),
          ),
        ],
      ),
    );
  }

  void _handleContinue() {
    final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
    if (args == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: Game data not found')),
      );
      return;
    }
    final selected = crewLists.firstWhere((l) => l['name'] == selectedListName);
    final crewsRaw = selected['crews'];
    List<Map<String, dynamic>> selectedCrews = [];

    if (crewsRaw != null) {
      if (crewsRaw is List) {
        selectedCrews = (crewsRaw)
            .map((crew) => Map<String, dynamic>.from(crew as Map))
            .toList();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid crew data in the selected list')),
        );
        return;
      }
    }

    final updatedArgs = {
      ...args,
      'selectedCrews': selectedCrews,
      'method': 'hire_crew',
      'selectedCrewListName': selectedListName,
    };

    // Always pop back with the updated arguments
    Navigator.pop(context, updatedArgs);
  }

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final sport = args?['sport'] as String? ?? 'Unknown Sport';
    final fromTemplateCreation = args?['fromTemplateCreation'] == true;

    // Filter out special items for the main list display
    List<Map<String, dynamic>> actualCrewLists = 
        crewLists.where((list) => list['id'] != 0 && list['id'] != -1).toList();
    
    // If coming from template creation, filter by sport if needed
    if (fromTemplateCreation && sport != 'Unknown Sport') {
      actualCrewLists = actualCrewLists.where((list) {
        final listSport = list['sport'] as String?;
        return listSport == null || listSport.isEmpty || listSport == sport;
      }).toList();
    }

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
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Lists of Crews',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: primaryTextColor,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Manage your saved lists of crews',
                style: TextStyle(
                  fontSize: 16,
                  color: secondaryTextColor,
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: isLoading
                    ? const Center(child: CircularProgressIndicator(color: efficialsYellow))
                    : actualCrewLists.isEmpty
                        ? _buildEmptyState(sport)
                        : _buildCrewListsList(actualCrewLists),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(String sport) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.group,
            size: 80,
            color: secondaryTextColor,
          ),
          const SizedBox(height: 16),
          const Text(
            'No crew lists found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: primaryTextColor,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Create your first crew list to get started',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: secondaryTextColor,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: 250,
            child: ElevatedButton.icon(
              onPressed: () {
                final actualCrewLists = crewLists.where((list) => list['id'] != 0 && list['id'] != -1).toList();
                final existingListNames = actualCrewLists
                    .map((list) => list['name'] as String)
                    .toList();
                final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
                Navigator.pushNamed(
                  context,
                  '/name_crew_list',
                  arguments: {
                    'existingLists': existingListNames,
                    'fromTemplateCreation': isFromTemplateCreation,
                    'sport': sport,
                    ...?args,
                  },
                ).then((result) async {
                  if (result != null) {
                    await _handleNewCrewListResult(result, sport);
                  }
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: efficialsYellow,
                foregroundColor: efficialsBlack,
                padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 32),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              icon: const Icon(Icons.add, color: efficialsBlack),
              label: const Text(
                'Create New Crew List',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCrewListsList(List<Map<String, dynamic>> lists) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const buttonHeight = 60.0;
        const padding = 20.0;
        const minBottomSpace = 100.0;

        final maxListHeight = constraints.maxHeight - buttonHeight - padding - minBottomSpace;

        return Column(
          children: [
            Container(
              constraints: BoxConstraints(
                maxHeight: maxListHeight > 0 ? maxListHeight : constraints.maxHeight * 0.6,
              ),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: lists.length,
                itemBuilder: (context, index) {
                  final list = lists[index];
                  final listName = list['name'] as String;
                  final crews = list['crews'] as List<dynamic>? ?? [];
                  final crewCount = crews.length;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: darkSurface,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            spreadRadius: 1,
                            blurRadius: 3,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: getSportIconColor(list['sport'] as String? ?? 'Unknown').withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                getSportIcon(list['sport'] as String? ?? 'Unknown'),
                                color: getSportIconColor(list['sport'] as String? ?? 'Unknown'),
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    listName,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: primaryTextColor,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '$crewCount crew${crewCount == 1 ? '' : 's'}',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: secondaryTextColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  onPressed: () {
                                    Navigator.pushNamed(
                                      context,
                                      '/edit_crew_list',
                                      arguments: {
                                        'listName': listName,
                                        'listId': list['id'] as int,
                                        'crews': crews.map((crew) => 
                                            Map<String, dynamic>.from(crew as Map)).toList(),
                                      },
                                    ).then((result) async {
                                      if (result != null) {
                                        await _handleEditCrewListResult(result, list);
                                      }
                                    });
                                  },
                                  icon: const Icon(
                                    Icons.edit,
                                    color: efficialsYellow,
                                    size: 20,
                                  ),
                                  tooltip: 'Edit List',
                                ),
                                IconButton(
                                  onPressed: () {
                                    _showDeleteConfirmationDialog(listName, list['id'] as int);
                                  },
                                  icon: Icon(
                                    Icons.delete_outline,
                                    color: Colors.red.shade600,
                                    size: 20,
                                  ),
                                  tooltip: 'Delete List',
                                ),
                                if (isFromTemplateCreation)
                                  IconButton(
                                    onPressed: () {
                                      setState(() {
                                        selectedListName = listName;
                                      });
                                      _handleContinue();
                                    },
                                    icon: const Icon(
                                      Icons.arrow_forward,
                                      color: Colors.green,
                                      size: 20,
                                    ),
                                    tooltip: 'Use This List',
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: SizedBox(
                width: 250,
                child: ElevatedButton.icon(
                  onPressed: () {
                    final existingListNames = lists
                        .map((list) => list['name'] as String)
                        .toList();
                    Navigator.pushNamed(
                      context,
                      '/name_crew_list',
                      arguments: {
                        'existingLists': existingListNames,
                        'fromTemplateCreation': isFromTemplateCreation,
                        'sport': crewLists.isNotEmpty ? crewLists.first['sport'] : 'Unknown Sport',
                        ...?ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?,
                      },
                    ).then((result) async {
                      if (result != null) {
                        await _handleNewCrewListResult(result, crewLists.isNotEmpty ? crewLists.first['sport'] : 'Unknown Sport');
                      }
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: efficialsYellow,
                    foregroundColor: efficialsBlack,
                    padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 32),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  icon: const Icon(Icons.add, color: efficialsBlack),
                  label: const Text(
                    'Create New Crew List',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _handleNewCrewListResult(dynamic result, String sport) async {
    setState(() {
      if (crewLists.any((l) => l['name'] == 'No saved crew lists')) {
        crewLists.removeWhere((l) => l['name'] == 'No saved crew lists');
      }
      final newList = result as Map<String, dynamic>;
      if (!crewLists.any((list) => list['name'] == newList['listName'])) {
        crewLists.insert(0, {
          'name': newList['listName'],
          'sport': newList['sport'] ?? sport,
          'crews': newList['crews'],
          'id': crewLists.length + 1,
        });
        selectedListName = newList['listName'] as String;
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('A crew list with this name already exists!')),
        );
        selectedListName = null;
      }
    });
    await _saveCrewLists();
    await _fetchCrewLists();
  }

  Future<void> _handleEditCrewListResult(dynamic result, Map<String, dynamic> originalList) async {
    setState(() {
      final updatedList = result as Map<String, dynamic>;
      final index = crewLists.indexWhere((l) => l['name'] == originalList['name']);
      if (index != -1) {
        if (!crewLists.any((list) => 
            list['name'] == updatedList['name'] && 
            list['id'] != originalList['id'])) {
          crewLists[index] = updatedList;
          selectedListName = updatedList['name'] as String;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Crew list updated!')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('A crew list with this name already exists!')),
          );
          selectedListName = null;
        }
      }
    });
    await _saveCrewLists();
    await _fetchCrewLists();
  }

  Future<void> _handleNewCrewListFromReview(Map<String, dynamic> newListData) async {
    await _fetchCrewLists(); // Refresh the lists from SharedPreferences

    setState(() {
      selectedListName = newListData['listName'] as String;
    });

    // Show success message
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Your crew list was created successfully!'),
          backgroundColor: darkSurface,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }
}