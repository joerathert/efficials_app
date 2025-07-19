import 'package:flutter/material.dart';
import '../../shared/theme.dart';

class OfficialAssignmentsScreen extends StatefulWidget {
  const OfficialAssignmentsScreen({super.key});

  @override
  State<OfficialAssignmentsScreen> createState() => _OfficialAssignmentsScreenState();
}

class _OfficialAssignmentsScreenState extends State<OfficialAssignmentsScreen> {
  String _selectedFilter = 'All';

  // Mock data for demonstration
  final List<Map<String, dynamic>> assignments = [
    {
      'id': 1,
      'sport': 'Football',
      'date': DateTime.now().add(const Duration(days: 3)),
      'time': '7:00 PM',
      'school': 'Lincoln High vs Roosevelt',
      'location': 'Lincoln High School',
      'fee': 60.0,
      'status': 'pending',
      'position': 'Referee',
      'assignedBy': 'Sarah Johnson',
      'assignedAt': DateTime.now().subtract(const Duration(hours: 2)),
      'expiresAt': DateTime.now().add(const Duration(hours: 22)),
      'notes': 'JV game, 2 officials needed',
    },
    {
      'id': 2,
      'sport': 'Basketball',
      'date': DateTime.now().add(const Duration(days: 4)),
      'time': '2:00 PM',
      'school': 'Central vs North',
      'location': 'Central High School',
      'fee': 45.0,
      'status': 'pending',
      'position': 'Umpire',
      'assignedBy': 'Mike Thompson',
      'assignedAt': DateTime.now().subtract(const Duration(hours: 5)),
      'expiresAt': DateTime.now().add(const Duration(hours: 19)),
      'notes': 'Varsity game',
    },
    {
      'id': 3,
      'sport': 'Basketball',
      'date': DateTime.now().add(const Duration(days: 7)),
      'time': '6:30 PM',
      'school': 'East vs West',
      'location': 'East High School',
      'fee': 45.0,
      'status': 'pending',
      'position': 'Referee',
      'assignedBy': 'Lisa Davis',
      'assignedAt': DateTime.now().subtract(const Duration(minutes: 30)),
      'expiresAt': DateTime.now().add(const Duration(hours: 47, minutes: 30)),
      'notes': 'Conference championship game',
    },
    {
      'id': 4,
      'sport': 'Football',
      'date': DateTime.now().add(const Duration(days: 1)),
      'time': '7:00 PM',
      'school': 'Madison vs Jefferson',
      'location': 'Madison High School',
      'fee': 60.0,
      'status': 'accepted',
      'position': 'Referee',
      'assignedBy': 'Tom Wilson',
      'assignedAt': DateTime.now().subtract(const Duration(days: 2)),
      'acceptedAt': DateTime.now().subtract(const Duration(days: 1)),
    },
    {
      'id': 5,
      'sport': 'Basketball',
      'date': DateTime.now().subtract(const Duration(days: 1)),
      'time': '1:00 PM',
      'school': 'Adams vs Wilson',
      'location': 'Adams High School',
      'fee': 45.0,
      'status': 'declined',
      'position': 'Umpire',
      'assignedBy': 'Sarah Johnson',
      'assignedAt': DateTime.now().subtract(const Duration(days: 3)),
      'declinedAt': DateTime.now().subtract(const Duration(days: 2)),
      'declineReason': 'Schedule conflict',
    },
  ];

  List<Map<String, dynamic>> get filteredAssignments {
    List<Map<String, dynamic>> filtered = assignments;

    if (_selectedFilter == 'Pending') {
      filtered = filtered.where((assignment) => assignment['status'] == 'pending').toList();
    } else if (_selectedFilter == 'Accepted') {
      filtered = filtered.where((assignment) => assignment['status'] == 'accepted').toList();
    } else if (_selectedFilter == 'Declined') {
      filtered = filtered.where((assignment) => assignment['status'] == 'declined').toList();
    }

    // Sort by date/priority
    filtered.sort((a, b) {
      // Pending assignments first, then by date
      if (a['status'] == 'pending' && b['status'] != 'pending') return -1;
      if (b['status'] == 'pending' && a['status'] != 'pending') return 1;
      return a['date'].compareTo(b['date']);
    });

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final pendingCount = assignments.where((a) => a['status'] == 'pending').length;

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
                child: filteredAssignments.isEmpty
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

  Widget _buildAssignmentCard(Map<String, dynamic> assignment) {
    final status = assignment['status'] as String;
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
                    assignment['sport'],
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
                '\$${assignment['fee']}',
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
            assignment['school'],
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
                '${_formatDate(assignment['date'])} at ${assignment['time']}',
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
                  assignment['location'],
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
                'Position: ${assignment['position']}',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[400],
                ),
              ),
            ],
          ),
          
          if (assignment['notes'] != null) ...[
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
                      assignment['notes'],
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
            'Assigned by ${assignment['assignedBy']} • ${_formatTimeAgo(assignment['assignedAt'])}',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[500],
            ),
          ),
          
          // Status-specific information
          if (status == 'pending') ...[
            const SizedBox(height: 4),
            Text(
              'Expires in ${_formatTimeRemaining(assignment['expiresAt'])}',
              style: const TextStyle(
                fontSize: 12,
                color: Colors.orange,
                fontWeight: FontWeight.w500,
              ),
            ),
          ] else if (status == 'accepted') ...[
            const SizedBox(height: 4),
            Text(
              'Accepted ${_formatTimeAgo(assignment['acceptedAt'])}',
              style: const TextStyle(
                fontSize: 12,
                color: Colors.green,
              ),
            ),
          ] else if (status == 'declined') ...[
            const SizedBox(height: 4),
            Text(
              'Declined ${_formatTimeAgo(assignment['declinedAt'])} • ${assignment['declineReason']}',
              style: const TextStyle(
                fontSize: 12,
                color: Colors.red,
              ),
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

  void _acceptAssignment(Map<String, dynamic> assignment) {
    setState(() {
      assignment['status'] = 'accepted';
      assignment['acceptedAt'] = DateTime.now();
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Assignment accepted for ${assignment['school']}'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showDeclineDialog(Map<String, dynamic> assignment) {
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
              'Are you sure you want to decline this assignment for ${assignment['school']}?',
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

  void _declineAssignment(Map<String, dynamic> assignment, String reason) {
    setState(() {
      assignment['status'] = 'declined';
      assignment['declinedAt'] = DateTime.now();
      assignment['declineReason'] = reason.isNotEmpty ? reason : 'No reason provided';
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Assignment declined for ${assignment['school']}'),
        backgroundColor: Colors.red,
      ),
    );
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
}