import '../../models/database_models.dart';
import 'base_repository.dart';

class LocationRepository extends BaseRepository {
  static const String tableName = 'locations';
  
  // Cache for user locations
  final Map<int, List<Location>> _locationsByUserCache = {};

  // Create a new location
  Future<int> createLocation(Location location) async {
    return await insert(tableName, location.toMap());
  }

  // Update an existing location
  Future<int> updateLocation(Location location) async {
    if (location.id == null) throw ArgumentError('Location ID cannot be null for update');
    
    return await update(
      tableName,
      location.toMap(),
      'id = ?',
      [location.id],
    );
  }

  // Delete a location
  Future<int> deleteLocation(int locationId) async {
    // Check if location is being used by any games
    final gamesUsingLocation = await query(
      'games',
      columns: ['id'],
      where: 'location_id = ?',
      whereArgs: [locationId],
      limit: 1,
    );

    if (gamesUsingLocation.isNotEmpty) {
      throw Exception('Cannot delete location: it is being used by existing games');
    }

    // Check if location is being used by any game templates
    final templatesUsingLocation = await query(
      'game_templates',
      columns: ['id'],
      where: 'location_id = ?',
      whereArgs: [locationId],
      limit: 1,
    );

    if (templatesUsingLocation.isNotEmpty) {
      throw Exception('Cannot delete location: it is being used by game templates');
    }

    return await delete(tableName, 'id = ?', [locationId]);
  }

  // Get location by ID
  Future<Location?> getLocationById(int locationId) async {
    final results = await query(
      tableName,
      where: 'id = ?',
      whereArgs: [locationId],
    );

    if (results.isEmpty) return null;
    return Location.fromMap(results.first);
  }

  // Get all locations for a user
  Future<List<Location>> getLocationsByUser(int userId) async {
    final results = await query(
      tableName,
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'name ASC',
    );

    return results.map((map) => Location.fromMap(map)).toList();
  }

  // Get location by name for a user
  Future<Location?> getLocationByName(int userId, String name) async {
    final results = await query(
      tableName,
      where: 'user_id = ? AND name = ?',
      whereArgs: [userId, name],
    );

    if (results.isEmpty) return null;
    return Location.fromMap(results.first);
  }

  // Search locations by name for a user
  Future<List<Location>> searchLocationsByName(int userId, String searchTerm) async {
    final results = await query(
      tableName,
      where: 'user_id = ? AND name LIKE ?',
      whereArgs: [userId, '%$searchTerm%'],
      orderBy: 'name ASC',
    );

    return results.map((map) => Location.fromMap(map)).toList();
  }

  // Check if location name exists for a user
  Future<bool> doesLocationExist(int userId, String name, {int? excludeId}) async {
    String whereClause = 'user_id = ? AND name = ?';
    List<dynamic> whereArgs = [userId, name];

    if (excludeId != null) {
      whereClause += ' AND id != ?';
      whereArgs.add(excludeId);
    }

    final results = await query(
      tableName,
      columns: ['id'],
      where: whereClause,
      whereArgs: whereArgs,
      limit: 1,
    );

    return results.isNotEmpty;
  }

  // Get locations with usage count (how many games use each location)
  Future<List<Map<String, dynamic>>> getLocationsWithUsageCount(int userId) async {
    final results = await rawQuery('''
      SELECT l.*, 
             COUNT(g.id) as games_count,
             COUNT(gt.id) as templates_count
      FROM locations l
      LEFT JOIN games g ON l.id = g.location_id
      LEFT JOIN game_templates gt ON l.id = gt.location_id
      WHERE l.user_id = ?
      GROUP BY l.id
      ORDER BY l.name ASC
    ''', [userId]);

    return results;
  }

  // Get most used locations for a user
  Future<List<Location>> getMostUsedLocations(int userId, {int limit = 10}) async {
    final results = await rawQuery('''
      SELECT l.*, COUNT(g.id) as usage_count
      FROM locations l
      LEFT JOIN games g ON l.id = g.location_id
      WHERE l.user_id = ?
      GROUP BY l.id
      ORDER BY usage_count DESC, l.name ASC
      LIMIT ?
    ''', [userId, limit]);

    return results.map((map) => Location.fromMap(map)).toList();
  }

  // Bulk create locations
  Future<List<int>> bulkCreateLocations(List<Location> locations) async {
    // Validate all locations first
    for (var location in locations) {
      if (location.name.trim().isEmpty) {
        throw ArgumentError('Location name cannot be empty');
      }
      if (location.address != null && location.address!.trim().isEmpty) {
        throw ArgumentError('Location address cannot be empty if provided');
      }
    }
    
    final db = await database;
    final List<int> ids = [];
    final Set<int> affectedUsers = {};

    await db.transaction((txn) async {
      for (var location in locations) {
        // Check for duplicates within this user's existing locations
        final exists = await doesLocationExist(location.userId, location.name);
        if (exists) {
          throw Exception('A location with the name "${location.name}" already exists');
        }
        
        final id = await txn.insert(tableName, location.toMap());
        ids.add(id);
        affectedUsers.add(location.userId);
      }
    });

    // Invalidate cache for all affected users
    for (var userId in affectedUsers) {
      _locationsByUserCache.remove(userId);
    }

    return ids;
  }

  // Get or create location by name
  Future<int> getOrCreateLocationByName(int userId, String name, {String? address, String? notes}) async {
    // Validate name
    if (name.trim().isEmpty) {
      throw ArgumentError('Location name cannot be empty');
    }
    
    // First try to find existing location
    final existing = await getLocationByName(userId, name);
    if (existing != null) {
      return existing.id!;
    }

    // Create new location if it doesn't exist
    final newLocation = Location(
      name: name,
      address: address,
      notes: notes,
      userId: userId,
    );

    return await createLocation(newLocation);
  }

  // Get location statistics for a user
  Future<Map<String, dynamic>> getLocationStatistics(int userId) async {
    final results = await rawQuery('''
      SELECT 
        COUNT(DISTINCT l.id) as total_locations,
        COUNT(DISTINCT g.id) as total_games_with_location,
        COUNT(DISTINCT gt.id) as total_templates_with_location
      FROM locations l
      LEFT JOIN games g ON l.id = g.location_id AND g.user_id = ?
      LEFT JOIN game_templates gt ON l.id = gt.location_id AND gt.user_id = ?
      WHERE l.user_id = ?
    ''', [userId, userId, userId]);

    return results.first;
  }
  
  // Clear all caches
  void clearCache() {
    _locationsByUserCache.clear();
  }
  
  // Clear cache for specific user
  void clearUserCache(int userId) {
    _locationsByUserCache.remove(userId);
  }
  
  // Check if user locations are cached
  bool isUserLocationsCached(int userId) {
    return _locationsByUserCache.containsKey(userId);
  }
}