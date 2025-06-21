import 'package:flutter/material.dart';
import 'theme.dart';

class SchedulerSignUpStep2 extends StatelessWidget {
  const SchedulerSignUpStep2({super.key});

  void _selectRole(BuildContext context, String role) {
    final args = ModalRoute.of(context)!.settings.arguments as Map<String, String>? ?? {};
    Navigator.pushNamed(context, '/add_photo', arguments: {
      'email': args['email'] ?? '',
      'password': args['password'] ?? '',
      'firstName': args['firstName'] ?? '',
      'lastName': args['lastName'] ?? '',
      'organization': args['organization'] ?? '',
      'phone': args['phone'] ?? '',
      'role': role,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: efficialsBlue,
        title: const Text('Select Role', style: appBarTextStyle),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text(
                'Which role best describes you?',
                style: headlineStyle,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: () => _selectRole(context, 'Athletic Director'),
                style: elevatedButtonStyle(
                  padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 40),
                ),
                child: const Text('Athletic Director', style: signInButtonTextStyle),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => _selectRole(context, 'Assigner'),
                style: elevatedButtonStyle(
                  padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 40),
                ),
                child: const Text('Assigner', style: signInButtonTextStyle),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => _selectRole(context, 'Coach'),
                style: elevatedButtonStyle(
                  padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 40),
                ),
                child: const Text('Coach', style: signInButtonTextStyle),
              ),
            ],
          ),
        ),
      ),
    );
  }
}