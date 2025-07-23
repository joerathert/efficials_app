import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../shared/theme.dart';
import '../../shared/services/database_helper.dart';

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
  String? defaultLocationName;
  String? defaultLocationAddress;

  @override
  void initState() {
    super.initState();
    _loadDefaultLocation();
  }

  Future<void> _loadDefaultLocation() async {
    try {
      final db = await DatabaseHelper().database;
      final adResult = await db.query(
        'users', 
        columns: ['school_address', 'school_name'],
        where: 'scheduler_type = ? AND school_address IS NOT NULL',
        whereArgs: ['athletic_director'],
        limit: 1
      );
      
      if (adResult.isNotEmpty && adResult.first['school_address'] != null) {
        setState(() {
          defaultLocationName = adResult.first['school_name'] as String?;
          defaultLocationAddress = adResult.first['school_address'] as String?;
        });
      }
    } catch (e) {
      print('Could not load AD school address: $e');
    }
  }

  @override
  void dispose() {
    _yearsController.dispose();
    _radiusController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final args =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    final sport = args['sport'] as String? ?? 'Football';
    final locationData = args['locationData'] as Map<String, dynamic>?;
    final isAwayGame = args['isAwayGame'] as bool? ?? false;

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
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 10),
                const Text(
                  'Filter Settings',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: efficialsYellow,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('IHSA Certifications',
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: efficialsYellow)),
                      const SizedBox(height: 12),
                      CheckboxListTile(
                        title: const Text('IHSA - Registered',
                            style:
                                TextStyle(fontSize: 16, color: Colors.white)),
                        value: ihsaRegistered,
                        onChanged: (value) =>
                            setState(() => ihsaRegistered = value ?? false),
                        controlAffinity: ListTileControlAffinity.leading,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 0, vertical: 0),
                        dense: true,
                        activeColor: efficialsYellow,
                        checkColor: efficialsBlack,
                      ),
                      CheckboxListTile(
                        title: const Text('IHSA - Recognized',
                            style:
                                TextStyle(fontSize: 16, color: Colors.white)),
                        value: ihsaRecognized,
                        onChanged: (value) =>
                            setState(() => ihsaRecognized = value ?? false),
                        controlAffinity: ListTileControlAffinity.leading,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 0, vertical: 0),
                        dense: true,
                        activeColor: efficialsYellow,
                        checkColor: efficialsBlack,
                      ),
                      CheckboxListTile(
                        title: const Text('IHSA - Certified',
                            style:
                                TextStyle(fontSize: 16, color: Colors.white)),
                        value: ihsaCertified,
                        onChanged: (value) =>
                            setState(() => ihsaCertified = value ?? false),
                        controlAffinity: ListTileControlAffinity.leading,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 0, vertical: 0),
                        dense: true,
                        activeColor: efficialsYellow,
                        checkColor: efficialsBlack,
                      ),
                      const SizedBox(height: 20),
                      const Text('Experience',
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: efficialsYellow)),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _yearsController,
                        decoration:
                            textFieldDecoration('Minimum years of experience'),
                        textAlign: TextAlign.left,
                        style:
                            const TextStyle(fontSize: 16, color: Colors.white),
                        keyboardType: TextInputType.number,
                        textInputAction: TextInputAction.next,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly
                        ],
                        maxLength: 2,
                        buildCounter: (context,
                                {required currentLength,
                                required maxLength,
                                required isFocused}) =>
                            null,
                      ),
                      const SizedBox(height: 20),
                      const Text('Competition Levels',
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: efficialsYellow)),
                      const SizedBox(height: 12),
                      Column(
                        children: competitionLevels.keys.map((level) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            child: CheckboxListTile(
                              title: Text(level,
                                  style: const TextStyle(
                                      fontSize: 16, color: Colors.white)),
                              value: competitionLevels[level],
                              onChanged: (value) => setState(() =>
                                  competitionLevels[level] = value ?? false),
                              controlAffinity: ListTileControlAffinity.leading,
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 0, vertical: 0),
                              dense: true,
                              activeColor: efficialsYellow,
                              checkColor: efficialsBlack,
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 20),
                      const Text('Location',
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: efficialsYellow)),
                      const SizedBox(height: 12),
                      if (isAwayGame) ...[
                        const Text(
                          'Radius filtering unavailable for Away Games.',
                          style: TextStyle(
                              fontSize: 16, color: secondaryTextColor),
                        ),
                      ] else ...[
                        Text(
                          locationData != null 
                            ? 'Game Location: ${locationData!['name']}'
                            : defaultLocationName != null
                              ? 'Game Location: $defaultLocationName'
                              : 'Distance measured from your school\'s address',
                          style: TextStyle(
                              fontSize: locationData == null && defaultLocationName == null ? 14 : 16, 
                              color: Colors.white),
                        ),
                        if (locationData == null && defaultLocationAddress != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Using school address: ${defaultLocationAddress}',
                            style: const TextStyle(
                                fontSize: 12, color: secondaryTextColor, fontStyle: FontStyle.italic),
                          ),
                        ],
                        const SizedBox(height: 12),
                        TextField(
                          controller: _radiusController,
                          decoration:
                              textFieldDecoration('Search Radius (miles)')
                                  .copyWith(
                            hintText: 'Enter search radius (miles)',
                            hintStyle: const TextStyle(color: efficialsGray),
                          ),
                          textAlign: TextAlign.left,
                          style: const TextStyle(
                              fontSize: 16, color: Colors.white),
                          keyboardType: TextInputType.number,
                          textInputAction: TextInputAction.done,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly
                          ],
                          maxLength: 3,
                          buildCounter: (context,
                                  {required currentLength,
                                  required maxLength,
                                  required isFocused}) =>
                              null,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 30),
                ElevatedButton(
                  onPressed: () {
                    if (!competitionLevels.values.any((selected) => selected)) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text(
                                'Please select at least one competition level!')),
                      );
                      return;
                    }
                    if (!isAwayGame && _radiusController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Please specify a search radius!')),
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
                        'minYears': _yearsController.text.isNotEmpty
                            ? int.parse(_yearsController.text)
                            : 0,
                        'levels': selectedLevels,
                        'locationData': locationData,
                        'radius': isAwayGame
                            ? null
                            : int.parse(_radiusController.text),
                      },
                    );
                  },
                  style: elevatedButtonStyle(
                    padding: const EdgeInsets.symmetric(
                        vertical: 15, horizontal: 50),
                  ),
                  child:
                      const Text('Apply Filters', style: signInButtonTextStyle),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
