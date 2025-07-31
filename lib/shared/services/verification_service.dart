import 'dart:math';
import 'repositories/official_repository.dart';
import 'repositories/user_repository.dart';

class VerificationService {
  static const String _verificationTableName = 'verification_tokens';
  
  final OfficialRepository _officialRepo = OfficialRepository();
  final UserRepository _userRepo = UserRepository();
  
  // Generate a random verification code
  String _generateVerificationCode({int length = 6}) {
    const chars = '0123456789';
    final random = Random();
    return String.fromCharCodes(
      Iterable.generate(length, (_) => chars.codeUnitAt(random.nextInt(chars.length)))
    );
  }
  
  // Generate a random verification token
  String _generateVerificationToken({int length = 32}) {
    const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    return String.fromCharCodes(
      Iterable.generate(length, (_) => chars.codeUnitAt(random.nextInt(chars.length)))
    );
  }
  
  /// Request email verification
  /// Returns the verification token that should be sent in the email
  Future<String> requestEmailVerification(int officialUserId, String email) async {
    try {
      final token = _generateVerificationToken();
      final expiresAt = DateTime.now().add(const Duration(hours: 24));
      
      // Store verification token in database
      await _storeVerificationToken(
        officialUserId: officialUserId,
        type: 'email',
        token: token,
        expiresAt: expiresAt,
      );
      
      // TODO: Send email with verification link
      print('Email verification requested for user $officialUserId');
      print('Verification link: https://yourapp.com/verify-email?token=$token');
      
      return token;
    } catch (e) {
      print('Error requesting email verification: $e');
      rethrow;
    }
  }
  
  /// Verify email with token
  Future<bool> verifyEmail(String token) async {
    try {
      final tokenData = await _getVerificationToken(token, 'email');
      
      if (tokenData == null) {
        print('Invalid or expired email verification token');
        return false;
      }
      
      // Mark email as verified
      await _officialRepo.updateVerificationStatus(
        tokenData['official_user_id'],
        emailVerified: true,
      );
      
      // Delete the used token
      await _deleteVerificationToken(token);
      
      print('Email verified successfully for user ${tokenData['official_user_id']}');
      return true;
    } catch (e) {
      print('Error verifying email: $e');
      return false;
    }
  }
  
  /// Request phone verification
  /// Returns the verification code that should be sent via SMS
  Future<String> requestPhoneVerification(int officialUserId, String phone) async {
    try {
      final code = _generateVerificationCode();
      final expiresAt = DateTime.now().add(const Duration(minutes: 10));
      
      // Store verification code in database
      await _storeVerificationToken(
        officialUserId: officialUserId,
        type: 'phone',
        token: code,
        expiresAt: expiresAt,
      );
      
      // TODO: Send SMS with verification code
      print('Phone verification requested for user $officialUserId');
      print('SMS verification code: $code');
      
      return code;
    } catch (e) {
      print('Error requesting phone verification: $e');
      rethrow;
    }
  }
  
  /// Verify phone with code
  Future<bool> verifyPhone(int officialUserId, String code) async {
    try {
      final tokenData = await _getVerificationTokenByUser(officialUserId, 'phone');
      
      if (tokenData == null || tokenData['token'] != code) {
        print('Invalid or expired phone verification code');
        return false;
      }
      
      // Mark phone as verified
      await _officialRepo.updateVerificationStatus(
        officialUserId,
        phoneVerified: true,
      );
      
      // Delete the used token
      await _deleteVerificationToken(code);
      
      print('Phone verified successfully for user $officialUserId');
      return true;
    } catch (e) {
      print('Error verifying phone: $e');
      return false;
    }
  }
  
  /// Mark profile as verified (admin only)
  Future<void> verifyProfile(int officialUserId, bool verified) async {
    try {
      await _officialRepo.updateVerificationStatus(
        officialUserId,
        profileVerified: verified,
      );
      
      print('Profile verification status updated for user $officialUserId: $verified');
    } catch (e) {
      print('Error updating profile verification: $e');
      rethrow;
    }
  }
  
  /// Store verification token in database
  Future<void> _storeVerificationToken({
    required int officialUserId,
    required String type,
    required String token,
    required DateTime expiresAt,
  }) async {
    // First, delete any existing tokens for this user and type
    await _deleteVerificationTokensByUser(officialUserId, type);
    
    // Insert new token
    final db = await _userRepo.database;
    await db.insert(_verificationTableName, {
      'official_user_id': officialUserId,
      'type': type,
      'token': token,
      'expires_at': expiresAt.toIso8601String(),
      'created_at': DateTime.now().toIso8601String(),
    });
  }
  
  /// Get verification token data
  Future<Map<String, dynamic>?> _getVerificationToken(String token, String type) async {
    final db = await _userRepo.database;
    final results = await db.query(
      _verificationTableName,
      where: 'token = ? AND type = ? AND expires_at > ?',
      whereArgs: [token, type, DateTime.now().toIso8601String()],
    );
    
    return results.isEmpty ? null : results.first;
  }
  
  /// Get verification token by user ID and type
  Future<Map<String, dynamic>?> _getVerificationTokenByUser(int officialUserId, String type) async {
    final db = await _userRepo.database;
    final results = await db.query(
      _verificationTableName,
      where: 'official_user_id = ? AND type = ? AND expires_at > ?',
      whereArgs: [officialUserId, type, DateTime.now().toIso8601String()],
    );
    
    return results.isEmpty ? null : results.first;
  }
  
  /// Delete verification token
  Future<void> _deleteVerificationToken(String token) async {
    final db = await _userRepo.database;
    await db.delete(
      _verificationTableName,
      where: 'token = ?',
      whereArgs: [token],
    );
  }
  
  /// Delete verification tokens by user and type
  Future<void> _deleteVerificationTokensByUser(int officialUserId, String type) async {
    final db = await _userRepo.database;
    await db.delete(
      _verificationTableName,
      where: 'official_user_id = ? AND type = ?',
      whereArgs: [officialUserId, type],
    );
  }
  
  /// Clean up expired tokens (should be called periodically)
  Future<void> cleanupExpiredTokens() async {
    final db = await _userRepo.database;
    await db.delete(
      _verificationTableName,
      where: 'expires_at <= ?',
      whereArgs: [DateTime.now().toIso8601String()],
    );
  }
}