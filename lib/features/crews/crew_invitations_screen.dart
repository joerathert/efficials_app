import 'package:flutter/material.dart';
import 'dart:async';
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
  
  // Undo state management
  int? _declinedInvitationId;
  Timer? _undoTimer;

  @override
  void initState() {
    super.initState();
    _loadInvitations();
  }

  @override
  void dispose() {
    _undoTimer?.cancel();
    super.dispose();
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

      if (status == 'declined') {
        // Handle decline with undo option
        await _handleDeclineWithUndo(invitation);
      } else {
        // Handle accept normally
        await _crewRepo.respondToInvitation(
          invitation.id!,
          status,
          null,
          _currentOfficialId!,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Invitation accepted'),
              backgroundColor: Colors.green,
            ),
          );
        }

        // Refresh the list
        _loadInvitations();
      }
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

  Future<void> _handleDeclineWithUndo(CrewInvitation invitation) async {
    print('DEBUG: Starting decline with undo for invitation ${invitation.id}');
    
    // Store the declined invitation info for undo
    setState(() {
      _declinedInvitationId = invitation.id;
    });

    // Remove the invitation from UI immediately
    setState(() {
      _invitations.removeWhere((inv) => inv.id == invitation.id);
    });

    // Show undo overlay instead of snackbar
    if (mounted) {
      print('DEBUG: Showing undo overlay');
      _showUndoOverlay();
    }

    // Start 5-second timer to finalize decline
    _undoTimer?.cancel();
    _undoTimer = Timer(const Duration(seconds: 5), () {
      _finalizeDecline(invitation);
    });
  }

  void _showUndoOverlay() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: efficialsBlack,
          title: const Text(
            'Invitation Declined',
            style: TextStyle(
              color: efficialsWhite,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'You have 5 seconds to undo this action.',
                style: TextStyle(
                  color: efficialsWhite,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      print('DEBUG: Undo button pressed');
                      _undoDecline();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: efficialsYellow,
                      foregroundColor: efficialsBlack,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    child: const Text(
                      'UNDO',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  OutlinedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.grey),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    child: const Text(
                      'OK',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );

    // Auto-close dialog after 5 seconds
    Timer(const Duration(seconds: 5), () {
      if (mounted && Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }
    });
  }

  void _undoDecline() {
    // Cancel the timer
    _undoTimer?.cancel();
    
    // Clear declined invitation state
    setState(() {
      _declinedInvitationId = null;
    });

    // Refresh invitations to restore the declined one
    _loadInvitations();

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
      });
      
    } catch (e) {
      // If finalize fails, restore the invitation
      if (mounted) {
        setState(() {
          _declinedInvitationId = null;
        });
        _loadInvitations();
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to decline invitation: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}