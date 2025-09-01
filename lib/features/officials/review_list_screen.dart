import 'package:flutter/material.dart';
import '../../shared/theme.dart';
import '../../shared/services/repositories/official_repository.dart';
import '../../shared/services/repositories/list_repository.dart';
import '../../shared/services/user_session_service.dart';
import '../../shared/models/database_models.dart';

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
      if (_currentUserId == null) {
        debugPrint(
            '🔄 REVIEW LIST: _getListsCountBySport($sport) - no current user ID');
        return 0;
      }

      final listRepository = ListRepository();
      final userLists = await listRepository.getUserLists(_currentUserId!);

      // Count lists for the specific sport
      final count =
          userLists.where((list) => list['sport_name'] == sport).length;
      debugPrint(
          '🔄 REVIEW LIST: _getListsCountBySport($sport) = $count lists found');
      return count;
    } catch (e) {
      debugPrint('🔄 REVIEW LIST: _getListsCountBySport($sport) error: $e');
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
              style: TextStyle(
                  color: efficialsYellow,
                  fontSize: 20,
                  fontWeight: FontWeight.bold)),
        ),
        content: Text(
            'You need at least two lists to use Multiple Lists. Let\'s create your second one.',
            style: TextStyle(color: Colors.white)),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              // Use pushNamed instead of pushReplacementNamed to preserve navigation stack
              Navigator.pushNamed(
                context,
                '/name_list',
                arguments: {
                  'sport': sport ?? 'Baseball',
                  'fromGameCreation': true,
                  'creatingSecondList': true, // Flag to show explanation popup
                  ...arguments, // Pass through all game creation context
                },
              );
            },
            child: const Text('Continue',
                style: TextStyle(color: efficialsYellow)),
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
        final arguments =
            ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;

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
              throw Exception(
                  'Invalid official data type: ${item.runtimeType}');
            }
          }).toList();
        } else {
          throw Exception(
              'selectedOfficials is not a List: ${selectedOfficialsRaw.runtimeType}');
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
            .where((official) =>
                official['name'].toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  void _confirmList() async {
    final selectedOfficialsData = selectedOfficialsList
        .where((official) => selectedOfficials[official['id'] as int] ?? false)
        .toList();

    try {
      final listRepository = ListRepository();

      // Get current user ID
      final userId = _currentUserId ??
          await UserSessionService.instance.getCurrentUserId();
      if (userId == null) {
        throw Exception('No current user found');
      }

      if (isEdit && listId != null) {
        // Update existing list - check for duplicate names first
        final nameExists = await listRepository
            .listNameExists(listName!, userId, excludeListId: listId);
        if (nameExists) {
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

        // Update list name if changed
        await listRepository.updateListName(listId!, listName!);

        // Update officials in list
        await listRepository.updateListById(listId!, selectedOfficialsData);

        if (mounted) {
          // Navigate back to the lists screen after updating
          Navigator.popUntil(context, (route) {
            return route.settings.name == '/lists_of_officials' ||
                route.isFirst;
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
        // Create new list - check for duplicate names first
        debugPrint(
            'DEBUG: Checking if list name "$listName" exists for user $userId');
        final nameExists =
            await listRepository.listNameExists(listName!, userId);
        debugPrint('DEBUG: List name exists check result: $nameExists');

        if (nameExists) {
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

        // Save to database using the new saveListFromUI method
        debugPrint(
            'DEBUG: Attempting to save list "$listName" with sport "$sport" and ${selectedOfficialsData.length} officials');
        final actualDatabaseId = await listRepository.saveListFromUI(
            listName!, sport!, selectedOfficialsData);
        debugPrint(
            'DEBUG: List saved successfully with database ID: $actualDatabaseId');

        if (mounted) {
          // Get the arguments to check if we're coming from game creation
          final arguments = ModalRoute.of(context)!.settings.arguments
              as Map<String, dynamic>;
          final fromGameCreation = arguments['fromGameCreation'] == true;

          debugPrint(
              '🔄 REVIEW LIST: Save List clicked - arguments: ${arguments.keys.toList()}');
          debugPrint('🔄 REVIEW LIST: fromGameCreation=$fromGameCreation');
          debugPrint('🔄 REVIEW LIST: All arguments:');
          arguments.forEach((key, value) {
            debugPrint('  $key: $value');
          });

          // Check for special navigation logic for sports lists from game creation
          if (fromGameCreation && sport != null) {
            final currentSportListsCount = await _getListsCountBySport(sport!);
            final method = arguments['method'] as String?;

            debugPrint(
                '🔄 REVIEW LIST: fromGameCreation=$fromGameCreation, sport=$sport, method=$method');
            debugPrint(
                '🔄 REVIEW LIST: currentSportListsCount=$currentSportListsCount');

            // Only show second list dialog for 'advanced' (Multiple Lists) method
            if (method == 'advanced' && currentSportListsCount == 1) {
              // First list of this sport created for Multiple Lists method - navigate to name_list_screen for second list
              debugPrint(
                  '🔄 REVIEW LIST: Taking FIRST LIST path - showing second list dialog');
              if (mounted) {
                _showSecondListCreationDialog(arguments);
              }
              return;
            } else if (method == 'advanced' && currentSportListsCount >= 2) {
              // Second+ list of this sport created for Multiple Lists method - return to advanced_officials_selection
              debugPrint(
                  '🔄 REVIEW LIST: Taking SECOND+ LIST path - returning to Advanced Officials Selection');
              if (mounted) {
                // Use popUntil to go directly back to Advanced Officials Selection screen
                // This bypasses any intermediate screens that might be in the stack
                debugPrint(
                    '🔄 REVIEW LIST: Using popUntil to reach Advanced Officials Selection');
                Navigator.popUntil(context, (route) {
                  debugPrint(
                      '🔄 REVIEW LIST: Checking route: ${route.settings.name}');
                  return route.settings.name == '/advanced_officials_selection';
                });

                // Since we can't pass data with popUntil, the Advanced Officials Selection
                // screen will refresh its lists when it becomes active again
              }
              return;
            }
          }

          debugPrint(
              '🔄 REVIEW LIST: Continuing to regular fromGameCreation logic');

          if (fromGameCreation) {
            final method = arguments['method'] as String?;
            debugPrint(
                '🔄 REVIEW LIST: In regular fromGameCreation logic - method=$method');

            // For Single List method, navigate to lists_of_officials so user can select with green arrow
            if (method == 'use_list') {
              debugPrint(
                  '🔄 REVIEW LIST: Taking use_list path - navigating to lists_of_officials');
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
                    'actualDatabaseId': actualDatabaseId,
                  },
                },
              );
              return;
            }

            // For other methods, return the list data with actual database ID
            debugPrint(
                '🔄 REVIEW LIST: Taking regular fromGameCreation pop path - popping with list data');
            Navigator.pop(context, {
              'listName': listName,
              'sport': sport,
              'officials': selectedOfficialsData,
              'actualDatabaseId': actualDatabaseId,
            });
          } else {
            // Regular pop for non-game creation flows
            debugPrint('🔄 REVIEW LIST: Taking non-game creation pop path');
            Navigator.pop(context, {
              'listName': listName,
              'sport': sport,
              'officials': selectedOfficialsData,
              'actualDatabaseId': actualDatabaseId,
            });
          }

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Your list was created successfully!'),
              backgroundColor: darkSurface,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error saving list: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving list: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final int selectedCount =
        selectedOfficials.values.where((selected) => selected).length;

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
                                      filteredOfficials.every((official) =>
                                          selectedOfficials[official['id']] ??
                                          false),
                                  onChanged: (bool? value) {
                                    setState(() {
                                      if (value == true) {
                                        for (final official
                                            in filteredOfficials) {
                                          selectedOfficials[official['id']] =
                                              true;
                                        }
                                      } else {
                                        for (final official
                                            in filteredOfficials) {
                                          selectedOfficials
                                              .remove(official['id']);
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
                                        selectedOfficials[officialId] ?? false
                                            ? Icons.check_circle
                                            : Icons.add_circle,
                                        color: selectedOfficials[officialId] ??
                                                false
                                            ? Colors.green
                                            : efficialsYellow,
                                        size: 36,
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          selectedOfficials[officialId] =
                                              !(selectedOfficials[officialId] ??
                                                  false);
                                          if (selectedOfficials[officialId] ==
                                              false) {
                                            selectedOfficials
                                                .remove(officialId);
                                          }
                                        });
                                      },
                                    ),
                                    title: Text(
                                      '${official['name']} (${official['cityState'] ?? 'Unknown'})',
                                      style:
                                          const TextStyle(color: Colors.white),
                                    ),
                                    subtitle: Text(
                                      'Distance: ${official['distance'] != null ? (official['distance'] as num).toStringAsFixed(1) : '0.0'} mi, Experience: ${official['yearsExperience'] ?? 0} yrs',
                                      style:
                                          const TextStyle(color: Colors.grey),
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
                        child: Text(isEdit ? 'Update List' : 'Save List',
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
}
