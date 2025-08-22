import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

// Simple test app to check if Flutter web works
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  print('Starting Efficials App - Web: $kIsWeb');
  
  runApp(const TestEfficialsApp());
}

class TestEfficialsApp extends StatelessWidget {
  const TestEfficialsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Efficials Test',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const TestHomeScreen(),
    );
  }
}

class TestHomeScreen extends StatelessWidget {
  const TestHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Efficials Web Test'),
        backgroundColor: Colors.blue,
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.sports_basketball,
              size: 100,
              color: Colors.blue,
            ),
            SizedBox(height: 20),
            Text(
              'Efficials App',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 10),
            Text(
              'Web Version Working!',
              style: TextStyle(
                fontSize: 18,
                color: Colors.green,
              ),
            ),
            SizedBox(height: 20),
            Card(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'This is a test version to verify Flutter web functionality.\n'
                  'If you can see this, the web build is working correctly.',
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}