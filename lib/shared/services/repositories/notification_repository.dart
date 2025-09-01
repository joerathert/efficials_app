import 'dart:convert';
// Temporarily commented out for web testing
// import 'notification_repository_web_stub.dart'
//     if (dart.library.io) 'package:firebase_messaging/firebase_messaging.dart';
import '../database_helper.dart';
import '../../models/database_models.dart' as models;

class NotificationRepository {
  final DatabaseHelper _db = DatabaseHelper();

  /// Get all notifications for a specific user
  Future<List<models.Notification>> getNotifications(int userId, {bool unreadOnly = false, bool readOnly = false}) async {
    final database = await _db.database;
    
    String whereClause = 'recipient_id = ?';
    List<dynamic> whereArgs = [userId];
    
    if (unreadOnly) {
      whereClause += ' AND is_read = 0';
    } else if (readOnly) {
      whereClause += ' AND is_read = 1';
    }
    
    final result = await database.query(
      'notifications',
      where: whereClause,
      whereArgs: whereArgs,
      orderBy: 'created_at DESC',
    );
    
    return result.map((row) => models.Notification.fromMap(row)).toList();
  }

  /// Get count of unread notifications for badge display
  Future<int> getUnreadNotificationCount(int userId) async {
    final database = await _db.database;
    
    final result = await database.rawQuery(
      'SELECT COUNT(*) as count FROM notifications WHERE recipient_id = ? AND is_read = 0',
      [userId],
    );
    
    return result.first['count'] as int;
  }

  /// Create a new notification
  Future<int> createNotification(models.Notification notification) async {
    final database = await _db.database;
    
    final notificationMap = notification.toMap();
    notificationMap.remove('id'); // Remove ID for insert
    
    return await database.insert('notifications', notificationMap);
  }

