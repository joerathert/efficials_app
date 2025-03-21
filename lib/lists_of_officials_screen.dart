import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'theme.dart';
import 'edit_list_screen.dart';

class ListsOfOfficialsScreen extends StatefulWidget {
  const ListsOfOfficialsScreen({super.key});

  @override
  State<ListsOfOfficialsScreen> createState() => _ListsOfOfficialsScreenState();
}

class _ListsOfOfficialsScreenState extends State<ListsOfOfficialsScreen> {
  String? selectedList;
  List<Map<String, dynamic>> lists = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    // Initialize with default values to avoid empty lists
    lists = [
      {'name': 'No saved lists', 'id': -1},
      {'name': '+ Create new list', 'id': 0},
    ];
    selectedList = lists[0]['name'] as String;
    _fetchLists();
  }

  Future<void> _fetchLists() async {
    final prefs = await SharedPreferences.getInstance();
    final String? listsJson = prefs.getString('saved_lists');
    setState(() {
      print('fetchLists - Raw JSON from SharedPreferences: $listsJson');
      if (listsJson != null && listsJson.isNotEmpty) {
        try {
          lists = List<Map<String, dynamic>>.from(jsonDecode(listsJson));
          print('fetchLists - Decoded lists: $lists');
        } catch (e) {
          print('Error decoding lists: $e');
          lists = [];
        }
      }
      if (lists.isEmpty) {
        lists.add({'name': 'No saved lists', 'id': -1});
      }
      lists.add({'name': '+ Create new list', 'id': 0});
      selectedList = lists.isNotEmpty ? lists[0]['name'] as String : null;
      print('fetchLists - Final lists: $lists, selectedList: $selectedList');
      isLoading = false;
    });
  }

  Future<void> _saveLists() async {
    final prefs = await SharedPreferences.getInstance();
    final listsToSave = lists.where((list) => list['id'] != 0 && list['id'] != -1).toList();
    print('saveLists - Saving lists: $listsToSave');
    await prefs.setString('saved_lists', jsonEncode(listsToSave));
    print('saveLists - Saved to SharedPreferences: ${prefs.getString('saved_lists')}');
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
            child: const Text('Cancel', style: TextStyle(color: efficialsBlue)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                print('showDeleteConfirmationDialog - Before: lists: $lists, selectedList: $selectedList');
                lists.removeWhere((list) => list['id'] == listId);
                if (lists.isEmpty || (lists.length == 1 && lists[0]['id'] == 0)) {
                  lists.insert(0, {'name': 'No saved lists', 'id': -1});
                }
                selectedList = lists.isNotEmpty ? lists[0]['name'] as String : null;
                print('showDeleteConfirmationDialog - After: lists: $lists, selectedList: $selectedList');
                _saveLists();
              });
            },
            child: const Text('Delete', style: TextStyle(color: efficialsBlue)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dropdownItems = lists.isNotEmpty
        ? lists.map((list) {
            return DropdownMenuItem(
              value: list['name'] as String,
              child: Text(
                list['name'] as String,
                style: list['name'] == 'No saved lists' ? const TextStyle(color: Colors.red) : null,
              ),
            );
          }).toList()
        : [
            const DropdownMenuItem(
              value: 'No saved lists',
              child: Text('No saved lists', style: TextStyle(color: Colors.red)),
            ),
          ];

    if (selectedList == null || !dropdownItems.any((item) => item.value == selectedList)) {
      selectedList = dropdownItems.isNotEmpty ? dropdownItems[0].value : null;
    }

    print('build - lists: $lists, selectedList: $selectedList');

    return Scaffold(
      appBar: AppBar(
        backgroundColor: efficialsBlue,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, size: 36, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Lists of Officials',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Select a list to edit, or create a new list.',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 60),
                  isLoading || selectedList == null
                      ? const CircularProgressIndicator()
                      : DropdownButtonFormField<String>(
                          decoration: textFieldDecoration('Lists'),
                          value: selectedList,
                          onChanged: (newValue) {
                            setState(() {
                              print('Dropdown onChanged - Before: newValue: $newValue, selectedList: $selectedList');
                              selectedList = newValue;
                              if (newValue == '+ Create new list') {
                                final existingListNames = lists
                                    .where((list) => list['id'] != 0 && list['id'] != -1)
                                    .map((list) => list['name'] as String)
                                    .toList();
                                Navigator.pushNamed(
                                  context,
                                  '/create_new_list',
                                  arguments: {'existingLists': existingListNames},
                                ).then((result) async {
                                  print('Create new list - Returned result: $result');
                                  if (result != null) {
                                    setState(() {
                                      print('Create new list - Before: lists: $lists, selectedList: $selectedList');
                                      if (lists.any((l) => l['name'] == 'No saved lists')) {
                                        lists.removeWhere((l) => l['name'] == 'No saved lists');
                                      }
                                      final newList = result as Map<String, dynamic>;
                                      if (!lists.any((list) => list['name'] == newList['listName'])) {
                                        lists.insert(0, {
                                          'name': newList['listName'],
                                          'sport': newList['sport'] ?? 'Unknown',
                                          'officials': newList['officials'],
                                          'id': lists.length + 1,
                                        });
                                        selectedList = newList['listName'] as String;
                                        print('Create new list - After adding: lists: $lists, selectedList: $selectedList');
                                      } else {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('A list with this name already exists!')),
                                        );
                                        selectedList = lists.isNotEmpty ? lists[0]['name'] as String : null;
                                      }
                                    });
                                    await _saveLists();
                                    await _fetchLists();
                                    print('Create new list - After reload: lists: $lists, selectedList: $selectedList');
                                  } else {
                                    print('Create new list - Result was null, no list added');
                                    selectedList = lists.isNotEmpty ? lists[0]['name'] as String : null;
                                  }
                                });
                              } else if (newValue != 'No saved lists' && !newValue!.startsWith('Error')) {
                                selectedList = newValue;
                              }
                              print('Dropdown onChanged - After: selectedList: $selectedList');
                            });
                          },
                          items: dropdownItems,
                        ),
                  const SizedBox(height: 60),
                  if (selectedList != null &&
                      selectedList != '+ Create new list' &&
                      selectedList != 'No saved lists' &&
                      !selectedList!.startsWith('Error')) ...[
                    ElevatedButton(
                      onPressed: () {
                        try {
                          final selected = lists.firstWhere((l) => l['name'] == selectedList);
                          Navigator.pushNamed(
                            context,
                            '/edit_list',
                            arguments: {
                              'listName': selected['name'] as String? ?? 'Unnamed List',
                              'listId': selected['id'] as int? ?? -1,
                              'officials': selected['officials'] as List<Map<String, dynamic>>? ?? [],
                            },
                          ).then((result) async {
                            if (result != null) {
                              setState(() {
                                print('Edit list - Before: lists: $lists, selectedList: $selectedList');
                                final updatedList = result as Map<String, dynamic>;
                                final index = lists.indexWhere((l) => l['name'] == selected['name']);
                                if (index != -1) {
                                  if (!lists.any((list) => list['name'] == updatedList['name'] && list['id'] != selected['id'])) {
                                    lists[index] = updatedList;
                                    selectedList = updatedList['name'] as String;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('List updated!')),
                                    );
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('A list with this name already exists!')),
                                    );
                                    selectedList = lists.isNotEmpty ? lists[0]['name'] as String : null;
                                  }
                                }
                                print('Edit list - After: lists: $lists, selectedList: $selectedList');
                              });
                              await _saveLists();
                              await _fetchLists();
                            }
                          });
                        } catch (e) {
                          print('Error navigating to EditListScreen: $e');
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error editing list: $e')),
                          );
                        }
                      },
                      style: elevatedButtonStyle(),
                      child: const Text('Edit List', style: signInButtonTextStyle),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: () {
                        final selected = lists.firstWhere((l) => l['name'] == selectedList);
                        _showDeleteConfirmationDialog(selectedList!, selected['id'] as int);
                      },
                      style: elevatedButtonStyle(backgroundColor: Colors.red),
                      child: const Text('Delete List', style: signInButtonTextStyle),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}