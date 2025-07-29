import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../shared/theme.dart';
import '../../shared/services/user_session_service.dart';
import '../../shared/services/repositories/notification_repository.dart';
import '../../shared/services/repositories/official_repository.dart';
import '../../shared/models/database_models.dart' as models;

class OfficialNotificationsScreen extends StatefulWidget {
  const OfficialNotificationsScreen({super.key});

  @override
  State<OfficialNotificationsScreen> createState() =>
      _OfficialNotificationsScreenState();
}

class _OfficialNotificationsScreenState
    extends State<OfficialNotificationsScreen>
    with SingleTickerProviderStateMixin {
  final NotificationRepository _notificationRepo = NotificationRepository();
  final OfficialRepository _officialRepo = OfficialRepository();
  List<models.Notification> _notifications = [];
  bool _isLoading = true;
  int? _currentOfficialId;
  late TabController _tabController;
  bool _showUnread = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_onTabChanged);
    _loadNotifications();
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) {
      setState(() {
        _showUnread = _tabController.index == 0;
      });
      _loadNotifications();
    }
  }

  Future<void> _loadNotifications() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Get current user session and official record
      final userSession = UserSessionService.instance;
      final userId = await userSession.getCurrentUserId();
      final userType = await userSession.getCurrentUserType();

      if (userId == null || userType != 'official') {
        // Handle error - redirect to login
        return;
      }

      // Get the official record to get the official ID
      final official = await _officialRepo.getOfficialByOfficialUserId(userId);

      if (official?.id == null) {
        // Handle error - no official record found
        return;
      }

      _currentOfficialId = official!.id!;

      debugPrint('Loading notifications for official ID: $_currentOfficialId');

      // Load notifications based on current tab from official_notifications table
      final notificationMaps = await _notificationRepo.getOfficialNotifications(
        _currentOfficialId!,
        unreadOnly: _showUnread,
        readOnly: !_showUnread && !_showUnread, // Only read if on "read" tab
      );

      // Convert to Notification objects for display
      final notifications =
          notificationMaps.map((map) => _mapToNotification(map)).toList();

      debugPrint(
          'Found ${notifications.length} notifications for official $_currentOfficialId');

      if (mounted) {
        setState(() {
          _notifications = notifications;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading notifications: $e');
      if (mounted) {
        setState(() {
          _notifications = [];
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _markAsRead(models.Notification notification) async {
    if (notification.isRead) return;

    try {
      await _notificationRepo.markOfficialNotificationAsRead(notification.id!);

      // Update UI immediately
      setState(() {
        final index = _notifications.indexWhere((n) => n.id == notification.id);
        if (index != -1) {
          _notifications[index] = models.Notification(
            id: notification.id,
            recipientId: notification.recipientId,
            type: notification.type,
            title: notification.title,
            message: notification.message,
            data: notification.data,
            isRead: true,
            createdAt: notification.createdAt,
            readAt: DateTime.now(),
          );
        }
      });

      // If showing unread only, reload to remove this notification
      if (_showUnread) {
        _loadNotifications();
      }
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
    }
  }

  Future<void> _markAllAsRead() async {
    if (_currentOfficialId == null) return;

    try {
      await _notificationRepo
          .markAllOfficialNotificationsAsRead(_currentOfficialId!);
      _loadNotifications();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('All notifications marked as read'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error marking all notifications as read: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error marking notifications as read'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteNotification(models.Notification notification) async {
    try {
      await _notificationRepo.deleteOfficialNotification(notification.id!);

      // Update UI immediately
      setState(() {
        _notifications.removeWhere((n) => n.id == notification.id);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Notification deleted'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error deleting notification: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error deleting notification'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Convert official_notifications table row to Notification model
  models.Notification _mapToNotification(Map<String, dynamic> map) {
    return models.Notification(
      id: map['id'] as int?,
      recipientId: map['official_id'] as int, // Use official_id as recipient
      type: map['type'] as String,
      title: map['title'] as String,
      message: map['message'] as String,
      data: map['related_game_id'] != null
          ? {'game_id': map['related_game_id']}
          : null,
      isRead: map['read_at'] != null,
      createdAt: DateTime.parse(map['created_at'] as String),
      readAt: map['read_at'] != null
          ? DateTime.parse(map['read_at'] as String)
          : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: darkBackground,
      appBar: AppBar(
        backgroundColor: efficialsBlack,
        title: const Text(
          'Notifications',
          style: TextStyle(color: efficialsYellow, fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: efficialsWhite),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (_showUnread && _notifications.isNotEmpty)
            TextButton(
              onPressed: _markAllAsRead,
              child: const Text(
                'Mark All Read',
                style: TextStyle(color: efficialsYellow, fontSize: 14),
              ),
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: efficialsYellow,
          labelColor: efficialsYellow,
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(text: 'Unread'),
            Tab(text: 'All'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildNotificationsList(unreadOnly: true),
          _buildNotificationsList(unreadOnly: false),
        ],
      ),
    );
  }

  Widget _buildNotificationsList({required bool unreadOnly}) {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: efficialsYellow),
            SizedBox(height: 16),
            Text(
              'Loading notifications...',
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
          ],
        ),
      );
    }

    if (_notifications.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              unreadOnly ? Icons.notifications_none : Icons.notifications_off,
              size: 64,
              color: Colors.grey[600],
            ),
            const SizedBox(height: 16),
            Text(
              unreadOnly ? 'No unread notifications' : 'No notifications yet',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[400],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              unreadOnly
                  ? 'You\'re all caught up!'
                  : 'Notifications about game assignments\nand removals will appear here.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadNotifications,
      color: efficialsYellow,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _notifications.length,
        itemBuilder: (context, index) {
          final notification = _notifications[index];
          return _buildNotificationCard(notification);
        },
      ),
    );
  }

  Widget _buildNotificationCard(models.Notification notification) {
    final isRead = notification.isRead;
    final createdAt = _formatNotificationDate(notification.createdAt);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isRead ? darkSurface : darkSurface.withOpacity(0.8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isRead
              ? Colors.grey.withOpacity(0.2)
              : efficialsYellow.withOpacity(0.3),
          width: isRead ? 1 : 2,
        ),
        boxShadow: isRead
            ? null
            : [
                BoxShadow(
                  color: efficialsYellow.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _getNotificationIcon(notification.type),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      notification.title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isRead ? Colors.grey[300] : efficialsYellow,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      createdAt,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ),
              if (!isRead)
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: efficialsYellow,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            notification.message,
            style: TextStyle(
              fontSize: 14,
              color: isRead ? Colors.grey[400] : Colors.white,
              height: 1.4,
            ),
          ),
          if (notification.type == 'official_removal' &&
              notification.data != null)
            _buildRemovalDetails(notification.data!),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (!isRead)
                TextButton.icon(
                  onPressed: () => _markAsRead(notification),
                  icon: const Icon(Icons.mark_email_read, size: 16),
                  label: const Text('Mark as Read'),
                  style: TextButton.styleFrom(
                    foregroundColor: efficialsYellow,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  ),
                ),
              const SizedBox(width: 8),
              TextButton.icon(
                onPressed: () => _deleteNotification(notification),
                icon: const Icon(Icons.delete, size: 16),
                label: const Text('Delete'),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.red,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _getNotificationIcon(String type) {
    IconData iconData;
    Color iconColor;

    switch (type) {
      case 'official_removal':
        iconData = Icons.person_remove;
        iconColor = Colors.red.shade300; // Lighter red
        break;
      case 'game_assignment':
        iconData = Icons.assignment;
        iconColor = Colors.green;
        break;
      case 'schedule_change':
        iconData = Icons.schedule;
        iconColor = Colors.orange;
        break;
      default:
        iconData = Icons.notifications;
        iconColor = efficialsYellow;
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: type == 'official_removal'
            ? Colors.transparent // Remove background for removal notifications
            : iconColor.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        iconData,
        color: iconColor,
        size: 20,
      ),
    );
  }

  Widget _buildRemovalDetails(Map<String, dynamic> data) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (data['game_sport'] != null) ...[
            _buildDetailRow('Sport', data['game_sport']),
            const SizedBox(height: 4),
          ],
          if (data['game_opponent'] != null) ...[
            _buildDetailRow('Opponent', data['game_opponent']),
            const SizedBox(height: 4),
          ],
          if (data['game_date'] != null) ...[
            _buildDetailRow('Date', _formatGameDate(data['game_date'])),
            const SizedBox(height: 4),
          ],
          if (data['game_time'] != null) ...[
            _buildDetailRow('Time', data['game_time']),
            const SizedBox(height: 4),
          ],
          if (data['scheduler_name'] != null)
            _buildDetailRow('Removed by', data['scheduler_name']),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            '$label:',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[400],
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  String _formatNotificationDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return DateFormat('MMM d, yyyy').format(date);
    }
  }

  String _formatGameDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('MMM d, yyyy').format(date);
    } catch (e) {
      return dateString;
    }
  }
}
