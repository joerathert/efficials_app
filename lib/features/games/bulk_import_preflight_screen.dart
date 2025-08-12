import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../shared/theme.dart';
import '../../shared/services/location_service.dart';
import '../../shared/services/repositories/crew_repository.dart';

class BulkImportPreflightScreen extends StatefulWidget {
  const BulkImportPreflightScreen({super.key});

  @override
  State<BulkImportPreflightScreen> createState() => _BulkImportPreflightScreenState();
}

class _BulkImportPreflightScreenState extends State<BulkImportPreflightScreen> {
  bool isLoading = true;
  
  // Data counts
  int locationCount = 0;
  int officialsListCount = 0;
  int crewListCount = 0;
  
  // Status checks
  bool locationsReady = false;
  bool officialsListsReady = false;
  bool crewListsReady = false;
  
  final LocationService _locationService = LocationService();
  final CrewRepository _crewRepository = CrewRepository();

  @override
  void initState() {
    super.initState();
    _checkDataAvailability();
  }

  Future<void> _checkDataAvailability() async {
    try {
      await Future.wait([
        _checkLocations(),
        _checkOfficialsLists(),
        _checkCrewLists(),
      ]);
      
      setState(() {
        isLoading = false;
      });
    } catch (e) {
      debugPrint('Error checking data availability: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _checkLocations() async {
    try {
      final locations = await _locationService.getLocations();
      setState(() {
        locationCount = locations.length;
        locationsReady = locationCount > 0;
      });
    } catch (e) {
      debugPrint('Error checking locations: $e');
      setState(() {
        locationCount = 0;
        locationsReady = false;
      });
    }
  }

  Future<void> _checkOfficialsLists() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? listsJson = prefs.getString('saved_lists');
      
      if (listsJson != null && listsJson.isNotEmpty) {
        final List<dynamic> lists = jsonDecode(listsJson);
        setState(() {
          officialsListCount = lists.length;
          officialsListsReady = officialsListCount >= 1; // Need at least 1 list
        });
      } else {
        setState(() {
          officialsListCount = 0;
          officialsListsReady = false;
        });
      }
    } catch (e) {
      debugPrint('Error checking officials lists: $e');
      setState(() {
        officialsListCount = 0;
        officialsListsReady = false;
      });
    }
  }

  Future<void> _checkCrewLists() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? crewListsJson = prefs.getString('saved_crew_lists');
      
