import 'package:flutter/material.dart';
import 'theme.dart';

class SchedulerSignUpStep1 extends StatefulWidget {
  const SchedulerSignUpStep1({super.key});

  @override
  _SchedulerSignUpStep1State createState() => _SchedulerSignUpStep1State();
}

class _SchedulerSignUpStep1State extends State<SchedulerSignUpStep1> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _organizationController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  void _handleContinue() {
    // TODO: Add validation for required fields (empty checks, password match, email format)
    Navigator.pushNamed(context, '/scheduler_signup_step2', arguments: {
      'email': _emailController.text.trim(),
      'password': _passwordController.text.trim(),
      'firstName': _firstNameController.text.trim(),
      'lastName': _firstNameController.text.trim(),
      'organization': _organizationController.text.trim(),
      'phone': _phoneController.text.trim(),
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: efficialsBlue,
        title: const Text('Scheduler Sign Up', style: appBarTextStyle),
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
                  controller: _emailController,
                  decoration: textFieldDecoration('Email'),
                  keyboardType: TextInputType.emailAddress,
                  textCapitalization: TextCapitalization.none,
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _passwordController,
                  decoration: textFieldDecoration('Password'),
                  obscureText: true,
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _confirmPasswordController,
                  decoration: textFieldDecoration('Confirm Password'),
                  obscureText: true,
                ),
                const SizedBox(height: 20),
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
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _organizationController.dispose();
    _phoneController.dispose();
    super.dispose();
  }
}