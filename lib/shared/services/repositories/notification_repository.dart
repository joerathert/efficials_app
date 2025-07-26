import 'dart:convert';
import '../database_helper.dart';
import '../../models/database_models.dart';

class NotificationRepository {
  final DatabaseHelper _db = DatabaseHelper();

  /// Get all notifications for a specific user
  Future<List<Notification>> getNotifications(int userId, {bool unreadOnly = false}) async {
    final database = await _db.database;
    
    String whereClause = 'recipient_id = ?';
    List<dynamic> whereArgs = [userId];
    
    if (unreadOnly) {
      whereClause += ' AND is_read = 0';
    }
    
    final result = await database.query(
      'notifications',
      where: whereClause,
      whereArgs: whereArgs,
      orderBy: 'created_at DESC',
    );
    
    return result.map((row) => Notification.fromMap(row)).toList();
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
  Future<int> createNotification(Notification notification) async {
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
  Future<List<Notification>> getNotificationsByType(int userId, String type) async {
    final database = await _db.database;
    
    final result = await database.query(
      'notifications',
      where: 'recipient_id = ? AND type = ?',
      whereArgs: [userId, type],
      orderBy: 'created_at DESC',
    );
    
    return result.map((row) => Notification.fromMap(row)).toList();
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
    final notification = Notification.createBackoutNotification(
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
    final notification = Notification.createGameFillingNotification(
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
    final notification = Notification.createOfficialInterestNotification(
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
    final notification = Notification.createOfficialClaimNotification(
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

  // Notification Settings Methods

  /// Get notification settings for a user
  Future<NotificationSettings?> getNotificationSettings(int userId) async {
    final database = await _db.database;
    
    final result = await database.query(
      'notification_settings',
      where: 'user_id = ?',
      whereArgs: [userId],
    );
    
    if (result.isEmpty) {
      return null;
    }
    
    return NotificationSettings.fromMap(result.first);
  }

  /// Create or update notification settings
  Future<void> saveNotificationSettings(NotificationSettings settings) async {
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
  Future<NotificationSettings> getDefaultNotificationSettings(int userId) async {
    return NotificationSettings(
      userId: userId,
      backoutNotificationsEnabled: true,
      gameFillingNotificationsEnabled: true,
      officialInterestNotificationsEnabled: true,
      officialClaimNotificationsEnabled: true,
      gameFillingReminderDays: [3, 1], // 3 days and 1 day before
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