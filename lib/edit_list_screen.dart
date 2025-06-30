import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'theme.dart';

class EditListScreen extends StatefulWidget {
  const EditListScreen({super.key});

  @override
  State<EditListScreen> createState() => _EditListScreenState();
}

class _EditListScreenState extends State<EditListScreen> {
  String searchQuery = '';
  late List<Map<String, dynamic>> selectedOfficialsList;
  late List<Map<String, dynamic>> filteredOfficials;
  Map<int, bool> selectedOfficials = {};
  bool isInitialized = false;
  String? listName;
  int? listId;
  final TextEditingController _listNameController = TextEditingController();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!isInitialized) {
      final arguments = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
      listName = arguments['listName'] as String;
      listId = arguments['listId'] as int;
      selectedOfficialsList = arguments['officials'] as List<Map<String, dynamic>>? ?? [];
      filteredOfficials = List.from(selectedOfficialsList);
      _listNameController.text = listName ?? 'Unnamed List';
      for (var official in selectedOfficialsList) {
        selectedOfficials[official['id'] as int] = true;
      }
      isInitialized = true;
    }
  }

  void filterOfficials(String query) {
    setState(() {
      searchQuery = query;
      filteredOfficials = List.from(selectedOfficialsList);
      if (query.isNotEmpty) {
        filteredOfficials = filteredOfficials
            .where((official) => official['name'].toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  Future<void> _saveList() async {
    final updatedOfficials = selectedOfficialsList
        .where((official) => selectedOfficials[official['id'] as int] ?? false)
        .toList();

    // Update the list in shared_preferences
    final prefs = await SharedPreferences.getInstance();
    final String? listsJson = prefs.getString('saved_lists');
    List<Map<String, dynamic>> existingLists = [];
    if (listsJson != null && listsJson.isNotEmpty) {
      existingLists = List<Map<String, dynamic>>.from(jsonDecode(listsJson));
    }

    final updatedList = {
      'name': _listNameController.text.trim(),
      'sport': 'Football', // Replace with dynamic sport if available
      'officials': updatedOfficials,
      'id': listId,
    };

    // Update the existing list
    final index = existingLists.indexWhere((list) => list['id'] == listId);
    if (index != -1) {
      // Check for duplicate names (excluding the current list)
      if (existingLists.any((list) => list['name'] == updatedList['name'] && list['id'] != listId)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('A list with this name already exists!')),
        );
        return;
      }
      existingLists[index] = updatedList;
    } else {
      existingLists.add(updatedList);
    }

    await prefs.setString('saved_lists', jsonEncode(existingLists));

    // Return the updated list data to the previous screen
    Navigator.pop(context, updatedList);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('List updated!'), duration: Duration(seconds: 2)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final int selectedCount = selectedOfficials.values.where((selected) => selected).length;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: efficialsBlack,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, size: 36, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Edit List',
          style: TextStyle(color: darkSurface, fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: TextField(
                controller: _listNameController,
                decoration: textFieldDecoration('List Name'),
                style: const TextStyle(fontSize: 18),
              ),
            ),
          ),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: TextField(
                decoration: textFieldDecoration('Search Officials'),
                style: const TextStyle(fontSize: 18),
                onChanged: (value) => filterOfficials(value),
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
                          child: Text(
                            'No officials in this list.',
                            style: TextStyle(fontSize: 18, color: Colors.grey),
                            textAlign: TextAlign.center,
                          ),
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Checkbox(
                                  value: filteredOfficials.isNotEmpty &&
                                      filteredOfficials.every((official) => selectedOfficials[official['id']] ?? false),
                                  onChanged: (bool? value) {
                                    setState(() {
                                      if (value == true) {
                                        for (final official in filteredOfficials) {
                                          selectedOfficials[official['id']] = true;
                                        }
                                      } else {
                                        for (final official in filteredOfficials) {
                                          selectedOfficials.remove(official['id']);
                                        }
                                      }
                                    });
                                  },
                                  activeColor: efficialsBlue, // Changed to blue background when checked
                                  checkColor: Colors.white, // White checkmark
                                ),
                                const Text('Select all', style: TextStyle(fontSize: 18)),
                              ],
                            ),
                            Expanded(
                              child: ListView.builder(
                                itemCount: filteredOfficials.length,
                                itemBuilder: (context, index) {
                                  final official = filteredOfficials[index];
                                  final officialId = official['id'] as int;
                                  return ListTile(
                                    key: ValueKey(officialId),
                                    leading: IconButton(
                                      icon: Icon(
                                        selectedOfficials[officialId] ?? false ? Icons.check_circle : Icons.add_circle,
                                        color: selectedOfficials[officialId] ?? false ? Colors.green : efficialsBlue,
                                        size: 36,
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          selectedOfficials[officialId] = !(selectedOfficials[officialId] ?? false);
                                          if (selectedOfficials[officialId] == false) {
                                            selectedOfficials.remove(officialId);
                                          }
                                        });
                                      },
                                    ),
                                    title: Text('${official['name']} (${official['cityState'] ?? 'Unknown'})'),
                                    subtitle: Text(
                                      'Distance: ${official['distance'] != null ? (official['distance'] as num).toStringAsFixed(1) : '0.0'} mi, Experience: ${official['yearsExperience'] ?? 0} yrs',
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
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.only(bottom: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '($selectedCount) Selected',
              style: const TextStyle(fontSize: 16, color: primaryTextColor, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(
                  context,
                  '/populate_roster',
                  arguments: {
                    'sport': 'Football',
                    'listName': listName,
                    'listId': listId,
                    'selectedOfficials': selectedOfficialsList.where((official) => selectedOfficials[official['id'] as int] ?? false).toList(),
                    'isEdit': true, // Add isEdit flag to indicate edit mode
                  },
                ).then((result) {
                  if (result != null) {
                    setState(() {
                      selectedOfficialsList = result as List<Map<String, dynamic>>;
                      filteredOfficials = List.from(selectedOfficialsList);
                      selectedOfficials.clear();
                      for (var official in selectedOfficialsList) {
                        selectedOfficials[official['id'] as int] = true;
                      }
                    });
                  }
                });
              },
              style: elevatedButtonStyle(),
              child: const Text('Add Official(s)', style: signInButtonTextStyle),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: selectedCount > 0 ? _saveList : null,
              style: elevatedButtonStyle(),
              child: const Text('Save List', style: signInButtonTextStyle),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _listNameController.dispose();
    super.dispose();
  }
}