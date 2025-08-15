import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import '../models/database_models.dart';
import 'database_helper.dart';
import 'user_session_service.dart';

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
    // print('DEBUG: Login attempt for email: $email');
    
    if (email.trim().isEmpty || password.trim().isEmpty) {
      print('DEBUG: Empty email or password');
      return LoginResult(
        success: false,
        error: 'Please enter email and password',
      );
    }

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

