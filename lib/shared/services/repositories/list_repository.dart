import 'base_repository.dart';
import '../../models/database_models.dart';
import '../user_session_service.dart';
import '../unified_data_service.dart';

class ListRepository extends BaseRepository {
  final UnifiedDataService _dataService = UnifiedDataService();
  // Create a new official list with officials (Firebase-first version)
  Future<int> createList(
      String name, String sport, List<Official> officials) async {
    // Convert Official objects to Map format for unified data service
    // IMPORTANT: Use the actual Firebase document IDs (emails) for consistency
    final officialsMap = officials.map((official) {
      // Use the actual email address from the official data (no generation needed)
      final actualEmail = official.email;
      if (actualEmail == null || actualEmail.isEmpty) {
        throw Exception('Official ${official.name} has no email address');
      }

      return {
        'id': official.id,
        'email': actualEmail,
        'name': official.name,
        'phone': official.phone,
        'city': official.city,
        'state': official.state,
        // Add other fields that might be needed
        'userId': official.userId,
        'sportId': official.sportId,
        'rating': official.rating,
        'experienceYears': official.experienceYears,
        'certificationLevel': official.certificationLevel,
      };
    }).toList();

    final userId = await _getCurrentUserId();
    final userIdString = userId.toString();

    // Use unified data service for Firebase-first architecture
    final listId = await _dataService.createOfficialList(
      name: name,
      sport: sport,
      userId: userIdString,
      officials: officialsMap,
    );

    if (listId != null) {
      // Return a hash of the string ID as integer for backward compatibility
      return listId.hashCode.abs();
    } else {
      print('ERROR: Failed to create list');
      throw Exception('Failed to create list: $name');
    }
  }

  // Get all lists for a user (now uses unified data service)
  Future<List<Map<String, dynamic>>> getUserLists(int userId) async {
    print('DEBUG: ListRepository.getUserLists for userId: $userId');

    // Use unified data service for Firebase-first architecture
    final lists = await _dataService.getOfficialLists(userId.toString());

    // Transform to match expected format (add sport_name field)
    final transformedLists = lists.map((list) {
      final transformed = Map<String, dynamic>.from(list);
      transformed['sport_name'] =
          list['sport']; // Firebase stores sport as string, not separate table
      return transformed;
    }).toList();

    print('DEBUG: Returning ${transformedLists.length} lists with sport names');
    return transformedLists;
  }

  // Get officials from a specific list (Firebase-first version)
  Future<List<Map<String, dynamic>>> getListOfficials(String listId) async {
    try {
      // Use unified data service to get officials for this list
      final officials = await _dataService.getListOfficials(listId);
      return officials;
    } catch (e) {
      print('Error getting list officials: $e');
      return [];
    }
  }

  // Delete a list and its members
  Future<void> deleteList(int listId) async {
    final db = await database;

    await db.transaction((txn) async {
      // Delete list members first
      await txn.delete('official_list_members',
          where: 'list_id = ?', whereArgs: [listId]);

      // Delete the list
      await txn.delete('official_lists', where: 'id = ?', whereArgs: [listId]);
    });
  }

  // Update list name
  Future<int> updateListName(int listId, String newName) async {
    return await update(
        'official_lists', {'name': newName}, 'id = ?', [listId]);
  }

  // Check if list name exists for a user (Firebase-first version)
  Future<bool> listNameExists(String name, int userId,
      {int? excludeListId}) async {
    print(
        'DEBUG: ListRepository.listNameExists - name: $name, userId: $userId, excludeListId: $excludeListId');

    try {
      // Use unified data service to get all lists for the user
      final lists = await _dataService.getOfficialLists(userId.toString());
      print(
          'DEBUG: Retrieved ${lists.length} lists from Firebase for duplicate check');

      // Check if any list has the same name, excluding the specified list if provided
      for (var list in lists) {
        final listName = list['name'] as String;
        final listId = list['id'] as String;

        // If this is the list we're excluding, skip it
        if (excludeListId != null && listId.hashCode.abs() == excludeListId) {
          print('DEBUG: Skipping excluded list: $listName (ID: $listId)');
          continue;
        }

        // Check for name match (case-insensitive)
        if (listName.toLowerCase() == name.toLowerCase()) {
          print('DEBUG: Found duplicate list name: $listName');
          return true;
        }
      }

      print('DEBUG: No duplicate list name found');
      return false;
    } catch (e) {
      print('ERROR: Exception in listNameExists: $e');
      // In case of error, assume name doesn't exist to allow creation
      return false;
    }
  }

