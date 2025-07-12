import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // For formatting DateTime
import 'package:shared_preferences/shared_preferences.dart';
import 'game_template.dart';
import '../../shared/theme.dart';

class SportTemplatesScreen extends StatefulWidget {
  const SportTemplatesScreen({super.key});

  @override
  State<SportTemplatesScreen> createState() => _SportTemplatesScreenState();
}

class _SportTemplatesScreenState extends State<SportTemplatesScreen> {
  List<GameTemplate> templates = [];
  String? selectedTemplate;
  String sport = '';
  bool isLoading = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    sport = args['sport'] as String? ?? 'Unknown';
    _fetchTemplates();
  }

  Future<void> _fetchTemplates() async {
    final prefs = await SharedPreferences.getInstance();
    final String? templatesJson = prefs.getString('game_templates');
    setState(() {
      templates.clear();
      if (templatesJson != null && templatesJson.isNotEmpty) {
        final List<dynamic> decoded = jsonDecode(templatesJson);
        templates = decoded.map((json) => GameTemplate.fromJson(json)).toList();
      }
      // Filter templates by sport
      templates =
          templates.where((t) => t.includeSport && t.sport == sport).toList();
      isLoading = false;
    });
  }

  void _onTemplateSelected(String? value) {
    if (value == null) return;
    setState(() {
      selectedTemplate = value;
    });

    if (value == '+ Create new template') {
      Navigator.pushNamed(context, '/new_game_template').then((result) {
        if (result == true) {
          _fetchTemplates(); // Refresh templates after creating a new one
        }
      });
    }
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
                'Select a Game Template',
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
                      'Which Template would you like to use?',
                      style: TextStyle(
                        fontSize: 16,
                        color: primaryTextColor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    DropdownButtonFormField<String>(
                      value: selectedTemplate,
                      decoration: textFieldDecoration('Choose template'),
                      dropdownColor: darkSurface,
                      items: [
                        ...templates.map((template) {
                          return DropdownMenuItem(
                            value: template.name,
                            child: Text(
                              template.name ?? 'Unnamed Template',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                              ),
                            ),
                          );
                        }).toList(),
                        const DropdownMenuItem(
                          value: '+ Create new template',
                          child: Text(
                            '+ Create new template',
                            style: TextStyle(
                              color: efficialsYellow,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                      onChanged: _onTemplateSelected,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                      icon: const Icon(
                        Icons.arrow_drop_down,
                        color: efficialsYellow,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              if (selectedTemplate != null &&
                  selectedTemplate != '+ Create new template') ...[
                SizedBox(
                  width: 200,
                  child: ElevatedButton(
                    onPressed: () {
                      final selected = templates
                          .firstWhere((t) => t.name == selectedTemplate);
                      Navigator.pushNamed(
                        context,
                        '/create_game_template',
                        arguments: {
                          'template': selected,
                          'sport': sport,
                          'isEdit': true,
                        },
                      ).then((result) {
                        if (result != null) {
                          _fetchTemplates();
                        }
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: efficialsYellow,
                      padding: const EdgeInsets.symmetric(
                          vertical: 15, horizontal: 32),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Edit Template',
                      style: TextStyle(
                        color: efficialsBlack,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: 200,
                  child: ElevatedButton(
                    onPressed: () async {
                      final selected = templates
                          .firstWhere((t) => t.name == selectedTemplate);
                      final shouldDelete = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          backgroundColor: darkSurface,
                          title: const Text(
                            'Confirm Delete',
                            style: TextStyle(
                              color: efficialsYellow,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          content: Text(
                            'Are you sure you want to delete "${selected.name}"?',
                            style: const TextStyle(
                              color: primaryTextColor,
                              fontSize: 16,
                            ),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text(
                                'Cancel',
                                style: TextStyle(
                                  color: efficialsYellow,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text(
                                'Delete',
                                style: TextStyle(
                                  color: efficialsYellow,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      );

                      if (shouldDelete == true) {
                        final prefs = await SharedPreferences.getInstance();
                        final templatesJson = prefs.getString('game_templates');
                        if (templatesJson != null) {
                          final List<dynamic> decoded =
                              jsonDecode(templatesJson);
                          final updatedTemplates = decoded
                              .where((t) => t['id'] != selected.id)
                              .toList();
                          await prefs.setString(
                              'game_templates', jsonEncode(updatedTemplates));
                          setState(() {
                            templates.removeWhere((t) => t.id == selected.id);
                            selectedTemplate = null;
                          });
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content:
                                      Text('Template deleted successfully')),
                            );
                          }
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(
                          vertical: 15, horizontal: 32),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Delete Template',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              SizedBox(
                width: 200,
                child: ElevatedButton(
                  onPressed: (selectedTemplate == null ||
                          selectedTemplate == '+ Create new template')
                      ? null
                      : () {
                          final selected = templates
                              .firstWhere((t) => t.name == selectedTemplate);
                          final args = ModalRoute.of(context)!
                              .settings
                              .arguments as Map<String, dynamic>?;
                          final scheduleName = args?['scheduleName'] as String?;

                          if (scheduleName != null) {
                            Navigator.pushNamed(
                              context,
                              '/date_time',
                              arguments: {
                                'sport': sport,
                                'template': selected,
                                'scheduleName': scheduleName,
                              },
                            );
                          } else {
                            Navigator.pushNamed(
                              context,
                              '/select_schedule',
                              arguments: {
                                'sport': sport,
                                'template': selected,
                              },
                            );
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: efficialsYellow,
                    disabledBackgroundColor: Colors.grey[600],
                    disabledForegroundColor: Colors.grey[300],
                    padding: const EdgeInsets.symmetric(
                        vertical: 15, horizontal: 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Continue',
                    style: TextStyle(
                      color: efficialsBlack,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatOfficialsDisplay(GameTemplate template) {
    if (template.method == 'use_list' && template.officialsListName != null) {
      return 'List Used (${template.officialsListName})';
    } else if (template.method == 'standard' &&
        template.selectedOfficials != null &&
        template.selectedOfficials!.isNotEmpty) {
      final names = template.selectedOfficials!
          .map((official) => official['name'] as String? ?? 'Unknown')
          .join(', ');
      return 'Standard ($names)';
    } else if (template.method == 'advanced' &&
        template.selectedOfficials != null &&
        template.selectedOfficials!.isNotEmpty) {
      final names = template.selectedOfficials!
          .map((official) => official['name'] as String? ?? 'Unknown')
          .join(', ');
      return 'Advanced ($names)';
    } else {
      return 'None';
    }
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label: ',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }
}
