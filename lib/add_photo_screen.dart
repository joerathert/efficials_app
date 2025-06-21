import 'package:flutter/material.dart';
import 'theme.dart';

class AddPhotoScreen extends StatelessWidget {
  const AddPhotoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)!.settings.arguments as Map<String, String>? ?? {};

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: efficialsBlue,
        title: const Text('Add Photo (Optional)', style: appBarTextStyle),
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
                    size: 200,
                    color: Colors.grey,
                  ),
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
                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 30),
                      minimumSize: const Size(150, 40),
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