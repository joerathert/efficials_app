import 'package:flutter/material.dart';
import 'theme.dart';

class CreateNewListScreen extends StatefulWidget {
  const CreateNewListScreen({super.key});

  @override
  State<CreateNewListScreen> createState() => _CreateNewListScreenState();
}

class _CreateNewListScreenState extends State<CreateNewListScreen> {
  String? selectedSport;
  final List<String> sports = ['Football', 'Basketball', 'Baseball', 'Soccer', 'Volleyball', 'Other'];

  @override
  Widget build(BuildContext context) {
    final existingLists = ModalRoute.of(context)!.settings.arguments as List<String>;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: efficialsBlue,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, size: 36, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Create New List',
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
                children: [
                  const Text(
                    'Choose a sport for your new list.',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 30),
                  DropdownButtonFormField<String>(
                    decoration: textFieldDecoration('Sport'),
                    value: selectedSport,
                    onChanged: (newValue) => setState(() => selectedSport = newValue),
                    items: sports.map((value) => DropdownMenuItem(value: value, child: Text(value))).toList(),
                  ),
                  const SizedBox(height: 30),
                  ElevatedButton(
                    onPressed: () {
                      if (selectedSport != null) {
                        Navigator.pushNamed(
                          context,
                          '/name_list',
                          arguments: {
                            'sport': selectedSport,
                            'existingLists': existingLists,
                          },
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Please select a sport!')),
                        );
                      }
                    },
                    style: elevatedButtonStyle(),
                    child: const Text('Continue', style: signInButtonTextStyle),
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