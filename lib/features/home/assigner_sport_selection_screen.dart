import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../shared/theme.dart';
import '../../shared/utils/utils.dart';

class AssignerSportSelectionScreen extends StatefulWidget {
  const AssignerSportSelectionScreen({super.key});

  @override
  State<AssignerSportSelectionScreen> createState() =>
      _AssignerSportSelectionScreenState();
}

class _AssignerSportSelectionScreenState
    extends State<AssignerSportSelectionScreen> {
  String? selectedSport;
  final TextEditingController _leagueNameController = TextEditingController();

  final List<String> sports = [
    'Baseball',
    'Basketball',
    'Football',
    'Soccer',
    'Softball',
    'Volleyball',
    'Wrestling',
    'Track & Field',
    'Cross Country',
    'Tennis',
    'Swimming',
    'Golf',
    'Lacrosse',
    'Hockey'
  ];

  @override
  void initState() {
    super.initState();
    _leagueNameController.addListener(_updateLeagueName);
  }

  void _updateLeagueName() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('league_name', _leagueNameController.text);
  }

  void _onContinue() async {
    if (_leagueNameController.text.isNotEmpty && selectedSport != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('assigner_sport', selectedSport!);
      await prefs.setString('league_name', _leagueNameController.text);
      await prefs.setBool('assigner_setup_completed', true);

      if (mounted) {
        Navigator.pushReplacementNamed(
          context,
          '/assigner_home',
          arguments: {
            'sport': selectedSport,
            'leagueName': _leagueNameController.text,
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
    _leagueNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: darkBackground,
      appBar: AppBar(
        backgroundColor: efficialsBlack,
        title: const Text('Assigner Setup', style: appBarTextStyle),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 40),
                TextField(
                  controller: _leagueNameController,
                  decoration: textFieldDecoration(
                      'League Name (Ex. Metro Basketball League)'),
                ),
                const SizedBox(height: 8),
                const Text(
                  'The league or organization you assign officials for.',
                  style: TextStyle(
                    fontSize: 12,
                    color: secondaryTextColor,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Select the sport you assign officials for:',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 3,
                  ),
                  itemCount: sports.length,
                  itemBuilder: (context, index) {
                    final sport = sports[index];
                    final isSelected = selectedSport == sport;

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          selectedSport = sport;
                        });
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: isSelected ? efficialsBlue : Colors.white,
                          border: Border.all(
                            color:
                                isSelected ? efficialsBlue : Colors.grey[300]!,
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              getSportIcon(sport),
                              color: isSelected
                                  ? Colors.white
                                  : getSportIconColor(sport),
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                sport,
                                style: TextStyle(
                                  color:
                                      isSelected ? Colors.white : Colors.black,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 30),
                Center(
                  child: ElevatedButton(
                    onPressed: _onContinue,
                    style: elevatedButtonStyle(),
                    child: const Text(
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
