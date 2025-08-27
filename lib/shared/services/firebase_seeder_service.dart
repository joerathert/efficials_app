import 'package:flutter/foundation.dart';
import 'firebase_database_service.dart';
import 'firebase_auth_service.dart';
import '../../utils/officials_data.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseSeederService {
  static final FirebaseSeederService _instance =
      FirebaseSeederService._internal();
  FirebaseSeederService._internal();
  factory FirebaseSeederService() => _instance;

  final FirebaseDatabaseService _firebaseDb = FirebaseDatabaseService();
  final FirebaseAuthService _firebaseAuth = FirebaseAuthService();

  // Expose the firebase database service for external access
  FirebaseDatabaseService get firebaseDb => _firebaseDb;

  // Seed all data to Firebase
  Future<bool> seedAllData({bool force = false}) async {
    try {
      print('DEBUG: Starting Firebase seeding process...');

      // 1. Seed scheduler users (AD, Assigner, Coach)
      await _seedSchedulerUsers();

      // 2. Seed officials (always try to seed officials, even if some users exist)
      await _seedOfficials();

      print('DEBUG: Firebase seeding completed successfully');
      return true;
    } catch (e) {
      print('ERROR: Firebase seeding failed: $e');
      return false;
    }
  }

  // Seed scheduler users (AD, Assigner, Coach)
  Future<void> _seedSchedulerUsers() async {
    print('DEBUG: Seeding scheduler users...');

    final users = [
      {
        'email': 'ad@test.com',
        'firstName': 'Athletic',
        'lastName': 'Director',
        'userType': 'scheduler',
        'schedulerType': 'athletic_director',
        'teamName': 'Edwardsville Tigers',
        'schoolName': 'Edwardsville High School',
        'schoolAddress': '6161 Center Grove Rd, Edwardsville, IL 62025',
        'phone': '618-656-7600',
        'password': 'test123',
        'isActive': true,
        'createdAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
      },
      {
        'email': 'assigner@test.com',
        'firstName': 'Game',
        'lastName': 'Assigner',
        'userType': 'scheduler',
        'schedulerType': 'assigner',
        'organizationName': 'Southern Illinois Officials Association',
        'organizationAddress': '123 Official St, Edwardsville, IL 62025',
        'phone': '618-656-7601',
        'password': 'test123',
        'isActive': true,
        'createdAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
      },
      {
        'email': 'coach@test.com',
        'firstName': 'Head',
        'lastName': 'Coach',
        'userType': 'scheduler',
        'schedulerType': 'coach',
        'teamName': 'Highland Bulldogs',
        'schoolName': 'Highland High School',
        'schoolAddress': '12 Bulldog Blvd, Highland, IL 62249',
        'phone': '618-656-7602',
        'password': 'test123',
        'isActive': true,
        'createdAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
      },
    ];

    for (final user in users) {
      final email = user['email'] as String;
      final password = user['password'] as String;
      
      // 1. Create Firebase Auth account
      final authResult = await _firebaseAuth.createUserWithEmailAndPassword(email, password);
      if (authResult.success) {
        print('DEBUG: ✅ Firebase Auth account created for scheduler: $email');
      } else {
        print('DEBUG: ❌ Firebase Auth failed for scheduler $email: ${authResult.error}');
      }
      
      // 2. Create Firestore profile
      await _firebaseDb.saveUserProfile(email, user);
      print('DEBUG: Created scheduler user: $email');
    }

    print('DEBUG: Scheduler users seeding completed');
  }

  // Seed all officials using real data from OfficialsDataProvider
  Future<void> _seedOfficials() async {
    print('DEBUG: Seeding officials with rate limiting and batch processing...');

    final officials = OfficialsDataProvider.getAllOfficials();
    print('DEBUG: Processing ${officials.length} officials in batches of 10...');

    int successCount = 0;
    int errorCount = 0;
    int skipCount = 0;
    const batchSize = 10;

    // Process officials in batches
    for (int batchStart = 0; batchStart < officials.length; batchStart += batchSize) {
      final batchEnd = (batchStart + batchSize).clamp(0, officials.length);
      final batch = officials.sublist(batchStart, batchEnd);
      
      print('DEBUG: Processing batch ${(batchStart / batchSize + 1).ceil()}/${(officials.length / batchSize).ceil()} (${batch.length} officials)');
      
      for (int i = 0; i < batch.length; i++) {
        final official = batch[i];
        final globalIndex = batchStart + i;

        try {
          // Parse the official data (it's in CSV format from your existing code)
          final parts = _parseOfficialData(official, globalIndex + 1);

          // Generate test email using your domain to avoid sending notifications to real users
          final testEmail = '${parts['firstName'].toLowerCase()}.${parts['lastName'].toLowerCase()}@test.efficials.com';
          
          final officialData = {
            'id': parts['id'],
            'email': testEmail, // Use test email with your domain
            'realEmail': official.email, // Store real email for reference only
            'firstName': parts['firstName'],
            'lastName': parts['lastName'],
            'displayName': official.displayName,
            'address': parts['address'],
            'city': parts['city'],
            'zipCode': parts['zipCode'],
            'phone': parts['phone'],
            'certificationLevel': parts['certificationLevel'],
            'experienceYears': parts['experienceYears'],
            'userType': 'official',
            'password': 'test123', // All officials have same test password
            'isActive': true,
            'rating': 0.0,
            'gamesWorked': 0,
            'availability': 'available',
            'createdAt': DateTime.now().toIso8601String(),
            'updatedAt': DateTime.now().toIso8601String(),
          };

          final emailToUse = testEmail;
          print('DEBUG: Creating Firebase Auth + Firestore profile with TEST email: $emailToUse (real: ${official.email})');
          
          // 1. Create Firebase Auth account with retry logic
          final authResult = await _createUserWithRetry(emailToUse, 'test123');
          bool authSuccess = authResult['success'] as bool;
          final String? authError = authResult['error'] as String?;
          
          if (authSuccess) {
            print('DEBUG: ✅ Firebase Auth account created for $emailToUse');
          } else if (authError?.contains('email-already-in-use') == true) {
            print('DEBUG: ⚠️ User already exists: $emailToUse (skipping Auth)');
            authSuccess = true; // Consider existing users as success
          } else if (authError?.contains('Too many requests') == true) {
            print('DEBUG: ⏸️ Rate limited - skipping remaining officials');
            skipCount += officials.length - globalIndex;
            return; // Exit completely if rate limited
          } else {
            print('DEBUG: ❌ Firebase Auth failed for $emailToUse: $authError');
          }
          
          // 2. Create Firestore profile (always do this)
          final profileSuccess = await _firebaseDb.saveOfficialProfile(emailToUse, officialData);
          
          final success = authSuccess && profileSuccess;
          if (success) {
            successCount++;
            if (globalIndex % 10 == 0) {
              print('DEBUG: Processed $globalIndex/${officials.length} officials...');
            }
          } else {
            errorCount++;
            print('ERROR: Failed to create official: $emailToUse');
          }

          // Rate limiting: 3 second delay between requests within batch
          if (i < batch.length - 1) {
            await Future.delayed(Duration(seconds: 3));
          }
          
        } catch (e) {
          errorCount++;
          print('ERROR: Exception processing official ${official.email}: $e');
        }
      }
      
      // Longer delay between batches (10 seconds)
      if (batchEnd < officials.length) {
        print('DEBUG: Batch complete. Waiting 10 seconds before next batch...');
        await Future.delayed(Duration(seconds: 10));
      }
    }

    print('DEBUG: Officials seeding complete - Success: $successCount, Errors: $errorCount, Skipped: $skipCount');
  }

  // Create user with retry logic and exponential backoff
  Future<Map<String, dynamic>> _createUserWithRetry(String email, String password) async {
    const maxRetries = 3;
    const baseDelaySeconds = 5;
    
    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      final result = await _firebaseAuth.createUserWithEmailAndPassword(email, password);
      
      if (result.success) {
        return {'success': true, 'error': null};
      }
      
      // If rate limited and not last attempt, wait and retry
      if (result.error?.contains('Too many requests') == true && attempt < maxRetries) {
        final delaySeconds = baseDelaySeconds * (attempt * attempt); // Exponential backoff
        print('DEBUG: Rate limited on attempt $attempt/$maxRetries for $email, waiting ${delaySeconds}s...');
        await Future.delayed(Duration(seconds: delaySeconds));
        continue;
      }
      
      // Return the error (don't retry for non-rate-limit errors)
      return {'success': false, 'error': result.error};
    }
    
    return {'success': false, 'error': 'Max retries exceeded'};
  }

  // Parse the CSV-like data from your existing officials data
  Map<String, dynamic> _parseOfficialData(OfficialData official, int id) {
    // The displayName is like "J. Smith" - extract first/last names
    final nameParts = official.displayName.split(' ');
    final firstName = nameParts.length > 0 ? nameParts[0] : 'Unknown';
    final lastName =
        nameParts.length > 1 ? nameParts.sublist(1).join(' ') : 'Official';

    // Parse actual CSV data from officials_data.dart
    // Format: Certified,8,Aldridge,Brandon,2627 Columbia Lakes Drive Unit 2D,Columbia,62236,618-719-4373,aldridge_brandon@ymail.com
    try {
      // Use the SAME CSV data as officials_data.dart to ensure consistency
      final csvData = OfficialsDataProvider.getCsvData();
      final lines = csvData.split('\n');

      // Try to find matching line by last name
      for (final line in lines) {
        if (line.trim().isEmpty) continue;
        final parts = line.split(',');
        if (parts.length >= 9) { // Now includes email as 9th field
          final csvLastName = parts[2].trim();
          final csvFirstName = parts[3].trim();

          // Match by both first name AND last name to avoid siblings/duplicates
          final cleanFirstName = firstName.replaceAll('.', '').toLowerCase();
          final cleanCsvFirstName = csvFirstName.toLowerCase();
          final firstNameMatch = cleanFirstName.startsWith(cleanCsvFirstName.substring(0, 1)) ||
                                  cleanCsvFirstName.startsWith(cleanFirstName.substring(0, 1));
          final lastNameMatch = lastName.toLowerCase() == csvLastName.toLowerCase();
          
          if (firstNameMatch && lastNameMatch) {
            print('DEBUG: MATCHED ${firstName} ${lastName} → ${csvFirstName} ${csvLastName} with email: ${parts[8].trim()}');
            return {
              'id': id,
              'firstName': csvFirstName,
              'lastName': csvLastName,
              'address': parts[4].trim(),
              'city': parts[5].trim(),
              'zipCode': parts[6].trim(),
              'phone': parts[7].trim(),
              'certificationLevel': parts[0].trim(),
              'experienceYears': int.tryParse(parts[1].trim()) ?? 5,
            };
          }
        }
      }
    } catch (e) {
      print('Error parsing CSV data for official: $e');
    }

    // Fallback to extracted names with better defaults
    print('DEBUG: NO MATCH for ${firstName} ${lastName} - using fallback');
    return {
      'id': id,
      'firstName': firstName,
      'lastName': lastName,
      'address': '123 Main St',
      'city': 'Edwardsville',
      'zipCode': '62025',
      'phone': '618-555-0000',
      'certificationLevel': 'Certified',
      'experienceYears': 5,
    };
  }

  // Check if data has already been seeded
  Future<bool> isDataSeeded() async {
    try {
      // Check if any users exist
      final user = await _firebaseDb.getUserProfile('ad@test.com');
      return user != null;
    } catch (e) {
      return false;
    }
  }

  // Clear all officials from Firebase (Firestore + Auth)
  Future<bool> clearOfficials() async {
    try {
      print('DEBUG: Clearing all officials from Firebase (Firestore + Auth)...');
      final firestore = FirebaseFirestore.instance;
      
      // Get all officials
      final querySnapshot = await firestore.collection('officials').get();
      final docs = querySnapshot.docs;
      
      if (docs.isEmpty) {
        print('DEBUG: No officials found to delete');
        return true;
      }
      
      print('DEBUG: Found ${docs.length} officials to delete');
      
      // Delete in batches (Firestore limit is 500 per batch)
      WriteBatch batch = firestore.batch();
      int count = 0;
      
      for (final doc in docs) {
        batch.delete(doc.reference);
        count++;
        
        // Commit batch every 500 operations (Firestore limit)
        if (count % 500 == 0) {
          await batch.commit();
          print('DEBUG: Deleted $count officials so far...');
        }
      }

      // Commit remaining operations
      if (count % 500 != 0) {
        await batch.commit();
      }

      print('DEBUG: Successfully deleted $count officials from Firestore');
      
      // Note: Firebase Auth users can only be deleted individually and require admin SDK
      // For now, we'll just warn about this
      print('WARNING: Firebase Auth users with real emails still exist.');
      print('WARNING: These should be manually deleted from Firebase Console to prevent notifications.');
      
      return true;
    } catch (e) {
      print('ERROR: Failed to clear officials: $e');
      return false;
    }
  }

  // Clear ALL Firebase Auth users (WARNING: Use with caution!)
  Future<bool> clearAllAuthUsers() async {
    print('WARNING: Cannot delete Firebase Auth users programmatically without Admin SDK');
    print('WARNING: Please manually delete users from Firebase Console > Authentication');
    print('WARNING: Or use Firebase CLI: firebase auth:delete [email]');
    return false;
  }
}