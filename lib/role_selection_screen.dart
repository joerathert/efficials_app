import 'package:flutter/material.dart';
import 'theme.dart';

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Sign Up'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text(
                'Are you a Scheduler or an Official?',
                style: headlineStyle,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/scheduler_signup_step1');
                },
                style: elevatedButtonStyle(
                  padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 40),
                ),
                child: const Text('Scheduler', style: signInButtonTextStyle),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Official sign-up not implemented yet')),
                  );
                },
                style: elevatedButtonStyle(
                  padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 40),
                ),
                child: const Text('Official', style: signInButtonTextStyle),
              ),
            ],
          ),
        ),
      ),
    );
  }
}