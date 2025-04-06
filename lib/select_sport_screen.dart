import 'package:flutter/material.dart';
import 'theme.dart';

class SelectSportScreen extends StatefulWidget {
  const SelectSportScreen({super.key});

  @override
  State<SelectSportScreen> createState() => _SelectSportScreenState();
}

class _SelectSportScreenState extends State<SelectSportScreen> {
  String? selectedSport;
  final List<String> sports = ['Football', 'Basketball', 'Baseball', 'Soccer', 'Volleyball', 'Other'];
  bool _isInitialized = false; // Flag to ensure initialization happens once

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Only initialize once
    if (!_isInitialized) {
      // Check if coming from a template flow and pre-fill the sport
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (args != null && args['fromTemplate'] == true && args['sport'] != null) {
        setState(() {
          selectedSport = args['sport'] as String;
        });
      }
      _isInitialized = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: efficialsBlue,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, size: 36, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Select Sport',
          style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Select a sport for your schedule.',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  DropdownButtonFormField<String>(
                    decoration: textFieldDecoration('Sport'),
                    value: selectedSport,
                    onChanged: (newValue) => setState(() => selectedSport = newValue),
                    items: sports.map((value) => DropdownMenuItem(value: value, child: Text(value))).toList(),
                  ),
                  const SizedBox(height: 60),
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
                          const SnackBar(content: Text('Please select a sport!')),
                        );
                      }
                    },
                    style: elevatedButtonStyle(),
                    child: const Text('Continue', style: signInButtonTextStyle),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}