  /// Mark a notification as read
  Future<void> markAsRead(int notificationId) async {
    final database = await _db.database;
    
    await database.update(
      'notifications',
      {
        'is_read': 1,
        'read_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [notificationId],
    );
  }

  /// Mark all notifications as read for a user
  Future<void> markAllAsRead(int userId) async {
    final database = await _db.database;
    
    await database.update(
      'notifications',
      {
        'is_read': 1,
        'read_at': DateTime.now().toIso8601String(),
      },
      where: 'recipient_id = ? AND is_read = 0',
      whereArgs: [userId],
    );
  }

  /// Delete a notification
  Future<void> deleteNotification(int notificationId) async {
    final database = await _db.database;
    
    await database.delete(
      'notifications',
      where: 'id = ?',
      whereArgs: [notificationId],
    );
  }

  /// Get notifications by type
  Future<List<models.Notification>> getNotificationsByType(int userId, String type) async {
    final database = await _db.database;
    
    final result = await database.query(
      'notifications',
      where: 'recipient_id = ? AND type = ?',
      whereArgs: [userId, type],
      orderBy: 'created_at DESC',
    );
    
    return result.map((row) => models.Notification.fromMap(row)).toList();
  }

  /// Create backout notification
  Future<int> createBackoutNotification({
    required int schedulerId,
    required String officialName,
    required String gameSport,
    required String gameOpponent,
    required DateTime gameDate,
    required String gameTime,
    required String reason,
    Map<String, dynamic>? additionalData,
  }) async {
    final notification = models.Notification.createBackoutNotification(
      schedulerId: schedulerId,
      officialName: officialName,
      gameSport: gameSport,
      gameOpponent: gameOpponent,
      gameDate: gameDate,
      gameTime: gameTime,
      reason: reason,
      additionalData: additionalData,
    );
    
    return await createNotification(notification);
  }

  /// Create game filling notification
  Future<int> createGameFillingNotification({
    required int schedulerId,
    required String gameSport,
    required String gameOpponent,
    required DateTime gameDate,
    required String gameTime,
    required int officialsNeeded,
    required int daysUntilGame,
    Map<String, dynamic>? additionalData,
  }) async {
    final notification = models.Notification.createGameFillingNotification(
      schedulerId: schedulerId,
      gameSport: gameSport,
      gameOpponent: gameOpponent,
      gameDate: gameDate,
      gameTime: gameTime,
      officialsNeeded: officialsNeeded,
      daysUntilGame: daysUntilGame,
      additionalData: additionalData,
    );
    
    return await createNotification(notification);
  }

  /// Create official interest notification
  Future<int> createOfficialInterestNotification({
    required int schedulerId,
    required String officialName,
    required String gameSport,
    required String gameOpponent,
    required DateTime gameDate,
    required String gameTime,
    Map<String, dynamic>? additionalData,
  }) async {
    final notification = models.Notification.createOfficialInterestNotification(
      schedulerId: schedulerId,
      officialName: officialName,
      gameSport: gameSport,
      gameOpponent: gameOpponent,
      gameDate: gameDate,
      gameTime: gameTime,
      additionalData: additionalData,
    );
    
    return await createNotification(notification);
  }

  /// Create official claim notification
  Future<int> createOfficialClaimNotification({
    required int schedulerId,
    required String officialName,
    required String gameSport,
    required String gameOpponent,
    required DateTime gameDate,
    required String gameTime,
    Map<String, dynamic>? additionalData,
  }) async {
    final notification = models.Notification.createOfficialClaimNotification(
      schedulerId: schedulerId,
      officialName: officialName,
      gameSport: gameSport,
      gameOpponent: gameOpponent,
      gameDate: gameDate,
      gameTime: gameTime,
      additionalData: additionalData,
    );
    
    return await createNotification(notification);
  }

  /// Create crew backout notification
  Future<int> createCrewBackoutNotification({
    required int schedulerId,
    required String crewName,
    required String gameSport,
    required String gameOpponent,
    required DateTime gameDate,
    required String gameTime,
    required String reason,
    required Map<String, dynamic> crewData,
    Map<String, dynamic>? additionalData,
  }) async {
    final notification = models.Notification.createCrewBackoutNotification(
      schedulerId: schedulerId,
      crewName: crewName,
      gameSport: gameSport,
      gameOpponent: gameOpponent,
      gameDate: gameDate,
      gameTime: gameTime,
      reason: reason,
      crewData: crewData,
      additionalData: additionalData,
    );
    
    return await createNotification(notification);
  }

  /// Create official removal notification
  Future<int> createOfficialRemovalNotification({
    required int officialId,
    required String schedulerName,
    required String gameSport,
    required String gameOpponent,
    required DateTime gameDate,
    required String gameTime,
    Map<String, dynamic>? additionalData,
  }) async {
    // Use the official_notifications table instead of the general notifications table
    return await createOfficialNotification(
      officialId: officialId,
      type: 'official_removal',
      title: 'Removed from Game',
      message: 'You have been removed from the $gameSport game ($gameOpponent) on ${gameDate.toString().split(' ')[0]} at $gameTime by $schedulerName.',
      relatedGameId: additionalData?['game_id'],
    );
  }

  /// Create backout excuse notification for the official
  Future<int> createBackoutExcuseNotification({
    required int officialId,
    required String schedulerName,
    required String gameSport,
    required String gameOpponent,
    required DateTime gameDate,
    required String gameTime,
    required String excuseReason,
    Map<String, dynamic>? additionalData,
  }) async {
    // Use the official_notifications table instead of the general notifications table
    return await createOfficialNotification(
      officialId: officialId,
      type: 'backout_excuse',
      title: 'Backout Excused - Follow-Through Rate Restored',
      message: 'Your backout for the $gameSport game ($gameOpponent) on ${gameDate.toString().split(' ')[0]} at $gameTime has been excused by $schedulerName. Your follow-through rate has been restored. Reason: $excuseReason',
      relatedGameId: additionalData?['game_id'],
    );
  }

  // Official Notification Methods (using official_notifications table)

  /// Get all notifications for a specific official
  Future<List<Map<String, dynamic>>> getOfficialNotifications(int officialId, {bool unreadOnly = false, bool readOnly = false}) async {
    final database = await _db.database;
    
    String whereClause = 'official_id = ?';
    List<dynamic> whereArgs = [officialId];
    
    if (unreadOnly) {
      whereClause += ' AND read_at IS NULL';
    } else if (readOnly) {
      whereClause += ' AND read_at IS NOT NULL';
    }
    
    final result = await database.query(
      'official_notifications',
      where: whereClause,
      whereArgs: whereArgs,
      orderBy: 'created_at DESC',
    );
    
    return result;
  }

  /// Get count of unread notifications for an official
  Future<int> getUnreadOfficialNotificationCount(int officialId) async {
    final database = await _db.database;
    
    final result = await database.rawQuery(
      'SELECT COUNT(*) as count FROM official_notifications WHERE official_id = ? AND read_at IS NULL',
      [officialId],
    );
    
    return result.first['count'] as int;
  }

  /// Create a new official notification
  Future<int> createOfficialNotification({
    required int officialId,
    required String type,
    required String title,
    required String message,
    int? relatedGameId,
  }) async {
    final database = await _db.database;
    
    return await database.insert('official_notifications', {
      'official_id': officialId,
      'type': type,
      'title': title,
      'message': message,
      'related_game_id': relatedGameId,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  /// Mark an official notification as read
  Future<void> markOfficialNotificationAsRead(int notificationId) async {
    final database = await _db.database;
    
    await database.update(
      'official_notifications',
      {
        'read_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [notificationId],
    );
  }

  /// Mark all notifications as read for an official
  Future<void> markAllOfficialNotificationsAsRead(int officialId) async {
    final database = await _db.database;
    
    await database.update(
      'official_notifications',
      {
        'read_at': DateTime.now().toIso8601String(),
      },
      where: 'official_id = ? AND read_at IS NULL',
      whereArgs: [officialId],
    );
  }

  /// Delete an official notification
  Future<void> deleteOfficialNotification(int notificationId) async {
    final database = await _db.database;
    
    await database.delete(
      'official_notifications',
      where: 'id = ?',
      whereArgs: [notificationId],
    );
  }

  // Push Notification Methods (Web-compatible stubs)

  /// Request push notification permission
  Future<bool> requestPushPermission() async {
    try {
      // Temporarily disabled for web testing
      // final messaging = FirebaseMessaging.instance;
      // final settings = await messaging.requestPermission(
      //   alert: true,
      //   announcement: false,
      //   badge: true,
      //   carPlay: false,
      //   criticalAlert: false,
      //   provisional: false,
      //   sound: true,
      // );
      
      // On web, always return false for now since Firebase messaging has issues
      return false;
    } catch (e) {
      print('Error requesting push notification permission: $e');
      return false;
    }
  }

  /// Subscribe to push notifications for a user
  Future<bool> subscribeToPush(int userId) async {
    try {
      // Temporarily disabled for web testing
      // final messaging = FirebaseMessaging.instance;
      // 
      // // Subscribe to user-specific topics
      // await messaging.subscribeToTopic('user_${userId}_notifications');
      // await messaging.subscribeToTopic('user_${userId}_backouts');
      // await messaging.subscribeToTopic('user_${userId}_game_filling');
      // 
      // // Get and store FCM token for direct messaging if needed
      // final token = await messaging.getToken();
      // if (token != null) {
      //   // Store token in database or send to server
      //   print('FCM Token: $token');
      // }
      
      return true;
    } catch (e) {
      print('Error subscribing to push notifications: $e');
      return false;
    }
  }

  /// Unsubscribe from push notifications for a user
  Future<bool> unsubscribeFromPush(int userId) async {
    try {
      // Temporarily disabled for web testing
      // final messaging = FirebaseMessaging.instance;
      // 
      // // Unsubscribe from user-specific topics
      // await messaging.unsubscribeFromTopic('user_${userId}_notifications');
      // await messaging.unsubscribeFromTopic('user_${userId}_backouts');
      // await messaging.unsubscribeFromTopic('user_${userId}_game_filling');
      
      return true;
    } catch (e) {
      print('Error unsubscribing from push notifications: $e');
      return false;
    }
  }

  /// Initialize push notification handlers
  Future<void> initializePushNotifications(int userId) async {
    try {
      // Temporarily disabled for web testing
      // final messaging = FirebaseMessaging.instance;
      // 
      // // Handle foreground messages
      // messaging.onMessage.listen((RemoteMessage message) {
      //   print('Received foreground message: ${message.notification?.title}');
      //   // Handle the message and potentially create local notification
      // });
      // 
      // // Handle when app is opened from notification
      // messaging.onMessageOpenedApp.listen((RemoteMessage message) {
      //   print('App opened from notification: ${message.notification?.title}');
      //   // Navigate to appropriate screen based on message data
      // });
      // 
      // // Handle background messages
      // FirebaseMessaging.onBackgroundMessage = _firebaseMessagingBackgroundHandler;
      
    } catch (e) {
      print('Error initializing push notifications: $e');
    }
  }

  // Notification Settings Methods

  /// Get notification settings for a user
  Future<models.NotificationSettings?> getNotificationSettings(int userId) async {
    final database = await _db.database;
    
    final result = await database.query(
      'notification_settings',
      where: 'user_id = ?',
      whereArgs: [userId],
    );
    
    if (result.isEmpty) {
      return null;
    }
    
    return models.NotificationSettings.fromMap(result.first);
  }

  /// Create or update notification settings
  Future<void> saveNotificationSettings(models.NotificationSettings settings) async {
    final database = await _db.database;
    
    final settingsMap = settings.toMap();
    
    // Check if settings exist
    final existing = await getNotificationSettings(settings.userId);
    
    if (existing == null) {
      // Insert new settings
      settingsMap.remove('id');
      await database.insert('notification_settings', settingsMap);
    } else {
      // Update existing settings
      // Remove id and created_at for updates since they shouldn't change
      final updateMap = Map<String, dynamic>.from(settingsMap);
      updateMap.remove('id');
      updateMap.remove('created_at');
      updateMap['updated_at'] = DateTime.now().toIso8601String();
      
      await database.update(
        'notification_settings',
        updateMap,
        where: 'user_id = ?',
        whereArgs: [settings.userId],
      );
    }
  }

  /// Get default notification settings for a new user
  Future<models.NotificationSettings> getDefaultNotificationSettings(int userId) async {
    return models.NotificationSettings(
      userId: userId,
      backoutNotificationsEnabled: true,
      gameFillingNotificationsEnabled: true,
      officialInterestNotificationsEnabled: true,
      officialClaimNotificationsEnabled: true,
      gameFillingReminderDays: [3, 1], // 3 days and 1 day before
      emailEnabled: false,
      smsEnabled: false,
    );
  }

  /// Initialize default settings for a user if they don't exist
  Future<void> initializeUserNotificationSettings(int userId) async {
    final existing = await getNotificationSettings(userId);
    if (existing == null) {
      final defaultSettings = await getDefaultNotificationSettings(userId);
      await saveNotificationSettings(defaultSettings);
    }
  }

  /// Create game change notification for confirmed officials
  Future<void> createGameChangeNotifications({
    required int gameId,
    required String changeType, // 'date', 'time', 'location', 'home_team', 'away_team'
    required String oldValue,
    required String newValue,
    required int schedulerId,
    Map<String, dynamic>? additionalData,
  }) async {
    // Get all confirmed officials for this game
    final database = await _db.database;
    
    final confirmedOfficials = await database.rawQuery('''
      SELECT DISTINCT o.id, o.name, ga.id as assignment_id
      FROM game_assignments ga
      JOIN officials o ON ga.official_id = o.id
      WHERE ga.game_id = ? AND ga.status = 'accepted'
    ''', [gameId]);
    
    // Get game details for notification message
    final gameDetails = await database.rawQuery('''
      SELECT g.*, s.name as sport_name, l.name as location_name, sch.name as schedule_name
      FROM games g
      LEFT JOIN sports s ON g.sport_id = s.id
      LEFT JOIN locations l ON g.location_id = l.id
      LEFT JOIN schedules sch ON g.schedule_id = sch.id
      WHERE g.id = ?
    ''', [gameId]);
    
    if (gameDetails.isEmpty || confirmedOfficials.isEmpty) {
      return; // No game found or no confirmed officials
    }
    
    final game = gameDetails.first;
    final sportName = game['sport_name'] as String? ?? 'Game';
    final opponent = (game['opponent'] as String?) ?? (game['home_team'] as String?) ?? 'TBD';
    final gameDate = DateTime.parse(game['date'] as String);
    final gameTime = game['time'] as String? ?? 'TBD';
    
    // Format date and time for display
    final formattedDate = _formatDateForDisplay(gameDate);
    
    // Create notification title and message based on change type
    String title;
    String message;
    String changeDescription;
    String referenceTime; // Time to use in the initial game reference
    String referenceDate; // Date to use in the initial game reference
    
    switch (changeType.toLowerCase()) {
      case 'date':
        title = 'Game Date Changed';
        try {
          final oldFormattedDate = _formatDateForDisplay(DateTime.parse(oldValue));
          final newFormattedDate = _formatDateForDisplay(DateTime.parse(newValue));
          changeDescription = 'date has been changed from $oldFormattedDate to $newFormattedDate';
          // For date changes, use the original date in the initial reference
          referenceDate = oldFormattedDate;
          referenceTime = _formatTimeForDisplay(gameTime);
        } catch (e) {
          changeDescription = 'date has been changed from $oldValue to $newValue';
          referenceDate = formattedDate;
          referenceTime = _formatTimeForDisplay(gameTime);
        }
        break;
      case 'time':
        title = 'Game Time Changed';
        final oldFormattedTime = _formatTimeStringForDisplay(oldValue);
        final newFormattedTime = _formatTimeStringForDisplay(newValue);
        changeDescription = 'time has been changed from $oldFormattedTime to $newFormattedTime';
        referenceTime = oldFormattedTime; // Use original time in the initial reference
        referenceDate = formattedDate;
        break;
      case 'location':
        title = 'Game Location Changed';
        changeDescription = 'location has been changed from $oldValue to $newValue';
        referenceTime = _formatTimeForDisplay(gameTime);
        referenceDate = formattedDate;
        break;
      case 'home_team':
        title = 'Home Team Changed';
        changeDescription = 'home team has been changed from $oldValue to $newValue';
        referenceTime = _formatTimeForDisplay(gameTime);
        referenceDate = formattedDate;
        break;
      case 'away_team':
        title = 'Away Team Changed';
        changeDescription = 'away team has been changed from $oldValue to $newValue';
        referenceTime = _formatTimeForDisplay(gameTime);
        referenceDate = formattedDate;
        break;
      default:
        title = 'Game Information Changed';
        changeDescription = '$changeType has been changed from $oldValue to $newValue';
        referenceTime = _formatTimeForDisplay(gameTime);
        referenceDate = formattedDate;
    }
    
    message = 'Your ${sportName.toLowerCase()} game on $referenceDate at $referenceTime has been updated by the Scheduler. The $changeDescription.';
    
    // Create notifications for each confirmed official
    for (final official in confirmedOfficials) {
      await createOfficialNotification(
        officialId: official['id'] as int,
        type: 'game_change',
        title: title,
        message: message,
        relatedGameId: gameId,
      );
    }
  }

  /// Get notifications that need to be processed for game filling reminders
  Future<List<Map<String, dynamic>>> getGameFillingCandidates(int daysBefore) async {
    final database = await _db.database;
    
    // This would need to be implemented based on your game/schedule table structure
    // For now, returning empty list as placeholder
    final result = await database.rawQuery('''
      SELECT DISTINCT 
        s.assigner_id as scheduler_id,
        g.sport,
        g.officials_needed,
        g.date,
        g.time,
        g.home_team,
        g.away_team
      FROM games g
      JOIN schedules s ON g.schedule_id = s.id
      WHERE DATE(g.date) = DATE('now', '+$daysBefore days')
        AND g.officials_needed > 0
        AND NOT EXISTS (
          SELECT 1 FROM notifications n 
          WHERE n.type = 'game_filling' 
            AND json_extract(n.data, '\$.game_date') = g.date
            AND n.recipient_id = s.assigner_id
        )
    ''');
    
    return result;
  }

  /// Helper method to format date for display (August 29, 2025)
  String _formatDateForDisplay(DateTime date) {
    const months = [
      '', 'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${months[date.month]} ${date.day}, ${date.year}';
  }

  /// Helper method to format time for display (7:00 PM)
  String _formatTimeForDisplay(String timeString) {
    try {
      // Handle various time formats
      if (timeString == 'TBD' || timeString.isEmpty) return 'TBD';
      
      // Parse time string (could be "19:00" or "TimeOfDay(19:00)" format)
      String cleanTime = timeString;
      if (timeString.contains('TimeOfDay')) {
        // Extract time from TimeOfDay(19:00) format
        final match = RegExp(r'TimeOfDay\((\d{1,2}):(\d{2})\)').firstMatch(timeString);
        if (match != null) {
          cleanTime = '${match.group(1)}:${match.group(2)}';
        }
      }
      
      final parts = cleanTime.split(':');
      if (parts.length != 2) return timeString;
      
      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);
      
      return _formatTime12Hour(hour, minute);
    } catch (e) {
      return timeString; // Return original if parsing fails
    }
  }

  /// Helper method to format time string for display (handles TimeOfDay format)
  String _formatTimeStringForDisplay(String timeString) {
    return _formatTimeForDisplay(timeString);
  }

  /// Helper method to convert 24-hour time to 12-hour format
  String _formatTime12Hour(int hour, int minute) {
    String period = hour >= 12 ? 'PM' : 'AM';
    int displayHour = hour;
    
    if (hour == 0) {
      displayHour = 12;
    } else if (hour > 12) {
      displayHour = hour - 12;
    }
    
    String minuteStr = minute.toString().padLeft(2, '0');
    return '$displayHour:$minuteStr $period';
  }
}

/// Top-level function to handle background messages
// Temporarily disabled for web testing
// @pragma('vm:entry-point')
// Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
//   print('Handling background message: ${message.notification?.title}');
//   // Handle background notification logic here
// }