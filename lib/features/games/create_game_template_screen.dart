import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../shared/theme.dart';
import 'game_template.dart';
import '../../shared/services/repositories/sport_repository.dart';
import '../../shared/services/repositories/user_repository.dart';
import '../../shared/services/game_service.dart';
import '../../shared/services/location_service.dart';

class CreateGameTemplateScreen extends StatefulWidget {
  const CreateGameTemplateScreen({super.key});

  @override
  State<CreateGameTemplateScreen> createState() =>
      _CreateGameTemplateScreenState();
}

class _CreateGameTemplateScreenState extends State<CreateGameTemplateScreen> {
  final _nameController = TextEditingController();
  final _gameFeeController = TextEditingController();
  String? sport;
  TimeOfDay? selectedTime;
  String? scheduleName;
  String? levelOfCompetition;
  String? gender;
  int? officialsRequired;
  bool hireAutomatically = false;
  String? selectedListName;
  String? method; // Method for officials selection: 'standard', 'use_list', 'advanced', 'hire_crew'
  List<Map<String, dynamic>> selectedLists = []; // For advanced method
  List<Map<String, dynamic>> selectedCrews = []; // For crew selection
  String? selectedCrewListName; // For crew list name
  String? location; // Selected location name
  bool isEditing = false;
  GameTemplate? existingTemplate;
  List<Map<String, dynamic>> locations = []; // List of saved locations
  bool isLoadingLocations = true; // Track location loading
  List<String> availableSports = []; // List of available sports
  bool isLoadingSports = true; // Track sports loading
  bool isCreatingFromScratch = false; // Track if creating from scratch
  String? currentUserSchedulerType; // Current user's scheduler type
  String? currentUserSport; // Current user's sport (for Assigners)
  bool isAssigner = false; // Track if current user is an Assigner
  bool isLoadingUser = true; // Track if user data is still loading
  final SportRepository _sportRepository = SportRepository();
  final UserRepository _userRepository = UserRepository();
  final GameService _gameService = GameService();
  final LocationService _locationService = LocationService();

  // Toggle states for including fields in the template
  bool includeSport = true;
  bool includeTime = true;
  bool includeLevelOfCompetition = true;
  bool includeGender = true;
  bool includeOfficialsRequired = true;
  bool includeGameFee = true;
  bool includeHireAutomatically = true;
  bool includeOfficialsList = true;
  bool includeLocation = true;

