import 'package:flutter/material.dart';
import '../../shared/theme.dart';
import '../../shared/services/repositories/crew_repository.dart';
import '../../shared/services/repositories/official_repository.dart';
import '../../shared/services/user_session_service.dart';
import '../../shared/models/database_models.dart';
import '../../shared/services/database_helper.dart';

class CreateCrewScreen extends StatefulWidget {
  const CreateCrewScreen({super.key});

  @override
  State<CreateCrewScreen> createState() => _CreateCrewScreenState();
}

class _CreateCrewScreenState extends State<CreateCrewScreen> {
  final CrewRepository _crewRepo = CrewRepository();
  final OfficialRepository _officialRepo = OfficialRepository();
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();

  List<CrewType> _crewTypes = [];
  CrewType? _selectedCrewType;
  List<String> _selectedCompetitionLevels = [];
  bool _isLoading = true;
  int? _currentUserId;

  final List<String> _competitionLevels = [
    'Grade School (6U-11U)',
    'Middle School (11U-14U)',
    'Underclass (15U-16U)',
    'Junior Varsity (16U-17U)',
    'Varsity (17U-18U)',
    'College',
    'Adult',
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      print('Starting to load create crew data...');
      setState(() {
        _isLoading = true;
      });

      print('Getting user session...');
      final userSession = UserSessionService.instance;
      _currentUserId = await userSession.getCurrentUserId();
      print('Current user ID: $_currentUserId');

      print('Loading crew types...');
      final crewTypes = await _crewRepo.getAllCrewTypes();

      print('Loaded ${crewTypes.length} crew types');
      
      if (crewTypes.isEmpty) {
        print('WARNING: No crew types found in database');
        await _debugDatabaseState();
      }

      if (mounted) {
        setState(() {
          _crewTypes = crewTypes;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading data: $e');
      print('Stack trace: ${StackTrace.current}');
      
      // Check if it's a missing table error
      if (e.toString().contains('no such table: crew_types')) {
        print('Crew types table missing - forcing database upgrade...');
        try {
          await DatabaseHelper().forceUpgrade();
          print('Database upgrade completed, retrying data load...');
          await _loadData(); // Retry loading data
          return;
        } catch (upgradeError) {
          print('Database upgrade failed: $upgradeError');
        }
      }
      
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _showErrorDialog('Failed to load data: ${e.toString()}');
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
          'Create New Crew',
          style: TextStyle(color: efficialsWhite),
        ),
        iconTheme: const IconThemeData(color: efficialsWhite),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: efficialsYellow),
            )
          : _buildForm(),
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildCrewNameField(),
          const SizedBox(height: 24),
          _buildCrewTypeSelector(),
          const SizedBox(height: 24),
          if (_selectedCrewType != null) ...[
            _buildRequiredMembersInfo(),
            const SizedBox(height: 24),
            _buildCompetitionLevelsSelector(),
            const SizedBox(height: 32),
            _buildNextButton(),
          ],
        ],
      ),
    );
  }

  Widget _buildCrewNameField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Crew Name',
          style: TextStyle(
            color: efficialsWhite,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _nameController,
          style: const TextStyle(color: efficialsWhite),
          decoration: InputDecoration(
            hintText: 'Enter crew name (e.g., "Smith Football Crew")',
            hintStyle: TextStyle(color: Colors.grey[600]),
            filled: true,
            fillColor: efficialsBlack,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: efficialsYellow),
            ),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter a crew name';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildCrewTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Sport',
          style: TextStyle(
            color: efficialsWhite,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: efficialsBlack,
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<CrewType>(
              value: _selectedCrewType,
              hint: Text(
                'Select sport and crew size',
                style: TextStyle(color: Colors.grey[600]),
              ),
              dropdownColor: efficialsBlack,
              style: const TextStyle(color: efficialsWhite),
              items: _crewTypes.isEmpty 
                  ? [
                      DropdownMenuItem<CrewType>(
                        value: null,
                        child: Text(
                          'No crew types available - check database setup',
                          style: TextStyle(color: Colors.red[300]),
                        ),
                      )
                    ]
                  : _crewTypes.map((crewType) {
                      return DropdownMenuItem<CrewType>(
                        value: crewType,
                        child: Text(
                          '${crewType.sportName} - ${crewType.requiredOfficials} Officials',
                        ),
                      );
                    }).toList(),
              onChanged: (CrewType? newValue) {
                setState(() {
                  _selectedCrewType = newValue;
                  _selectedCompetitionLevels.clear(); // Reset competition levels
                });
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRequiredMembersInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: efficialsYellow.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: efficialsYellow.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.info_outline,
            color: efficialsYellow,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'This crew requires exactly ${_selectedCrewType!.requiredOfficials} members including yourself as crew chief.',
              style: const TextStyle(
                color: efficialsWhite,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompetitionLevelsSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Competition Levels',
          style: TextStyle(
            color: efficialsWhite,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Select the competition levels this crew can officiate:',
          style: TextStyle(
            color: Colors.grey[400],
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          constraints: const BoxConstraints(maxHeight: 250),
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: _competitionLevels.length,
            itemBuilder: (context, index) {
              final level = _competitionLevels[index];
              final isSelected = _selectedCompetitionLevels.contains(level);

              return CheckboxListTile(
                title: Text(
                  level,
                  style: const TextStyle(color: efficialsWhite),
                ),
                value: isSelected,
                activeColor: efficialsYellow,
                checkColor: efficialsBlack,
                tileColor: isSelected ? efficialsYellow.withOpacity(0.1) : null,
                onChanged: (bool? value) {
                  setState(() {
                    if (value == true) {
                      _selectedCompetitionLevels.add(level);
                    } else {
                      _selectedCompetitionLevels.remove(level);
                    }
                  });
                },
              );
            },
          ),
        ),
        if (_selectedCompetitionLevels.isEmpty)
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(top: 8),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red.withOpacity(0.3)),
            ),
            child: const Row(
              children: [
                Icon(Icons.error_outline, color: Colors.red, size: 16),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'At least one competition level is required.',
                    style: TextStyle(color: Colors.red, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildNextButton() {
    final canProceed = _selectedCrewType != null && _selectedCompetitionLevels.isNotEmpty;
    
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: canProceed ? _proceedToMemberSelection : null,
        icon: const Icon(Icons.arrow_forward, size: 20),
        label: const Text(
          'Next: Select Members',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: canProceed ? efficialsYellow : Colors.grey[700],
          foregroundColor: efficialsBlack,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }

  void _proceedToMemberSelection() {
    if (!_formKey.currentState!.validate()) {
      _showValidationError('Please fix the form errors before proceeding.');
      return;
    }

    if (_currentUserId == null) {
      _showValidationError('User session error. Please log in again.');
      return;
    }

    if (_selectedCrewType == null) {
      _showValidationError('Please select a sport and crew type.');
      return;
    }

    if (_selectedCompetitionLevels.isEmpty) {
      _showValidationError('Please select at least one competition level.');
      return;
    }

    Navigator.pushNamed(
      context,
      '/select_crew_members',
      arguments: {
        'crewName': _nameController.text.trim(),
        'crewType': _selectedCrewType!,
        'competitionLevels': _selectedCompetitionLevels,
        'currentUserId': _currentUserId!,
      },
    );
  }


  void _showValidationError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: efficialsBlack,
        title: const Text(
          'Error',
          style: TextStyle(color: efficialsWhite),
        ),
        content: Text(
          message,
          style: const TextStyle(color: efficialsWhite),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'OK',
              style: TextStyle(color: efficialsYellow),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _debugDatabaseState() async {
    try {
      // Check sports table
      final sportsCount = await _crewRepo.rawQuery('SELECT COUNT(*) as count FROM sports');
      final crewTypesCount = await _crewRepo.rawQuery('SELECT COUNT(*) as count FROM crew_types');
      
      print('Sports count: ${sportsCount.first['count']}');
      print('Crew types count: ${crewTypesCount.first['count']}');
      
      if (sportsCount.first['count'] == 0) {
        print('Sports table is empty - initializing default sports...');
        await _initializeDefaultSports();
      }
      
      if (crewTypesCount.first['count'] == 0) {
        print('Crew types table is empty - initializing default crew types...');
        await _initializeDefaultCrewTypes();
        
        // Reload crew types after initialization
        final newCrewTypes = await _crewRepo.getAllCrewTypes();
        if (mounted) {
          setState(() {
            _crewTypes = newCrewTypes;
          });
        }
        print('Reloaded ${newCrewTypes.length} crew types after initialization');
      }
    } catch (e) {
      print('Error debugging database state: $e');
    }
  }

  Future<void> _initializeDefaultSports() async {
    final sports = [
      'Football', 'Basketball', 'Baseball', 'Softball', 'Soccer', 
      'Volleyball', 'Tennis', 'Track & Field', 'Swimming', 'Wrestling',
      'Cross Country', 'Golf', 'Hockey', 'Lacrosse'
    ];
    
    for (final sport in sports) {
      await _crewRepo.rawQuery('INSERT OR IGNORE INTO sports (name) VALUES (?)', [sport]);
    }
    print('✅ Default sports initialized');
  }

  Future<void> _initializeDefaultCrewTypes() async {
    // Get sport IDs
    final sportsQuery = await _crewRepo.rawQuery('SELECT id, name FROM sports');
    final sportMap = Map.fromIterable(sportsQuery,
        key: (s) => s['name'], value: (s) => s['id']);

    final defaultCrewTypes = [
      {'sport': 'Football', 'level': 'Varsity', 'officials': 5, 'desc': 'Varsity Football - 5 Officials'},
      {'sport': 'Football', 'level': 'Underclass', 'officials': 4, 'desc': 'JV/Freshman Football - 4 Officials'},
      {'sport': 'Baseball', 'level': 'All', 'officials': 2, 'desc': 'All Baseball Levels - 2 Officials'},
      {'sport': 'Basketball', 'level': 'Varsity', 'officials': 3, 'desc': 'Varsity Basketball - 3 Officials'},
      {'sport': 'Basketball', 'level': 'JV', 'officials': 3, 'desc': 'JV Basketball - 3 Officials'},
      {'sport': 'Basketball', 'level': 'Other', 'officials': 2, 'desc': 'Freshman/Middle School Basketball - 2 Officials'},
    ];

    for (final crewType in defaultCrewTypes) {
      final sportId = sportMap[crewType['sport']];
      if (sportId != null) {
        await _crewRepo.rawQuery('''
          INSERT OR IGNORE INTO crew_types (sport_id, level_of_competition, required_officials, description)
          VALUES (?, ?, ?, ?)
        ''', [sportId, crewType['level'], crewType['officials'], crewType['desc']]);
      }
    }
    print('✅ Default crew types initialized');
  }
}