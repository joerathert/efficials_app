import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../shared/theme.dart';
import '../../shared/models/database_models.dart';
import '../../shared/services/repositories/official_repository.dart';
import '../../shared/services/repositories/advanced_method_repository.dart';
import '../../shared/services/user_session_service.dart';

class AdvancedMethodSetupScreen extends StatefulWidget {
  const AdvancedMethodSetupScreen({super.key});

  @override
  State<AdvancedMethodSetupScreen> createState() => _AdvancedMethodSetupScreenState();
}

class _AdvancedMethodSetupScreenState extends State<AdvancedMethodSetupScreen> {
  final OfficialRepository _officialRepo = OfficialRepository();
  final AdvancedMethodRepository _advancedRepo = AdvancedMethodRepository();
  
  List<Map<String, dynamic>> availableLists = [];
  List<Map<String, dynamic>> selectedMultipleLists = [];
  bool _isLoading = true;
  bool _isSaving = false;
  
  int? gameId;
  String? sportName;
  int? currentUserId;
  int officialsRequired = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null) {
      gameId = args['gameId'] as int?;
      sportName = args['sportName'] as String?;
      _loadData();
    }
  }

  Future<void> _loadData() async {
    if (gameId == null) return;
    
    try {
      setState(() => _isLoading = true);
      
      // Get current user
      final userSession = UserSessionService.instance;
      currentUserId = await userSession.getCurrentUserId();
      
      if (currentUserId == null) return;

      // Get game info to fetch officials required
      final gameResults = await _advancedRepo.rawQuery('''
        SELECT officials_required FROM games WHERE id = ?
      ''', [gameId!]);
      
      if (gameResults.isNotEmpty) {
        officialsRequired = gameResults.first['officials_required'] as int? ?? 0;
      }

      // Get available lists for this sport
      final listsCount = await _officialRepo.getListsCountBySport(currentUserId!, sportName ?? '');
      
      if (listsCount > 0) {
        // Get actual list data
        final results = await _officialRepo.rawQuery('''
          SELECT ol.id, ol.name, COUNT(olm.official_id) as member_count
          FROM official_lists ol
          LEFT JOIN official_list_members olm ON ol.id = olm.list_id
          INNER JOIN sports s ON ol.sport_id = s.id
          WHERE ol.user_id = ? AND s.name = ?
          GROUP BY ol.id, ol.name
          ORDER BY ol.name ASC
        ''', [currentUserId!, sportName ?? '']);
        
        availableLists = results;
      }

      // Load existing quotas if any
      final existingQuotas = await _advancedRepo.getGameListQuotas(gameId!);
      
      if (existingQuotas.isNotEmpty) {
        // Convert existing quotas to selectedMultipleLists format
        selectedMultipleLists = existingQuotas.map((quota) {
          final listName = availableLists.firstWhere(
            (list) => list['id'] == quota.listId,
            orElse: () => {'name': 'Unknown List'},
          )['name'] as String;
          
          return {
            'list': listName,
            'min': quota.minOfficials,
            'max': quota.maxOfficials,
          };
        }).toList();
      } else {
        // Initialize with 2 empty list slots by default
        selectedMultipleLists = [
          {'list': null, 'min': 0, 'max': 1},
          {'list': null, 'min': 0, 'max': 1},
        ];
      }

      setState(() => _isLoading = false);
    } catch (e) {
      debugPrint('Error loading data: $e');
      setState(() => _isLoading = false);
      _showErrorDialog('Error loading data: $e');
    }
  }

  Future<void> _saveQuotas() async {
    if (gameId == null) return;

    // Validate quotas
    final validationError = _validateQuotas();
    if (validationError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(validationError), backgroundColor: Colors.red),
      );
      return;
    }

    try {
      setState(() => _isSaving = true);

      // Convert selectedMultipleLists to database format
      final quotas = <Map<String, dynamic>>[];
      
      for (final listConfig in selectedMultipleLists) {
        final listName = listConfig['list'] as String?;
        if (listName != null && listName.isNotEmpty) {
          // Find the list ID from availableLists
          final listData = availableLists.firstWhere(
            (list) => list['name'] == listName,
            orElse: () => <String, dynamic>{},
          );
          
          if (listData.isNotEmpty) {
            quotas.add({
              'listId': listData['id'],
              'minOfficials': listConfig['min'] as int,
              'maxOfficials': listConfig['max'] as int,
            });
          }
        }
      }

      // Save quotas
      await _advancedRepo.setGameListQuotas(gameId!, quotas);

      // Update game method to 'advanced'
      await _advancedRepo.update(
        'games',
        {
          'method': 'advanced',
          'updated_at': DateTime.now().toIso8601String(),
        },
        'id = ?',
        [gameId!],
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Advanced Method quotas saved successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context, true); // Return success
      
    } catch (e) {
      debugPrint('Error saving quotas: $e');
      _showErrorDialog('Error saving quotas: $e');
    } finally {
      setState(() => _isSaving = false);
    }
  }

  String? _validateQuotas() {
    if (availableLists.isEmpty) {
      return 'No official lists available. Please create official lists first.';
    }

    int totalMin = 0;
    int totalMax = 0;
    int configuredListsCount = 0;

    for (final listConfig in selectedMultipleLists) {
      final listName = listConfig['list'] as String?;
      final min = listConfig['min'] as int;
      final max = listConfig['max'] as int;
      
      if (listName != null && listName.isNotEmpty) {
        configuredListsCount++;
        
        if (min < 0) {
          return 'Minimum officials cannot be negative for $listName';
        }
        
        if (max < min) {
          return 'Maximum cannot be less than minimum for $listName';
        }

        // Only count if this quota is actually used (max > 0)
        if (max > 0) {
          totalMin += min;
          totalMax += max;
        }
      }
    }

    if (configuredListsCount == 0) {
      return 'Please select at least one officials list';
    }

    if (totalMax == 0) {
      return 'At least one list must have a maximum greater than 0';
    }

    return null; // No validation errors
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: darkBackground,
      appBar: AppBar(
        backgroundColor: efficialsBlack,
        title: const Text(
          'Advanced Method Setup',
          style: TextStyle(color: efficialsYellow, fontSize: 18),
        ),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: efficialsWhite),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: efficialsYellow))
          : _buildContent(),
      bottomNavigationBar: _isLoading
          ? null
          : Container(
              color: efficialsBlack,
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 16,
                bottom: MediaQuery.of(context).padding.bottom + 16,
              ),
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveQuotas,
                style: ElevatedButton.styleFrom(
                  backgroundColor: efficialsYellow,
                  foregroundColor: efficialsBlack,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isSaving
                    ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(efficialsBlack),
                            ),
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Saving...',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      )
                    : const Text(
                        'Save Advanced Method Setup',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
    );
  }

  Widget _buildContent() {
    if (availableLists.isEmpty) {
      return _buildNoListsMessage();
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 20),
          _buildMultipleListsConfiguration(),
          const SizedBox(height: 20),
          _buildSummary(),
          const SizedBox(height: 100), // Bottom padding for navigation bar
        ],
      ),
    );
  }

  Widget _buildNoListsMessage() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.list_alt,
              size: 80,
              color: secondaryTextColor,
            ),
            const SizedBox(height: 16),
            Text(
              'No Official Lists Found',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: primaryTextColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              sportName != null 
                  ? 'You need to create official lists for $sportName before using the Advanced Method.'
                  : 'You need to create official lists before using the Advanced Method.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: secondaryTextColor,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/lists_of_officials', arguments: {
                  'sport': sportName ?? 'Unknown Sport',
                  'fromGameCreation': false,
                  'fromTemplateCreation': false,
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: efficialsYellow,
                foregroundColor: efficialsBlack,
              ),
              child: const Text('Create Official Lists'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Advanced Method Setup',
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: efficialsYellow,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Configure minimum and maximum officials from each list. This ensures proper experience distribution.',
          style: const TextStyle(
            fontSize: 16,
            color: Colors.white70,
          ),
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: efficialsYellow.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: efficialsYellow.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.people,
                color: efficialsYellow,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Total Officials Required',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: efficialsYellow,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$officialsRequired officials needed for this $sportName game',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMultipleListsConfiguration() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          // Header row with title and + button
          Row(
            children: [
              const Text(
                'Configure Multiple Lists',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              if (selectedMultipleLists.length < 3)
                IconButton(
                  onPressed: () {
                    setState(() {
                      selectedMultipleLists.add({'list': null, 'min': 0, 'max': 1});
                    });
                  },
                  icon: const Icon(Icons.add_circle, color: efficialsYellow),
                ),
            ],
          ),
          const SizedBox(height: 12),
          // List items
          ...selectedMultipleLists.asMap().entries.map((entry) {
            final listIndex = entry.key;
            final listConfig = entry.value;
            return _buildMultipleListItem(listIndex, listConfig);
          }),
        ],
      ),
    );
  }

  Widget _buildMultipleListItem(int listIndex, Map<String, dynamic> listConfig) {
    final validLists = availableLists.where((list) => list['name'] != null && list['name'] != 'No saved lists' && list['name'] != '+ Create new list').toList();
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: darkSurface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                'List ${listIndex + 1}',
                style: const TextStyle(
                  color: efficialsYellow,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              if (selectedMultipleLists.length > 2)
                IconButton(
                  onPressed: () {
                    setState(() {
                      selectedMultipleLists.removeAt(listIndex);
                    });
                  },
                  icon: const Icon(Icons.remove_circle, color: Colors.red, size: 20),
                ),
            ],
          ),
          const SizedBox(height: 8),
          // List selection dropdown
          DropdownButtonFormField<String>(
            decoration: _textFieldDecoration('Select Officials List'),
            value: listConfig['list'],
            style: const TextStyle(color: Colors.white, fontSize: 14),
            dropdownColor: darkSurface,
            onChanged: (value) {
              setState(() {
                listConfig['list'] = value;
              });
            },
            items: validLists.map((list) {
              return DropdownMenuItem(
                value: list['name'] as String,
                child: Text(
                  list['name'] as String,
                  style: const TextStyle(color: Colors.white),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 8),
          // Min/Max configuration
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<int>(
                  decoration: _textFieldDecoration('Min'),
                  value: listConfig['min'],
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  dropdownColor: darkSurface,
                  onChanged: (value) {
                    setState(() {
                      listConfig['min'] = value;
                    });
                  },
                  items: List.generate(10, (i) => i).map((num) {
                    return DropdownMenuItem(
                      value: num,
                      child: Text(
                        num.toString(),
                        style: const TextStyle(color: Colors.white),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButtonFormField<int>(
                  decoration: _textFieldDecoration('Max'),
                  value: listConfig['max'],
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  dropdownColor: darkSurface,
                  onChanged: (value) {
                    setState(() {
                      listConfig['max'] = value;
                    });
                  },
                  items: List.generate(10, (i) => i + 1).map((num) {
                    return DropdownMenuItem(
                      value: num,
                      child: Text(
                        num.toString(),
                        style: const TextStyle(color: Colors.white),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  InputDecoration _textFieldDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.grey),
      filled: true,
      fillColor: darkBackground,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey.withOpacity(0.3)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey.withOpacity(0.3)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: efficialsYellow),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    );
  }



  Widget _buildSummary() {
    final activeListConfigs = selectedMultipleLists.where((config) => 
      config['list'] != null && config['list'] != '' && config['max'] > 0).toList();
    final totalMin = activeListConfigs.fold<int>(0, (sum, config) => sum + (config['min'] as int));
    final totalMax = activeListConfigs.fold<int>(0, (sum, config) => sum + (config['max'] as int));

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: efficialsYellow.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: efficialsYellow.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Summary',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: efficialsYellow,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Total Officials: $totalMin minimum, $totalMax maximum',
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Active Lists: ${activeListConfigs.length}',
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

}