import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'theme.dart';

class AddPhotoScreen extends StatelessWidget {
  const AddPhotoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final args =
        ModalRoute.of(context)!.settings.arguments as Map<String, String>? ??
            {};

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: efficialsBlue,
        title: const Icon(
          Icons.sports,
          color: Colors.white,
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
                'Add Your Photo',
                style: headlineStyle,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'This helps others recognize you (optional)',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.white,
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
                  children: [
                    Container(
                      width: 150,
                      height: 150,
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.grey[300]!, width: 2),
                      ),
                      child: const Icon(
                        Icons.person,
                        size: 80,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 32),
                    const Text(
                      'Choose a photo source',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Gallery not implemented yet')),
                          );
                        },
                        style: elevatedButtonStyle(
                          padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 24),
                        ),
                        icon: const Icon(Icons.photo_library, color: Colors.white),
                        label: const Text('Choose from Gallery', style: signInButtonTextStyle),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Camera not implemented yet')),
                          );
                        },
                        style: elevatedButtonStyle(
                          padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 24),
                        ),
                        icon: const Icon(Icons.camera_alt, color: Colors.white),
                        label: const Text('Take a Photo', style: signInButtonTextStyle),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              TextButton(
                onPressed: () async {
                  final role = args['role'] ?? 'Athletic Director';

                  // Save the scheduler type to SharedPreferences
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setString('schedulerType', role);

                  String route;
                  switch (role) {
                    case 'Assigner':
                      route = '/assigner_sport_selection';
                      break;
                    case 'Coach':
                      route = '/select_team';
                      break;
                    case 'Athletic Director':
                      route = '/athletic_director_setup';
                      break;
                    default:
                      route = '/athletic_director_home';
                  }
                  Navigator.pushReplacementNamed(context, route,
                      arguments: args);
                },
                child: Text(
                  'Skip for Now',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                    decoration: TextDecoration.underline,
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
