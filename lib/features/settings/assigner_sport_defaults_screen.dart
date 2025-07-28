import 'package:flutter/material.dart';
import '../../shared/theme.dart';
import '../../shared/services/repositories/user_repository.dart';
import '../../shared/services/repositories/sport_repository.dart';
import '../../shared/services/user_session_service.dart';
import '../../shared/models/database_models.dart';

class AssignerSportDefaultsScreen extends StatefulWidget {
  const AssignerSportDefaultsScreen({super.key});

  @override
  State<AssignerSportDefaultsScreen> createState() => _AssignerSportDefaultsScreenState();
}

class _AssignerSportDefaultsScreenState extends State<AssignerSportDefaultsScreen> {
  String? selectedGender;
  String? selectedOfficials;
  String? selectedGameFee;
  String? selectedCompetitionLevel;
  String? sport;
  bool isLoading = true;
  Map<String, String> validationErrors = {};
  
  final List<String> genderOptions = ['Boys', 'Girls', 'Coed'];
  final List<String> officialsOptions = ['1', '2', '3', '4', '5', '6', '7', '8'];
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
  final TextEditingController _gameFeeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadDefaultsAndSport();
  }

  Future<void> _loadDefaultsAndSport() async {
    try {
      final sessionService = UserSessionService.instance;
      final userId = await sessionService.getCurrentUserId();
      
      if (userId != null) {
        final userRepo = UserRepository();
        final user = await userRepo.getUserById(userId);
        sport = user?.sport;
        
        if (sport != null) {
          final sportRepo = SportRepository();
          final sportDefaults = await sportRepo.getSportDefaultsByUserAndSport(userId, sport!);
          
          setState(() {
            selectedGender = sportDefaults?.gender;
            selectedOfficials = sportDefaults?.officialsRequired?.toString();
            selectedGameFee = sportDefaults?.gameFee;
            selectedCompetitionLevel = sportDefaults?.levelOfCompetition;
            if (selectedGameFee != null) {
              _gameFeeController.text = selectedGameFee!;
            }
            isLoading = false;
          });
        } else {
          setState(() {
            isLoading = false;
          });
        }
      } else {
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading sport defaults: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _saveDefaults() async {
    try {
      final sessionService = UserSessionService.instance;
      final userId = await sessionService.getCurrentUserId();
      
      if (userId != null && sport != null) {
        final sportRepo = SportRepository();
        
        // Create or update sport defaults
        final sportDefaults = SportDefaults(
          userId: userId,
          sportName: sport!,
          gender: selectedGender,
          officialsRequired: selectedOfficials != null ? int.tryParse(selectedOfficials!) : null,
          gameFee: _gameFeeController.text.isNotEmpty ? _gameFeeController.text : null,
          levelOfCompetition: selectedCompetitionLevel,
        );
        
        // Validate defaults before saving
        final errors = sportRepo.validateDefaults(sportDefaults);
        
        if (errors.isNotEmpty) {
          setState(() {
            validationErrors = errors;
          });
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Please fix the following errors: ${errors.values.join(', ')}',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                ),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }
        
        // Clear any previous validation errors
        setState(() {
          validationErrors = {};
        });
        
        await sportRepo.saveSportDefaults(sportDefaults);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Defaults saved successfully',
                style: TextStyle(color: efficialsBlack, fontWeight: FontWeight.w600),
              ),
              backgroundColor: efficialsYellow,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No user found. Please log in again.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error saving sport defaults: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error saving defaults. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _clearDefaults() async {
    // Show confirmation dialog
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: darkSurface,
          title: const Text(
            'Clear Defaults',
            style: TextStyle(color: primaryTextColor, fontWeight: FontWeight.bold),
          ),
          content: const Text(
            'Are you sure you want to clear all sport defaults? This action cannot be undone.',
            style: TextStyle(color: primaryTextColor),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.grey),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text(
                'Clear',
                style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
    
    if (confirmed != true) return;
    
    try {
      final sessionService = UserSessionService.instance;
      final userId = await sessionService.getCurrentUserId();
      
      if (userId != null && sport != null) {
        final sportRepo = SportRepository();
        await sportRepo.deleteSportDefaults(userId, sport!);
        
        setState(() {
          selectedGender = null;
          selectedOfficials = null;
          selectedGameFee = null;
          selectedCompetitionLevel = null;
          validationErrors = {};
          _gameFeeController.clear();
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Defaults cleared successfully',
                style: TextStyle(color: efficialsBlack, fontWeight: FontWeight.w600),
              ),
              backgroundColor: efficialsYellow,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error clearing sport defaults: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error clearing defaults. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildDropdownSection(String title, String? value, List<String> options, Function(String?) onChanged, {String? errorKey}) {
    final hasError = errorKey != null && validationErrors.containsKey(errorKey);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: darkSurface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: primaryTextColor,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: darkSurface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: hasError ? Colors.red : Colors.grey.shade300,
                  width: hasError ? 2 : 1,
                ),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: value,
                  hint: Text('Select $title'),
                  items: options.map((String option) {
                    return DropdownMenuItem<String>(
                      value: option,
                      child: Text(
                        option,
                        style: const TextStyle(
                          color: primaryTextColor,
                          fontSize: 16,
                        ),
                      ),
                    );
                  }).toList(),
                  onChanged: onChanged,
                  isExpanded: true,
                  dropdownColor: darkSurface,
                ),
              ),
            ),
            if (hasError) ...[
              const SizedBox(height: 8),
              Text(
                validationErrors[errorKey]!,
                style: const TextStyle(
                  color: Colors.red,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTextFieldSection(String title, TextEditingController controller, {String? errorKey, String? helperText}) {
    final hasError = errorKey != null && validationErrors.containsKey(errorKey);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: darkSurface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: primaryTextColor,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              onChanged: (value) {
                setState(() {
                  selectedGameFee = value.isNotEmpty ? value : null;
                  // Clear error when user starts typing
                  if (errorKey != null && validationErrors.containsKey(errorKey)) {
                    validationErrors.remove(errorKey);
                  }
                });
              },
              decoration: InputDecoration(
                hintText: 'Enter $title',
                helperText: helperText,
                helperStyle: const TextStyle(color: Colors.grey, fontSize: 12),
                errorText: hasError ? validationErrors[errorKey] : null,
                errorStyle: const TextStyle(color: Colors.red, fontSize: 12),
                filled: true,
                fillColor: darkSurface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: hasError ? Colors.red : Colors.grey.shade300,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: hasError ? Colors.red : Colors.grey.shade300,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: hasError ? Colors.red : efficialsYellow,
                    width: 2,
                  ),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.red, width: 2),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.red, width: 2),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              style: const TextStyle(
                color: primaryTextColor,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: darkBackground,
      appBar: AppBar(
        title: Text(
          sport != null ? '$sport Defaults' : 'Sport Defaults',
          style: const TextStyle(
            color: primaryTextColor,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: darkBackground,
        elevation: 0,
        iconTheme: const IconThemeData(color: primaryTextColor),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : sport == null
              ? const Center(
                  child: Text(
                    'No sport selected',
                    style: TextStyle(
                      color: primaryTextColor,
                      fontSize: 18,
                    ),
                  ),
                )
              : SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 16),
                      _buildDropdownSection(
                        'Gender',
                        selectedGender,
                        genderOptions,
                        (value) {
                          setState(() {
                            selectedGender = value;
                            // Clear error when user selects a value
                            validationErrors.remove('gender');
                          });
                        },
                        errorKey: 'gender',
                      ),
                      _buildDropdownSection(
                        'Number of Officials',
                        selectedOfficials,
                        officialsOptions,
                        (value) {
                          setState(() {
                            selectedOfficials = value;
                            // Clear error when user selects a value
                            validationErrors.remove('officialsRequired');
                          });
                        },
                        errorKey: 'officialsRequired',
                      ),
                      _buildTextFieldSection(
                        'Game Fee',
                        _gameFeeController,
                        errorKey: 'gameFee',
                        helperText: 'Enter amount in format: 25.00',
                      ),
                      _buildDropdownSection(
                        'Competition Level',
                        selectedCompetitionLevel,
                        competitionLevels,
                        (value) {
                          setState(() {
                            selectedCompetitionLevel = value;
                            // Clear error when user selects a value
                            validationErrors.remove('levelOfCompetition');
                          });
                        },
                        errorKey: 'levelOfCompetition',
                      ),
                      const SizedBox(height: 32),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                onPressed: _saveDefaults,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: efficialsYellow,
                                  foregroundColor: efficialsBlack,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: const Text(
                                  'Save Defaults',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: OutlinedButton(
                                onPressed: _clearDefaults,
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(color: efficialsYellow),
                                  foregroundColor: efficialsYellow,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: const Text(
                                  'Clear Defaults',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
    );
  }

  @override
  void dispose() {
    _gameFeeController.dispose();
    super.dispose();
  }
}