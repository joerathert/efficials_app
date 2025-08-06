import 'package:flutter/material.dart';
import 'dart:async';
import '../../shared/theme.dart';
import '../../shared/services/repositories/crew_repository.dart';
import '../../shared/services/repositories/official_repository.dart';
import '../../shared/services/user_session_service.dart';
import '../../shared/models/database_models.dart';

class CrewDashboardScreen extends StatefulWidget {
  const CrewDashboardScreen({super.key});

  @override
  State<CrewDashboardScreen> createState() => _CrewDashboardScreenState();
}

class _CrewDashboardScreenState extends State<CrewDashboardScreen> {
  final CrewRepository _crewRepo = CrewRepository();
  final OfficialRepository _officialRepo = OfficialRepository();
  List<Crew> _allCrews = [];
  List<CrewInvitation> _pendingInvitations = [];
  bool _isLoading = true;
  int? _currentUserId;
  int? _currentOfficialId;
  DateTime? _lastRefresh;
  
  // Undo state management
  int? _declinedInvitationId;
  CrewInvitation? _declinedInvitation;
  Timer? _undoTimer;

  @override
  void initState() {
    super.initState();
    _loadCrews();
  }

  @override
  void dispose() {
    _undoTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadCrews() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final userSession = UserSessionService.instance;
      _currentUserId = await userSession.getCurrentUserId();

      if (_currentUserId != null) {
        // Get the official ID for the current user
        final currentUserOfficial = await _officialRepo.rawQuery(
            'SELECT id FROM officials WHERE user_id = ? OR official_user_id = ?',
            [_currentUserId, _currentUserId]);

        if (currentUserOfficial.isNotEmpty) {
          _currentOfficialId = currentUserOfficial.first['id'] as int;
        } else {
          // No official record found for this user
          debugPrint('No official record found for user ID: $_currentUserId');
          setState(() {
            _isLoading = false;
          });
          return;
        }
      } else {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      if (_currentOfficialId != null) {
        // Simple caching: avoid frequent refreshes (but always refresh if no crews loaded)
        final now = DateTime.now();
        if (_lastRefresh != null &&
            now.difference(_lastRefresh!).inSeconds < 30 &&
            _allCrews.isNotEmpty) {
          setState(() {
            _isLoading = false;
          });
          return;
        }
        final crewsAsChief =
            await _crewRepo.getCrewsWhereChief(_currentOfficialId!);
        final crewsAsMember =
            await _crewRepo.getCrewsForOfficial(_currentOfficialId!);
        final pendingInvitations =
            await _crewRepo.getPendingInvitations(_currentOfficialId!);

        // Combine all crews into one list, removing duplicates
        final allCrews = <Crew>[];
        allCrews.addAll(crewsAsChief);

        // Only add member crews that aren't already in the chief list
        for (final memberCrew in crewsAsMember) {
          if (!crewsAsChief.any((chiefCrew) => chiefCrew.id == memberCrew.id)) {
            allCrews.add(memberCrew);
          }
        }

        if (mounted) {
          _lastRefresh = now;
          setState(() {
            _allCrews = allCrews;
            _pendingInvitations = pendingInvitations;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading crews: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
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
          'My Crews',
          style: TextStyle(color: efficialsWhite),
        ),
        iconTheme: const IconThemeData(color: efficialsWhite),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: efficialsYellow),
            onPressed: () => _forceRefresh(),
            tooltip: 'Refresh Crews',
          ),
          IconButton(
            icon: const Icon(Icons.mail, color: efficialsYellow),
            onPressed: () => _navigateToInvitations(),
            tooltip: 'View Invitations',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: efficialsYellow),
                  SizedBox(height: 16),
                  Text(
                    'Loading crews...',
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadCrews,
              color: efficialsYellow,
              child: _buildCrewsList(),
            ),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  Widget _buildCrewsList() {
    final hasCrews = _allCrews.isNotEmpty;
    final hasInvitations = _pendingInvitations.isNotEmpty;

    if (!hasCrews && !hasInvitations) {
      return _buildEmptyState();
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Pending Invitations Section
        if (hasInvitations) ...[
          _buildSectionHeader('Crew Invitations', _pendingInvitations.length),
          const SizedBox(height: 8),
          ..._pendingInvitations
              .map((invitation) => _buildInvitationCard(invitation)),
          if (hasCrews) const SizedBox(height: 24),
        ],

        // My Crews Section
        if (hasCrews) ...[
          _buildSectionHeader('My Crews', _allCrews.length),
          const SizedBox(height: 8),
          ..._allCrews.map((crew) {
            // Check if current user is crew chief
            final isChief = crew.crewChiefId == _currentOfficialId;
            return _buildCrewCard(crew, isChief: isChief);
          }),
        ],
      ],
    );
  }

  Widget _buildCrewCard(Crew crew, {required bool isChief}) {
    final memberCount = crew.members?.length ?? 0;
    final requiredCount = crew.requiredOfficials ?? 0;
    final isFullyStaffed = memberCount == requiredCount;
    final members = crew.members ?? [];

    return Card(
      color: efficialsBlack,
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        backgroundColor: efficialsBlack,
        collapsedBackgroundColor: efficialsBlack,
        iconColor: efficialsYellow,
        collapsedIconColor: Colors.grey[400],
        onExpansionChanged: (expanded) {
          // Optional: Add analytics or state tracking
        },
        leading: GestureDetector(
          onTap: () => _navigateToCrewDetails(crew),
          child: const Icon(
            Icons.info_outline,
            color: efficialsYellow,
            size: 20,
          ),
        ),
        title: Row(
          children: [
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
            if (isChief)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: efficialsYellow,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'CHIEF',
                  style: TextStyle(
                    color: efficialsBlack,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
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
                  '$memberCount of $requiredCount members',
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 14,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: isFullyStaffed
                        ? Colors.green.withOpacity(0.2)
                        : Colors.orange.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    isFullyStaffed ? 'READY' : 'INCOMPLETE',
                    style: TextStyle(
                      color: isFullyStaffed ? Colors.green : Colors.orange,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        children: [
          if (members.isNotEmpty)
            Container(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(color: Colors.grey),
                  const Text(
                    'Crew Members:',
                    style: TextStyle(
                      color: efficialsWhite,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...members.map((member) => _buildMemberRow(member, isChief)),
                  const SizedBox(height: 8),
                  Center(
                    child: TextButton(
                      onPressed: () => _navigateToCrewDetails(crew),
                      child: const Text(
                        'View Full Details',
                        style: TextStyle(color: efficialsYellow),
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            Container(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                children: [
                  const Divider(color: Colors.grey),
                  Text(
                    'No members yet. ${isChief ? "Start inviting officials to join your crew." : "Waiting for crew chief to add members."}',
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 14,
                      fontStyle: FontStyle.italic,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  if (isChief)
                    ElevatedButton.icon(
                      onPressed: () => _navigateToCrewDetails(crew),
                      icon: const Icon(Icons.person_add, size: 16),
                      label: const Text('Add Members'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: efficialsYellow,
                        foregroundColor: efficialsBlack,
                        textStyle: const TextStyle(fontSize: 12),
                      ),
                    )
                  else
                    TextButton(
                      onPressed: () => _navigateToCrewDetails(crew),
                      child: const Text(
                        'View Details',
                        style: TextStyle(color: efficialsYellow),
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, int count) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text(
            title,
            style: const TextStyle(
              color: efficialsYellow,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: efficialsYellow.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              count.toString(),
              style: const TextStyle(
                color: efficialsYellow,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInvitationCard(CrewInvitation invitation) {
    return Card(
      color: efficialsBlack,
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.group_add,
                    color: Colors.orange,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        invitation.crewName ?? 'Unknown Crew',
                        style: const TextStyle(
                          color: efficialsWhite,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Invited by ${invitation.inviterName ?? 'Unknown'}',
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.orange.withOpacity(0.5)),
                  ),
                  child: const Text(
                    'PENDING',
                    style: TextStyle(
                      color: Colors.orange,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (invitation.sportName != null ||
                invitation.levelOfCompetition != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    if (invitation.sportName != null) ...[
                      Icon(Icons.sports, color: Colors.grey[400], size: 16),
                      const SizedBox(width: 4),
                      Text(
                        invitation.sportName!,
                        style: TextStyle(color: Colors.grey[400], fontSize: 14),
                      ),
                    ],
                    if (invitation.sportName != null &&
                        invitation.levelOfCompetition != null)
                      Text(' • ', style: TextStyle(color: Colors.grey[400])),
                    if (invitation.levelOfCompetition != null) ...[
                      Icon(Icons.emoji_events,
                          color: Colors.grey[400], size: 16),
                      const SizedBox(width: 4),
                      Text(
                        invitation.levelOfCompetition!,
                        style: TextStyle(color: Colors.grey[400], fontSize: 14),
                      ),
                    ],
                  ],
                ),
              ),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () =>
                        _respondToInvitation(invitation, 'accepted'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Accept'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () =>
                        _respondToInvitation(invitation, 'declined'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Decline'),
                  ),
                ),
              ],
            ),
          ],
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
              Icons.groups,
              size: 64,
              color: Colors.grey[600],
            ),
            const SizedBox(height: 16),
            Text(
              'No Crews Yet',
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Create or join a crew to start working games together',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _navigateToCreateCrew,
              icon: const Icon(Icons.add),
              label: const Text('Create New Crew'),
              style: ElevatedButton.styleFrom(
                backgroundColor: efficialsYellow,
                foregroundColor: efficialsBlack,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMemberRow(CrewMember member, bool isChief) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            Icons.person,
            color: Colors.grey[400],
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: GestureDetector(
              onTap: () => _navigateToOfficialProfile(member),
              child: Text(
                member.officialName ?? 'Unknown Official',
                style: TextStyle(
                  color: efficialsYellow,
                  fontSize: 13,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ),
          if (member.position.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                member.position.toUpperCase(),
                style: const TextStyle(
                  color: Colors.blue,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    return FloatingActionButton(
      onPressed: _navigateToCreateCrew,
      backgroundColor: efficialsYellow,
      foregroundColor: efficialsBlack,
      tooltip: 'Create New Crew',
      child: const Icon(Icons.add),
    );
  }

  void _forceRefresh() {
    _lastRefresh = null; // Reset cache
    _loadCrews();
  }

  void _navigateToCreateCrew() async {
    final result = await Navigator.pushNamed(context, '/create_crew');

    if (result == true) {
      _loadCrews(); // Refresh the list
    }
  }

  Future<void> _respondToInvitation(
      CrewInvitation invitation, String response) async {
    try {
      if (response == 'declined') {
        // Handle decline with undo option
        await _handleDeclineWithUndo(invitation);
      } else {
        // Handle accept normally
        setState(() {
          _isLoading = true;
        });

        await _crewRepo.respondToInvitation(
          invitation.id!,
          response,
          null,
          _currentOfficialId!,
        );

        // Refresh the crew list to show updated state
        await _loadCrews();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  'You have accepted the invitation to join ${invitation.crewName}'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error responding to invitation: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error responding to invitation: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _handleDeclineWithUndo(CrewInvitation invitation) async {
    print('DEBUG: Starting decline with undo for invitation ${invitation.id}');
    
    // Store the declined invitation info for undo
    setState(() {
      _declinedInvitationId = invitation.id;
      _declinedInvitation = invitation;
    });

    // Remove the invitation from UI immediately
    setState(() {
      _pendingInvitations.removeWhere((inv) => inv.id == invitation.id);
    });

    // Show undo snackbar
    if (mounted) {
      print('DEBUG: Showing undo snackbar');
      _showUndoSnackbar(invitation);
    }

    // Start 5-second timer to finalize decline
    _undoTimer?.cancel();
    _undoTimer = Timer(const Duration(seconds: 5), () {
      _finalizeDecline(invitation);
    });
  }

  void _showUndoSnackbar(CrewInvitation invitation) {
    // Clear any existing snackbars first
    ScaffoldMessenger.of(context).clearSnackBars();
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Expanded(
              child: Text(
                'Invitation declined',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: () {
                print('DEBUG: Undo button pressed from snackbar');
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
                _undoDecline();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: efficialsYellow,
                foregroundColor: efficialsBlack,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                minimumSize: const Size(70, 36),
                elevation: 2,
              ),
              child: const Text(
                'UNDO',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.orange.shade700,
        duration: const Duration(seconds: 5),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        elevation: 6,
      ),
    );
  }

  void _undoDecline() {
    // Cancel the timer
    _undoTimer?.cancel();
    
    // Restore the invitation to the UI
    if (_declinedInvitation != null) {
      setState(() {
        _pendingInvitations.add(_declinedInvitation!);
        _declinedInvitationId = null;
        _declinedInvitation = null;
      });
    }

    // Show confirmation
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Decline undone - invitation restored',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.blue,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _finalizeDecline(CrewInvitation invitation) async {
    try {
      if (_currentOfficialId == null) return;

      await _crewRepo.respondToInvitation(
        invitation.id!,
        'declined',
        null,
        _currentOfficialId!,
      );

      // Clear state
      setState(() {
        _declinedInvitationId = null;
        _declinedInvitation = null;
      });

      // Hide the snackbar if still visible
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
      }
      
    } catch (e) {
      // If finalize fails, restore the invitation
      if (mounted) {
        setState(() {
          if (_declinedInvitation != null) {
            _pendingInvitations.add(_declinedInvitation!);
          }
          _declinedInvitationId = null;
          _declinedInvitation = null;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to decline invitation: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _navigateToInvitations() async {
    final result = await Navigator.pushNamed(context, '/crew_invitations');

    if (result == true) {
      _loadCrews(); // Refresh the list
    }
  }

  void _navigateToCrewDetails(Crew crew) async {
    final result = await Navigator.pushNamed(
      context,
      '/crew_details',
      arguments: crew,
    );

    if (result == true) {
      _loadCrews(); // Refresh the list
    }
  }

  String _buildLocationString(String? city, String? state) {
    final cityStr = city?.trim() ?? '';
    final stateStr = state?.trim() ?? '';
    
    if (cityStr.isNotEmpty && stateStr.isNotEmpty) {
      return '$cityStr, $stateStr';
    } else if (cityStr.isNotEmpty) {
      return cityStr;
    } else if (stateStr.isNotEmpty) {
      return stateStr;
    } else {
      return 'Location not specified';
    }
  }

  void _navigateToOfficialProfile(CrewMember member) async {
    try {
      debugPrint('Attempting to navigate to profile for member: ${member.officialName} (ID: ${member.officialId})');
      
      // Get the full official data from the database using direct query
      final results = await _officialRepo.query(
        'officials',
        where: 'id = ?',
        whereArgs: [member.officialId],
      );

      debugPrint('Database query results: ${results.length} records found');
      if (results.isNotEmpty) {
        debugPrint('First result keys: ${results.first.keys.toList()}');
        debugPrint('First result: ${results.first}');
      }

      if (results.isEmpty) {
        debugPrint('No official found with ID: ${member.officialId}');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Official profile not found (ID: ${member.officialId})'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      final officialData = results.first;

      // Navigate to the official profile screen with the official's data
      if (mounted) {
        final arguments = {
          'id': officialData['id'],
          'name': (officialData['name']?.toString() ?? 'Unknown Official'),
          'email': (officialData['email']?.toString() ?? ''),
          'phone': (officialData['phone']?.toString() ?? ''),
          'location': _buildLocationString(officialData['city']?.toString(), officialData['state']?.toString()),
          'experienceYears': (officialData['experience_years'] as int?) ?? 0,
          'primarySport': (officialData['sport_name']?.toString() ?? 'N/A'),
          'certificationLevel': (officialData['certification_level']?.toString() ?? 'N/A'),
          'joinedDate': DateTime.tryParse(
                  officialData['created_at']?.toString() ?? '') ??
              DateTime.now(),
          'totalGames': (officialData['total_accepted_games'] as int?) ?? 0,
          'followThroughRate': (officialData['follow_through_rate'] as num?)?.toDouble() ?? 100.0,
          'showCareerStats': true, // Default to showing stats
        };
        
        debugPrint('Navigating with arguments: $arguments');
        await Navigator.pushNamed(
          context,
          '/official_profile',
          arguments: arguments,
        );
      }
    } catch (e) {
      debugPrint('Error navigating to official profile: $e');
      debugPrint('Stack trace: ${StackTrace.current}');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading official profile: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
