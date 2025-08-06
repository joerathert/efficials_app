import 'package:flutter/material.dart';
import '../../shared/theme.dart';
import '../../shared/services/repositories/crew_repository.dart';
import '../../shared/services/repositories/official_repository.dart';
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
  List<CrewMember> _members = [];
  List<CrewInvitation> _pendingInvitations = [];
  Map<String, dynamic> _performanceStats = {};
  bool _isLoading = true;
  bool _isCrewChief = false;
  int? _currentOfficialId;

  @override
  void initState() {
    super.initState();
    _loadCrewDetails();
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
        final pendingInvitations =
            await _crewRepo.getCrewInvitations(widget.crew.id!);

        Map<String, dynamic> stats = {};
        if (isChief) {
          stats = await _crewChiefService.getCrewPerformanceStats(
              widget.crew.id!, _currentOfficialId!);
        }

        if (mounted) {
          setState(() {
            _isCrewChief = isChief;
            _members = members;
            _pendingInvitations = pendingInvitations
                .where((inv) => inv.status == 'pending')
                .toList();
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
    return SafeArea(
      bottom: true,
      child: ListView(
        padding: EdgeInsets.fromLTRB(
            16, 16, 16, 16 + MediaQuery.of(context).padding.bottom),
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
      ),
    );
  }

  Widget _buildCrewInfo() {
    final memberCount = _members.length;
    final pendingCount = _pendingInvitations.length;
    final totalCount = memberCount + pendingCount;
    final requiredCount = widget.crew.requiredOfficials ?? 0;
    final isFullyStaffed = memberCount == requiredCount;
    final hasPendingInvitations = pendingCount > 0;

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
                Icons.people,
                'Members',
                hasPendingInvitations
                    ? '$memberCount active + $pendingCount pending ($totalCount of $requiredCount)'
                    : '$memberCount of $requiredCount'),
            const SizedBox(height: 8),
            _buildInfoRow(
                Icons.person, 'Crew Chief', '${widget.crew.crewChiefName}'),
            const SizedBox(height: 8),
            _buildCompetitionLevelsRow(),
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

  Widget _buildCompetitionLevelsRow() {
    final competitionLevels = widget.crew.competitionLevels;
    String displayText;

    if (competitionLevels == null || competitionLevels.isEmpty) {
      displayText = 'No competition levels set';
    } else {
      displayText = competitionLevels.join(', ');
    }

    return Row(
      children: [
        Icon(
          Icons.military_tech,
          color: Colors.grey[400],
          size: 20,
        ),
        const SizedBox(width: 12),
        Text(
          'Competition Levels:',
          style: TextStyle(
            color: Colors.grey[400],
            fontSize: 14,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            displayText,
            style: TextStyle(
              color: competitionLevels == null || competitionLevels.isEmpty
                  ? Colors.orange
                  : efficialsWhite,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        if (competitionLevels == null || competitionLevels.isEmpty)
          if (_isCrewChief)
            TextButton(
              onPressed: () => _showEditCompetitionLevelsDialog(),
              child: const Text(
                'SET LEVELS',
                style: TextStyle(
                  color: efficialsYellow,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
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
                  ElevatedButton.icon(
                    onPressed: () async {
                      final result = await Navigator.pushNamed(
                          context, '/add_crew_member',
                          arguments: widget.crew);
                      if (result == true) {
                        // Refresh crew details after successful invitation
                        await _loadCrewDetails();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: efficialsYellow,
                      foregroundColor: efficialsBlack,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                      elevation: 2,
                    ),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text(
                      'Add Members',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            if (_members.isEmpty && _pendingInvitations.isEmpty)
              const Text(
                'No members added yet',
                style: TextStyle(color: Colors.grey),
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Active Members
                  if (_members.isNotEmpty) ...[
                    if (_pendingInvitations.isNotEmpty)
                      const Padding(
                        padding: EdgeInsets.only(bottom: 12),
                        child: Text(
                          'Active Members',
                          style: TextStyle(
                            color: efficialsYellow,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ..._members.map((member) => _buildMemberTile(member)),
                  ],

                  // Pending Invitations
                  if (_pendingInvitations.isNotEmpty) ...[
                    if (_members.isNotEmpty) const SizedBox(height: 16),
                    const Padding(
                      padding: EdgeInsets.only(bottom: 12),
                      child: Text(
                        'Pending Invitations',
                        style: TextStyle(
                          color: Colors.orange,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    ..._pendingInvitations
                        .map((invitation) => _buildInvitationTile(invitation)),
                  ],
                ],
              ),
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
                GestureDetector(
                  onTap: () => _navigateToOfficialProfile(member),
                  child: Text(
                    member.officialName ?? 'Unknown',
                    style: const TextStyle(
                      color: efficialsYellow,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      decoration: TextDecoration.underline,
                    ),
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

  Widget _buildInvitationTile(CrewInvitation invitation) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: Colors.orange.withOpacity(0.2),
            child: Icon(
              Icons.mail_outline,
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
                  invitation.invitedOfficialName ?? 'Unknown',
                  style: const TextStyle(
                    color: efficialsWhite,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  'Invitation sent ${_formatDate(invitation.invitedAt)}',
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
          if (_isCrewChief)
            IconButton(
              onPressed: () => _cancelInvitation(invitation),
              icon: Icon(
                Icons.cancel_outlined,
                color: Colors.red[400],
                size: 20,
              ),
              tooltip: 'Cancel Invitation',
            ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
    } else {
      return 'Just now';
    }
  }

  Future<void> _cancelInvitation(CrewInvitation invitation) async {
    try {
      // Show confirmation dialog
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: efficialsBlack,
          title: const Text(
            'Cancel Invitation',
            style: TextStyle(color: efficialsWhite),
          ),
          content: Text(
            'Are you sure you want to cancel the invitation to ${invitation.invitedOfficialName}? You will be able to re-invite them later if needed.',
            style: const TextStyle(color: efficialsWhite),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text(
                'No',
                style: TextStyle(color: efficialsYellow),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text(
                'Yes, Cancel',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        ),
      );

      if (confirmed == true) {
        // Update invitation status to cancelled
        await _crewRepo.respondToInvitation(
          invitation.id!,
          'cancelled',
          'Cancelled by crew chief',
          invitation.invitedOfficialId,
        );

        // Refresh the crew details
        await _loadCrewDetails();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  'Invitation to ${invitation.invitedOfficialName} has been cancelled. You can re-invite them later if needed.'),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error cancelling invitation: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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
                Navigator.pushNamed(context, '/crew_availability',
                    arguments: widget.crew);
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

  void _handleMenuSelection(String value) async {
    switch (value) {
      case 'manage_availability':
        Navigator.pushNamed(context, '/crew_availability',
            arguments: widget.crew);
        break;
      case 'add_member':
        final result = await Navigator.pushNamed(context, '/add_crew_member',
            arguments: widget.crew);
        if (result == true) {
          // Refresh crew details after successful invitation
          await _loadCrewDetails();
        }
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
      final hasActiveAssignments =
          await _crewRepo.checkAssignments(widget.crew.id!);
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
                content: Text(
                    'Cannot remove ${member.officialName} - they have active game assignments'),
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

  Future<void> _showEditCompetitionLevelsDialog() async {
    final competitionLevelOptions = [
      'Grade School (6U-11U)',
      'Middle School (12U-14U)',
      'Junior Varsity',
      'Varsity',
      'Semi Pro/College'
    ];

    List<String> selectedLevels =
        List.from(widget.crew.competitionLevels ?? []);

    final result = await showDialog<List<String>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: efficialsBlack,
          title: const Text(
            'Edit Competition Levels',
            style: TextStyle(color: efficialsWhite),
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Select the competition levels this crew can officiate:',
                  style: TextStyle(color: Colors.grey[400]),
                ),
                const SizedBox(height: 16),
                ...competitionLevelOptions.map((level) {
                  final isSelected = selectedLevels.contains(level);
                  return CheckboxListTile(
                    title: Text(
                      level,
                      style: const TextStyle(color: efficialsWhite),
                    ),
                    value: isSelected,
                    activeColor: efficialsYellow,
                    checkColor: efficialsBlack,
                    onChanged: (bool? value) {
                      setState(() {
                        if (value == true) {
                          selectedLevels.add(level);
                        } else {
                          selectedLevels.remove(level);
                        }
                      });
                    },
                  );
                }).toList(),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, null),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.grey),
              ),
            ),
            TextButton(
              onPressed: selectedLevels.isEmpty
                  ? null
                  : () => Navigator.pop(context, selectedLevels),
              child: Text(
                'Save',
                style: TextStyle(
                  color: selectedLevels.isEmpty ? Colors.grey : efficialsYellow,
                ),
              ),
            ),
          ],
        ),
      ),
    );

    if (result != null) {
      await _updateCrewCompetitionLevels(result);
    }
  }

  Future<void> _updateCrewCompetitionLevels(
      List<String> competitionLevels) async {
    try {
      await _crewRepo.updateCrewCompetitionLevels(
          widget.crew.id!, competitionLevels);

      // Reload crew details to reflect changes
      await _loadCrewDetails();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Competition levels updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update competition levels: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
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
      print(
          'Navigating to official profile for member: ${member.officialName} (ID: ${member.officialId})');
      final officialRepo = OfficialRepository();
      // Get the full official data from the database using direct query
      final results = await officialRepo.query(
        'officials',
        where: 'id = ?',
        whereArgs: [member.officialId],
      );

      if (results.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Official profile not found'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      final officialData = results.first;
      print('Retrieved official data: $officialData');

      // Validate that we have the required data
      if (officialData['id'] == null) {
        print('Error: Official ID is null');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Error: Official data is incomplete'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // Navigate to the official profile screen with the official's data
      if (mounted) {
        await Navigator.pushNamed(
          context,
          '/official_profile',
          arguments: {
            'id': officialData['id'],
            'name': (officialData['name']?.toString() ?? 'Unknown Official'),
            'email': (officialData['email']?.toString() ?? ''),
            'phone': (officialData['phone']?.toString() ?? ''),
            'location': _buildLocationString(officialData['city']?.toString(),
                officialData['state']?.toString()),
            'experienceYears': (officialData['experience_years'] as int?) ?? 0,
            'primarySport': (officialData['sport_name']?.toString() ?? 'N/A'),
            'certificationLevel':
                (officialData['certification_level']?.toString() ?? 'N/A'),
            'joinedDate': DateTime.tryParse(
                    officialData['created_at']?.toString() ?? '') ??
                DateTime.now(),
            'totalGames': (officialData['total_accepted_games'] as int?) ?? 0,
            'followThroughRate':
                (officialData['follow_through_rate'] as num?)?.toDouble() ??
                    100.0,
            'showCareerStats': true, // Default to showing stats
          },
        );
      }
    } catch (e) {
      print('Error navigating to official profile: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error loading official profile'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
