import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../shared/theme.dart';
import '../../shared/services/game_service.dart';

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
  }

  void _addList(String listName) {
    final selectedList = lists.firstWhere((l) => l['name'] == listName);
    setState(() {
      selectedLists.add({
        'name': listName,
        'id': selectedList['id'],
        'officials': selectedList['officials'] ?? [],
      });
    });
  }

  void _removeList(int index) {
    setState(() {
      selectedLists.removeAt(index);
    });
  }

  Future<void> _saveUpdatedListToPreferences(String listName, List<Map<String, dynamic>> updatedOfficials) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? listsJson = prefs.getString('saved_lists');
      
      if (listsJson != null && listsJson.isNotEmpty) {
        List<Map<String, dynamic>> savedLists = List<Map<String, dynamic>>.from(jsonDecode(listsJson));
        
        // Find and update the specific list
        for (int i = 0; i < savedLists.length; i++) {
          if (savedLists[i]['name'] == listName) {
            savedLists[i]['officials'] = updatedOfficials;
            break;
          }
        }
        
        // Save back to SharedPreferences
        await prefs.setString('saved_lists', jsonEncode(savedLists));
        
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
      }
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
                  await _saveUpdatedListToPreferences(list['name'], officials);
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

  Future<void> _handleContinue() async {
    final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    final requiredOfficials = int.tryParse(args['officialsRequired'].toString()) ?? 0;

    if (selectedLists.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least two lists for the advanced method')),
      );
      return;
    }

    // Check that min/max are set for all lists
    for (var list in selectedLists) {
      if (list['minOfficials'] == null || list['maxOfficials'] == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please set minimum and maximum officials for all lists')),
        );
        return;
      }
    }

    int totalMin = selectedLists.fold(0, (sum, list) => sum + (list['minOfficials'] as int));
    int totalMax = selectedLists.fold(0, (sum, list) => sum + (list['maxOfficials'] as int));

    if (totalMin > requiredOfficials || totalMax < requiredOfficials) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Total min must be ≤ required officials, and total max must be ≥ required officials')),
      );
      return;
    }

    List<Map<String, dynamic>> selectedOfficials = [];
    for (var list in selectedLists) {
      final officials = (list['officials'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? [];
      selectedOfficials.addAll(officials);
    }

    final updatedArgs = {
      ...args,
      'selectedOfficials': selectedOfficials,
      'method': 'advanced',
      'selectedLists': selectedLists.map((list) => {
        'name': list['name'],
        'id': list['id'],
        'minOfficials': list['minOfficials'],
        'maxOfficials': list['maxOfficials'],
        'officials': list['officials'], // Include the game-specific officials for each list
      }).toList(),
    };

    // Check if we're in edit mode
    final isEditMode = args['isEdit'] as bool? ?? false;
    
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
      final gameService = GameService();
      
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
          
          // Update the SharedPreferences cache that _gameToMapWithOfficials relies on
          final prefs = await SharedPreferences.getInstance();
          final advancedData = {
            'selectedLists': gameData['selectedLists'],
            'selectedOfficials': gameData['selectedOfficials'] ?? [],
          };
          await prefs.setString('recent_advanced_selection_$databaseGameId', jsonEncode(advancedData));
          debugPrint('Updated advanced selection cache for game $databaseGameId');
          
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

    final dropdownItems = lists.isNotEmpty
        ? lists.map((list) {
            return DropdownMenuItem(
              value: list['name'] as String,
              child: Text(
                list['name'] as String,
                style: list['name'] == 'No saved lists' 
                  ? const TextStyle(color: Colors.red) 
                  : const TextStyle(color: primaryTextColor),
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
                      else if (selectedLists.isEmpty) ...[
                        Container(
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
                            child: DropdownButtonFormField<String>(
                              decoration: textFieldDecoration('Select First List'),
                              dropdownColor: darkSurface,
                              style: const TextStyle(color: primaryTextColor),
                              value: null,
                              onChanged: (newValue) {
                                if (newValue != null && newValue != 'No saved lists' && !selectedLists.any((l) => l['name'] == newValue)) {
                                  _addList(newValue);
                                }
                              },
                              items: dropdownItems,
                            ),
                          ),
                        ),
                      ],
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
                                        list['name'] as String,
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: primaryTextColor,
                                        ),
                                      ),
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
                                  TextField(
                                    decoration: textFieldDecoration('Minimum Officials'),
                                    keyboardType: TextInputType.number,
                                    style: const TextStyle(color: primaryTextColor),
                                    controller: TextEditingController(
                                      text: list['minOfficials']?.toString() ?? '',
                                    ),
                                    onChanged: (value) => _updateMinOfficials(index, value),
                                  ),
                                  const SizedBox(height: 10),
                                  TextField(
                                    decoration: textFieldDecoration('Maximum Officials'),
                                    keyboardType: TextInputType.number,
                                    style: const TextStyle(color: primaryTextColor),
                                    controller: TextEditingController(
                                      text: list['maxOfficials']?.toString() ?? '',
                                    ),
                                    onChanged: (value) => _updateMaxOfficials(index, value),
                                  ),
                                  const SizedBox(height: 10),
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
                      if (selectedLists.isNotEmpty) ...[
                        const SizedBox(height: 20),
                        Center(
                          child: Container(
                            width: 250,
                            child: ElevatedButton.icon(
                              onPressed: () {
                                String? selectedValue;
                                showDialog(
                                  context: context,
                                  builder: (context) => StatefulBuilder(
                                    builder: (context, setDialogState) => AlertDialog(
                                      backgroundColor: darkSurface,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        side: const BorderSide(
                                          color: efficialsYellow,
                                          width: 2,
                                        ),
                                      ),
                                      title: const Text(
                                        'Add Another List',
                                        style: TextStyle(
                                          color: primaryTextColor,
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      content: Container(
                                        decoration: BoxDecoration(
                                          color: darkBackground,
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(
                                            color: efficialsYellow.withOpacity(0.3),
                                            width: 1,
                                          ),
                                        ),
                                        child: Padding(
                                          padding: const EdgeInsets.all(12),
                                          child: DropdownButtonFormField<String>(
                                            decoration: textFieldDecoration('Select List'),
                                            dropdownColor: darkSurface,
                                            style: const TextStyle(color: primaryTextColor),
                                            value: selectedValue,
                                            onChanged: (newValue) {
                                              setDialogState(() {
                                                selectedValue = newValue;
                                              });
                                            },
                                            items: dropdownItems,
                                          ),
                                        ),
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(context),
                                          style: TextButton.styleFrom(
                                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                          ),
                                          child: const Text(
                                            'Cancel',
                                            style: TextStyle(
                                              color: secondaryTextColor,
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                        ElevatedButton(
                                          onPressed: selectedValue != null && 
                                                    selectedValue != 'No saved lists' && 
                                                    !selectedLists.any((l) => l['name'] == selectedValue)
                                              ? () {
                                                  _addList(selectedValue!);
                                                  Navigator.pop(context);
                                                }
                                              : null,
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: efficialsYellow,
                                            foregroundColor: efficialsBlack,
                                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                          ),
                                          child: const Text(
                                            'Add List',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
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
                            onPressed: selectedLists.length >= 2 ? _handleContinue : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: selectedLists.length >= 2 ? efficialsYellow : efficialsGray,
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