  // Options for dropdowns
  final List<String> competitionLevels = [
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
  final List<String> youthGenders = ['Boys', 'Girls', 'Co-ed'];
  final List<String> adultGenders = ['Men', 'Women', 'Co-ed'];
  final List<int> officialsOptions = [1, 2, 3, 4, 5, 6, 7, 8, 9];
  List<String> currentGenders = ['Boys', 'Girls', 'Co-ed'];

  @override
  void initState() {
    super.initState();
    _initializeScreen();
  }

  Future<void> _initializeScreen() async {
    // Fetch all required data before processing arguments
    await Future.wait([
      _fetchLocations(), // Fetch locations at initialization
      _fetchSports(), // Fetch sports at initialization
      _fetchCurrentUser(), // Fetch current user information
    ]);
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args =
          ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
      
      // Determine if we're creating from scratch (no arguments)
      isCreatingFromScratch = (args == null);
      
      // Re-apply Assigner sport pre-population if needed
      if (isAssigner && currentUserSport != null && sport == null) {
        debugPrint('RE-APPLYING ASSIGNER SPORT: $currentUserSport');
        setState(() {
          sport = currentUserSport;
          includeSport = true;
        });
      } else {
        debugPrint('NOT RE-APPLYING - isAssigner: $isAssigner, currentUserSport: $currentUserSport, sport: $sport');
      }
      
      if (args != null) {
        // Check if this is an Away Game - Away Games can't be used for templates
        final isAwayGame = args['isAway'] as bool? ?? false;
        final locationArg = args['location'] as String?;
        final opponent = args['opponent'] as String?;
        
        // Detect Away Game by checking for Away Game indicators
        if (isAwayGame || 
            (locationArg != null && locationArg.toLowerCase() == 'away game')) {
          
          // Show dialog and return to previous screen
          WidgetsBinding.instance.addPostFrameCallback((_) {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                backgroundColor: darkSurface,
                title: const Text('Away Game Template Not Supported',
                    style: TextStyle(color: efficialsYellow, fontSize: 18, fontWeight: FontWeight.bold)),
                content: const Text(
                  'Game templates can only be created from Home Games. Away Games have different data requirements and cannot be used as template bases.\n\nTo create a template, please use a Home Game instead.',
                  style: TextStyle(color: Colors.white),
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop(); // Close dialog
                      Navigator.of(context).pop(); // Return to previous screen
                    },
                    child: const Text('OK', style: TextStyle(color: efficialsYellow)),
                  ),
                ],
              ),
            );
          });
          return;
        }
        
        setState(() {
          scheduleName = args['scheduleName'] as String?;
          sport = args['sport'] as String?;
          existingTemplate = args['template'] as GameTemplate?;

          // Handle location from args or template
          if (args['locationData'] != null) {
            final locationData = args['locationData'] as Map<String, dynamic>;
            location = locationData['name'] as String? ?? '';
          } else {
            location = args['location'] as String?;
          }

          if (existingTemplate != null) {
            isEditing = true;
            _nameController.text = existingTemplate!.name ?? '';
            sport = existingTemplate!.sport ?? sport;
            selectedTime = existingTemplate!.time;
            levelOfCompetition = existingTemplate!.levelOfCompetition;
            gender = existingTemplate!.gender;
            officialsRequired = existingTemplate!.officialsRequired;
            _gameFeeController.text = existingTemplate!.gameFee ?? '';
            hireAutomatically = existingTemplate!.hireAutomatically ?? false;
            selectedListName = existingTemplate!.officialsListName;
            method = existingTemplate!.method;
            selectedLists = existingTemplate!.selectedLists ?? [];
            selectedCrews = existingTemplate!.selectedCrews ?? [];
            selectedCrewListName = existingTemplate!.selectedCrewListName;
            location = existingTemplate!.location ?? location;
            includeSport = existingTemplate!.includeSport;
            includeTime = existingTemplate!.includeTime;
            includeLevelOfCompetition =
                existingTemplate!.includeLevelOfCompetition;
            includeGender = existingTemplate!.includeGender;
            includeOfficialsRequired =
                existingTemplate!.includeOfficialsRequired;
            includeGameFee = existingTemplate!.includeGameFee;
            includeHireAutomatically =
                existingTemplate!.includeHireAutomatically;
            includeOfficialsList = existingTemplate!.includeOfficialsList;
            includeLocation = existingTemplate!.includeLocation;
          } else {
            // Pre-fill fields from gameData
            levelOfCompetition = args['levelOfCompetition'] as String?;
            gender = args['gender'] as String?;
            officialsRequired = args['officialsRequired'] as int?;
            _gameFeeController.text = args['gameFee']?.toString() ?? '';
            hireAutomatically = args['hireAutomatically'] as bool? ?? false;
            selectedListName = args['selectedListName'] as String?;
            method = args['method'] as String?;
            selectedLists = args['selectedLists'] != null 
                ? List<Map<String, dynamic>>.from(args['selectedLists'] as List)
                : [];
            selectedCrews = args['selectedCrews'] != null 
                ? List<Map<String, dynamic>>.from(args['selectedCrews'] as List)
                : [];
            selectedCrewListName = args['selectedCrewListName'] as String?;
            // Check if the game has a selected list name (indicates 'use_list' method was used)
            includeOfficialsList = selectedListName != null && selectedListName!.isNotEmpty;
            if (args['time'] != null) {
              if (args['time'] is TimeOfDay) {
                selectedTime = args['time'] as TimeOfDay;
              } else if (args['time'] is String) {
                final parts = (args['time'] as String).split(':');
                if (parts.length == 2) {
                  selectedTime = TimeOfDay(
                    hour: int.parse(parts[0]),
                    minute: int.parse(parts[1]),
                  );
                }
              }
            }
          }

          // Validate sport
          if (sport == null) {
            sport = null; // Keep it null if not provided
          }
          
          _updateCurrentGenders();
          
          // Final validation to ensure all dropdown values are safe
          if (levelOfCompetition != null && !competitionLevels.contains(levelOfCompetition)) {
            levelOfCompetition = null;
          }
          
          if (gender != null && !currentGenders.contains(gender)) {
            gender = null;
          }
          
          if (officialsRequired != null && !officialsOptions.contains(officialsRequired)) {
            officialsRequired = null;
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _gameFeeController.dispose();
    super.dispose();
  }

  Future<void> _fetchLocations() async {
    try {
      final fetchedLocations = await _locationService.getLocations();
      if (mounted) {
        setState(() {
          locations = List<Map<String, dynamic>>.from(fetchedLocations);
          
          // Remove any existing "Create new location" entries to prevent duplicates
          locations.removeWhere((loc) => loc['name'] == '+ Create new location');
          
          // Add the create option only once
          locations.add({'name': '+ Create new location', 'id': 0});
          
          // Validate current location selection
          if (location != null && 
              !locations.any((loc) => loc['name'] == location && loc['id'] != 0)) {
            location = null; // Clear invalid location
          }
          
          isLoadingLocations = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          locations = [{'name': '+ Create new location', 'id': 0}];
          isLoadingLocations = false;
        });
      }
    }
  }

  Future<void> _fetchSports() async {
    try {
      final sports = await _sportRepository.getAllSports();
      if (mounted) {
        setState(() {
          availableSports = sports.map((sport) => sport.name).toList();
          isLoadingSports = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          availableSports = [
            'Football',
            'Basketball',
            'Baseball',
            'Soccer',
            'Volleyball',
          ];
          isLoadingSports = false;
        });
      }
    }
  }

  Future<void> _fetchCurrentUser() async {
    try {
      final currentUser = await _userRepository.getCurrentUser();
      if (currentUser != null && mounted) {
        setState(() {
          currentUserSchedulerType = currentUser.schedulerType;
          currentUserSport = currentUser.sport;
          debugPrint('USER DATA: schedulerType="${currentUser.schedulerType}", sport="${currentUser.sport}"');
          isAssigner = currentUserSchedulerType == 'assigner';
          debugPrint('COMPARISON: "$currentUserSchedulerType" == "assigner" = $isAssigner');
          
          // Pre-populate sport for Assigners
          if (isAssigner && currentUserSport != null && sport == null) {
            sport = currentUserSport;
            includeSport = true; // Always include sport for Assigners
            debugPrint('ASSIGNER SPORT SET: $sport (from currentUserSport: $currentUserSport)');
          } else {
            debugPrint('SPORT NOT SET - isAssigner: $isAssigner, currentUserSport: $currentUserSport, sport: $sport');
          }
          
          isLoadingUser = false; // Mark user loading as complete
        });
      }
    } catch (e) {
      // Handle error silently - user info not critical for template creation
      if (mounted) {
        setState(() {
          isLoadingUser = false; // Mark user loading as complete even on error
        });
      }
    }
  }


  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: selectedTime ?? TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            primaryColor: efficialsYellow,
            colorScheme: const ColorScheme.dark(
              primary: efficialsYellow,
              onPrimary: efficialsBlack,
              surface: darkSurface,
              onSurface: primaryTextColor,
              secondary: efficialsYellow,
              onSecondary: efficialsBlack,
            ),
            timePickerTheme: TimePickerThemeData(
              backgroundColor: darkSurface,
              hourMinuteColor: darkBackground,
              hourMinuteTextColor: primaryTextColor,
              dayPeriodColor: WidgetStateColor.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return efficialsYellow;
                }
                return darkBackground;
              }),
              dayPeriodTextColor: WidgetStateColor.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return efficialsBlack;
                }
                return Colors.white;
              }),
              dialBackgroundColor: darkBackground,
              dialHandColor: efficialsYellow,
              dialTextColor: WidgetStateColor.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return efficialsBlack;
                }
                return primaryTextColor;
              }),
              entryModeIconColor: efficialsYellow,
              helpTextStyle: const TextStyle(color: primaryTextColor),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != selectedTime) {
      setState(() {
        selectedTime = picked;
        includeTime = true;
      });
    }
  }

  void _updateCurrentGenders() {
    if (levelOfCompetition == null) {
      currentGenders = youthGenders;
    } else {
      currentGenders =
          (levelOfCompetition == 'College' || levelOfCompetition == 'Adult')
              ? adultGenders
              : youthGenders;
    }
    if (gender != null && !currentGenders.contains(gender)) {
      gender = null;
    }
  }

  Future<void> _selectOfficialsList() async {
    final result = await Navigator.pushNamed(
      context,
      '/lists_of_officials',
      arguments: {
        'sport': sport,
        'fromGameCreation': true,
        'fromTemplateCreation': true, // Add flag to indicate this is from template creation
      },
    );
    if (result != null && result is Map<String, dynamic>) {
      setState(() {
        selectedListName = result['selectedListName'] as String?;
        method = 'use_list';
      });
    }
  }

  Future<void> _selectAdvancedLists() async {
    final result = await Navigator.pushNamed(
      context,
      '/advanced_officials_selection',
      arguments: {
        'sport': sport,
        'fromGameCreation': true,
        'fromTemplateCreation': true, // Flag to indicate we're coming from template creation
        'method': 'advanced', // Include the method so downstream screens know this is Multiple Lists
        'selectedLists': selectedLists,
        'officialsRequired': officialsRequired ?? 0, // Pass the officials required value
      },
    );
    if (result != null && result is Map<String, dynamic>) {
      setState(() {
        selectedLists = result['selectedLists'] != null 
            ? List<Map<String, dynamic>>.from(result['selectedLists'] as List)
            : [];
        method = 'advanced';
      });
    }
  }

  Future<void> _selectCrews() async {
    final result = await Navigator.pushNamed(
      context,
      '/lists_of_crews',
      arguments: {
        'sport': sport,
        'fromTemplateCreation': true, // Flag to indicate we're coming from template creation
        'method': 'hire_crew',
      },
    );
    if (result != null && result is Map<String, dynamic>) {
      print('🚢 CREW LIST RESULT: $result'); // Debug
      setState(() {
        // Handle crew list selection from lists screen
        if (result['selectedCrews'] != null) {
          selectedCrews = List<Map<String, dynamic>>.from(result['selectedCrews'] as List);
          print('🚢 SAVED selectedCrews: $selectedCrews'); // Debug
        }
        if (result['selectedCrewListName'] != null) {
          selectedCrewListName = result['selectedCrewListName'] as String;
          print('🚢 SAVED selectedCrewListName: $selectedCrewListName'); // Debug
        }
        method = 'hire_crew';
      });
    }
  }

  Future<void> _saveTemplate() async {
    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a template name!')),
      );
      return;
    }
    if (includeGameFee &&
        (_gameFeeController.text.isEmpty ||
            !RegExp(r'^\d+(\.\d+)?$').hasMatch(_gameFeeController.text))) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please enter a valid game fee (e.g., 50 or 50.00)')),
      );
      return;
    }
    if (includeGameFee) {
      final fee = double.parse(_gameFeeController.text.trim());
      if (fee < 1 || fee > 99999) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Game fee must be between 1 and 99,999')),
        );
        return;
      }
    }

    final newTemplate = GameTemplate(
      id: isEditing
          ? existingTemplate!.id
          : DateTime.now().millisecondsSinceEpoch.toString(),
      name: _nameController.text.trim(),
      sport: sport,
      includeSport: true,
      time: selectedTime,
      includeTime: includeTime,
      levelOfCompetition: levelOfCompetition,
      includeLevelOfCompetition: includeLevelOfCompetition,
      gender: gender,
      includeGender: includeGender,
      officialsRequired: officialsRequired,
      includeOfficialsRequired: includeOfficialsRequired,
      gameFee: includeGameFee ? _gameFeeController.text.trim() : null,
      includeGameFee: includeGameFee,
      hireAutomatically: hireAutomatically,
      includeHireAutomatically: includeHireAutomatically,
      officialsListName: selectedListName,
      includeOfficialsList: includeOfficialsList,
      method: method,
      selectedLists: method == 'advanced' ? selectedLists : null,
      selectedCrews: method == 'hire_crew' ? selectedCrews : null,
      selectedCrewListName: method == 'hire_crew' ? selectedCrewListName : null,
      location:
          includeLocation ? location : null, // Use dropdown-selected location
      includeLocation: includeLocation,
    );

    try {
      final templateData = {
        'name': newTemplate.name,
        'sport': newTemplate.sport,
        'scheduleName': newTemplate.scheduleName,
        'date': newTemplate.date,
        'time': newTemplate.time,
        'location': newTemplate.location,
        'isAwayGame': newTemplate.isAwayGame,
        'levelOfCompetition': newTemplate.levelOfCompetition,
        'gender': newTemplate.gender,
        'officialsRequired': newTemplate.officialsRequired,
        'gameFee': newTemplate.gameFee,
        'opponent': newTemplate.opponent,
        'hireAutomatically': newTemplate.hireAutomatically,
        'method': newTemplate.method,
        'selectedLists': newTemplate.selectedLists,
        'selectedCrews': newTemplate.selectedCrews,
        'selectedCrewListName': newTemplate.selectedCrewListName,
        'officialsListName': newTemplate.officialsListName,
        'officialsListId': null,
        'includeScheduleName': newTemplate.includeScheduleName,
        'includeSport': newTemplate.includeSport,
        'includeDate': newTemplate.includeDate,
        'includeTime': newTemplate.includeTime,
        'includeLocation': newTemplate.includeLocation,
        'includeIsAwayGame': newTemplate.includeIsAwayGame,
        'includeLevelOfCompetition': newTemplate.includeLevelOfCompetition,
        'includeGender': newTemplate.includeGender,
        'includeOfficialsRequired': newTemplate.includeOfficialsRequired,
        'includeGameFee': newTemplate.includeGameFee,
        'includeOpponent': newTemplate.includeOpponent,
        'includeHireAutomatically': newTemplate.includeHireAutomatically,
        'includeSelectedOfficials': newTemplate.includeSelectedOfficials,
        'includeOfficialsList': newTemplate.includeOfficialsList,
      };

      if (isEditing) {
        // Update existing template
        final success = await _gameService.updateTemplate(newTemplate.toJson());
        if (!success) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Failed to update template. Please try again.'),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }
        if (mounted) {
          Navigator.pop(context, newTemplate);
        }
      } else {
        // Create new template
        print('🚢 TEMPLATE SAVE DEBUG: selectedCrews being saved: ${templateData['selectedCrews']}');
        print('🚢 TEMPLATE SAVE DEBUG: selectedCrewListName being saved: ${templateData['selectedCrewListName']}');
        final result = await _gameService.createTemplate(templateData);
        if (result == null) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Failed to create template. Template name may already exist.'),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }
        
        // Create a new template object with the database ID
        final savedTemplate = GameTemplate(
          id: result['id'].toString(),
          name: newTemplate.name,
          scheduleName: newTemplate.scheduleName,
          sport: newTemplate.sport,
          date: newTemplate.date,
          time: newTemplate.time,
          location: newTemplate.location,
          isAwayGame: newTemplate.isAwayGame,
          levelOfCompetition: newTemplate.levelOfCompetition,
          gender: newTemplate.gender,
          officialsRequired: newTemplate.officialsRequired,
          gameFee: newTemplate.gameFee,
          opponent: newTemplate.opponent,
          hireAutomatically: newTemplate.hireAutomatically,
          method: newTemplate.method,
          selectedOfficials: newTemplate.selectedOfficials,
          selectedLists: newTemplate.selectedLists,
          selectedCrews: newTemplate.selectedCrews,
          selectedCrewListName: newTemplate.selectedCrewListName,
          officialsListName: newTemplate.officialsListName,
          includeScheduleName: newTemplate.includeScheduleName,
          includeSport: newTemplate.includeSport,
          includeDate: newTemplate.includeDate,
          includeTime: newTemplate.includeTime,
          includeLocation: newTemplate.includeLocation,
          includeIsAwayGame: newTemplate.includeIsAwayGame,
          includeLevelOfCompetition: newTemplate.includeLevelOfCompetition,
          includeGender: newTemplate.includeGender,
          includeOfficialsRequired: newTemplate.includeOfficialsRequired,
          includeGameFee: newTemplate.includeGameFee,
          includeOpponent: newTemplate.includeOpponent,
          includeHireAutomatically: newTemplate.includeHireAutomatically,
          includeSelectedOfficials: newTemplate.includeSelectedOfficials,
          includeOfficialsList: newTemplate.includeOfficialsList,
        );
        
        if (mounted) {
          Navigator.pop(context, savedTemplate);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving template: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildFieldRow(String label, String value, Function(bool?)? onChanged,
      {bool isEditable = true, bool isCheckboxEnabled = true}) {
    bool checkboxValue;
    switch (label) {
      case 'Sport':
        checkboxValue = includeSport;
        break;
      case 'Time':
        checkboxValue = includeTime;
        break;
      case 'Level of Competition':
        checkboxValue = includeLevelOfCompetition;
        break;
      case 'Gender':
        checkboxValue = includeGender;
        break;
      case 'Officials Required':
        checkboxValue = includeOfficialsRequired;
        break;
      case 'Game Fee':
        checkboxValue = includeGameFee;
        break;
      case 'Hire Automatically':
        checkboxValue = includeHireAutomatically;
        break;
      case 'Selected Officials':
        checkboxValue = includeOfficialsList;
        break;
      case 'Location':
        checkboxValue = includeLocation;
        break;
      default:
        checkboxValue = false;
    }

    return Row(
      children: [
        Checkbox(
          value: checkboxValue,
          onChanged: isCheckboxEnabled ? onChanged : null,
          activeColor: efficialsYellow,
          checkColor: efficialsBlack,
          fillColor: WidgetStateProperty.resolveWith<Color?>((states) {
            if (!isCheckboxEnabled) {
              return Colors.grey;
            }
            return states.contains(WidgetState.selected)
                ? efficialsYellow
                : Colors.grey;
          }),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Text(
              '$label: $value',
              style: TextStyle(
                fontSize: 16,
                color: isEditable ? Colors.white : Colors.grey,
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Template Configuration',
                style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: efficialsYellow)),
            const SizedBox(height: 8),
            const Text(
                'Checkboxes indicate which fields will be included in the template',
                style: TextStyle(fontSize: 14, color: Colors.grey)),
            const SizedBox(height: 16),
            TextField(
              controller: _nameController,
              decoration: textFieldDecoration('Template Name'),
              style: const TextStyle(fontSize: 18, color: Colors.white),
            ),
            const SizedBox(height: 20),
            // Basic Information Section
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: darkSurface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Basic Information',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white)),
                  const SizedBox(height: 16),
                  // Sport field - editable when creating from scratch and not an Assigner
                  isCreatingFromScratch && !isAssigner
                      ? Row(
                          children: [
                            Checkbox(
                              value: includeSport,
                              onChanged: (value) {
                                // Sport is always included, but we need onChanged for styling
                                setState(() {
                                  includeSport = true; // Always keep it true
                                });
                              },
                              activeColor: efficialsYellow,
                              checkColor: efficialsBlack,
                            ),
                            Expanded(
                              child: isLoadingSports
                                  ? const CircularProgressIndicator()
                                  : DropdownButtonFormField<String>(
                                      decoration: textFieldDecoration('Sport'),
                                      value: sport != null &&
                                              availableSports.contains(sport)
                                          ? sport
                                          : null,
                                      hint: const Text('Select Sport',
                                          style: TextStyle(color: efficialsGray)),
                                      style: const TextStyle(
                                          color: Colors.white, fontSize: 16),
                                      dropdownColor: darkSurface,
                                      onChanged: (newValue) {
                                        setState(() {
                                          sport = newValue;
                                        });
                                      },
                                      items: availableSports.map((sportName) {
                                        return DropdownMenuItem(
                                          value: sportName,
                                          child: Text(sportName,
                                              style: const TextStyle(
                                                  color: Colors.white)),
                                        );
                                      }).toList(),
                                    ),
                            ),
                          ],
                        )
                      : isCreatingFromScratch && isAssigner
                          ? Row(
                              children: [
                                Checkbox(
                                  value: includeSport,
                                  onChanged: null, // Disabled for Assigners
                                  activeColor: Colors.grey,
                                  checkColor: Colors.white,
                                  fillColor: WidgetStateProperty.resolveWith<Color?>((states) {
                                    return Colors.grey;
                                  }),
                                ),
                                Expanded(
                                  child: isLoadingUser
                                      ? Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                                          decoration: BoxDecoration(
                                            color: Colors.grey[800],
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(color: Colors.grey.withOpacity(0.3)),
                                          ),
                                          child: const Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                'Loading sport...',
                                                style: TextStyle(
                                                  color: Colors.grey,
                                                  fontSize: 16,
                                                ),
                                              ),
                                              SizedBox(
                                                width: 16,
                                                height: 16,
                                                child: CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.grey),
                                                ),
                                              ),
                                            ],
                                          ),
                                        )
                                      : Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                                          decoration: BoxDecoration(
                                            color: Colors.grey[800],
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(color: Colors.grey.withOpacity(0.3)),
                                          ),
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                sport ?? 'Sport not found',
                                                style: const TextStyle(
                                                  color: Colors.grey,
                                                  fontSize: 16,
                                                ),
                                              ),
                                              const Icon(
                                                Icons.lock,
                                                color: Colors.grey,
                                                size: 16,
                                              ),
                                            ],
                                          ),
                                        ),
                                ),
                              ],
                            )
                          : _buildFieldRow('Sport', sport ?? 'Not specified', (value) {},
                              isEditable: false, isCheckboxEnabled: false),
                  Row(
                    children: [
                      Checkbox(
                        value: includeTime,
                        onChanged: (value) =>
                            setState(() => includeTime = value!),
                        activeColor: efficialsYellow,
                        checkColor: efficialsBlack,
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => _selectTime(context),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  selectedTime == null
                                      ? 'Time: Select Time'
                                      : 'Time: ${selectedTime!.format(context)}',
                                  style: const TextStyle(
                                      fontSize: 16, color: Colors.white),
                                ),
                                const Icon(Icons.access_time,
                                    color: efficialsYellow),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Checkbox(
                        value: includeLocation,
                        onChanged: (value) =>
                            setState(() => includeLocation = value!),
                        activeColor: efficialsYellow,
                        checkColor: efficialsBlack,
                      ),
                      Expanded(
                        child: isLoadingLocations
                            ? const CircularProgressIndicator()
                            : Theme(
                                data: Theme.of(context).copyWith(
                                  splashColor: Colors.transparent,
                                  highlightColor: Colors.transparent,
                                ),
                                child: DropdownButtonFormField<String>(
                                  decoration: textFieldDecoration('Location'),
                                  value: location != null &&
                                          locations.isNotEmpty &&
                                          locations.any(
                                              (loc) => loc['name'] == location &&
                                                      loc['id'] != 0) // Exclude the "create new" option
                                      ? location
                                      : null,
                                  hint: locations.isEmpty ||
                                          locations.length ==
                                              1 // Only "+ Create new location"
                                      ? const Text('No locations available',
                                          style: TextStyle(color: Colors.grey))
                                      : const Text('Select location',
                                          style: TextStyle(color: efficialsGray)),
                                  style: const TextStyle(
                                      color: Colors.white, fontSize: 16),
                                  dropdownColor: darkSurface,
                                  isExpanded: true,
                                onChanged: (newValue) {
                                  if (newValue == null) return;
                                  setState(() {
                                    if (newValue == '+ Create new location') {
                                      Navigator.pushNamed(
                                              context, '/add_new_location')
                                          .then((result) async {
                                        if (result != null) {
                                          final newLoc =
                                              result as Map<String, dynamic>;
                                          // Refresh locations from database
                                          await _fetchLocations();
                                          setState(() {
                                            location = newLoc['name'];
                                          });
                                        }
                                      });
                                    } else {
                                      location = newValue;
                                    }
                                  });
                                },
                                items: locations
                                    .fold<List<Map<String, dynamic>>>([], (uniqueList, loc) {
                                      // Only add if name doesn't already exist in uniqueList
                                      if (!uniqueList.any((item) => item['name'] == loc['name'])) {
                                        uniqueList.add(loc);
                                      }
                                      return uniqueList;
                                    })
                                    .map((loc) {
                                      return DropdownMenuItem(
                                        value: loc['name'] as String,
                                        child: Text(loc['name'] as String,
                                            style: const TextStyle(
                                                color: Colors.white),
                                            overflow: TextOverflow.ellipsis),
                                      );
                                    }).toList(),
                                ),
                              ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Game Details Section
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: darkSurface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Game Details',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white)),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Checkbox(
                        value: includeLevelOfCompetition,
                        onChanged: (value) =>
                            setState(() => includeLevelOfCompetition = value!),
                        activeColor: efficialsYellow,
                        checkColor: efficialsBlack,
                      ),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          decoration:
                              textFieldDecoration('Level of Competition'),
                          value: levelOfCompetition != null && 
                                  competitionLevels.contains(levelOfCompetition) 
                              ? levelOfCompetition 
                              : null,
                          hint: const Text('Level of Competition',
                              style: TextStyle(
                                  fontSize: 16, color: efficialsGray)),
                          style: const TextStyle(
                              fontSize: 16, color: Colors.white),
                          dropdownColor: darkSurface,
                          onChanged: (value) {
                            setState(() {
                              levelOfCompetition = value;
                              _updateCurrentGenders();
                            });
                          },
                          items: competitionLevels.map((level) {
                            return DropdownMenuItem(
                              value: level,
                              child: Text(level,
                                  style: const TextStyle(
                                      fontSize: 16, color: Colors.white)),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Checkbox(
                        value: includeGender,
                        onChanged: (value) =>
                            setState(() => includeGender = value!),
                        activeColor: efficialsYellow,
                        checkColor: efficialsBlack,
                      ),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          decoration: textFieldDecoration('Gender'),
                          value: gender != null && 
                                  currentGenders.contains(gender) 
                              ? gender 
                              : null,
                          hint: const Text('Gender',
                              style: TextStyle(
                                  fontSize: 16, color: efficialsGray)),
                          style: const TextStyle(
                              fontSize: 16, color: Colors.white),
                          dropdownColor: darkSurface,
                          onChanged: (value) => setState(() => gender = value),
                          items: currentGenders.map((g) {
                            return DropdownMenuItem(
                              value: g,
                              child: Text(g,
                                  style: const TextStyle(
                                      fontSize: 16, color: Colors.white)),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Checkbox(
                        value: includeOfficialsRequired,
                        onChanged: (value) =>
                            setState(() => includeOfficialsRequired = value!),
                        activeColor: efficialsYellow,
                        checkColor: efficialsBlack,
                      ),
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          decoration:
                              textFieldDecoration('# of Officials Required'),
                          value: officialsRequired != null && 
                                  officialsOptions.contains(officialsRequired) 
                              ? officialsRequired 
                              : null,
                          hint: const Text('# of Officials Required',
                              style: TextStyle(
                                  fontSize: 16, color: efficialsGray)),
                          style: const TextStyle(
                              fontSize: 16, color: Colors.white),
                          dropdownColor: darkSurface,
                          onChanged: (value) =>
                              setState(() => officialsRequired = value),
                          items: officialsOptions.map((num) {
                            return DropdownMenuItem(
                              value: num,
                              child: Text(num.toString(),
                                  style: const TextStyle(
                                      fontSize: 16, color: Colors.white)),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Financial & Hiring Section
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: darkSurface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Financial & Hiring',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white)),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Checkbox(
                        value: includeGameFee,
                        onChanged: (value) =>
                            setState(() => includeGameFee = value!),
                        activeColor: efficialsYellow,
                        checkColor: efficialsBlack,
                      ),
                      Expanded(
                        child: TextField(
                          controller: _gameFeeController,
                          decoration:
                              textFieldDecoration('Game Fee per Official')
                                  .copyWith(
                            prefixText: '\$',
                            prefixStyle: const TextStyle(
                                color: Colors.white, fontSize: 16),
                            hintText: 'Enter fee (e.g., 50 or 50.00)',
                          ),
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                                RegExp(r'[0-9.]')),
                            LengthLimitingTextInputFormatter(7),
                          ],
                          style: const TextStyle(
                              fontSize: 16, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Checkbox(
                        value: includeHireAutomatically,
                        onChanged: (value) =>
                            setState(() => includeHireAutomatically = value!),
                        activeColor: efficialsYellow,
                        checkColor: efficialsBlack,
                      ),
                      Expanded(
                        child: Row(
                          children: [
                            const Text('Hire Automatically: ',
                                style: TextStyle(
                                    fontSize: 16, color: Colors.white)),
                            Switch(
                              value: hireAutomatically,
                              onChanged: (value) =>
                                  setState(() => hireAutomatically = value),
                              activeColor: efficialsYellow,
                            ),
                            Text(hireAutomatically ? 'Yes' : 'No',
                                style: const TextStyle(
                                    fontSize: 16, color: Colors.white)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Officials Assignment Section
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: darkSurface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Officials Assignment',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white)),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Checkbox(
                        value: includeOfficialsList,
                        onChanged: (value) =>
                            setState(() => includeOfficialsList = value!),
                        activeColor: efficialsYellow,
                        checkColor: efficialsBlack,
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Method:',
                              style: TextStyle(fontSize: 16, color: Colors.white),
                            ),
                            const SizedBox(height: 8),
                            DropdownButtonFormField<String>(
                              decoration: textFieldDecoration('Selection Method'),
                              value: method,
                              hint: const Text('Select officials method',
                                  style: TextStyle(color: efficialsGray)),
                              style: const TextStyle(color: Colors.white, fontSize: 16),
                              dropdownColor: darkSurface,
                              onChanged: (value) {
                                setState(() {
                                  method = value;
                                  // Clear related data when method changes
                                  if (method != 'use_list') {
                                    selectedListName = null;
                                  }
                                  if (method != 'advanced') {
                                    selectedLists.clear();
                                  }
                                  if (method != 'hire_crew') {
                                    selectedCrews.clear();
                                  }
                                });
                              },
                              items: const [
                                DropdownMenuItem(
                                  value: 'standard',
                                  child: Text('Manual Selection',
                                      style: TextStyle(color: Colors.white)),
                                ),
                                DropdownMenuItem(
                                  value: 'advanced',
                                  child: Text('Multiple Lists',
                                      style: TextStyle(color: Colors.white)),
                                ),
                                DropdownMenuItem(
                                  value: 'use_list',
                                  child: Text('Single List',
                                      style: TextStyle(color: Colors.white)),
                                ),
                                DropdownMenuItem(
                                  value: 'hire_crew',
                                  child: Text('Hire a Crew',
                                      style: TextStyle(color: Colors.white)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            // Method-specific configuration
                            if (method == 'use_list') ...[
                              GestureDetector(
                                onTap: _selectOfficialsList,
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.grey.withOpacity(0.3)),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          selectedListName == null
                                              ? 'Tap to select a saved list'
                                              : 'List: $selectedListName',
                                          style: const TextStyle(
                                              fontSize: 14, color: Colors.white),
                                        ),
                                      ),
                                      const Icon(Icons.list, color: efficialsYellow),
                                    ],
                                  ),
                                ),
                              ),
                            ] else if (method == 'advanced') ...[
                              GestureDetector(
                                onTap: _selectAdvancedLists,
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.grey.withOpacity(0.3)),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          selectedLists.isEmpty
                                              ? 'Tap to configure advanced lists'
                                              : 'Lists configured: ${selectedLists.length}',
                                          style: const TextStyle(
                                              fontSize: 14, color: Colors.white),
                                        ),
                                      ),
                                      const Icon(Icons.settings, color: efficialsYellow),
                                    ],
                                  ),
                                ),
                              ),
                              if (selectedLists.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                ...selectedLists.map((list) => Padding(
                                  padding: const EdgeInsets.only(left: 16, bottom: 4),
                                  child: Text(
                                    '• ${list['name']}: ${list['minOfficials']}-${list['maxOfficials']} officials',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                )),
                              ],
                            ] else if (method == 'hire_crew') ...[
                              GestureDetector(
                                onTap: _selectCrews,
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.grey.withOpacity(0.3)),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          selectedCrews.isEmpty
                                              ? 'Tap to select crew lists'
                                              : 'Crew lists selected: ${selectedCrews.length}',
                                          style: const TextStyle(
                                              fontSize: 14, color: Colors.white),
                                        ),
                                      ),
                                      const Icon(Icons.group, color: efficialsYellow),
                                    ],
                                  ),
                                ),
                              ),
                              if (selectedCrews.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                ...selectedCrews.map((crew) => Padding(
                                  padding: const EdgeInsets.only(left: 16, bottom: 4),
                                  child: Text(
                                    '• ${crew['name']}: ${crew['sportName']} (${crew['memberCount'] ?? 0} officials)',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                )),
                              ],
                            ] else if (method == 'standard') ...[
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey.withOpacity(0.3)),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Row(
                                  children: [
                                    Icon(Icons.person, color: efficialsYellow),
                                    SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Officials will be selected manually when using this template',
                                        style: TextStyle(
                                            fontSize: 14, color: Colors.white),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        color: efficialsBlack,
        padding: EdgeInsets.only(
          left: 32,
          right: 32,
          top: 16,
          bottom: MediaQuery.of(context).padding.bottom + 16,
        ),
        child: ElevatedButton(
          onPressed: _saveTemplate,
          style: elevatedButtonStyle(),
          child: const Text('Save Template', style: signInButtonTextStyle),
        ),
      ),
    );
  }
}
