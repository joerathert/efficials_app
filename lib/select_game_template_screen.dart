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
          templateKey =
              'assigner_team_template_${scheduleName!.toLowerCase().replaceAll(' ', '_')}';
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
          style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: efficialsYellow),
        ),
        const SizedBox(height: 10),
        if (template.includeSport && template.sport != null)
          Text('Sport: ${template.sport}',
              style: const TextStyle(fontSize: 16, color: Colors.white)),
        if (template.includeTime && template.time != null)
          Text('Time: ${template.time!.format(context)}',
              style: const TextStyle(fontSize: 16, color: Colors.white)),
        if (template.includeLocation && template.location != null)
          Text('Location: ${template.location}',
              style: const TextStyle(fontSize: 16, color: Colors.white)),
        if (template.includeLevelOfCompetition &&
            template.levelOfCompetition != null)
          Text('Level of Competition: ${template.levelOfCompetition}',
              style: const TextStyle(fontSize: 16, color: Colors.white)),
        if (template.includeGender && template.gender != null)
          Text('Gender: ${template.gender}',
              style: const TextStyle(fontSize: 16, color: Colors.white)),
        if (template.includeOfficialsRequired &&
            template.officialsRequired != null)
          Text('Officials Required: ${template.officialsRequired}',
              style: const TextStyle(fontSize: 16, color: Colors.white)),
        if (template.includeGameFee && template.gameFee != null)
          Text(
              'Game Fee: \$${double.parse(template.gameFee!).toStringAsFixed(2)}',
              style: const TextStyle(fontSize: 16, color: Colors.white)),
        if (template.includeHireAutomatically &&
            template.hireAutomatically != null)
          Text(
              'Hire Automatically: ${template.hireAutomatically! ? 'Yes' : 'No'}',
              style: const TextStyle(fontSize: 16, color: Colors.white)),
        if (template.includeOfficialsList && template.officialsListName != null)
          Text('Selected Officials: List Used (${template.officialsListName})',
              style: const TextStyle(fontSize: 16, color: Colors.white)),
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
      body: SingleChildScrollView(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 40),
                  const Text(
                    'Select Game Template',
                    style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: efficialsYellow),
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
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Text(
                          'Choose a template to use for games in this schedule, or create a new one.',
                          style: TextStyle(fontSize: 16, color: Colors.white),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        isLoading
                            ? const Center(child: CircularProgressIndicator())
                            : DropdownButtonFormField<String>(
                                decoration: textFieldDecoration('Templates'),
                                value: selectedTemplateId,
                                hint: const Text('Select a template',
                                    style: TextStyle(color: efficialsGray)),
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 16),
                                dropdownColor: darkSurface,
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
                                    child: Text(template.name,
                                        style: const TextStyle(
                                            color: Colors.white)),
                                  );
                                }).toList(),
                              ),
                        if (selectedTemplate != null) ...[
                          const SizedBox(height: 24),
                          _buildTemplateDetails(selectedTemplate),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                  SizedBox(
                    width: 200,
                    child: ElevatedButton(
                      onPressed: selectedTemplateId != null &&
                              selectedTemplateId != '0'
                          ? () => _editTemplate(selectedTemplate!)
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: efficialsBlack,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: Colors.grey[600],
                        disabledForegroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(
                            vertical: 15, horizontal: 32),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Edit', style: signInButtonTextStyle),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: 200,
                    child: ElevatedButton(
                      onPressed: selectedTemplateId != null &&
                              selectedTemplateId != '0'
                          ? _associateTemplate
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: efficialsBlack,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: Colors.grey[600],
                        disabledForegroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(
                            vertical: 15, horizontal: 32),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Continue', style: signInButtonTextStyle),
                    ),
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
