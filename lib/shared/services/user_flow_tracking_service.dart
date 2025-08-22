import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'logging_service.dart';

class UserFlowEvent {
  final DateTime timestamp;
  final String eventType;
  final String screenName;
  final String? action;
  final Map<String, dynamic>? parameters;
  final String? userId;
  final String? userRole;

  UserFlowEvent({
    required this.timestamp,
    required this.eventType,
    required this.screenName,
    this.action,
    this.parameters,
    this.userId,
    this.userRole,
  });

  Map<String, dynamic> toJson() => {
    'timestamp': timestamp.toIso8601String(),
    'eventType': eventType,
    'screenName': screenName,
    'action': action,
    'parameters': parameters,
    'userId': userId,
    'userRole': userRole,
  };

  static UserFlowEvent fromJson(Map<String, dynamic> json) => UserFlowEvent(
    timestamp: DateTime.parse(json['timestamp']),
    eventType: json['eventType'],
    screenName: json['screenName'],
    action: json['action'],
    parameters: json['parameters'] != null ? Map<String, dynamic>.from(json['parameters']) : null,
    userId: json['userId'],
    userRole: json['userRole'],
  );
}

class UserFlowTrackingService {
  static final UserFlowTrackingService _instance = UserFlowTrackingService._internal();
  factory UserFlowTrackingService() => _instance;
  UserFlowTrackingService._internal();

  static const String _eventsKey = 'user_flow_events';
  static const String _sessionKey = 'current_session';
  static const int _maxEvents = 2000;

  final LoggingService _loggingService = LoggingService();
  final List<UserFlowEvent> _events = [];
  String? _currentSessionId;
  String? _currentUserId;
  String? _currentUserRole;
  DateTime? _sessionStartTime;
  String? _currentScreen;

  bool _isEnabled = true;

  Future<void> initialize({String? userId, String? userRole}) async {
    await _loadSettings();
    await _loadStoredEvents();
    await startSession(userId: userId, userRole: userRole);
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _isEnabled = prefs.getBool('user_flow_tracking_enabled') ?? true;
  }

  Future<void> _loadStoredEvents() async {
    final prefs = await SharedPreferences.getInstance();
    final eventsJson = prefs.getStringList(_eventsKey) ?? [];
    
    for (final eventString in eventsJson) {
      try {
        final eventData = jsonDecode(eventString);
        _events.add(UserFlowEvent.fromJson(eventData));
      } catch (e) {
        // Skip corrupted events
      }
    }
  }

  Future<void> _persistEvents() async {
    final prefs = await SharedPreferences.getInstance();
    final eventsJson = _events
        .take(_maxEvents)
        .map((event) => jsonEncode(event.toJson()))
        .toList();
    await prefs.setStringList(_eventsKey, eventsJson);
  }

  Future<void> startSession({String? userId, String? userRole}) async {
    _currentSessionId = DateTime.now().millisecondsSinceEpoch.toString();
    _sessionStartTime = DateTime.now();
    _currentUserId = userId;
    _currentUserRole = userRole;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_sessionKey, jsonEncode({
      'sessionId': _currentSessionId,
      'startTime': _sessionStartTime!.toIso8601String(),
      'userId': userId,
      'userRole': userRole,
    }));

    _trackEvent('session_start', 'app', action: 'start_session', parameters: {
      'session_id': _currentSessionId,
      'user_id': userId,
      'user_role': userRole,
    });

