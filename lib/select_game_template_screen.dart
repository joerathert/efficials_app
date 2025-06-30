import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'theme.dart';
import 'game_template.dart';

class SelectGameTemplateScreen extends StatefulWidget {
  const SelectGameTemplateScreen({super.key});

  @override
  State<SelectGameTemplateScreen> createState() =>
      _SelectGameTemplateScreenState();
}

class _SelectGameTemplateScreenState extends State<SelectGameTemplateScreen> {
  String? selectedTemplateId;
  List<GameTemplate> templates = [];
  bool isLoading = true;
  String? scheduleName;
  String? sport;
  bool isAssignerFlow = false;

  @override
  void initState() {
    super.initState();
    _fetchTemplates();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
    if (args != null) {
      scheduleName = args['scheduleName'] as String?;
      sport = args['sport'] as String?;
      isAssignerFlow = args['isAssignerFlow'] as bool? ?? false;
      if (sport != null) {
        _fetchTemplates(); // Refresh templates when sport changes
      }
    }
  }

  Future<void> _fetchTemplates() async {
    final prefs = await SharedPreferences.getInstance();
    final String? templatesJson = prefs.getString('game_templates');
    setState(() {
      templates.clear();
      if (templatesJson != null && templatesJson.isNotEmpty) {
        final List<dynamic> templatesList = jsonDecode(templatesJson);
        templates =
            templatesList.map((json) => GameTemplate.fromJson(json)).toList();
        // Filter templates by sport
        if (sport != null) {
          templates = templates
              .where((t) => t.includeSport && t.sport == sport)
              .toList();
        }
      }
      templates.add(GameTemplate(
        id: '0',
        name: '+ Create new template',
        includeSport: false,
      ));
      isLoading = false;
    });
  }

  Future<void> _associateTemplate() async {
    if (selectedTemplateId == null) return;
    final prefs = await SharedPreferences.getInstance();

    if (selectedTemplateId == '0') {
      Navigator.pushReplacementNamed(
        context,
        '/create_game_template',
        arguments: {
          'scheduleName': scheduleName,
          'sport': sport,
        },
      );
    } else {
      final selectedTemplate =
          templates.firstWhere((t) => t.id == selectedTemplateId);
      
      // Handle Coach flow - navigate to date_time with template data
      if (scheduleName == null) {
        // This is likely the Coach flow
        Navigator.pushNamed(
          context,
          '/date_time',
          arguments: {
            'sport': sport,
            'template': selectedTemplate,
          },
        );
      } else {
        // This is the Assigner/Athletic Director flow
        String templateKey;
        if (isAssignerFlow) {
          templateKey = 'assigner_team_template_${scheduleName!.toLowerCase().replaceAll(' ', '_')}';
        } else {
          templateKey = 'schedule_template_${scheduleName!.toLowerCase()}';
        }
        
        await prefs.setString(
          templateKey,
          jsonEncode(selectedTemplate.toJson()),
        );
        Navigator.pop(context);
      }
    }
  }

  Future<void> _editTemplate(GameTemplate template) async {
    print('SelectGameTemplateScreen - Editing template: ${template.toJson()}');
    final updatedTemplate = await Navigator.pushNamed(
      context,
      '/create_game_template',
      arguments: {
        'scheduleName': scheduleName,
        'sport': sport,
        'template': template,
        'isEdit': true,
      },
    );

    if (updatedTemplate != null && updatedTemplate is GameTemplate) {
      setState(() {
        final index = templates.indexWhere((t) => t.id == updatedTemplate.id);
        if (index != -1) {
          templates[index] = updatedTemplate;
        }
      });
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'game_templates',
        jsonEncode(templates
            .where((t) => t.id != '0')
            .map((t) => t.toJson())
            .toList()),
      );
    }
  }

  Widget _buildTemplateDetails(GameTemplate template) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Template Details:',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        if (template.includeSport && template.sport != null)
          Text('Sport: ${template.sport}',
              style: const TextStyle(fontSize: 16)),
        if (template.includeTime && template.time != null)
          Text('Time: ${template.time!.format(context)}',
              style: const TextStyle(fontSize: 16)),
        if (template.includeLocation && template.location != null)
          Text('Location: ${template.location}',
              style: const TextStyle(fontSize: 16)),
        if (template.includeLevelOfCompetition &&
            template.levelOfCompetition != null)
          Text('Level of Competition: ${template.levelOfCompetition}',
              style: const TextStyle(fontSize: 16)),
        if (template.includeGender && template.gender != null)
          Text('Gender: ${template.gender}',
              style: const TextStyle(fontSize: 16)),
        if (template.includeOfficialsRequired &&
            template.officialsRequired != null)
          Text('Officials Required: ${template.officialsRequired}',
              style: const TextStyle(fontSize: 16)),
        if (template.includeGameFee && template.gameFee != null)
          Text(
              'Game Fee: \$${double.parse(template.gameFee!).toStringAsFixed(2)}',
              style: const TextStyle(fontSize: 16)),
        if (template.includeHireAutomatically &&
            template.hireAutomatically != null)
          Text(
              'Hire Automatically: ${template.hireAutomatically! ? 'Yes' : 'No'}',
              style: const TextStyle(fontSize: 16)),
        if (template.includeOfficialsList && template.officialsListName != null)
          Text('Selected Officials: List Used (${template.officialsListName})',
              style: const TextStyle(fontSize: 16)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    GameTemplate? selectedTemplate;
    if (selectedTemplateId != null && selectedTemplateId != '0') {
      selectedTemplate =
          templates.firstWhere((t) => t.id == selectedTemplateId);
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: efficialsBlack,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, size: 36, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Select Game Template', style: appBarTextStyle),
      ),
      body: SingleChildScrollView(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text(
                    'Select a template for this schedule.',
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : DropdownButtonFormField<String>(
                          decoration: textFieldDecoration('Templates'),
                          value: selectedTemplateId,
                          hint: const Text('Select a template'),
                          onChanged: (newValue) {
                            setState(() {
                              selectedTemplateId = newValue;
                              if (newValue == '0') {
                                _associateTemplate();
                              }
                            });
                          },
                          items: templates.map((template) {
                            return DropdownMenuItem(
                              value: template.id,
                              child: Text(template.name),
                            );
                          }).toList(),
                        ),
                  const SizedBox(height: 20),
                  if (selectedTemplate != null) ...[
                    _buildTemplateDetails(selectedTemplate),
                    const SizedBox(height: 20),
                  ],
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton(
                        onPressed: selectedTemplateId != null &&
                                selectedTemplateId != '0'
                            ? () => _editTemplate(selectedTemplate!)
                            : null,
                        style: elevatedButtonStyle(),
                        child: const Text('Edit', style: signInButtonTextStyle),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: selectedTemplateId != null &&
                                selectedTemplateId != '0'
                            ? _associateTemplate
                            : null,
                        style: elevatedButtonStyle(),
                        child: const Text('Continue',
                            style: signInButtonTextStyle),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
