import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'theme.dart';

class AthleticDirectorSetupScreen extends StatefulWidget {
  const AthleticDirectorSetupScreen({super.key});

  @override
  State<AthleticDirectorSetupScreen> createState() => _AthleticDirectorSetupScreenState();
}

class _AthleticDirectorSetupScreenState extends State<AthleticDirectorSetupScreen> {
  final TextEditingController _schoolNameController = TextEditingController();
  final TextEditingController _mascotController = TextEditingController();

  void _handleContinue() async {
    if (_schoolNameController.text.trim().isEmpty || _mascotController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please complete all fields')),
      );
      return;
    }

    // Save the Athletic Director information
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('ad_school_name', _schoolNameController.text.trim());
    await prefs.setString('ad_mascot', _mascotController.text.trim());
    await prefs.setBool('ad_setup_completed', true);

    // Navigate to Athletic Director Home
    Navigator.pushReplacementNamed(context, '/athletic_director_home');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: efficialsBlue,
        title: const Icon(
          Icons.sports,
          color: Colors.white,
          size: 32,
        ),
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false, // Remove back button since this is required setup
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
                  'School Information',
                  style: headlineStyle,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Enter your school details to complete setup',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
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
                        'School Name',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _schoolNameController,
                        decoration: textFieldDecoration('Enter your school name'),
                        textCapitalization: TextCapitalization.words,
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'School Mascot',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _mascotController,
                        decoration: textFieldDecoration('Enter your school mascot'),
                        textCapitalization: TextCapitalization.words,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
                ElevatedButton(
                  onPressed: _handleContinue,
                  style: elevatedButtonStyle(
                    padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 50),
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
    _schoolNameController.dispose();
    _mascotController.dispose();
    super.dispose();
  }
}