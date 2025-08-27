import 'base_repository.dart';
import '../../models/database_models.dart';
import '../firebase_database_service.dart';
import '../unified_data_service.dart';
import 'package:flutter/foundation.dart';

class OfficialRepository extends BaseRepository {
  final UnifiedDataService _dataService = UnifiedDataService();

  /// Initialize the repository - call this once at app startup
  Future<void> initialize() async {
    await _dataService.initialize();
  }

  // Get official by user ID (for officials who have app accounts)
  Future<Official?> getOfficialByUserId(int userId) async {
    final results = await query(
      'officials',
      where: 'user_id = ? AND is_user_account = ?',
      whereArgs: [userId, true],
    );

    if (results.isEmpty) return null;
    return Official.fromMap(results.first);
  }

  // Get official by official_user_id (for app account officials)
  Future<Official?> getOfficialByOfficialUserId(int officialUserId) async {
    final results = await query(
      'officials',
      where: 'official_user_id = ?',
      whereArgs: [officialUserId],
    );

    if (results.isEmpty) return null;
    return Official.fromMap(results.first);
  }

  // Get official by email
  Future<Official?> getOfficialByEmail(String email) async {
    print('DEBUG: OfficialRepository.getOfficialByEmail($email)');

    // Use unified data service for Firebase-first approach
    final officials = await _dataService.getAllOfficials();
    print(
        'DEBUG: Found ${officials.length} total officials in unified data service');

    // Find official by email
    final matchingOfficials = officials.where((official) {
      final officialEmail = official['email'] as String?;
      final match = officialEmail?.toLowerCase() == email.toLowerCase();
      if (match) {
        print('DEBUG: Found matching official: $officialEmail');
      }
      return match;
    }).toList();

    print(
        'DEBUG: Found ${matchingOfficials.length} officials with email $email');

    if (matchingOfficials.isEmpty) return null;

    final officialData = matchingOfficials.first;

    // DEBUG: Let's see what fields are actually available
    print('DEBUG: Available fields in officialData:');
    officialData.forEach((key, value) {
      print('  $key: $value (${value.runtimeType})');
    });

    // Try multiple name sources in order
    String officialName = 'Official'; // fallback

    // First try the 'name' field (which unified service should provide)
    if (officialData['name'] != null &&
        (officialData['name'] as String).trim().isNotEmpty) {
      officialName = (officialData['name'] as String).trim();
      print('DEBUG: Using name field: "$officialName"');
    }
    // Then try firstName + lastName
    else if (officialData['firstName'] != null ||
        officialData['lastName'] != null) {
      final firstName = (officialData['firstName'] as String? ?? '').trim();
      final lastName = (officialData['lastName'] as String? ?? '').trim();
      officialName = '$firstName $lastName'.trim();
      print(
          'DEBUG: Using firstName + lastName: "$firstName" + "$lastName" = "$officialName"');
    }
    // Fallback to other fields if available
    else {
      print('DEBUG: No name, firstName, or lastName found. Using fallback.');
    }

    print('DEBUG: Final official name: "$officialName"');

    // Convert Firebase format to Official model format with proper type handling
    final convertedData = {
      'id': officialData['id'] is String
          ? email.hashCode.abs()
          : officialData['id'],
      'name': officialName.isNotEmpty ? officialName : 'Official',
      'email': officialData['email'],
      'phone': officialData['phone']?.toString(),
      'certification_level': officialData['certificationLevel']?.toString(),
      'experience_years': _safeToInt(officialData['experienceYears']),
      'city': officialData['city']?.toString(),
      'state': 'IL', // Default for our area
      'rating': (officialData['rating'] ?? 0.0).toString(),
      'games_worked': _safeToInt(officialData['gamesWorked']),
      'availability': officialData['availability']?.toString() ?? 'available',
      'is_active': officialData['isActive'] ?? true,
    };

    print('DEBUG: Converted official data: ${convertedData['name']}');
    return Official.fromMap(convertedData);
  }

