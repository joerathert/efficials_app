import 'package:flutter/material.dart';
import '../../shared/theme.dart';
import '../../shared/services/user_session_service.dart';
import '../../shared/services/repositories/notification_repository.dart';
import '../../shared/models/database_models.dart' as models;

class BackoutNotificationsScreen extends StatefulWidget {
  const BackoutNotificationsScreen({super.key});

  @override
  State<BackoutNotificationsScreen> createState() => _BackoutNotificationsScreenState();
}

class _BackoutNotificationsScreenState extends State<BackoutNotificationsScreen> with SingleTickerProviderStateMixin {
  final NotificationRepository _notificationRepo = NotificationRepository();
  List<models.Notification> _notifications = [];
  bool _isLoading = true;
  int? _currentUserId;
  late TabController _tabController;
  bool _showUnread = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_onTabChanged);
    _initializePushNotifications();
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

  Future<void> _initializePushNotifications() async {
    try {
      final userSession = UserSessionService.instance;
      final userId = await userSession.getCurrentUserId();
      
      if (userId != null) {
        // Request permission for push notifications
        final permissionGranted = await _notificationRepo.requestPushPermission();
        
        if (permissionGranted) {
          // Subscribe to push notifications
          await _notificationRepo.subscribeToPush(userId);
          
          // Initialize push notification handlers
          await _notificationRepo.initializePushNotifications(userId);
        }
      }
    } catch (e) {
      print('Error initializing push notifications: $e');
    }
  }

  Future<void> _loadNotifications() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final userSession = UserSessionService.instance;
      _currentUserId = await userSession.getCurrentUserId();
      
      if (_currentUserId != null) {
        final notifications = await _notificationRepo.getNotifications(
          _currentUserId!, 
          unreadOnly: _showUnread, 
          readOnly: !_showUnread
        );
        
        if (mounted) {
          setState(() {
            _notifications = notifications;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      print('Error loading notifications: $e');
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
          'Notifications',
          style: TextStyle(color: efficialsWhite),
        ),
        iconTheme: const IconThemeData(color: efficialsWhite),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: efficialsYellow,
          unselectedLabelColor: Colors.grey[400],
          indicatorColor: efficialsYellow,
          tabs: const [
            Tab(text: 'Unread'),
            Tab(text: 'Read'),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: efficialsWhite),
            color: darkSurface,
            onSelected: (value) {
              switch (value) {
                case 'settings':
                  Navigator.pushNamed(context, '/notification_settings');
                  break;
                case 'mark_all_read':
                  _markAllAsRead();
                  break;
              }
            },
            itemBuilder: (BuildContext context) => [
              PopupMenuItem<String>(
                value: 'settings',
                child: Row(
                  children: [
                    Icon(Icons.settings, color: Colors.grey[300], size: 20),
                    const SizedBox(width: 12),
                    Text(
                      'Notification Settings',
                      style: TextStyle(color: Colors.grey[300]),
                    ),
                  ],
                ),
              ),
              if (_notifications.isNotEmpty)
                PopupMenuItem<String>(
                  value: 'mark_all_read',
                  child: Row(
                    children: [
                      Icon(Icons.done_all, color: Colors.grey[300], size: 20),
                      const SizedBox(width: 12),
                      Text(
                        'Mark All as Read',
                        style: TextStyle(color: Colors.grey[300]),
                      ),
                    ],
                  ),
                ),
            ],
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
                    'Loading notifications...',
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                ],
              ),
            )
          : _notifications.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
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
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(40),
              ),
              child: Icon(
                Icons.check_circle,
                size: 40,
                color: Colors.green.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'No Pending Notifications',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: efficialsYellow,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'You\'re all caught up! New notifications will appear here when there are updates about your games, officials, or other important information.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[400],
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationCard(models.Notification notification) {
    switch (notification.type) {
      case 'backout':
        return _buildBackoutNotificationCard(notification);
      case 'crew_backout':
        return _buildCrewBackoutNotificationCard(notification);
      case 'game_filling':
        return _buildGameFillingNotificationCard(notification);
      case 'official_interest':
        return _buildOfficialInterestNotificationCard(notification);
      case 'official_claim':
        return _buildOfficialClaimNotificationCard(notification);
      default:
        return _buildGenericNotificationCard(notification);
    }
  }

  Widget _buildBackoutNotificationCard(models.Notification notification) {
    final data = notification.data ?? {};
    final officialName = data['official_name'] ?? 'Unknown Official';
    final backoutReason = data['reason'] ?? 'No reason provided';

    return _buildNotificationCardBase(
      notification: notification,
      iconData: Icons.person_remove,
      iconColor: Colors.red,
      borderColor: Colors.red.withOpacity(0.3),
      headerColor: Colors.red.withOpacity(0.1),
      statusText: 'NEEDS ACTION',
      statusColor: Colors.orange[300]!,
      title: '$officialName backed out',
      subtitle: 'Backed out ${_formatTimeAgo(notification.createdAt)}',
      additionalContent: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Reason for Backing Out',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.grey[300],
            ),
          ),
          const SizedBox(height: 4),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              backoutReason,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[300],
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
      actions: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _showExcuseDialog(notification),
            icon: const Icon(Icons.check_circle_outline, size: 18),
            label: const Text('Excuse Official'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.green,
              side: const BorderSide(color: Colors.green),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _markAsRead(notification),
            icon: const Icon(Icons.visibility, size: 18),
            label: const Text('Mark as Seen'),
            style: OutlinedButton.styleFrom(
              foregroundColor: efficialsYellow,
              side: const BorderSide(color: efficialsYellow),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCrewBackoutNotificationCard(models.Notification notification) {
    final data = notification.data ?? {};
    final crewName = data['crew_name'] ?? 'Unknown Crew';
    final backoutReason = data['reason'] ?? 'No reason provided';
    final crewData = data['crew_data'] ?? {};

    return _buildNotificationCardBase(
      notification: notification,
      iconData: Icons.group_remove,
      iconColor: Colors.red,
      borderColor: Colors.red.withOpacity(0.3),
      headerColor: Colors.red.withOpacity(0.1),
      statusText: 'CREW BACKOUT',
      statusColor: Colors.red[300]!,
      title: '$crewName backed out',
      subtitle: 'Crew backed out ${_formatTimeAgo(notification.createdAt)}',
      additionalContent: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Reason for Backing Out',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.grey[300],
            ),
          ),
          const SizedBox(height: 4),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              backoutReason,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[300],
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
          if (crewData.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              'Crew Information',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.grey[300],
              ),
            ),
            const SizedBox(height: 4),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (crewData['members'] != null)
                    Text(
                      'Members: ${crewData['members']}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[400],
                      ),
                    ),
                  if (crewData['chief'] != null)
                    Text(
                      'Crew Chief: ${crewData['chief']}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[400],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
      actions: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _showExcuseDialog(notification),
            icon: const Icon(Icons.check_circle_outline, size: 18),
            label: const Text('Excuse Crew'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.green,
              side: const BorderSide(color: Colors.green),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _markAsRead(notification),
            icon: const Icon(Icons.visibility, size: 18),
            label: const Text('Mark as Seen'),
            style: OutlinedButton.styleFrom(
              foregroundColor: efficialsYellow,
              side: const BorderSide(color: efficialsYellow),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGameFillingNotificationCard(models.Notification notification) {
    final data = notification.data ?? {};
    final officialsNeeded = data['officials_needed'] ?? 1;
    final daysUntilGame = data['days_until_game'] ?? 0;

    return _buildNotificationCardBase(
      notification: notification,
      iconData: Icons.group_add,
      iconColor: Colors.orange,
      borderColor: Colors.orange.withOpacity(0.3),
      headerColor: Colors.orange.withOpacity(0.1),
      statusText: 'NEEDS OFFICIALS',
      statusColor: Colors.orange[300]!,
      title: 'Game needs $officialsNeeded official${officialsNeeded > 1 ? 's' : ''}',
      subtitle: '$daysUntilGame day${daysUntilGame != 1 ? 's' : ''} until game',
      actions: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _viewGame(notification),
            icon: const Icon(Icons.visibility, size: 18),
            label: const Text('View Game'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.orange,
              side: const BorderSide(color: Colors.orange),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _markAsRead(notification),
            icon: const Icon(Icons.check, size: 18),
            label: const Text('Mark as Seen'),
            style: OutlinedButton.styleFrom(
              foregroundColor: efficialsYellow,
              side: const BorderSide(color: efficialsYellow),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOfficialInterestNotificationCard(models.Notification notification) {
    final data = notification.data ?? {};
    final officialName = data['official_name'] ?? 'Unknown Official';

    return _buildNotificationCardBase(
      notification: notification,
      iconData: Icons.thumb_up,
      iconColor: Colors.blue,
      borderColor: Colors.blue.withOpacity(0.3),
      headerColor: Colors.blue.withOpacity(0.1),
      statusText: 'INTERESTED',
      statusColor: Colors.blue[300]!,
      title: '$officialName showed interest',
      subtitle: 'Expressed interest ${_formatTimeAgo(notification.createdAt)}',
      actions: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _viewOfficialProfile(notification),
            icon: const Icon(Icons.person, size: 18),
            label: const Text('View Official'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.blue,
              side: const BorderSide(color: Colors.blue),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _markAsRead(notification),
            icon: const Icon(Icons.check, size: 18),
            label: const Text('Mark as Seen'),
            style: OutlinedButton.styleFrom(
              foregroundColor: efficialsYellow,
              side: const BorderSide(color: efficialsYellow),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOfficialClaimNotificationCard(models.Notification notification) {
    final data = notification.data ?? {};
    final officialName = data['official_name'] ?? 'Unknown Official';

    return _buildNotificationCardBase(
      notification: notification,
      iconData: Icons.assignment_ind,
      iconColor: Colors.green,
      borderColor: Colors.green.withOpacity(0.3),
      headerColor: Colors.green.withOpacity(0.1),
      statusText: 'CLAIMED',
      statusColor: Colors.green[300]!,
      title: '$officialName claimed game',
      subtitle: 'Claimed game ${_formatTimeAgo(notification.createdAt)}',
      actions: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _approveAssignment(notification),
            icon: const Icon(Icons.check_circle, size: 18),
            label: const Text('Approve'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.green,
              side: const BorderSide(color: Colors.green),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _markAsRead(notification),
            icon: const Icon(Icons.visibility, size: 18),
            label: const Text('Review Later'),
            style: OutlinedButton.styleFrom(
              foregroundColor: efficialsYellow,
              side: const BorderSide(color: efficialsYellow),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGenericNotificationCard(models.Notification notification) {
    return _buildNotificationCardBase(
      notification: notification,
      iconData: Icons.notifications,
      iconColor: efficialsYellow,
      borderColor: Colors.grey.withOpacity(0.3),
      headerColor: Colors.grey.withOpacity(0.1),
      statusText: 'INFO',
      statusColor: Colors.grey[300]!,
      title: notification.title,
      subtitle: _formatTimeAgo(notification.createdAt),
      actions: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _markAsRead(notification),
            icon: const Icon(Icons.check, size: 18),
            label: const Text('Mark as Read'),
            style: OutlinedButton.styleFrom(
              foregroundColor: efficialsYellow,
              side: const BorderSide(color: efficialsYellow),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNotificationCardBase({
    required models.Notification notification,
    required IconData iconData,
    required Color iconColor,
    required Color borderColor,
    required Color headerColor,
    required String statusText,
    required Color statusColor,
    required String title,
    required String subtitle,
    Widget? additionalContent,
    required List<Widget> actions,
  }) {
    final data = notification.data ?? {};
    final gameSport = data['game_sport'] ?? data['sport'] ?? 'Game';
    final gameTitle = data['game_title'] ?? 'Game Details';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: darkSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: headerColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(
                    iconData,
                    color: iconColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: iconColor,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[400],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Content
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Game Details
                Text(
                  'Game Details',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[300],
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.sports, size: 16, color: Colors.grey[400]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '$gameSport: $gameTitle',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                
                // Message
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    notification.message,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[300],
                    ),
                  ),
                ),
                
                if (additionalContent != null) ...[
                  const SizedBox(height: 16),
                  additionalContent,
                ],
                
                const SizedBox(height: 16),
                
                // Actions
                Row(children: actions),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showExcuseDialog(models.Notification notification) {
    final TextEditingController reasonController = TextEditingController();
    final data = notification.data ?? {};
    final officialName = data['official_name'] ?? 'Unknown Official';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: darkSurface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 24),
              const SizedBox(width: 8),
              const Text(
                'Excuse Official',
                style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'You are about to excuse $officialName for backing out of this game. This will not negatively impact their follow-through rate.',
                style: TextStyle(color: Colors.grey[300], fontSize: 16),
              ),
              const SizedBox(height: 16),
              Text(
                'Reason for excuse (optional):',
                style: TextStyle(
                  color: Colors.grey[300],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: reasonController,
                maxLines: 3,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'e.g., Emergency, illness, family matter...',
                  hintStyle: TextStyle(color: Colors.grey[500]),
                  filled: true,
                  fillColor: Colors.black.withOpacity(0.3),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey[600]!),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey[600]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Colors.green),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.grey[400],
                side: BorderSide(color: Colors.grey[600]!),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _excuseOfficial(notification, reasonController.text.trim());
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              child: const Text('Excuse Official'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _excuseOfficial(models.Notification notification, String reason) async {
    try {
      final excuseReason = reason.isEmpty ? 'Excused by scheduler' : reason;
      final data = notification.data ?? {};
      final officialName = data['official_name'] ?? 'Unknown Official';
      
      // Mark notification as read and handle excuse logic
      await _notificationRepo.markAsRead(notification.id!);

      // Reload notifications to reflect the change
      await _loadNotifications();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$officialName has been excused'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      print('Error excusing official: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to excuse official. Please try again.'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _markAsRead(models.Notification notification) async {
    try {
      await _notificationRepo.markAsRead(notification.id!);

      // Reload notifications to reflect the change in the appropriate tab
      await _loadNotifications();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Notification marked as read'),
            backgroundColor: efficialsYellow,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('Error marking notification as read: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to mark notification. Please try again.'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
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

  String _formatDate(DateTime date) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                   'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    
    final dayName = days[date.weekday - 1];
    final monthName = months[date.month - 1];
    
    return '$dayName, $monthName ${date.day}';
  }

  String _formatGameTime(String? timeString) {
    if (timeString == null || timeString.isEmpty) return 'TBD';
    
    try {
      final time = DateTime.parse('1970-01-01 $timeString');
      final hour = time.hour;
      final minute = time.minute;
      final period = hour >= 12 ? 'PM' : 'AM';
      final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
      
      return '$displayHour:${minute.toString().padLeft(2, '0')} $period';
    } catch (e) {
      return timeString;
    }
  }

  // Placeholder methods for new notification actions
  void _viewGame(models.Notification notification) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Game view functionality will be implemented soon'),
        backgroundColor: Colors.orange,
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _viewOfficialProfile(models.Notification notification) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Official profile view functionality will be implemented soon'),
        backgroundColor: Colors.blue,
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _approveAssignment(models.Notification notification) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Assignment approval functionality will be implemented soon'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _markAllAsRead() async {
    if (_currentUserId == null || _notifications.isEmpty) return;

    try {
      await _notificationRepo.markAllAsRead(_currentUserId!);
      
      // Reload notifications to reflect the change
      await _loadNotifications();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('All notifications marked as read'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('Error marking all notifications as read: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to mark all notifications as read'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }
}