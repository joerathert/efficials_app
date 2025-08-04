import '../models/database_models.dart';
import 'repositories/user_repository.dart';
import 'database_helper.dart';

/// Service to manage user session and authentication state
class UserSessionService {
  static const String _sessionTableName = 'user_sessions';
  
  static UserSessionService? _instance;
  static UserSessionService get instance => _instance ??= UserSessionService._();
  UserSessionService._();

  /// Set the current user session after successful login
  Future<void> setCurrentUser({
    required int userId, 
    required String userType, 
    required String email
  }) async {
    final db = await DatabaseHelper().database;
    
    // Clear any existing session
    await db.delete(_sessionTableName);
    
    // Insert new session
    await db.insert(_sessionTableName, {
      'user_id': userId,
      'user_type': userType,
      'email': email,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  /// Get the current user ID (null if not logged in)
  Future<int?> getCurrentUserId() async {
    final session = await _getCurrentSession();
    return session?['user_id'] as int?;
  }

  /// Get the current user type ('scheduler' or 'official')
  Future<String?> getCurrentUserType() async {
    final session = await _getCurrentSession();
    return session?['user_type'] as String?;
  }

  /// Get the current user email
  Future<String?> getCurrentUserEmail() async {
    final session = await _getCurrentSession();
    return session?['email'] as String?;
  }

  /// Check if a user is currently logged in
  Future<bool> isLoggedIn() async {
    final userId = await getCurrentUserId();
    return userId != null;
  }

  /// Get the full current user object (scheduler)
  Future<User?> getCurrentSchedulerUser() async {
    final userId = await getCurrentUserId();
    final userType = await getCurrentUserType();
    
    if (userId == null || userType != 'scheduler') return null;
    
    final userRepo = UserRepository();
    return await userRepo.getUserById(userId);
  }

  /// Get the current official user object
  Future<OfficialUser?> getCurrentOfficialUser() async {
    final userId = await getCurrentUserId();
    final userType = await getCurrentUserType();
    
    if (userId == null || userType != 'official') return null;
    
    final db = await DatabaseHelper().database;
    final results = await db.query(
      'official_users',
      where: 'id = ?',
      whereArgs: [userId],
    );
    
    if (results.isEmpty) return null;
    return OfficialUser.fromMap(results.first);
  }

  /// Clear the current user session (logout)
  Future<void> clearSession() async {
    final db = await DatabaseHelper().database;
    await db.delete(_sessionTableName);
  }
  
  /// Get the current session data from database
  Future<Map<String, dynamic>?> _getCurrentSession() async {
    try {
      final db = await DatabaseHelper().database;
      final results = await db.query(
        _sessionTableName,
        limit: 1,
        orderBy: 'created_at DESC',
      );
      
      return results.isNotEmpty ? results.first : null;
    } catch (e) {
      // Table might not exist yet, return null
      return null;
    }
  }

  /// Get current user info for display
  Future<Map<String, dynamic>?> getCurrentUserInfo() async {
    final userId = await getCurrentUserId();
    final userType = await getCurrentUserType();
    final email = await getCurrentUserEmail();
    
    if (userId == null || userType == null) return null;
    
    if (userType == 'scheduler') {
      final user = await getCurrentSchedulerUser();
      return {
        'id': userId,
        'type': userType,
        'email': email,
        'name': user != null ? '${user.firstName} ${user.lastName}' : 'Unknown',
        'schedulerType': user?.schedulerType,
        'sport': user?.sport,
      };
    } else {
      final user = await getCurrentOfficialUser();
      return {
        'id': userId,
        'type': userType,
        'email': email,
        'name': user != null ? '${user.firstName} ${user.lastName}' : 'Unknown',
      };
    }
  }
}