      if (crewListsJson != null && crewListsJson.isNotEmpty) {
        final List<dynamic> crewLists = jsonDecode(crewListsJson);
        setState(() {
          crewListCount = crewLists.length;
          crewListsReady = crewListCount >= 1; // Need at least 1 crew list
        });
      } else {
        setState(() {
          crewListCount = 0;
          crewListsReady = false;
        });
      }
    } catch (e) {
      debugPrint('Error checking crew lists: $e');
      setState(() {
        crewListCount = 0;
        crewListsReady = false;
      });
    }
  }

  bool get canProceed => locationsReady && (officialsListsReady || crewListsReady);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: darkBackground,
      appBar: AppBar(
        backgroundColor: efficialsBlack,
        title: const Icon(
          Icons.upload_file,
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
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(color: efficialsYellow),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  const Text(
                    'Bulk Import Setup',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: efficialsYellow,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Let\'s prepare your data first to ensure smooth Excel generation and import.',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 30),

                  // Data Status Cards
                  _buildStatusCard(
                    icon: Icons.location_on,
                    title: 'Locations',
                    count: locationCount,
                    isReady: locationsReady,
                    isSatisfied: locationsReady,
                    description: locationsReady
                        ? 'Great! You have $locationCount location${locationCount == 1 ? '' : 's'} ready.'
                        : 'You need to create at least one location before generating Excel files.',
                    actionText: 'Manage Locations',
                    onActionTap: () async {
                      await Navigator.pushNamed(context, '/locations');
                      _checkLocations(); // Refresh count
                    },
                  ),
                  const SizedBox(height: 16),

                  _buildStatusCard(
                    icon: Icons.people,
                    title: 'Officials Lists',
                    count: officialsListCount,
                    isReady: officialsListsReady,
                    isSatisfied: officialsListsReady || crewListsReady,
                    description: officialsListsReady
                        ? 'Perfect! You have $officialsListCount list${officialsListCount == 1 ? '' : 's'} of officials ready.'
                        : crewListsReady 
                            ? 'Officials Lists not needed - you have crew lists ready.'
                            : 'You need either Officials Lists OR Crew Lists to proceed.',
                    actionText: 'Manage Officials',
                    onActionTap: () async {
                      await Navigator.pushNamed(context, '/lists_of_officials');
                      _checkOfficialsLists(); // Refresh count
                    },
                  ),
                  const SizedBox(height: 16),

                  _buildStatusCard(
                    icon: Icons.groups,
                    title: 'Crew Lists',
                    count: crewListCount,
                    isReady: crewListsReady,
                    isSatisfied: officialsListsReady || crewListsReady,
                    description: crewListsReady
                        ? 'Excellent! You have $crewListCount crew${crewListCount == 1 ? '' : 's'} available for hire.'
                        : officialsListsReady
                            ? 'Crew Lists not needed - you have officials lists ready.'
                            : 'You need either Officials Lists OR Crew Lists to proceed.',
                    actionText: crewListCount == 0 ? 'Create Crew Lists' : 'Manage Crews',
                    onActionTap: () async {
                      await Navigator.pushNamed(context, '/lists_of_crews');
                      _checkCrewLists(); // Refresh count
                    },
                    isOptional: false,
                  ),
                  const SizedBox(height: 40),

                  // Info Box
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: efficialsYellow.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: efficialsYellow.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.info_outline,
                          color: efficialsYellow,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Having this data ready will create dropdown menus in your Excel file, preventing typos and ensuring valid imports.',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Divider
                  const SizedBox(height: 30),
                  Row(
                    children: [
                      const Expanded(child: Divider(color: Colors.grey)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'OR',
                          style: TextStyle(
                            color: Colors.grey.withOpacity(0.8),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const Expanded(child: Divider(color: Colors.grey)),
                    ],
                  ),
                  const SizedBox(height: 30),

                  // Upload Existing File Option
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: darkSurface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue.withOpacity(0.5)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.file_upload,
                              color: Colors.blue,
                              size: 28,
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Text(
                                'Already Have an Excel File?',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Skip the wizard if you already have a completed Excel file from a previous session.',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withOpacity(0.8),
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.pushNamed(context, '/bulk_import_upload');
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text(
                              'Upload Existing Excel File',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 100), // Bottom padding for button
                ],
              ),
            ),
      bottomNavigationBar: Container(
        color: efficialsBlack,
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 16,
          bottom: MediaQuery.of(context).padding.bottom + 16,
        ),
        child: ElevatedButton(
          onPressed: canProceed
              ? () {
                  Navigator.pushNamed(context, '/bulk_import_wizard');
                }
              : null,
          style: elevatedButtonStyle(),
          child: Text(
            canProceed ? 'Create New Excel File' : 'Complete Setup First',
            style: signInButtonTextStyle.copyWith(
              color: canProceed ? efficialsBlack : Colors.grey,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusCard({
    required IconData icon,
    required String title,
    required int count,
    required bool isReady,
    required bool isSatisfied,
    required String description,
    required String actionText,
    required VoidCallback onActionTap,
    bool isOptional = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: darkSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSatisfied ? Colors.green.withOpacity(0.5) : (isOptional ? efficialsYellow.withOpacity(0.5) : Colors.red.withOpacity(0.5)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: isSatisfied ? Colors.green : (isOptional ? efficialsYellow : Colors.red),
                size: 28,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              Icon(
                isSatisfied ? Icons.check_circle : (isOptional ? Icons.info : Icons.warning),
                color: isSatisfied ? Colors.green : (isOptional ? efficialsYellow : Colors.red),
                size: 24,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.8),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: onActionTap,
              style: TextButton.styleFrom(
                backgroundColor: (isSatisfied && !isOptional) ? Colors.grey.withOpacity(0.2) : efficialsYellow.withOpacity(0.1),
                padding: const EdgeInsets.symmetric(vertical: 8),
              ),
              child: Text(
                actionText,
                style: TextStyle(
                  color: (isSatisfied && !isOptional) ? Colors.grey : efficialsYellow,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}