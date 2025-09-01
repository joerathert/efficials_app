import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class FirebaseDatabaseService {
  static final FirebaseDatabaseService _instance =
      FirebaseDatabaseService._internal();
  FirebaseDatabaseService._internal();
  factory FirebaseDatabaseService() => _instance;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // SCHEDULES COLLECTION

  // Create a new schedule
  Future<Map<String, dynamic>?> createSchedule({
    required String name,
    required String sport,
    required String userId,
    String? homeTeamName,
  }) async {
    try {
      print(
          'DEBUG: Creating schedule - name: $name, sport: $sport, userId: $userId');

      final scheduleData = {
        'name': name,
        'sport': sport,
        'userId': userId,
        'homeTeamName': homeTeamName ?? '',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      print('DEBUG: Schedule data prepared: $scheduleData');

      final docRef = await _firestore.collection('schedules').add(scheduleData);
      print('DEBUG: Document reference created: ${docRef.id}');

      // Get the created document
      final doc = await docRef.get();
      print('DEBUG: Document exists: ${doc.exists}');

      if (doc.exists) {
        final data = doc.data()!;
        data['id'] = doc.id;
        print('DEBUG: Schedule created successfully: ${data['id']}');
        return data;
      }

      print('DEBUG: Document was created but does not exist when retrieved');
      return null;
    } catch (e, stackTrace) {
      print('ERROR: Creating schedule failed: $e');
      print('ERROR: Stack trace: $stackTrace');
      return null;
    }
  }

  // Get all schedules for a user
  Future<List<Map<String, dynamic>>> getSchedules(String userId) async {
    try {
      print(
          'DEBUG: getSchedules - userId: $userId (type: ${userId.runtimeType})');

      // Try both string and integer userId to handle data type inconsistencies
      final stringQuery =
          _firestore.collection('schedules').where('userId', isEqualTo: userId);

      final intQuery = _firestore
          .collection('schedules')
          .where('userId', isEqualTo: int.tryParse(userId) ?? userId);

      print('DEBUG: getSchedules - trying string userId query first');
      var querySnapshot = await stringQuery.get();

      print(
          'DEBUG: getSchedules - string query found ${querySnapshot.docs.length} documents');

      if (querySnapshot.docs.isEmpty) {
        print('DEBUG: getSchedules - trying integer userId query');
        querySnapshot = await intQuery.get();
        print(
            'DEBUG: getSchedules - integer query found ${querySnapshot.docs.length} documents');
      }

      // If still no results, try getting all documents and filtering manually
      if (querySnapshot.docs.isEmpty) {
        print('DEBUG: getSchedules - trying manual filter as fallback');
        final allDocs = await _firestore.collection('schedules').get();
        print(
            'DEBUG: getSchedules - found ${allDocs.docs.length} total documents in collection');

        final matchingDocs = allDocs.docs.where((doc) {
          final data = doc.data();
          final docUserId = data['userId'];
          print(
              'DEBUG: getSchedules - checking doc userId: $docUserId (type: ${docUserId.runtimeType}) against target: $userId');
          return docUserId.toString() == userId.toString();
        }).toList();

        print(
            'DEBUG: getSchedules - manual filter found ${matchingDocs.length} matching documents');

        final schedules = matchingDocs.map((doc) {
          final data = doc.data();
          data['id'] = doc.id;
          print('DEBUG: getSchedules - schedule: ${data}');
          return data;
        }).toList();

        return schedules;
      }

      final schedules = querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        print('DEBUG: getSchedules - schedule: ${data}');
        return data;
      }).toList();

      return schedules;
    } catch (e, stackTrace) {
      print('ERROR: getting schedules: $e');
      print('ERROR: Stack trace: $stackTrace');
      return [];
    }
  }

  // Get schedules by sport for a user
  Future<List<Map<String, dynamic>>> getSchedulesBySport(
      String userId, String sport) async {
    try {
      final querySnapshot = await _firestore
          .collection('schedules')
          .where('userId', isEqualTo: userId)
          .where('sport', isEqualTo: sport)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      print('Error getting schedules by sport: $e');
      return [];
    }
  }

  // Check if schedule exists
  Future<bool> scheduleExists(String userId, String name, String sport) async {
    try {
      print(
          'DEBUG: scheduleExists - userId: $userId, name: $name, sport: $sport');

      final querySnapshot = await _firestore
          .collection('schedules')
          .where('userId', isEqualTo: userId)
          .where('name', isEqualTo: name)
          .where('sport', isEqualTo: sport)
          .limit(1)
          .get();

      print(
          'DEBUG: scheduleExists - found ${querySnapshot.docs.length} documents');

      if (querySnapshot.docs.isNotEmpty) {
        for (var doc in querySnapshot.docs) {
          print('DEBUG: scheduleExists - existing doc: ${doc.data()}');
        }
      }

      return querySnapshot.docs.isNotEmpty;
    } catch (e, stackTrace) {
      print('ERROR: checking if schedule exists: $e');
      print('ERROR: Stack trace: $stackTrace');
      return false;
    }
  }

  // Update schedule
  Future<bool> updateSchedule(
      String scheduleId, Map<String, dynamic> updates) async {
    try {
      updates['updatedAt'] = FieldValue.serverTimestamp();
      await _firestore.collection('schedules').doc(scheduleId).update(updates);
      return true;
    } catch (e) {
      print('Error updating schedule: $e');
      return false;
    }
  }

  // Delete schedule
  Future<bool> deleteSchedule(String scheduleId) async {
    try {
      await _firestore.collection('schedules').doc(scheduleId).delete();
      return true;
    } catch (e) {
      print('Error deleting schedule: $e');
      return false;
    }
  }

  // GAMES COLLECTION (for future use)

  // Create a new game
  Future<Map<String, dynamic>?> createGame({
    required String scheduleId,
    required String scheduleName,
    required String sport,
    required String userId,
    required Map<String, dynamic> gameData,
  }) async {
    try {
      final data = {
        'scheduleId': scheduleId,
        'scheduleName': scheduleName,
        'sport': sport,
        'userId': userId,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        ...gameData,
      };

      final docRef = await _firestore.collection('games').add(data);

      // Get the created document
      final doc = await docRef.get();
      if (doc.exists) {
        final gameData = doc.data()!;
        gameData['id'] = doc.id;
        return gameData;
      }

      return null;
    } catch (e) {
      print('Error creating game: $e');
      return null;
    }
  }

  // Get games for a schedule
  Future<List<Map<String, dynamic>>> getGames(String scheduleId) async {
    try {
      final querySnapshot = await _firestore
          .collection('games')
          .where('scheduleId', isEqualTo: scheduleId)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      print('Error getting games: $e');
      return [];
    }
  }

  // USERS COLLECTION (for storing additional user data)

  // Save user profile data
  Future<bool> saveUserProfile(
      String userId, Map<String, dynamic> userData) async {
    try {
      userData['updatedAt'] = FieldValue.serverTimestamp();
      await _firestore
          .collection('users')
          .doc(userId)
          .set(userData, SetOptions(merge: true));
      return true;
    } catch (e) {
      print('Error saving user profile: $e');
      return false;
    }
  }

  // Get user profile data
  Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        final data = doc.data()!;
        data['id'] = doc.id;
        return data;
      }
      return null;
    } catch (e) {
      print('Error getting user profile: $e');
      return null;
    }
  }

  // OFFICIALS COLLECTION

  // Save official profile data
  Future<bool> saveOfficialProfile(
      String officialEmail, Map<String, dynamic> officialData) async {
    try {
      officialData['updatedAt'] = FieldValue.serverTimestamp();
      await _firestore
          .collection('officials')
          .doc(officialEmail)
          .set(officialData, SetOptions(merge: true));
      return true;
    } catch (e) {
      print('Error saving official profile: $e');
      return false;
    }
  }

  // Get official profile data
  Future<Map<String, dynamic>?> getOfficialProfile(String officialEmail) async {
    try {
      final doc =
          await _firestore.collection('officials').doc(officialEmail).get();
      if (doc.exists) {
        final data = doc.data()!;
        data['id'] = doc.id;
        return data;
      }
      return null;
    } catch (e) {
      print('Error getting official profile: $e');
      return null;
    }
  }

  // Get all officials
  Future<List<Map<String, dynamic>>> getAllOfficials() async {
    try {
      print('DEBUG: Querying Firestore officials collection...');
      final querySnapshot = await _firestore
          .collection('officials')
          .get(); // Removed orderBy to avoid Firestore index issues

      print('DEBUG: Found ${querySnapshot.docs.length} officials in Firestore');
      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      print('ERROR: Failed to get officials from Firestore: $e');
      return [];
    }
  }

  // Get officials by city/location
  Future<List<Map<String, dynamic>>> getOfficialsByLocation(String city) async {
    try {
      final querySnapshot = await _firestore
          .collection('officials')
          .where('city', isEqualTo: city)
          .orderBy('lastName')
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      print('Error getting officials by location: $e');
      return [];
    }
  }

  // Authenticate user (check email/password)
  Future<Map<String, dynamic>?> authenticateUser(
      String email, String password) async {
    try {
      // Check in users collection first
      final userDoc = await _firestore.collection('users').doc(email).get();
      if (userDoc.exists) {
        final userData = userDoc.data()!;
        if (userData['password'] == password) {
          userData['id'] = userDoc.id;
          return userData;
        }
      }

      // Check in officials collection
      final officialDoc =
          await _firestore.collection('officials').doc(email).get();
      if (officialDoc.exists) {
        final officialData = officialDoc.data()!;
        if (officialData['password'] == password) {
          officialData['id'] = officialDoc.id;
          return officialData;
        }
      }

      return null;
    } catch (e) {
      print('Error authenticating user: $e');
      return null;
    }
  }

  // OFFICIAL LISTS COLLECTION

  // Create a new official list
  Future<String?> createOfficialList({
    required String name,
    required String sport,
    required String userId,
    required List<String> officialIds,
  }) async {
    try {
      final listData = {
        'name': name,
        'sport': sport,
        'userId': userId,
        'officialIds': officialIds,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      final docRef =
          await _firestore.collection('official_lists').add(listData);

      return docRef.id;
    } catch (e, stackTrace) {
      print('ERROR: Creating official list failed: $e');
      print('ERROR: Stack trace: $stackTrace');
      return null;
    }
  }

  // Get all official lists for a user
  Future<List<Map<String, dynamic>>> getOfficialLists(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection('official_lists')
          .where('userId', isEqualTo: userId)
          .get();

      final lists = querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        // Calculate official count from officialIds array
        final officialIds = data['officialIds'] as List<dynamic>? ?? [];
        data['official_count'] = officialIds.length;
        return data;
      }).toList();

      return lists;
    } catch (e, stackTrace) {
      print('ERROR: Getting official lists failed: $e');
      return [];
    }
  }

  // Get officials in a specific list
  Future<List<Map<String, dynamic>>> getListOfficials(String listId) async {
    try {
      // Get the list document to get official IDs
      final listDoc =
          await _firestore.collection('official_lists').doc(listId).get();

      if (!listDoc.exists) {
        print('ERROR: List not found: $listId');
        return [];
      }

      final listData = listDoc.data()!;
      final officialIds = listData['officialIds'] as List<dynamic>? ?? [];

      if (officialIds.isEmpty) {
        return [];
      }

      // Get officials from officials collection
      final officials = <Map<String, dynamic>>[];

      for (final officialId in officialIds) {
        final officialDoc = await _firestore
            .collection('officials')
            .doc(officialId.toString())
            .get();
        if (officialDoc.exists) {
          final officialData = officialDoc.data()!;
          officialData['id'] = officialDoc.id;
          officials.add(officialData);
        }
      }

      return officials;
    } catch (e, stackTrace) {
      print('ERROR: Getting list officials failed: $e');
      print('ERROR: Stack trace: $stackTrace');
      return [];
    }
  }

  // Delete an official list
  Future<bool> deleteOfficialList(String listId) async {
    try {
      await _firestore.collection('official_lists').doc(listId).delete();
      print('DEBUG: Official list deleted: $listId');
      return true;
    } catch (e) {
      print('ERROR: Deleting official list failed: $e');
      return false;
    }
  }

  // Update official list
  Future<bool> updateOfficialList(
    String listId, {
    String? name,
    List<String>? officialIds,
  }) async {
    try {
      final updates = <String, dynamic>{
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (name != null) {
        updates['name'] = name;
      }

      if (officialIds != null) {
        updates['officialIds'] = officialIds;
      }

      await _firestore.collection('official_lists').doc(listId).update(updates);
      print('DEBUG: Official list updated: $listId');
      return true;
    } catch (e) {
      print('ERROR: Updating official list failed: $e');
      return false;
    }
  }
}
