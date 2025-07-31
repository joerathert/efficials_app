import 'package:flutter/material.dart';
import '../../shared/theme.dart';
import '../../shared/services/repositories/crew_repository.dart';
import '../../shared/services/repositories/official_repository.dart';
import '../../shared/services/user_session_service.dart';
import '../../shared/models/database_models.dart';

class SelectCrewMembersScreen extends StatefulWidget {
  final String crewName;
  final CrewType crewType;
  final List<String> competitionLevels;
  final int currentUserId;

  const SelectCrewMembersScreen({
    super.key,
    required this.crewName,
    required this.crewType,
    required this.competitionLevels,
    required this.currentUserId,
  });

  @override
  State<SelectCrewMembersScreen> createState() =>
      _SelectCrewMembersScreenState();
}

class _SelectCrewMembersScreenState extends State<SelectCrewMembersScreen> {
  final CrewRepository _crewRepo = CrewRepository();
  final OfficialRepository _officialRepo = OfficialRepository();
  final _searchController = TextEditingController();

  List<Map<String, dynamic>> _availableOfficials = [];
  List<Map<String, dynamic>> _filteredOfficials = [];
  List<Map<String, dynamic>> _selectedMembers = [];
  bool _isLoading = true;
  bool _isCreating = false;
  int? _currentUserOfficialId;

