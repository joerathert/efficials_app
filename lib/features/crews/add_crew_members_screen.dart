import 'package:flutter/material.dart';
import '../../shared/theme.dart';
import '../../shared/services/repositories/crew_repository.dart';
import '../../shared/services/repositories/official_repository.dart';
import '../../shared/services/user_session_service.dart';
import '../../shared/models/database_models.dart';

class AddCrewMembersScreen extends StatefulWidget {
  final Crew crew;

  const AddCrewMembersScreen({
    super.key,
    required this.crew,
  });

  @override
  State<AddCrewMembersScreen> createState() => _AddCrewMembersScreenState();
}

class _AddCrewMembersScreenState extends State<AddCrewMembersScreen> {
  final CrewRepository _crewRepo = CrewRepository();
  final OfficialRepository _officialRepo = OfficialRepository();
  final _searchController = TextEditingController();

  List<Map<String, dynamic>> _availableOfficials = [];
  List<Map<String, dynamic>> _filteredOfficials = [];
  List<Map<String, dynamic>> _selectedMembers = [];
  List<int> _existingMemberIds = [];
  List<int> _pendingInvitationIds = [];
  bool _isLoading = true;
  bool _isInviting = false;
  int? _currentUserOfficialId;
  String? _sportName;

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

      final userSession = UserSessionService.instance;
      final currentUserId = await userSession.getCurrentUserId();

      if (currentUserId == null) {
        throw Exception('User not logged in');
      }

      // Get current user's official ID
      final currentUserOfficial = await _officialRepo.rawQuery(
          'SELECT id FROM officials WHERE user_id = ? OR official_user_id = ?',
          [currentUserId, currentUserId]);

      if (currentUserOfficial.isNotEmpty) {
        _currentUserOfficialId = currentUserOfficial.first['id'] as int;
      }

      // Get existing crew members to exclude them
      final existingMembers = await _crewRepo.getCrewMembers(widget.crew.id!);
      _existingMemberIds =
          existingMembers.map((member) => member.officialId).toList();

      // Get existing pending invitations to exclude those officials too
      final pendingInvitations =
          await _crewRepo.getCrewInvitations(widget.crew.id!);
      _pendingInvitationIds = pendingInvitations
          .where((inv) => inv.status == 'pending')
          .map((inv) => inv.invitedOfficialId)
          .toList();

      print(
          'Crew ${widget.crew.name}: Excluding ${_existingMemberIds.length} existing members and ${_pendingInvitationIds.length} pending invitations');

      // Get crew type to determine sport
      final crewTypeQuery = await _crewRepo.rawQuery(
          'SELECT ct.*, s.name as sport_name FROM crew_types ct JOIN sports s ON ct.sport_id = s.id WHERE ct.id = ?',
          [widget.crew.crewTypeId]);

      if (crewTypeQuery.isNotEmpty) {
        _sportName = crewTypeQuery.first['sport_name'] as String?;
      }

      if (_sportName != null) {
        // Get sport ID
        final sportQuery = await _officialRepo
            .rawQuery('SELECT id FROM sports WHERE name = ?', [_sportName]);

        if (sportQuery.isNotEmpty) {
          final sportId = sportQuery.first['id'] as int;
          final allOfficials = await _officialRepo.getOfficialsBySport(sportId);

          // Filter out existing members, current user, and officials with pending invitations
          final officials = allOfficials.where((official) {
            final officialId = official['id'] as int;
            return !_existingMemberIds.contains(officialId) &&
                !_pendingInvitationIds.contains(officialId) &&
                officialId != _currentUserOfficialId;
          }).toList();

          if (mounted) {
            setState(() {
              _availableOfficials = officials;
              _filteredOfficials = [];
              _isLoading = false;
            });
          }
        }
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
    return Scaffold(
      backgroundColor: darkBackground,
      appBar: AppBar(
        backgroundColor: efficialsBlack,
        title: const Text(
          'Add Crew Members',
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
                _buildHeader(),
                Expanded(child: _buildMembersList()),
                _buildBottomBar(),
              ],
            ),
    );
  }

  Widget _buildHeader() {
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
            widget.crew.name,
            style: const TextStyle(
              color: efficialsYellow,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add members to your ${_sportName ?? 'crew'}',
            style: TextStyle(
              color: Colors.grey[300],
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Officials already in crew or with pending invitations are excluded',
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Selected: ${_selectedMembers.length}',
            style: TextStyle(
              color:
                  _selectedMembers.isNotEmpty ? Colors.green : Colors.grey[400],
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMembersList() {
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
                          _filteredOfficials = [];
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
                  _filteredOfficials = [];
                } else {
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
                          onPressed: () {
                            setState(() {
                              if (isSelected) {
                                _selectedMembers.remove(official);
                              } else {
                                _selectedMembers.add(official);
                              }
                            });
                          },
                        ),
                        title: Text(
                          official['name'],
                          style: const TextStyle(
                            color: efficialsWhite,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        subtitle: _buildOfficialLocation(official),
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
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    final hasSelectedMembers = _selectedMembers.isNotEmpty;

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
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed:
                  hasSelectedMembers && !_isInviting ? _sendInvitations : null,
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    hasSelectedMembers ? efficialsYellow : Colors.grey[700],
                foregroundColor: efficialsBlack,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: _isInviting
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
                      hasSelectedMembers
                          ? 'Send ${_selectedMembers.length} Invitation${_selectedMembers.length == 1 ? '' : 's'}'
                          : 'Select Members to Invite',
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

  Future<void> _sendInvitations() async {
    setState(() {
      _isInviting = true;
    });

    try {
      // Send individual invitations for each selected member
      for (final member in _selectedMembers) {
        try {
          final invitation = CrewInvitation(
            crewId: widget.crew.id!,
            invitedOfficialId: member['id'],
            invitedBy: _currentUserOfficialId!,
            position: 'member',
            status: 'pending',
            invitedAt: DateTime.now(),
          );

          await _crewRepo.createCrewInvitation(invitation);
        } catch (e) {
          // Handle individual invitation errors
          print('Error sending invitation to ${member['name']}: $e');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                    'Failed to invite ${member['name']}: ${e.toString().replaceAll('Exception: ', '')}'),
                backgroundColor: Colors.orange,
                duration: const Duration(seconds: 4),
              ),
            );
          }
          // Continue with next invitation
          continue;
        }
      }

      if (mounted) {
        Navigator.pop(context, true); // Return true to indicate success
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                '${_selectedMembers.length} invitation${_selectedMembers.length == 1 ? '' : 's'} sent!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('Error in invitation process: $e');
      if (mounted) {
        _showErrorDialog(
            'An unexpected error occurred while sending invitations. Please try again.');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isInviting = false;
        });
      }
    }
  }

  Widget _buildOfficialLocation(Map<String, dynamic> official) {
    String locationText = official['cityState'] ?? '';

    if (locationText.isEmpty || locationText == 'Location not available') {
      final city = official['city'] as String?;
      final state = official['state'] as String?;

      if (city != null && city.isNotEmpty && city != 'null') {
        locationText = city;
        if (state != null && state.isNotEmpty && state != 'null') {
          locationText += ', $state';
        }
      } else {
        locationText = 'Location not available';
      }
    }

    return Text(
      locationText,
      style: TextStyle(
        color: Colors.grey[400],
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
