import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'theme.dart';

class FilterSettingsScreen extends StatefulWidget {
  const FilterSettingsScreen({super.key});

  @override
  State<FilterSettingsScreen> createState() => _FilterSettingsScreenState();
}

class _FilterSettingsScreenState extends State<FilterSettingsScreen> {
  bool ihsaRegistered = false;
  bool ihsaRecognized = false;
  bool ihsaCertified = false;
  final _yearsController = TextEditingController();
  final Map<String, bool> competitionLevels = {
    'Grade School': false,
    'Middle School': false,
    'Underclass': false,
    'JV': false,
    'Varsity': false,
    'College': false,
    'Adult': false,
  };
  final _radiusController = TextEditingController();

  @override
  void dispose() {
    _yearsController.dispose();
    _radiusController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    final sport = args['sport'] as String;
    final locationData = args['locationData'] as Map<String, dynamic>?;
    final isAwayGame = args['isAwayGame'] as bool? ?? false;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: efficialsBlue,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, size: 36, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Filter Settings', style: appBarTextStyle),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('IHSA Certifications', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  CheckboxListTile(
                    title: const Text('IHSA - Registered', style: TextStyle(fontSize: 18)),
                    value: ihsaRegistered,
                    onChanged: (value) => setState(() => ihsaRegistered = value ?? false),
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                    dense: true,
                    activeColor: efficialsBlue,
                  ),
                  CheckboxListTile(
                    title: const Text('IHSA - Recognized', style: TextStyle(fontSize: 18)),
                    value: ihsaRecognized,
                    onChanged: (value) => setState(() => ihsaRecognized = value ?? false),
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                    dense: true,
                    activeColor: efficialsBlue,
                  ),
                  CheckboxListTile(
                    title: const Text('IHSA - Certified', style: TextStyle(fontSize: 18)),
                    value: ihsaCertified,
                    onChanged: (value) => setState(() => ihsaCertified = value ?? false),
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                    dense: true,
                    activeColor: efficialsBlue,
                  ),
                  const SizedBox(height: 16),
                  const Text('Experience', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _yearsController,
                    decoration: textFieldDecoration('Minimum years of experience'),
                    textAlign: TextAlign.left,
                    style: const TextStyle(fontSize: 18),
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.next,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    maxLength: 2,
                    buildCounter: (context, {required currentLength, required maxLength, required isFocused}) => null,
                  ),
                  const SizedBox(height: 16),
                  const Text('Competition Levels', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Column(
                    children: competitionLevels.keys.map((level) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: CheckboxListTile(
                          title: Text(level, style: const TextStyle(fontSize: 18)),
                          value: competitionLevels[level],
                          onChanged: (value) => setState(() => competitionLevels[level] = value ?? false),
                          controlAffinity: ListTileControlAffinity.leading,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                          dense: true,
                          activeColor: efficialsBlue,
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  const Text('Location', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  if (isAwayGame) ...[
                    const Text(
                      'Radius filtering unavailable for Away Games.',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  ] else ...[
                    Text(
                      'Game Location: ${locationData?['name'] ?? 'Not set'}',
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _radiusController,
                      decoration: textFieldDecoration('Search Radius (miles)').copyWith(
                        hintText: 'Enter search radius (miles)',
                      ),
                      textAlign: TextAlign.left,
                      style: const TextStyle(fontSize: 18),
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.done,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      maxLength: 3,
                      buildCounter: (context, {required currentLength, required maxLength, required isFocused}) => null,
                    ),
                  ],
                  const SizedBox(height: 30),
                  Center(
                    child: ElevatedButton(
                      onPressed: () {
                        if (!competitionLevels.values.any((selected) => selected)) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Please select at least one competition level!')),
                          );
                          return;
                        }
                        if (!isAwayGame && _radiusController.text.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Please specify a search radius!')),
                          );
                          return;
                        }
                        final selectedLevels = competitionLevels.entries
                            .where((entry) => entry.value)
                            .map((entry) => entry.key)
                            .toList();
                        Navigator.pop(
                          context,
                          {
                            'sport': sport,
                            'ihsaRegistered': ihsaRegistered,
                            'ihsaRecognized': ihsaRecognized,
                            'ihsaCertified': ihsaCertified,
                            'minYears': _yearsController.text.isNotEmpty ? int.parse(_yearsController.text) : 0,
                            'levels': selectedLevels,
                            'locationData': locationData,
                            'radius': isAwayGame ? null : int.parse(_radiusController.text),
                          },
                        );
                      },
                      style: elevatedButtonStyle(),
                      child: const Text('Apply Filters', style: signInButtonTextStyle),
                    ),
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