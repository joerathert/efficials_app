import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class FirebaseDatabaseService {
  static final FirebaseDatabaseService _instance = FirebaseDatabaseService._internal();
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
      print('DEBUG: Creating schedule - name: $name, sport: $sport, userId: $userId');
      
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
      print('DEBUG: getSchedules - userId: $userId (type: ${userId.runtimeType})');
      
      // Try both string and integer userId to handle data type inconsistencies
      final stringQuery = _firestore
          .collection('schedules')
          .where('userId', isEqualTo: userId);
          
      final intQuery = _firestore
          .collection('schedules')
          .where('userId', isEqualTo: int.tryParse(userId) ?? userId);
      
      print('DEBUG: getSchedules - trying string userId query first');
      var querySnapshot = await stringQuery.get();
      
      print('DEBUG: getSchedules - string query found ${querySnapshot.docs.length} documents');
      
      if (querySnapshot.docs.isEmpty) {
        print('DEBUG: getSchedules - trying integer userId query');
        querySnapshot = await intQuery.get();
        print('DEBUG: getSchedules - integer query found ${querySnapshot.docs.length} documents');
      }
      
      // If still no results, try getting all documents and filtering manually
      if (querySnapshot.docs.isEmpty) {
        print('DEBUG: getSchedules - trying manual filter as fallback');
        final allDocs = await _firestore.collection('schedules').get();
        print('DEBUG: getSchedules - found ${allDocs.docs.length} total documents in collection');
        
        final matchingDocs = allDocs.docs.where((doc) {
          final data = doc.data();
          final docUserId = data['userId'];
          print('DEBUG: getSchedules - checking doc userId: $docUserId (type: ${docUserId.runtimeType}) against target: $userId');
          return docUserId.toString() == userId.toString();
        }).toList();
        
        print('DEBUG: getSchedules - manual filter found ${matchingDocs.length} matching documents');
        
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
  Future<List<Map<String, dynamic>>> getSchedulesBySport(String userId, String sport) async {
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
      print('DEBUG: scheduleExists - userId: $userId, name: $name, sport: $sport');
      
      final querySnapshot = await _firestore
          .collection('schedules')
          .where('userId', isEqualTo: userId)
          .where('name', isEqualTo: name)
          .where('sport', isEqualTo: sport)
          .limit(1)
          .get();

      print('DEBUG: scheduleExists - found ${querySnapshot.docs.length} documents');
      
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
  Future<bool> updateSchedule(String scheduleId, Map<String, dynamic> updates) async {
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
  Future<bool> saveUserProfile(String userId, Map<String, dynamic> userData) async {
    try {
      userData['updatedAt'] = FieldValue.serverTimestamp();
      await _firestore.collection('users').doc(userId).set(userData, SetOptions(merge: true));
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
}