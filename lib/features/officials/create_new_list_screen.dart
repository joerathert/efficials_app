import 'package:flutter/material.dart';
import '../../shared/theme.dart';

class CreateNewListScreen extends StatefulWidget {
  const CreateNewListScreen({super.key});

  @override
  State<CreateNewListScreen> createState() => _CreateNewListScreenState();
}

class _CreateNewListScreenState extends State<CreateNewListScreen> {
  String? selectedSport;
  final List<String> sports = [
    'Football',
    'Basketball',
    'Baseball',
    'Soccer',
    'Volleyball',
    'Other'
  ];
  List<String> existingLists = [];
  bool isFromGameCreation = false;
  bool shouldAutoNavigate = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
    existingLists = args?['existingLists'] as List<String>? ?? [];
    isFromGameCreation = args?['fromGameCreation'] == true;
    
    // If we're coming from game creation and have a sport, auto-select it
    if (isFromGameCreation && args?['sport'] != null) {
      selectedSport = args!['sport'] as String?;
      shouldAutoNavigate = true;
    }
  }

  @override
  void initState() {
    super.initState();
    // Use WidgetsBinding to auto-navigate after the widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (shouldAutoNavigate) {
        _continueToNameList();
      }
    });
  }

  void _continueToNameList() {
    final args = ModalRoute.of(context)!.settings.arguments
            as Map<String, dynamic>? ??
        {};
    Navigator.pushNamed(
      context,
      '/name_list',
      arguments: {
        'sport': selectedSport,
        'existingLists': existingLists,
        'locationData': args['locationData'],
        'isAwayGame': args['isAwayGame'] ?? false,
        'fromGameCreation': isFromGameCreation,
        ...args, // Pass through all original arguments
      },
    ).then((result) {
      if (result != null) {
        Navigator.pop(context, result);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
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
                'Create New List',
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
                    const Text(
                      'Choose a sport for your new list',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    DropdownButtonFormField<String>(
                      decoration: textFieldDecoration('Sport'),
                      value: selectedSport,
                      hint: const Text('Select a sport',
                          style: TextStyle(color: efficialsGray)),
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                      dropdownColor: darkSurface,
                      onChanged: (newValue) =>
                          setState(() => selectedSport = newValue),
                      items: sports
                          .map((value) => DropdownMenuItem(
                              value: value,
                              child: Text(value,
                                  style: const TextStyle(color: Colors.white))))
                          .toList(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: () {
                  if (selectedSport != null) {
                    _continueToNameList();
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Please select a sport!'),
                        backgroundColor: darkSurface,
                      ),
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
    );
  }
}