  @override
  void initState() {
    super.initState();
    _loadOfficials();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadOfficials() async {
    try {
      setState(() {
        _isLoading = true;
      });

      // First, find the official ID for the current user (crew chief)
      final currentUserOfficial = await _officialRepo.rawQuery(
        'SELECT id FROM officials WHERE user_id = ? OR official_user_id = ?', 
        [widget.currentUserId, widget.currentUserId]
      );
      
      if (currentUserOfficial.isNotEmpty) {
        _currentUserOfficialId = currentUserOfficial.first['id'] as int;
      }

      // Use the same method as populate_roster_screen to get officials with city/state data
      final allSports = await _officialRepo.rawQuery('SELECT id FROM sports LIMIT 1');
      if (allSports.isEmpty) {
        throw Exception('No sports found in database');
      }
      final sportId = allSports.first['id'] as int;
      final allOfficials = await _officialRepo.getOfficialsBySport(sportId);
      
      // Filter out the current user (crew chief) from the available officials
      final officials = allOfficials.where((official) {
        return official['id'] != _currentUserOfficialId;
      }).toList();

      if (mounted) {
        setState(() {
          _availableOfficials = officials;
          _filteredOfficials = []; // Start with empty list
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading officials: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _showErrorDialog('Failed to load officials. Please try again.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final requiredCount = widget.crewType.requiredOfficials;
    final needToSelect = requiredCount - 1; // Subtract 1 for crew chief

    return Scaffold(
      backgroundColor: darkBackground,
      appBar: AppBar(
        backgroundColor: efficialsBlack,
        title: const Text(
          'Select Crew Members',
          style: TextStyle(color: efficialsWhite),
        ),
        iconTheme: const IconThemeData(color: efficialsWhite),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: efficialsYellow),
            )
          : Column(
              children: [
                _buildHeader(needToSelect),
                Expanded(child: _buildMembersList(needToSelect)),
                _buildBottomBar(needToSelect),
              ],
            ),
    );
  }

  Widget _buildHeader(int needToSelect) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            efficialsBlack,
            darkSurface,
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.crewName,
            style: const TextStyle(
              color: efficialsYellow,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${widget.crewType.sportName} - ${widget.crewType.requiredOfficials} Officials',
            style: TextStyle(
              color: Colors.grey[300],
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: efficialsYellow.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: efficialsYellow.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.info_outline,
                  color: efficialsYellow,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'You are the crew chief. Select $needToSelect additional members to complete your crew.',
                    style: const TextStyle(
                      color: efficialsWhite,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Selected: ${_selectedMembers.length} of $needToSelect',
            style: TextStyle(
              color: _selectedMembers.length == needToSelect
                  ? Colors.green
                  : Colors.grey[400],
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMembersList(int needToSelect) {
    return Column(
      children: [
        // Search Field
        Container(
          padding: const EdgeInsets.all(20),
          child: TextFormField(
            controller: _searchController,
            style: const TextStyle(color: efficialsWhite),
            decoration: InputDecoration(
              hintText: 'Type official\'s name to search...',
              hintStyle: TextStyle(color: Colors.grey[600]),
              prefixIcon: const Icon(Icons.search, color: efficialsYellow),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, color: efficialsYellow),
                      onPressed: () {
                        setState(() {
                          _searchController.clear();
                          _filteredOfficials =
                              []; // Clear list when clearing search
                        });
                      },
                    )
                  : null,
              filled: true,
              fillColor: efficialsBlack,
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
                if (value.isEmpty) {
                  _filteredOfficials =
                      []; // Show empty list when no search text
                } else {
                  // Filter officials and sort alphabetically
                  _filteredOfficials = _availableOfficials
                      .where((official) => official['name']
                          .toLowerCase()
                          .contains(value.toLowerCase()))
                      .toList()
                    ..sort((a, b) => a['name']
                        .toLowerCase()
                        .compareTo(b['name'].toLowerCase()));
                }
              });
            },
          ),
        ),
        // Officials List
        Expanded(
          child: _filteredOfficials.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: _filteredOfficials.length,
                  itemBuilder: (context, index) {
                    final official = _filteredOfficials[index];
                    final isSelected = _selectedMembers.contains(official);
                    final canSelect = _selectedMembers.length < needToSelect || isSelected;

                    return Container(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? efficialsYellow.withOpacity(0.1)
                            : darkSurface,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected
                              ? efficialsYellow.withOpacity(0.5)
                              : Colors.transparent,
                        ),
                      ),
                      child: ListTile(
                        leading: IconButton(
                          icon: Icon(
                            isSelected ? Icons.check_circle : Icons.add_circle,
                            color: isSelected ? Colors.green : efficialsYellow,
                            size: 36,
                          ),
                          onPressed: canSelect
                              ? () {
                                  setState(() {
                                    if (isSelected) {
                                      _selectedMembers.remove(official);
                                    } else {
                                      _selectedMembers.add(official);
                                    }
                                  });
                                }
                              : null,
                        ),
                        title: Text(
                          official['name'],
                          style: TextStyle(
                            color: canSelect
                                ? efficialsWhite
                                : Colors.grey[600],
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        subtitle: _buildOfficialLocation(official, canSelect),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    final hasSearchText = _searchController.text.isNotEmpty;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            hasSearchText ? Icons.search_off : Icons.search,
            size: 64,
            color: Colors.grey[600],
          ),
          const SizedBox(height: 16),
          Text(
            hasSearchText ? 'No officials found' : 'Search for Officials',
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            hasSearchText
                ? 'Try adjusting your search terms'
                : 'Start typing to find officials by name',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
          if (!hasSearchText) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey[800],
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Example: Type "John" to find officials named John',
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBottomBar(int needToSelect) {
    final hasRequiredMembers = _selectedMembers.length == needToSelect;
    final membersNeeded = needToSelect - _selectedMembers.length;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: efficialsBlack,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!hasRequiredMembers)
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber,
                      color: Colors.orange, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Select $membersNeeded more member${membersNeeded == 1 ? '' : 's'} to complete the crew.',
                      style:
                          const TextStyle(color: Colors.orange, fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed:
                  hasRequiredMembers && !_isCreating ? _createCrew : null,
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    hasRequiredMembers ? efficialsYellow : Colors.grey[700],
                foregroundColor: efficialsBlack,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: _isCreating
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(efficialsBlack),
                      ),
                    )
                  : Text(
                      hasRequiredMembers
                          ? 'Create Crew'
                          : 'Select $membersNeeded More Member${membersNeeded == 1 ? '' : 's'}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _createCrew() async {
    setState(() {
      _isCreating = true;
    });

    try {
      final crew = Crew(
        name: widget.crewName,
        crewTypeId: widget.crewType.id!,
        crewChiefId: widget.currentUserId,
        createdBy: widget.currentUserId,
        competitionLevels: widget.competitionLevels,
      );

      // Convert Map objects back to Official objects
      final selectedOfficials = _selectedMembers
          .map((member) => Official(
                id: member['id'],
                name: member['name'],
                email: member['email'],
                phone: member['phone'],
                userId: widget.currentUserId, // Required field
              ))
          .toList();

      await _crewRepo.createCrewWithMembersAndInvitations(
        crew: crew,
        selectedMembers: selectedOfficials,
        crewChiefId: widget.currentUserId,
      );

      if (mounted) {
        // Return to crew dashboard with success
        Navigator.pop(context); // Pop this screen
        Navigator.pop(context, true); // Pop create crew screen with success

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Crew "${crew.name}" created and invitations sent!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('Error creating crew: $e');
      if (mounted) {
        _showErrorDialog('Failed to create crew. Please try again.');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCreating = false;
        });
      }
    }
  }

  Widget _buildOfficialLocation(Map<String, dynamic> official, bool canSelect) {
    final locationText = official['cityState'] ?? 'Location not available';

    return Text(
      locationText,
      style: TextStyle(
        color: canSelect ? Colors.grey[400] : Colors.grey[700],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: efficialsBlack,
        title: const Text(
          'Error',
          style: TextStyle(color: efficialsWhite),
        ),
        content: Text(
          message,
          style: const TextStyle(color: efficialsWhite),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'OK',
              style: TextStyle(color: efficialsYellow),
            ),
          ),
        ],
      ),
    );
  }
}
