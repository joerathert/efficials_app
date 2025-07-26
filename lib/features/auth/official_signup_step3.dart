import 'package:flutter/material.dart';
import '../../shared/theme.dart';

class OfficialSignUpStep3 extends StatefulWidget {
  const OfficialSignUpStep3({super.key});

  @override
  _OfficialSignUpStep3State createState() => _OfficialSignUpStep3State();
}

class _OfficialSignUpStep3State extends State<OfficialSignUpStep3> {
  
  late Map<String, dynamic> previousData;
  
  // Available sports and their certification levels
  final List<String> availableSports = [
    'Football',
    'Basketball',
    'Baseball',
    'Softball',
    'Soccer',
    'Volleyball',
    'Tennis',
    'Track & Field',
    'Swimming',
    'Wrestling',
    'Cross Country',
    'Golf',
    'Hockey',
  ];

  final List<String> certificationLevels = [
    'IHSA Registered',
    'IHSA Recognized', 
    'IHSA Certified',
    'No Certification',
  ];

  final List<String> competitionLevels = [
    'Grade School (6U-11U)',
    'Middle School (11U-14U)',
    'Underclass (15U-16U)',
    'Junior Varsity (16U-17U)',
    'Varsity (17U-18U)',
    'College',
    'Adult',
  ];

  // Selected sports with their details
  Map<String, Map<String, dynamic>> selectedSports = {};

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    previousData = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
  }


  void _addSport(String sport) {
    if (!selectedSports.containsKey(sport)) {
      setState(() {
        selectedSports[sport] = {
          'certification': certificationLevels.first,
          'experience': 0,
          'levels': <String>[],
        };
      });
    }
  }

  void _removeSport(String sport) {
    setState(() {
      selectedSports.remove(sport);
    });
  }


  void _handleContinue() {
    // Validate that at least one sport is selected
    if (selectedSports.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one sport you can officiate')),
      );
      return;
    }


    // Validate that each sport has at least one competition level
    for (var entry in selectedSports.entries) {
      if (entry.value['levels'].isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please select competition levels for ${entry.key}')),
        );
        return;
      }
    }

    final updatedData = {
      ...previousData,
      'selectedSports': selectedSports,
    };

    Navigator.pushNamed(context, '/official_signup_step4', arguments: updatedData);
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              const Text(
                'Sports & Certifications',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: efficialsYellow,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Step 3 of 4: Your Officiating Experience',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 40),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Sports You Officiate',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: efficialsYellow,
                            ),
                          ),
                          ElevatedButton(
                            onPressed: _showAddSportDialog,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: efficialsYellow,
                              foregroundColor: efficialsBlack,
                            ),
                            child: const Text('Add Sport'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (selectedSports.isEmpty)
                        Column(
                          children: [
                            const Center(
                              child: Padding(
                                padding: EdgeInsets.all(32.0),
                                child: Text(
                                  'No sports selected yet.\nTap "Add Sport" to get started.',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            SizedBox(
                              width: 200,
                              child: ElevatedButton(
                                onPressed: _handleContinue,
                                style: elevatedButtonStyle(),
                                child: const Text('Continue', style: signInButtonTextStyle),
                              ),
                            ),
                          ],
                        )
                      else
                        Column(
                          children: [
                            ...selectedSports.entries.map((entry) => _buildSportCard(entry.key, entry.value)),
                            const SizedBox(height: 40),
                            SizedBox(
                              width: 200,
                              child: ElevatedButton(
                                onPressed: _handleContinue,
                                style: elevatedButtonStyle(),
                                child: const Text('Continue', style: signInButtonTextStyle),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSportCard(String sport, Map<String, dynamic> sportData) {
    return Card(
      color: darkSurface,
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      sport,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: efficialsYellow,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  onPressed: () => _removeSport(sport),
                  icon: const Icon(Icons.delete, color: Colors.red),
                ),
              ],
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: sportData['certification'],
              decoration: const InputDecoration(
                labelText: 'Certification Level',
                labelStyle: TextStyle(color: Colors.grey),
                border: OutlineInputBorder(),
              ),
              dropdownColor: darkSurface,
              style: const TextStyle(color: Colors.white),
              items: certificationLevels.map((level) {
                return DropdownMenuItem(
                  value: level,
                  child: Text(level),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  sportData['certification'] = value;
                });
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              initialValue: sportData['experience'].toString(),
              decoration: const InputDecoration(
                labelText: 'Years of Experience in this Sport',
                labelStyle: TextStyle(color: Colors.grey),
                border: OutlineInputBorder(),
              ),
              style: const TextStyle(color: Colors.white),
              keyboardType: TextInputType.number,
              onChanged: (value) {
                sportData['experience'] = int.tryParse(value) ?? 0;
              },
            ),
            const SizedBox(height: 16),
            const Text(
              'Competition Levels:',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: competitionLevels.map((level) {
                final isSelected = (sportData['levels'] as List<String>).contains(level);
                return Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 8),
                  child: FilterChip(
                    label: SizedBox(
                      width: double.infinity,
                      child: Text(
                        level,
                        textAlign: TextAlign.center,
                      ),
                    ),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          (sportData['levels'] as List<String>).add(level);
                        } else {
                          (sportData['levels'] as List<String>).remove(level);
                        }
                      });
                    },
                    selectedColor: efficialsYellow,
                    backgroundColor: Colors.grey[800],
                    checkmarkColor: efficialsBlack,
                    labelStyle: TextStyle(
                      color: isSelected ? efficialsBlack : Colors.white,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddSportDialog() {
    final availableToAdd = availableSports.where((sport) => !selectedSports.containsKey(sport)).toList();
    
    if (availableToAdd.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You have already added all available sports')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: darkSurface,
        title: const Text(
          'Select a Sport',
          style: TextStyle(color: efficialsYellow),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: availableToAdd.length,
            itemBuilder: (context, index) {
              final sport = availableToAdd[index];
              return ListTile(
                title: Text(sport, style: const TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  _addSport(sport);
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: efficialsYellow)),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}