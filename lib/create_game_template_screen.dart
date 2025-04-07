import 'package:flutter/material.dart';
import 'theme.dart';
import 'game_template.dart';

class CreateGameTemplateScreen extends StatefulWidget {
  const CreateGameTemplateScreen({super.key});

  @override
  State<CreateGameTemplateScreen> createState() => _CreateGameTemplateScreenState();
}

class _CreateGameTemplateScreenState extends State<CreateGameTemplateScreen> {
  final _nameController = TextEditingController();
  String? selectedSport;
  TimeOfDay? selectedTime;
  String? scheduleName;
  List<String> sports = ['Baseball', 'Basketball', 'Football', 'Soccer', 'Volleyball']; // Example sports

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
    if (args != null) {
      scheduleName = args['scheduleName'] as String?;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: selectedTime ?? TimeOfDay.now(),
    );
    if (picked != null && picked != selectedTime) {
      setState(() {
        selectedTime = picked;
      });
    }
  }

  void _handleContinue() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a template name!')),
      );
      return;
    }
    if (selectedSport == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a sport!')),
      );
      return;
    }

    // Create a new template
    final newTemplate = GameTemplate(
      id: DateTime.now().millisecondsSinceEpoch.toString(), // Added id
      name: name,
      sport: selectedSport,
      includeSport: true,
      time: selectedTime, // Pass TimeOfDay directly
    );

    // Return the new template to SelectGameTemplateScreen
    Navigator.pop(context, newTemplate);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: efficialsBlue,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, size: 36, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Create Game Template', style: appBarTextStyle),
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
                    'Create a new game template',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _nameController,
                    decoration: textFieldDecoration('Template Name'),
                    style: const TextStyle(fontSize: 18),
                  ),
                  const SizedBox(height: 20),
                  DropdownButtonFormField<String>(
                    decoration: textFieldDecoration('Sport'),
                    value: selectedSport,
                    hint: const Text('Select a sport'),
                    onChanged: (newValue) {
                      setState(() {
                        selectedSport = newValue;
                      });
                    },
                    items: sports.map((sport) {
                      return DropdownMenuItem(
                        value: sport,
                        child: Text(sport),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),
                  ListTile(
                    title: Text(
                      selectedTime == null
                          ? 'Select Time (Optional)'
                          : 'Time: ${selectedTime!.format(context)}',
                      style: const TextStyle(fontSize: 18),
                    ),
                    trailing: const Icon(Icons.access_time),
                    onTap: () => _selectTime(context),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _handleContinue,
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