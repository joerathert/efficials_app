import 'package:flutter/material.dart';
import '../../shared/theme.dart';
import '../../shared/services/repositories/crew_repository.dart';
import '../../shared/services/user_session_service.dart';
import '../../shared/models/database_models.dart';

class CrewDashboardScreen extends StatefulWidget {
  const CrewDashboardScreen({super.key});

  @override
  State<CrewDashboardScreen> createState() => _CrewDashboardScreenState();
}

class _CrewDashboardScreenState extends State<CrewDashboardScreen> {
  final CrewRepository _crewRepo = CrewRepository();
  List<Crew> _allCrews = [];
  bool _isLoading = true;
  int? _currentOfficialId;
  DateTime? _lastRefresh;

  @override
  void initState() {
    super.initState();
    _loadCrews();
  }

  Future<void> _loadCrews() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final userSession = UserSessionService.instance;
      _currentOfficialId = await userSession.getCurrentUserId();
      
      if (_currentOfficialId != null) {
        // Simple caching: avoid frequent refreshes
        final now = DateTime.now();
        if (_lastRefresh != null && 
            now.difference(_lastRefresh!).inMinutes < 2 && 
            _allCrews.isNotEmpty) {
          setState(() {
            _isLoading = false;
          });
          return;
        }
        final crewsAsChief = await _crewRepo.getCrewsWhereChief(_currentOfficialId!);
        final crewsAsMember = await _crewRepo.getCrewsForOfficial(_currentOfficialId!);
        
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
            icon: const Icon(Icons.mail, color: efficialsYellow),
            onPressed: () => _navigateToInvitations(),
            tooltip: 'View Invitations',
          ),
          IconButton(
            icon: const Icon(Icons.add, color: efficialsYellow),
            onPressed: () => _navigateToCreateCrew(),
            tooltip: 'Create New Crew',
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
    if (_allCrews.isEmpty) {
      return _buildEmptyState();
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: _allCrews.map((crew) {
        // Check if current user is crew chief
        final isChief = crew.crewChiefId == _currentOfficialId;
        return _buildCrewCard(crew, isChief: isChief);
      }).toList(),
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
            child: Text(
              member.officialName ?? 'Unknown Official',
              style: TextStyle(
                color: Colors.grey[300],
                fontSize: 13,
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

  void _navigateToCreateCrew() async {
    final result = await Navigator.pushNamed(context, '/create_crew');
    
    if (result == true) {
      _loadCrews(); // Refresh the list
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
}