import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

enum LogLevel { debug, info, warning, error, critical }

class LogEntry {
  final DateTime timestamp;
  final LogLevel level;
  final String message;
  final String? category;
  final Map<String, dynamic>? context;
  final StackTrace? stackTrace;

  LogEntry({
    required this.timestamp,
    required this.level,
    required this.message,
    this.category,
    this.context,
    this.stackTrace,
  });

  Map<String, dynamic> toJson() => {
    'timestamp': timestamp.toIso8601String(),
    'level': level.name,
    'message': message,
    'category': category,
    'context': context,
    'stackTrace': stackTrace?.toString(),
  };

  static LogEntry fromJson(Map<String, dynamic> json) => LogEntry(
    timestamp: DateTime.parse(json['timestamp']),
    level: LogLevel.values.firstWhere((e) => e.name == json['level']),
    message: json['message'],
    category: json['category'],
    context: json['context'] != null ? Map<String, dynamic>.from(json['context']) : null,
    stackTrace: json['stackTrace'] != null ? StackTrace.fromString(json['stackTrace']) : null,
  );
}

class LoggingService {
  static final LoggingService _instance = LoggingService._internal();
  factory LoggingService() => _instance;
  LoggingService._internal();

  static const String _logsKey = 'app_logs';
  static const int _maxLogEntries = 1000;
  
  final List<LogEntry> _logs = [];
  bool _isEnabled = kDebugMode;
  LogLevel _minLevel = LogLevel.debug;

  Future<void> initialize() async {
    await _loadSettings();
    await _loadStoredLogs();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _isEnabled = prefs.getBool('debug_logging_enabled') ?? kDebugMode;
    final levelName = prefs.getString('debug_log_level') ?? LogLevel.debug.name;
    _minLevel = LogLevel.values.firstWhere((e) => e.name == levelName);
  }

  Future<void> _loadStoredLogs() async {
    final prefs = await SharedPreferences.getInstance();
    final logsJson = prefs.getStringList(_logsKey) ?? [];
    
    for (final logString in logsJson) {
      try {
        final logData = jsonDecode(logString);
        _logs.add(LogEntry.fromJson(logData));
      } catch (e) {
        // Skip corrupted log entries
      }
    }
  }

  Future<void> _persistLogs() async {
    final prefs = await SharedPreferences.getInstance();
    final logsJson = _logs
        .take(_maxLogEntries)
        .map((log) => jsonEncode(log.toJson()))
        .toList();
    await prefs.setStringList(_logsKey, logsJson);
  }

  void log(LogLevel level, String message, {
    String? category,
    Map<String, dynamic>? context,
    StackTrace? stackTrace,
  }) {
    if (!_isEnabled || level.index < _minLevel.index) return;

    final entry = LogEntry(
      timestamp: DateTime.now(),
      level: level,
      message: message,
      category: category,
      context: context,
      stackTrace: stackTrace,
    );

    _logs.insert(0, entry);
    
    // Keep only recent logs in memory
    if (_logs.length > _maxLogEntries) {
      _logs.removeRange(_maxLogEntries, _logs.length);
    }

    // Console output for development
    if (kDebugMode) {
      final timestamp = DateFormat('HH:mm:ss.SSS').format(entry.timestamp);
      final levelStr = level.name.toUpperCase().padRight(8);
      final categoryStr = category != null ? '[$category] ' : '';
      
      print('$timestamp $levelStr $categoryStr$message');
      if (context != null && context.isNotEmpty) {
        print('  Context: $context');
      }
      if (stackTrace != null) {
        print('  Stack: ${stackTrace.toString().split('\n').take(3).join('\n')}');
      }
    }

    // Persist critical logs immediately
    if (level == LogLevel.critical || level == LogLevel.error) {
      _persistLogs();
    }
  }

  // Convenience methods
  void debug(String message, {String? category, Map<String, dynamic>? context}) =>
      log(LogLevel.debug, message, category: category, context: context);

  void info(String message, {String? category, Map<String, dynamic>? context}) =>
      log(LogLevel.info, message, category: category, context: context);

  void warning(String message, {String? category, Map<String, dynamic>? context}) =>
      log(LogLevel.warning, message, category: category, context: context);

  void error(String message, {String? category, Map<String, dynamic>? context, StackTrace? stackTrace}) =>
      log(LogLevel.error, message, category: category, context: context, stackTrace: stackTrace);

  void critical(String message, {String? category, Map<String, dynamic>? context, StackTrace? stackTrace}) =>
      log(LogLevel.critical, message, category: category, context: context, stackTrace: stackTrace);

  // User flow tracking
  void trackNavigation(String from, String to, {Map<String, dynamic>? context}) {
    info('Navigation: $from → $to', 
         category: 'Navigation', 
         context: {'from': from, 'to': to, ...?context});
  }

  void trackUserAction(String action, {Map<String, dynamic>? context}) {
    info('User Action: $action', 
         category: 'UserAction', 
         context: context);
  }

  void trackDatabaseOperation(String operation, String table, {Map<String, dynamic>? context}) {
    debug('DB: $operation on $table', 
          category: 'Database', 
          context: {'operation': operation, 'table': table, ...?context});
  }

  void trackAPICall(String endpoint, String method, {Map<String, dynamic>? context}) {
    debug('API: $method $endpoint', 
          category: 'API', 
          context: {'endpoint': endpoint, 'method': method, ...?context});
  }

  // Settings
  Future<void> setEnabled(bool enabled) async {
    _isEnabled = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('debug_logging_enabled', enabled);
  }

  Future<void> setMinLevel(LogLevel level) async {
    _minLevel = level;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('debug_log_level', level.name);
  }

  // Log access
  List<LogEntry> getLogs({LogLevel? minLevel, String? category, int? limit}) {
    var filteredLogs = _logs.where((log) {
      if (minLevel != null && log.level.index < minLevel.index) return false;
      if (category != null && log.category != category) return false;
      return true;
    }).toList();

    if (limit != null && filteredLogs.length > limit) {
      filteredLogs = filteredLogs.take(limit).toList();
    }

    return filteredLogs;
  }

  Future<void> clearLogs() async {
    _logs.clear();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_logsKey);
  }

  Future<void> exportLogs() async {
    await _persistLogs();
  }

  // Getters
  bool get isEnabled => _isEnabled;
  LogLevel get minLevel => _minLevel;
  int get logCount => _logs.length;
  List<String> get categories => _logs
      .where((log) => log.category != null)
      .map((log) => log.category!)
      .toSet()
      .toList();
}