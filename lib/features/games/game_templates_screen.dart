import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'game_template.dart';
import '../../shared/theme.dart';
import '../../shared/utils/utils.dart';
import '../../shared/services/game_service.dart';

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
  final GameService _gameService = GameService();

  @override
  void initState() {
    super.initState();
    _fetchTemplates();
  }

  Future<void> _fetchTemplates() async {
    try {
      // Use GameService to get templates from database
      final templatesData = await _gameService.getTemplates();
      
      // Load scheduler information (still needed for user context)
      final prefs = await SharedPreferences.getInstance();
      schedulerType = prefs.getString('schedulerType');
      if (schedulerType == 'Assigner') {
        userSport = prefs.getString('assigner_sport');
      } else if (schedulerType == 'Coach') {
        userSport = prefs.getString('sport');
      }
      
      setState(() {
        templates.clear();
        // Convert Map data to GameTemplate objects
        templates = templatesData.map((templateData) => GameTemplate.fromJson(templateData)).toList();
        
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
    } catch (e) {
      // Fallback to SharedPreferences if database fails
      await _fetchTemplatesFromPrefs();
    }
  }

  Future<void> _fetchTemplatesFromPrefs() async {
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

  void _showDeleteConfirmationDialog(String templateName, GameTemplate template) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: Text('Are you sure you want to delete "$templateName"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: efficialsYellow)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteTemplate(template);
            },
            child: const Text('Delete', style: TextStyle(color: efficialsYellow)),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteTemplate(GameTemplate template) async {
    try {
      // Use GameService to delete template from database
      final success = await _gameService.deleteTemplate(template.id);
      
      if (success) {
        // Refresh the templates list
        await _fetchTemplates();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Template deleted successfully')),
          );
        }
      } else {
        // Fallback to SharedPreferences
        await _deleteTemplateFromPrefs(template);
      }
    } catch (e) {
      // Fallback to SharedPreferences
      await _deleteTemplateFromPrefs(template);
    }
  }

  Future<void> _deleteTemplateFromPrefs(GameTemplate template) async {
    setState(() {
      templates.removeWhere((t) => t.id == template.id);
    });
    await _saveTemplates();
    await _fetchTemplates();
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Template deleted successfully')),
      );
    }
  }

  Future<void> _saveTemplates() async {
    final prefs = await SharedPreferences.getInstance();
    final templatesJson = jsonEncode(templates.map((t) => t.toJson()).toList());
    await prefs.setString('game_templates', templatesJson);
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
              const Text(
                'Game Templates',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: primaryTextColor,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Manage your saved game templates',
                style: TextStyle(
                  fontSize: 16,
                  color: secondaryTextColor,
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : templates.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.description,
                                  size: 80,
                                  color: secondaryTextColor,
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  'No game templates found',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: primaryTextColor,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'Create your first game to add a template',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: secondaryTextColor,
                                  ),
                                ),
                                const SizedBox(height: 24),
                                Container(
                                  width: 250,
                                  child: ElevatedButton.icon(
                                    onPressed: () {
                                      Navigator.pushNamed(context, '/create_game');
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: efficialsYellow,
                                      foregroundColor: efficialsBlack,
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 15, horizontal: 32),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    icon: const Icon(Icons.add, color: efficialsBlack),
                                    label: const Text(
                                      'Create New Game',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )
                        : LayoutBuilder(
                            builder: (context, constraints) {
                              const buttonHeight = 60.0;
                              const padding = 20.0;
                              const minBottomSpace = 100.0;
                              
                              final maxListHeight = constraints.maxHeight - buttonHeight - padding - minBottomSpace;
                              
                              return Column(
                                children: [
                                  Container(
                                    constraints: BoxConstraints(
                                      maxHeight: maxListHeight > 0 ? maxListHeight : constraints.maxHeight * 0.6,
                                    ),
                                    child: ListView.builder(
                                      shrinkWrap: true,
                                      itemCount: templates.length,
                                      itemBuilder: (context, index) {
                                        final template = templates[index];
                                        final templateName = template.name;
                                        final sport = template.sport ?? 'Unknown';

                                        return Padding(
                                          padding: const EdgeInsets.only(bottom: 12.0),
                                          child: Container(
                                            decoration: BoxDecoration(
                                              color: darkSurface,
                                              borderRadius: BorderRadius.circular(12),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black.withOpacity(0.3),
                                                  spreadRadius: 1,
                                                  blurRadius: 3,
                                                  offset: const Offset(0, 1),
                                                ),
                                              ],
                                            ),
                                            child: Padding(
                                              padding: const EdgeInsets.all(16),
                                              child: Row(
                                                children: [
                                                  Container(
                                                    padding: const EdgeInsets.all(12),
                                                    decoration: BoxDecoration(
                                                      color: getSportIconColor(sport).withOpacity(0.1),
                                                      borderRadius: BorderRadius.circular(8),
                                                    ),
                                                    child: Icon(
                                                      getSportIcon(sport),
                                                      color: getSportIconColor(sport),
                                                      size: 24,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 16),
                                                  Expanded(
                                                    child: Column(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        Text(
                                                          templateName,
                                                          style: const TextStyle(
                                                            fontSize: 18,
                                                            fontWeight: FontWeight.bold,
                                                            color: primaryTextColor,
                                                          ),
                                                        ),
                                                        const SizedBox(height: 4),
                                                        Text(
                                                          sport,
                                                          style: const TextStyle(
                                                            fontSize: 14,
                                                            color: secondaryTextColor,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  Row(
                                                    mainAxisSize: MainAxisSize.min,
                                                    children: [
                                                      IconButton(
                                                        onPressed: () {
                                                          Navigator.pushNamed(
                                                            context,
                                                            '/sport_templates',
                                                            arguments: {
                                                              'sport': sport,
                                                              'selectedTemplate': template.id,
                                                              'editMode': true,
                                                            },
                                                          );
                                                        },
                                                        icon: const Icon(
                                                          Icons.edit,
                                                          color: efficialsYellow,
                                                          size: 20,
                                                        ),
                                                        tooltip: 'Edit Template',
                                                      ),
                                                      IconButton(
                                                        onPressed: () {
                                                          _showDeleteConfirmationDialog(templateName, template);
                                                        },
                                                        icon: Icon(
                                                          Icons.delete_outline,
                                                          color: Colors.red.shade600,
                                                          size: 20,
                                                        ),
                                                        tooltip: 'Delete Template',
                                                      ),
                                                      IconButton(
                                                        onPressed: () {
                                                          Navigator.pushNamed(
                                                            context,
                                                            '/create_game',
                                                            arguments: {
                                                              'useTemplate': true,
                                                              'template': template,
                                                            },
                                                          );
                                                        },
                                                        icon: const Icon(
                                                          Icons.arrow_forward,
                                                          color: Colors.green,
                                                          size: 20,
                                                        ),
                                                        tooltip: 'Use This Template',
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  Center(
                                    child: Container(
                                      width: 250,
                                      child: ElevatedButton.icon(
                                        onPressed: () {
                                          Navigator.pushNamed(context, '/create_game');
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: efficialsYellow,
                                          foregroundColor: efficialsBlack,
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 15, horizontal: 32),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                        ),
                                        icon: const Icon(Icons.add, color: efficialsBlack),
                                        label: const Text(
                                          'Create New Game',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
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
