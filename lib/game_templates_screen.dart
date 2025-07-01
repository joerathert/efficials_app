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
                'Game Templates',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: efficialsYellow,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              Expanded(
                child: isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: efficialsYellow,
                        ),
                      )
                    : sports.isEmpty
                        ? Center(
                            child: Container(
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
                              child: const Text(
                                'No templates available. Create a game to add a template.',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          )
                        : GridView.builder(
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
                                  color: darkSurface,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        getSportIcon(sport),
                                        size: 48,
                                        color: efficialsYellow,
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        sport,
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
