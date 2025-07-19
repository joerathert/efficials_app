import 'package:flutter/material.dart';
import '../../shared/theme.dart';

class OfficialSignUpStep1 extends StatefulWidget {
  const OfficialSignUpStep1({super.key});

  @override
  _OfficialSignUpStep1State createState() => _OfficialSignUpStep1State();
}

class _OfficialSignUpStep1State extends State<OfficialSignUpStep1> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  bool _acceptedTerms = false;

  void _handleContinue() {
    // For testing purposes, only require email or provide defaults
    final email = _emailController.text.trim().isNotEmpty 
        ? _emailController.text.trim() 
        : 'test@example.com';
    final password = _passwordController.text.trim().isNotEmpty 
        ? _passwordController.text.trim() 
        : 'password123';
    final confirmPassword = _confirmPasswordController.text.trim().isNotEmpty 
        ? _confirmPasswordController.text.trim() 
        : 'password123';
    final firstName = _firstNameController.text.trim().isNotEmpty 
        ? _firstNameController.text.trim() 
        : 'Test';
    final lastName = _lastNameController.text.trim().isNotEmpty 
        ? _lastNameController.text.trim() 
        : 'Official';
    final phone = _phoneController.text.trim();

    // Validate password match if both are provided
    if (_passwordController.text.trim().isNotEmpty && 
        _confirmPasswordController.text.trim().isNotEmpty &&
        password != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passwords do not match')),
      );
      return;
    }

    // Validate email format if provided
    if (_emailController.text.trim().isNotEmpty && 
        !RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid email address')),
      );
      return;
    }

    Navigator.pushNamed(context, '/official_signup_step2', arguments: {
      'email': email,
      'password': password,
      'firstName': firstName,
      'lastName': lastName,
      'phone': phone,
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
          color: efficialsYellow,
          size: 32,
        ),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: efficialsWhite),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              const Text(
                'Official Registration',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: efficialsYellow,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Step 1 of 4: Basic Information',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 40),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      TextField(
                        controller: _emailController,
                        decoration: textFieldDecoration('Email (or leave blank for test@example.com)'),
                        style: const TextStyle(fontSize: 18, color: Colors.white),
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 20),
                      TextField(
                        controller: _passwordController,
                        decoration: textFieldDecoration('Password (or leave blank for default)'),
                        style: const TextStyle(fontSize: 18, color: Colors.white),
                        obscureText: true,
                      ),
                      const SizedBox(height: 20),
                      TextField(
                        controller: _confirmPasswordController,
                        decoration: textFieldDecoration('Confirm Password (or leave blank)'),
                        style: const TextStyle(fontSize: 18, color: Colors.white),
                        obscureText: true,
                      ),
                      const SizedBox(height: 20),
                      TextField(
                        controller: _firstNameController,
                        decoration: textFieldDecoration('First Name (or leave blank for Test)'),
                        style: const TextStyle(fontSize: 18, color: Colors.white),
                      ),
                      const SizedBox(height: 20),
                      TextField(
                        controller: _lastNameController,
                        decoration: textFieldDecoration('Last Name (or leave blank for Official)'),
                        style: const TextStyle(fontSize: 18, color: Colors.white),
                      ),
                      const SizedBox(height: 20),
                      TextField(
                        controller: _phoneController,
                        decoration: textFieldDecoration('Phone Number'),
                        style: const TextStyle(fontSize: 18, color: Colors.white),
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 30),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Checkbox(
                            value: _acceptedTerms,
                            onChanged: (value) {
                              setState(() {
                                _acceptedTerms = value ?? false;
                              });
                            },
                            activeColor: efficialsYellow,
                            checkColor: efficialsBlack,
                          ),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'I accept the Terms of Service and Privacy Policy',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 40),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _handleContinue,
                          style: elevatedButtonStyle(),
                          child: const Text('Continue', style: signInButtonTextStyle),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
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
    _phoneController.dispose();
    super.dispose();
  }
}