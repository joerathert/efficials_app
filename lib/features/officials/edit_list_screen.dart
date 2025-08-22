import 'package:flutter/material.dart';
import '../../shared/theme.dart';
import '../../shared/services/repositories/list_repository.dart';
import '../../shared/services/user_session_service.dart';

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
      listName = arguments['listName'] as String? ?? 'Unknown List';
      listId = arguments['listId'] as int? ?? 0;
      selectedOfficialsList = arguments['officials'] as List<Map<String, dynamic>>? ?? [];
      filteredOfficials = List.from(selectedOfficialsList);
      _listNameController.text = listName ?? 'Unnamed List';
      for (var official in selectedOfficialsList) {
        final officialId = official['id'] as int? ?? 0;
        selectedOfficials[officialId] = true;
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
    try {
      final updatedOfficials = selectedOfficialsList
          .where((official) => selectedOfficials[official['id'] as int? ?? 0] ?? false)
          .toList();

      final listRepository = ListRepository();
      final userId = await UserSessionService.instance.getCurrentUserId();
      
      if (userId == null) {
        throw Exception('No user logged in');
      }

      final newListName = _listNameController.text.trim();
      
      // Check for duplicate names (excluding the current list)
      final nameExists = await listRepository.listNameExists(
          newListName, userId, excludeListId: listId);
      if (nameExists) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('A list with this name already exists!')),
          );
        }
        return;
      }

      // Update list name if changed
      if (listId != null) {
        await listRepository.updateListName(listId!, newListName);
      }
      
      // Update officials in list
      await listRepository.updateListById(listId!, updatedOfficials);

      final updatedList = {
        'name': newListName,
        'officials': updatedOfficials,
        'id': listId,
      };

      if (mounted) {
        // Return the updated list data to the previous screen
        Navigator.pop(context, updatedList);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('List updated!'), duration: Duration(seconds: 2)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating list: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final int selectedCount = selectedOfficials.values.where((selected) => selected).length;

    return Scaffold(
      backgroundColor: darkBackground,
      appBar: AppBar(
        backgroundColor: efficialsBlack,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: efficialsWhite),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Icon(
          Icons.sports,
          color: efficialsYellow,
          size: 32,
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              const Text(
                'Edit List',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: efficialsYellow,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _listNameController,
                decoration: textFieldDecoration('List Name'),
                style: const TextStyle(fontSize: 18, color: Colors.white),
              ),
              const SizedBox(height: 16),
              TextField(
                decoration: textFieldDecoration('Search Officials'),
                style: const TextStyle(fontSize: 18, color: Colors.white),
                onChanged: (value) => filterOfficials(value),
              ),
              const SizedBox(height: 16),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: darkSurface,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
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
                              activeColor: Colors.green,
                              checkColor: Colors.black,
                            ),
                            const Text(
                              'Select all', 
                              style: TextStyle(fontSize: 18, color: Colors.white)
                            ),
                          ],
                        ),
                            Expanded(
                              child: ListView.builder(
                                itemCount: filteredOfficials.length,
                                itemBuilder: (context, index) {
                                  final official = filteredOfficials[index];
                                  final officialId = official['id'] as int? ?? 0;
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
                                          final wasSelected = selectedOfficials[officialId] ?? false;
                                          selectedOfficials[officialId] = !wasSelected;
                                          if (selectedOfficials[officialId] == false) {
                                            selectedOfficials.remove(officialId);
                                          }
                                        });
                                      },
                                    ),
                                    title: Text(
                                      '${official['name']} (${official['cityState'] ?? 'Unknown'})',
                                      style: const TextStyle(color: Colors.white),
                                    ),
                                    subtitle: Text(
                                      'Distance: ${official['distance'] != null ? (official['distance'] as num).toStringAsFixed(1) : '0.0'} mi, Experience: ${official['yearsExperience'] ?? 0} yrs',
                                      style: const TextStyle(color: Colors.grey),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
              ),
            ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: darkSurface,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Text(
                      '($selectedCount) Selected',
                      style: const TextStyle(
                        fontSize: 16,
                        color: efficialsYellow,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          final currentlySelected = selectedOfficialsList.where((official) => selectedOfficials[official['id'] as int? ?? 0] ?? false).toList();
                          
                          Navigator.pushNamed(
                            context,
                            '/populate_roster',
                            arguments: {
                              'sport': 'Football',
                              'listName': listName,
                              'listId': listId,
                              'selectedOfficials': currentlySelected,
                              'isEdit': true,
                            },
                          ).then((result) {
                            if (result != null) {
                              final resultList = result as List<Map<String, dynamic>>;
                              
                              setState(() {
                                selectedOfficialsList = resultList;
                                filteredOfficials = List.from(selectedOfficialsList);
                                selectedOfficials.clear();
                                for (var official in selectedOfficialsList) {
                                  final officialId = official['id'] as int? ?? 0;
                                  selectedOfficials[officialId] = true;
                                }
                              });
                            }
                          });
                        },
                        style: elevatedButtonStyle(),
                        child: const Text('Add Official(s)', style: signInButtonTextStyle),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: selectedCount > 0 ? _saveList : null,
                        style: elevatedButtonStyle(),
                        child: const Text('Save List', style: signInButtonTextStyle),
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

  @override
  void dispose() {
    _listNameController.dispose();
    super.dispose();
  }
}