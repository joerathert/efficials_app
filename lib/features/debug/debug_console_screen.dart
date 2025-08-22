import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../shared/theme.dart';
import '../../shared/services/logging_service.dart';

class DebugConsoleScreen extends StatefulWidget {
  const DebugConsoleScreen({super.key});

  @override
  State<DebugConsoleScreen> createState() => _DebugConsoleScreenState();
}

class _DebugConsoleScreenState extends State<DebugConsoleScreen> {
  final LoggingService _loggingService = LoggingService();
  List<LogEntry> _filteredLogs = [];
  LogLevel? _selectedLevel;
  String? _selectedCategory;
  bool _autoScroll = true;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _refreshLogs();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _refreshLogs() {
    setState(() {
      _filteredLogs = _loggingService.getLogs(
        minLevel: _selectedLevel,
        category: _selectedCategory,
        limit: 500,
      );
    });
    
    if (_autoScroll && _filteredLogs.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            0.0,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  Color _getLevelColor(LogLevel level) {
    switch (level) {
      case LogLevel.debug:
        return Colors.grey;
      case LogLevel.info:
        return Colors.blue;
      case LogLevel.warning:
        return Colors.orange;
      case LogLevel.error:
        return Colors.red;
      case LogLevel.critical:
        return Colors.purple;
    }
  }

  IconData _getLevelIcon(LogLevel level) {
    switch (level) {
      case LogLevel.debug:
        return Icons.bug_report;
      case LogLevel.info:
        return Icons.info;
      case LogLevel.warning:
        return Icons.warning;
      case LogLevel.error:
        return Icons.error;
      case LogLevel.critical:
        return Icons.dangerous;
    }
  }

  Widget _buildLogEntry(LogEntry log) {
    final timeFormat = DateFormat('HH:mm:ss.SSS');
    final color = _getLevelColor(log.level);
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      color: darkSurface,
      child: ExpansionTile(
        leading: Icon(_getLevelIcon(log.level), color: color, size: 16),
        title: Row(
          children: [
            Text(
              timeFormat.format(log.timestamp),
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[400],
                fontFamily: 'monospace',
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: color.withOpacity(0.5)),
              ),
              child: Text(
                log.level.name.toUpperCase(),
                style: TextStyle(
                  fontSize: 10,
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            if (log.category != null) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: efficialsBlue.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  log.category!,
                  style: const TextStyle(
                    fontSize: 10,
                    color: efficialsBlue,
                  ),
                ),
              ),
            ],
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            log.message,
            style: const TextStyle(fontSize: 14),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        children: [
          if (log.context != null || log.stackTrace != null)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (log.context != null) ...[
                    const Text(
                      'Context:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: efficialsBlue,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: darkBackground,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.grey[700]!),
                      ),
                      child: Text(
                        log.context.toString(),
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                  if (log.stackTrace != null) ...[
                    if (log.context != null) const SizedBox(height: 12),
                    const Text(
                      'Stack Trace:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: efficialsBlue,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: darkBackground,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.grey[700]!),
                      ),
                      child: Text(
                        log.stackTrace.toString(),
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton.icon(
                        onPressed: () {
                          final text = _formatLogForCopy(log);
                          Clipboard.setData(ClipboardData(text: text));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Log entry copied to clipboard'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        },
                        icon: const Icon(Icons.copy, size: 16),
                        label: const Text('Copy'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  String _formatLogForCopy(LogEntry log) {
    final buffer = StringBuffer();
    buffer.writeln('Timestamp: ${log.timestamp.toIso8601String()}');
    buffer.writeln('Level: ${log.level.name.toUpperCase()}');
    if (log.category != null) {
      buffer.writeln('Category: ${log.category}');
    }
    buffer.writeln('Message: ${log.message}');
    if (log.context != null) {
      buffer.writeln('Context: ${log.context}');
    }
    if (log.stackTrace != null) {
      buffer.writeln('Stack Trace:\n${log.stackTrace}');
    }
    return buffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    final categories = _loggingService.categories;
    
    return Scaffold(
      backgroundColor: darkBackground,
      appBar: AppBar(
        backgroundColor: efficialsBlack,
        title: const Text(
          'Debug Console',
          style: TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _autoScroll ? Icons.vertical_align_bottom : Icons.vertical_align_center,
              color: Colors.white,
            ),
            onPressed: () {
              setState(() {
                _autoScroll = !_autoScroll;
              });
            },
            tooltip: _autoScroll ? 'Disable auto-scroll' : 'Enable auto-scroll',
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _refreshLogs,
            tooltip: 'Refresh logs',
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onSelected: (value) async {
              switch (value) {
                case 'clear':
                  await _loggingService.clearLogs();
                  _refreshLogs();
                  break;
                case 'export':
                  await _loggingService.exportLogs();
                  if (mounted) {
                    // ignore: use_build_context_synchronously
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Logs exported to storage'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  }
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'clear',
                child: ListTile(
                  leading: Icon(Icons.clear_all),
                  title: Text('Clear Logs'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'export',
                child: ListTile(
                  leading: Icon(Icons.download),
                  title: Text('Export Logs'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Filters
          Container(
            padding: const EdgeInsets.all(16),
            color: darkSurface,
            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<LogLevel?>(
                    value: _selectedLevel,
                    decoration: const InputDecoration(
                      labelText: 'Min Level',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    items: [
                      const DropdownMenuItem<LogLevel?>(
                        value: null,
                        child: Text('All'),
                      ),
                      ...LogLevel.values.map((level) => DropdownMenuItem<LogLevel?>(
                        value: level,
                        child: Text(level.name.toUpperCase()),
                      )),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedLevel = value;
                      });
                      _refreshLogs();
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<String?>(
                    value: _selectedCategory,
                    decoration: const InputDecoration(
                      labelText: 'Category',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    items: [
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('All'),
                      ),
                      ...categories.map((category) => DropdownMenuItem<String?>(
                        value: category,
                        child: Text(category),
                      )),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedCategory = value;
                      });
                      _refreshLogs();
                    },
                  ),
                ),
              ],
            ),
          ),
          // Stats
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: darkBackground,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total: ${_loggingService.logCount} | Filtered: ${_filteredLogs.length}',
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 12,
                  ),
                ),
                if (_loggingService.isEnabled)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'LOGGING ENABLED',
                      style: TextStyle(
                        color: Colors.green,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'LOGGING DISABLED',
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          // Log entries
          Expanded(
            child: _filteredLogs.isEmpty
                ? const Center(
                    child: Text(
                      'No logs found',
                      style: TextStyle(
                        color: secondaryTextColor,
                        fontSize: 16,
                      ),
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    reverse: true,
                    itemCount: _filteredLogs.length,
                    itemBuilder: (context, index) {
                      return _buildLogEntry(_filteredLogs[index]);
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Add a test log entry
          _loggingService.info(
            'Test log entry from Debug Console',
            category: 'Debug',
            context: {
              'timestamp': DateTime.now().toIso8601String(),
              'user_action': 'manual_test',
              'screen': 'debug_console',
            },
          );
          _refreshLogs();
        },
        backgroundColor: efficialsBlue,
        tooltip: 'Add test log',
        child: const Icon(Icons.add),
      ),
    );
  }
}