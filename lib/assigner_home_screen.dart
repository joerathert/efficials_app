import 'package:flutter/material.dart';
import 'theme.dart';

class AssignerHomeScreen extends StatelessWidget {
  const AssignerHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)!.settings.arguments as Map<String, String>? ?? {};
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: efficialsBlue,
        title: const Text('', style: appBarTextStyle), // Removed title
      ),
      body: const Center(
        child: Text('Welcome, Assigner!', style: TextStyle(fontSize: 24)),
      ),
    );
  }
}