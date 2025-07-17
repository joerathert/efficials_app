import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../shared/theme.dart';

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
    final prefs = await SharedPreferences.getInstance();
    sport = prefs.getString('assigner_sport');
    
    if (sport != null) {
      final defaultsKey = 'assigner_sport_defaults_${sport!.toLowerCase()}';
      final defaultGender = prefs.getString('${defaultsKey}_gender');
      final defaultOfficials = prefs.getString('${defaultsKey}_officials');
      final defaultGameFee = prefs.getString('${defaultsKey}_game_fee');
      final defaultCompetitionLevel = prefs.getString('${defaultsKey}_competition_level');
      
      setState(() {
        selectedGender = defaultGender;
        selectedOfficials = defaultOfficials;
        selectedGameFee = defaultGameFee;
        selectedCompetitionLevel = defaultCompetitionLevel;
        if (defaultGameFee != null) {
          _gameFeeController.text = defaultGameFee;
        }
        isLoading = false;
      });
    } else {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _saveDefaults() async {
    final prefs = await SharedPreferences.getInstance();
    
    if (sport != null) {
      final defaultsKey = 'assigner_sport_defaults_${sport!.toLowerCase()}';
      
      if (selectedGender != null) {
        await prefs.setString('${defaultsKey}_gender', selectedGender!);
      }
      if (selectedOfficials != null) {
        await prefs.setString('${defaultsKey}_officials', selectedOfficials!);
      }
      if (_gameFeeController.text.isNotEmpty) {
        await prefs.setString('${defaultsKey}_game_fee', _gameFeeController.text);
      }
      if (selectedCompetitionLevel != null) {
        await prefs.setString('${defaultsKey}_competition_level', selectedCompetitionLevel!);
      }
      
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
    }
  }

  Future<void> _clearDefaults() async {
    final prefs = await SharedPreferences.getInstance();
    
    if (sport != null) {
      final defaultsKey = 'assigner_sport_defaults_${sport!.toLowerCase()}';
      await prefs.remove('${defaultsKey}_gender');
      await prefs.remove('${defaultsKey}_officials');
      await prefs.remove('${defaultsKey}_game_fee');
      await prefs.remove('${defaultsKey}_competition_level');
      
      setState(() {
        selectedGender = null;
        selectedOfficials = null;
        selectedGameFee = null;
        selectedCompetitionLevel = null;
        _gameFeeController.clear();
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Defaults cleared',
              style: TextStyle(color: efficialsBlack, fontWeight: FontWeight.w600),
            ),
            backgroundColor: efficialsYellow,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _gameFeeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: darkBackground,
      appBar: AppBar(
        backgroundColor: efficialsBlack,
        title: const Text('Game Defaults', style: appBarTextStyle),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: efficialsWhite),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: efficialsYellow))
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: efficialsBlue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: efficialsBlue.withOpacity(0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.info_outline, color: efficialsBlue, size: 20),
                              const SizedBox(width: 8),
                              const Text(
                                'Game Defaults',
                                style: TextStyle(
                                  color: efficialsBlue,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Set default values for games. These will be pre-filled when creating new games.',
                            style: TextStyle(
                              color: secondaryTextColor,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),
                    
                    // Competition Level Selection
                    const Text(
                      'Default Competition Level',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: primaryTextColor,
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      decoration: textFieldDecoration('Select default competition level'),
                      value: selectedCompetitionLevel,
                      hint: const Text('Select competition level', style: TextStyle(color: efficialsGray)),
                      dropdownColor: darkSurface,
                      style: const TextStyle(color: primaryTextColor),
                      onChanged: (value) {
                        setState(() {
                          selectedCompetitionLevel = value;
                        });
                      },
                      items: competitionLevels.map((level) => DropdownMenuItem(
                        value: level,
                        child: Text(level, style: const TextStyle(color: primaryTextColor)),
                      )).toList(),
                    ),
                    const SizedBox(height: 24),
                    
                    // Gender Selection
                    const Text(
                      'Default Gender',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: primaryTextColor,
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      decoration: textFieldDecoration('Select default gender'),
                      value: selectedGender,
                      hint: const Text('Select gender', style: TextStyle(color: efficialsGray)),
                      dropdownColor: darkSurface,
                      style: const TextStyle(color: primaryTextColor),
                      onChanged: (value) {
                        setState(() {
                          selectedGender = value;
                        });
                      },
                      items: genderOptions.map((gender) => DropdownMenuItem(
                        value: gender,
                        child: Text(gender, style: const TextStyle(color: primaryTextColor)),
                      )).toList(),
                    ),
                    const SizedBox(height: 24),
                    
                    // Officials Required
                    const Text(
                      'Default Number of Officials',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: primaryTextColor,
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      decoration: textFieldDecoration('Select default officials count'),
                      value: selectedOfficials,
                      hint: const Text('Select officials count', style: TextStyle(color: efficialsGray)),
                      dropdownColor: darkSurface,
                      style: const TextStyle(color: primaryTextColor),
                      onChanged: (value) {
                        setState(() {
                          selectedOfficials = value;
                        });
                      },
                      items: officialsOptions.map((count) => DropdownMenuItem(
                        value: count,
                        child: Text(count, style: const TextStyle(color: primaryTextColor)),
                      )).toList(),
                    ),
                    const SizedBox(height: 24),
                    
                    // Game Fee
                    const Text(
                      'Default Game Fee (per official)',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: primaryTextColor,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _gameFeeController,
                      style: textFieldTextStyle,
                      decoration: textFieldDecoration('Enter default game fee (\$)'),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 40),
                    
                    // Action Buttons
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _saveDefaults,
                            style: elevatedButtonStyle(),
                            child: const Text(
                              'Save Defaults',
                              style: signInButtonTextStyle,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _clearDefaults,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'Clear Defaults',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}