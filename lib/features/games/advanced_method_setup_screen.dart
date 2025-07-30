import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../shared/theme.dart';
import '../../shared/models/database_models.dart';
import '../../shared/services/repositories/official_repository.dart';
import '../../shared/services/repositories/advanced_method_repository.dart';
import '../../shared/services/user_session_service.dart';

class AdvancedMethodSetupScreen extends StatefulWidget {
  const AdvancedMethodSetupScreen({super.key});

  @override
  State<AdvancedMethodSetupScreen> createState() => _AdvancedMethodSetupScreenState();
}

class _AdvancedMethodSetupScreenState extends State<AdvancedMethodSetupScreen> {
  final OfficialRepository _officialRepo = OfficialRepository();
  final AdvancedMethodRepository _advancedRepo = AdvancedMethodRepository();
  
  List<Map<String, dynamic>> availableLists = [];
  List<QuotaSetup> quotaSetups = [];
  bool _isLoading = true;
  bool _isSaving = false;
  
  int? gameId;
  String? sportName;
  int? currentUserId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null) {
      gameId = args['gameId'] as int?;
      sportName = args['sportName'] as String?;
      _loadData();
    }
  }

  Future<void> _loadData() async {
    if (gameId == null) return;
    
    try {
      setState(() => _isLoading = true);
      
      // Get current user
      final userSession = UserSessionService.instance;
      currentUserId = await userSession.getCurrentUserId();
      
      if (currentUserId == null) return;

      // Get available lists for this sport
      final listsCount = await _officialRepo.getListsCountBySport(currentUserId!, sportName ?? '');
      
      if (listsCount > 0) {
        // Get actual list data
        final results = await _officialRepo.rawQuery('''
          SELECT ol.id, ol.name, COUNT(olm.official_id) as member_count
          FROM official_lists ol
          LEFT JOIN official_list_members olm ON ol.id = olm.list_id
          INNER JOIN sports s ON ol.sport_id = s.id
          WHERE ol.user_id = ? AND s.name = ?
          GROUP BY ol.id, ol.name
          ORDER BY ol.name ASC
        ''', [currentUserId!, sportName ?? '']);
        
        availableLists = results;
      }

      // Load existing quotas if any
      final existingQuotas = await _advancedRepo.getGameListQuotas(gameId!);
      
      if (existingQuotas.isNotEmpty) {
        // Convert existing quotas to setup objects
        quotaSetups = existingQuotas.map((quota) => QuotaSetup(
          listId: quota.listId,
          listName: quota.listName ?? 'Unknown List',
          minOfficials: quota.minOfficials,
          maxOfficials: quota.maxOfficials,
        )).toList();
      } else {
        // Initialize with available lists
        quotaSetups = availableLists.map((list) => QuotaSetup(
          listId: list['id'] as int,
          listName: list['name'] as String,
          minOfficials: 0,
          maxOfficials: 0,
        )).toList();
      }

      setState(() => _isLoading = false);
    } catch (e) {
      debugPrint('Error loading data: $e');
      setState(() => _isLoading = false);
      _showErrorDialog('Error loading data: $e');
    }
  }

  Future<void> _saveQuotas() async {
    if (gameId == null) return;

    // Validate quotas
    final validationError = _validateQuotas();
    if (validationError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(validationError), backgroundColor: Colors.red),
      );
      return;
    }

    try {
      setState(() => _isSaving = true);

      // Convert quota setups to database format
      final quotas = quotaSetups.map((setup) => {
        'listId': setup.listId,
        'minOfficials': setup.minOfficials,
        'maxOfficials': setup.maxOfficials,
      }).toList();

      // Save quotas
      await _advancedRepo.setGameListQuotas(gameId!, quotas);

      // Update game method to 'advanced'
      await _advancedRepo.update(
        'games',
        {
          'method': 'advanced',
          'updated_at': DateTime.now().toIso8601String(),
        },
        'id = ?',
        [gameId!],
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Advanced Method quotas saved successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context, true); // Return success
      
    } catch (e) {
      debugPrint('Error saving quotas: $e');
      _showErrorDialog('Error saving quotas: $e');
    } finally {
      setState(() => _isSaving = false);
    }
  }

  String? _validateQuotas() {
    if (quotaSetups.isEmpty) {
      return 'No official lists available. Please create official lists first.';
    }

    int totalMin = 0;
    int totalMax = 0;

    for (final quota in quotaSetups) {
      if (quota.minOfficials < 0) {
        return 'Minimum officials cannot be negative for ${quota.listName}';
      }
      
      if (quota.maxOfficials < quota.minOfficials) {
        return 'Maximum cannot be less than minimum for ${quota.listName}';
      }

      // Only count if this quota is actually used (max > 0)
      if (quota.maxOfficials > 0) {
        totalMin += quota.minOfficials;
        totalMax += quota.maxOfficials;
      }
    }

    if (totalMax == 0) {
      return 'At least one list must have a maximum greater than 0';
    }

    return null; // No validation errors
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: darkBackground,
      appBar: AppBar(
        backgroundColor: efficialsBlack,
        title: const Text(
          'Advanced Method Setup',
          style: TextStyle(color: efficialsWhite),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: efficialsWhite),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (!_isLoading && !_isSaving)
            TextButton(
              onPressed: _saveQuotas,
              child: const Text(
                'Save',
                style: TextStyle(
                  color: efficialsYellow,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildContent(),
    );
  }

  Widget _buildContent() {
    if (availableLists.isEmpty) {
      return _buildNoListsMessage();
    }

    return Column(
      children: [
        _buildHeader(),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: quotaSetups.length,
            itemBuilder: (context, index) => _buildQuotaCard(quotaSetups[index]),
          ),
        ),
        _buildSummary(),
        _buildSaveButton(),
      ],
    );
  }

  Widget _buildNoListsMessage() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.list_alt,
              size: 80,
              color: secondaryTextColor,
            ),
            const SizedBox(height: 16),
            Text(
              'No Official Lists Found',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: primaryTextColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              sportName != null 
                  ? 'You need to create official lists for $sportName before using the Advanced Method.'
                  : 'You need to create official lists before using the Advanced Method.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: secondaryTextColor,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/lists_of_officials', arguments: {
                  'sport': sportName ?? 'Unknown Sport',
                  'fromGameCreation': false,
                  'fromTemplateCreation': false,
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: efficialsYellow,
                foregroundColor: efficialsBlack,
              ),
              child: const Text('Create Official Lists'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      color: darkSurface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Set Quotas for $sportName Game',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: primaryTextColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Configure minimum and maximum officials from each list. This ensures proper experience distribution.',
            style: TextStyle(
              fontSize: 14,
              color: secondaryTextColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuotaCard(QuotaSetup quota) {
    final listInfo = availableLists.firstWhere(
      (list) => list['id'] == quota.listId,
      orElse: () => {'member_count': 0},
    );
    final memberCount = listInfo['member_count'] as int? ?? 0;

    return Card(
      color: darkSurface,
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    quota.listName,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: primaryTextColor,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: efficialsYellow.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$memberCount officials',
                    style: const TextStyle(
                      fontSize: 12,
                      color: efficialsYellow,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildNumberInput(
                    label: 'Minimum',
                    value: quota.minOfficials,
                    onChanged: (value) {
                      setState(() {
                        quota.minOfficials = value;
                      });
                    },
                    max: memberCount,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildNumberInput(
                    label: 'Maximum',
                    value: quota.maxOfficials,
                    onChanged: (value) {
                      setState(() {
                        quota.maxOfficials = value;
                      });
                    },
                    max: memberCount,
                  ),
                ),
              ],
            ),
            if (quota.maxOfficials > 0) ...[
              const SizedBox(height: 8),
              Text(
                quota.minOfficials == quota.maxOfficials
                    ? 'Exactly ${quota.minOfficials} official${quota.minOfficials == 1 ? '' : 's'} required'
                    : '${quota.minOfficials}-${quota.maxOfficials} officials allowed',
                style: TextStyle(
                  fontSize: 12,
                  color: secondaryTextColor,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildNumberInput({
    required String label,
    required int value,
    required ValueChanged<int> onChanged,
    required int max,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: primaryTextColor,
          ),
        ),
        const SizedBox(height: 4),
        TextFormField(
          initialValue: value.toString(),
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          style: TextStyle(color: primaryTextColor),
          decoration: InputDecoration(
            filled: true,
            fillColor: darkBackground,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: secondaryTextColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: secondaryTextColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: efficialsYellow),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          onChanged: (text) {
            final newValue = int.tryParse(text) ?? 0;
            final clampedValue = newValue.clamp(0, max);
            onChanged(clampedValue);
          },
        ),
      ],
    );
  }

  Widget _buildSummary() {
    final activeQuotas = quotaSetups.where((q) => q.maxOfficials > 0).toList();
    final totalMin = activeQuotas.fold<int>(0, (sum, q) => sum + q.minOfficials);
    final totalMax = activeQuotas.fold<int>(0, (sum, q) => sum + q.maxOfficials);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      decoration: BoxDecoration(
        color: darkSurface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: efficialsYellow.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Summary',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: primaryTextColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Total Officials: $totalMin minimum, $totalMax maximum',
            style: TextStyle(
              fontSize: 14,
              color: secondaryTextColor,
            ),
          ),
          Text(
            'Active Lists: ${activeQuotas.length}',
            style: TextStyle(
              fontSize: 14,
              color: secondaryTextColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      child: ElevatedButton(
        onPressed: _isSaving ? null : _saveQuotas,
        style: ElevatedButton.styleFrom(
          backgroundColor: efficialsYellow,
          foregroundColor: efficialsBlack,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: _isSaving
            ? const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(efficialsBlack),
                    ),
                  ),
                  SizedBox(width: 8),
                  Text('Saving...'),
                ],
              )
            : const Text(
                'Save Advanced Method Setup',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }
}

class QuotaSetup {
  final int listId;
  final String listName;
  int minOfficials;
  int maxOfficials;

  QuotaSetup({
    required this.listId,
    required this.listName,
    required this.minOfficials,
    required this.maxOfficials,
  });
}