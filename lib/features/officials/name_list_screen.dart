import 'package:flutter/material.dart';
import '../../shared/theme.dart';

class NameListScreen extends StatefulWidget {
  const NameListScreen({super.key});

  @override
  State<NameListScreen> createState() => _NameListScreenState();
}

class _NameListScreenState extends State<NameListScreen> {
  final _nameController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    final sport = args['sport'] as String? ?? 'Football';
    final existingLists = args['existingLists'] as List<String>? ?? [];

    return Scaffold(
      backgroundColor: darkBackground,
      appBar: AppBar(
        backgroundColor: efficialsBlack,
        title: const Icon(
          Icons.sports,
          color: efficialsYellow,
          size: 32,
        ),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: efficialsWhite),
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
                'Name List',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: efficialsYellow,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: darkSurface,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      'Name your list of $sport officials',
                      style: const TextStyle(
                        fontSize: 18,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    TextField(
                      controller: _nameController,
                      decoration: textFieldDecoration('Ex. Varsity $sport Officials'),
                      textAlign: TextAlign.left,
                      style: const TextStyle(fontSize: 18, color: Colors.white),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: () {
                  final name = _nameController.text.trim();
                  if (name.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Please enter a list name!'),
                        backgroundColor: darkSurface,
                      ),
                    );
                  } else if (existingLists.contains(name)) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('List name must be unique!'),
                        backgroundColor: darkSurface,
                      ),
                    );
                  } else if (RegExp(r'^\s+$').hasMatch(name)) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('List name cannot be just spaces!'),
                        backgroundColor: darkSurface,
                      ),
                    );
                  } else {
                    Navigator.pushNamed(
                      context,
                      '/populate_roster',
                      arguments: {
                        'sport': sport, 
                        'listName': name,
                        'fromGameCreation': true, // Ensure this flag is set
                        // Pass through ALL game creation context
                        ...args,
                        // Override specific values
                        'sport': sport,
                        'listName': name,
                        // Explicitly exclude selectedOfficials to start with clean slate
                        'selectedOfficials': null,
                      },
                    ).then((result) {
                      if (result != null && mounted) {
                        // Pass the result back to the lists screen
                        Navigator.pop(context, result);
                      }
                    });
                  }
                },
                style: elevatedButtonStyle(),
                child: const Text('Continue', style: signInButtonTextStyle),
              ),
            ],
          ),
        ),
      ),
    );
  }
}