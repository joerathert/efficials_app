import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../shared/theme.dart';
import '../../shared/services/location_service.dart';
import '../../shared/services/repositories/user_repository.dart';
import '../../shared/services/repositories/crew_repository.dart';
import '../../shared/services/user_session_service.dart';
import '../../shared/services/schedule_service.dart';
import '../../shared/models/database_models.dart';

class BulkImportWizardScreen extends StatefulWidget {
  const BulkImportWizardScreen({super.key});

  @override
  State<BulkImportWizardScreen> createState() => _BulkImportWizardScreenState();
}

class _BulkImportWizardScreenState extends State<BulkImportWizardScreen> {
  final PageController _pageController = PageController();
  int currentStep = 0;
  
  // Step 1: Number of teams
  int numberOfTeams = 2;
  
  // Step 2: Global settings - simple checkboxes for "set globally or not"
  Map<String, bool> globalSettings = {
    'sport': true, // Always true for Assigners
    'gender': false,
    'competitionLevel': false, 
    'officialsRequired': false,
    'gameFee': false,
    'method': false,
    'hireAutomatically': false,
    'location': false,
    'teamName': false,
    'time': false,
  };
  
  // Global values
  Map<String, dynamic> globalValues = {};
  
  // Schedule settings (for variables not set globally)
  Map<String, bool> scheduleSettings = {};
  
  
  // Available options
  List<String> competitionLevels = [
    '6U', '7U', '8U', '9U', '10U', '11U', '12U', '13U', '14U', '15U', '16U', '17U', '18U',
    'Grade School', 'Middle School', 'Underclass', 'JV', 'Varsity', 'College', 'Adult'
  ];
  List<String> genderOptions = ['Boys', 'Girls', 'Co-ed'];
  List<String> adultGenderOptions = ['Men', 'Women', 'Co-ed'];
  List<int> officialsOptions = [1, 2, 3, 4, 5, 6, 7, 8, 9];
  List<String> methodOptions = ['Single List', 'Multiple Lists', 'Hire a Crew'];
  List<Map<String, dynamic>> availableLocations = [];
  List<Map<String, dynamic>> availableLists = [];
  List<Crew> availableCrews = [];
  
  // Secondary dropdown state
  String? selectedList;
  String? selectedCrew;
  List<Map<String, dynamic>> selectedMultipleLists = [];
  
