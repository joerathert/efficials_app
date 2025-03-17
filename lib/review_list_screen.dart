import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'theme.dart';

class ReviewListScreen extends StatefulWidget {
  const ReviewListScreen({super.key});

  @override
  State<ReviewListScreen> createState() => _ReviewListScreenState();
}

class _ReviewListScreenState extends State<ReviewListScreen> {
  String searchQuery = '';
  late List<Map<String, dynamic>> selectedOfficialsList;
  late List<Map<String, dynamic>> filteredOfficials;
  Map<int, bool> selectedOfficials = {};
  bool isInitialized = false;
  String? sport;
  String? listName;

  @override
  void initState() {
    super.initState();
    selectedOfficialsList = [];
    filteredOfficials = [];
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!isInitialized) {
      final arguments = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
      sport = arguments['sport'] as String;
      listName = arguments['listName'] as String;
      selectedOfficialsList = arguments['selectedOfficials'] as List<Map<String, dynamic>>;
      filteredOfficials = List.from(selectedOfficialsList);
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
    final prefs = await SharedPreferences.getInstance();
    final String? listsJson = prefs.getString('official_lists');
    List<Map<String, dynamic>> existingLists = listsJson != null ? List<Map<String, dynamic>>.from(jsonDecode(listsJson)) : [];

    final selectedOfficialsData = selectedOfficialsList
        .where((official) => selectedOfficials[official['id'] as int] ?? false)
        .toList();

    final newList = {
      'id': existingLists.length + 1,
      'name': listName!,
      'sport': sport!,
      'officials': selectedOfficialsData,
    };

    existingLists.add(newList);
    await prefs.setString('official_lists', jsonEncode(existingLists));

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Your list was created!'), duration: Duration(seconds: 2)),
    );
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final int selectedCount = selectedOfficials.values.where((selected) => selected).length;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: efficialsBlue,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, size: 36, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Review List',
          style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
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
                            'No officials selected.',
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
                                  activeColor: efficialsBlue, // Updated: Changed checkbox color to blue when selected
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
              style: const TextStyle(fontSize: 16, color: Colors.black, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
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
}