import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'game_template.dart';
import 'theme.dart';

class GameTemplatesScreen extends StatefulWidget {
  const GameTemplatesScreen({super.key});

  @override
  State<GameTemplatesScreen> createState() => _GameTemplatesScreenState();
}

class _GameTemplatesScreenState extends State<GameTemplatesScreen> {
  List<GameTemplate> templates = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
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
      isLoading = false;
    });
  }

  Future<void> _deleteTemplate(GameTemplate template) async {
    final prefs = await SharedPreferences.getInstance();
    templates.removeWhere((t) => t.name == template.name);
    await prefs.setString('game_templates', jsonEncode(templates.map((t) => t.toJson()).toList()));
    setState(() {});
  }

  void _showDeleteConfirmationDialog(GameTemplate template) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: Text('Are you sure you want to delete the template "${template.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: efficialsBlue)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteTemplate(template);
            },
            child: const Text('Delete', style: TextStyle(color: efficialsBlue)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: efficialsBlue,
        title: const Text('Game Templates', style: appBarTextStyle),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : templates.isEmpty
              ? const Center(child: Text('No templates available. Create a game to add a template.'))
              : ListView.builder(
                  itemCount: templates.length,
                  itemBuilder: (context, index) {
                    final template = templates[index];
                    return ListTile(
                      title: Text(template.name),
                      subtitle: Text('Sport: ${template.includeSport ? template.sport : "Not included"}'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _showDeleteConfirmationDialog(template),
                          ),
                        ],
                      ),
                      onTap: () {
                        // Optionally, add an edit functionality here
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Edit functionality not implemented yet')),
                        );
                      },
                    );
                  },
                ),
    );
  }
}