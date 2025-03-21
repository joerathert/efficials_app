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
  bool isFromGameCreation = false;

  @override
  void initState() {
    super.initState();
    lists = [
      {'name': 'No saved lists', 'id': -1},
      {'name': '+ Create new list', 'id': 0},
    ];
    selectedList = lists[0]['name'] as String;
    _fetchLists();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null) {
      isFromGameCreation = args['fromGameCreation'] == true;
    }
  }

  Future<void> _fetchLists() async {
    final prefs = await SharedPreferences.getInstance();
    final String? listsJson = prefs.getString('saved_lists');
    setState(() {
      if (listsJson != null && listsJson.isNotEmpty) {
        try {
          lists = List<Map<String, dynamic>>.from(jsonDecode(listsJson));
        } catch (e) {
          lists = [];
        }
      }
      if (lists.isEmpty) {
        lists.add({'name': 'No saved lists', 'id': -1});
      }
      lists.add({'name': '+ Create new list', 'id': 0});
      selectedList = lists.isNotEmpty ? lists[0]['name'] as String : null;
      isLoading = false;
    });
  }

  Future<void> _saveLists() async {
    final prefs = await SharedPreferences.getInstance();
    final listsToSave = lists.where((list) => list['id'] != 0 && list['id'] != -1).toList();
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
            child: const Text('Cancel', style: TextStyle(color: efficialsBlue)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                lists.removeWhere((list) => list['id'] == listId);
                if (lists.isEmpty || (lists.length == 1 && lists[0]['id'] == 0)) {
                  lists.insert(0, {'name': 'No saved lists', 'id': -1});
                }
                selectedList = lists.isNotEmpty ? lists[0]['name'] as String : null;
                _saveLists();
              });
            },
            child: const Text('Delete', style: TextStyle(color: efficialsBlue)),
          ),
        ],
      ),
    );
  }

  void _handleContinue() {
    final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    final selected = lists.firstWhere((l) => l['name'] == selectedList);
    final officialsRaw = selected['officials'];
    List<Map<String, dynamic>> selectedOfficials = [];

    if (officialsRaw != null) {
      if (officialsRaw is List) {
        selectedOfficials = officialsRaw.cast<Map<String, dynamic>>();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid officials data in the selected list')),
        );
        return;
      }
    }

    Navigator.pop(context, {
      ...args,
      'selectedOfficials': selectedOfficials,
      'method': 'use_list', // Add method to indicate Use List was used
      'selectedListName': selectedList, // Pass the selected list name
    });
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
                                  if (result != null) {
                                    setState(() {
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
                                      } else {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('A list with this name already exists!')),
                                        );
                                        selectedList = lists.isNotEmpty ? lists[0]['name'] as String : null;
                                      }
                                    });
                                    await _saveLists();
                                    await _fetchLists();
                                  } else {
                                    selectedList = lists.isNotEmpty ? lists[0]['name'] as String : null;
                                  }
                                });
                              } else if (newValue != 'No saved lists' && !newValue!.startsWith('Error')) {
                                selectedList = newValue;
                              }
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
                            });
                            await _saveLists();
                            await _fetchLists();
                          }
                        });
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
                    if (isFromGameCreation) ...[
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: _handleContinue,
                        style: elevatedButtonStyle(),
                        child: const Text('Continue', style: signInButtonTextStyle),
                      ),
                    ],
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