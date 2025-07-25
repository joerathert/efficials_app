import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../shared/theme.dart';
import '../../shared/services/database_helper.dart';

class FilterCrewsScreen extends StatefulWidget {
  const FilterCrewsScreen({super.key});

  @override
  State<FilterCrewsScreen> createState() => _FilterCrewsScreenState();
}

class _FilterCrewsScreenState extends State<FilterCrewsScreen> {
  // IHSA Certification levels for crews (based on lowest common level)
  bool ihsaRegistered = false;
  bool ihsaRecognized = false;
  bool ihsaCertified = false;
  
  // Competition levels that crews have selected during creation
  final Map<String, bool> competitionLevels = {
    'Grade School (6U-11U)': false,
    'Middle School (11U-14U)': false,
    'Underclass (15U-16U)': false,
    'Junior Varsity (16U-17U)': false,
    'Varsity (17U-18U)': false,
    'College': false,
    'Adult': false,
  };
  
  // Distance filter based on crew chief's address
  final _radiusController = TextEditingController();
  String? defaultLocationName;
  String? defaultLocationAddress;

  @override
  void initState() {
    super.initState();
    _loadDefaultLocation();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadCurrentFilters();
  }

  Future<void> _loadDefaultLocation() async {
    try {
      final db = await DatabaseHelper().database;
      final adResult = await db.query(
        'users',
        columns: ['school_name', 'school_address'],
        where: 'user_type = ?',
        whereArgs: ['scheduler'],
        limit: 1,
      );

      if (adResult.isNotEmpty) {
        setState(() {
          defaultLocationName = adResult.first['school_name'] as String?;
          defaultLocationAddress = adResult.first['school_address'] as String?;
        });
      }
    } catch (e) {
      print('Error loading default location: $e');
    }
  }

