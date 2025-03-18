import 'package:flutter/material.dart';
import 'theme.dart';

class NameScheduleScreen extends StatefulWidget {
  const NameScheduleScreen({super.key});

  @override
  State<NameScheduleScreen> createState() => _NameScheduleScreenState();
}

class _NameScheduleScreenState extends State<NameScheduleScreen> {
  final _nameController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _handleContinue() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a schedule name!')),
      );
      return;
    }
    // Placeholder: Navigate to next screen with the name (to be implemented)
    Navigator.pushNamed(context, '/next_screen', arguments: {'scheduleName': name});
  }

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    final sport = args['sport'] as String;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: efficialsBlue,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, size: 36, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Name Schedule',
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
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    'Provide a name for your new ${sport.toUpperCase()} schedule. The name you choose should identify the level of competition.',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20), // Reduced from 60 to 20
                  TextField(
                    controller: _nameController,
                    decoration: textFieldDecoration('Ex. - Varsity Football'),
                    style: const TextStyle(fontSize: 18),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Note: There is no need to specify a time period for your schedule. For example, use "Varsity Football" rather than "2025 Varsity Football".',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                    textAlign: TextAlign.left,
                  ),
                  const SizedBox(height: 60),
                  Center(
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
        ),
      ),
    );
  }
}