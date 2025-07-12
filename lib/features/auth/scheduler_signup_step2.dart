import 'package:flutter/material.dart';
import '../../shared/theme.dart';

class SchedulerSignUpStep2 extends StatelessWidget {
  const SchedulerSignUpStep2({super.key});

  void _selectRole(BuildContext context, String role) {
    final args =
        ModalRoute.of(context)!.settings.arguments as Map<String, String>? ??
            {};
    Navigator.pushNamed(context, '/add_photo', arguments: {
      'email': args['email'] ?? '',
      'password': args['password'] ?? '',
      'firstName': args['firstName'] ?? '',
      'lastName': args['lastName'] ?? '',
      'phone': args['phone'] ?? '',
      'role': role,
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
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 40),
              const Text(
                'Select Your Role',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: efficialsYellow,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              Center(
                child: Container(
                  width: double.infinity,
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
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Text(
                        'Which role best describes you?',
                        style: homeTextStyle,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: 200,
                        child: ElevatedButton(
                          onPressed: () =>
                              _selectRole(context, 'Athletic Director'),
                          style: elevatedButtonStyle(
                            padding: const EdgeInsets.symmetric(
                                vertical: 15, horizontal: 32),
                          ),
                          child: const Text('Athletic Director',
                              style: signInButtonTextStyle),
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: 200,
                        child: ElevatedButton(
                          onPressed: () => _selectRole(context, 'Assigner'),
                          style: elevatedButtonStyle(
                            padding: const EdgeInsets.symmetric(
                                vertical: 15, horizontal: 32),
                          ),
                          child: const Text('Assigner',
                              style: signInButtonTextStyle),
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: 200,
                        child: ElevatedButton(
                          onPressed: () => _selectRole(context, 'Coach'),
                          style: elevatedButtonStyle(
                            padding: const EdgeInsets.symmetric(
                                vertical: 15, horizontal: 32),
                          ),
                          child:
                              const Text('Coach', style: signInButtonTextStyle),
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
}
