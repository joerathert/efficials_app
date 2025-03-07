import 'package:flutter/material.dart';
import 'theme.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)!.settings.arguments as Map<String, String>?;
    final name = args != null ? '${args['firstName']} ${args['lastName']}' : 'User';

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Home'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'Hi, $name!\nYou’ve been given 1 free game token.',
                style: headlineStyle,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Create Game not implemented yet')),
                  );
                },
                style: elevatedButtonStyle(),
                child: const Text('Create First Game', style: signInButtonTextStyle),
              ),
            ],
          ),
        ),
      ),
    );
  }
}