  String? currentUserSport;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    try {
      await Future.wait([
        _loadUserSport(),
        _loadLocations(),
        _loadOfficialsLists(),
        _loadCrews(),
      ]);
      
      // Set default global values - start empty to show hints
      globalValues = {
        'sport': currentUserSport ?? 'Unknown', // Sport is locked, so keep this
        'gender': null,
        'competitionLevel': null,
        'officialsRequired': null,
        'gameFee': null,
        'method': null,
        'hireAutomatically': null,
        'location': null,
        'teamName': '',
        'time': null,
      };
      
      
      setState(() {
        isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading initial data: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _loadUserSport() async {
    try {
      final userRepository = UserRepository();
      final currentUser = await userRepository.getCurrentUser();
      setState(() {
        currentUserSport = currentUser?.sport ?? 'Unknown';
      });
    } catch (e) {
      debugPrint('Error loading user sport: $e');
    }
  }

  Future<void> _loadLocations() async {
    try {
      final locationService = LocationService();
      final locations = await locationService.getLocations();
      setState(() {
        availableLocations = List<Map<String, dynamic>>.from(locations);
      });
    } catch (e) {
      debugPrint('Error loading locations: $e');
    }
  }

  Future<void> _loadOfficialsLists() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? listsJson = prefs.getString('saved_lists');
      setState(() {
        availableLists.clear();
        if (listsJson != null && listsJson.isNotEmpty) {
          try {
            final decodedLists = jsonDecode(listsJson) as List<dynamic>;
            availableLists = decodedLists.map((list) {
              final listMap = Map<String, dynamic>.from(list as Map);
              if (listMap['officials'] != null) {
                listMap['officials'] = (listMap['officials'] as List<dynamic>)
                    .map((official) => Map<String, dynamic>.from(official as Map))
                    .toList();
              } else {
                listMap['officials'] = [];
              }
              return listMap;
            }).toList();
          } catch (e) {
            debugPrint('Error decoding lists: $e');
            availableLists = [];
          }
        }
        
        if (availableLists.isEmpty) {
          availableLists.add({'name': 'No saved lists', 'id': -1});
        }
        availableLists.add({'name': '+ Create new list', 'id': 0});
      });
    } catch (e) {
      debugPrint('Error loading officials lists: $e');
    }
  }

  Future<void> _loadCrews() async {
    try {
      final crewRepository = CrewRepository();
      final userSession = UserSessionService.instance;
      final currentUserId = await userSession.getCurrentUserId();
      
      if (currentUserId != null) {
        // Get all crews for the current user (as chief or member)
        final crewsAsChief = await crewRepository.getCrewsWhereChief(currentUserId);
        final crewsAsMember = await crewRepository.getCrewsForOfficial(currentUserId);
        
        // Combine and deduplicate crews
        final allCrews = <Crew>[];
        allCrews.addAll(crewsAsChief);
        
        for (final memberCrew in crewsAsMember) {
          if (!crewsAsChief.any((chiefCrew) => chiefCrew.id == memberCrew.id)) {
            allCrews.add(memberCrew);
          }
        }
        
        setState(() {
          availableCrews = allCrews;
        });
      }
    } catch (e) {
      debugPrint('Error loading crews: $e');
    }
  }

  void nextStep() {
    if (currentStep < 2) {
      setState(() {
        currentStep++;
      });
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void previousStep() {
    if (currentStep > 0) {
      setState(() {
        currentStep--;
      });
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void generateExcel() {
    final wizardConfig = {
      'numberOfTeams': numberOfTeams,
      'globalSettings': globalSettings,
      'globalValues': globalValues,
      'scheduleSettings': scheduleSettings,
      'selectedList': selectedList,
      'selectedCrew': selectedCrew,
      'selectedMultipleLists': selectedMultipleLists,
    };
    
    Navigator.pushNamed(
      context,
      '/bulk_import_generate',
      arguments: wizardConfig,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: darkBackground,
      appBar: AppBar(
        backgroundColor: efficialsBlack,
        title: Text(
          'Step ${currentStep + 1} of 3',
          style: const TextStyle(color: efficialsYellow, fontSize: 18),
        ),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: efficialsWhite),
          onPressed: currentStep == 0 ? () => Navigator.pop(context) : previousStep,
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: efficialsYellow))
          : PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildStep1(), // Number of teams
                _buildStep2(), // Global settings
                _buildStep3(), // Schedule settings
              ],
            ),
      bottomNavigationBar: isLoading
          ? null
          : Container(
              color: efficialsBlack,
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 16,
                bottom: MediaQuery.of(context).padding.bottom + 16,
              ),
              child: Row(
                children: [
                  if (currentStep > 0)
                    Expanded(
                      child: TextButton(
                        onPressed: previousStep,
                        child: const Text(
                          'Back',
                          style: TextStyle(color: efficialsYellow, fontSize: 16),
                        ),
                      ),
                    ),
                  if (currentStep > 0) const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: currentStep == 2 ? generateExcel : nextStep,
                      style: elevatedButtonStyle(),
                      child: Text(
                        currentStep == 2 ? 'Continue to Schedule Configuration' : 'Next',
                        style: signInButtonTextStyle,
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildStep1() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'How many team schedules?',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: efficialsYellow,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Each team will get its own sheet in the Excel file.',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 40),
          
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: darkSurface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      onPressed: numberOfTeams > 1 ? () => setState(() => numberOfTeams--) : null,
                      icon: const Icon(Icons.remove_circle_outline),
                      color: numberOfTeams > 1 ? efficialsYellow : Colors.grey,
                      iconSize: 40,
                    ),
                    Column(
                      children: [
                        Text(
                          numberOfTeams.toString(),
                          style: const TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                            color: efficialsYellow,
                          ),
                        ),
                        Text(
                          'team${numberOfTeams == 1 ? '' : 's'}',
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      onPressed: numberOfTeams < 20 ? () => setState(() => numberOfTeams++) : null,
                      icon: const Icon(Icons.add_circle_outline),
                      color: numberOfTeams < 20 ? efficialsYellow : Colors.grey,
                      iconSize: 40,
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  'You will create $numberOfTeams Excel sheet${numberOfTeams == 1 ? '' : 's'}:\n${List.generate(numberOfTeams, (index) => '• Team ${index + 1} Schedule').join('\n')}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep2() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Global Settings',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: efficialsYellow,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Check any settings that are the same for ALL teams. Leave unchecked to set per-team.',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 30),

          // Sport (always locked)
          _buildGlobalSettingTile(
            'sport',
            'Sport',
            (globalValues['sport'] ?? 'Unknown').toString(),
            enabled: false,
            description: 'Locked to your assigned sport',
          ),

          _buildGlobalSettingTile(
            'gender',
            'Gender',
            globalValues['gender']?.toString() ?? '',
            onValueChanged: (value) => globalValues['gender'] = value,
            options: _getGenderOptions(),
          ),

          _buildGlobalSettingTile(
            'competitionLevel',
            'Competition Level',
            globalValues['competitionLevel']?.toString() ?? '',
            onValueChanged: (value) => globalValues['competitionLevel'] = value,
            options: competitionLevels,
          ),

          _buildGlobalSettingTile(
            'officialsRequired',
            'Officials Required',
            globalValues['officialsRequired']?.toString() ?? '',
            onValueChanged: (value) => globalValues['officialsRequired'] = int.parse(value),
            options: officialsOptions.map((e) => e.toString()).toList(),
          ),

          _buildGlobalSettingTile(
            'gameFee',
            'Game Fee per Official',
            globalValues['gameFee']?.toString() ?? '',
            onValueChanged: (value) => globalValues['gameFee'] = value.replaceAll('\$', ''),
            isTextField: true,
          ),

          _buildGlobalSettingTile(
            'method',
            'Officials Assignment Method',
            globalValues['method']?.toString() ?? '',
            onValueChanged: (value) {
              setState(() {
                globalValues['method'] = value;
                // Clear secondary selections when method changes
                selectedList = null;
                selectedCrew = null;
                
                // Initialize Multiple Lists with 2 lists by default
                if (value == 'Multiple Lists') {
                  selectedMultipleLists = [
                    {'list': null, 'min': 0, 'max': 1},
                    {'list': null, 'min': 0, 'max': 1},
                  ];
                } else {
                  selectedMultipleLists.clear();
                }
              });
            },
            options: methodOptions,
            hasSecondaryDropdown: true,
          ),

          _buildGlobalSettingTile(
            'location',
            'Home Location',
            globalValues['location']?.toString() ?? '',
            onValueChanged: (value) => globalValues['location'] = value,
            options: availableLocations.map((loc) => loc['name'] as String).toList(),
          ),

          _buildGlobalSettingTile(
            'teamName',
            'Team Name',
            globalValues['teamName']?.toString() ?? '',
            onValueChanged: (value) => globalValues['teamName'] = value,
            isTeamNameDropdown: true,
            description: 'Use same team name for all schedules',
          ),

          _buildGlobalSettingTile(
            'hireAutomatically',
            'Hire Automatically',
            globalValues['hireAutomatically'] == null 
                ? ''
                : (globalValues['hireAutomatically'] as bool ? 'Yes' : 'No'),
            onValueChanged: (value) => globalValues['hireAutomatically'] = value == 'Yes',
            options: ['Yes', 'No'],
          ),

          _buildGlobalSettingTile(
            'time',
            'Game Time',
            globalValues['time']?.toString() ?? '',
            onValueChanged: (value) => globalValues['time'] = value,
            isTextField: true,
            description: 'Use same start time for all games',
          ),
        ],
      ),
    );
  }

  Widget _buildStep3() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Schedule Settings',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: efficialsYellow,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'For variables not set globally, choose whether to set per-schedule or per-game.',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 30),

          // Show checkboxes for variables not set globally
          ...(_getUnsetGlobalVariables().map((variable) => _buildScheduleSettingTile(variable))),

          if (_getUnsetGlobalVariables().isEmpty) ...[
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.withOpacity(0.3)),
              ),
              child: const Column(
                children: [
                  Icon(Icons.check_circle, color: Colors.green, size: 48),
                  SizedBox(height: 12),
                  Text(
                    'All Variables Set Globally',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'You\'ve set all variables globally. Only Schedule Name will vary per-schedule.',
                    style: TextStyle(fontSize: 14, color: Colors.white70),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 30),

          // Summary of what will be columns
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: efficialsYellow.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: efficialsYellow.withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Game Columns (Row-by-row entry)',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: efficialsYellow,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Everything else will be column headers in your Excel sheets:\n'
                  '• Date (required)\n'
                  '• Time (required)\n'
                  '• Opponent (required)\n'
                  '• Away Game (Yes/No)${_getAdditionalColumns()}',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getAdditionalColumns() {
    List<String> columns = [];
    
    if (!(globalSettings['gender'] ?? false) && !(scheduleSettings['gender'] ?? false)) {
      columns.add('• Gender');
    }
    if (!(globalSettings['competitionLevel'] ?? false) && !(scheduleSettings['competitionLevel'] ?? false)) {
      columns.add('• Competition Level');
    }
    if (!(globalSettings['officialsRequired'] ?? false) && !(scheduleSettings['officialsRequired'] ?? false)) {
      columns.add('• Officials Required');
    }
    if (!(globalSettings['gameFee'] ?? false) && !(scheduleSettings['gameFee'] ?? false)) {
      columns.add('• Game Fee');
    }
    if (!(globalSettings['method'] ?? false) && !(scheduleSettings['method'] ?? false)) {
      columns.add('• Officials Method');
    }
    if (!(globalSettings['hireAutomatically'] ?? false) && !(scheduleSettings['hireAutomatically'] ?? false)) {
      columns.add('• Hire Automatically');
    }
    
    return columns.isEmpty ? '' : '\n${columns.join('\n')}';
  }

  List<String> _getGenderOptions() {
    final competitionLevel = globalValues['competitionLevel'] as String? ?? 'Varsity';
    return (competitionLevel == 'College' || competitionLevel == 'Adult')
        ? adultGenderOptions
        : genderOptions;
  }

  List<String> _getUnsetGlobalVariables() {
    List<String> unsetVariables = [];
    final variableKeys = ['gender', 'competitionLevel', 'officialsRequired', 'gameFee', 'method', 'location', 'teamName', 'hireAutomatically', 'time'];
    
    for (String key in variableKeys) {
      if (!(globalSettings[key] ?? false)) {
        unsetVariables.add(key);
      }
    }
    
    return unsetVariables;
  }

  String _getVariableDisplayName(String key) {
    switch (key) {
      case 'gender': return 'Gender';
      case 'competitionLevel': return 'Competition Level';
      case 'officialsRequired': return 'Officials Required';
      case 'gameFee': return 'Game Fee per Official';
      case 'method': return 'Officials Assignment Method';
      case 'location': return 'Location';
      case 'teamName': return 'Team Name';
      case 'hireAutomatically': return 'Hire Automatically';
      case 'time': return 'Game Time';
      default: return key;
    }
  }
  
  Widget _buildTeamNameDropdownForGlobal(String currentValue, Function(String) onValueChanged) {
    return FutureBuilder<List<String>>(
      future: _loadTeamNamesForGlobal(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const CircularProgressIndicator(color: efficialsYellow);
        }
        
        final teamNames = snapshot.data!;
        
        // Create dropdown with option to add new team
        final allOptions = [...teamNames, '+ Add New Team'];
        
        return DropdownButtonFormField<String>(
          decoration: textFieldDecoration('Select Team Name'),
          value: currentValue.isEmpty ? null : (teamNames.contains(currentValue) ? currentValue : null),
          style: const TextStyle(color: Colors.white, fontSize: 16),
          dropdownColor: darkSurface,
          onChanged: (value) {
            if (value == '+ Add New Team') {
              _showAddTeamDialogForGlobal(onValueChanged);
            } else {
              setState(() => onValueChanged(value ?? ''));
            }
          },
          items: allOptions.map((name) {
            return DropdownMenuItem(
              value: name == '+ Add New Team' ? '+ Add New Team' : name,
              child: Text(
                name,
                style: TextStyle(
                  color: name == '+ Add New Team' ? efficialsYellow : Colors.white,
                  fontStyle: name == '+ Add New Team' ? FontStyle.italic : FontStyle.normal,
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
  
  Future<List<String>> _loadTeamNamesForGlobal() async {
    try {
      final scheduleService = ScheduleService();
      final schedules = await scheduleService.getRecentSchedules();
      final teamNames = schedules
          .map((schedule) => schedule['homeTeamName'] as String?)
          .where((name) => name != null && name.isNotEmpty)
          .cast<String>()
          .toSet()
          .toList();
      return teamNames;
    } catch (e) {
      debugPrint('Error loading team names for global: $e');
      return [];
    }
  }
  
  void _showAddTeamDialogForGlobal(Function(String) onValueChanged) {
    final controller = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: darkSurface,
        title: const Text('Add New Team', style: TextStyle(color: efficialsYellow)),
        content: TextField(
          controller: controller,
          decoration: textFieldDecoration('Team Name').copyWith(hintText: 'e.g., Edwardsville Tigers'),
          style: const TextStyle(color: Colors.white),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                setState(() => onValueChanged(name));
                Navigator.pop(context);
              }
            },
            child: const Text('Add', style: TextStyle(color: efficialsYellow)),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleSettingTile(String key) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: darkSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: (scheduleSettings[key] ?? false) ? Colors.green.withOpacity(0.5) : Colors.grey.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Checkbox(
            value: scheduleSettings[key] ?? false,
            onChanged: (value) {
              setState(() {
                scheduleSettings[key] = value ?? false;
              });
            },
            activeColor: Colors.green,
            checkColor: efficialsBlack,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getVariableDisplayName(key),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Check to set per-schedule, leave unchecked for per-game',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlobalSettingTile(
    String key,
    String title,
    String currentValue, {
    bool enabled = true,
    String? description,
    List<String>? options,
    bool isTextField = false,
    bool isTeamNameDropdown = false,
    bool hasSecondaryDropdown = false,
    Function(String)? onValueChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: darkSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: (globalSettings[key] ?? false) ? efficialsYellow.withOpacity(0.5) : Colors.grey.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Checkbox(
                value: globalSettings[key] ?? false,
                onChanged: enabled ? (value) {
                  setState(() {
                    globalSettings[key] = value ?? false;
                    // If unchecking, also uncheck from schedule settings
                    if (!(value ?? false)) scheduleSettings[key] = false;
                  });
                } : null,
                activeColor: efficialsYellow,
                checkColor: efficialsBlack,
              ),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: enabled ? Colors.white : Colors.grey,
                  ),
                ),
              ),
            ],
          ),
          if (description != null) ...[
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.only(left: 48),
              child: Text(
                description,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withOpacity(0.6),
                ),
              ),
            ),
          ],
          if ((globalSettings[key] ?? false) && onValueChanged != null) ...[
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.only(left: 48),
              child: isTeamNameDropdown
                  ? _buildTeamNameDropdownForGlobal(currentValue, onValueChanged)
                  : isTextField
                      ? TextField(
                          decoration: textFieldDecoration(key == 'teamName' ? 'Ex. Edwardsville Tigers' : _getHintForField(key)),
                          style: const TextStyle(color: Colors.white),
                          onChanged: onValueChanged,
                        )
                      : DropdownButtonFormField<String>(
                          decoration: textFieldDecoration(_getHintForField(key)),
                          value: (currentValue.isEmpty || currentValue == 'null') ? null : currentValue,
                          style: const TextStyle(color: Colors.white, fontSize: 16),
                          dropdownColor: darkSurface,
                          onChanged: (value) => setState(() => onValueChanged(value ?? '')),
                          items: (options ?? []).map((option) {
                            return DropdownMenuItem(
                              value: option,
                              child: Text(option, style: const TextStyle(color: Colors.white)),
                            );
                          }).toList(),
                        ),
            ),
          ],
          // Secondary dropdown for method field
          if (hasSecondaryDropdown && key == 'method' && (globalSettings[key] ?? false) && currentValue.isNotEmpty) ...[
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.only(left: 48),
              child: _buildSecondaryMethodDropdown(currentValue),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSecondaryMethodDropdown(String method) {
    switch (method) {
      case 'Single List':
        final validLists = availableLists.where((list) => list['name'] != null && list['name'] != 'No saved lists' && list['name'] != '+ Create new list').toList();
        if (validLists.isEmpty) {
          return const Text(
            'No officials lists available. Create a list first.',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          );
        }
        return DropdownButtonFormField<String>(
          decoration: textFieldDecoration('Select Officials List'),
          value: selectedList,
          style: const TextStyle(color: Colors.white, fontSize: 16),
          dropdownColor: darkSurface,
          onChanged: (value) {
            setState(() {
              selectedList = value;
            });
          },
          items: validLists.map((list) {
            final listName = list['name'] as String;
            return DropdownMenuItem(
              value: listName,
              child: Text(listName, style: const TextStyle(color: Colors.white)),
            );
          }).toList(),
        );

      case 'Multiple Lists':
        final validLists = availableLists.where((list) => list['name'] != null && list['name'] != 'No saved lists' && list['name'] != '+ Create new list').toList();
        if (validLists.isEmpty) {
          return const Text(
            'No officials lists available. Create multiple lists first.',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          );
        }
        return _buildMultipleListsConfiguration();

      case 'Hire a Crew':
        if (availableCrews.isEmpty) {
          return const Text(
            'No crews available. Create a crew first.',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          );
        }
        return DropdownButtonFormField<String>(
          decoration: textFieldDecoration('Select Crew'),
          value: selectedCrew,
          style: const TextStyle(color: Colors.white, fontSize: 16),
          dropdownColor: darkSurface,
          onChanged: (value) {
            setState(() {
              selectedCrew = value;
            });
          },
          items: availableCrews.map((crew) {
            return DropdownMenuItem(
              value: crew.name,
              child: Text(crew.name, style: const TextStyle(color: Colors.white)),
            );
          }).toList(),
        );

      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildMultipleListsConfiguration() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          // Header row with title and + button
          Row(
            children: [
              const Text(
                'Configure Multiple Lists',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              if (selectedMultipleLists.length < 3)
                IconButton(
                  onPressed: () {
                    setState(() {
                      selectedMultipleLists.add({'list': null, 'min': 0, 'max': 1});
                    });
                  },
                  icon: const Icon(Icons.add_circle, color: efficialsYellow),
                ),
            ],
          ),
          const SizedBox(height: 12),
          // List items
          ...selectedMultipleLists.asMap().entries.map((entry) {
            final listIndex = entry.key;
            final listConfig = entry.value;
            return _buildMultipleListItem(listIndex, listConfig);
          }),
        ],
      ),
    );
  }

  Widget _buildMultipleListItem(int listIndex, Map<String, dynamic> listConfig) {
    final validLists = availableLists.where((list) => list['name'] != null && list['name'] != 'No saved lists' && list['name'] != '+ Create new list').toList();
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: darkSurface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                'List ${listIndex + 1}',
                style: const TextStyle(
                  color: efficialsYellow,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              if (selectedMultipleLists.length > 2)
                IconButton(
                  onPressed: () {
                    setState(() {
                      selectedMultipleLists.removeAt(listIndex);
                    });
                  },
                  icon: const Icon(Icons.remove_circle, color: Colors.red, size: 20),
                ),
            ],
          ),
          const SizedBox(height: 8),
          // List selection dropdown
          DropdownButtonFormField<String>(
            decoration: textFieldDecoration('Select Officials List'),
            value: listConfig['list'],
            style: const TextStyle(color: Colors.white, fontSize: 14),
            dropdownColor: darkSurface,
            onChanged: (value) {
              setState(() {
                listConfig['list'] = value;
              });
            },
            items: validLists.map((list) {
              return DropdownMenuItem(
                value: list['name'] as String,
                child: Text(
                  list['name'] as String,
                  style: const TextStyle(color: Colors.white),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 8),
          // Min/Max configuration
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<int>(
                  decoration: textFieldDecoration('Min'),
                  value: listConfig['min'],
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  dropdownColor: darkSurface,
                  onChanged: (value) {
                    setState(() {
                      listConfig['min'] = value;
                    });
                  },
                  items: List.generate(10, (i) => i).map((num) {
                    return DropdownMenuItem(
                      value: num,
                      child: Text(
                        num.toString(),
                        style: const TextStyle(color: Colors.white),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButtonFormField<int>(
                  decoration: textFieldDecoration('Max'),
                  value: listConfig['max'],
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  dropdownColor: darkSurface,
                  onChanged: (value) {
                    setState(() {
                      listConfig['max'] = value;
                    });
                  },
                  items: List.generate(10, (i) => i + 1).map((num) {
                    return DropdownMenuItem(
                      value: num,
                      child: Text(
                        num.toString(),
                        style: const TextStyle(color: Colors.white),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getHintForField(String key) {
    switch (key) {
      case 'gender':
        return 'Select Gender';
      case 'competitionLevel':
        return 'Select Competition Level';
      case 'officialsRequired':
        return 'Select Officials Required';
      case 'gameFee':
        return 'Enter Game Fee (e.g., \$50)';
      case 'method':
        return 'Select Assignment Method';
      case 'location':
        return 'Select Home Location';
      case 'hireAutomatically':
        return 'Select Hire Automatically';
      case 'time':
        return 'Select Game Time';
      default:
        return 'Select Value';
    }
  }

}