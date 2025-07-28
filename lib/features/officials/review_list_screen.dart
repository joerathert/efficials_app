import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../shared/theme.dart';
import '../../shared/services/repositories/official_repository.dart';
import '../../shared/services/user_session_service.dart';

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
  int? listId;
  bool isEdit = false;
  late final OfficialRepository _officialRepository;
  int? _currentUserId;

  @override
  void initState() {
    super.initState();
    selectedOfficialsList = [];
    filteredOfficials = [];
    _officialRepository = OfficialRepository();
    _initializeUser();
  }

  Future<void> _initializeUser() async {
    _currentUserId = await UserSessionService.instance.getCurrentUserId();
  }

  Future<int> _getListsCountBySport(String sport) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? listsJson = prefs.getString('saved_lists');
      
      if (listsJson == null || listsJson.isEmpty) return 0;
      
      final List<Map<String, dynamic>> existingLists = 
          List<Map<String, dynamic>>.from(jsonDecode(listsJson));
      
      // Count lists for the specific sport
      return existingLists.where((list) => list['sport'] == sport).length;
    } catch (e) {
      return 0;
    }
  }

  void _showSecondListCreationDialog(Map<String, dynamic> arguments) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: darkSurface,
        title: Center(
          child: Text('Create Second List',
              style: TextStyle(color: efficialsYellow, fontSize: 20, fontWeight: FontWeight.bold)),
        ),
        content: Text(
            'You need at least two lists to use Multiple Lists. Let\'s create your second one.',
            style: TextStyle(color: Colors.white)),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pushReplacementNamed(
                context,
                '/name_list',
                arguments: {
                  'sport': sport ?? 'Baseball',
                  'fromGameCreation': true,
                  ...arguments, // Pass through all game creation context
                },
              );
            },
            child: const Text('Continue', style: TextStyle(color: efficialsYellow)),
          ),
        ],
      ),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!isInitialized) {
      try {
        final arguments = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
        
        sport = arguments['sport'] as String? ?? 'Football';
        listName = arguments['listName'] as String? ?? 'Unnamed List';
        listId = arguments['listId'] as int?;
        isEdit = arguments['isEdit'] as bool? ?? false;
        
        // Handle the selectedOfficials casting more safely
        final selectedOfficialsRaw = arguments['selectedOfficials'];
        
        if (selectedOfficialsRaw is List) {
          selectedOfficialsList = selectedOfficialsRaw.map((item) {
            if (item is Map<String, dynamic>) {
              return item;
            } else if (item is Map) {
              return Map<String, dynamic>.from(item);
            } else {
              throw Exception('Invalid official data type: ${item.runtimeType}');
            }
          }).toList();
        } else {
          throw Exception('selectedOfficials is not a List: ${selectedOfficialsRaw.runtimeType}');
        }
        
        filteredOfficials = List.from(selectedOfficialsList);
        
        for (var official in selectedOfficialsList) {
          final officialId = official['id'];
          if (officialId is int) {
            selectedOfficials[officialId] = true;
          }
        }
        
        isInitialized = true;
      } catch (e, stackTrace) {
        rethrow;
      }
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

  void _confirmList() async {
    final selectedOfficialsData = selectedOfficialsList
        .where((official) => selectedOfficials[official['id'] as int] ?? false)
        .toList();

    // Save the list to shared_preferences
    final prefs = await SharedPreferences.getInstance();
    final String? listsJson = prefs.getString('saved_lists');
    List<Map<String, dynamic>> existingLists = [];
    if (listsJson != null && listsJson.isNotEmpty) {
      existingLists = List<Map<String, dynamic>>.from(jsonDecode(listsJson));
    }

    if (isEdit && listId != null) {
      // Update existing list
      final updatedList = {
        'name': listName,
        'sport': sport,
        'officials': selectedOfficialsData,
        'id': listId,
      };

      // Find and update the existing list
      final index = existingLists.indexWhere((list) => list['id'] == listId);
      if (index != -1) {
        // Check for duplicate names (excluding the current list)
        if (existingLists.any((list) => list['name'] == listName && list['id'] != listId)) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('A list with this name already exists!'),
                backgroundColor: darkSurface,
              ),
            );
          }
          return;
        }
        existingLists[index] = updatedList;
      } else {
        existingLists.add(updatedList);
      }

      await prefs.setString('saved_lists', jsonEncode(existingLists));

      if (mounted) {
        // Navigate back to the lists screen after updating
        Navigator.popUntil(context, (route) {
          return route.settings.name == '/lists_of_officials' || route.isFirst;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Your list was updated!'),
            backgroundColor: darkSurface,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } else {
      // Create new list
      final newList = {
        'name': listName,
        'sport': sport,
        'officials': selectedOfficialsData,
        'id': existingLists.isEmpty ? 1 : (existingLists
            .map((list) => (list['id'] as int?) ?? 0)
            .reduce((a, b) => a > b ? a : b) + 1),
      };

      // Check for duplicate names
      if (existingLists.any((list) => list['name'] == listName)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('A list with this name already exists!'),
              backgroundColor: darkSurface,
            ),
          );
        }
        return;
      }

      existingLists.add(newList);
      await prefs.setString('saved_lists', jsonEncode(existingLists));

      if (mounted) {
        // Get the arguments to check if we're coming from game creation
        final arguments = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
        final fromGameCreation = arguments['fromGameCreation'] == true;
        
        // Check for special navigation logic for sports lists from game creation
        if (fromGameCreation && sport != null) {
          final currentSportListsCount = await _getListsCountBySport(sport!);
          final method = arguments['method'] as String?;
          
          // Only show second list dialog for 'advanced' (Multiple Lists) method
          if (method == 'advanced' && currentSportListsCount == 1) {
            // First list of this sport created for Multiple Lists method - navigate to name_list_screen for second list
            if (mounted) {
              _showSecondListCreationDialog(arguments);
            }
            return;
          } else if (method == 'advanced' && currentSportListsCount >= 2) {
            // Second+ list of this sport created for Multiple Lists method - navigate to advanced_officials_selection
            if (mounted) {
              Navigator.pushReplacementNamed(
                context,
                '/advanced_officials_selection',
                arguments: arguments,
              );
            }
            return;
          }
        }
        
        if (fromGameCreation) {
          final method = arguments['method'] as String?;
          
          // For Single List method, navigate to lists_of_officials so user can select with green arrow
          if (method == 'use_list') {
            Navigator.pushReplacementNamed(
              context,
              '/lists_of_officials',
              arguments: {
                'sport': sport,
                'fromGameCreation': true,
                'method': method,
                'newListCreated': {
                  'listName': listName,
                  'sport': sport,
                  'officials': selectedOfficialsData,
                },
              },
            );
            return;
          }
          
          // For other methods, just pop back with the list data
          Navigator.pop(context, {
            'listName': listName,
            'sport': sport,
            'officials': selectedOfficialsData,
          });
        } else {
          // Regular pop for non-game creation flows
          Navigator.pop(context, {
            'listName': listName,
            'sport': sport,
            'officials': selectedOfficialsData,
          });
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Your list was created!'),
            backgroundColor: darkSurface,
            duration: const Duration(seconds: 2),
          ),
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
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              const Text(
                'Review List',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: efficialsYellow,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Container(
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
                child: TextField(
                  decoration: textFieldDecoration('Search Officials'),
                  style: const TextStyle(fontSize: 18, color: Colors.white),
                  onChanged: (value) => filterOfficials(value),
                ),
              ),
              const SizedBox(height: 20),
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
                            'No officials selected.',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey,
                            ),
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
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Colors.white,
                                  ),
                                ),
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
                                        color: selectedOfficials[officialId] ?? false ? Colors.green : efficialsYellow,
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
                        onPressed: selectedCount > 0 ? _confirmList : null,
                        style: elevatedButtonStyle(),
                        child: Text(isEdit ? 'Update List' : 'Save List', style: signInButtonTextStyle),
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
}