import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../shared/theme.dart';
import '../../shared/services/schedule_service.dart';
import '../../shared/services/repositories/user_repository.dart';
import '../../shared/models/database_models.dart';

class ADNameScheduleScreen extends StatefulWidget {
  const ADNameScheduleScreen({super.key});

  @override
  State<ADNameScheduleScreen> createState() => _ADNameScheduleScreenState();
}

class _ADNameScheduleScreenState extends State<ADNameScheduleScreen> {
  final _nameController = TextEditingController();
  final ScheduleService _scheduleService = ScheduleService();
  final UserRepository _userRepository = UserRepository();
  
  User? currentUser;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
  }

  Future<void> _loadCurrentUser() async {
    try {
      currentUser = await _userRepository.getCurrentUser();
    } catch (e) {
      debugPrint('Error loading current user: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _handleContinue() async {
    final name = _nameController.text.trim();

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a schedule name!')),
      );
      return;
    }

    final args =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    final sport = args['sport'] as String? ?? 'Unknown';

    try {
      // Use the AD's team name from their profile for homeTeamName
      final homeTeamName = currentUser?.teamName ?? '';
      
      // Try to create schedule using database service first
      final schedule = await _scheduleService.createSchedule(
        name: name,
        sportName: sport,
        homeTeamName: homeTeamName,
      );

      if (schedule != null) {
        // Schedule created successfully
        Navigator.pop(context, schedule);
      } else {
        // Schedule already exists
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('A schedule with this name already exists!')),
        );
      }
    } catch (e) {
      // Fallback to SharedPreferences if database fails
      await _handleContinueWithPrefs(name, sport);
    }
  }

  Future<void> _handleContinueWithPrefs(String name, String sport) async {
    // Save the schedule to SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    final String? unpublishedGamesJson = prefs.getString('unpublished_games');
    List<Map<String, dynamic>> unpublishedGames = [];
    if (unpublishedGamesJson != null && unpublishedGamesJson.isNotEmpty) {
      unpublishedGames =
          List<Map<String, dynamic>>.from(jsonDecode(unpublishedGamesJson));
    }

    final scheduleEntry = {
      'id': DateTime.now().millisecondsSinceEpoch,
      'scheduleName': name,
      'sport': sport,
      'createdAt': DateTime.now().toIso8601String(),
    };
    unpublishedGames.add(scheduleEntry);
    await prefs.setString('unpublished_games', jsonEncode(unpublishedGames));

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Schedule created!')),
      );

      // Return the new schedule name to SelectScheduleScreen
      Navigator.pop(context, name);
    }
  }

  @override
  Widget build(BuildContext context) {
    final args =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    final sport = args['sport'] as String? ?? 'Unknown';

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
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(height: 40),
                      const Text(
                        'Name Your Schedule',
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
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Schedule Name',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: efficialsYellow,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _nameController,
                              decoration: textFieldDecoration('Ex. Varsity Football'),
                              style:
                                  const TextStyle(fontSize: 16, color: Colors.white),
                            ),
                            if (currentUser?.teamName != null) ...[ 
                              const SizedBox(height: 16),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: efficialsBlue.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: efficialsBlue.withOpacity(0.3),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.info_outline,
                                      color: efficialsBlue,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Your team name "${currentUser!.teamName}" will be used for all home games.',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: efficialsBlue,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 30),
                      ElevatedButton(
                        onPressed: _handleContinue,
                        style: elevatedButtonStyle(
                          padding: const EdgeInsets.symmetric(
                              vertical: 15, horizontal: 50),
                        ),
                        child: const Text('Continue', style: signInButtonTextStyle),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}