    _loggingService.info('User session started', 
                        category: 'UserFlow', 
                        context: {
                          'session_id': _currentSessionId,
                          'user_id': userId,
                          'user_role': userRole,
                        });
  }

  Future<void> endSession() async {
    if (_currentSessionId != null && _sessionStartTime != null) {
      final sessionDuration = DateTime.now().difference(_sessionStartTime!);
      
      _trackEvent('session_end', 'app', action: 'end_session', parameters: {
        'session_id': _currentSessionId,
        'duration_seconds': sessionDuration.inSeconds,
      });

      _loggingService.info('User session ended', 
                          category: 'UserFlow', 
                          context: {
                            'session_id': _currentSessionId,
                            'duration': sessionDuration.toString(),
                          });

      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_sessionKey);
    }

    _currentSessionId = null;
    _sessionStartTime = null;
    _currentUserId = null;
    _currentUserRole = null;
    _currentScreen = null;
  }

  void trackScreenView(String screenName, {Map<String, dynamic>? parameters}) {
    if (!_isEnabled) return;

    final previousScreen = _currentScreen;
    _currentScreen = screenName;

    _trackEvent('screen_view', screenName, parameters: {
      'previous_screen': previousScreen,
      ...?parameters,
    });

    _loggingService.trackNavigation(
      previousScreen ?? 'unknown',
      screenName,
      context: parameters,
    );
  }

  void trackUserAction(String action, {String? screenName, Map<String, dynamic>? parameters}) {
    if (!_isEnabled) return;

    _trackEvent('user_action', screenName ?? _currentScreen ?? 'unknown', 
               action: action, parameters: parameters);

    _loggingService.trackUserAction(action, context: {
      'screen': screenName ?? _currentScreen,
      ...?parameters,
    });
  }

  void trackButtonTap(String buttonName, {String? screenName, Map<String, dynamic>? parameters}) {
    trackUserAction('button_tap', screenName: screenName, parameters: {
      'button_name': buttonName,
      ...?parameters,
    });
  }

  void trackFormSubmission(String formName, {String? screenName, bool success = true, Map<String, dynamic>? parameters}) {
    trackUserAction('form_submission', screenName: screenName, parameters: {
      'form_name': formName,
      'success': success,
      ...?parameters,
    });
  }

  void trackDatabaseOperation(String operation, String table, {bool success = true, Map<String, dynamic>? parameters}) {
    if (!_isEnabled) return;

    _trackEvent('database_operation', _currentScreen ?? 'unknown', 
               action: operation, parameters: {
      'table': table,
      'success': success,
      ...?parameters,
    });

    _loggingService.trackDatabaseOperation(operation, table, context: {
      'success': success,
      'screen': _currentScreen,
      ...?parameters,
    });
  }

  void trackError(String errorType, String errorMessage, {String? screenName, Map<String, dynamic>? parameters}) {
    if (!_isEnabled) return;

    _trackEvent('error', screenName ?? _currentScreen ?? 'unknown', 
               action: errorType, parameters: {
      'error_message': errorMessage,
      ...?parameters,
    });

    _loggingService.error(errorMessage, category: 'UserFlow', context: {
      'error_type': errorType,
      'screen': screenName ?? _currentScreen,
      ...?parameters,
    });
  }

  void trackPerformanceMetric(String metricName, dynamic value, {String? screenName, Map<String, dynamic>? parameters}) {
    if (!_isEnabled) return;

    _trackEvent('performance', screenName ?? _currentScreen ?? 'unknown', 
               action: metricName, parameters: {
      'metric_value': value,
      ...?parameters,
    });

    _loggingService.debug('Performance metric: $metricName = $value', 
                         category: 'Performance', 
                         context: {
                           'screen': screenName ?? _currentScreen,
                           ...?parameters,
                         });
  }

  void _trackEvent(String eventType, String screenName, {String? action, Map<String, dynamic>? parameters}) {
    if (!_isEnabled) return;

    final event = UserFlowEvent(
      timestamp: DateTime.now(),
      eventType: eventType,
      screenName: screenName,
      action: action,
      parameters: parameters,
      userId: _currentUserId,
      userRole: _currentUserRole,
    );

    _events.insert(0, event);

    // Keep only recent events in memory
    if (_events.length > _maxEvents) {
      _events.removeRange(_maxEvents, _events.length);
    }

    // Persist events periodically
    if (_events.length % 50 == 0) {
      _persistEvents();
    }
  }

  // Settings management
  Future<void> setEnabled(bool enabled) async {
    _isEnabled = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('user_flow_tracking_enabled', enabled);
  }

  // Data access
  List<UserFlowEvent> getEvents({
    String? eventType,
    String? screenName,
    String? userId,
    DateTime? since,
    int? limit,
  }) {
    var filteredEvents = _events.where((event) {
      if (eventType != null && event.eventType != eventType) return false;
      if (screenName != null && event.screenName != screenName) return false;
      if (userId != null && event.userId != userId) return false;
      if (since != null && event.timestamp.isBefore(since)) return false;
      return true;
    }).toList();

    if (limit != null && filteredEvents.length > limit) {
      filteredEvents = filteredEvents.take(limit).toList();
    }

    return filteredEvents;
  }

  List<String> getScreenFlow({int? limit}) {
    final screenViews = getEvents(eventType: 'screen_view', limit: limit);
    return screenViews.map((event) => event.screenName).toList();
  }

  Map<String, int> getUserActionFrequency({String? screenName, DateTime? since}) {
    final actions = getEvents(eventType: 'user_action', screenName: screenName, since: since);
    final frequency = <String, int>{};
    
    for (final event in actions) {
      if (event.action != null) {
        frequency[event.action!] = (frequency[event.action!] ?? 0) + 1;
      }
    }
    
    return frequency;
  }

  Future<void> exportEvents() async {
    await _persistEvents();
  }

  Future<void> clearEvents() async {
    _events.clear();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_eventsKey);
  }

  // Getters
  bool get isEnabled => _isEnabled;
  String? get currentSessionId => _currentSessionId;
  String? get currentScreen => _currentScreen;
  String? get currentUserId => _currentUserId;
  String? get currentUserRole => _currentUserRole;
  int get eventCount => _events.length;
  DateTime? get sessionStartTime => _sessionStartTime;
  Duration? get sessionDuration => _sessionStartTime != null 
      ? DateTime.now().difference(_sessionStartTime!) 
      : null;
}