import 'package:flutter/material.dart';
import '../../shared/theme.dart';
import '../../shared/services/user_session_service.dart';
import '../../shared/services/repositories/list_repository.dart';
import '../../shared/utils/utils.dart';
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
  ListRepository _listRepository = ListRepository();

  @override
  void initState() {
    super.initState();
    lists = [
      {'name': 'No saved lists', 'id': -1},
      {'name': '+ Create new list', 'id': 0},
    ];
    _fetchLists();
  }
  

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null) {
      setState(() {
        isFromGameCreation = args['fromGameCreation'] == true;
      });

      // Handle new list creation from review_list_screen
      if (args['newListCreated'] != null) {
        final newListData = args['newListCreated'] as Map<String, dynamic>;
        _handleNewListFromReview(newListData);
      } else if (lists.length <= 2 && lists[0]['name'] == 'No saved lists') {
        _fetchLists();
      }
    }
    
    // Always refresh the lists when this screen becomes active
    // This ensures we see updated counts when returning from editing workflows
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _fetchLists();
      }
    });
  }

  Future<void> _fetchLists() async {
    try {
      final userId = await UserSessionService.instance.getCurrentUserId();
      if (userId == null) {
        setState(() {
          lists = [
            {'name': 'No saved lists', 'id': -1},
            {'name': '+ Create new list', 'id': 0},
          ];
          isLoading = false;
        });
        return;
      }

      final userLists = await _listRepository.getLists(userId);
      
      setState(() {
        lists.clear();
        
        if (userLists.isNotEmpty) {
          lists = userLists.map((list) {
            return {
              'name': list['name'],
              'id': list['id'],
              'sport': list['sport_name'],
              'officials': list['officials'] ?? [],
            };
          }).toList();
        }
        
        if (lists.isEmpty) {
          lists.add({'name': 'No saved lists', 'id': -1});
        }
        lists.add({'name': '+ Create new list', 'id': 0});
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        lists = [
          {'name': 'No saved lists', 'id': -1},
          {'name': '+ Create new list', 'id': 0},
        ];
        isLoading = false;
      });
      debugPrint('Error fetching lists: $e');
    }
  }

  Future<void> _saveLists() async {
    // No longer needed - data is saved directly to database
    // This method is kept for compatibility but does nothing
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
            child:
                const Text('Cancel', style: TextStyle(color: efficialsYellow)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await _listRepository.deleteList(listId);
                setState(() {
                  lists.removeWhere((list) => list['id'] == listId);
                  if (lists.isEmpty ||
                      (lists.length == 1 && lists[0]['id'] == 0)) {
                    lists.insert(0, {'name': 'No saved lists', 'id': -1});
                  }
                  selectedList = null; // Reset to show hint after deletion
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('List deleted successfully')),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error deleting list: $e')),
                );
              }
            },
            child:
                const Text('Delete', style: TextStyle(color: efficialsYellow)),
          ),
        ],
      ),
    );
  }

  void _handleContinue() {
    final args =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
    if (args == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: Game data not found')),
      );
      return;
    }
    final selected = lists.firstWhere((l) => l['name'] == selectedList);
    final officialsRaw = selected['officials'];
    List<Map<String, dynamic>> selectedOfficials = [];

    if (officialsRaw != null) {
      if (officialsRaw is List) {
        selectedOfficials = (officialsRaw)
            .map((official) => Map<String, dynamic>.from(official as Map))
            .toList();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Invalid officials data in the selected list')),
        );
        return;
      }
    }

    final updatedArgs = {
      ...args,
      'selectedOfficials': selectedOfficials,
      'method': 'use_list',
      'selectedListName': selectedList,
    };

    // Always pop back with the updated arguments
    // The receiving screen will handle the navigation appropriately
    Navigator.pop(context, updatedArgs);
  }

  @override
  Widget build(BuildContext context) {
    final args =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
    final sport = args?['sport'] as String? ?? 'Unknown Sport';
    final fromTemplateCreation = args?['fromTemplateCreation'] == true;

    // Filter out special items for the main list display
    List<Map<String, dynamic>> actualLists =
        lists.where((list) => list['id'] != 0 && list['id'] != -1).toList();


    // If coming from template creation, filter by sport
    if (fromTemplateCreation && sport != 'Unknown Sport') {
      actualLists = actualLists.where((list) {
        final listSport = list['sport'] as String?;
        // Show lists that match the sport or have no sport assigned (legacy lists)
        return listSport == null || listSport.isEmpty || listSport == sport;
      }).toList();
    }

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
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Lists of Officials',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: primaryTextColor,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Manage your saved lists of officials',
                style: TextStyle(
                  fontSize: 16,
                  color: secondaryTextColor,
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : actualLists.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.people,
                                  size: 80,
                                  color: secondaryTextColor,
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  'No official lists found',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: primaryTextColor,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'Create your first list to get started',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: secondaryTextColor,
                                  ),
                                ),
                                const SizedBox(height: 24),
                                Container(
                                  width: 250,
                                  child: ElevatedButton.icon(
                                    onPressed: () async {
                                      final existingListNames = actualLists
                                          .map((list) => list['name'] as String)
                                          .toList();

                                      // Get current user info
                                      final userInfo = await UserSessionService
                                          .instance
                                          .getCurrentUserInfo();
                                      final isAssigner = userInfo != null &&
                                          userInfo['schedulerType'] ==
                                              'assigner';
                                      final assignerSport = isAssigner
                                          ? userInfo['sport'] as String?
                                          : null;

                                      final Map<String, dynamic>
                                          navigationArgs = {
                                        'existingLists': existingListNames,
                                        'fromGameCreation': isFromGameCreation,
                                        'sport':
                                            isAssigner && assignerSport != null
                                                ? assignerSport
                                                : sport,
                                      };

                                      if (args != null) {
                                        navigationArgs.addAll(
                                            Map<String, dynamic>.from(args));
                                      }

                                      final route =
                                          isAssigner && assignerSport != null
                                              ? '/name_list'
                                              : '/create_new_list';
                                      final effectiveSport =
                                          isAssigner && assignerSport != null
                                              ? assignerSport
                                              : sport;

                                      Navigator.pushNamed(
                                        context,
                                        route,
                                        arguments: navigationArgs,
                                      ).then((result) async {
                                        if (result != null) {
                                          await _handleNewListResult(
                                              result, effectiveSport);
                                        }
                                      });
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
                                    icon: const Icon(Icons.add,
                                        color: efficialsBlack),
                                    label: const Text(
                                      'Create New List',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )
                        : LayoutBuilder(
                            builder: (context, constraints) {
                              // Calculate available space for the list
                              const buttonHeight =
                                  60.0; // Approximate button height
                              const padding =
                                  20.0; // Padding between list and button
                              const minBottomSpace =
                                  100.0; // Minimum space from bottom to avoid navigation bar

                              final maxListHeight = constraints.maxHeight -
                                  buttonHeight -
                                  padding -
                                  minBottomSpace;

                              return Column(
                                children: [
                                  Container(
                                    constraints: BoxConstraints(
                                      maxHeight: maxListHeight > 0
                                          ? maxListHeight
                                          : constraints.maxHeight * 0.6,
                                    ),
                                    child: ListView.builder(
                                      shrinkWrap: true,
                                      itemCount: actualLists.length,
                                      itemBuilder: (context, index) {
                                        final list = actualLists[index];
                                        final listName = list['name'] as String;
                                        final officials = list['officials']
                                                as List<dynamic>? ??
                                            [];
                                        final officialCount = officials.length;

                                        return Padding(
                                          padding: const EdgeInsets.only(
                                              bottom: 12.0),
                                          child: Container(
                                            decoration: BoxDecoration(
                                              color: darkSurface,
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black
                                                      .withOpacity(0.3),
                                                  spreadRadius: 1,
                                                  blurRadius: 3,
                                                  offset: const Offset(0, 1),
                                                ),
                                              ],
                                            ),
                                            child: Padding(
                                              padding: const EdgeInsets.all(16),
                                              child: Row(
                                                children: [
                                                  Container(
                                                    padding:
                                                        const EdgeInsets.all(
                                                            12),
                                                    decoration: BoxDecoration(
                                                      color: getSportIconColor(
                                                              list['sport']
                                                                      as String? ??
                                                                  sport)
                                                          .withOpacity(0.1),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              8),
                                                    ),
                                                    child: Icon(
                                                      getSportIcon(list['sport']
                                                              as String? ??
                                                          sport),
                                                      color: getSportIconColor(
                                                          list['sport']
                                                                  as String? ??
                                                              sport),
                                                      size: 24,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 16),
                                                  Expanded(
                                                    child: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        Text(
                                                          listName,
                                                          style:
                                                              const TextStyle(
                                                            fontSize: 18,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            color:
                                                                primaryTextColor,
                                                          ),
                                                        ),
                                                        const SizedBox(
                                                            height: 4),
                                                        Text(
                                                          '$officialCount official${officialCount == 1 ? '' : 's'}',
                                                          style:
                                                              const TextStyle(
                                                            fontSize: 14,
                                                            color:
                                                                secondaryTextColor,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  Row(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      IconButton(
                                                        onPressed: () {
                                                          Navigator.pushNamed(
                                                            context,
                                                            '/edit_list',
                                                            arguments: {
                                                              'listName':
                                                                  listName,
                                                              'listId':
                                                                  list['id']
                                                                      as int,
                                                              'officials': officials
                                                                  .map((official) => Map<
                                                                          String,
                                                                          dynamic>.from(
                                                                      official
                                                                          as Map))
                                                                  .toList(),
                                                            },
                                                          ).then(
                                                              (result) async {
                                                            if (result !=
                                                                null) {
                                                              await _handleEditListResult(
                                                                  result, list);
                                                            }
                                                          });
                                                        },
                                                        icon: const Icon(
                                                          Icons.edit,
                                                          color:
                                                              efficialsYellow,
                                                          size: 20,
                                                        ),
                                                        tooltip: 'Edit List',
                                                      ),
                                                      IconButton(
                                                        onPressed: () {
                                                          _showDeleteConfirmationDialog(
                                                              listName,
                                                              list['id']
                                                                  as int);
                                                        },
                                                        icon: Icon(
                                                          Icons.delete_outline,
                                                          color: Colors
                                                              .red.shade600,
                                                          size: 20,
                                                        ),
                                                        tooltip: 'Delete List',
                                                      ),
                                                      if (isFromGameCreation)
                                                        IconButton(
                                                          onPressed: () {
                                                            setState(() {
                                                              selectedList =
                                                                  listName;
                                                            });
                                                            _handleContinue();
                                                          },
                                                          icon: const Icon(
                                                            Icons.arrow_forward,
                                                            color: Colors.green,
                                                            size: 20,
                                                          ),
                                                          tooltip:
                                                              'Use This List',
                                                        ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  Center(
                                    child: Container(
                                      width: 250,
                                      child: ElevatedButton.icon(
                                        onPressed: () async {
                                          final existingListNames = actualLists
                                              .map((list) =>
                                                  list['name'] as String)
                                              .toList();

                                          // Get current user info
                                          final userInfo = await UserSessionService
                                              .instance
                                              .getCurrentUserInfo();
                                          final isAssigner = userInfo != null &&
                                              userInfo['schedulerType'] ==
                                                  'assigner';
                                          final assignerSport = isAssigner
                                              ? userInfo['sport'] as String?
                                              : null;

                                          final Map<String, dynamic>
                                              navigationArgs = {
                                            'existingLists': existingListNames,
                                            'fromGameCreation': isFromGameCreation,
                                            'sport':
                                                isAssigner && assignerSport != null
                                                    ? assignerSport
                                                    : sport,
                                          };

                                          if (args != null) {
                                            navigationArgs.addAll(
                                                Map<String, dynamic>.from(args));
                                          }

                                          final route =
                                              isAssigner && assignerSport != null
                                                  ? '/name_list'
                                                  : '/create_new_list';
                                          final effectiveSport =
                                              isAssigner && assignerSport != null
                                                  ? assignerSport
                                                  : sport;

                                          Navigator.pushNamed(
                                            context,
                                            route,
                                            arguments: navigationArgs,
                                          ).then((result) async {
                                            if (result != null) {
                                              await _handleNewListResult(
                                                  result, effectiveSport);
                                            }
                                          });
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: efficialsYellow,
                                          foregroundColor: efficialsBlack,
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 15, horizontal: 32),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                        ),
                                        icon: const Icon(Icons.add,
                                            color: efficialsBlack),
                                        label: const Text(
                                          'Create New List',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleNewListResult(dynamic result, String sport) async {
    // Refresh lists from database
    await _fetchLists();
    
    final newList = result as Map<String, dynamic>;
    setState(() {
      selectedList = newList['listName'] as String;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('List created successfully!')),
    );
  }

  Future<void> _handleEditListResult(
      dynamic result, Map<String, dynamic> originalList) async {
    final updatedList = result as Map<String, dynamic>;
    final listId = updatedList['id'] as int?;
    
    // Refresh lists from database
    await _fetchLists();
    
    setState(() {
      selectedList = updatedList['name'] as String;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('List updated successfully!')),
    );
  }

  Future<void> _handleNewListFromReview(
      Map<String, dynamic> newListData) async {
    await _fetchLists(); // Refresh the lists from database

    setState(() {
      selectedList = newListData['listName'] as String;
    });

    // Show success message
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Your list was created successfully!'),
          backgroundColor: darkSurface,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }
}