  /// Helper method to safely convert values to int
  int _safeToInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    if (value is double) return value.toInt();
    return 0;
  }

  // Get all officials
  Future<List<Official>> getAllOfficials() async {
    final results = await query('officials');
    return results.map((data) => Official.fromMap(data)).toList();
  }

  // Get all officials with formatted location data (for crew selection)
  Future<List<Map<String, dynamic>>> getAllOfficialsWithLocation() async {
    final results = await rawQuery('''
      SELECT DISTINCT
        o.id,
        o.name,
        o.email,
        o.phone,
        o.city,
        o.state
      FROM officials o
      ORDER BY o.name
    ''');

    return results.map((row) {
      // Format city and state
      String cityState = '';
      final city = row['city'] as String?;
      final state = row['state'] as String?;

      if (city != null && city.isNotEmpty && city != 'null') {
        cityState = city;
        if (state != null && state.isNotEmpty && state != 'null') {
          cityState += ', $state';
        }
      } else {
        cityState = 'Location not available';
      }

      return {
        'id': row['id'],
        'name': row['name'],
        'email': row['email'],
        'phone': row['phone'],
        'cityState': cityState,
      };
    }).toList();
  }

  // Get officials by sport with comprehensive filtering support
  // Now uses the unified data service for consistent cross-platform behavior
  Future<List<Map<String, dynamic>>> getOfficialsBySport(int sportId,
      {Map<String, dynamic>? filters}) async {
    debugPrint(
        '🔍 OfficialRepository.getOfficialsBySport() - sportId: $sportId, filters: $filters');

    // Use unified data service - it handles platform detection automatically
    try {
      final officials =
          await _dataService.getOfficialsBySport('Football', filters: filters);
      debugPrint('✅ UnifiedDataService returned ${officials.length} officials');

      // Transform data to match the expected format for UI
      return officials.map((official) => _transformForUI(official)).toList();
    } catch (e) {
      debugPrint('❌ UnifiedDataService error: $e');
      return [];
    }
  }

  /// Transform standardized official data to the format expected by the UI
  Map<String, dynamic> _transformForUI(Map<String, dynamic> official) {
    // Extract certification level and format for UI
    final certLevel =
        official['certification_level'] as String? ?? 'Registered';
    final competitionLevels =
        (official['competition_levels'] as String? ?? 'Varsity').split(',');

    // Format city and state
    String cityState = '';
    final city = official['city'] as String?;
    final state = official['state'] as String?;

    if (city != null && city.isNotEmpty && city != 'null') {
      cityState = city;
      if (state != null && state.isNotEmpty && state != 'null') {
        cityState += ', $state';
      }
    } else {
      cityState = 'Location not available';
    }

    // Generate a consistent integer ID from the string ID (email)
    final stringId = official['id'].toString();
    final intId =
        stringId.hashCode.abs(); // Convert string ID to positive integer

    return {
      'id': intId,
      'name': official['name'],
      'email': official['id'], // Keep the original email/string ID for Firebase operations
      'cityState': cityState,
      'distance': 10.0 + (intId % 30) * 2.5, // Temp distance calculation
      'yearsExperience': official['years_experience'] ?? 0,
      // IHSA certification flags - hierarchical
      'ihsaRegistered':
          ['Registered', 'Recognized', 'Certified'].contains(certLevel),
      'ihsaRecognized': ['Recognized', 'Certified'].contains(certLevel),
      'ihsaCertified': certLevel == 'Certified',
      'level':
          competitionLevels.isNotEmpty ? competitionLevels.first : 'Varsity',
      'competitionLevels': competitionLevels,
      'sports': ['Football'], // All officials are football officials
    };
  }

  // Legacy method maintained for compatibility
  Future<List<Official>> getOfficialsBySportLegacy(int sportId,
      {double? minRating, double? minFollowThroughRate}) async {
    String whereClause = 'sport_id = ?';
    List<dynamic> whereArgs = [sportId];

    if (minRating != null) {
      whereClause += ' AND rating >= ?';
      whereArgs.add(minRating.toString());
    }

    if (minFollowThroughRate != null) {
      whereClause += ' AND follow_through_rate >= ?';
      whereArgs.add(minFollowThroughRate);
    }

    final results = await query(
      'official_sports',
      where: whereClause,
      whereArgs: whereArgs,
    );

    List<Official> officials = [];
    for (var result in results) {
      int officialId = result['official_id'];
      final officialResults = await query(
        'officials',
        where: 'id = ?',
        whereArgs: [officialId],
      );
      if (officialResults.isNotEmpty) {
        officials.add(Official.fromMap(officialResults.first));
      }
    }

    return officials;
  }

  // Create a new official
  Future<int> createOfficial(Official official) async {
    final id = await insert('officials', official.toMap());
    return id;
  }

  // Update an official
  Future<int> updateOfficial(Official official) async {
    return await update(
      'officials',
      official.toMap(),
      'id = ?',
      [official.id],
    );
  }

  // Delete an official
  Future<int> deleteOfficial(int id) async {
    return await delete(
      'officials',
      'id = ?',
      [id],
    );
  }

  // Add sport to official
  Future<int> addSportToOfficial({
    required int officialId,
    required int sportId,
    required String certificationLevel,
    int yearsExperience = 0,
    String competitionLevels = '',
    bool isPrimary = false,
  }) async {
    return await insert('official_sports', {
      'official_id': officialId,
      'sport_id': sportId,
      'certification_level': certificationLevel,
      'years_experience': yearsExperience,
      'competition_levels': competitionLevels,
      'is_primary': isPrimary ? 1 : 0,
    });
  }

  // Remove sport from official
  Future<int> removeSportFromOfficial(int officialId, int sportId) async {
    return await delete(
      'official_sports',
      'official_id = ? AND sport_id = ?',
      [officialId, sportId],
    );
  }

  // Get officials by list name and user
  Future<List<Map<String, dynamic>>> getOfficialsByListName(
      String listName, int userId) async {
    final results = await rawQuery('''
      SELECT DISTINCT
        o.id,
        o.name,
        o.email,
        o.phone,
        o.city,
        o.state
      FROM officials o
      JOIN official_lists ol ON o.id = ol.official_id
      WHERE ol.name = ? AND ol.user_id = ?
      ORDER BY o.name
    ''', [listName, userId]);

    return results;
  }

  // Get official user by ID (for app accounts)
  Future<OfficialUser?> getOfficialUserById(int id) async {
    final results = await query(
      'official_users',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (results.isEmpty) return null;
    return OfficialUser.fromMap(results.first);
  }

  // Create official user account
  Future<int> createOfficialUser(OfficialUser officialUser) async {
    return await insert('official_users', officialUser.toMap());
  }

  // Get available lists count
  Future<int> getAvailableListsCount(int userId) async {
    final result = await rawQuery('''
      SELECT COUNT(DISTINCT name) as count
      FROM official_lists
      WHERE user_id = ? AND sport = 'Football'
    ''', [userId]);

    return result.isNotEmpty ? (result.first['count'] as int? ?? 0) : 0;
  }

  // Get baseball lists count
  Future<int> getBaseballListsCount(int userId) async {
    final result = await rawQuery('''
      SELECT COUNT(DISTINCT name) as count
      FROM official_lists
      WHERE user_id = ? AND sport = 'Baseball'
    ''', [userId]);

    return result.isNotEmpty ? (result.first['count'] as int? ?? 0) : 0;
  }

  // Get officials from list
  Future<List<Map<String, dynamic>>> getOfficialsFromList(
      String listName, int userId) async {
    final results = await rawQuery('''
      SELECT DISTINCT
        o.id,
        o.name,
        o.email,
        o.phone,
        o.city,
        o.state
      FROM officials o
      JOIN official_lists ol ON o.id = ol.official_id
      WHERE ol.name = ? AND ol.user_id = ?
      ORDER BY o.name
    ''', [listName, userId]);

    return results;
  }

  // Get lists count by sport
  Future<int> getListsCountBySport(int userId, String sport) async {
    final result = await rawQuery('''
      SELECT COUNT(DISTINCT name) as count
      FROM official_lists
      WHERE user_id = ? AND sport = ?
    ''', [userId, sport]);

    return result.isNotEmpty ? (result.first['count'] as int? ?? 0) : 0;
  }

  // Batch create officials
  Future<List<int>> batchCreateOfficials(List<Official> officials) async {
    final data = officials.map((official) => official.toMap()).toList();
    return await batchInsert('officials', data);
  }

  // Update verification status
  Future<void> updateVerificationStatus(
    int officialUserId, {
    bool? profileVerified,
    bool? photoVerified,
    bool? documentVerified,
    bool? emailVerified,
    bool? phoneVerified,
    String? verificationNotes,
  }) async {
    final updates = <String, dynamic>{};

    if (profileVerified != null) {
      updates['profile_verified'] = profileVerified ? 1 : 0;
    }
    if (photoVerified != null) {
      updates['photo_verified'] = photoVerified ? 1 : 0;
    }
    if (documentVerified != null) {
      updates['document_verified'] = documentVerified ? 1 : 0;
    }
    if (emailVerified != null) {
      updates['email_verified'] = emailVerified ? 1 : 0;
    }
    if (phoneVerified != null) {
      updates['phone_verified'] = phoneVerified ? 1 : 0;
    }
    if (verificationNotes != null) {
      updates['verification_notes'] = verificationNotes;
    }

    updates['updated_at'] = DateTime.now().toIso8601String();

    await update('official_users', updates, 'id = ?', [officialUserId]);
  }
}
