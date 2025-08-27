import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/database_models.dart';
import 'database_helper.dart';
import 'user_session_service.dart';
import 'firebase_auth_service.dart';

class AuthService {
  static const int _saltLength = 32;
  static const int _keyLength = 32;
  static const int _iterations = 100000;

  static String _generateSalt() {
    final random = Random.secure();
    final saltBytes = Uint8List(_saltLength);
    for (int i = 0; i < _saltLength; i++) {
      saltBytes[i] = random.nextInt(256);
    }
    return base64Encode(saltBytes);
  }

  static String _hashPasswordWithSalt(String password, String salt) {
    final saltBytes = base64Decode(salt);
    final passwordBytes = utf8.encode(password);
    
    // Use PBKDF2 with HMAC-SHA256
    final derivedKey = _pbkdf2(passwordBytes, saltBytes, _iterations, _keyLength);
    return base64Encode(derivedKey);
  }

  static Uint8List _pbkdf2(List<int> password, List<int> salt, int iterations, int keyLength) {
    final hmac = Hmac(sha256, password);
    final result = Uint8List(keyLength);
    var resultOffset = 0;
    
    for (var blockIndex = 1; resultOffset < keyLength; blockIndex++) {
      final block = _pbkdf2Block(hmac, salt, iterations, blockIndex);
      final remaining = keyLength - resultOffset;
      final copyLength = remaining < block.length ? remaining : block.length;
      result.setRange(resultOffset, resultOffset + copyLength, block);
      resultOffset += copyLength;
    }
    
    return result;
  }

  static Uint8List _pbkdf2Block(Hmac hmac, List<int> salt, int iterations, int blockIndex) {
    final saltWithIndex = Uint8List(salt.length + 4);
    saltWithIndex.setRange(0, salt.length, salt);
    saltWithIndex[salt.length] = (blockIndex >> 24) & 0xff;
    saltWithIndex[salt.length + 1] = (blockIndex >> 16) & 0xff;
    saltWithIndex[salt.length + 2] = (blockIndex >> 8) & 0xff;
    saltWithIndex[salt.length + 3] = blockIndex & 0xff;
    
    var u = Uint8List.fromList(hmac.convert(saltWithIndex).bytes);
    final result = Uint8List.fromList(u);
    
    for (var i = 1; i < iterations; i++) {
      u = Uint8List.fromList(hmac.convert(u).bytes);
      for (var j = 0; j < result.length; j++) {
        result[j] ^= u[j];
      }
    }
    
    return result;
  }

  static String hashPassword(String password) {
    final salt = _generateSalt();
    final hash = _hashPasswordWithSalt(password, salt);
    return '$salt:$hash';
  }

  static bool verifyPassword(String password, String storedHash) {
    try {
      final parts = storedHash.split(':');
      if (parts.length != 2) return false;
      
      final salt = parts[0];
      final hash = parts[1];
      final computedHash = _hashPasswordWithSalt(password, salt);
      
      return hash == computedHash;
    } catch (e) {
      return false;
    }
  }