  void _loadCurrentFilters() {
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final currentFilters = args?['currentFilters'] as Map<String, dynamic>?;
    
    if (currentFilters != null) {
      setState(() {
        ihsaRegistered = currentFilters['ihsaRegistered'] ?? false;
        ihsaRecognized = currentFilters['ihsaRecognized'] ?? false;
        ihsaCertified = currentFilters['ihsaCertified'] ?? false;
        _radiusController.text = currentFilters['radius']?.toString() ?? '';
        
        // Load competition levels
        final levels = currentFilters['competitionLevels'] as Map<String, dynamic>?;
        if (levels != null) {
          competitionLevels.forEach((key, _) {
            competitionLevels[key] = levels[key] ?? false;
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: darkBackground,
      appBar: AppBar(
        backgroundColor: efficialsBlack,
        title: const Text(
          'Filter Crews',
          style: TextStyle(color: efficialsWhite),
        ),
        iconTheme: const IconThemeData(color: efficialsWhite),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildIHSACertificationSection(),
            const SizedBox(height: 24),
            _buildCompetitionLevelsSection(),
            const SizedBox(height: 24),
            _buildDistanceSection(),
            const SizedBox(height: 32),
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildIHSACertificationSection() {
    return Card(
      color: efficialsBlack,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'IHSA Certification Level',
              style: TextStyle(
                color: efficialsWhite,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Filter crews by their lowest common certification level',
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),
            CheckboxListTile(
              title: const Text(
                'IHSA Registered',
                style: TextStyle(color: efficialsWhite),
              ),
              subtitle: Text(
                'All crew members have at least Registered certification',
                style: TextStyle(color: Colors.grey[400], fontSize: 12),
              ),
              value: ihsaRegistered,
              activeColor: efficialsYellow,
              checkColor: efficialsBlack,
              onChanged: (value) {
                setState(() {
                  ihsaRegistered = value ?? false;
                });
              },
            ),
            CheckboxListTile(
              title: const Text(
                'IHSA Recognized',
                style: TextStyle(color: efficialsWhite),
              ),
              subtitle: Text(
                'All crew members have at least Recognized certification',
                style: TextStyle(color: Colors.grey[400], fontSize: 12),
              ),
              value: ihsaRecognized,
              activeColor: efficialsYellow,
              checkColor: efficialsBlack,
              onChanged: (value) {
                setState(() {
                  ihsaRecognized = value ?? false;
                });
              },
            ),
            CheckboxListTile(
              title: const Text(
                'IHSA Certified',
                style: TextStyle(color: efficialsWhite),
              ),
              subtitle: Text(
                'All crew members have Certified certification',
                style: TextStyle(color: Colors.grey[400], fontSize: 12),
              ),
              value: ihsaCertified,
              activeColor: efficialsYellow,
              checkColor: efficialsBlack,
              onChanged: (value) {
                setState(() {
                  ihsaCertified = value ?? false;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompetitionLevelsSection() {
    return Card(
      color: efficialsBlack,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Competition Levels',
              style: TextStyle(
                color: efficialsWhite,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Show crews that have selected these competition levels',
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),
            ...competitionLevels.entries.map((entry) {
              return CheckboxListTile(
                title: Text(
                  entry.key,
                  style: const TextStyle(color: efficialsWhite),
                ),
                value: entry.value,
                activeColor: efficialsYellow,
                checkColor: efficialsBlack,
                onChanged: (value) {
                  setState(() {
                    competitionLevels[entry.key] = value ?? false;
                  });
                },
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildDistanceSection() {
    return Card(
      color: efficialsBlack,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Distance from Game Location',
              style: TextStyle(
                color: efficialsWhite,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Filter based on crew chief\'s home address',
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 14,
              ),
            ),
            if (defaultLocationName != null) ...[
              const SizedBox(height: 8),
              Text(
                'Game location: $defaultLocationName',
                style: TextStyle(
                  color: Colors.grey[300],
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
            const SizedBox(height: 16),
            TextField(
              controller: _radiusController,
              style: const TextStyle(color: efficialsWhite),
              decoration: InputDecoration(
                labelText: 'Maximum distance (miles)',
                labelStyle: TextStyle(color: Colors.grey[400]),
                hintText: 'e.g., 25',
                hintStyle: TextStyle(color: Colors.grey[600]),
                filled: true,
                fillColor: darkBackground,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: efficialsYellow),
                ),
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(3),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: _clearFilters,
            style: OutlinedButton.styleFrom(
              foregroundColor: efficialsWhite,
              side: const BorderSide(color: efficialsWhite),
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: const Text('Clear All'),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton(
            onPressed: _applyFilters,
            style: ElevatedButton.styleFrom(
              backgroundColor: efficialsYellow,
              foregroundColor: efficialsBlack,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: const Text('Apply Filters'),
          ),
        ),
      ],
    );
  }

  void _clearFilters() {
    setState(() {
      ihsaRegistered = false;
      ihsaRecognized = false;
      ihsaCertified = false;
      _radiusController.clear();
      competitionLevels.updateAll((key, value) => false);
    });
  }

  void _applyFilters() {
    final filters = <String, dynamic>{};
    
    // Add IHSA certification filters
    if (ihsaRegistered) filters['ihsaRegistered'] = true;
    if (ihsaRecognized) filters['ihsaRecognized'] = true;
    if (ihsaCertified) filters['ihsaCertified'] = true;
    
    // Add competition level filters
    final selectedLevels = competitionLevels.entries
        .where((entry) => entry.value)
        .map((entry) => entry.key)
        .toList();
    if (selectedLevels.isNotEmpty) {
      filters['competitionLevels'] = competitionLevels;
    }
    
    // Add distance filter
    final radiusText = _radiusController.text.trim();
    if (radiusText.isNotEmpty) {
      final radius = int.tryParse(radiusText);
      if (radius != null && radius > 0) {
        filters['radius'] = radius;
      }
    }
    
    Navigator.pop(context, filters);
  }

  @override
  void dispose() {
    _radiusController.dispose();
    super.dispose();
  }
}