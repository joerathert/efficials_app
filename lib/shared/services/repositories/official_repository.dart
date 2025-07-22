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
  
  // Get officials by sport
  Future<List<Official>> getOfficialsBySport(int sportId) async {
    final results = await query(
      'officials',
      where: 'sport_id = ?',
      whereArgs: [sportId],
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
}