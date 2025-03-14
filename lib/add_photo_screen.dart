import 'package:flutter/material.dart';
import 'theme.dart';

class AddPhotoScreen extends StatelessWidget {
  const AddPhotoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final Object? rawArgs = ModalRoute.of(context)?.settings.arguments;
    final Map<String, String> args = rawArgs is Map<String, String> ? rawArgs : {};

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Add Photo (Optional)'),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.account_circle,
                    size: 200, // Increased from 100 to 200 for a larger avatar
                    color: Colors.grey,
                  ), // Centered faceless avatar
                  const SizedBox(height: 40),
                  ElevatedButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Gallery not implemented yet')),
                      );
                    },
                    style: elevatedButtonStyle(),
                    child: const Text('Gallery', style: signInButtonTextStyle),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Camera not implemented yet')),
                      );
                    },
                    style: elevatedButtonStyle(),
                    child: const Text('Camera', style: signInButtonTextStyle),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/home', arguments: args);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: efficialsBlue,
                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 30), // Smaller size
                      minimumSize: const Size(150, 40), // Custom smaller minimum size
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Skip for Now', style: signInButtonTextStyle),
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