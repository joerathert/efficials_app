import 'package:flutter/material.dart';
import '../../shared/theme.dart';
import '../../shared/services/repositories/crew_repository.dart';
import '../../shared/services/crew_chief_service.dart';
import '../../shared/services/user_session_service.dart';
import '../../shared/models/database_models.dart';

class CrewDetailsScreen extends StatefulWidget {
  final Crew crew;

  const CrewDetailsScreen({
    super.key,
    required this.crew,
  });

  @override
  State<CrewDetailsScreen> createState() => _CrewDetailsScreenState();
}

class _CrewDetailsScreenState extends State<CrewDetailsScreen> {
  final CrewRepository _crewRepo = CrewRepository();
  final CrewChiefService _crewChiefService = CrewChiefService();
  final TextEditingController _searchController = TextEditingController();

  List<CrewMember> _members = [];
  List<CrewMember> _filteredMembers = [];
  Map<String, dynamic> _performanceStats = {};
  bool _isLoading = true;
  bool _isCrewChief = false;
  int? _currentOfficialId;
  String _searchQuery = '';

@override
  void initState() {
    super.initState();
    _loadCrewDetails();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text;
      _filterMembers();
    });
  }

  void _filterMembers() {
    if (_searchQuery.isEmpty) {
      _filteredMembers = List.from(_members);
    } else {
      _filteredMembers = _members.where((member) {
        final name = member.officialName?.toLowerCase() ?? '';
        return name.contains(_searchQuery.toLowerCase());
      }).toList();
    }
  }

  Future<void> _loadCrewDetails() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final userSession = UserSessionService.instance;
      _currentOfficialId = await userSession.getCurrentUserId();

      if (_currentOfficialId != null) {
        final isChief = await _crewChiefService.isCrewChief(
            _currentOfficialId!, widget.crew.id!);
        final members = await _crewRepo.getCrewMembers(widget.crew.id!);

        Map<String, dynamic> stats = {};
        if (isChief) {
          stats = await _crewChiefService.getCrewPerformanceStats(
              widget.crew.id!, _currentOfficialId!);
        }

        if (mounted) {
          setState(() {
            _isCrewChief = isChief;
            _members = members;
            _filteredMembers = List.from(members);
            _performanceStats = stats;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      print('Error loading crew details: $e');
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
        title: Text(
          widget.crew.name,
          style: const TextStyle(color: efficialsWhite),
        ),
        iconTheme: const IconThemeData(color: efficialsWhite),
        elevation: 0,
        actions: [
          if (_isCrewChief)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: efficialsWhite),
              color: efficialsBlack,
              onSelected: _handleMenuSelection,
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'manage_availability',
                  child: Text(
                    'Manage Availability',
                    style: TextStyle(color: efficialsWhite),
                  ),
                ),
                const PopupMenuItem(
                  value: 'add_member',
                  child: Text(
                    'Add Member',
                    style: TextStyle(color: efficialsWhite),
                  ),
                ),
                const PopupMenuItem(
                  value: 'edit_crew',
                  child: Text(
                    'Edit Crew',
                    style: TextStyle(color: efficialsWhite),
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete_crew',
                  child: Text(
                    'Delete Crew',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              ],
            ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: efficialsYellow),
            )
          : RefreshIndicator(
              onRefresh: _loadCrewDetails,
              color: efficialsYellow,
              child: _buildContent(),
            ),
    );
  }

  Widget _buildContent() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildCrewInfo(),
        const SizedBox(height: 24),
        _buildMembersSection(),
        if (_isCrewChief && _performanceStats.isNotEmpty) ...[
          const SizedBox(height: 24),
          _buildPerformanceSection(),
        ],
        const SizedBox(height: 24),
        _buildActionsSection(),
      ],
    );
  }

  Widget _buildCrewInfo() {
    final memberCount = _members.length;
    final requiredCount = widget.crew.requiredOfficials ?? 0;
    final isFullyStaffed = memberCount == requiredCount;

    return Card(
      color: efficialsBlack,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    widget.crew.name,
                    style: const TextStyle(
                      color: efficialsWhite,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: isFullyStaffed
                        ? Colors.green.withOpacity(0.2)
                        : Colors.orange.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    isFullyStaffed ? 'READY TO HIRE' : 'INCOMPLETE',
                    style: TextStyle(
                      color: isFullyStaffed ? Colors.green : Colors.orange,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildInfoRow(Icons.sports, 'Sport', '${widget.crew.sportName}'),
            const SizedBox(height: 8),
            _buildInfoRow(
                Icons.people, 'Members', '$memberCount of $requiredCount'),
            const SizedBox(height: 8),
            _buildInfoRow(
                Icons.person, 'Crew Chief', '${widget.crew.crewChiefName}'),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(
          icon,
          color: Colors.grey[400],
          size: 20,
        ),
        const SizedBox(width: 12),
        Text(
          '$label:',
          style: TextStyle(
            color: Colors.grey[400],
            fontSize: 14,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          value,
          style: const TextStyle(
            color: efficialsWhite,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildMembersSection() {
    return Card(
      color: efficialsBlack,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'Crew Members',
                  style: TextStyle(
                    color: efficialsWhite,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                if (_isCrewChief)
                  TextButton.icon(
                    onPressed: () {
                      Navigator.pushNamed(context, '/add_crew_member', arguments: widget.crew);
                    },
                    icon:
                        const Icon(Icons.add, color: efficialsYellow, size: 16),
                    label: const Text(
                      'Add',
                      style: TextStyle(color: efficialsYellow, fontSize: 12),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _searchController,
              style: const TextStyle(color: efficialsWhite),
              decoration: InputDecoration(
                hintText: 'Search members...',
                hintStyle: TextStyle(color: Colors.grey[400]),
                prefixIcon: Icon(Icons.search, color: Colors.grey[400]),
                filled: true,
                fillColor: Colors.grey[900],
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
            const SizedBox(height: 16),
            if (_filteredMembers.isEmpty)
              Text(
                _searchQuery.isEmpty ? 'No members added yet' : 'No members found matching "$_searchQuery"',
                style: const TextStyle(color: Colors.grey),
              )
            else
              ..._filteredMembers.map((member) => _buildMemberTile(member)),
          ],
        ),
      ),
    );
  }

  Widget _buildMemberTile(CrewMember member) {
    final isChief = member.position == 'crew_chief';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: isChief ? efficialsYellow : Colors.grey[700],
            child: Icon(
              isChief ? Icons.star : Icons.person,
              color: isChief ? efficialsBlack : efficialsWhite,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  member.officialName ?? 'Unknown',
                  style: const TextStyle(
                    color: efficialsWhite,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (member.gamePosition != null)
                  Text(
                    member.gamePosition!,
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 14,
                    ),
                  ),
              ],
            ),
          ),
          if (isChief)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
          if (_isCrewChief && !isChief)
            IconButton(
              onPressed: () => _removeMember(member),
              icon: Icon(
                Icons.remove_circle_outline,
                color: Colors.red[400],
                size: 20,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPerformanceSection() {
    final totalAssignments = _performanceStats['total_assignments'] ?? 0;
    final acceptanceRate = _performanceStats['acceptance_rate'] ?? 0.0;
    final avgFee = _performanceStats['avg_fee'] ?? 0.0;

    return Card(
      color: efficialsBlack,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Crew Performance',
              style: TextStyle(
                color: efficialsWhite,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem('Total Games', '$totalAssignments'),
                ),
                Expanded(
                  child: _buildStatItem('Acceptance Rate',
                      '${acceptanceRate.toStringAsFixed(1)}%'),
                ),
                Expanded(
                  child: _buildStatItem(
                      'Avg Fee', '\$${avgFee.toStringAsFixed(0)}'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: efficialsYellow,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[400],
            fontSize: 12,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildActionsSection() {
    return Column(
      children: [
        if (_isCrewChief) ...[
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.pushNamed(context, '/crew_availability', arguments: widget.crew);
              },
              icon: const Icon(Icons.calendar_today),
              label: const Text('Manage Availability'),
              style: ElevatedButton.styleFrom(
                backgroundColor: efficialsYellow,
                foregroundColor: efficialsBlack,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () {
              // TODO: Navigate to crew assignments/games
            },
            icon: const Icon(Icons.assignment, color: efficialsWhite),
            label: const Text(
              'View Assignments',
              style: TextStyle(color: efficialsWhite),
            ),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: efficialsWhite),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
      ],
    );
  }

  void _handleMenuSelection(String value) {
    switch (value) {
      case 'manage_availability':
        Navigator.pushNamed(context, '/crew_availability', arguments: widget.crew);
        break;
      case 'add_member':
        Navigator.pushNamed(context, '/add_crew_member', arguments: widget.crew);
        break;
      case 'edit_crew':
        Navigator.pushNamed(context, '/edit_crew', arguments: widget.crew);
        break;
      case 'delete_crew':
        _showDeleteCrewConfirmation();
        break;
    }
  }

  Future<void> _showDeleteCrewConfirmation() async {
    // First confirmation dialog
    final firstConfirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: efficialsBlack,
        title: const Text(
          'Delete Crew?',
          style: TextStyle(color: efficialsWhite),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to delete "${widget.crew.name}"?',
              style: const TextStyle(color: efficialsWhite),
            ),
            const SizedBox(height: 16),
            const Text(
              'This will:',
              style: TextStyle(
                color: efficialsWhite,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '• Remove all crew members',
              style: TextStyle(color: Colors.orange),
            ),
            const Text(
              '• Cancel all pending invitations',
              style: TextStyle(color: Colors.orange),
            ),
            const Text(
              '• Delete availability settings',
              style: TextStyle(color: Colors.orange),
            ),
            const Text(
              '• Remove pending assignments',
              style: TextStyle(color: Colors.orange),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.grey),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Continue',
              style: TextStyle(color: Colors.orange),
            ),
          ),
        ],
      ),
    );

    if (firstConfirmed != true) return;

    if (!mounted) return;

    // Second confirmation dialog (double confirmation)
    final secondConfirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        final controller = TextEditingController();

        return StatefulBuilder(
          builder: (context, setState) {
            final canDelete = controller.text == widget.crew.name;

            return AlertDialog(
              backgroundColor: efficialsBlack,
              title: const Text(
                'FINAL CONFIRMATION',
                style:
                    TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.warning,
                    color: Colors.red,
                    size: 48,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'This action cannot be undone.',
                    style: TextStyle(
                      color: efficialsWhite,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Type "${widget.crew.name}" to confirm deletion:',
                    style: const TextStyle(color: efficialsWhite),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: controller,
                    style: const TextStyle(color: efficialsWhite),
                    decoration: InputDecoration(
                      hintText: widget.crew.name,
                      hintStyle: TextStyle(color: Colors.grey[600]),
                      filled: true,
                      fillColor: Colors.grey[900],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Colors.red),
                      ),
                    ),
                    onChanged: (value) {
                      setState(() {}); // Rebuild to update button state
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
                TextButton(
                  onPressed:
                      canDelete ? () => Navigator.pop(context, true) : null,
                  child: Text(
                    'DELETE CREW',
                    style: TextStyle(
                      color: canDelete ? Colors.red : Colors.grey,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    if (secondConfirmed == true) {
      await _deleteCrew();
    }
  }

  Future<void> _deleteCrew() async {
    try {
      if (_currentOfficialId == null) return;

      // Check for active assignments before deletion
      final hasActiveAssignments = await _crewRepo.checkAssignments(widget.crew.id!);
      if (hasActiveAssignments) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Cannot delete crew with active game assignments'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      await _crewRepo.deleteCrew(widget.crew.id!, _currentOfficialId!);

      if (mounted) {
        Navigator.pop(
            context, true); // Return true to indicate crew was deleted
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Crew "${widget.crew.name}" deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete crew: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _removeMember(CrewMember member) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: efficialsBlack,
        title: const Text(
          'Remove Member',
          style: TextStyle(color: efficialsWhite),
        ),
        content: Text(
          'Are you sure you want to remove ${member.officialName} from this crew?',
          style: const TextStyle(color: efficialsWhite),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.grey),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Remove',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && _currentOfficialId != null) {
      try {
        // Check for active assignments before removal
        final hasActiveAssignments = await _crewRepo.checkMemberAssignments(
          widget.crew.id!,
          member.officialId,
        );
        if (hasActiveAssignments) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Cannot remove ${member.officialName} - they have active game assignments'),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }

        await _crewChiefService.removeCrewMember(
          widget.crew.id!,
          member.officialId,
          _currentOfficialId!,
        );

        await _loadCrewDetails(); // Refresh the details

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${member.officialName} removed from crew'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to remove member: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}
