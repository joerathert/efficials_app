import 'package:flutter/foundation.dart';
import 'firebase_database_service.dart';
import '../../utils/officials_data.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseSeederService {
  static final FirebaseSeederService _instance =
      FirebaseSeederService._internal();
  FirebaseSeederService._internal();
  factory FirebaseSeederService() => _instance;

  final FirebaseDatabaseService _firebaseDb = FirebaseDatabaseService();

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
        'setupCompleted': true,
        'password': 'test123', // In production, this would be hashed
        'createdAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
      },
      {
        'email': 'assigner@test.com',
        'firstName': 'Game',
        'lastName': 'Assigner',
        'userType': 'scheduler',
        'schedulerType': 'assigner',
        'teamName': 'Metro East Officials',
        'schoolName': 'Metro East Officials Association',
        'phone': '618-555-0100',
        'setupCompleted': true,
        'password': 'test123',
        'createdAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
      },
      {
        'email': 'coach@test.com',
        'firstName': 'Head',
        'lastName': 'Coach',
        'userType': 'scheduler',
        'schedulerType': 'coach',
        'teamName': 'Alton Redbirds',
        'schoolName': 'Alton High School',
        'schoolAddress': '4200 Humbert Rd, Alton, IL 62002',
        'phone': '618-474-2600',
        'setupCompleted': true,
        'password': 'test123',
        'createdAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
      }
    ];

    for (var userData in users) {
      final success = await _firebaseDb.saveUserProfile(
          userData['email'] as String, userData);
      if (success) {
        print('DEBUG: Created user: ${userData['email']}');
      } else {
        print('ERROR: Failed to create user: ${userData['email']}');
      }
    }
  }

  // Seed all 123 officials from your existing data
  Future<void> _seedOfficials() async {
    print('DEBUG: Seeding officials...');

    final officials = OfficialsDataProvider.getAllOfficials();
    print('DEBUG: Processing ${officials.length} officials...');

    int successCount = 0;
    int errorCount = 0;

    for (int i = 0; i < officials.length; i++) {
      final official = officials[i];

      try {
        // Parse the official data (it's in CSV format from your existing code)
        final parts = _parseOfficialData(official, i + 1);

        final officialData = {
          'id': parts['id'],
          'email': official.email,
          'firstName': parts['firstName'],
          'lastName': parts['lastName'],
          'displayName': official.displayName,
          'address': parts['address'],
          'city': parts['city'],
          'zipCode': parts['zipCode'],
          'phone': parts['phone'],
          'certificationLevel': parts['certificationLevel'],
          'experienceYears': parts['experienceYears'],
          'competitionLevels': 'Varsity', // All officials work Varsity level
          'userType': 'official',
          'password': 'test123', // All officials have same test password
          'isActive': true,
          'rating': 0.0,
          'gamesWorked': 0,
          'availability': 'available',
          'createdAt': DateTime.now().toIso8601String(),
          'updatedAt': DateTime.now().toIso8601String(),
        };

        final success =
            await _firebaseDb.saveOfficialProfile(official.email, officialData);
        if (success) {
          successCount++;
          if (i % 10 == 0) {
            print('DEBUG: Processed $i/${officials.length} officials...');
          }
        } else {
          errorCount++;
          print('ERROR: Failed to seed official: ${official.email}');
        }
      } catch (e) {
        errorCount++;
        print('ERROR: Exception processing official ${official.email}: $e');
      }
    }

    print(
        'DEBUG: Officials seeding complete - Success: $successCount, Errors: $errorCount');
  }

  // Parse the CSV-like data from your existing officials data
  Map<String, dynamic> _parseOfficialData(OfficialData official, int id) {
    // The displayName is like "J. Smith" - extract first/last names
    final nameParts = official.displayName.split(' ');
    final firstName = nameParts.length > 0 ? nameParts[0] : 'Unknown';
    final lastName =
        nameParts.length > 1 ? nameParts.sublist(1).join(' ') : 'Official';

    // Parse actual CSV data from officials_data.dart
    // Format: Certified,8,Aldridge,Brandon,2627 Columbia Lakes Drive Unit 2D,Columbia,62236,618-719-4373
    try {
      // Use the SAME CSV data as officials_data.dart to ensure consistency
      final csvData = OfficialsDataProvider.getCsvData();
      final lines = csvData.split('\n');

      // Try to find matching line by name
      for (final line in lines) {
        final parts = line.split(',');
        if (parts.length >= 8) {
          final csvLastName = parts[2].trim();
          final csvFirstName = parts[3].trim();

          // Match by both first name AND last name to avoid siblings/duplicates
          // Handle abbreviated names like "A." matching "Arthur"
          final cleanFirstName = firstName.replaceAll('.', '').toLowerCase();
          final cleanCsvFirstName = csvFirstName.toLowerCase();
          final firstNameMatch = cleanFirstName.startsWith(cleanCsvFirstName.substring(0, 1)) ||
                                  cleanCsvFirstName.startsWith(cleanFirstName.substring(0, 1));
          final lastNameMatch = lastName.toLowerCase() == csvLastName.toLowerCase();
          
          // Debug Phillips specifically
          if (lastName.toLowerCase() == 'phillips') {
            print('DEBUG: Phillips check - ${firstName} vs ${csvFirstName}');
            print('   cleanFirstName="$cleanFirstName", cleanCsvFirstName="$cleanCsvFirstName"');
            print('   firstNameMatch=$firstNameMatch, lastNameMatch=$lastNameMatch');
          }
          
          if (firstNameMatch && lastNameMatch) {
            print('DEBUG: MATCHED ${firstName} ${lastName} → ${csvFirstName} ${csvLastName} (${parts[1]} years)');
            return {
              'id': id,
              'firstName': csvFirstName,
              'lastName': csvLastName,
              'address': parts[4].trim(),
              'city': parts[5].trim(), // Real city data!
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
    print('DEBUG: NO MATCH for ${firstName} ${lastName} - using fallback (15 years)');
    return {
      'id': id,
      'firstName': firstName,
      'lastName': lastName,
      'address': '123 Main St',
      'city': 'Various', // Better than all Edwardsville
      'zipCode': '62025',
      'phone': '618-555-0000',
      'certificationLevel': 'Certified',
      'experienceYears': 15, // Set to 15 so they pass 10+ years filter
    };
  }
}