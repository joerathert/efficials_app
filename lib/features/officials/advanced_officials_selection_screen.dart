import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../shared/theme.dart';
import '../../shared/services/game_service.dart';
import '../../shared/services/repositories/list_repository.dart';
import '../../shared/services/repositories/official_repository.dart';
import '../../shared/services/user_session_service.dart';

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
  
  late final ListRepository listRepo;
  late final OfficialRepository officialRepo;
  late final GameService gameService;

  @override
  void initState() {
    super.initState();
    listRepo = ListRepository();
    officialRepo = OfficialRepository();
    gameService = GameService();
    lists = [
      {'name': 'No saved lists', 'id': -1},
    ];
    // Initialize with 2 empty list slots
    selectedLists = [
      {'name': null, 'id': null, 'officials': [], 'minOfficials': null, 'maxOfficials': null},
      {'name': null, 'id': null, 'officials': [], 'minOfficials': null, 'maxOfficials': null},
    ];
    _fetchLists();
  }

  // Store args for use after lists are loaded
  Map<String, dynamic>? _routeArgs;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Capture route arguments
    if (_routeArgs == null) {
      _routeArgs = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    }
  }

  void _restoreSelectedLists(List<dynamic> existingLists) {
    final isEditMode = _routeArgs?['isEdit'] as bool? ?? false;
    
    setState(() {
      selectedLists.clear();
      for (var listData in existingLists) {
        if (listData is Map<String, dynamic>) {
          // Find the corresponding list from saved lists to get ID
          final fullList = lists.firstWhere(
            (l) => l['name'] == listData['name'],
            orElse: () => {'name': 'Unknown List', 'id': -1, 'officials': []},
          );
          
          selectedLists.add({
            'name': listData['name'],
            'id': fullList['id'],
            // In edit mode, use the game-specific officials from listData, not the full list
            'officials': isEditMode 
                ? (listData['officials'] ?? fullList['officials'] ?? [])
                : (fullList['officials'] ?? []),
            'minOfficials': listData['minOfficials'] ?? 0,
            'maxOfficials': listData['maxOfficials'] ?? 0,
          });
        }
      }
    });
  }

  Future<void> _fetchLists() async {
    try {
      final userId = await UserSessionService.instance.getCurrentUserId();
      if (userId == null) {
        setState(() {
          lists = [{'name': 'No saved lists', 'id': -1}];
          isLoading = false;
        });
        return;
      }

      final userLists = await listRepo.getLists(userId);
      debugPrint('DEBUG ADVANCED: Found ${userLists.length} lists from database');
      for (var list in userLists) {
        debugPrint('DEBUG ADVANCED: List - Name: ${list['name']}, Sport: ${list['sport_name']}, ID: ${list['id']}');
      }
      
      // Filter lists by current sport
      final currentSport = _routeArgs?['sport'] as String? ?? 'Baseball';
      final filteredLists = userLists.where((list) => list['sport_name'] == currentSport).toList();
      debugPrint('DEBUG ADVANCED: After sport filtering ($currentSport): ${filteredLists.length} lists');
      
      setState(() {
        lists = filteredLists.isNotEmpty ? filteredLists : [{'name': 'No saved lists', 'id': -1}];
        isLoading = false;
      });
      
      // After lists are loaded, check if we need to restore selected lists
      if (_routeArgs != null) {
        final isEdit = _routeArgs!['isEdit'] as bool? ?? false;
        if (isEdit && _routeArgs!['selectedLists'] != null) {
          final existingLists = _routeArgs!['selectedLists'] as List<dynamic>;
          if (existingLists.isNotEmpty) {
            _restoreSelectedLists(existingLists);
          }
        }
      }
    } catch (e) {
      setState(() {
        lists = [{'name': 'No saved lists', 'id': -1}];
        isLoading = false;
      });
      debugPrint('Error fetching lists: $e');
    }
  }

  void _setListForSlot(int slotIndex, String listName) {
    final selectedList = lists.firstWhere((l) => l['name'] == listName);
    setState(() {
      selectedLists[slotIndex] = {
        'name': listName,
        'id': selectedList['id'],
        'officials': selectedList['officials'] ?? [],
        'minOfficials': selectedLists[slotIndex]['minOfficials'],
        'maxOfficials': selectedLists[slotIndex]['maxOfficials'],
      };
    });
  }

  void _addThirdListSlot() {
    setState(() {
      selectedLists.add({
        'name': null,
        'id': null,
        'officials': [],
        'minOfficials': null,
        'maxOfficials': null,
      });
    });
  }

  void _removeList(int index) {
    setState(() {
      selectedLists.removeAt(index);
    });
  }

  Future<void> _saveUpdatedListToDatabase(String listName, List<Map<String, dynamic>> updatedOfficials) async {
    try {
      // Update list in database using the ListRepository
      await listRepo.updateList(listName, updatedOfficials);
      
      // Update the local lists data
      setState(() {
        for (int i = 0; i < lists.length; i++) {
          if (lists[i]['name'] == listName) {
            lists[i]['officials'] = updatedOfficials;
            break;
          }
        }
      });
      
      debugPrint('Updated list "$listName" with ${updatedOfficials.length} officials');
    } catch (e) {
      debugPrint('Error saving updated list: $e');
    }
  }

  void _showListOfficials(int listIndex) {
    final list = selectedLists[listIndex];
    final officials = (list['officials'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? [];
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: darkSurface,
          title: Text(
            'Officials in "${list['name']}"',
            style: const TextStyle(color: efficialsYellow, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          content: SizedBox(
            width: double.maxFinite,
            height: 400,
            child: officials.isEmpty
                ? const Text('No officials in this list.', style: TextStyle(color: Colors.white))
                : ListView.builder(
                    itemCount: officials.length,
                    itemBuilder: (context, index) {
                      final official = officials[index];
                      final officialName = official['name'] ?? 'Unknown Official';
                      
                      // Track which officials are checked/unchecked
                      final isChecked = official['_isSelected'] ?? true;
                      
                      return CheckboxListTile(
                        title: Text(
                          officialName,
                          style: TextStyle(
                            color: isChecked ? Colors.white : Colors.grey,
                            decoration: isChecked ? TextDecoration.none : TextDecoration.lineThrough,
                          ),
                        ),
                        subtitle: Text(
                          'Distance: ${(official['distance'] as num?)?.toStringAsFixed(1) ?? '0.0'} mi',
                          style: TextStyle(
                            color: isChecked ? Colors.grey : Colors.grey.shade600,
                          ),
                        ),
                        value: isChecked,
                        activeColor: Colors.green,
                        checkColor: Colors.white,
                        onChanged: (bool? value) {
                          setDialogState(() {
                            // Toggle the selection state but keep the official in the list
                            officials[index]['_isSelected'] = value ?? false;
                          });
                          
                          // Update the main state with only the checked officials
                          setState(() {
                            final checkedOfficials = officials.where((off) => off['_isSelected'] != false).toList();
                            // Remove the temporary _isSelected field from checked officials
                            for (var off in checkedOfficials) {
                              off.remove('_isSelected');
                            }
                            selectedLists[listIndex]['officials'] = checkedOfficials;
                          });
                        },
                      );
                    },
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () async {
                // Check if we're in edit mode for a game
                final isEditMode = _routeArgs?['isEdit'] as bool? ?? false;
                
                if (isEditMode) {
                  // In edit mode, DON'T save changes to the original saved lists
                  // Only update the game-specific selection
                  Navigator.pop(context);
                  
                  // Show confirmation that changes are for this game only
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Success! Removed officials will no longer have access to this game.'),
                      backgroundColor: Colors.blue,
                      duration: const Duration(seconds: 3),
                    ),
                  );
                } else {
                  // In new game creation mode, save changes to the original lists
                  await _saveUpdatedListToDatabase(list['name'], officials);
                  Navigator.pop(context);
                  
                  // Show confirmation
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Changes to "${list['name']}" saved permanently'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              },
              child: Text(
                (_routeArgs?['isEdit'] as bool? ?? false) ? 'Remove' : 'Save Changes',
                style: const TextStyle(color: efficialsYellow),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
          ],
        ),
      ),
    );
  }

  void _updateMinOfficials(int index, String value) {
    setState(() {
      selectedLists[index]['minOfficials'] = int.tryParse(value) ?? 0;
    });
  }

  void _updateMaxOfficials(int index, String value) {
    setState(() {
      selectedLists[index]['maxOfficials'] = int.tryParse(value) ?? 0; // Default to 0 if invalid, but hint will show initially
    });
  }

  Future<void> _saveFormState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final formStateJson = jsonEncode({
        'selectedLists': selectedLists,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });
      await prefs.setString('advanced_officials_form_state', formStateJson);
      debugPrint('Form state saved successfully');
    } catch (e) {
      debugPrint('Error saving form state: $e');
    }
  }

  Future<void> _restoreFormState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final formStateJson = prefs.getString('advanced_officials_form_state');
      
      if (formStateJson != null) {
        final formState = jsonDecode(formStateJson);
        final timestamp = formState['timestamp'] as int;
        final now = DateTime.now().millisecondsSinceEpoch;
        
        // Only restore if the saved state is less than 1 hour old
        if (now - timestamp < 3600000) {
          final savedSelectedLists = (formState['selectedLists'] as List)
              .map((item) => Map<String, dynamic>.from(item))
              .toList();
          
          // Merge saved form data with current lists
          setState(() {
            for (int i = 0; i < savedSelectedLists.length && i < selectedLists.length; i++) {
              final savedList = savedSelectedLists[i];
              if (savedList['name'] != null) {
                // Find the current list data to get fresh officials data
                final currentList = lists.firstWhere(
                  (l) => l['name'] == savedList['name'],
                  orElse: () => savedList,
                );
                
                selectedLists[i] = {
                  'name': savedList['name'],
                  'id': currentList['id'] ?? savedList['id'],
                  'officials': currentList['officials'] ?? savedList['officials'] ?? [],
                  'minOfficials': savedList['minOfficials'],
                  'maxOfficials': savedList['maxOfficials'],
                };
              }
            }
          });
          
          debugPrint('Form state restored successfully');
          
          // Clear the saved state after restoring
          await prefs.remove('advanced_officials_form_state');
        } else {
          // Clear expired state
          await prefs.remove('advanced_officials_form_state');
          debugPrint('Form state expired, cleared');
        }
      }
    } catch (e) {
      debugPrint('Error restoring form state: $e');
    }
  }

  Future<void> _navigateToCreateNewList() async {
    final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    final sport = args['sport'] as String? ?? 'Baseball';
    
    // Save current form state before navigating
    await _saveFormState();
    
    final result = await Navigator.pushNamed(
      context,
      '/create_new_list',
      arguments: {
        'sport': sport,
        'fromGameCreation': args['fromGameCreation'] ?? false,
        'fromTemplateCreation': true, // Flag to indicate we're coming from template creation
        ...args, // Pass through all game creation context
      },
    );
    
    if (result != null) {
      // Refresh the lists after creating a new one
      await _fetchLists();
      // Restore form state after refreshing lists
      await _restoreFormState();
      setState(() {});
    }
  }

  Future<void> _handleContinue() async {
    final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    final requiredOfficials = int.tryParse(args['officialsRequired'].toString()) ?? 0;

    // Filter out only the configured lists (those with names selected)
    final configuredLists = selectedLists.where((list) => list['name'] != null && list['name'] != '').toList();

    if (configuredLists.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least two lists for the advanced method')),
      );
      return;
    }

    // Check that min/max are set for all configured lists
    for (var list in configuredLists) {
      if (list['minOfficials'] == null || list['maxOfficials'] == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please set minimum and maximum officials for all selected lists')),
        );
        return;
      }
    }

    int totalMin = configuredLists.fold(0, (sum, list) => sum + (list['minOfficials'] as int));
    int totalMax = configuredLists.fold(0, (sum, list) => sum + (list['maxOfficials'] as int));

    if (totalMin > requiredOfficials || totalMax < requiredOfficials) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Total min must be ≤ required officials, and total max must be ≥ required officials')),
      );
      return;
    }

    List<Map<String, dynamic>> selectedOfficials = [];
    for (var list in configuredLists) {
      final officials = (list['officials'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? [];
      selectedOfficials.addAll(officials);
    }

    final updatedArgs = {
      ...args,
      'selectedOfficials': selectedOfficials,
      'method': 'advanced',
      'selectedLists': configuredLists.map((list) => {
        'name': list['name'],
        'id': list['id'],
        'minOfficials': list['minOfficials'],
        'maxOfficials': list['maxOfficials'],
        'officials': list['officials'], // Include the game-specific officials for each list
      }).toList(),
    };

    // Check if we're in edit mode or template creation mode
    final isEditMode = args['isEdit'] as bool? ?? false;
    final isFromTemplateCreation = args['fromTemplateCreation'] as bool? ?? false;
    
    if (isEditMode) {
      // In edit mode, update the game in the database and return to game info screen
      await _updateGameInDatabase(updatedArgs);
      
      // Navigate back to game information screen
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/game_information',
        (route) => route.settings.name == '/athletic_director_home' ||
                   route.settings.name == '/coach_home' ||
                   route.settings.name == '/assigner_home',
        arguments: updatedArgs,
      );
    } else if (isFromTemplateCreation) {
      // Return to template creation screen with the advanced configuration data
      Navigator.pop(context, {
        'selectedLists': configuredLists.map((list) => {
          'name': list['name'],
          'id': list['id'],
          'minOfficials': list['minOfficials'],
          'maxOfficials': list['maxOfficials'],
          'officials': list['officials'],
        }).toList(),
        'method': 'advanced',
      });
    } else {
      // Continue to review screen for new game creation
      Navigator.pushNamed(
        context,
        '/review_game_info',
        arguments: updatedArgs,
      );
    }
  }

  Future<void> _updateGameInDatabase(Map<String, dynamic> gameData) async {
    try {
      final gameId = gameData['id'];
      if (gameId != null) {
        // Convert data for database storage
        final updateData = Map<String, dynamic>.from(gameData);
        
        // Convert DateTime objects to strings if needed
        if (updateData['date'] != null && updateData['date'] is DateTime) {
          updateData['date'] = (updateData['date'] as DateTime).toIso8601String();
        }
        if (updateData['time'] != null && updateData['time'] is TimeOfDay) {
          final time = updateData['time'] as TimeOfDay;
          updateData['time'] = '${time.hour}:${time.minute}';
        }
        if (updateData['createdAt'] != null && updateData['createdAt'] is DateTime) {
          updateData['createdAt'] = (updateData['createdAt'] as DateTime).toIso8601String();
        }
        if (updateData['updatedAt'] != null && updateData['updatedAt'] is DateTime) {
          updateData['updatedAt'] = (updateData['updatedAt'] as DateTime).toIso8601String();
        }
        
        // Update the game in the database
        int? databaseGameId;
        if (gameId is int) {
          databaseGameId = gameId;
        } else if (gameId is String) {
          databaseGameId = int.tryParse(gameId);
        }
        
        if (databaseGameId != null) {
          await gameService.updateGame(databaseGameId, updateData);
          debugPrint('Game updated in database successfully with ID: $databaseGameId');
          
          // Show success message
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Game updated successfully!'),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 2),
              ),
            );
          }
        }
      }
    } catch (e) {
      debugPrint('Error updating game in database: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error updating game. Please try again.'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    _routeArgs = args; // Store args for later use
    totalRequiredOfficials = int.tryParse(args['officialsRequired'].toString()) ?? 0;

    final dropdownItems = <DropdownMenuItem<String>>[];
    
    // Add existing lists
    if (lists.isNotEmpty && lists.first['name'] != 'No saved lists') {
      for (final list in lists) {
        dropdownItems.add(
          DropdownMenuItem(
            value: list['name'] as String,
            child: Text(
              list['name'] as String,
              style: const TextStyle(color: primaryTextColor),
            ),
          ),
        );
      }
    }
    
    // Always add the "Create new list" option
    dropdownItems.add(
      const DropdownMenuItem(
        value: '+ Create new list',
        child: Text(
          '+ Create new list',
          style: TextStyle(color: efficialsYellow, fontWeight: FontWeight.bold),
        ),
      ),
    );
    
    // Add "No saved lists" message if no real lists exist
    if (lists.isEmpty || (lists.length == 1 && lists.first['name'] == 'No saved lists')) {
      dropdownItems.insert(0, 
        const DropdownMenuItem(
          value: 'No saved lists',
          child: Text('No saved lists', style: TextStyle(color: Colors.red)),
        ),
      );
    }

    return Scaffold(
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
      backgroundColor: darkBackground,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Advanced Officials Selection',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: primaryTextColor,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Select at least two lists and set constraints for officials.',
                style: TextStyle(
                  fontSize: 16,
                  color: secondaryTextColor,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Total officials required: $totalRequiredOfficials',
                style: const TextStyle(fontSize: 16, color: primaryTextColor),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      if (isLoading)
                        const Center(child: CircularProgressIndicator())
                      else
                        ...selectedLists.asMap().entries.map((entry) {
                        final index = entry.key;
                        final list = entry.value;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12.0),
                          child: Container(
                            decoration: BoxDecoration(
                              color: darkSurface,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.3),
                                  spreadRadius: 1,
                                  blurRadius: 3,
                                  offset: const Offset(0, 1),
                                ),
                              ],
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'List ${index + 1}',
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: efficialsYellow,
                                        ),
                                      ),
                                      if (selectedLists.length > 2)
                                        IconButton(
                                          icon: Icon(
                                            Icons.delete_outline,
                                            color: Colors.red.shade600,
                                          ),
                                          onPressed: () => _removeList(index),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  DropdownButtonFormField<String>(
                                    decoration: textFieldDecoration('Select Officials List'),
                                    dropdownColor: darkSurface,
                                    style: const TextStyle(color: primaryTextColor),
                                    value: list['name'],
                                    onChanged: (newValue) {
                                      if (newValue != null) {
                                        if (newValue == '+ Create new list') {
                                          _navigateToCreateNewList();
                                        } else if (newValue != 'No saved lists') {
                                          _setListForSlot(index, newValue);
                                        }
                                      }
                                    },
                                    items: dropdownItems,
                                  ),
                                  const SizedBox(height: 10),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: TextField(
                                          decoration: textFieldDecoration('Min. Officials'),
                                          keyboardType: TextInputType.number,
                                          style: const TextStyle(color: primaryTextColor),
                                          controller: TextEditingController(
                                            text: list['minOfficials']?.toString() ?? '',
                                          ),
                                          onChanged: (value) => _updateMinOfficials(index, value),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: TextField(
                                          decoration: textFieldDecoration('Max. Officials'),
                                          keyboardType: TextInputType.number,
                                          style: const TextStyle(color: primaryTextColor),
                                          controller: TextEditingController(
                                            text: list['maxOfficials']?.toString() ?? '',
                                          ),
                                          onChanged: (value) => _updateMaxOfficials(index, value),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  if (list['name'] != null && list['name'] != '')
                                    ElevatedButton.icon(
                                      onPressed: () => _showListOfficials(index),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: efficialsYellow,
                                        foregroundColor: efficialsBlack,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                      ),
                                      icon: const Icon(Icons.people, color: efficialsBlack),
                                      label: Text(
                                        'View Officials (${(list['officials'] as List?)?.length ?? 0})',
                                        style: const TextStyle(
                                          color: efficialsBlack,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }),
                      if (selectedLists.length < 3) ...[
                        const SizedBox(height: 20),
                        Center(
                          child: Container(
                            width: 250,
                            child: ElevatedButton.icon(
                              onPressed: _addThirdListSlot,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: efficialsYellow,
                                foregroundColor: efficialsBlack,
                                padding: const EdgeInsets.symmetric(
                                    vertical: 15, horizontal: 32),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              icon: const Icon(Icons.add, color: efficialsBlack),
                              label: const Text(
                                'Add Another List',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                      Center(
                        child: Container(
                          width: 250,
                          child: ElevatedButton(
                            onPressed: () {
                              final configuredCount = selectedLists.where((list) => list['name'] != null && list['name'] != '').length;
                              if (configuredCount >= 2) {
                                _handleContinue();
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: () {
                                final configuredCount = selectedLists.where((list) => list['name'] != null && list['name'] != '').length;
                                return configuredCount >= 2 ? efficialsYellow : efficialsGray;
                              }(),
                              foregroundColor: efficialsBlack,
                              padding: const EdgeInsets.symmetric(
                                  vertical: 15, horizontal: 32),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text(
                              'Continue',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}