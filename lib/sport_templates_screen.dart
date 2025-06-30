import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // For formatting DateTime
import 'package:shared_preferences/shared_preferences.dart';
import 'game_template.dart';
import 'theme.dart';

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
    sport = args['sport'] as String;
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
    final templateNames = templates.map((t) => t.name).toList()
      ..add('+ Create new template');
    // Find the selected template to display its details
    GameTemplate? selectedTemplateDetails;
    if (selectedTemplate != null &&
        selectedTemplate != '+ Create new template') {
      selectedTemplateDetails =
          templates.firstWhere((t) => t.name == selectedTemplate);
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: efficialsBlack,
        title: Text('$sport Templates', style: appBarTextStyle),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start, // Align to top
              crossAxisAlignment:
                  CrossAxisAlignment.center, // Center horizontally
              children: [
                const SizedBox(height: 20), // Space below AppBar
                isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : templates.isEmpty
                        ? const Center(
                            child: Text(
                              'No templates for this sport. Create a new template to get started.',
                              textAlign: TextAlign.center,
                            ),
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment
                                .center, // Center horizontally
                            children: [
                              DropdownButtonFormField<String>(
                                decoration: textFieldDecoration('Templates'),
                                value: selectedTemplate,
                                hint: const Text(
                                  'Select a template',
                                  style: TextStyle(color: Colors.grey),
                                ),
                                onChanged: _onTemplateSelected,
                                items: templateNames.map((name) {
                                  return DropdownMenuItem<String>(
                                    value: name,
                                    child: Text(name),
                                  );
                                }).toList(),
                              ),
                              const SizedBox(height: 20),
                              // Display template details if a template is selected
                              if (selectedTemplateDetails != null) ...[
                                const Text(
                                  'Template Details',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: darkSurface,
                                    borderRadius: BorderRadius.circular(8),
                                    border:
                                        Border.all(color: Colors.grey[300]!),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      if (selectedTemplateDetails
                                              .includeSport &&
                                          selectedTemplateDetails.sport != null)
                                        _buildDetailRow(
                                          'Sport',
                                          selectedTemplateDetails.sport!,
                                        ),
                                      if (selectedTemplateDetails
                                              .includeLocation &&
                                          selectedTemplateDetails.location !=
                                              null)
                                        _buildDetailRow(
                                          'Location',
                                          selectedTemplateDetails.location!,
                                        ),
                                      if (selectedTemplateDetails
                                              .includeLevelOfCompetition &&
                                          selectedTemplateDetails
                                                  .levelOfCompetition !=
                                              null)
                                        _buildDetailRow(
                                          'Level of Competition',
                                          selectedTemplateDetails
                                              .levelOfCompetition!,
                                        ),
                                      if (selectedTemplateDetails
                                              .includeGender &&
                                          selectedTemplateDetails.gender !=
                                              null)
                                        _buildDetailRow(
                                          'Gender',
                                          selectedTemplateDetails.gender!,
                                        ),
                                      if (selectedTemplateDetails
                                              .officialsRequired !=
                                          null)
                                        _buildDetailRow(
                                          'Officials Required',
                                          selectedTemplateDetails
                                              .officialsRequired
                                              .toString(),
                                        ),
                                      if (selectedTemplateDetails.gameFee !=
                                          null)
                                        _buildDetailRow(
                                          'Game Fee',
                                          '\$${double.tryParse(selectedTemplateDetails.gameFee!)?.toStringAsFixed(2) ?? selectedTemplateDetails.gameFee!}',
                                        ),
                                      if (selectedTemplateDetails
                                              .includeHireAutomatically &&
                                          selectedTemplateDetails
                                                  .hireAutomatically !=
                                              null)
                                        _buildDetailRow(
                                          'Hire Automatically',
                                          selectedTemplateDetails
                                                  .hireAutomatically!
                                              ? 'Yes'
                                              : 'No',
                                        ),
                                      if (selectedTemplateDetails
                                              .includeSelectedOfficials &&
                                          selectedTemplateDetails.method !=
                                              null)
                                        _buildDetailRow(
                                          'Selected Officials',
                                          _formatOfficialsDisplay(
                                              selectedTemplateDetails),
                                        ),
                                      if (selectedTemplateDetails.includeDate &&
                                          selectedTemplateDetails.date != null)
                                        _buildDetailRow(
                                          'Date',
                                          DateFormat('MMM d, yyyy').format(
                                              selectedTemplateDetails.date!),
                                        ),
                                      if (selectedTemplateDetails.includeTime &&
                                          selectedTemplateDetails.time != null)
                                        _buildDetailRow(
                                          'Time',
                                          selectedTemplateDetails.time!
                                              .format(context),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                              const SizedBox(height: 60),
                              ElevatedButton(
                                onPressed: (selectedTemplate == null ||
                                        selectedTemplate ==
                                            '+ Create new template')
                                    ? null
                                    : () {
                                        final selected = templates.firstWhere(
                                            (t) => t.name == selectedTemplate);
                                        Navigator.pushNamed(
                                          context,
                                          '/select_schedule',
                                          arguments: {'template': selected},
                                        );
                                      },
                                style: elevatedButtonStyle(),
                                child: const Text(
                                  'Create Game',
                                  style: signInButtonTextStyle,
                                ),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: (selectedTemplate == null ||
                                        selectedTemplate ==
                                            '+ Create new template')
                                    ? null
                                    : () {
                                        final selected = templates.firstWhere(
                                            (t) => t.name == selectedTemplate);
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
                                            _fetchTemplates(); // Refresh templates after editing
                                          }
                                        });
                                      },
                                style: elevatedButtonStyle(),
                                child: const Text(
                                  'Edit Template',
                                  style: signInButtonTextStyle,
                                ),
                              ),
                            ],
                          ),
              ],
            ),
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
          .map((official) => official['name'] as String)
          .join(', ');
      return 'Standard ($names)';
    } else if (template.method == 'advanced' &&
        template.selectedOfficials != null &&
        template.selectedOfficials!.isNotEmpty) {
      final names = template.selectedOfficials!
          .map((official) => official['name'] as String)
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
