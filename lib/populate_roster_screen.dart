import 'package:flutter/material.dart';
import 'theme.dart';

class PopulateRosterScreen extends StatefulWidget {
  const PopulateRosterScreen({super.key});

  @override
  State<PopulateRosterScreen> createState() => _PopulateRosterScreenState();
}

class _PopulateRosterScreenState extends State<PopulateRosterScreen> {
  String searchQuery = '';
  List<Map<String, dynamic>> officials = [];
  List<Map<String, dynamic>> filteredOfficials = [];
  List<Map<String, dynamic>> filteredOfficialsWithoutSearch = [];
  String filterSummary = '';
  bool filtersApplied = false;
  bool isLoading = false;
  Map<int, bool> selectedOfficials = {};
  Map<String, dynamic>? filterSettings;
  List<Map<String, dynamic>> initialOfficials = [];
  bool isInitialized = false;

  @override
  void initState() {
    super.initState();
    selectedOfficials = {};
    initialOfficials = [];
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!isInitialized) {
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (args != null) {
        initialOfficials = args['selectedOfficials'] as List<Map<String, dynamic>>? ?? [];
        selectedOfficials = {};
        for (var official in initialOfficials) {
          selectedOfficials[official['id'] as int] = true;
        }
      }
      isInitialized = true;
      _loadOfficials();
    }
  }

  Future<void> _loadOfficials() async {
    setState(() {
      isLoading = true;
    });
    try {
      // final dbOfficials = await DatabaseHelper.getOfficials();  // Commented out
      // setState(() {
      //   officials = dbOfficials;
      //   filteredOfficials = [];
      //   filteredOfficialsWithoutSearch = [];
      //   filterSummary = 'No filters applied';
      //   if (filterSettings != null) {
      //     _applyFiltersWithSettings(filterSettings!);
      //   }
      //   isLoading = false;
      // });
    } catch (e) {
      print('Error loading officials: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading officials: $e')),
      );
      setState(() {
        isLoading = false;
      });
    }
  }

  void _applyFiltersWithSettings(Map<String, dynamic> settings) {
    setState(() {
      filterSettings = settings;
      filtersApplied = true;
      final sport = settings['sport'] as String? ?? 'Football';
      final ihsaRegistered = settings['ihsaRegistered'] as bool? ?? false;
      final ihsaRecognized = settings['ihsaRecognized'] as bool? ?? false;
      final ihsaCertified = settings['ihsaCertified'] as bool? ?? false;
      final minYears = settings['minYears'] as int? ?? 0;
      final levels = settings['levels'] as List<String>? ?? [];
      final schedulerZip = settings['zipCode'] as String? ?? '00000';
      final radius = settings['radius'] as int? ?? 50;

      filteredOfficials = officials.where((official) {
        try {
          List<String> sports = (official['sports'] as String)
              .split(',')
              .map((s) => s.trim())
              .toList();
          final matchesSport = sports.map((s) => s.toLowerCase()).contains(sport.toLowerCase());

          List<String> officialLevels = (official['levels'] as String)
              .split(',')
              .map((l) => l.trim())
              .toList();
          final matchesLevel = levels.isEmpty || officialLevels.any((level) => levels.contains(level));

          final credential = official['ihsa_credential'] as String? ?? '';
          final matchesIhsaRegistered = !ihsaRegistered || credential.contains('Registered');
          final matchesIhsaRecognized = !ihsaRecognized || credential.contains('Recognized');
          final matchesIhsaCertified = !ihsaCertified || credential.contains('Certified');

          final matchesExperience = (official['yearsExperience'] as int? ?? 0) >= minYears;

          final officialZip = official['zipCode']?.toString() ?? '00000';
          final distance = officialZip == schedulerZip ? 0 : (official['distance'] as num? ?? 15);
          final withinDistance = distance <= radius;

          return matchesSport && matchesLevel && matchesIhsaRegistered && matchesIhsaRecognized &&
              matchesIhsaCertified && matchesExperience && withinDistance;
        } catch (e) {
          print('Error filtering official ${official['name']}: $e');
          return false;
        }
      }).toList();

      filteredOfficialsWithoutSearch = List.from(filteredOfficials);
      if (searchQuery.isNotEmpty) {
        filteredOfficials = filteredOfficials
            .where((official) => official['name'].toString().toLowerCase().contains(searchQuery.toLowerCase()))
            .toList();
      }
      isLoading = false;
    });
  }

  void filterOfficials(String query) {
    setState(() {
      searchQuery = query;
      if (filtersApplied) {
        filteredOfficials = List.from(filteredOfficialsWithoutSearch);
        if (query.isNotEmpty) {
          filteredOfficials = filteredOfficials
              .where((official) => official['name'].toString().toLowerCase().contains(searchQuery.toLowerCase()))
              .toList();
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    final sport = args['sport']!;
    final listName = args['listName']!;
    final listId = args['listId'] as int?;
    final int selectedCount = selectedOfficials.values.where((selected) => selected).length;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: efficialsBlue,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, size: 36, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Find Officials',
          style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          if (isLoading) ...[
            const Expanded(child: Center(child: CircularProgressIndicator())),
          ] else if (!filtersApplied) ...[
            const Expanded(
              child: Center(
                child: Text(
                  'The roster will populate after\nfilters have been applied.',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ] else ...[
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: TextField(
                  decoration: textFieldDecoration('Search Officials'),
                  style: const TextStyle(fontSize: 18),
                  onChanged: (value) => filterOfficials(value),
                ),
              ),
            ),
            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: filteredOfficials.isEmpty
                        ? const Center(
                            child: Text(
                              'No officials found. Try adjusting your filters.',
                              style: TextStyle(fontSize: 18, color: Colors.grey),
                              textAlign: TextAlign.center,
                            ),
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Checkbox(
                                    value: filteredOfficials.isNotEmpty &&
                                        filteredOfficials.every((official) => selectedOfficials[official['id']] ?? false),
                                    onChanged: (bool? value) {
                                      setState(() {
                                        if (value == true) {
                                          for (final official in filteredOfficials) {
                                            selectedOfficials[official['id']] = true;
                                          }
                                        } else {
                                          for (final official in filteredOfficials) {
                                            selectedOfficials.remove(official['id']);
                                          }
                                        }
                                      });
                                    },
                                  ),
                                  const Text('Select all', style: TextStyle(fontSize: 18)),
                                ],
                              ),
                              Expanded(
                                child: ListView.builder(
                                  itemCount: filteredOfficials.length,
                                  itemBuilder: (context, index) {
                                    final official = filteredOfficials[index];
                                    final officialId = official['id'] as int;
                                    return ListTile(
                                      key: ValueKey(officialId),
                                      leading: IconButton(
                                        icon: Icon(
                                          selectedOfficials[officialId] ?? false ? Icons.check_circle : Icons.add_circle,
                                          color: selectedOfficials[officialId] ?? false ? Colors.green : efficialsBlue,
                                          size: 36,
                                        ),
                                        onPressed: () {
                                          setState(() {
                                            selectedOfficials[officialId] = !(selectedOfficials[officialId] ?? false);
                                            if (selectedOfficials[officialId] == false) {
                                              selectedOfficials.remove(officialId);
                                            }
                                          });
                                        },
                                      ),
                                      title: Text('${official['name']} (${official['cityState'] ?? 'Unknown'})'),
                                      subtitle: Text(
                                        'Distance: ${official['distance'] != null ? (official['distance'] as num).toStringAsFixed(1) : '0.0'} mi, Experience: ${official['yearsExperience'] ?? 0} yrs',
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
      floatingActionButton: Padding(
        padding: filtersApplied ? const EdgeInsets.only(bottom: 0) : const EdgeInsets.only(bottom: 106),
        child: FloatingActionButton(
          onPressed: () {
            Navigator.pushNamed(context, '/filter_settings', arguments: sport).then((result) {
              if (result != null) {
                _loadOfficials().then((_) => _applyFiltersWithSettings(result as Map<String, dynamic>));
              }
            });
          },
          elevation: 0,
          backgroundColor: efficialsBlue,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            side: const BorderSide(color: Colors.black, width: 2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.filter_list, size: 30, color: Colors.white),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: filtersApplied
          ? Padding(
              padding: const EdgeInsets.only(bottom: 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '($selectedCount) Selected',
                    style: const TextStyle(fontSize: 16, color: Colors.black, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: selectedCount > 0
                        ? () {
                            final selected = officials.where((o) => selectedOfficials[o['id']] ?? false).toList();
                            Navigator.pushNamed(
                              context,
                              '/review_list',
                              arguments: {'sport': sport, 'listName': listName, 'listId': listId, 'selectedOfficials': selected},
                            );
                          }
                        : null,
                    style: elevatedButtonStyle(),
                    child: const Text('Continue', style: signInButtonTextStyle),
                  ),
                ],
              ),
            )
          : null,
    );
  }
}