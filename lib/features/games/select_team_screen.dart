import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../shared/theme.dart'; // For efficialsBlue, textFieldDecoration, headlineStyle, signInButtonTextStyle, appBarTextStyle

class SelectTeamScreen extends StatefulWidget {
  const SelectTeamScreen({Key? key}) : super(key: key);

  @override
  _SelectTeamScreenState createState() => _SelectTeamScreenState();
}

class _SelectTeamScreenState extends State<SelectTeamScreen> {
  String? _selectedSport;
  String? _selectedGrade;
  String? _selectedGender;
  final TextEditingController _teamNameController = TextEditingController();

  final List<String> sports = [
    'Baseball',
    'Basketball',
    'Football',
    'Soccer',
    'Softball',
    'Volleyball'
  ]; // From select_sport_screen.dart
  final List<String> grades = [
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
    'Adult'
  ];
  List<String> genders = ['Boys', 'Girls', 'Co-ed'];

  @override
  void initState() {
    super.initState();
    _teamNameController.addListener(_updateTeamName);
  }

  void _updateTeamName() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('team_name', _teamNameController.text);
  }

  void _updateGenderOptions(String? grade) {
    setState(() {
      if (grade == 'Adult') {
        genders = ['Men', 'Women', 'Co-ed'];
      } else {
        genders = ['Boys', 'Girls', 'Co-ed'];
      }
      _selectedGender = null; // Reset gender selection
    });
  }

  void _onContinue() async {
    if (_teamNameController.text.isNotEmpty &&
        _selectedSport != null &&
        _selectedGrade != null &&
        _selectedGender != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('team_setup_completed', true);
      await prefs.setString('team_name', _teamNameController.text);
      await prefs.setString('sport', _selectedSport!);
      await prefs.setString('grade', _selectedGrade!);
      await prefs.setString('gender', _selectedGender!);

      if (mounted) {
        Navigator.pushReplacementNamed(
          context,
          '/coach_home',
          arguments: {
            'teamName': _teamNameController.text,
            'sport': _selectedSport,
            'grade': _selectedGrade,
            'gender': _selectedGender,
          },
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please complete all fields')),
      );
    }
  }

  @override
  void dispose() {
    _teamNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: darkBackground,
      appBar: AppBar(
        backgroundColor: efficialsBlack,
        title: const Text('Team Setup', style: appBarTextStyle),
        elevation: 0,
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
                  'Let\'s set up your team profile',
                  style: headlineStyle,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  'This information helps officials and other teams identify you',
                  style: TextStyle(
                    fontSize: 16,
                    color: secondaryTextColor,
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
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Team Name',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: primaryTextColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _teamNameController,
                        decoration:
                            textFieldDecoration('Ex. Maryville Redwings'),
                        style: textFieldTextStyle,
                        textCapitalization: TextCapitalization.words,
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Sport',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: primaryTextColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        decoration: textFieldDecoration('Select Sport'),
                        style: textFieldTextStyle,
                        dropdownColor: darkSurface,
                        iconEnabledColor: efficialsYellow,
                        value: _selectedSport,
                        items: sports.map((sport) {
                          return DropdownMenuItem(
                            value: sport,
                            child: Text(sport, style: textFieldTextStyle),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedSport = value;
                          });
                        },
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Grade Level',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: primaryTextColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        decoration: textFieldDecoration('Select Grade Level'),
                        style: textFieldTextStyle,
                        dropdownColor: darkSurface,
                        iconEnabledColor: efficialsYellow,
                        value: _selectedGrade,
                        items: grades.map((grade) {
                          return DropdownMenuItem(
                            value: grade,
                            child: Text(grade, style: textFieldTextStyle),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedGrade = value;
                            _updateGenderOptions(value);
                          });
                        },
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Gender',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: primaryTextColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        decoration: textFieldDecoration('Select Gender'),
                        style: textFieldTextStyle,
                        dropdownColor: darkSurface,
                        iconEnabledColor: efficialsYellow,
                        value: _selectedGender,
                        items: genders.map((gender) {
                          return DropdownMenuItem(
                            value: gender,
                            child: Text(gender, style: textFieldTextStyle),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedGender = value;
                          });
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
                ElevatedButton(
                  onPressed: _onContinue,
                  style: elevatedButtonStyle(
                    padding: const EdgeInsets.symmetric(
                        vertical: 15, horizontal: 50),
                  ),
                  child: const Text(
                    'Continue',
                    style: signInButtonTextStyle,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
