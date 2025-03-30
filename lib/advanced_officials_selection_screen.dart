import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'theme.dart';

class AdvancedOfficialsSelectionScreen extends StatefulWidget {
  const AdvancedOfficialsSelectionScreen({super.key});

  @override
  State<AdvancedOfficialsSelectionScreen> createState() => _AdvancedOfficialsSelectionScreenState();
}

class _AdvancedOfficialsSelectionScreenState extends State<AdvancedOfficialsSelectionScreen> {
  List<Map<String, dynamic>> lists = [];
  List<Map<String, dynamic>> selectedLists = [];
  bool isLoading = true;
  int totalRequiredOfficials = 0;

  @override
  void initState() {
    super.initState();
    lists = [
      {'name': 'No saved lists', 'id': -1},
    ];
    _fetchLists();
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
      isLoading = false;
    });
  }

  void _addList(String listName) {
    final selectedList = lists.firstWhere((l) => l['name'] == listName);
    setState(() {
      selectedLists.add({
        'name': listName,
        'id': selectedList['id'],
        'officials': selectedList['officials'] ?? [],
        'minOfficials': 0,
        'maxOfficials': 0,
      });
    });
  }

  void _removeList(int index) {
    setState(() {
      selectedLists.removeAt(index);
    });
  }

  void _updateMinOfficials(int index, String value) {
    setState(() {
      selectedLists[index]['minOfficials'] = int.tryParse(value) ?? 0;
    });
  }

  void _updateMaxOfficials(int index, String value) {
    setState(() {
      selectedLists[index]['maxOfficials'] = int.tryParse(value) ?? 0;
    });
  }

  void _handleContinue() {
    final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    final requiredOfficials = args['officialsRequired'] as int? ?? 0; // Updated to treat as int

    // Validate at least two lists are selected
    if (selectedLists.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least two lists for the advanced method')),
      );
      return;
    }

    // Validate constraints
    int totalMin = selectedLists.fold(0, (sum, list) => sum + (list['minOfficials'] as int));
    int totalMax = selectedLists.fold(0, (sum, list) => sum + (list['maxOfficials'] as int));

    if (totalMin > requiredOfficials || totalMax < requiredOfficials) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Total minimum and maximum officials must match the required number')),
      );
      return;
    }

    // Combine officials based on constraints
    List<Map<String, dynamic>> finalOfficials = [];
    for (var list in selectedLists) {
      final officials = (list['officials'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? [];
      final min = list['minOfficials'] as int;
      final max = list['maxOfficials'] as int;
      int count = 0;

      for (var official in officials) {
        if (count < max) {
          finalOfficials.add(official);
          count++;
        }
        if (count >= min) break;
      }
    }

    Navigator.pushNamed(
      context,
      '/review_game_info',
      arguments: {
        ...args,
        'selectedOfficials': finalOfficials,
        'method': 'advanced',
        'selectedLists': selectedLists.map((list) => {
          'name': list['name'],
          'minOfficials': list['minOfficials'],
          'maxOfficials': list['maxOfficials'],
        }).toList(),
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    totalRequiredOfficials = args['officialsRequired'] as int? ?? 0; // Updated to treat as int

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

    return Scaffold(
      appBar: AppBar(
        backgroundColor: efficialsBlue,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, size: 36, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Advanced Officials Selection',
          style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
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
                    'Select at least two lists and set constraints for officials.',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Total officials required: $totalRequiredOfficials',
                    style: const TextStyle(fontSize: 16, color: Colors.black),
                  ),
                  const SizedBox(height: 20),
                  if (selectedLists.isEmpty) ...[
                    DropdownButtonFormField<String>(
                      decoration: textFieldDecoration('Select First List'),
                      value: null,
                      onChanged: (newValue) {
                        if (newValue != null && newValue != 'No saved lists' && !selectedLists.any((l) => l['name'] == newValue)) {
                          _addList(newValue);
                        }
                      },
                      items: dropdownItems,
                    ),
                  ],
                  ...selectedLists.asMap().entries.map((entry) {
                    final index = entry.key;
                    final list = entry.value;
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  list['name'] as String,
                                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () => _removeList(index),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            TextField(
                              decoration: textFieldDecoration('Minimum Officials'),
                              keyboardType: TextInputType.number,
                              onChanged: (value) => _updateMinOfficials(index, value),
                            ),
                            const SizedBox(height: 10),
                            TextField(
                              decoration: textFieldDecoration('Maximum Officials'),
                              keyboardType: TextInputType.number,
                              onChanged: (value) => _updateMaxOfficials(index, value),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                  if (selectedLists.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Add Another List'),
                            content: DropdownButtonFormField<String>(
                              decoration: textFieldDecoration('Select List'),
                              value: null,
                              onChanged: (newValue) {
                                if (newValue != null && newValue != 'No saved lists' && !selectedLists.any((l) => l['name'] == newValue)) {
                                  _addList(newValue);
                                  Navigator.pop(context);
                                }
                              },
                              items: dropdownItems,
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Cancel', style: TextStyle(color: efficialsBlue)),
                              ),
                            ],
                          ),
                        );
                      },
                      style: elevatedButtonStyle(),
                      child: const Text('Add Another List', style: signInButtonTextStyle),
                    ),
                    const SizedBox(height: 4),
                  ],
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: selectedLists.length >= 2 ? _handleContinue : null,
                    style: elevatedButtonStyle(),
                    child: const Text('Continue', style: signInButtonTextStyle),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}