import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../shared/theme.dart';
import '../../shared/models/database_models.dart' as db;
import 'game_template.dart' as ui;

class AdditionalGameInfoScreen extends StatefulWidget {
  const AdditionalGameInfoScreen({super.key});

  @override
  _AdditionalGameInfoScreenState createState() =>
      _AdditionalGameInfoScreenState();
}

class _AdditionalGameInfoScreenState extends State<AdditionalGameInfoScreen> {
  String? _levelOfCompetition;
  String? _gender;
  int? _officialsRequired;
  List<String> _currentGenders = ['Boys', 'Girls', 'Co-ed'];
  final TextEditingController _gameFeeController = TextEditingController();
  final TextEditingController _opponentController = TextEditingController();
  bool _hireAutomatically = false;
  bool _isFromEdit = false;
  bool _isInitialized = false;
  bool _isAwayGame = false;
  ui.GameTemplate? template; // Store the selected template

  final List<String> _competitionLevels = [
    '6U',
    '7U',
    '8U',
    '9U',
    '10U',
    '11U',
    '12U',
    '13U',
    '14U',
    '15U',
    '16U',
    '17U',
    '18U',
    'Grade School',
    'Middle School',
    'Underclass',
    'JV',
    'Varsity',
    'College',
    'Adult'
  ];
  final List<String> _youthGenders = ['Boys', 'Girls', 'Co-ed'];
  final List<String> _adultGenders = ['Men', 'Women', 'Co-ed'];
  final List<int> _officialsOptions = [1, 2, 3, 4, 5, 6, 7, 8, 9];

  Future<Map<String, dynamic>> _loadAssignerDefaults() async {
    final prefs = await SharedPreferences.getInstance();
    final sport = prefs.getString('assigner_sport');

    if (sport != null) {
      final defaultsKey = 'assigner_sport_defaults_${sport.toLowerCase()}';
      final defaultGender = prefs.getString('${defaultsKey}_gender');
      final defaultOfficials = prefs.getString('${defaultsKey}_officials');
      final defaultGameFee = prefs.getString('${defaultsKey}_game_fee');

      final defaultCompetitionLevel =
          prefs.getString('${defaultsKey}_competition_level');

      // Map genders to match the screen's expected format
      String? mappedGender;
      if (defaultGender != null) {
        if (defaultGender == 'Boys') {
          mappedGender = 'Boys';
        } else if (defaultGender == 'Girls') {
          mappedGender = 'Girls';
        } else if (defaultGender == 'Coed') {
          mappedGender = 'Co-ed';
        }
      }

      return {
        'gender': mappedGender,
        'officials':
            defaultOfficials != null ? int.tryParse(defaultOfficials) : null,
        'gameFee': defaultGameFee,
        'competitionLevel': defaultCompetitionLevel,
      };
    }

    return {};
  }

  void _updateCurrentGenders() {
    if (_levelOfCompetition == null) {
      _currentGenders = _youthGenders;
    } else {
      _currentGenders =
          (_levelOfCompetition == 'College' || _levelOfCompetition == 'Adult')
              ? _adultGenders
              : _youthGenders;
    }
  }

