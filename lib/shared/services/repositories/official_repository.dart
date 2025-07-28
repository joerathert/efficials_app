import 'base_repository.dart';
import '../../models/database_models.dart';

class OfficialRepository extends BaseRepository {
  
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
    final results = await query(
      'officials',
      where: 'email = ?',
      whereArgs: [email],
    );
    
    if (results.isEmpty) return null;
    return Official.fromMap(results.first);
  }
  
  // Get all officials
  Future<List<Official>> getAllOfficials() async {
    final results = await query('officials');
    return results.map((data) => Official.fromMap(data)).toList();
  }
  
  // Get officials by sport with comprehensive filtering support
  Future<List<Map<String, dynamic>>> getOfficialsBySport(int sportId, {Map<String, dynamic>? filters}) async {
    // Base query that joins officials with their sport certifications
    String query = '''
      SELECT DISTINCT 
        o.id,
        o.name,
        o.email,
        o.phone,
        os.certification_level,
        os.years_experience,
        os.competition_levels,
        os.is_primary,
        s.name as sport_name
      FROM officials o
      JOIN official_sports os ON o.id = os.official_id
      JOIN sports s ON os.sport_id = s.id
      WHERE os.sport_id = ?
    ''';
    
    List<dynamic> queryArgs = [sportId];
    
    if (filters != null) {
      // Apply certification level filters (hierarchical)
      final wantsRegistered = filters['ihsaRegistered'] ?? false;
      final wantsRecognized = filters['ihsaRecognized'] ?? false;
      final wantsCertified = filters['ihsaCertified'] ?? false;
      
      if (wantsCertified) {
        query += ' AND os.certification_level = ?';
        queryArgs.add('IHSA Certified');
      } else if (wantsRecognized) {
        query += ' AND os.certification_level IN (?, ?)';
        queryArgs.addAll(['IHSA Recognized', 'IHSA Certified']);
      } else if (wantsRegistered) {
        query += ' AND os.certification_level IN (?, ?, ?)';
        queryArgs.addAll(['IHSA Registered', 'IHSA Recognized', 'IHSA Certified']);
      }
      
      // Apply minimum years experience filter
      if (filters['minYears'] != null && filters['minYears'] > 0) {
        query += ' AND os.years_experience >= ?';
        queryArgs.add(filters['minYears']);
      }
      
      // Apply competition levels filter
      final selectedLevels = filters['levels'] as List<String>?;
      if (selectedLevels != null && selectedLevels.isNotEmpty) {
        final levelConditions = selectedLevels.map((_) => 'os.competition_levels LIKE ?').join(' OR ');
        query += ' AND ($levelConditions)';
        for (final level in selectedLevels) {
          queryArgs.add('%$level%');
        }
      }
      
      // Note: Distance filtering will be handled at the UI level since we don't have 
      // geolocation data in the database yet
    }
    
    final results = await rawQuery(query, queryArgs);
    
    // Transform results to match the expected format from populate_roster_screen.dart
    return results.map((row) {
      final certLevel = row['certification_level'] as String? ?? '';
      final competitionLevels = (row['competition_levels'] as String? ?? '').split(',');
      
      return {
        'id': row['id'],
        'name': row['name'],
        'cityState': 'Chicago, IL', // TODO: Replace with actual address from officials table
        'distance': 10.0 + (row['id'] as int) * 2.5, // TODO: Calculate actual distance
        'yearsExperience': row['years_experience'] ?? 0,
        // Hierarchical IHSA certification flags - higher levels include lower levels
        'ihsaRegistered': certLevel == 'IHSA Registered' || certLevel == 'IHSA Recognized' || certLevel == 'IHSA Certified',
        'ihsaRecognized': certLevel == 'IHSA Recognized' || certLevel == 'IHSA Certified', 
        'ihsaCertified': certLevel == 'IHSA Certified',
        'level': competitionLevels.isNotEmpty ? competitionLevels.first : 'Varsity',
        'competitionLevels': competitionLevels,
        'sports': [row['sport_name'] ?? 'Unknown'], // Single sport for this query
      };
    }).toList();
  }
  
  // Legacy method maintained for compatibility
  Future<List<Official>> getOfficialsBySportLegacy(int sportId, {double? minRating, double? minFollowThroughRate}) async {
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
      'officials',
      where: whereClause,
      whereArgs: whereArgs,
    );
    return results.map((data) => Official.fromMap(data)).toList();
  }
  
  // Create a new official
  Future<int> createOfficial(Official official) async {
    return await insert('officials', official.toMap());
  }
  
  // Update official
  Future<int> updateOfficial(Official official) async {
    return await update('officials', official.toMap(), 'id = ?', [official.id]);
  }
  
  // Delete official
  Future<int> deleteOfficial(int officialId) async {
    return await delete('officials', 'id = ?', [officialId]);
  }
  
  // Get official user by email (for authentication)
  Future<OfficialUser?> getOfficialUserByEmail(String email) async {
    final results = await query(
      'official_users',
      where: 'email = ?',
      whereArgs: [email],
    );
    
    if (results.isEmpty) return null;
    return OfficialUser.fromMap(results.first);
  }
  
  // Create official user account
  Future<int> createOfficialUser(OfficialUser officialUser) async {
    return await insert('official_users', officialUser.toMap());
  }
  
  // Get official's availability for a specific date
  Future<List<OfficialAvailability>> getOfficialAvailability(int officialId, DateTime date) async {
    final dateString = date.toIso8601String().split('T')[0]; // Get date part only
    
    final results = await query(
      'official_availability',
      where: 'official_id = ? AND date = ?',
      whereArgs: [officialId, dateString],
    );
    
    return results.map((data) => OfficialAvailability.fromMap(data)).toList();
  }
  
  // Set official availability
  Future<int> setOfficialAvailability(OfficialAvailability availability) async {
    // Check if availability already exists
    final existing = await query(
      'official_availability',
      where: 'official_id = ? AND date = ? AND start_time = ?',
      whereArgs: [availability.officialId, availability.date, availability.startTime],
    );
    
    if (existing.isNotEmpty) {
      // Update existing
      return await update('official_availability', availability.toMap(), 
                         'official_id = ? AND date = ? AND start_time = ?',
                         [availability.officialId, availability.date, availability.startTime]);
    } else {
      // Insert new
      return await insert('official_availability', availability.toMap());
    }
  }
  
  // Get officials with their sports using JOIN query
  Future<List<Official>> getOfficialsWithSports() async {
    final results = await rawQuery('''
      SELECT o.*, 
             GROUP_CONCAT(s.name) as sport_names,
             GROUP_CONCAT(os.sport_id) as sport_ids,
             GROUP_CONCAT(os.certification_level) as certification_levels,
             GROUP_CONCAT(os.years_experience) as years_experiences,
             GROUP_CONCAT(os.is_primary) as is_primaries
      FROM officials o 
      LEFT JOIN official_sports os ON o.id = os.official_id
      LEFT JOIN sports s ON os.sport_id = s.id
      GROUP BY o.id
    ''');
    
    List<Official> officials = [];
    for (final row in results) {
      // Create basic official from the row data
      final official = Official.fromMap(row);
      
      // Parse the concatenated sport data
      final sportNames = row['sport_names']?.toString().split(',') ?? [];
      final sportIds = row['sport_ids']?.toString().split(',').map((id) => int.tryParse(id) ?? 0).toList() ?? [];
      final certLevels = row['certification_levels']?.toString().split(',') ?? [];
      final yearsExp = row['years_experiences']?.toString().split(',').map((exp) => int.tryParse(exp) ?? 0).toList() ?? [];
      final isPrimaries = row['is_primaries']?.toString().split(',').map((p) => p == '1').toList() ?? [];
      
      // Create OfficialSport objects for the sports list
      List<OfficialSport> sports = [];
      for (int i = 0; i < sportIds.length && i < sportNames.length; i++) {
        if (sportIds[i] > 0) {
          sports.add(OfficialSport(
            id: null,
            officialId: official.id ?? 0,
            sportId: sportIds[i],
            certificationLevel: i < certLevels.length ? certLevels[i] : null,
            yearsExperience: i < yearsExp.length ? yearsExp[i] : null,
            isPrimary: i < isPrimaries.length ? isPrimaries[i] : false,
            sportName: sportNames[i],
          ));
        }
      }
      
      officials.add(official);
    }
    
    return officials;
  }
  
  // Get officials by minimum rating
  Future<List<Official>> getOfficialsByRating(double minRating) async {
    final results = await query(
      'officials',
      where: 'rating >= ?',
      whereArgs: [minRating.toString()],
    );
    return results.map((data) => Official.fromMap(data)).toList();
  }
  
  // Batch create officials
  Future<List<int>> batchCreateOfficials(List<Official> officials) async {
    final officialMaps = officials.map((official) => official.toMap()).toList();
    return await batchInsert('officials', officialMaps);
  }

  // Get count of available official lists for a user
  Future<int> getAvailableListsCount(int userId) async {
    final results = await query(
      'official_lists',
      columns: ['COUNT(*) as count'],
      where: 'user_id = ?',
      whereArgs: [userId],
    );
    
    if (results.isEmpty) return 0;
    return results.first['count'] as int;
  }

  // Get count of available baseball lists for a user
  Future<int> getBaseballListsCount(int userId) async {
    final results = await rawQuery('''
      SELECT COUNT(*) as count
      FROM official_lists ol
      INNER JOIN sports s ON ol.sport_id = s.id
      WHERE ol.user_id = ? AND s.name = 'Baseball'
    ''', [userId]);
    
    if (results.isEmpty) return 0;
    return results.first['count'] as int;
  }

  // Get count of lists for a specific sport for a user
  Future<int> getListsCountBySport(int userId, String sportName) async {
    final results = await rawQuery('''
      SELECT COUNT(*) as count
      FROM official_lists ol
      INNER JOIN sports s ON ol.sport_id = s.id
      WHERE ol.user_id = ? AND s.name = ?
    ''', [userId, sportName]);
    
    if (results.isEmpty) return 0;
    return results.first['count'] as int;
  }

  // Get officials from a specific list by list name
  Future<List<Map<String, dynamic>>> getOfficialsFromList(String listName, int userId) async {
    final results = await rawQuery('''
      SELECT o.*
      FROM officials o
      INNER JOIN official_list_members olm ON o.id = olm.official_id
      INNER JOIN official_lists ol ON olm.list_id = ol.id
      WHERE ol.name = ? AND ol.user_id = ?
    ''', [listName, userId]);
    
    return results;
  }
}