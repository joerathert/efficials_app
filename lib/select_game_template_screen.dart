import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'theme.dart';
import 'game_template.dart';

class SelectGameTemplateScreen extends StatefulWidget {
  const SelectGameTemplateScreen({super.key});

  @override
  State<SelectGameTemplateScreen> createState() => _SelectGameTemplateScreenState();
}

class _SelectGameTemplateScreenState extends State<SelectGameTemplateScreen> {
  String? selectedTemplateId;
  List<GameTemplate> templates = [];
  bool isLoading = true;
  String? scheduleName;

  @override
  void initState() {
    super.initState();
    _fetchTemplates();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
    if (args != null) {
      scheduleName = args['scheduleName'] as String?;
    }
  }

  Future<void> _fetchTemplates() async {
    final prefs = await SharedPreferences.getInstance();
    final String? templatesJson = prefs.getString('game_templates');
    setState(() {
      templates.clear();
      if (templatesJson != null && templatesJson.isNotEmpty) {
        final List<dynamic> templatesList = jsonDecode(templatesJson);
        templates = templatesList.map((json) => GameTemplate.fromJson(json)).toList();
      }
      templates.add(GameTemplate(
        id: '0',
        name: '+ Create new template',
        includeSport: false,
      )); // Placeholder for creating a new template
      isLoading = false;
    });
  }

  Future<void> _associateTemplate() async {
    if (selectedTemplateId == null || scheduleName == null) return;
    final prefs = await SharedPreferences.getInstance();

    if (selectedTemplateId == '0') {
      // Navigate to create a new template
      Navigator.pushNamed(context, '/create_game_template', arguments: {
        'scheduleName': scheduleName,
      }).then((result) async {
        if (result != null && result is GameTemplate) {
          // Add the new template to the list
          templates.insert(templates.length - 1, result);
          await prefs.setString('game_templates', jsonEncode(templates.where((t) => t.id != '0').toList()));
          // Associate the new template with the schedule
          await prefs.setString(
            'schedule_template_${scheduleName!.toLowerCase()}',
            jsonEncode(result.toJson()),
          );
          Navigator.pop(context);
        }
      });
    } else {
      // Associate the selected template with the schedule
      final selectedTemplate = templates.firstWhere((t) => t.id == selectedTemplateId);
      await prefs.setString(
        'schedule_template_${scheduleName!.toLowerCase()}',
        jsonEncode(selectedTemplate.toJson()),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: efficialsBlue,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, size: 36, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Select Game Template', style: appBarTextStyle),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Select a template for this schedule',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                isLoading
                    ? const CircularProgressIndicator()
                    : DropdownButtonFormField<String>(
                        decoration: textFieldDecoration('Templates'),
                        value: selectedTemplateId,
                        hint: const Text('Select a template'),
                        onChanged: (newValue) {
                          setState(() {
                            selectedTemplateId = newValue;
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
                ElevatedButton(
                  onPressed: selectedTemplateId != null ? _associateTemplate : null,
                  style: elevatedButtonStyle(),
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