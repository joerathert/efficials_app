import 'package:flutter/material.dart';
import '../../shared/theme.dart';
import '../../shared/services/repositories/game_assignment_repository.dart';
import '../../shared/services/repositories/official_repository.dart';
import '../../shared/services/user_session_service.dart';
import '../../shared/models/database_models.dart';

class OfficialAssignmentsScreen extends StatefulWidget {
  const OfficialAssignmentsScreen({super.key});

  @override
  State<OfficialAssignmentsScreen> createState() => _OfficialAssignmentsScreenState();
}

class _OfficialAssignmentsScreenState extends State<OfficialAssignmentsScreen> {
  String _selectedFilter = 'All';
  
  // Repositories
  final GameAssignmentRepository _assignmentRepo = GameAssignmentRepository();
  final OfficialRepository _officialRepo = OfficialRepository();
  
  // State
  List<GameAssignment> assignments = [];
  bool _isLoading = true;
  Official? _currentOfficial;
  
  @override
  void initState() {
    super.initState();
    _loadAssignments();
  }
  
  Future<void> _loadAssignments() async {
    try {
      setState(() {
        _isLoading = true;
      });
      
      // Get current user session
      final userSession = UserSessionService.instance;
      final userId = await userSession.getCurrentUserId();
      final userType = await userSession.getCurrentUserType();
      
      if (userId == null || userType != 'official') {
        return;
      }
      
      // Get the official record
      _currentOfficial = await _officialRepo.getOfficialByOfficialUserId(userId);
      
      if (_currentOfficial == null) {
        return;
      }
      
      // Load all assignments for this official
      final allAssignments = await _assignmentRepo.getAssignmentsForOfficial(_currentOfficial!.id!);
      
      if (mounted) {
        setState(() {
          assignments = allAssignments;
        });
      }
    } catch (e) {
      print('Error loading assignments: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  List<GameAssignment> get filteredAssignments {
    List<GameAssignment> filtered = assignments;

    if (_selectedFilter == 'Pending') {
      filtered = filtered.where((assignment) => assignment.status == 'pending').toList();
    } else if (_selectedFilter == 'Accepted') {
      filtered = filtered.where((assignment) => assignment.status == 'accepted').toList();
    } else if (_selectedFilter == 'Declined') {
      filtered = filtered.where((assignment) => assignment.status == 'declined').toList();
    }

    // Sort by date/priority
    filtered.sort((a, b) {
      // Pending assignments first, then by date
      if (a.status == 'pending' && b.status != 'pending') return -1;
      if (b.status == 'pending' && a.status != 'pending') return 1;
      final dateA = a.gameDate ?? DateTime(1970);
      final dateB = b.gameDate ?? DateTime(1970);
      return dateA.compareTo(dateB);
    });

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final pendingCount = assignments.where((a) => a.status == 'pending').length;

    return Scaffold(
      backgroundColor: darkBackground,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Game Assignments',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: efficialsYellow,
                        ),
                      ),
                      if (pendingCount > 0)
                        Text(
                          '$pendingCount pending assignment${pendingCount == 1 ? '' : 's'}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.orange[300],
                          ),
                        ),
                    ],
                  ),
                  PopupMenuButton<String>(
                    onSelected: (String value) {
                      setState(() {
                        _selectedFilter = value;
                      });
                    },
                    itemBuilder: (BuildContext context) => [
                      const PopupMenuItem(value: 'All', child: Text('All Assignments')),
                      const PopupMenuItem(value: 'Pending', child: Text('Pending')),
                      const PopupMenuItem(value: 'Accepted', child: Text('Accepted')),
                      const PopupMenuItem(value: 'Declined', child: Text('Declined')),
                    ],
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: darkSurface,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _selectedFilter,
                            style: const TextStyle(color: Colors.white),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.arrow_drop_down, color: Colors.white),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Assignments List
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(color: efficialsYellow),
                      )
                    : filteredAssignments.isEmpty
                        ? _buildEmptyState()
                        : ListView.builder(
                            itemCount: filteredAssignments.length,
                            itemBuilder: (context, index) {
                              return _buildAssignmentCard(filteredAssignments[index]);
                            },
                          ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAssignmentCard(GameAssignment assignment) {
    final status = assignment.status;
    final sportName = assignment.sportName ?? 'Sport';
    final opponent = assignment.opponent ?? 'TBD';
    final locationName = assignment.locationName ?? 'TBD';
    final fee = assignment.feeAmount ?? 0.0;
    final position = assignment.position ?? 'Official';
    
    final gameDate = assignment.gameDate;
    final gameTime = assignment.gameTime;
    final dateString = gameDate != null ? _formatDate(gameDate) : 'TBD';
    final timeString = gameTime != null ? _formatTime(gameTime) : 'TBD';
    Color statusColor;
    Color borderColor;

    switch (status) {
      case 'pending':
        statusColor = Colors.orange;
        borderColor = Colors.orange;
        break;
      case 'accepted':
        statusColor = Colors.green;
        borderColor = Colors.green;
        break;
      case 'declined':
        statusColor = Colors.red;
        borderColor = Colors.red;
        break;
      default:
        statusColor = Colors.grey;
        borderColor = Colors.grey;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: darkSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border(left: BorderSide(color: borderColor, width: 4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with sport and status
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    sportName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: efficialsYellow,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      status.toUpperCase(),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                      ),
                    ),
                  ),
                ],
              ),
              Text(
                '\$${fee.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Game details
          Text(
            opponent,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          
          Row(
            children: [
              Icon(Icons.schedule, size: 14, color: Colors.grey[400]),
              const SizedBox(width: 4),
              Text(
                '$dateString at $timeString',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[400],
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          
          Row(
            children: [
              Icon(Icons.location_on, size: 14, color: Colors.grey[400]),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  locationName,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[400],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          
          Row(
            children: [
              Icon(Icons.person, size: 14, color: Colors.grey[400]),
              const SizedBox(width: 4),
              Text(
                'Position: $position',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[400],
                ),
              ),
            ],
          ),
          
          if (assignment.responseNotes != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 14, color: Colors.grey[400]),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      assignment.responseNotes!,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[400],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          
          const SizedBox(height: 12),
          
          // Assignment metadata
          Text(
            'Assigned by ${'Scheduler'} • ${_formatTimeAgo(assignment.assignedAt)}',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[500],
            ),
          ),
          
          // Status-specific information
          if (status == 'pending') ...[
            const SizedBox(height: 4),
            Text(
              'Expires in ${_formatTimeRemaining(DateTime.now().add(Duration(days: 2)))}',
              style: const TextStyle(
                fontSize: 12,
                color: Colors.orange,
                fontWeight: FontWeight.w500,
              ),
            ),
          ] else if (status == 'accepted') ...[
            const SizedBox(height: 4),
            Text(
              assignment.respondedAt != null 
                  ? 'Accepted ${_formatTimeAgo(assignment.respondedAt!)}'
                  : 'Accepted',
              style: const TextStyle(
                fontSize: 12,
                color: Colors.green,
              ),
            ),
          ] else if (status == 'declined') ...[
            const SizedBox(height: 4),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  assignment.respondedAt != null 
                      ? 'Declined ${_formatTimeAgo(assignment.respondedAt!)}'
                      : 'Declined',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.red,
                  ),
                ),
                if (assignment.responseNotes != null)
                  Text(
                    'Reason: ${assignment.responseNotes!}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
              ],
            ),
          ],
          
          // Action buttons for pending assignments
          if (status == 'pending') ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _showDeclineDialog(assignment),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                    ),
                    child: const Text('Decline'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _acceptAssignment(assignment),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: efficialsYellow,
                      foregroundColor: efficialsBlack,
                    ),
                    child: const Text('Accept'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    String message;
    String subtitle;
    
    switch (_selectedFilter) {
      case 'Pending':
        message = 'No pending assignments';
        subtitle = 'New assignment requests will appear here';
        break;
      case 'Accepted':
        message = 'No accepted assignments';
        subtitle = 'Assignments you accept will appear here';
        break;
      case 'Declined':
        message = 'No declined assignments';
        subtitle = 'Assignments you decline will appear here';
        break;
      default:
        message = 'No assignments yet';
        subtitle = 'Game assignments from schedulers will appear here';
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.assignment, size: 64, color: Colors.grey[600]),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[400],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _acceptAssignment(GameAssignment assignment) async {
    try {
      await _assignmentRepo.updateAssignmentStatus(assignment.id!, 'accepted');
      await _loadAssignments(); // Reload data
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Assignment accepted for ${assignment.opponent ?? 'game'}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error accepting assignment: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showDeclineDialog(GameAssignment assignment) {
    final reasonController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: darkSurface,
        title: const Text(
          'Decline Assignment',
          style: TextStyle(color: efficialsYellow),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Are you sure you want to decline this assignment for ${assignment.opponent}?',
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Reason (optional)',
                labelStyle: TextStyle(color: Colors.grey),
                border: OutlineInputBorder(),
              ),
              style: const TextStyle(color: Colors.white),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: efficialsYellow)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _declineAssignment(assignment, reasonController.text.trim());
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Decline'),
          ),
        ],
      ),
    );
  }

  void _declineAssignment(GameAssignment assignment, String reason) async {
    try {
      await _assignmentRepo.updateAssignmentStatus(assignment.id!, 'declined', 
          responseNotes: reason.isNotEmpty ? reason : 'No reason provided');
      await _loadAssignments(); // Reload data
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Assignment declined for ${assignment.opponent ?? 'game'}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error declining assignment: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    const weekdays = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    
    return '${weekdays[date.weekday % 7]}, ${months[date.month - 1]} ${date.day}';
  }

  String _formatTimeAgo(DateTime dateTime) {
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

  String _formatTimeRemaining(DateTime expiresAt) {
    final now = DateTime.now();
    final difference = expiresAt.difference(now);
    
    if (difference.isNegative) {
      return 'Expired';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'}';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'}';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'}';
    } else {
      return 'Expires soon';
    }
  }
  
  String _formatTime(DateTime time) {
    final hour = time.hour;
    final minute = time.minute;
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    
    return '$displayHour:${minute.toString().padLeft(2, '0')} $period';
  }
}