import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'game_template.dart';
import 'theme.dart';
import 'utils.dart';

class GameTemplatesScreen extends StatefulWidget {
  const GameTemplatesScreen({super.key});

  @override
  State<GameTemplatesScreen> createState() => _GameTemplatesScreenState();
}

class _GameTemplatesScreenState extends State<GameTemplatesScreen> {
  List<GameTemplate> templates = [];
  bool isLoading = true;
  List<String> sports = [];
  String? schedulerType;
  String? userSport;

  @override
  void initState() {
    super.initState();
    _fetchTemplates();
  }

  Future<void> _fetchTemplates() async {
    final prefs = await SharedPreferences.getInstance();
    final String? templatesJson = prefs.getString('game_templates');
    
    // Load scheduler information
    schedulerType = prefs.getString('schedulerType');
    if (schedulerType == 'Assigner') {
      userSport = prefs.getString('assigner_sport');
    } else if (schedulerType == 'Coach') {
      userSport = prefs.getString('sport');
    }
    
    setState(() {
      templates.clear();
      if (templatesJson != null && templatesJson.isNotEmpty) {
        final List<dynamic> decoded = jsonDecode(templatesJson);
        templates = decoded.map((json) => GameTemplate.fromJson(json)).toList();
      }
      // Extract unique sports from templates, excluding null values
      Set<String> allSports = templates
          .where((t) =>
              t.includeSport && t.sport != null) // Ensure sport is not null
          .map((t) => t.sport!) // Use ! since we filtered out nulls
          .toSet();
      
      // Filter sports based on scheduler type
      if (schedulerType == 'Assigner' && userSport != null) {
        // Assigners only see their assigned sport
        sports = allSports.where((sport) => sport == userSport).toList();
      } else if (schedulerType == 'Coach' && userSport != null) {
        // Coaches only see their team's sport
        sports = allSports.where((sport) => sport == userSport).toList();
      } else {
        // Athletic Directors see all sports
        sports = allSports.toList();
      }
      
      sports.sort(); // Sort alphabetically for consistency
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: efficialsBlack,
        title: const Text('Game Templates', style: appBarTextStyle),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : sports.isEmpty
              ? const Center(
                  child: Text(
                    'No templates available. Create a game to add a template.',
                    textAlign: TextAlign.center,
                  ),
                )
              : GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1, // Square tiles
                  ),
                  itemCount: sports.length,
                  itemBuilder: (context, index) {
                    final sport = sports[index];
                    return GestureDetector(
                      onTap: () {
                        Navigator.pushNamed(
                          context,
                          '/sport_templates',
                          arguments: {'sport': sport},
                        );
                      },
                      child: Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              getSportIcon(sport),
                              size: 48,
                              color: getSportIconColor(sport),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              sport,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