  static Future<LoginResult> login(String email, String password) async {
    print('DEBUG: Login attempt for email: $email on platform: ${kIsWeb ? "WEB" : "MOBILE"}');
    
    if (email.trim().isEmpty || password.trim().isEmpty) {
      print('DEBUG: Empty email or password');
      return LoginResult(
        success: false,
        error: 'Please enter email and password',
      );
    }

    // Use Firebase for web platform
    if (kIsWeb) {
      print('DEBUG: Attempting Firebase login for: $email');
      try {
        final firebaseAuth = FirebaseAuthService();
        final authResult = await firebaseAuth.signInWithEmailAndPassword(email, password);
        
        if (authResult.success) {
          // Set user session for Firebase auth
          print('DEBUG: Setting user session - userType: ${authResult.userType}, schedulerType: ${authResult.schedulerType}');
          await UserSessionService.instance.setCurrentUser(
            userId: 1, // Use a test user ID for Firebase web testing
            userType: authResult.userType ?? 'scheduler',
            email: email,
          );
          print('DEBUG: User session set successfully');
          
          return LoginResult(
            success: true,
            userType: authResult.userType,
            schedulerType: authResult.schedulerType,
          );
        } else {
          return LoginResult(
            success: false,
            error: authResult.error ?? 'Login failed',
          );
        }
      } catch (e) {
        print('DEBUG: Firebase login failed: $e');
        return LoginResult(
          success: false,
          error: 'Login error: $e',
        );
      }
    }

    // Mobile login: Firebase first, SQLite fallback
    if (!kIsWeb) {
      // TEMPORARY: Skip Firebase Auth during rate limiting - check Firestore directly
      if (email == 'ad@test.com' && password == 'test123') {
        print('DEBUG: TEMP BYPASS: Using direct AD login during rate limiting');
        await UserSessionService.instance.setCurrentUser(
          userId: 1,
          userType: 'scheduler',
          email: email,
        );
        
        return LoginResult(
          success: true,
          userType: 'scheduler',
          schedulerType: 'athletic_director',
        );
      }
      
      // Try Firebase first for mobile too (Firebase-first architecture)
      print('DEBUG: Attempting Firebase login for mobile: $email');
      try {
        final firebaseAuth = FirebaseAuthService();
        final authResult = await firebaseAuth.signInWithEmailAndPassword(email, password);
        
        if (authResult.success) {
          print('DEBUG: Firebase mobile login successful');
          await UserSessionService.instance.setCurrentUser(
            userId: 1,
            userType: authResult.userType ?? 'scheduler',
            email: email,
          );
          
          return LoginResult(
            success: true,
            userType: authResult.userType,
            schedulerType: authResult.schedulerType,
          );
        } else {
          print('DEBUG: Firebase mobile login failed: ${authResult.error}');
        }
      } catch (e) {
        print('DEBUG: Firebase mobile login exception: $e');
      }
      
      // Fallback to SQLite for offline support
      print('DEBUG: Falling back to SQLite login for mobile');
      
      try {
        final db = await DatabaseHelper().database;
      // print('DEBUG: Database connection established');
      
      // Check scheduler users first
      final schedulerResults = await db.query(
        'users',
        where: 'email = ?',
        whereArgs: [email.trim()],
      );
      // print('DEBUG: Found ${schedulerResults.length} scheduler users with email $email');
      
      if (schedulerResults.isNotEmpty) {
        final user = User.fromMap(schedulerResults.first);
        // print('DEBUG: Found scheduler user: ${user.firstName} ${user.lastName}');
        if (user.passwordHash != null && verifyPassword(password, user.passwordHash!)) {
          // print('DEBUG: Scheduler password verified successfully');
          await UserSessionService.instance.setCurrentUser(
            userId: user.id!,
            userType: 'scheduler',
            email: user.email!,
          );
          
          return LoginResult(
            success: true,
            userType: 'scheduler',
            schedulerType: user.schedulerType,
          );
        } else {
          print('DEBUG: Scheduler password verification failed');
        }
      }
      
      // Check official users
      final officialResults = await db.query(
        'official_users',
        where: 'email = ?',
        whereArgs: [email.trim()],
      );
      print('DEBUG: Found ${officialResults.length} official users with email $email');
      
      if (officialResults.isNotEmpty) {
        final officialUser = OfficialUser.fromMap(officialResults.first);
        print('DEBUG: Found official user with email: ${officialUser.email}');
        print('DEBUG: Official has password hash: ${officialUser.passwordHash != null}');
        
        if (verifyPassword(password, officialUser.passwordHash)) {
          print('DEBUG: Official password verified successfully');
          await UserSessionService.instance.setCurrentUser(
            userId: officialUser.id!,
            userType: 'official',
            email: officialUser.email,
          );
          
          return LoginResult(
            success: true,
            userType: 'official',
          );
        } else {
          print('DEBUG: Official password verification failed');
          print('DEBUG: Provided password: $password');
          print('DEBUG: Stored hash: ${officialUser.passwordHash}');
        }
      }
      
      // Debug: Let's see what emails actually exist in the database
      final allOfficials = await db.query('official_users');
      print('DEBUG: All official emails in database (${allOfficials.length} total):');
      for (var official in allOfficials.take(10)) {
        print('  - ${official['email']}');
      }
      if (allOfficials.length > 10) {
        print('  ... and ${allOfficials.length - 10} more');
      }
      
      print('DEBUG: Login failed - no matching user found');
      return LoginResult(
        success: false,
        error: 'Invalid email or password',
      );
      
      } catch (e) {
        print('DEBUG: Login exception: $e');
        return LoginResult(
          success: false,
          error: 'Login error: $e',
        );
      }
    }

    // Fallback for platforms that don't support database or web
    return LoginResult(
      success: false,
      error: 'Login not supported on this platform',
    );
  }

  // Web-specific login method for test users
  static Future<LoginResult> _loginWebTestUser(String email, String password) async {
    print('DEBUG: _loginWebTestUser called with email: $email, password: $password');
    final prefs = await SharedPreferences.getInstance();
    
    // Check if web test data exists
    final testUsersJson = prefs.getString('web_test_users');
    final testOfficialsJson = prefs.getString('web_test_officials');
    
    print('DEBUG: testUsersJson found: ${testUsersJson != null}');
    print('DEBUG: testOfficialsJson found: ${testOfficialsJson != null}');
    
    if (testUsersJson == null && testOfficialsJson == null) {
      print('DEBUG: No web test users found in SharedPreferences');
      return LoginResult(success: false, error: 'No web test users found');
    }
    
    // Check test users (AD, Assigner, Coach)
    if (testUsersJson != null) {
      final testUsers = jsonDecode(testUsersJson) as Map<String, dynamic>;
      
      for (final userEntry in testUsers.values) {
        final user = userEntry as Map<String, dynamic>;
        
        // Check by email or username
        if ((user['email'] == email || user['username'] == email) && 
            user['password'] == password) {
          
          // Set user session
          await UserSessionService.instance.setCurrentUser(
            userId: user['id'] as int,
            userType: 'scheduler',
            email: user['email'] as String,
          );
          
          // Store additional user data in SharedPreferences for web
          await prefs.setString('current_web_user', jsonEncode(user));
          
          return LoginResult(
            success: true,
            userType: 'scheduler',
            schedulerType: user['role'] as String,
          );
        }
      }
    }
    
    // Check test officials
    if (testOfficialsJson != null) {
      final testOfficials = jsonDecode(testOfficialsJson) as List<dynamic>;
      
      for (final officialData in testOfficials) {
        final official = officialData as Map<String, dynamic>;
        
        if ((official['email'] == email || official['username'] == email) && 
            official['password'] == password) {
          
          // Set user session
          await UserSessionService.instance.setCurrentUser(
            userId: official['id'] as int,
            userType: 'official',
            email: official['email'] as String,
          );
          
          // Store additional user data in SharedPreferences for web
          await prefs.setString('current_web_user', jsonEncode(official));
          
          return LoginResult(
            success: true,
            userType: 'official',
          );
        }
      }
    }
    
    return LoginResult(success: false, error: 'Invalid credentials');
  }
}

class LoginResult {
  final bool success;
  final String? error;
  final String? userType;
  final String? schedulerType;

  LoginResult({
    required this.success,
    this.error,
    this.userType,
    this.schedulerType,
  });
}

