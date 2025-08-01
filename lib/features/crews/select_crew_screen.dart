import 'package:flutter/material.dart';
import '../../shared/theme.dart';
import '../../shared/services/repositories/crew_repository.dart';
import '../../shared/models/database_models.dart';

class SelectCrewScreen extends StatefulWidget {
  const SelectCrewScreen({super.key});

  @override
  State<SelectCrewScreen> createState() => _SelectCrewScreenState();
}

class _SelectCrewScreenState extends State<SelectCrewScreen> {
  final CrewRepository _crewRepo = CrewRepository();
  List<Crew> _availableCrews = [];
  List<Crew> _filteredCrews = [];
  List<Crew> _selectedCrews = [];
  bool _isLoading = true;
  String _searchQuery = '';
  bool _filtersApplied = false;
  Map<String, dynamic>? _filterSettings;

  @override
  void initState() {
    super.initState();
    // Don't load crews initially - wait for user to apply filters
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _loadAvailableCrews() async {
    try {
      setState(() {
        _isLoading = true;
      });

      // For now, load all crews. Later we'll add filtering based on game requirements
      final crews = await _crewRepo.getAllCrews();
      
      // Only show crews that are fully staffed and active
      final availableCrews = crews.where((crew) => 
        crew.isActive && crew.canBeHired
      ).toList();

      if (mounted) {
        setState(() {
          _availableCrews = availableCrews;
          _filteredCrews = availableCrews;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading crews: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _applySearch() {
    setState(() {
      if (_searchQuery.isEmpty) {
        _filteredCrews = _availableCrews;
      } else {
        _filteredCrews = _availableCrews.where((crew) =>
          crew.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (crew.sportName?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false) ||
          (crew.crewChiefName?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false)
        ).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    
    return Scaffold(
      backgroundColor: darkBackground,
      appBar: AppBar(
        backgroundColor: efficialsBlack,
        title: const Text(
          'Select Crew',
          style: TextStyle(color: efficialsWhite),
        ),
        iconTheme: const IconThemeData(color: efficialsWhite),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Search bar
          Container(
            padding: const EdgeInsets.all(16),
            color: efficialsBlack,
            child: TextField(
              style: const TextStyle(color: efficialsWhite),
              decoration: InputDecoration(
                hintText: 'Search crews...',
                hintStyle: TextStyle(color: Colors.grey[600]),
                prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
                filled: true,
                fillColor: darkBackground,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: efficialsYellow),
                ),
              ),
              onChanged: (value) {
                _searchQuery = value;
                _applySearch();
              },
            ),
          ),
          
          // Results count
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: darkSurface,
            child: Row(
              children: [
                Text(
                  '${_filteredCrews.length} ${_filteredCrews.length == 1 ? 'crew' : 'crews'} available',
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 14,
                  ),
                ),
                if (_selectedCrews.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: efficialsYellow.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${_selectedCrews.length} selected',
                      style: const TextStyle(
                        color: efficialsYellow,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
                const Spacer(),
                if (_filtersApplied) ...[
                  GestureDetector(
                    onTap: _clearFilters,
                    child: const Text(
                      'Clear filters',
                      style: TextStyle(
                        color: efficialsYellow,
                        fontSize: 14,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          
          // Crew list
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: efficialsYellow),
                  )
                : _filteredCrews.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _filteredCrews.length,
                        itemBuilder: (context, index) {
                          final crew = _filteredCrews[index];
                          return _buildCrewCard(crew, args);
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToFilters(args),
        backgroundColor: Colors.grey[600],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: const Icon(Icons.filter_list, size: 30, color: efficialsYellow),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: _selectedCrews.isNotEmpty
          ? Container(
              color: efficialsBlack,
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: MediaQuery.of(context).padding.bottom + 16,
              ),
              child: ElevatedButton(
                onPressed: _proceedWithSelectedCrews,
                style: ElevatedButton.styleFrom(
                  backgroundColor: efficialsYellow,
                  foregroundColor: efficialsBlack,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  'Continue with ${_selectedCrews.length} ${_selectedCrews.length == 1 ? 'Crew' : 'Crews'}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildCrewCard(Crew crew, Map<String, dynamic> args) {
    final memberCount = crew.members?.length ?? 0;
    final requiredCount = crew.requiredOfficials ?? 0;
    final isSelected = _selectedCrews.any((c) => c.id == crew.id);

    return Card(
      color: isSelected ? efficialsYellow.withOpacity(0.1) : efficialsBlack,
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _toggleCrewSelection(crew),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Checkbox(
                    value: isSelected,
                    onChanged: (value) => _toggleCrewSelection(crew),
                    activeColor: efficialsYellow,
                    checkColor: efficialsBlack,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      crew.name,
                      style: const TextStyle(
                        color: efficialsWhite,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'AVAILABLE',
                      style: TextStyle(
                        color: Colors.green,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.only(left: 48), // Align with text after checkbox
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.sports,
                          color: Colors.grey[400],
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${crew.sportName}',
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.people,
                          color: Colors.grey[400],
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '$memberCount officials',
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Icon(
                          Icons.person,
                          color: Colors.grey[400],
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Chief: ${crew.crewChiefName}',
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 14,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
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

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _filtersApplied ? Icons.search_off : Icons.filter_list,
              size: 64,
              color: Colors.grey[600],
            ),
            const SizedBox(height: 16),
            Text(
              _filtersApplied ? 'No Crews Found' : 'Find Your Crew',
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _filtersApplied 
                  ? 'Try adjusting your filters to see more crews'
                  : 'Click the Filter button to search for available crews',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            if (!_filtersApplied) ...[
              const SizedBox(height: 24),
              Icon(
                Icons.arrow_downward,
                size: 32,
                color: efficialsYellow,
              ),
              const SizedBox(height: 8),
              Text(
                'Tap the yellow filter button below',
                style: TextStyle(
                  color: efficialsYellow,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _navigateToFilters(Map<String, dynamic> args) async {
    final result = await Navigator.pushNamed(
      context,
      '/filter_crews_settings',
      arguments: {
        ...args,
        'currentFilters': _filterSettings,
      },
    );

    if (result != null) {
      setState(() {
        _filterSettings = result as Map<String, dynamic>;
        _filtersApplied = _filterSettings!.isNotEmpty;
      });
      
      // Apply filters and reload crews
      await _loadFilteredCrews();
    }
  }

  Future<void> _loadFilteredCrews() async {
    if (_filterSettings == null || _filterSettings!.isEmpty) {
      // No filters applied, load all crews
      await _loadAvailableCrews();
      return;
    }

    try {
      setState(() {
        _isLoading = true;
      });

      // Extract filter settings
      final ihsaCertifications = <String>[];
      if (_filterSettings!['ihsaRegistered'] == true) ihsaCertifications.add('IHSA Registered');
      if (_filterSettings!['ihsaRecognized'] == true) ihsaCertifications.add('IHSA Recognized');
      if (_filterSettings!['ihsaCertified'] == true) ihsaCertifications.add('IHSA Certified');

      final competitionLevels = <String>[];
      final competitionLevelMap = _filterSettings!['competitionLevels'] as Map<String, dynamic>?;
      if (competitionLevelMap != null) {
        competitionLevelMap.forEach((level, isSelected) {
          if (isSelected == true) {
            competitionLevels.add(level);
          }
        });
      }

      final maxDistance = _filterSettings!['radius'] as int?;

      // Get game location from arguments
      final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
      final gameLocation = args['locationData'] as Map<String, dynamic>?;

      // Apply filters using the advanced filtering method
      final filteredCrews = await _crewRepo.getFilteredCrews(
        ihsaCertifications: ihsaCertifications.isNotEmpty ? ihsaCertifications : null,
        competitionLevels: competitionLevels.isNotEmpty ? competitionLevels : null,
        maxDistanceMiles: maxDistance,
        gameLocation: gameLocation,
      );

      if (mounted) {
        setState(() {
          _availableCrews = filteredCrews;
          _filteredCrews = filteredCrews;
          _isLoading = false;
        });
        
        // Apply search filter if there's a search query
        if (_searchQuery.isNotEmpty) {
          _applySearch();
        }
      }
    } catch (e) {
      print('Error loading filtered crews: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _clearFilters() {
    setState(() {
      _filterSettings = null;
      _filtersApplied = false;
      _availableCrews = [];
      _filteredCrews = [];
    });
  }

  void _toggleCrewSelection(Crew crew) {
    setState(() {
      final isSelected = _selectedCrews.any((c) => c.id == crew.id);
      if (isSelected) {
        _selectedCrews.removeWhere((c) => c.id == crew.id);
      } else {
        _selectedCrews.add(crew);
      }
    });
  }

  void _proceedWithSelectedCrews() {
    if (_selectedCrews.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one crew to proceed.'),
        ),
      );
      return;
    }

    final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    
    Navigator.pushNamed(
      context,
      '/review_game_info',
      arguments: {
        ...args,
        'selectedCrews': _selectedCrews,
        'selectedCrew': _selectedCrews.length == 1 ? _selectedCrews.first : null, // For backward compatibility
        'method': 'hire_crew',
      },
    );
  }
}