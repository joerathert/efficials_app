import 'dart:async';
import '../services/repositories/base_repository.dart';

/// Database monitor service to track changes to official_list_members table
class DatabaseMonitor extends BaseRepository {
  static final DatabaseMonitor _instance = DatabaseMonitor._internal();
  factory DatabaseMonitor() => _instance;
  DatabaseMonitor._internal();

  Timer? _monitorTimer;
  Map<int, List<int>> _lastKnownListMembers = {};
  bool _isMonitoring = false;

  /// Start monitoring database changes for specific lists
  void startMonitoring(List<int> listIds) {
    if (_isMonitoring) {
      print('🔍 DATABASE MONITOR: Already monitoring, stopping previous session');
      stopMonitoring();
    }

    print('🔍 DATABASE MONITOR: Starting monitoring for lists: $listIds');
    _isMonitoring = true;

    // Take initial snapshot
    _takeSnapshot(listIds);

    // Monitor every 500ms for the first 30 seconds, then every 2 seconds
    int checkCount = 0;
    _monitorTimer = Timer.periodic(Duration(milliseconds: 500), (timer) async {
      checkCount++;
      await _checkForChanges(listIds);

      // After 60 checks (30 seconds), slow down to every 2 seconds
      if (checkCount == 60) {
        timer.cancel();
        _monitorTimer = Timer.periodic(Duration(seconds: 2), (timer) async {
          await _checkForChanges(listIds);
        });
      }

      // Stop after 5 minutes total
      if (checkCount > 150) {
        print('🔍 DATABASE MONITOR: Stopping monitoring after 5 minutes');
        stopMonitoring();
      }
    });
  }

  /// Stop monitoring
  void stopMonitoring() {
    _monitorTimer?.cancel();
    _monitorTimer = null;
    _isMonitoring = false;
    _lastKnownListMembers.clear();
    print('🔍 DATABASE MONITOR: Monitoring stopped');
  }

  /// Take initial snapshot of list members
  Future<void> _takeSnapshot(List<int> listIds) async {
    for (int listId in listIds) {
      try {
        final members = await rawQuery(
          'SELECT official_id FROM official_list_members WHERE list_id = ? ORDER BY official_id',
          [listId]
        );
        final officialIds = members.map((m) => m['official_id'] as int).toList();
        _lastKnownListMembers[listId] = officialIds;
        print('🔍 DATABASE MONITOR: Initial snapshot for list $listId: $officialIds (${officialIds.length} members)');
        
        // Special check for Paul Barczewski (assuming ID 4 based on monitoring code)
        if (officialIds.contains(4)) {
          print('🔍 DATABASE MONITOR: Paul Barczewski (ID 4) is PRESENT in list $listId');
        }
      } catch (e) {
        print('🔍 DATABASE MONITOR ERROR taking snapshot for list $listId: $e');
      }
    }
  }

  /// Check for changes in list membership
  Future<void> _checkForChanges(List<int> listIds) async {
    for (int listId in listIds) {
      try {
        final members = await rawQuery(
          'SELECT official_id FROM official_list_members WHERE list_id = ? ORDER BY official_id',
          [listId]
        );
        final currentOfficialIds = members.map((m) => m['official_id'] as int).toList();
        final previousOfficialIds = _lastKnownListMembers[listId] ?? [];

        if (!_listsEqual(currentOfficialIds, previousOfficialIds)) {
          final timestamp = DateTime.now().toIso8601String();
          print('🚨 DATABASE MONITOR: CHANGE DETECTED in list $listId at $timestamp');
          print('🚨 Previous: $previousOfficialIds (${previousOfficialIds.length} members)');
          print('🚨 Current:  $currentOfficialIds (${currentOfficialIds.length} members)');

          final added = currentOfficialIds.where((id) => !previousOfficialIds.contains(id)).toList();
          final removed = previousOfficialIds.where((id) => !currentOfficialIds.contains(id)).toList();

          if (added.isNotEmpty) {
            print('🚨 ADDED: $added');
            for (int id in added) {
              await _logOfficialDetails(id, 'ADDED');
            }
          }

          if (removed.isNotEmpty) {
            print('🚨 REMOVED: $removed');
            for (int id in removed) {
              await _logOfficialDetails(id, 'REMOVED');
              
              // Special alert for Paul Barczewski (ID 4)
              if (id == 4) {
                print('🚨🚨🚨 CRITICAL: Paul Barczewski (ID 4) has been REMOVED! 🚨🚨🚨');
                await _investigatePaulRemoval();
              }
            }
          }

          // Update our snapshot
          _lastKnownListMembers[listId] = currentOfficialIds;
        }
      } catch (e) {
        print('🔍 DATABASE MONITOR ERROR checking list $listId: $e');
      }
    }
  }

  /// Log details about an official
  Future<void> _logOfficialDetails(int officialId, String action) async {
    try {
      final official = await rawQuery(
        'SELECT name, city, state FROM officials WHERE id = ?',
        [officialId]
      );
      
      if (official.isNotEmpty) {
        final name = official.first['name'];
        final city = official.first['city'];
        final state = official.first['state'];
        print('🔍 $action Official ID $officialId: $name ($city, $state)');
      } else {
        print('🔍 $action Official ID $officialId: NOT FOUND in officials table');
      }
    } catch (e) {
      print('🔍 ERROR logging details for official $officialId: $e');
    }
  }

  /// Special investigation when Paul is removed
  Future<void> _investigatePaulRemoval() async {
    try {
      // Check if Paul still exists in officials table
      final paulExists = await rawQuery(
        'SELECT id, name, city, state FROM officials WHERE id = 4'
      );
      
      if (paulExists.isNotEmpty) {
        print('🔍 INVESTIGATION: Paul still exists in officials table: ${paulExists.first}');
      } else {
        print('🔍 INVESTIGATION: Paul has been DELETED from officials table entirely!');
      }

      // Check if Paul has sport data
      final paulSports = await rawQuery(
        'SELECT * FROM official_sports WHERE official_id = 4'
      );
      print('🔍 INVESTIGATION: Paul has ${paulSports.length} sport entries: $paulSports');

      // Check all current list memberships for Paul
      final allMemberships = await rawQuery(
        'SELECT list_id, ol.name as list_name FROM official_list_members olm JOIN official_lists ol ON olm.list_id = ol.id WHERE olm.official_id = 4'
      );
      print('🔍 INVESTIGATION: Paul is currently in ${allMemberships.length} lists: $allMemberships');

    } catch (e) {
      print('🔍 INVESTIGATION ERROR: $e');
    }
  }

  /// Compare two lists for equality
  bool _listsEqual(List<int> list1, List<int> list2) {
    if (list1.length != list2.length) return false;
    for (int i = 0; i < list1.length; i++) {
      if (list1[i] != list2[i]) return false;
    }
    return true;
  }

  /// Get current status of monitoring
  bool get isMonitoring => _isMonitoring;

  /// Get current snapshot
  Map<int, List<int>> get currentSnapshot => Map.from(_lastKnownListMembers);
}