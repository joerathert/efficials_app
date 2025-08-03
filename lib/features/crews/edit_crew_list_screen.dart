import 'package:flutter/material.dart';
import '../../shared/theme.dart';
import '../../shared/services/repositories/crew_repository.dart';
import '../../shared/models/database_models.dart';
import '../../shared/utils/utils.dart';

class EditCrewListScreen extends StatefulWidget {
  const EditCrewListScreen({super.key});

  @override
  State<EditCrewListScreen> createState() => _EditCrewListScreenState();
}

class _EditCrewListScreenState extends State<EditCrewListScreen> {
  final CrewRepository _crewRepo = CrewRepository();
  final _nameController = TextEditingController();
  
  List<Crew> _allCrews = [];
  List<Crew> _filteredCrews = [];
  List<Crew> _selectedCrews = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String? _sport;
  List<String> _existingListNames = [];
  String _originalListName = '';
  int _listId = 0;

  @override
  void initState() {
    super.initState();
    _loadCrews();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null) {
      _originalListName = args['listName'] as String? ?? '';
      _listId = args['listId'] as int? ?? 0;
      _nameController.text = _originalListName;
      _existingListNames = List<String>.from(args['existingLists'] ?? []);
      
      // Load existing crew selection
      final existingCrews = args['crews'] as List<dynamic>? ?? [];
      _selectedCrews = existingCrews.map<Crew>((crewData) {
        final crewMap = Map<String, dynamic>.from(crewData as Map);
        return Crew(
          id: crewMap['id'] as int,
          name: crewMap['name'] as String,
          crewTypeId: 1, // Default crew type
          crewChiefId: 1, // Default crew chief
          createdBy: 1, // Default creator
          sportName: crewMap['sportName'] as String?,
          crewChiefName: crewMap['crewChiefName'] as String?,
          members: [], // Will be populated if needed
          isActive: true,
        );
      }).toList();
      
      if (_selectedCrews.isNotEmpty) {
        _sport = _selectedCrews.first.sportName;
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _loadCrews() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final crews = await _crewRepo.getAllCrews();
      
      // Only show active crews
      final availableCrews = crews.where((crew) => 
        crew.isActive
      ).toList();

      if (mounted) {
        setState(() {
          _allCrews = availableCrews;
          _applyFilters();
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

  void _applyFilters() {
    List<Crew> filtered = List.from(_allCrews);

    // Filter by sport if specified
    if (_sport != null && _sport != 'Unknown Sport') {
      filtered = filtered.where((crew) => 
        crew.sportName?.toLowerCase() == _sport!.toLowerCase()
      ).toList();
    }

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((crew) =>
        crew.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
        (crew.sportName?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false) ||
        (crew.crewChiefName?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false)
      ).toList();
    }

    setState(() {
      _filteredCrews = filtered;
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

  bool _isCrewSelected(Crew crew) {
    return _selectedCrews.any((c) => c.id == crew.id);
  }

  void _saveCrewList() {
    final listName = _nameController.text.trim();
    
    if (listName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a list name')),
      );
      return;
    }

    // Check if name changed and if new name already exists
    if (listName != _originalListName && _existingListNames.contains(listName)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('A list with this name already exists')),
      );
      return;
    }

    if (_selectedCrews.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one crew')),
      );
      return;
    }

    final crewListData = {
      'name': listName,
      'sport': _sport ?? 'Unknown Sport',
      'crews': _selectedCrews.map((crew) => {
        'id': crew.id,
        'name': crew.name,
        'sportName': crew.sportName,
        'memberCount': crew.members?.length ?? 0,
        'crewChiefName': crew.crewChiefName,
      }).toList(),
      'id': _listId,
    };

    Navigator.pop(context, crewListData);
  }

  @override
  Widget build(BuildContext context) {
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
      body: Column(
        children: [
          // Header and Name Input
          Container(
            padding: const EdgeInsets.all(20),
            color: darkSurface,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Edit Crew List',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: efficialsYellow,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _nameController,
                  style: const TextStyle(color: efficialsWhite),
                  decoration: InputDecoration(
                    labelText: 'List Name',
                    labelStyle: const TextStyle(color: efficialsGray),
                    hintText: 'Enter a name for your crew list',
                    hintStyle: TextStyle(color: Colors.grey[600]),
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
                ),
              ],
            ),
          ),
          
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
                setState(() {
                  _searchQuery = value;
                  _applyFilters();
                });
              },
            ),
          ),
          
          // Results count and selected count
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
                          return _buildCrewCard(crew);
                        },
                      ),
          ),
        ],
      ),
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
                onPressed: _saveCrewList,
                style: ElevatedButton.styleFrom(
                  backgroundColor: efficialsYellow,
                  foregroundColor: efficialsBlack,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  'Update List with ${_selectedCrews.length} ${_selectedCrews.length == 1 ? 'Crew' : 'Crews'}',
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

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: Colors.grey[600],
            ),
            const SizedBox(height: 16),
            Text(
              'No crews found',
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try adjusting your search terms\nor create new crews first',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCrewCard(Crew crew) {
    final memberCount = crew.members?.length ?? 0;
    final isSelected = _isCrewSelected(crew);

    return Card(
      color: isSelected ? efficialsYellow.withOpacity(0.1) : efficialsBlack,
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _toggleCrewSelection(crew),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Checkbox(
                value: isSelected,
                onChanged: (value) => _toggleCrewSelection(crew),
                activeColor: efficialsYellow,
                checkColor: efficialsBlack,
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: getSportIconColor(crew.sportName ?? 'Unknown').withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  getSportIcon(crew.sportName ?? 'Unknown'),
                  color: getSportIconColor(crew.sportName ?? 'Unknown'),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      crew.name,
                      style: const TextStyle(
                        color: efficialsWhite,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${crew.sportName} • $memberCount officials',
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 14,
                      ),
                    ),
                    if (crew.crewChiefName != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        'Chief: ${crew.crewChiefName}',
                        style: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
        ),
      ),
    );
  }
}