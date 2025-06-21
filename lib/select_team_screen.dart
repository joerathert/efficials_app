import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'theme.dart'; // For efficialsBlue, textFieldDecoration, headlineStyle, signInButtonTextStyle, appBarTextStyle

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
    'Baseball', 'Basketball', 'Football', 'Soccer', 'Softball', 'Volleyball'
  ]; // From select_sport_screen.dart
  final List<String> grades = [
    '6U', '7U', '8U', '9U', '10U', '11U', '12U', '13U', '14U', '15U', '16U', '17U', '18U', 'Adult'
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

  void _onContinue() {
    if (_teamNameController.text.isNotEmpty &&
        _selectedSport != null &&
        _selectedGrade != null &&
        _selectedGender != null) {
      final prefs = SharedPreferences.getInstance();
      prefs.then((prefs) {
        prefs.setBool('team_setup_completed', true); // Mark team setup as done
      });
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
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please complete all fields')),
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
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: efficialsBlue,
        title: Text('Team Setup', style: appBarTextStyle), // Add "Team Setup" title
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 40), // Maintain initial spacing
                TextField(
                  controller: _teamNameController,
                  decoration: textFieldDecoration('Team Name (Ex. Maryville Redwings)'), // Update hint text
                ),
                SizedBox(height: 8),
                Text(
                  'Your team name is how officials and other teams in your league will identify you.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                SizedBox(height: 20),
                DropdownButtonFormField<String>(
                  decoration: textFieldDecoration('Select Sport'),
                  value: _selectedSport,
                  items: sports.map((sport) {
                    return DropdownMenuItem(
                      value: sport,
                      child: Text(sport),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedSport = value;
                    });
                  },
                ),
                SizedBox(height: 20),
                DropdownButtonFormField<String>(
                  decoration: textFieldDecoration('Select Grade Level'),
                  value: _selectedGrade,
                  items: grades.map((grade) {
                    return DropdownMenuItem(
                      value: grade,
                      child: Text(grade),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedGrade = value;
                      _updateGenderOptions(value);
                    });
                  },
                ),
                SizedBox(height: 20),
                DropdownButtonFormField<String>(
                  decoration: textFieldDecoration('Select Gender'),
                  value: _selectedGender,
                  items: genders.map((gender) {
                    return DropdownMenuItem(
                      value: gender,
                      child: Text(gender),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedGender = value;
                    });
                  },
                ),
                SizedBox(height: 30), // Spacing above Continue button
                Center( // Center the Continue button
                  child: ElevatedButton(
                    onPressed: _onContinue,
                    style: elevatedButtonStyle(),
                    child: Text(
                      'Continue',
                      style: signInButtonTextStyle,
                    ),
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