  // Get all lists with their officials for a user (for advanced officials selection)
  Future<List<Map<String, dynamic>>> getLists([int? userId]) async {
    // If no userId provided, get current user
    final userIdToUse = userId ?? await _getCurrentUserId();
    final userIdString = userIdToUse.toString();

    // Use unified data service for Firebase-first architecture
    final lists = await _dataService.getOfficialLists(userIdString);

    // Transform lists to match expected format WITHOUT loading officials yet (lazy loading)
    final mutableLists = <Map<String, dynamic>>[];
    for (var list in lists) {
      final listId = list['id'] as String;

      // Create mutable copy with expected format
      final mutableList = Map<String, dynamic>.from(list);

      // Set empty officials list for now - will be loaded when needed
      mutableList['officials'] = [];

      // Add official count from Firebase data if available
      final officialIds = list['officialIds'] as List<dynamic>? ?? [];
      mutableList['official_count'] = officialIds.length;

      // Add integer ID for backward compatibility
      mutableList['id'] = listId.hashCode.abs();
      mutableList['original_id'] =
          listId; // Keep original string ID for Firebase operations

      mutableLists.add(mutableList);
    }

    return mutableLists;
  }

  // Update list with new officials (replaces existing officials)
  Future<void> updateList(
      String listName, List<Map<String, dynamic>> officials) async {
    final db = await database;

    await db.transaction((txn) async {
      // Find the list by name
      final listResults = await txn
          .query('official_lists', where: 'name = ?', whereArgs: [listName]);
      if (listResults.isEmpty) {
        throw Exception('List not found: $listName');
      }

      final listId = listResults.first['id'] as int;

      // Remove existing officials from the list
      await txn.delete('official_list_members',
          where: 'list_id = ?', whereArgs: [listId]);

      // Add new officials to the list
      for (final official in officials) {
        final officialId = official['id'];
        if (officialId != null) {
          await txn.insert('official_list_members', {
            'list_id': listId,
            'official_id': officialId,
          });
        }
      }
    });
  }

  // Update list with new officials by list ID (replaces existing officials)
  Future<void> updateListById(
      int listId, List<Map<String, dynamic>> officials) async {
    final db = await database;

    await db.transaction((txn) async {
      // Remove existing officials from the list
      await txn.delete('official_list_members',
          where: 'list_id = ?', whereArgs: [listId]);

      // Add new officials to the list
      for (final official in officials) {
        final officialId = official['id'];
        if (officialId != null) {
          await txn.insert('official_list_members', {
            'list_id': listId,
            'official_id': officialId,
          });
        }
      }
    });
  }

  // Create list from UI screens (saves list with officials from screens)
  Future<int> saveListFromUI(String listName, String sport,
      List<Map<String, dynamic>> officials) async {
    final userId = await _getCurrentUserId();
    final userIdString = userId.toString();

    // Use unified data service for Firebase-first architecture
    final listId = await _dataService.createOfficialList(
      name: listName,
      sport: sport,
      userId: userIdString,
      officials: officials,
    );

    if (listId != null) {
      // Return a hash of the string ID as integer for backward compatibility
      return listId.hashCode.abs();
    } else {
      print('ERROR: Failed to create list');
      throw Exception('Failed to create list: $listName');
    }
  }

  // Helper method to get current user ID
  Future<int> _getCurrentUserId() async {
    final userId = await UserSessionService.instance.getCurrentUserId();
    if (userId == null) {
      throw Exception('No user logged in');
    }
    return userId;
  }
}
