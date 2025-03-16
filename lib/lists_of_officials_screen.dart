import 'dart:convert';
import 'package:flutter/material.dart';
import 'theme.dart';

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
    _fetchLists();
  }

  Future<void> _fetchLists() async {
    try {
      // final fetchedLists = await DatabaseHelper.getLists();  // Commented out
      // setState(() {
      //   lists = fetchedLists;
      //   if (lists.isEmpty) {
      //     lists.add({'name': 'No saved lists', 'id': -1});
      //   }
      //   lists.add({'name': '+ Create new list', 'id': 0});
      //   isLoading = false;
      // });
    } catch (e) {
      print('Error fetching lists: $e');
      setState(() {
        isLoading = false;
        lists = [
          {'name': 'Error loading lists: $e', 'id': -1},
          {'name': '+ Create new list', 'id': 0}
        ];
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading lists: $e')),
      );
    }
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
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                lists.removeWhere((list) => list['id'] == listId);
                if (lists.length == 1) {
                  lists.insert(0, {'name': 'No saved lists', 'id': -1});
                }
              });
              // DatabaseHelper.deleteList(listId);  // Commented out
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
                    'Select a list of officials to edit or create a new list.',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 60),
                  isLoading
                      ? const CircularProgressIndicator()
                      : DropdownButtonFormField<String>(
                          decoration: textFieldDecoration('Official Lists'),
                          value: selectedList,
                          onChanged: (newValue) {
                            setState(() {
                              selectedList = newValue;
                              if (newValue == '+ Create new list') {
                                Navigator.pushNamed(
                                  context,
                                  '/create_new_list',
                                  arguments: lists.map((l) => l['name'] as String).toList(),
                                ).then((result) {
                                  if (result != null) {
                                    setState(() {
                                      if (lists.any((l) => l['name'] == 'No saved lists')) {
                                        lists.removeWhere((l) => l['name'] == 'No saved lists');
                                      }
                                      lists.insert(0, {'name': result as String, 'id': lists.length + 1});
                                      selectedList = result;
                                    });
                                  } else {
                                    selectedList = null;
                                  }
                                });
                              } else if (newValue != 'No saved lists' && newValue != 'Error loading lists: ...') {
                                final selected = lists.firstWhere((l) => l['name'] == newValue);
                                // DatabaseHelper.getOfficials().then((officials) {  // Commented out
                                //   Navigator.pushNamed(
                                //     context,
                                //     '/edit_list',
                                //     arguments: {
                                //       'listName': newValue,
                                //       'listId': selected['id'],
                                //       'officials': officials,
                                //     },
                                //   );
                                // });
                              }
                            });
                          },
                          items: lists.map((list) {
                            return DropdownMenuItem(
                              value: list['name'] as String,
                              child: Text(
                                list['name'] as String,
                                style: list['name'].startsWith('Error') || list['name'] == 'No saved lists'
                                    ? const TextStyle(color: Colors.red)
                                    : null,
                              ),
                            );
                          }).toList(),
                        ),
                  const SizedBox(height: 60),
                  if (selectedList != null &&
                      selectedList != '+ Create new list' &&
                      selectedList != 'No saved lists' &&
                      !selectedList!.startsWith('Error')) ...[
                    ElevatedButton(
                      onPressed: () {
                        final selected = lists.firstWhere((l) => l['name'] == selectedList);
                        // DatabaseHelper.getOfficials().then((officials) {  // Commented out
                        //   Navigator.pushNamed(
                        //     context,
                        //     '/edit_list',
                        //     arguments: {
                        //       'listName': selectedList,
                        //       'listId': selected['id'],
                        //       'officials': officials,
                        //     },
                        //   );
                        // });
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
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        side: const BorderSide(color: Colors.black, width: 2),
                        minimumSize: const Size(125, 35),
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Delete List', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
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