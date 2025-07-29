import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
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

  // Push Notification Methods

  /// Request push notification permission
  Future<bool> requestPushPermission() async {
    try {
      final messaging = FirebaseMessaging.instance;
      final settings = await messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );
      
      return settings.authorizationStatus == AuthorizationStatus.authorized ||
             settings.authorizationStatus == AuthorizationStatus.provisional;
    } catch (e) {
      print('Error requesting push notification permission: $e');
      return false;
    }
  }

  /// Subscribe to push notifications for a user
  Future<bool> subscribeToPush(int userId) async {
    try {
      final messaging = FirebaseMessaging.instance;
      
      // Subscribe to user-specific topics
      await messaging.subscribeToTopic('user_${userId}_notifications');
      await messaging.subscribeToTopic('user_${userId}_backouts');
      await messaging.subscribeToTopic('user_${userId}_game_filling');
      
      // Get and store FCM token for direct messaging if needed
      final token = await messaging.getToken();
      if (token != null) {
        // Store token in database or send to server
        print('FCM Token: $token');
      }
      
      return true;
    } catch (e) {
      print('Error subscribing to push notifications: $e');
      return false;
    }
  }

  /// Unsubscribe from push notifications for a user
  Future<bool> unsubscribeFromPush(int userId) async {
    try {
      final messaging = FirebaseMessaging.instance;
      
      // Unsubscribe from user-specific topics
      await messaging.unsubscribeFromTopic('user_${userId}_notifications');
      await messaging.unsubscribeFromTopic('user_${userId}_backouts');
      await messaging.unsubscribeFromTopic('user_${userId}_game_filling');
      
      return true;
    } catch (e) {
      print('Error unsubscribing from push notifications: $e');
      return false;
    }
  }

  /// Initialize push notification handlers
  Future<void> initializePushNotifications(int userId) async {
    try {
      final messaging = FirebaseMessaging.instance;
      
      // Handle foreground messages
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        print('Received foreground message: ${message.notification?.title}');
        // Handle the message and potentially create local notification
      });
      
      // Handle when app is opened from notification
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        print('App opened from notification: ${message.notification?.title}');
        // Navigate to appropriate screen based on message data
      });
      
      // Handle background messages
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
      
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
}

/// Top-level function to handle background messages
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('Handling background message: ${message.notification?.title}');
  // Handle background notification logic here
}