import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sqflite/sqflite.dart' show ConflictAlgorithm;
import 'firebase_database_service.dart';
import 'database_helper.dart';

/// Unified Data Service - The single source of truth for all data operations
///
/// Architecture:
/// - Web: Firebase/Firestore only
/// - Mobile: Firebase primary + SQLite cache for offline
/// - Desktop: Firebase primary (with SQLite fallback if needed)
///
/// This service automatically handles:
/// - Platform detection using kIsWeb
/// - Online/offline state management
/// - Data synchronization between Firebase and SQLite
/// - Consistent data format across platforms
class UnifiedDataService {
  static final UnifiedDataService _instance = UnifiedDataService._internal();
  UnifiedDataService._internal();
  factory UnifiedDataService() => _instance;

  final FirebaseDatabaseService _firebase = FirebaseDatabaseService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  DatabaseHelper? _sqlite;

  bool get isWeb => kIsWeb;
  bool get isMobile =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);
  bool get shouldUseCache => isMobile; // Only mobile devices use SQLite cache

  /// Initialize the service based on platform
  Future<void> initialize() async {
    debugPrint(
        '🔄 UnifiedDataService: Initializing for platform: ${isWeb ? 'Web' : isMobile ? 'Mobile' : 'Desktop'}');

    if (shouldUseCache) {
      try {
        _sqlite = DatabaseHelper();
        await _sqlite!.database; // Initialize SQLite
        debugPrint('✅ SQLite cache initialized for offline support');
      } catch (e) {
        debugPrint('⚠️  SQLite initialization failed: $e');
      }
    }

    debugPrint('✅ UnifiedDataService initialized');
  }

  /// Check if we're currently online (simplified version)
  /// In production, you'd use connectivity_plus package
  Future<bool> get isOnline async {
    try {
      // Try a simple Firebase operation to test connectivity
      await _firebase.getUserProfile('connectivity_test');
      return true;
    } catch (e) {
      return false;
    }
  }

  // ============================================================================
  // OFFICIALS DATA METHODS
  // ============================================================================

  /// Get all officials with smart platform handling
  Future<List<Map<String, dynamic>>> getAllOfficials({
    Map<String, dynamic>? filters,
  }) async {
    debugPrint(
        '🔍 UnifiedDataService.getAllOfficials() - Platform: ${isWeb ? 'Web' : isMobile ? 'Mobile' : 'Desktop'}');

    // Web: Always use Firebase
    if (isWeb) {
      return await _getOfficialsFromFirebase(filters);
    }

    // Mobile/Desktop: Firebase first, SQLite fallback
    if (await isOnline) {
      try {
        final firebaseOfficials = await _getOfficialsFromFirebase(filters);
        debugPrint(
            '🔥 Firebase returned ${firebaseOfficials.length} officials');

        // Cache to SQLite for offline use (mobile only)
        if (shouldUseCache && firebaseOfficials.isNotEmpty) {
          await _cacheOfficialsToSQLite(firebaseOfficials);
        }

        return firebaseOfficials;
      } catch (e) {
        debugPrint('❌ Firebase failed: $e');
        // Fall through to SQLite fallback
      }
    }

    // Offline or Firebase failed: Use SQLite cache (mobile only)
    if (shouldUseCache && _sqlite != null) {
      debugPrint('📱 Using SQLite cache (offline mode)');
      return await _getOfficialsFromSQLite(filters);
    }

    debugPrint('❌ No data source available');
    return [];
  }

  /// Get officials by sport with filtering
  Future<List<Map<String, dynamic>>> getOfficialsBySport(
    String sport, {
    Map<String, dynamic>? filters,
  }) async {
    final allOfficials = await getAllOfficials(filters: filters);

    // Filter by sport (all officials in our system are football officials for now)
    // In the future, you might store sport preferences per official
    return allOfficials;
  }

  // ============================================================================
  // LOCATIONS DATA METHODS
  // ============================================================================

  /// Get all locations with smart platform handling
  Future<List<Map<String, dynamic>>> getLocations({
    String? userId,
  }) async {
    debugPrint(
        '🔍 UnifiedDataService.getLocations() - Platform: ${isWeb ? 'Web' : isMobile ? 'Mobile' : 'Desktop'}');

    // Web: Always use Firestore
    if (isWeb) {
      return await _getLocationsFromFirestore(userId);
    }

    // Mobile/Desktop: Firestore first, SQLite fallback
    if (await isOnline) {
      try {
        final firestoreLocations = await _getLocationsFromFirestore(userId);
        debugPrint(
            '🔥 Firestore returned ${firestoreLocations.length} locations');

        // Cache to SQLite for offline use (mobile only)
        if (shouldUseCache && firestoreLocations.isNotEmpty) {
          await _cacheLocationsToSQLite(firestoreLocations);
        }

        return firestoreLocations;
      } catch (e) {
        debugPrint('❌ Firestore failed: $e');
        // Fall through to SQLite fallback
      }
    }

    // Offline or Firestore failed: Use SQLite cache (mobile only)
    if (shouldUseCache && _sqlite != null) {
      debugPrint('📱 Using SQLite cache (offline mode)');
      return await _getLocationsFromSQLite(userId);
    }

    debugPrint('❌ No data source available for locations');
    return [];
  }

  /// Create a new location
  Future<Map<String, dynamic>?> createLocation({
    required String name,
    required String address,
    required String city,
    required String state,
    required String zip,
    required String userId,
    String? notes,
  }) async {
    // Web: Always use Firestore
    if (isWeb) {
      return await _createLocationInFirestore(
        name: name,
        address: address,
        city: city,
        state: state,
        zip: zip,
        userId: userId,
        notes: notes,
      );
    }

    // Mobile/Desktop: Firestore first, SQLite fallback
    if (await isOnline) {
      try {
        final location = await _createLocationInFirestore(
          name: name,
          address: address,
          city: city,
          state: state,
          zip: zip,
          userId: userId,
          notes: notes,
        );

        // Cache to SQLite for offline use (mobile only)
        if (shouldUseCache && location != null) {
          await _cacheLocationToSQLite(location);
        }

        return location;
      } catch (e) {
        debugPrint('❌ Firestore location creation failed: $e');
        // Fall through to SQLite fallback
      }
    }

    // Offline: Use SQLite (mobile only)
    if (shouldUseCache && _sqlite != null) {
      debugPrint('📱 Creating location in SQLite cache (offline mode)');
      return await _createLocationInSQLite(
        name: name,
        address: address,
        city: city,
        state: state,
        zip: zip,
        userId: userId,
        notes: notes,
      );
    }

    return null;
  }

  // ============================================================================
  // GAMES DATA METHODS
  // ============================================================================

  /// Get games for a schedule with smart platform handling
  Future<List<Map<String, dynamic>>> getGames(String scheduleId) async {
    debugPrint(
        '🔍 UnifiedDataService.getGames() - Platform: ${isWeb ? 'Web' : isMobile ? 'Mobile' : 'Desktop'}');

    // Web: Always use Firebase
    if (isWeb) {
      return await _firebase.getGames(scheduleId);
    }

    // Mobile/Desktop: Firebase first, SQLite fallback
    if (await isOnline) {
      try {
        final firebaseGames = await _firebase.getGames(scheduleId);
        debugPrint('🔥 Firebase returned ${firebaseGames.length} games');

        // Cache to SQLite for offline use (mobile only)
        if (shouldUseCache && firebaseGames.isNotEmpty) {
          await _cacheGamesToSQLite(firebaseGames, scheduleId);
        }

        return firebaseGames;
      } catch (e) {
        debugPrint('❌ Firebase failed: $e');
        // Fall through to SQLite fallback
      }
    }

    // Offline or Firebase failed: Use SQLite cache (mobile only)
    if (shouldUseCache && _sqlite != null) {
      debugPrint('📱 Using SQLite cache (offline mode)');
      return await _getGamesFromSQLite(scheduleId);
    }

    debugPrint('❌ No data source available for games');
    return [];
  }

  /// Create a new game
  Future<Map<String, dynamic>?> createGame({
    required String scheduleId,
    required String scheduleName,
    required String sport,
    required String userId,
    required String opponent,
    required String date,
    required String time,
    required String location,
    String? notes,
  }) async {
    final gameData = {
      'opponent': opponent,
      'date': date,
      'time': time,
      'location': location,
      'notes': notes ?? '',
    };

    // Web: Always use Firebase
    if (isWeb) {
      return await _firebase.createGame(
        scheduleId: scheduleId,
        scheduleName: scheduleName,
        sport: sport,
        userId: userId,
        gameData: gameData,
      );
    }

    // Mobile/Desktop: Firebase first, SQLite fallback
    if (await isOnline) {
      try {
        final game = await _firebase.createGame(
          scheduleId: scheduleId,
          scheduleName: scheduleName,
          sport: sport,
          userId: userId,
          gameData: gameData,
        );

        // Cache to SQLite for offline use (mobile only)
        if (shouldUseCache && game != null) {
          await _cacheGameToSQLite(game, scheduleId);
        }

        return game;
      } catch (e) {
        debugPrint('❌ Firebase game creation failed: $e');
        // Fall through to SQLite fallback
      }
    }

    // Offline: Use SQLite (mobile only)
    if (shouldUseCache && _sqlite != null) {
      debugPrint('📱 Creating game in SQLite cache (offline mode)');
      return await _createGameInSQLite(
        scheduleId: scheduleId,
        opponent: opponent,
        date: date,
        time: time,
        location: location,
        notes: notes,
      );
    }

    return null;
  }

  // ============================================================================
  // FIREBASE/FIRESTORE OPERATIONS
  // ============================================================================

  Future<List<Map<String, dynamic>>> _getOfficialsFromFirebase(
    Map<String, dynamic>? filters,
  ) async {
    try {
      final officials = await _firebase.getAllOfficials();
      debugPrint('🔥 Firebase raw data: ${officials.length} officials');

      if (officials.isEmpty) {
        return [];
      }

      // Convert to standardized format and apply filters
      List<Map<String, dynamic>> convertedOfficials = [];
      int totalProcessed = 0;
      int passedFilters = 0;

      // Count officials by certification level for debugging
      Map<String, int> certCounts = {
        'Certified': 0,
        'Recognized': 0,
        'Registered': 0
      };
      Map<String, int> experienceCounts = {'10+': 0, '5-9': 0, '<5': 0};

      for (var official in officials) {
        totalProcessed++;
        final converted = _standardizeOfficialData(official);

        // Count certification levels
        final certLevel = converted['certification_level'] ?? 'Unknown';
        certCounts[certLevel] = (certCounts[certLevel] ?? 0) + 1;

        // Count experience levels
        final years = converted['years_experience'] as int? ?? 0;
        if (years >= 10) {
          experienceCounts['10+'] = experienceCounts['10+']! + 1;
        } else if (years >= 5) {
          experienceCounts['5-9'] = experienceCounts['5-9']! + 1;
        } else {
          experienceCounts['<5'] = experienceCounts['<5']! + 1;
        }

        if (_passesFilters(converted, filters)) {
          convertedOfficials.add(converted);
          passedFilters++;
        }
      }

      debugPrint('📊 FILTER SUMMARY:');
      debugPrint('   Total processed: $totalProcessed');
      debugPrint(
          '   Certification - Certified: ${certCounts['Certified']}, Recognized: ${certCounts['Recognized']}, Registered: ${certCounts['Registered']}');
      debugPrint(
          '   Experience - 10+ years: ${experienceCounts['10+']}, 5-9 years: ${experienceCounts['5-9']}, <5 years: ${experienceCounts['<5']}');
      debugPrint('   Passed all filters: $passedFilters');
      debugPrint('🔥 After filtering: ${convertedOfficials.length} officials');
      return convertedOfficials;
    } catch (e) {
      debugPrint('❌ Firebase query error: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> _getLocationsFromFirestore(
      String? userId) async {
    try {
      final query = userId != null
          ? _firestore
              .collection('locations')
              .where('userId', isEqualTo: userId)
          : _firestore.collection('locations');

      final querySnapshot = await query.get();
      debugPrint('🔥 Firestore returned ${querySnapshot.docs.length} locations');

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      debugPrint('❌ Firestore locations query error: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> _createLocationInFirestore({
    required String name,
    required String address,
    required String city,
    required String state,
    required String zip,
    required String userId,
    String? notes,
  }) async {
    try {
      final locationData = {
        'name': name,
        'address': address,
        'city': city,
        'state': state,
        'zip': zip,
        'userId': userId,
        'notes': notes ?? '',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      final docRef = await _firestore.collection('locations').add(locationData);
      final doc = await docRef.get();

      if (doc.exists) {
        final data = doc.data()!;
        data['id'] = doc.id;
        debugPrint('✅ Location created in Firestore: ${data['id']}');
        return data;
      }

      return null;
    } catch (e) {
      debugPrint('❌ Firestore location creation error: $e');
      rethrow;
    }
  }

  // ============================================================================
  // SQLITE OPERATIONS
  // ============================================================================

  Future<List<Map<String, dynamic>>> _getOfficialsFromSQLite(
    Map<String, dynamic>? filters,
  ) async {
    if (_sqlite == null) return [];

    try {
      final db = await _sqlite!.database;

      // Build query with filters
      String query = '''
        SELECT DISTINCT 
          o.id,
          o.name,
          o.email,
          o.phone,
          o.city,
          o.state,
          os.certification_level,
          os.years_experience,
          os.competition_levels
        FROM officials o
        LEFT JOIN official_sports os ON o.id = os.official_id
        WHERE 1=1
      ''';

      List<dynamic> args = [];

      if (filters != null) {
        // Add filter conditions
        query += _buildSQLiteFilters(filters, args);
      }

      final results = await db.rawQuery(query, args);
      debugPrint('📱 SQLite returned ${results.length} officials');

      return results.map((row) => Map<String, dynamic>.from(row)).toList();
    } catch (e) {
      debugPrint('❌ SQLite query error: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> _getLocationsFromSQLite(
      String? userId) async {
    if (_sqlite == null) return [];

    try {
      final db = await _sqlite!.database;

      String query = 'SELECT * FROM locations';
      List<dynamic> args = [];

      if (userId != null) {
        query += ' WHERE user_id = ?';
        args.add(int.tryParse(userId) ?? userId);
      }

      final results = await db.rawQuery(query, args);
      debugPrint('📱 SQLite returned ${results.length} locations');

      return results.map((row) => Map<String, dynamic>.from(row)).toList();
    } catch (e) {
      debugPrint('❌ SQLite locations query error: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>?> _createLocationInSQLite({
    required String name,
    required String address,
    required String city,
    required String state,
    required String zip,
    required String userId,
    String? notes,
  }) async {
    if (_sqlite == null) return null;

    try {
      final db = await _sqlite!.database;

      final locationData = {
        'name': name,
        'address': '$address, $city, $state $zip',
        'notes': notes ?? '',
        'user_id': int.tryParse(userId) ?? 1,
      };

      final id = await db.insert('locations', locationData);

      return {
        'id': id,
        'name': name,
        'address': address,
        'city': city,
        'state': state,
        'zip': zip,
        'notes': notes,
      };
    } catch (e) {
      debugPrint('❌ SQLite location creation error: $e');
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> _getGamesFromSQLite(
      String scheduleId) async {
    if (_sqlite == null) return [];

    try {
      final db = await _sqlite!.database;

      final results = await db.rawQuery('''
        SELECT * FROM games 
        WHERE schedule_id = ?
        ORDER BY created_at DESC
      ''', [int.tryParse(scheduleId) ?? scheduleId]);

      debugPrint('📱 SQLite returned ${results.length} games');
      return results.map((row) => Map<String, dynamic>.from(row)).toList();
    } catch (e) {
      debugPrint('❌ SQLite games query error: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>?> _createGameInSQLite({
    required String scheduleId,
    required String opponent,
    required String date,
    required String time,
    required String location,
    String? notes,
  }) async {
    if (_sqlite == null) return null;

    try {
      final db = await _sqlite!.database;

      final gameData = {
        'schedule_id': int.tryParse(scheduleId) ?? scheduleId,
        'opponent': opponent,
        'date': date,
        'time': time,
        'location': location,
        'notes': notes ?? '',
        'created_at': DateTime.now().millisecondsSinceEpoch,
      };

      final id = await db.insert('games', gameData);

      return {
        'id': id.toString(),
        'scheduleId': scheduleId,
        'opponent': opponent,
        'date': date,
        'time': time,
        'location': location,
        'notes': notes,
      };
    } catch (e) {
      debugPrint('❌ SQLite game creation error: $e');
      return null;
    }
  }

  // ============================================================================
  // CACHING OPERATIONS (Mobile Only)
  // ============================================================================

  Future<void> _cacheOfficialsToSQLite(
      List<Map<String, dynamic>> officials) async {
    if (_sqlite == null || officials.isEmpty) return;

    try {
      final db = await _sqlite!.database;

      // Clear existing cache
      await db.delete('officials_cache');

      // Insert fresh data
      for (var official in officials) {
        await db.insert(
            'officials_cache',
            {
              'firebase_id': official['id'],
              'data': official.toString(), // JSON serialize in production
              'cached_at': DateTime.now().millisecondsSinceEpoch,
            },
            conflictAlgorithm: ConflictAlgorithm.replace);
      }

      debugPrint('💾 Cached ${officials.length} officials to SQLite');
    } catch (e) {
      debugPrint('❌ Cache error: $e');
    }
  }

  Future<void> _cacheLocationsToSQLite(
      List<Map<String, dynamic>> locations) async {
    if (_sqlite == null || locations.isEmpty) return;

    try {
      final db = await _sqlite!.database;

      // Clear existing cache
      await db.delete('locations_cache');

      // Insert fresh data
      for (var location in locations) {
        await db.insert(
            'locations_cache',
            {
              'firestore_id': location['id'],
              'data': location.toString(), // JSON serialize in production
              'cached_at': DateTime.now().millisecondsSinceEpoch,
            },
            conflictAlgorithm: ConflictAlgorithm.replace);
      }

      debugPrint('💾 Cached ${locations.length} locations to SQLite');
    } catch (e) {
      debugPrint('❌ Locations cache error: $e');
    }
  }

  Future<void> _cacheLocationToSQLite(Map<String, dynamic> location) async {
    if (_sqlite == null) return;

    try {
      final db = await _sqlite!.database;

      await db.insert(
          'locations_cache',
          {
            'firestore_id': location['id'],
            'data': location.toString(), // JSON serialize in production
            'cached_at': DateTime.now().millisecondsSinceEpoch,
          },
          conflictAlgorithm: ConflictAlgorithm.replace);

      debugPrint('💾 Cached location to SQLite');
    } catch (e) {
      debugPrint('❌ Location cache error: $e');
    }
  }

  Future<void> _cacheGamesToSQLite(
      List<Map<String, dynamic>> games, String scheduleId) async {
    if (_sqlite == null || games.isEmpty) return;

    try {
      final db = await _sqlite!.database;

      // Clear existing cache for this schedule
      await db.delete('games_cache',
          where: 'schedule_id = ?', whereArgs: [scheduleId]);

      // Insert fresh data
      for (var game in games) {
        await db.insert(
            'games_cache',
            {
              'firebase_id': game['id'],
              'schedule_id': scheduleId,
              'data': game.toString(), // JSON serialize in production
              'cached_at': DateTime.now().millisecondsSinceEpoch,
            },
            conflictAlgorithm: ConflictAlgorithm.replace);
      }

      debugPrint('💾 Cached ${games.length} games to SQLite');
    } catch (e) {
      debugPrint('❌ Games cache error: $e');
    }
  }

  Future<void> _cacheGameToSQLite(
      Map<String, dynamic> game, String scheduleId) async {
    if (_sqlite == null) return;

    try {
      final db = await _sqlite!.database;

      await db.insert(
          'games_cache',
          {
            'firebase_id': game['id'],
            'schedule_id': scheduleId,
            'data': game.toString(), // JSON serialize in production
            'cached_at': DateTime.now().millisecondsSinceEpoch,
          },
          conflictAlgorithm: ConflictAlgorithm.replace);

      debugPrint('💾 Cached game to SQLite');
    } catch (e) {
      debugPrint('❌ Game cache error: $e');
    }
  }

  // ============================================================================
  // DATA STANDARDIZATION
  // ============================================================================

  /// Convert Firebase official data to standardized format
  Map<String, dynamic> _standardizeOfficialData(
      Map<String, dynamic> firebaseOfficial) {
    final firstName = firebaseOfficial['firstName'];
    final lastName = firebaseOfficial['lastName'];

    final standardizedName =
        '${firstName ?? 'Unknown'} ${lastName ?? 'Official'}';

    return {
      'id': firebaseOfficial['email'] ??
          'unknown_${DateTime.now().millisecondsSinceEpoch}',
      'name': standardizedName,
      'email': firebaseOfficial['email'], // Preserve the email field
      'phone': firebaseOfficial['phone'] ?? '',
      'city': firebaseOfficial['city'] ?? '',
      'state': firebaseOfficial['state'] ?? 'IL',
      'address': firebaseOfficial['address'] ?? '',
      'zipCode': firebaseOfficial['zipCode'] ?? '',
      'firstName': firebaseOfficial['firstName'] ?? '',
      'lastName': firebaseOfficial['lastName'] ?? '',
      'displayName': firebaseOfficial['displayName'] ?? standardizedName,
      'certificationLevel':
          firebaseOfficial['certificationLevel'] ?? 'Registered',
      'experienceYears': firebaseOfficial['experienceYears'] ?? 0,
      'competitionLevels': firebaseOfficial['competitionLevels'] ?? 'Varsity',
      'rating': firebaseOfficial['rating'] ?? 0.0,
      'gamesWorked': firebaseOfficial['gamesWorked'] ?? 0,
      'availability': firebaseOfficial['availability'] ?? 'available',
      'isActive': firebaseOfficial['isActive'] ?? true,
      'userType': firebaseOfficial['userType'] ?? 'official',
      'password': firebaseOfficial['password'] ?? '',
      'createdAt': firebaseOfficial['createdAt'] ?? '',
      'updatedAt': firebaseOfficial['updatedAt'] ?? '',
      // Add calculated fields for UI
      'cityState':
          '${firebaseOfficial['city'] ?? ''}, ${firebaseOfficial['state'] ?? 'IL'}',
      'yearsExperience': firebaseOfficial['experienceYears'] ?? 0,
      'years_experience': firebaseOfficial['experienceYears'] ?? 0,
      'certification_level':
          firebaseOfficial['certificationLevel'] ?? 'Registered',
      'competition_levels': firebaseOfficial['competitionLevels'] ?? 'Varsity',
    };
  }


  // ============================================================================
  // FILTERING
  // ============================================================================

  bool _passesFilters(
      Map<String, dynamic> official, Map<String, dynamic>? filters) {
    if (filters == null) return true;

    final officialName = official['name'] ?? 'Unknown';
    bool passes = true;

    // Check IHSA certification level
    final ihsaLevel = filters['ihsaLevel'] as String?;
    if (ihsaLevel != null) {
      final certLevel = official['certification_level'];
      final passesIHSA = _passesIHSAFilter(certLevel, ihsaLevel);
      if (!passesIHSA) {
        debugPrint(
            '❌ $officialName failed IHSA filter: has $certLevel, needs $ihsaLevel');
        passes = false;
      } else {
        debugPrint(
            '✅ $officialName passed IHSA filter: has $certLevel, needs $ihsaLevel');
      }
    }

    // Check minimum years experience
    final minYears = filters['minYears'] as int?;
    if (minYears != null && minYears > 0 && passes) {
      final officialYears = official['years_experience'] as int? ?? 0;
      if (officialYears < minYears) {
        debugPrint(
            '❌ $officialName failed experience filter: has $officialYears years, needs $minYears+');
        passes = false;
      } else {
        debugPrint(
            '✅ $officialName passed experience filter: has $officialYears years, needs $minYears+');
      }
    }

    // Check competition levels
    final selectedLevels = filters['levels'] as List<String>?;
    if (selectedLevels != null && selectedLevels.isNotEmpty && passes) {
      final officialLevels = official['competition_levels'] as String? ?? '';
      bool hasMatchingLevel = selectedLevels.any((level) =>
          officialLevels.toLowerCase().contains(level.toLowerCase()));
      if (!hasMatchingLevel) {
        debugPrint(
            '❌ $officialName failed competition level filter: has "$officialLevels", needs one of $selectedLevels');
        passes = false;
      } else {
        debugPrint(
            '✅ $officialName passed competition level filter: has "$officialLevels", needs one of $selectedLevels');
      }
    }

    return passes;
  }

  bool _passesIHSAFilter(String officialLevel, String requiredLevel) {
    const hierarchy = {
      'Registered': 1,
      'Recognized': 2,
      'Certified': 3,
    };

    final officialRank = hierarchy[officialLevel] ?? 0;
    final requiredRank = hierarchy[_capitalizeFirst(requiredLevel)] ?? 0;

    return officialRank >= requiredRank;
  }

  String _capitalizeFirst(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1).toLowerCase();
  }

  String _buildSQLiteFilters(Map<String, dynamic> filters, List<dynamic> args) {
    String conditions = '';

    // Add filter building logic for SQLite queries
    // This would be used when offline on mobile

    return conditions;
  }

  // ============================================================================
  // OFFICIAL LISTS METHODS
  // ============================================================================

  /// Create a new official list with selected officials
  Future<String?> createOfficialList({
    required String name,
    required String sport,
    required String userId,
    required List<Map<String, dynamic>> officials,
  }) async {
    try {
      print(
          'DEBUG: createOfficialList called with ${officials.length} officials');

      // Extract official IDs (use email as ID for Firebase)
      final officialIds = officials.map((official) {
        final email = official['email'] as String?;

        // Use the actual email address (no generation needed)
        if (email == null || email.isEmpty) {
          throw Exception('Official ${official['name']} has no email address');
        }

        return email;
      }).toList();

      if (isWeb || await isOnline) {
        final listId = await _firebase.createOfficialList(
          name: name,
          sport: sport,
          userId: userId,
          officialIds: officialIds,
        );

        if (listId != null && shouldUseCache && _sqlite != null) {
          // TODO: Cache in SQLite for offline access on mobile
        }

        return listId;
      } else if (shouldUseCache && _sqlite != null) {
        print('DEBUG: Creating list in SQLite cache (offline mode)');
        // TODO: Implement SQLite list creation for offline mode
        // For now, return error since we need Firebase for primary storage
        throw Exception(
            'Cannot create lists while offline - Firebase connection required');
      }

      return null;
    } catch (e, stackTrace) {
      print('ERROR: UnifiedDataService.createOfficialList failed: $e');
      print('ERROR: Stack trace: $stackTrace');
      return null;
    }
  }

  /// Get all official lists for a user
  Future<List<Map<String, dynamic>>> getOfficialLists(String userId) async {
    try {
      if (isWeb || await isOnline) {
        final lists = await _firebase.getOfficialLists(userId);

        if (shouldUseCache && _sqlite != null) {
          // TODO: Cache in SQLite for offline access on mobile
        }

        return lists;
      } else if (shouldUseCache && _sqlite != null) {
        // TODO: Implement SQLite list retrieval for offline mode
        return [];
      }

      return [];
    } catch (e) {
      print('ERROR: UnifiedDataService.getOfficialLists failed: $e');
      return [];
    }
  }

  /// Get officials in a specific list
  Future<List<Map<String, dynamic>>> getListOfficials(String listId) async {
    try {
      if (isWeb || await isOnline) {
        final officials = await _firebase.getListOfficials(listId);

        // Transform officials to match UI format (consistent integer IDs)
        final transformedOfficials =
            officials.map<Map<String, dynamic>>((official) {
          return _transformOfficialForUI(official);
        }).toList();

        if (shouldUseCache && _sqlite != null) {
          // TODO: Cache in SQLite for offline access on mobile
        }

        return transformedOfficials;
      } else if (shouldUseCache && _sqlite != null) {
        print('DEBUG: Getting list officials from SQLite cache (offline mode)');
        // TODO: Implement SQLite list official retrieval for offline mode
        return [];
      }

      return [];
    } catch (e, stackTrace) {
      print('ERROR: UnifiedDataService.getListOfficials failed: $e');
      print('ERROR: Stack trace: $stackTrace');
      return [];
    }
  }

  /// Delete an official list
  Future<bool> deleteOfficialList(String listId) async {
    try {
      print('DEBUG: UnifiedDataService.deleteOfficialList for listId: $listId');

      if (isWeb || await isOnline) {
        print('DEBUG: Deleting list from Firebase');
        final success = await _firebase.deleteOfficialList(listId);

        if (success && shouldUseCache && _sqlite != null) {
          print('DEBUG: Removing list from SQLite cache');
          // TODO: Remove from SQLite cache
        }

        return success;
      } else if (shouldUseCache && _sqlite != null) {
        print(
            'DEBUG: Cannot delete list while offline - Firebase connection required');
        return false;
      }

      return false;
    } catch (e, stackTrace) {
      print('ERROR: UnifiedDataService.deleteOfficialList failed: $e');
      print('ERROR: Stack trace: $stackTrace');
      return false;
    }
  }

  // ============================================================================
  // USER DATA METHODS (for future expansion)
  // ============================================================================

  Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    if (isWeb || await isOnline) {
      return await _firebase.getUserProfile(userId);
    }

    // Add SQLite fallback for user data if needed
    return null;
  }

  Future<bool> saveUserProfile(
      String userId, Map<String, dynamic> userData) async {
    if (isWeb || await isOnline) {
      return await _firebase.saveUserProfile(userId, userData);
    }

    // Add SQLite caching for user data if needed
    return false;
  }

  // ============================================================================
  // HELPER METHODS
  // ============================================================================

  /// Transform official data to the format expected by the UI
  Map<String, dynamic> _transformOfficialForUI(Map<String, dynamic> official) {
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
      'email': official['id'], // Keep original email as separate field
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
}