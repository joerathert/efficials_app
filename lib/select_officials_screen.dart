import 'package:flutter/material.dart';
import 'theme.dart';

class SelectOfficialsScreen extends StatefulWidget {
  const SelectOfficialsScreen({super.key});

  @override
  State<SelectOfficialsScreen> createState() => _SelectOfficialsScreenState();
}

class _SelectOfficialsScreenState extends State<SelectOfficialsScreen> {
  bool _defaultChoice = false;

  void _showDifferenceDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Standard vs. Advanced'),
        content: const Text('Standard method uses basic filters to find officials. Advanced method allows detailed customization of filters for more specific selections.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close', style: TextStyle(color: efficialsBlue)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    final sport = args['sport'] as String? ?? 'Baseball';
    final listName = args['scheduleName'] as String? ?? 'New Roster';
    final listId = args['listId'] as int? ?? DateTime.now().millisecondsSinceEpoch;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: efficialsBlue,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, size: 36, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Select Officials',
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
                    'Choose a method for finding your officials.',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 60),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pushNamed(
                        context,
                        '/populate_roster',
                        arguments: {
                          ...args,
                          'sport': sport,
                          'listName': listName,
                          'listId': listId,
                          'method': 'standard',
                          'requiredCount': 2,
                        },
                      );
                    },
                    style: elevatedButtonStyle(),
                    child: const Text('Standard', style: signInButtonTextStyle),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pushNamed(
                        context,
                        '/advanced_officials_selection',
                        arguments: {
                          ...args,
                          'sport': sport,
                          'listName': listName,
                          'listId': listId,
                        },
                      );
                    },
                    style: elevatedButtonStyle(),
                    child: const Text('Advanced', style: signInButtonTextStyle),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pushNamed(
                        context,
                        '/lists_of_officials',
                        arguments: {
                          ...args,
                          'fromGameCreation': true,
                        },
                      ).then((result) {
                        if (result != null) {
                          Navigator.pushNamed(context, '/review_game_info', arguments: result);
                        }
                      });
                    },
                    style: elevatedButtonStyle(),
                    child: const Text('Use List', style: signInButtonTextStyle),
                  ),
                  const SizedBox(height: 20),
                  GestureDetector(
                    onTap: _showDifferenceDialog,
                    child: const Text(
                      'What\'s the difference?',
                      style: TextStyle(color: efficialsBlue, decoration: TextDecoration.underline),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Checkbox(
                        value: _defaultChoice,
                        onChanged: (value) => setState(() => _defaultChoice = value ?? false),
                        activeColor: efficialsBlue,
                      ),
                      const Text('Make this my default choice'),
                    ],
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