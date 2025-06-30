import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'theme.dart';
import 'edit_list_screen.dart';
import 'utils.dart';

class ListsOfOfficialsScreen extends StatefulWidget {
  const ListsOfOfficialsScreen({super.key});

  @override
  State<ListsOfOfficialsScreen> createState() => _ListsOfOfficialsScreenState();
}

class _ListsOfOfficialsScreenState extends State<ListsOfOfficialsScreen> {
  String? selectedList;
  List<Map<String, dynamic>> lists = [];
  bool isLoading = true;
  bool isFromGameCreation = false;

  @override
  void initState() {
    super.initState();
    lists = [
      {'name': 'No saved lists', 'id': -1},
      {'name': '+ Create new list', 'id': 0},
    ];
    _fetchLists();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null) {
      setState(() {
        isFromGameCreation = args['fromGameCreation'] == true;
      });
      if (lists.length <= 2 && lists[0]['name'] == 'No saved lists') {
        _fetchLists();
      }
    }
  }

  Future<void> _fetchLists() async {
    final prefs = await SharedPreferences.getInstance();
    final String? listsJson = prefs.getString('saved_lists');
    setState(() {
      lists.clear();
      if (listsJson != null && listsJson.isNotEmpty) {
        try {
          final decodedLists = jsonDecode(listsJson) as List<dynamic>;
          lists = decodedLists.map((list) {
            final listMap = Map<String, dynamic>.from(list as Map);
            if (listMap['officials'] != null) {
              listMap['officials'] = (listMap['officials'] as List<dynamic>)
                  .map((official) => Map<String, dynamic>.from(official as Map))
                  .toList();
            } else {
              listMap['officials'] = [];
            }
            return listMap;
          }).toList();
        } catch (e) {
          lists = [];
        }
      }
      if (lists.isEmpty) {
        lists.add({'name': 'No saved lists', 'id': -1});
      }
      lists.add({'name': '+ Create new list', 'id': 0});
      isLoading = false;
      print('Fetched lists: $lists, selectedList: $selectedList');
    });
  }

  Future<void> _saveLists() async {
    final prefs = await SharedPreferences.getInstance();
    final listsToSave =
        lists.where((list) => list['id'] != 0 && list['id'] != -1).toList();
    await prefs.setString('saved_lists', jsonEncode(listsToSave));
  }

  void _showDeleteConfirmationDialog(String listName, int listId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: Text('Are you sure you want to delete "$listName"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child:
                const Text('Cancel', style: TextStyle(color: efficialsYellow)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                lists.removeWhere((list) => list['id'] == listId);
                if (lists.isEmpty ||
                    (lists.length == 1 && lists[0]['id'] == 0)) {
                  lists.insert(0, {'name': 'No saved lists', 'id': -1});
                }
                selectedList = null; // Reset to show hint after deletion
                _saveLists();
              });
            },
            child:
                const Text('Delete', style: TextStyle(color: efficialsYellow)),
          ),
        ],
      ),
    );
  }

  void _handleContinue() {
    final args =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
    if (args == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: Game data not found')),
      );
      return;
    }
    final selected = lists.firstWhere((l) => l['name'] == selectedList);
    final officialsRaw = selected['officials'];
    List<Map<String, dynamic>> selectedOfficials = [];

    if (officialsRaw != null) {
      if (officialsRaw is List) {
        selectedOfficials = (officialsRaw)
            .map((official) => Map<String, dynamic>.from(official as Map))
            .toList();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Invalid officials data in the selected list')),
        );
        return;
      }
    }

    Navigator.pop(context, {
      ...args,
      'selectedOfficials': selectedOfficials,
      'method': 'use_list',
      'selectedListName': selectedList,
    });
  }

  @override
  Widget build(BuildContext context) {
    final args =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
    final sport = args?['sport'] as String? ?? 'Unknown Sport';

    // Filter out special items for the main list display
    final actualLists =
        lists.where((list) => list['id'] != 0 && list['id'] != -1).toList();

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
                'Lists of Officials',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: primaryTextColor,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Manage your saved lists of officials',
                style: TextStyle(
                  fontSize: 16,
                  color: secondaryTextColor,
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : actualLists.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.people,
                                  size: 80,
                                  color: secondaryTextColor,
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  'No official lists found',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: primaryTextColor,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'Create your first list to get started',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: secondaryTextColor,
                                  ),
                                ),
                                const SizedBox(height: 24),
                                ElevatedButton.icon(
                                  onPressed: () {
                                    final existingListNames = actualLists
                                        .map((list) => list['name'] as String)
                                        .toList();
                                    Navigator.pushNamed(
                                      context,
                                      '/create_new_list',
                                      arguments: {
                                        'existingLists': existingListNames,
                                        'fromGameCreation': isFromGameCreation,
                                        'sport': sport,
                                      },
                                    ).then((result) async {
                                      if (result != null) {
                                        await _handleNewListResult(
                                            result, sport);
                                      }
                                    });
                                  },
                                  style: elevatedButtonStyle(),
                                  icon: const Icon(Icons.add,
                                      color: efficialsBlack),
                                  label: const Text('Create New List',
                                      style: signInButtonTextStyle),
                                ),
                              ],
                            ),
                          )
                        : Column(
                            children: [
                              Expanded(
                                child: ListView.builder(
                                  itemCount: actualLists.length,
                                  itemBuilder: (context, index) {
                                    final list = actualLists[index];
                                    final listName = list['name'] as String;
                                    final officials =
                                        list['officials'] as List<dynamic>? ??
                                            [];
                                    final officialCount = officials.length;

                                    return Padding(
                                      padding:
                                          const EdgeInsets.only(bottom: 12.0),
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: darkSurface,
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          boxShadow: [
                                            BoxShadow(
                                              color:
                                                  Colors.black.withOpacity(0.3),
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
                                                padding:
                                                    const EdgeInsets.all(12),
                                                decoration: BoxDecoration(
                                                  color: getSportIconColor(
                                                          list['sport']
                                                                  as String? ??
                                                              sport)
                                                      .withOpacity(0.1),
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                                child: Icon(
                                                  getSportIcon(list['sport']
                                                          as String? ??
                                                      sport),
                                                  color: getSportIconColor(
                                                      list['sport']
                                                              as String? ??
                                                          sport),
                                                  size: 24,
                                                ),
                                              ),
                                              const SizedBox(width: 16),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      listName,
                                                      style: const TextStyle(
                                                        fontSize: 18,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color: primaryTextColor,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 4),
                                                    Text(
                                                      '$officialCount official${officialCount == 1 ? '' : 's'}',
                                                      style: const TextStyle(
                                                        fontSize: 14,
                                                        color:
                                                            secondaryTextColor,
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
                                                        '/edit_list',
                                                        arguments: {
                                                          'listName': listName,
                                                          'listId':
                                                              list['id'] as int,
                                                          'officials': officials
                                                              .map((official) => Map<
                                                                      String,
                                                                      dynamic>.from(
                                                                  official
                                                                      as Map))
                                                              .toList(),
                                                        },
                                                      ).then((result) async {
                                                        if (result != null) {
                                                          await _handleEditListResult(
                                                              result, list);
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
                                                      _showDeleteConfirmationDialog(
                                                          listName,
                                                          list['id'] as int);
                                                    },
                                                    icon: Icon(
                                                      Icons.delete_outline,
                                                      color:
                                                          Colors.red.shade600,
                                                      size: 20,
                                                    ),
                                                    tooltip: 'Delete List',
                                                  ),
                                                  if (isFromGameCreation)
                                                    IconButton(
                                                      onPressed: () {
                                                        setState(() {
                                                          selectedList =
                                                              listName;
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
                              const SizedBox(height: 16),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    final existingListNames = actualLists
                                        .map((list) => list['name'] as String)
                                        .toList();
                                    Navigator.pushNamed(
                                      context,
                                      '/create_new_list',
                                      arguments: {
                                        'existingLists': existingListNames,
                                        'fromGameCreation': isFromGameCreation,
                                        'sport': sport,
                                      },
                                    ).then((result) async {
                                      if (result != null) {
                                        await _handleNewListResult(
                                            result, sport);
                                      }
                                    });
                                  },
                                  style: elevatedButtonStyle(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 15),
                                  ),
                                  icon: const Icon(Icons.add,
                                      color: efficialsBlack),
                                  label: const Text('Create New List',
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

  Future<void> _handleNewListResult(dynamic result, String sport) async {
    setState(() {
      if (lists.any((l) => l['name'] == 'No saved lists')) {
        lists.removeWhere((l) => l['name'] == 'No saved lists');
      }
      final newList = result as Map<String, dynamic>;
      if (!lists.any((list) => list['name'] == newList['listName'])) {
        lists.insert(0, {
          'name': newList['listName'],
          'sport': newList['sport'] ?? sport,
          'officials': newList['officials'],
          'id': lists.length + 1,
        });
        selectedList = newList['listName'] as String;
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('A list with this name already exists!')),
        );
        selectedList = null;
      }
    });
    await _saveLists();
    await _fetchLists();
  }

  Future<void> _handleEditListResult(
      dynamic result, Map<String, dynamic> originalList) async {
    setState(() {
      final updatedList = result as Map<String, dynamic>;
      final index = lists.indexWhere((l) => l['name'] == originalList['name']);
      if (index != -1) {
        if (!lists.any((list) =>
            list['name'] == updatedList['name'] &&
            list['id'] != originalList['id'])) {
          lists[index] = updatedList;
          selectedList = updatedList['name'] as String;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('List updated!')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('A list with this name already exists!')),
          );
          selectedList = null;
        }
      }
    });
    await _saveLists();
    await _fetchLists();
  }
}