  void _showHireInfoDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: darkSurface,
        title: const Text('Hire Automatically',
            style: TextStyle(
                color: efficialsYellow,
                fontSize: 20,
                fontWeight: FontWeight.bold)),
        content: const Text(
          'When checked, the system will automatically assign officials based on your preferences and availability. Uncheck to manually select officials.',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child:
                const Text('Close', style: TextStyle(color: efficialsYellow)),
          ),
        ],
      ),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      _initializeAsync();
    }
  }

  Future<void> _initializeAsync() async {
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null) {
      _isFromEdit = args['isEdit'] == true;
      _isAwayGame = args['isAwayGame'] == true;

      // Convert database GameTemplate to UI GameTemplate if needed
      if (args['template'] is db.GameTemplate) {
        final dbTemplate = args['template'] as db.GameTemplate;
        
        // Debug database template crew data
        print('🚢 DB TEMPLATE DEBUG: selectedCrews from database: ${dbTemplate.selectedCrews}');
        print('🚢 DB TEMPLATE DEBUG: selectedCrewListName from database: ${dbTemplate.selectedCrewListName}');

        // Get selectedLists data from SharedPreferences if method is advanced
        List<Map<String, dynamic>>? selectedLists;
        if (dbTemplate.method == 'advanced' && dbTemplate.id != null) {
          final prefs = await SharedPreferences.getInstance();
          final key = 'template_selectedLists_${dbTemplate.id}';
          final selectedListsJson = prefs.getString(key);
          if (selectedListsJson != null) {
            try {
              selectedLists = List<Map<String, dynamic>>.from(
                  jsonDecode(selectedListsJson));
              debugPrint(
                  'Loaded selectedLists from SharedPreferences: ${selectedLists.length} lists');
            } catch (e) {
              debugPrint('Error parsing selectedLists data: $e');
            }
          }
        }

        template = ui.GameTemplate(
          id: dbTemplate.id?.toString() ?? '',
          name: dbTemplate.name,
          scheduleName: dbTemplate.scheduleName,
          sport: dbTemplate.sportName,
          date: dbTemplate.date,
          time: dbTemplate.time,
          location: dbTemplate.locationName,
          isAwayGame: dbTemplate.isAwayGame,
          levelOfCompetition: dbTemplate.levelOfCompetition,
          gender: dbTemplate.gender,
          officialsRequired: dbTemplate.officialsRequired,
          gameFee: dbTemplate.gameFee,
          opponent: dbTemplate.opponent,
          hireAutomatically: dbTemplate.hireAutomatically,
          method: dbTemplate.method,
          selectedOfficials: dbTemplate.selectedOfficials,
          selectedLists: selectedLists, // Use the loaded selectedLists data
          selectedCrews: dbTemplate.selectedCrews, // Add crew data
          selectedCrewListName: dbTemplate.selectedCrewListName, // Add crew list name
          officialsListName: dbTemplate.officialsListName,
          includeScheduleName: dbTemplate.includeScheduleName,
          includeSport: dbTemplate.includeSport,
          includeDate: dbTemplate.includeDate,
          includeTime: dbTemplate.includeTime,
          includeLocation: dbTemplate.includeLocation,
          includeIsAwayGame: dbTemplate.includeIsAwayGame,
          includeLevelOfCompetition: dbTemplate.includeLevelOfCompetition,
          includeGender: dbTemplate.includeGender,
          includeOfficialsRequired: dbTemplate.includeOfficialsRequired,
          includeGameFee: dbTemplate.includeGameFee,
          includeOpponent: dbTemplate.includeOpponent,
          includeHireAutomatically: dbTemplate.includeHireAutomatically,
          includeSelectedOfficials: dbTemplate.includeSelectedOfficials,
          includeOfficialsList: dbTemplate.includeOfficialsList,
        );
      } else {
        template = args['template'] as ui.GameTemplate?;
      }


      // Load assigner defaults (only for assigner flow, not for edit mode)
      Map<String, dynamic> defaults = {};
      final isAssignerFlow = args['isAssignerFlow'] == true;
      if (isAssignerFlow && !_isFromEdit) {
        defaults = await _loadAssignerDefaults();
      }

      // Pre-fill fields from the template if available, otherwise use args, then defaults
      if (template != null) {
        _levelOfCompetition = template!.includeLevelOfCompetition &&
                template!.levelOfCompetition != null
            ? template!.levelOfCompetition
            : (args['levelOfCompetition'] as String? ??
                defaults['competitionLevel']);
        _updateCurrentGenders();
        _gender = template!.includeGender && template!.gender != null
            ? template!.gender
            : (args['gender'] as String? ?? defaults['gender']);
        if (_gender != null && !_currentGenders.contains(_gender)) {
          _gender = null;
        }
        _officialsRequired = template!.includeOfficialsRequired &&
                template!.officialsRequired != null
            ? template!.officialsRequired
            : (args['officialsRequired'] != null
                ? int.tryParse(args['officialsRequired'].toString())
                : defaults['officials']);
        _gameFeeController.text =
            template!.includeGameFee && template!.gameFee != null
                ? template!.gameFee!
                : (args['gameFee']?.toString() ?? defaults['gameFee'] ?? '');
        _hireAutomatically = template!.includeHireAutomatically &&
                template!.hireAutomatically != null
            ? template!.hireAutomatically!
            : (args['hireAutomatically'] as bool? ?? false);
      } else {
        _levelOfCompetition = args['levelOfCompetition'] as String? ??
            defaults['competitionLevel'];
        _updateCurrentGenders();
        final genderArg = args['gender'] as String?;
        _gender = (genderArg != null && _currentGenders.contains(genderArg))
            ? genderArg
            : (defaults['gender'] != null &&
                    _currentGenders.contains(defaults['gender']))
                ? defaults['gender']
                : null;
        _officialsRequired = args['officialsRequired'] != null
            ? int.tryParse(args['officialsRequired'].toString())
            : defaults['officials'];
        _gameFeeController.text =
            args['gameFee']?.toString() ?? defaults['gameFee'] ?? '';
        _hireAutomatically = args['hireAutomatically'] as bool? ?? false;
      }
      // Opponent field should only be populated from args during edit flow
      // Never pre-fill opponent for new games in assigner flow
      if (_isFromEdit) {
        _opponentController.text = args['opponent'] as String? ?? '';
      } else {
        _opponentController.text = '';
      }

      // Validate that _officialsRequired is a valid option
      if (_officialsRequired != null &&
          !_officialsOptions.contains(_officialsRequired)) {
        _officialsRequired = null;
      }

      // Clear game fee if it's "0" (from away game) so hint text shows
      if (_gameFeeController.text == '0' ||
          _gameFeeController.text == '0.0' ||
          _gameFeeController.text == '0.00') {
        _gameFeeController.text = '';
      }
    }

    setState(() {
      _isInitialized = true;
    });
  }

  List<Map<String, dynamic>> _getTemplateSelectedLists() {
    if (template == null || template!.method != 'advanced') {
      return [];
    }

    // Return the selectedLists directly from the template if available
    if (template!.selectedLists != null &&
        template!.selectedLists!.isNotEmpty) {
      return List<Map<String, dynamic>>.from(template!.selectedLists!);
    }

    return [];
  }

  Future<List<Map<String, dynamic>>> _getTemplateListOfficials() async {
    if (template == null ||
        template!.method != 'use_list' ||
        template!.officialsListName == null) {
      return [];
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final String? listsJson = prefs.getString('saved_lists');

      if (listsJson == null || listsJson.isEmpty) {
        return [];
      }

      final List<dynamic> lists = jsonDecode(listsJson);

      // Find the list by name
      for (final list in lists) {
        if (list['name'] == template!.officialsListName) {
          final officials = list['officials'] as List<dynamic>?;
          if (officials != null) {
            final officialsList = officials
                .map((official) => Map<String, dynamic>.from(official as Map))
                .toList();
            return officialsList;
          }
        }
      }

      return [];
    } catch (e) {
      return [];
    }
  }

  List<Map<String, dynamic>> _getTemplateAdvancedOfficials() {
    if (template == null ||
        template!.method != 'advanced' ||
        template!.selectedLists == null) {
      return [];
    }

    // Collect all officials from all selected lists in the template
    List<Map<String, dynamic>> allOfficials = [];
    for (var list in template!.selectedLists!) {
      final officials = list['officials'] as List<dynamic>?;
      if (officials != null) {
        for (var official in officials) {
          if (official is Map<String, dynamic>) {
            allOfficials.add(Map<String, dynamic>.from(official));
          }
        }
      }
    }
    return allOfficials;
  }

  Future<void> _handleContinue() async {
    if (!_isAwayGame) {
      if (_levelOfCompetition == null ||
          _gender == null ||
          _officialsRequired == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(
                  'Please select a level, gender, and number of officials')),
        );
        return;
      }
      final feeText = _gameFeeController.text.trim();
      if (feeText.isEmpty || !RegExp(r'^\d+(\.\d+)?$').hasMatch(feeText)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content:
                  Text('Please enter a valid game fee (e.g., 50 or 50.00)')),
        );
        return;
      }
      final fee = double.parse(feeText);
      if (fee < 1 || fee > 99999) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Game fee must be between 1 and 99,999')),
        );
        return;
      }
    }

    final args =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;

    debugPrint('Template in args: ${args['template']}');

    // Load officials from template if needed
    List<Map<String, dynamic>> templateOfficials = [];
    if (template?.method == 'use_list' && template?.officialsListName != null) {
      templateOfficials = await _getTemplateListOfficials();
    } else if (template?.method == 'advanced' &&
        template?.selectedLists != null) {
      templateOfficials = _getTemplateAdvancedOfficials();
    }

    final updatedArgs = {
      ...args,
      'id': args['id'] ?? DateTime.now().millisecondsSinceEpoch,
      'levelOfCompetition': _isAwayGame ? null : _levelOfCompetition,
      'gender': _isAwayGame ? null : _gender,
      'officialsRequired': _isAwayGame ? 0 : _officialsRequired,
      'gameFee': _isAwayGame ? '0' : _gameFeeController.text.trim(),
      'opponent': _opponentController.text.trim(),
      'hireAutomatically': _isAwayGame ? false : _hireAutomatically,
      'isAway': _isAwayGame,
      'officialsHired': args['officialsHired'] ?? 0,
      'selectedOfficials':
          (template?.method == 'use_list' || template?.method == 'advanced') &&
                  templateOfficials.isNotEmpty
              ? templateOfficials
              : (args['selectedOfficials'] ?? <Map<String, dynamic>>[]),
      'template': template,
      // Add template-specific data for advanced method
      'method': template?.method,
      'selectedLists': template?.method == 'advanced'
          ? _getTemplateSelectedLists()
          : (args['selectedLists'] ?? []),
      'selectedListName': template?.method == 'use_list'
          ? template?.officialsListName
          : args['selectedListName'],
      'sport': template?.includeSport == true ? template?.sport : args['sport'],
      'location': (template?.includeLocation == true && template?.location != null)
          ? template?.location
          : args['location'],
      'fromScheduleDetails': args['fromScheduleDetails'] ?? false,
      'scheduleId': args['scheduleId'],
      'scheduleName': args['scheduleName'],
    };

    debugPrint('Updated args method: ${updatedArgs['method']}');
    debugPrint('Updated args selectedLists: ${updatedArgs['selectedLists']}');
    
    // Debug location handling
    debugPrint('🔍 AdditionalGameInfo - Location debugging:');
    debugPrint('  template?.includeLocation: ${template?.includeLocation}');
    debugPrint('  template?.location: ${template?.location}');
    debugPrint('  args[location]: ${args['location']}');
    debugPrint('  updatedArgs[location]: ${updatedArgs['location']}');

    if (_isFromEdit) {
      // When editing an existing game, navigate directly to review screen
      Navigator.pushReplacementNamed(
        context,
        '/review_game_info',
        arguments: {
          ...updatedArgs,
          'isEdit': true,
          'isFromGameInfo': args['isFromGameInfo'] ?? false
        },
      );
    } else {
      // Normal game creation flow
      String nextRoute;
      if (_isAwayGame) {
        nextRoute = '/review_game_info';
      } else {
        // Check if template has a specific method for officials selection
        if (template?.method != null) {

          switch (template!.method) {
            case 'advanced':
              // If template has pre-configured selectedLists with min/max data, skip advanced selection
              if (template!.selectedLists != null &&
                  template!.selectedLists!.isNotEmpty) {
                debugPrint('Using pre-configured lists, skipping to review');
                updatedArgs['selectedLists'] = template!.selectedLists;
                nextRoute = '/review_game_info';
              } else {
                debugPrint(
                    'No pre-configured lists, going to advanced selection');
                nextRoute = '/advanced_officials_selection';
              }
              break;
            case 'use_list':
              // If template has a pre-selected list, skip the list selection screen
              if (template!.officialsListName != null &&
                  template!.officialsListName!.isNotEmpty) {
                nextRoute = '/review_game_info';
              } else {
                nextRoute = '/lists_of_officials';
              }
              break;
            case 'hire_crew':
              // Debug logging for crew template data
              print('🚢 CREW DEBUG: Template method: ${template!.method}');
              print('🚢 CREW DEBUG: selectedCrews: ${template!.selectedCrews}');
              print('🚢 CREW DEBUG: selectedCrewListName: ${template!.selectedCrewListName}');
              
              // If template has pre-selected crews, skip directly to review
              if (template!.selectedCrews != null &&
                  template!.selectedCrews!.isNotEmpty) {
                print('🚢 CREW DEBUG: Template has crew data, routing to review');
                nextRoute = '/review_game_info';
                // Add crew data to the arguments
                updatedArgs['method'] = 'hire_crew';
                updatedArgs['selectedCrews'] = template!.selectedCrews;
                updatedArgs['selectedCrew'] = template!.selectedCrews!.first;
                if (template!.selectedCrewListName != null) {
                  updatedArgs['selectedCrewListName'] = template!.selectedCrewListName;
                }
              } else {
                print('🚢 CREW DEBUG: Template missing crew data, routing to select_crew');
                nextRoute = '/select_crew';
              }
              break;
            case 'standard':
            default:
              nextRoute = '/select_officials';
              break;
          }
        } else {
          // Default to standard selection if no template method is specified
          nextRoute = '/select_officials';
        }
      }

      debugPrint('Navigating to: $nextRoute');
      
      // Add template creation flag for lists_of_officials screen
      if (nextRoute == '/lists_of_officials' && template != null) {
        updatedArgs['fromTemplateCreation'] = true;
      }
      
      Navigator.pushNamed(
        context,
        nextRoute,
        arguments: updatedArgs,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    _updateCurrentGenders();
    if (_gender != null && !_currentGenders.contains(_gender)) {
      _gender = null;
    }

    return Scaffold(
      backgroundColor: darkBackground,
      appBar: AppBar(
        backgroundColor: efficialsBlack,
        title: const Icon(
          Icons.sports,
          color: efficialsYellow,
          size: 32,
        ),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: efficialsWhite),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 40),
                const Text(
                  'Additional Game Info',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: efficialsYellow,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: darkSurface,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (!_isAwayGame) ...[
                        DropdownButtonFormField<String>(
                          decoration:
                              textFieldDecoration('Level of competition'),
                          value: _levelOfCompetition,
                          hint: const Text('Level of competition',
                              style: TextStyle(color: efficialsGray)),
                          style: const TextStyle(
                              color: Colors.white, fontSize: 16),
                          dropdownColor: darkSurface,
                          onChanged: (value) {
                            setState(() {
                              _levelOfCompetition = value;
                              _updateCurrentGenders();
                              if (_gender != null &&
                                  !_currentGenders.contains(_gender)) {
                                _gender = null;
                              }
                            });
                          },
                          items: _competitionLevels
                              .map((level) => DropdownMenuItem(
                                  value: level,
                                  child: Text(level,
                                      style: const TextStyle(
                                          color: Colors.white))))
                              .toList(),
                        ),
                        const SizedBox(height: 20),
                        DropdownButtonFormField<String>(
                          decoration: textFieldDecoration('Gender'),
                          value: _gender,
                          hint: const Text('Select gender',
                              style: TextStyle(color: efficialsGray)),
                          style: const TextStyle(
                              color: Colors.white, fontSize: 16),
                          dropdownColor: darkSurface,
                          onChanged: (value) => setState(() => _gender = value),
                          items: _currentGenders
                              .map((gender) => DropdownMenuItem(
                                  value: gender,
                                  child: Text(gender,
                                      style: const TextStyle(
                                          color: Colors.white))))
                              .toList(),
                        ),
                        const SizedBox(height: 20),
                        DropdownButtonFormField<int>(
                          decoration: textFieldDecoration(
                              'Required number of officials'),
                          value: _officialsRequired,
                          hint: const Text('Required number of officials',
                              style: TextStyle(color: efficialsGray)),
                          style: const TextStyle(
                              color: Colors.white, fontSize: 16),
                          dropdownColor: darkSurface,
                          onChanged: (value) =>
                              setState(() => _officialsRequired = value),
                          items: _officialsOptions
                              .map((num) => DropdownMenuItem(
                                  value: num,
                                  child: Text(num.toString(),
                                      style: const TextStyle(
                                          color: Colors.white))))
                              .toList(),
                        ),
                        const SizedBox(height: 20),
                        TextField(
                          controller: _gameFeeController,
                          enabled: true,
                          autofocus: false,
                          decoration:
                              textFieldDecoration('Game Fee per Official')
                                  .copyWith(
                            prefixText: '\$',
                            prefixStyle: const TextStyle(
                                color: fieldLineWhite, fontSize: 16),
                            hintText: 'Enter fee (e.g., 50 or 50.00)',
                            hintStyle: const TextStyle(color: efficialsGray),
                          ),
                          style: const TextStyle(
                              color: fieldLineWhite, fontSize: 16),
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                                RegExp(r'[0-9.]')),
                            LengthLimitingTextInputFormatter(
                                7), // Allow for "99999.99"
                          ],
                        ),
                        const SizedBox(height: 20),
                      ],
                      TextField(
                        controller: _opponentController,
                        enabled: true,
                        autofocus: false,
                        decoration: textFieldDecoration('Opponent'),
                        style:
                            const TextStyle(color: Colors.white, fontSize: 16),
                        keyboardType: TextInputType.text,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'This name will be displayed to officials to help them identify the opponent',
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                      const SizedBox(height: 20),
                      if (!_isAwayGame)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Checkbox(
                              value: _hireAutomatically,
                              onChanged: (value) => setState(
                                  () => _hireAutomatically = value ?? false),
                              activeColor: efficialsYellow,
                              checkColor: efficialsBlack,
                            ),
                            const Text('Hire Automatically',
                                style: TextStyle(color: Colors.white)),
                            IconButton(
                              icon: const Icon(Icons.help_outline,
                                  color: efficialsYellow),
                              onPressed: _showHireInfoDialog,
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
                ElevatedButton(
                  onPressed: _handleContinue,
                  style: elevatedButtonStyle(
                    padding: const EdgeInsets.symmetric(
                        vertical: 15, horizontal: 50),
                  ),
                  child: const Text('Continue', style: signInButtonTextStyle),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _gameFeeController.dispose();
    _opponentController.dispose();
    super.dispose();
  }
}
