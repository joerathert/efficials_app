import 'base_repository.dart';
import '../../models/database_models.dart';
import '../user_session_service.dart';

class ListRepository extends BaseRepository {
  // Create a new official list with officials
  Future<int> createList(
      String name, String sport, List<Official> officials) async {
    final db = await database;

    return await db.transaction((txn) async {
      // Get sport_id
      final sportResult =
          await txn.query('sports', where: 'name = ?', whereArgs: [sport]);
      if (sportResult.isEmpty) {
        throw Exception('Sport not found: $sport');
      }
      final sportId = sportResult.first['id'] as int;

      // Get current user ID from session
      final userId = await _getCurrentUserId();

      // Create the list
      final listId = await txn.insert('official_lists', {
        'name': name,
        'sport_id': sportId,
        'user_id': userId,
        'created_at': DateTime.now().toIso8601String(),
      });

      // Add officials to the list
      for (final official in officials) {
        await txn.insert('official_list_members', {
          'list_id': listId,
          'official_id': official.id,
        });
      }

      return listId;
    });
  }

  // Get all lists for a user
  Future<List<Map<String, dynamic>>> getUserLists(int userId) async {
    final results = await rawQuery('''
      SELECT ol.*, s.name as sport_name,
             COUNT(olm.official_id) as official_count
      FROM official_lists ol
      LEFT JOIN sports s ON ol.sport_id = s.id
      LEFT JOIN official_list_members olm ON ol.id = olm.list_id
      WHERE ol.user_id = ?
      GROUP BY ol.id
      ORDER BY ol.created_at DESC
    ''', [userId]);

    return results;
  }

  // Get officials from a specific list
  Future<List<Map<String, dynamic>>> getListOfficials(int listId) async {
    final results = await rawQuery('''
      SELECT o.*, os.certification_level, os.years_experience, os.competition_levels
      FROM officials o
      INNER JOIN official_list_members olm ON o.id = olm.official_id
      LEFT JOIN official_sports os ON o.id = os.official_id
      WHERE olm.list_id = ?
    ''', [listId]);

    return results;
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
        'official_lists',
        {'name': newName, 'updated_at': DateTime.now().toIso8601String()},
        'id = ?',
        [listId]);
  }

  // Check if list name exists for a user
  Future<bool> listNameExists(String name, int userId,
      {int? excludeListId}) async {
    String whereClause = 'name = ? AND user_id = ?';
    List<dynamic> whereArgs = [name, userId];

    if (excludeListId != null) {
      whereClause += ' AND id != ?';
      whereArgs.add(excludeListId);
    }

    final results =
        await query('official_lists', where: whereClause, whereArgs: whereArgs);
    return results.isNotEmpty;
  }

  // Get all lists with their officials for a user (for advanced officials selection)
  Future<List<Map<String, dynamic>>> getLists([int? userId]) async {
    // If no userId provided, get current user
    final userIdToUse = userId ?? await _getCurrentUserId();

    final lists = await getUserLists(userIdToUse);

    // Create mutable copies and get officials for each list
    final mutableLists = <Map<String, dynamic>>[];
    for (var list in lists) {
      final listId = list['id'] as int;
      final officials = await getListOfficials(listId);
      
      // Create a new mutable map instead of modifying the read-only query result
      final mutableList = Map<String, dynamic>.from(list);
      mutableList['officials'] = officials;
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

  // Create list from UI screens (saves list with officials from screens)
  Future<int> saveListFromUI(
      String listName, String sport, List<Map<String, dynamic>> officials) async {
    final db = await database;
    final userId = await _getCurrentUserId();

    return await db.transaction((txn) async {
      // Get sport_id
      final sportResult =
          await txn.query('sports', where: 'name = ?', whereArgs: [sport]);
      if (sportResult.isEmpty) {
        throw Exception('Sport not found: $sport');
      }
      final sportId = sportResult.first['id'] as int;

      // Create the list
      final listId = await txn.insert('official_lists', {
        'name': listName,
        'sport_id': sportId,
        'user_id': userId,
        'created_at': DateTime.now().toIso8601String(),
      });

      // Add officials to the list
      for (final official in officials) {
        final officialId = official['id'];
        if (officialId != null) {
          await txn.insert('official_list_members', {
            'list_id': listId,
            'official_id': officialId,
          });
        }
      }

      return listId;
    });
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
