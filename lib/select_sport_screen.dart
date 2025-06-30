import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'theme.dart';

class SelectSportScreen extends StatefulWidget {
  const SelectSportScreen({super.key});

  @override
  State<SelectSportScreen> createState() => _SelectSportScreenState();
}

class _SelectSportScreenState extends State<SelectSportScreen> {
  String? selectedSport;
  List<String> sports = [
    'Football',
    'Basketball',
    'Baseball',
    'Soccer',
    'Volleyball',
    'Other'
  ];
  bool _isInitialized = false; // Flag to ensure initialization happens once
  bool isLoading = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Only initialize once
    if (!_isInitialized) {
      _loadSchedulerConstraints();
      _isInitialized = true;
    }
  }

  Future<void> _loadSchedulerConstraints() async {
    final prefs = await SharedPreferences.getInstance();
    final schedulerType = prefs.getString('schedulerType');
    String? userSport;

    if (schedulerType == 'Assigner') {
      userSport = prefs.getString('assigner_sport');
    } else if (schedulerType == 'Coach') {
      userSport = prefs.getString('sport');
    }

    setState(() {
      // Filter sports based on scheduler type
      if (schedulerType == 'Assigner' && userSport != null) {
        // Assigners only see their assigned sport
        sports = [userSport];
        selectedSport = userSport;
      } else if (schedulerType == 'Coach' && userSport != null) {
        // Coaches only see their team's sport
        sports = [userSport];
        selectedSport = userSport;
      }
      // Athletic Directors keep all sports

      // Check if coming from a template flow and pre-fill the sport
      final args =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (args != null &&
          args['fromTemplate'] == true &&
          args['sport'] != null) {
        selectedSport = args['sport'] as String;
      }

      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: darkBackground,
      appBar: AppBar(
        backgroundColor: efficialsBlack,
        title: const Icon(
          Icons.sports,
          color: darkSurface,
          size: 32,
        ),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: efficialsBlue))
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 40),
                    const Text(
                      'Select Sport',
                      style: headlineStyle,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Choose the sport for your new schedule',
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
                        children: [
                          DropdownButtonFormField<String>(
                            decoration: textFieldDecoration('Select a sport'),
                            value: selectedSport,
                            dropdownColor: darkSurface,
                            style: const TextStyle(
                                color: Colors.white, fontSize: 16),
                            onChanged: sports.length == 1
                                ? null
                                : (newValue) =>
                                    setState(() => selectedSport = newValue),
                            items: sports
                                .map((value) => DropdownMenuItem(
                                    value: value,
                                    child: Text(value,
                                        style: const TextStyle(color: Colors.white))))
                                .toList(),
                          ),
                          if (sports.length == 1 && selectedSport != null) ...[
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.blue.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.info_outline,
                                    color: Colors.blue,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Sport is pre-selected based on your role',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.blue.shade700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),
                    ElevatedButton(
                      onPressed: () {
                        if (selectedSport != null) {
                          Navigator.pushNamed(
                            context,
                            '/name_schedule',
                            arguments: {'sport': selectedSport},
                          ).then((result) {
                            // Forward the schedule name (a String) back to SelectScheduleScreen
                            Navigator.pop(context, result);
                          });
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Please select a sport!')),
                          );
                        }
                      },
                      style: elevatedButtonStyle(
                        padding: const EdgeInsets.symmetric(
                            vertical: 15, horizontal: 50),
                      ),
                      child:
                          const Text('Continue', style: signInButtonTextStyle),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
