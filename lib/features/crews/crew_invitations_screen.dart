import 'package:flutter/material.dart';
import '../../shared/theme.dart';
import '../../shared/services/repositories/crew_repository.dart';
import '../../shared/services/user_session_service.dart';
import '../../shared/models/database_models.dart';

class CrewInvitationsScreen extends StatefulWidget {
  const CrewInvitationsScreen({super.key});

  @override
  State<CrewInvitationsScreen> createState() => _CrewInvitationsScreenState();
}

class _CrewInvitationsScreenState extends State<CrewInvitationsScreen> {
  final CrewRepository _crewRepo = CrewRepository();
  
  List<CrewInvitation> _invitations = [];
  bool _isLoading = true;
  int? _currentOfficialId;

  @override
  void initState() {
    super.initState();
    _loadInvitations();
  }

  Future<void> _loadInvitations() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final userSession = UserSessionService.instance;
      _currentOfficialId = await userSession.getCurrentUserId();

      if (_currentOfficialId != null) {
        final invitations = await _crewRepo.getPendingInvitations(_currentOfficialId!);

        if (mounted) {
          setState(() {
            _invitations = invitations;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
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
          'Crew Invitations',
          style: TextStyle(color: efficialsWhite),
        ),
        iconTheme: const IconThemeData(color: efficialsWhite),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: efficialsYellow),
            )
          : RefreshIndicator(
              onRefresh: _loadInvitations,
              color: efficialsYellow,
              child: _buildContent(),
            ),
    );
  }

  Widget _buildContent() {
    if (_invitations.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.mail_outline,
              size: 64,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              'No pending invitations',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 18,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Crew invitations will appear here',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _invitations.length,
      itemBuilder: (context, index) {
        return _buildInvitationCard(_invitations[index]);
      },
    );
  }

  Widget _buildInvitationCard(CrewInvitation invitation) {
    return Card(
      color: efficialsBlack,
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    invitation.crewName ?? 'Unknown Crew',
                    style: const TextStyle(
                      color: efficialsWhite,
                      fontSize: 18,
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
                    color: efficialsYellow.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'INVITATION',
                    style: TextStyle(
                      color: efficialsYellow,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildInfoRow(Icons.sports, 'Sport', '${invitation.sportName}'),
            const SizedBox(height: 8),
            _buildInfoRow(Icons.person, 'Invited by', '${invitation.inviterName}'),
            const SizedBox(height: 8),
            _buildInfoRow(Icons.access_time, 'Invited', _formatDateTime(invitation.invitedAt)),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _respondToInvitation(invitation, 'declined'),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.red),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text(
                      'Decline',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _respondToInvitation(invitation, 'accepted'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: efficialsYellow,
                      foregroundColor: efficialsBlack,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('Accept'),
                  ),
                ),
              ],
            ),
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

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

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

  Future<void> _respondToInvitation(CrewInvitation invitation, String status) async {
    try {
      if (_currentOfficialId == null) return;

      await _crewRepo.respondToInvitation(
        invitation.id!,
        status,
        null, // No notes for now
        _currentOfficialId!,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Invitation ${status == 'accepted' ? 'accepted' : 'declined'}',
            ),
            backgroundColor: status == 'accepted' ? Colors.green : Colors.orange,
          ),
        );
      }

      // Refresh the list
      _loadInvitations();
      
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to respond to invitation: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}