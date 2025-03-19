import 'package:flutter/material.dart';
import 'theme.dart';

class SchedulerSignUpStep2 extends StatefulWidget {
  const SchedulerSignUpStep2({super.key});

  @override
  _SchedulerSignUpStep2State createState() => _SchedulerSignUpStep2State();
}

class _SchedulerSignUpStep2State extends State<SchedulerSignUpStep2> {
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _organizationController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  void _handleContinue() {
    // Temporarily removed validation for development
    final args = ModalRoute.of(context)!.settings.arguments as Map<String, String>;
    Navigator.pushNamed(context, '/add_photo', arguments: {
      'email': args['email'],
      'password': args['password'],
      'firstName': _firstNameController.text.trim(),
      'lastName': _lastNameController.text.trim(),
      'organization': _organizationController.text.trim(),
      'phone': _phoneController.text.trim(),
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Scheduler Sign Up'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 40),
                TextField(
                  controller: _firstNameController,
                  decoration: textFieldDecoration('First Name'),
                  textCapitalization: TextCapitalization.words,
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _lastNameController,
                  decoration: textFieldDecoration('Last Name'),
                  textCapitalization: TextCapitalization.words,
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _organizationController,
                  decoration: textFieldDecoration('Organization'),
                  textCapitalization: TextCapitalization.words,
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _phoneController,
                  decoration: textFieldDecoration('Phone Number'),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 30),
                ElevatedButton(
                  onPressed: _handleContinue,
                  style: elevatedButtonStyle(),
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
    _firstNameController.dispose();
    _lastNameController.dispose();
    _organizationController.dispose();
    _phoneController.dispose();
    super.dispose();
  }
}