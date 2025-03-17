import 'package:flutter/material.dart';
import 'theme.dart';

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
    final sport = args['sport'] as String;
    final existingLists = args['existingLists'] as List<String>;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: efficialsBlue,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, size: 36, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Name List',
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
                  Text(
                    'Name your list of $sport officials.',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black), // Updated: Made text black
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 60),
                  TextField(
                    controller: _nameController,
                    decoration: textFieldDecoration('Ex. Varsity $sport Officials'),
                    textAlign: TextAlign.left,
                    style: const TextStyle(fontSize: 18),
                    enableSuggestions: false,
                    autocorrect: false,
                    showCursor: true,
                  ),
                  const SizedBox(height: 60),
                  ElevatedButton(
                    onPressed: () {
                      final name = _nameController.text.trim();
                      if (name.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Please enter a list name!')),
                        );
                      } else if (existingLists.contains(name)) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('List name must be unique!')),
                        );
                      } else if (RegExp(r'^\s+$').hasMatch(name)) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('List name cannot be just spaces!')),
                        );
                      } else {
                        Navigator.pushNamed(
                          context,
                          '/populate_roster',
                          arguments: {'sport': sport, 'listName': name},
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