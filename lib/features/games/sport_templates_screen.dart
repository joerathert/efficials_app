import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // For formatting DateTime
import 'package:shared_preferences/shared_preferences.dart';
import 'game_template.dart';
import '../../shared/theme.dart';
import '../../shared/utils/utils.dart';
import '../../shared/services/game_service.dart';

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
  String? schedulerType;
  String? teamName;
  String? expandedTemplateId;
  final GameService _gameService = GameService();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    sport = args['sport'] as String? ?? 'Unknown';
    _fetchTemplates();
  }

  Future<void> _fetchTemplates() async {
    try {
      // Use GameService to get templates from database for specific sport
      final templatesData = await _gameService.getTemplatesBySport(sport);
      
      // Load scheduler information for coaches (still needed for context)
      final prefs = await SharedPreferences.getInstance();
      schedulerType = prefs.getString('schedulerType');
      if (schedulerType == 'Coach') {
        teamName = prefs.getString('team_name');
      }
      
      setState(() {
        templates.clear();
        // Convert Map data to GameTemplate objects and filter by sport
        templates = templatesData.map((templateData) => GameTemplate.fromJson(templateData)).toList();
        templates = templates.where((template) => template.sport == sport).toList();
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
    
    // Load scheduler information for coaches
    schedulerType = prefs.getString('schedulerType');
    if (schedulerType == 'Coach') {
      teamName = prefs.getString('team_name');
    }
    
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
      Navigator.pushNamed(context, '/create_game_template', arguments: {
        'sport': sport,
      }).then((result) {
        if (result == true) {
          _fetchTemplates(); // Refresh templates after creating a new one
        }
      });
    }
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
    final prefs = await SharedPreferences.getInstance();
    final templatesJson = prefs.getString('game_templates');
    if (templatesJson != null) {
      final List<dynamic> decoded = jsonDecode(templatesJson);
      final updatedTemplates = decoded.where((t) => t['id'] != template.id).toList();
      await prefs.setString('game_templates', jsonEncode(updatedTemplates));
      setState(() {
        templates.removeWhere((t) => t.id == template.id);
        selectedTemplate = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Template deleted successfully')),
      );
      _fetchTemplates();
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
              Text(
                'Manage your saved game templates for $sport',
                style: const TextStyle(
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
                                Text(
                                  'Create your first $sport template to get started',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: secondaryTextColor,
                                  ),
                                ),
                                const SizedBox(height: 24),
                                Container(
                                  width: 250,
                                  child: ElevatedButton.icon(
                                    onPressed: () {
                                      Navigator.pushNamed(context, '/create_game_template', arguments: {
                                        'sport': sport,
                                      });
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
                                      'Create New Template',
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
                                        final templateName = template.name ?? 'Unnamed Template';

                                        final isExpanded = expandedTemplateId == template.id;

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
                                            child: Column(
                                              children: [
                                                InkWell(
                                                  onTap: () {
                                                    setState(() {
                                                      expandedTemplateId = isExpanded ? null : template.id;
                                                    });
                                                  },
                                                  borderRadius: BorderRadius.circular(12),
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
                                                                _formatTemplateDetails(template),
                                                                style: const TextStyle(
                                                                  fontSize: 14,
                                                                  color: secondaryTextColor,
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                        Icon(
                                                          isExpanded ? Icons.expand_less : Icons.expand_more,
                                                          color: secondaryTextColor,
                                                          size: 24,
                                                        ),
                                                        const SizedBox(width: 8),
                                                        Row(
                                                          mainAxisSize: MainAxisSize.min,
                                                          children: [
                                                            IconButton(
                                                              onPressed: () {
                                                                Navigator.pushNamed(
                                                                  context,
                                                                  '/create_game_template',
                                                                  arguments: {
                                                                    'template': template,
                                                                    'sport': sport,
                                                                    'isEdit': true,
                                                                  },
                                                                ).then((result) {
                                                                  if (result != null) {
                                                                    _fetchTemplates();
                                                                  }
                                                                });
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
                                                                final args = ModalRoute.of(context)!
                                                                    .settings
                                                                    .arguments as Map<String, dynamic>?;
                                                                final scheduleName = args?['scheduleName'] as String?;

                                                                // Coaches should skip schedule selection and use their team name
                                                                if (schedulerType == 'Coach' && teamName != null) {
                                                                  Navigator.pushNamed(
                                                                    context,
                                                                    '/date_time',
                                                                    arguments: {
                                                                      'sport': sport,
                                                                      'template': template,
                                                                      'scheduleName': teamName,
                                                                    },
                                                                  );
                                                                } else if (scheduleName != null) {
                                                                  Navigator.pushNamed(
                                                                    context,
                                                                    '/date_time',
                                                                    arguments: {
                                                                      'sport': sport,
                                                                      'template': template,
                                                                      'scheduleName': scheduleName,
                                                                    },
                                                                  );
                                                                } else {
                                                                  Navigator.pushNamed(
                                                                    context,
                                                                    '/select_schedule',
                                                                    arguments: {
                                                                      'sport': sport,
                                                                      'template': template,
                                                                    },
                                                                  );
                                                                }
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
                                                if (isExpanded) ...[
                                                  const Divider(
                                                    color: secondaryTextColor,
                                                    thickness: 0.5,
                                                    height: 1,
                                                  ),
                                                  Padding(
                                                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
                                                    child: _buildTemplateDetails(template),
                                                  ),
                                                ],
                                              ],
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
                                          Navigator.pushNamed(context, '/create_game_template', arguments: {
                                            'sport': sport,
                                          });
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
                                          'Create New Template',
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

  String _formatTemplateDetails(GameTemplate template) {
    final details = <String>[];
    
    if (template.includeDate && template.date != null) {
      details.add(DateFormat('MMM d, y').format(template.date!));
    }
    
    if (template.includeOpponent && template.opponent?.isNotEmpty == true) {
      details.add('vs ${template.opponent}');
    }
    
    if (template.includeLocation && template.location?.isNotEmpty == true) {
      details.add(template.location!);
    }
    
    return details.isEmpty ? 'Template details' : details.join(' • ');
  }

  Widget _buildTemplateDetails(GameTemplate template) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Template Details',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: primaryTextColor,
          ),
        ),
        const SizedBox(height: 12),
        
        // Basic Information
        if (template.includeScheduleName && template.scheduleName?.isNotEmpty == true)
          _buildDetailRow('Schedule', template.scheduleName!),
        
        if (template.includeDate && template.date != null)
          _buildDetailRow('Date', DateFormat('EEEE, MMMM d, y').format(template.date!)),
        
        if (template.includeTime && template.time != null)
          _buildDetailRow('Time', template.time!.format(context)),
        
        if (template.includeLocation && template.location?.isNotEmpty == true)
          _buildDetailRow('Location', template.location!),
        
        if (template.includeOpponent && template.opponent?.isNotEmpty == true)
          _buildDetailRow('Opponent', template.opponent!),
        
        if (template.includeIsAwayGame)
          _buildDetailRow('Game Type', template.isAwayGame ? 'Away Game' : 'Home Game'),
        
        if (template.includeLevelOfCompetition && template.levelOfCompetition?.isNotEmpty == true)
          _buildDetailRow('Level', template.levelOfCompetition!),
        
        if (template.includeGender && template.gender?.isNotEmpty == true)
          _buildDetailRow('Gender', template.gender!),
        
        if (template.includeOfficialsRequired && template.officialsRequired != null)
          _buildDetailRow('Officials Required', '${template.officialsRequired}'),
        
        if (template.includeGameFee && template.gameFee?.isNotEmpty == true)
          _buildDetailRow('Game Fee', '\$${template.gameFee}'),
        
        if (template.includeHireAutomatically && template.hireAutomatically != null)
          _buildDetailRow('Auto Hire', template.hireAutomatically! ? 'Yes' : 'No'),
        
        // Officials Information
        if (template.includeSelectedOfficials || template.includeOfficialsList) ...[
          const SizedBox(height: 8),
          const Divider(color: secondaryTextColor, thickness: 0.5),
          const SizedBox(height: 8),
          const Text(
            'Officials Assignment',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: primaryTextColor,
            ),
          ),
          const SizedBox(height: 8),
          _buildDetailRow('Method', _getMethodDisplayName(template.method)),
          
          if (template.method == 'use_list' && template.officialsListName?.isNotEmpty == true)
            _buildDetailRow('Officials List', template.officialsListName!),
          
          if ((template.method == 'standard' || template.method == 'advanced') && 
              template.selectedOfficials?.isNotEmpty == true) ...[
            _buildDetailRow('Selected Officials', ''),
            const SizedBox(height: 4),
            ...template.selectedOfficials!.map((official) {
              final name = official['name'] as String? ?? 'Unknown';
              return Padding(
                padding: const EdgeInsets.only(left: 16, bottom: 2),
                child: Text(
                  '• $name',
                  style: const TextStyle(
                    fontSize: 14,
                    color: secondaryTextColor,
                  ),
                ),
              );
            }).toList(),
          ],
        ],
      ],
    );
  }

  String _getMethodDisplayName(String? method) {
    switch (method) {
      case 'use_list':
        return 'Use Saved List';
      case 'standard':
        return 'Standard Selection';
      case 'advanced':
        return 'Advanced Selection';
      default:
        return 'Not Set';
    }
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
