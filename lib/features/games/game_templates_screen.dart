import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // For formatting DateTime
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

class _GameTemplatesScreenState extends State<GameTemplatesScreen> with RouteAware {
  List<GameTemplate> templates = [];
  bool isLoading = true;
  List<String> sports = [];
  String? schedulerType;
  String? userSport;
  String? expandedTemplateId;
  final GameService _gameService = GameService();

  @override
  void initState() {
    super.initState();
    _fetchTemplates();
  }

  @override
  void didPopNext() {
    // Called when a route has been popped and this route is now the current route
    // This will refresh the templates when returning from create template screen
    _fetchTemplates();
  }

  Future<void> _fetchTemplates() async {
    try {
      // Use GameService to get templates from database
      final templatesData = await _gameService.getTemplates();
      
      // If database returns empty but we might have SharedPreferences data, check there too
      if (templatesData.isEmpty) {
        final prefs = await SharedPreferences.getInstance();
        final String? templatesJson = prefs.getString('game_templates');
        if (templatesJson != null && templatesJson.isNotEmpty) {
          await _fetchTemplatesFromPrefs();
          return;
        }
      }
      
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
      final success = await _gameService.deleteTemplate(int.parse(template.id));
      
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

  Future<void> _useTemplate(GameTemplate template) async {
    final prefs = await SharedPreferences.getInstance();
    final currentSchedulerType = prefs.getString('schedulerType');
    
    
    // For Coaches: Skip schedule selection and use their team name
    if (currentSchedulerType == 'Coach') {
      final teamName = prefs.getString('team_name');
      if (teamName != null) {
        Navigator.pushNamed(
          context,
          '/date_time',
          arguments: {
            'sport': template.sport,
            'template': template,
            'scheduleName': teamName,
          },
        );
        return;
      }
    }
    
    // For Athletic Directors and Assigners: Navigate to schedule selection
    // They need to select a schedule first before creating the game
    Navigator.pushNamed(
      context,
      '/select_schedule',
      arguments: {
        'sport': template.sport,
        'template': template,
      },
    );
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
                                  'No Game Templates found.',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: primaryTextColor,
                                  ),
                                ),
                                const SizedBox(height: 24),
                                Container(
                                  width: 250,
                                  child: ElevatedButton.icon(
                                    onPressed: () async {
                                      final result = await Navigator.pushNamed(context, '/create_game_template');
                                      if (result != null) {
                                        // Template was created, refresh the list
                                        await _fetchTemplates();
                                      }
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
                                        final templateName = template.name;
                                        final sport = template.sport ?? 'Unknown';
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
                                                                overflow: TextOverflow.ellipsis,
                                                                maxLines: 2,
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
                                                              onPressed: () async {
                                                                final result = await Navigator.pushNamed(
                                                                  context,
                                                                  '/create_game_template',
                                                                  arguments: {
                                                                    'template': template,
                                                                  },
                                                                );
                                                                if (result != null) {
                                                                  // Template was updated, refresh the list
                                                                  await _fetchTemplates();
                                                                }
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
                                                                _useTemplate(template);
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
                                        onPressed: () async {
                                          final result = await Navigator.pushNamed(context, '/create_game_template');
                                          if (result != null) {
                                            // Template was created, refresh the list
                                            await _fetchTemplates();
                                          }
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
          if (template.method == 'use_list' && template.officialsListName?.isNotEmpty == true)
            _buildDetailRow('Method', 'Use Saved List: ${template.officialsListName}')
          else
            _buildDetailRow('Method', _getMethodDisplayName(template.method)),
          
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
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
          ),
        ],
      ),
    );
  }
}
