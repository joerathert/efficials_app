import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/database_models.dart' as models;
import 'auth_service.dart';
import 'firebase_database_service.dart';

class FirebaseAuthService {
  static final FirebaseAuthService _instance = FirebaseAuthService._internal();
  FirebaseAuthService._internal();
  factory FirebaseAuthService() => _instance;

  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get current Firebase user
  User? get currentUser => _auth.currentUser;

  // Listen to auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Sign in with email and password
  Future<LoginResult> signInWithEmailAndPassword(String email, String password) async {
    try {
      // For web testing, always use hardcoded test users
      if (kIsWeb) {
        return _handleTestUser(email, password);
      }

      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      if (credential.user != null) {
        // Query Firebase database to get actual user type
        final FirebaseDatabaseService firebaseDb = FirebaseDatabaseService();
        final userData = await firebaseDb.authenticateUser(email, password);
        
        if (userData != null) {
          return LoginResult(
            success: true,
            userType: userData['userType'] as String,
            schedulerType: userData['schedulerType'] as String?,
          );
        }
        
        // Fallback - shouldn't happen since user authenticated successfully
        return LoginResult(
          success: false,
          error: 'User authenticated but profile not found',
        );
      }
      
      return LoginResult(
        success: false,
        error: 'Sign in failed',
      );
    } on FirebaseAuthException catch (e) {
      return LoginResult(
        success: false,
        error: _getErrorMessage(e.code),
      );
    } catch (e) {
      return LoginResult(
        success: false,
        error: 'An unexpected error occurred: $e',
      );
    }
  }

  // Handle authentication by querying Firebase collections
  Future<LoginResult> _handleTestUser(String email, String password) async {
    try {
      // Import Firebase database service to query real collections
      final FirebaseDatabaseService firebaseDb = FirebaseDatabaseService();
      
      // Try to authenticate against real Firebase data
      final userData = await firebaseDb.authenticateUser(email, password);
      
      if (userData != null) {
        // User found in Firebase collections
        return LoginResult(
          success: true,
          userType: userData['userType'] as String,
          schedulerType: userData['schedulerType'] as String?,
        );
      }
      
      // Fallback to hardcoded credentials for backwards compatibility
      final testUsers = {
        'ad_test': {
          'password': '123',
          'userType': 'scheduler',
          'schedulerType': 'athletic_director',
        },
        'assigner_test': {
          'password': '123',
          'userType': 'scheduler',
          'schedulerType': 'assigner',
        },
      };

      final testUser = testUsers[email];
      if (testUser != null && testUser['password'] == password) {
        return LoginResult(
          success: true,
          userType: testUser['userType'] as String,
          schedulerType: testUser['schedulerType'] as String,
        );
      }

      return LoginResult(
        success: false,
        error: 'Invalid credentials',
      );
    } catch (e) {
      print('ERROR: Authentication failed: $e');
      return LoginResult(
        success: false,
        error: 'Authentication error: $e',
      );
    }
  }

  // Sign up with email and password
  Future<LoginResult> createUserWithEmailAndPassword(String email, String password) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      if (credential.user != null) {
        return LoginResult(
          success: true,
          userType: 'scheduler',
          schedulerType: 'athletic_director',
        );
      }
      
      return LoginResult(
        success: false,
        error: 'Account creation failed',
      );
    } on FirebaseAuthException catch (e) {
      return LoginResult(
        success: false,
        error: _getErrorMessage(e.code),
      );
    } catch (e) {
      return LoginResult(
        success: false,
        error: 'An unexpected error occurred: $e',
      );
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Delete current user (admin only - for testing)
  Future<bool> deleteCurrentUser() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        await user.delete();
        print('DEBUG: Deleted Firebase Auth user: ${user.email}');
        return true;
      }
      return false;
    } catch (e) {
      print('ERROR: Failed to delete user: $e');
      return false;
    }
  }

  // Convert Firebase auth error codes to user-friendly messages
  String _getErrorMessage(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No user found for that email.';
      case 'wrong-password':
        return 'Wrong password provided.';
      case 'email-already-in-use':
        return 'An account already exists for that email.';
      case 'weak-password':
        return 'The password provided is too weak.';
      case 'invalid-email':
        return 'The email address is not valid.';
      case 'user-disabled':
        return 'This user account has been disabled.';
      case 'too-many-requests':
        return 'Too many requests. Try again later.';
      case 'operation-not-allowed':
        return 'Signing in with Email and Password is not enabled.';
      default:
        return 'An error occurred. Please try again.';
    }
  }
}