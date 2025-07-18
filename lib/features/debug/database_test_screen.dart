import 'package:flutter/material.dart';
import '../../shared/theme.dart';
import '../../shared/services/migration_service.dart';

class DatabaseTestScreen extends StatefulWidget {
  const DatabaseTestScreen({super.key});

  @override
  State<DatabaseTestScreen> createState() => _DatabaseTestScreenState();
}

class _DatabaseTestScreenState extends State<DatabaseTestScreen> {
  Map<String, dynamic> migrationStatus = {};
  bool isLoading = true;
  String testResult = '';

  @override
  void initState() {
    super.initState();
    _loadMigrationStatus();
  }

  Future<void> _loadMigrationStatus() async {
    try {
      final status = await MigrationService().getMigrationStatus();
      setState(() {
        migrationStatus = status;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        testResult = 'Error loading migration status: $e';
        isLoading = false;
      });
    }
  }

  Future<void> _testDatabase() async {
    setState(() {
      isLoading = true;
      testResult = 'Testing database functionality...';
    });

    try {
      final success = await MigrationService().testDatabaseFunctionality();
      setState(() {
        testResult = success 
          ? 'Database test completed successfully!' 
          : 'Database test failed!';
        isLoading = false;
      });
      
      // Reload status after test
      await _loadMigrationStatus();
    } catch (e) {
      setState(() {
        testResult = 'Database test error: $e';
        isLoading = false;
      });
    }
  }

  Future<void> _forceMigration() async {
    setState(() {
      isLoading = true;
      testResult = 'Running migration...';
    });

    try {
      await MigrationService().forceMigration();
      setState(() {
        testResult = 'Migration completed successfully!';
        isLoading = false;
      });
      
      // Reload status after migration
      await _loadMigrationStatus();
    } catch (e) {
      setState(() {
        testResult = 'Migration error: $e';
        isLoading = false;
      });
    }
  }

  Future<void> _resetDatabase() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Database'),
        content: const Text('This will delete all database data. Are you sure?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Reset'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() {
        isLoading = true;
        testResult = 'Resetting database...';
      });

      try {
        await MigrationService().resetDatabase();
        setState(() {
          testResult = 'Database reset completed!';
          isLoading = false;
        });
        
        // Reload status after reset
        await _loadMigrationStatus();
      } catch (e) {
        setState(() {
          testResult = 'Database reset error: $e';
          isLoading = false;
        });
      }
    }
  }

  Future<void> _clearTemplatesOnly() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Templates Only'),
        content: const Text('This will delete only game templates while preserving officials and other data. Are you sure?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Clear Templates'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() {
        isLoading = true;
        testResult = 'Clearing templates...';
      });

      try {
        await MigrationService().clearTemplatesOnly();
        setState(() {
          testResult = 'Templates cleared successfully! (Officials preserved)';
          isLoading = false;
        });
        
        // Reload status after clearing
        await _loadMigrationStatus();
      } catch (e) {
        setState(() {
          testResult = 'Template clearing error: $e';
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: darkBackground,
      appBar: AppBar(
        backgroundColor: efficialsBlack,
        title: const Text(
          'Database Test',
          style: TextStyle(color: efficialsWhite),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: efficialsWhite),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Database Migration Status',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: efficialsYellow,
                ),
              ),
              const SizedBox(height: 20),
              
              if (isLoading)
                const Center(child: CircularProgressIndicator(color: efficialsBlue))
              else
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildStatusCard(),
                        const SizedBox(height: 20),
                        _buildSharedPreferencesCard(),
                        const SizedBox(height: 20),
                        _buildActionButtons(),
                        if (testResult.isNotEmpty) ...[
                          const SizedBox(height: 20),
                          _buildTestResultCard(),
                        ],
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: darkSurface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Migration Status',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: primaryTextColor,
            ),
          ),
          const SizedBox(height: 12),
          _buildStatusRow(
            'Migration Completed',
            migrationStatus['migration_completed'] == true,
          ),
          _buildStatusRow(
            'Has User',
            migrationStatus['has_user'] == true,
          ),
        ],
      ),
    );
  }

  Widget _buildSharedPreferencesCard() {
    final spKeys = migrationStatus['shared_preferences_keys'] as Map<String, dynamic>? ?? {};
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: darkSurface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'SharedPreferences Data',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: primaryTextColor,
            ),
          ),
          const SizedBox(height: 12),
          ...spKeys.entries.map((entry) => _buildStatusRow(
            entry.key,
            entry.value == true,
          )),
        ],
      ),
    );
  }

  Widget _buildStatusRow(String label, bool isTrue) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            isTrue ? Icons.check_circle : Icons.cancel,
            color: isTrue ? Colors.green : Colors.red,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(color: primaryTextColor),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _testDatabase,
            style: elevatedButtonStyle(),
            child: const Text('Test Database Functionality'),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _forceMigration,
            style: elevatedButtonStyle(),
            child: const Text('Force Migration'),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _clearTemplatesOnly,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: const Text('Clear Templates Only'),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _resetDatabase,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Reset Database'),
          ),
        ),
      ],
    );
  }

  Widget _buildTestResultCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: darkSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: testResult.contains('error') || testResult.contains('failed')
            ? Colors.red
            : Colors.green,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Test Result',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: primaryTextColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            testResult,
            style: const TextStyle(color: primaryTextColor),
          ),
        ],
      ),
    );
  }
}