import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../shared/theme.dart';
import '../../shared/services/schedule_service.dart';
import '../../shared/services/repositories/user_repository.dart';
import '../../shared/models/database_models.dart';

class NameScheduleScreen extends StatefulWidget {
  const NameScheduleScreen({super.key});

  @override
  State<NameScheduleScreen> createState() => _NameScheduleScreenState();
}

class _NameScheduleScreenState extends State<NameScheduleScreen> {
  final _nameController = TextEditingController();
  final _homeTeamController = TextEditingController();
  final ScheduleService _scheduleService = ScheduleService();
  final UserRepository _userRepository = UserRepository();
  
  User? currentUser;
  bool isAssigner = false;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
  }

  Future<void> _loadCurrentUser() async {
    try {
      currentUser = await _userRepository.getCurrentUser();
      if (currentUser != null) {
        isAssigner = currentUser!.schedulerType == 'Assigner';
        // Pre-fill home team for ADs from their team name
        if (!isAssigner && currentUser!.teamName != null) {
          _homeTeamController.text = currentUser!.teamName!;
        }
      }
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
    _homeTeamController.dispose();
    super.dispose();
  }

  void _handleContinue() async {
    final name = _nameController.text.trim();
    final homeTeamName = _homeTeamController.text.trim();

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a schedule name!')),
      );
      return;
    }

    // Only require home team name for Assigners
    if (isAssigner && homeTeamName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a home team name!')),
      );
      return;
    }
    
    // For ADs, use their existing team name if home team field is empty
    if (!isAssigner && homeTeamName.isEmpty && currentUser?.teamName != null) {
      _homeTeamController.text = currentUser!.teamName!;
    }

    final args =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    final sport = args['sport'] as String? ?? 'Unknown';

    try {
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
                              decoration: textFieldDecoration(
                                isAssigner 
                                  ? 'Ex. - Edwardsville Varsity'
                                  : 'Ex. Varsity Football'
                              ),
                              style:
                                  const TextStyle(fontSize: 16, color: Colors.white),
                            ),
                            // Only show home team field for Assigners
                            if (isAssigner) ...[
                              const SizedBox(height: 24),
                              const Text(
                                'Home Team',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: efficialsYellow,
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextField(
                                controller: _homeTeamController,
                                decoration:
                                    textFieldDecoration('Ex. - Edwardsville Tigers'),
                                style:
                                    const TextStyle(fontSize: 16, color: Colors.white),
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
