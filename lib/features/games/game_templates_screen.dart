import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'game_template.dart';
import '../../shared/theme.dart';
import '../../shared/utils/utils.dart';
import '../../shared/services/game_service.dart';
import '../../shared/services/repositories/user_repository.dart';

class GameTemplatesScreen extends StatefulWidget {
  const GameTemplatesScreen({super.key});

  @override
  State<GameTemplatesScreen> createState() => _GameTemplatesScreenState();
}

class _GameTemplatesScreenState extends State<GameTemplatesScreen>
    with RouteAware {
  List<GameTemplate> templates = [];
  bool isLoading = true;
  List<String> sports = [];
  Map<String, List<GameTemplate>> groupedTemplates = {};
  String? schedulerType;
  String? userSport;
  String? expandedTemplateId;
  String? expandedDialogTemplateId;
  final GameService _gameService = GameService();
  final UserRepository _userRepository = UserRepository();

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
      // Get current user information for context and filtering
      final currentUser = await _userRepository.getCurrentUser();
      if (currentUser != null) {
        schedulerType = currentUser.schedulerType;
        // For assigners and coaches, get their sport
        if (schedulerType == 'Assigner' || schedulerType == 'Coach') {
          userSport = currentUser.sport ?? currentUser.leagueName;
        }
      }

      // Use GameService to get templates from database
      final templatesData = await _gameService.getTemplates();

      setState(() {
        templates.clear();
        // Convert Map data to GameTemplate objects
        templates = templatesData
            .map((templateData) => GameTemplate.fromJson(templateData))
            .toList();

        // Extract unique sports from templates, excluding null values
        Set<String> allSports = templates
            .where((t) =>
                t.includeSport && t.sport != null) // Ensure sport is not null
            .map((t) => t.sport!) // Use ! since we filtered out nulls
            .toSet()
            .cast<String>();

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

        // Group templates by sport for Athletic Directors
        _groupTemplatesBySport();

        isLoading = false;
      });
    } catch (e) {
      setState(() {
        templates = [];
        sports = [];
        groupedTemplates = {};
        isLoading = false;
      });
    }
  }

  void _groupTemplatesBySport() {
    groupedTemplates.clear();

    // Only group by sport for Athletic Directors
    if (schedulerType != 'athletic_director') {
      // For non-Athletic Directors, don't group
      return;
    }

    for (var template in templates) {
      final sport = template.sport ?? 'Unknown';
      if (!groupedTemplates.containsKey(sport)) {
        groupedTemplates[sport] = [];
      }
      groupedTemplates[sport]!.add(template);
    }

    // Sort templates within each sport group by name
    for (var sportTemplates in groupedTemplates.values) {
      sportTemplates.sort((a, b) => a.name.compareTo(b.name));
    }
  }

  void _showTemplateSelectionDialog(
      String sport, List<GameTemplate> sportTemplates) {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: darkSurface,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: efficialsYellow.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.sports,
                  color: efficialsYellow,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '$sport Templates',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: primaryTextColor,
                  ),
                ),
              ),
            ],
          ),
          contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 500),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: sportTemplates.map((template) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _buildDialogTemplateCard(template, setDialogState),
                  );
                }).toList(),
              ),
            ),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
          actions: [
            TextButton(
              onPressed: () {
                if (expandedDialogTemplateId != null) {
                  // If a template is expanded, collapse it first
                  setDialogState(() {
                    expandedDialogTemplateId = null;
                  });
                } else {
                  // If no template is expanded, close the dialog
                  Navigator.pop(context);
                }
              },
              style: TextButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              child: Text(
                expandedDialogTemplateId != null ? 'Collapse' : 'Close',
                style: const TextStyle(
                  color: efficialsBlue,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmationDialog(
      String templateName, GameTemplate template) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: darkSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        title: const Text(
          'Confirm Delete',
          style: TextStyle(
            color: primaryTextColor,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Are you sure you want to delete "$templateName"?',
          style: const TextStyle(
            color: secondaryTextColor,
            fontSize: 16,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              foregroundColor: efficialsGray,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            child: const Text(
              'Cancel',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteTemplate(template);
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red.shade400,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            child: const Text(
              'Delete',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
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
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to delete template')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting template: $e')),
        );
      }
    }
  }

  Future<void> _useTemplate(GameTemplate template) async {
    try {
      final currentUser = await _userRepository.getCurrentUser();
      final currentSchedulerType = currentUser?.schedulerType;

      // For Coaches: Skip schedule selection and use their team name
      if (currentSchedulerType == 'Coach') {
        final teamName = currentUser?.teamName;
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
    } catch (e) {
      // Fallback to schedule selection if we can't get user data
      Navigator.pushNamed(
        context,
        '/select_schedule',
        arguments: {
          'sport': template.sport,
          'template': template,
        },
      );
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
                                      final result = await Navigator.pushNamed(
                                          context, '/create_game_template');
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
                                    icon: const Icon(Icons.add,
                                        color: efficialsBlack),
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

                              final maxListHeight = constraints.maxHeight -
                                  buttonHeight -
                                  padding -
                                  minBottomSpace;

                              return Column(
                                children: [
                                  Container(
                                    constraints: BoxConstraints(
                                      maxHeight: maxListHeight > 0
                                          ? maxListHeight
                                          : constraints.maxHeight * 0.6,
                                    ),
                                    child: schedulerType ==
                                                'athletic_director' &&
                                            groupedTemplates.isNotEmpty
                                        ? ListView.builder(
                                            shrinkWrap: true,
                                            itemCount:
                                                groupedTemplates.keys.length,
                                            itemBuilder: (context, index) {
                                              final sport = groupedTemplates
                                                  .keys
                                                  .elementAt(index);
                                              final sportTemplates =
                                                  groupedTemplates[sport]!;

                                              return Padding(
                                                padding: const EdgeInsets.only(
                                                    bottom: 12.0),
                                                child: GestureDetector(
                                                  onTap: () {
                                                    // Always show template selection dialog
                                                    _showTemplateSelectionDialog(
                                                        sport, sportTemplates);
                                                  },
                                                  child: Container(
                                                    padding:
                                                        const EdgeInsets.all(
                                                            16),
                                                    decoration: BoxDecoration(
                                                      color: darkSurface,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              12),
                                                      boxShadow: [
                                                        BoxShadow(
                                                          color: Colors.black
                                                              .withOpacity(0.3),
                                                          spreadRadius: 1,
                                                          blurRadius: 3,
                                                          offset: const Offset(
                                                              0, 1),
                                                        ),
                                                      ],
                                                    ),
                                                    child: Row(
                                                      children: [
                                                        Container(
                                                          padding:
                                                              const EdgeInsets
                                                                  .all(12),
                                                          decoration:
                                                              BoxDecoration(
                                                            color:
                                                                getSportIconColor(
                                                                        sport)
                                                                    .withOpacity(
                                                                        0.1),
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        8),
                                                          ),
                                                          child: Icon(
                                                            getSportIcon(sport),
                                                            color:
                                                                getSportIconColor(
                                                                    sport),
                                                            size: 24,
                                                          ),
                                                        ),
                                                        const SizedBox(
                                                            width: 16),
                                                        Expanded(
                                                          child: Column(
                                                            crossAxisAlignment:
                                                                CrossAxisAlignment
                                                                    .start,
                                                            children: [
                                                              Row(
                                                                children: [
                                                                  Text(
                                                                    sport,
                                                                    style:
                                                                        const TextStyle(
                                                                      fontSize:
                                                                          18,
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .bold,
                                                                      color:
                                                                          primaryTextColor,
                                                                    ),
                                                                  ),
                                                                  if (sportTemplates
                                                                          .length >
                                                                      1) ...[
                                                                    const SizedBox(
                                                                        width:
                                                                            8),
                                                                    Container(
                                                                      padding: const EdgeInsets
                                                                          .symmetric(
                                                                          horizontal:
                                                                              6,
                                                                          vertical:
                                                                              2),
                                                                      decoration:
                                                                          BoxDecoration(
                                                                        color: Colors
                                                                            .grey
                                                                            .withOpacity(0.2),
                                                                        borderRadius:
                                                                            BorderRadius.circular(8),
                                                                      ),
                                                                      child:
                                                                          Text(
                                                                        '${sportTemplates.length}',
                                                                        style:
                                                                            const TextStyle(
                                                                          fontSize:
                                                                              12,
                                                                          fontWeight:
                                                                              FontWeight.w600,
                                                                        ),
                                                                      ),
                                                                    ),
                                                                  ],
                                                                ],
                                                              ),
                                                              const SizedBox(
                                                                  height: 4),
                                                              Text(
                                                                '${sportTemplates.length} template${sportTemplates.length == 1 ? '' : 's'}',
                                                                style:
                                                                    const TextStyle(
                                                                  fontSize: 14,
                                                                  color:
                                                                      secondaryTextColor,
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                        const Icon(
                                                          Icons
                                                              .arrow_forward_ios,
                                                          color: Colors.grey,
                                                          size: 16,
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              );
                                            },
                                          )
                                        : ListView.builder(
                                            shrinkWrap: true,
                                            itemCount: templates.length,
                                            itemBuilder: (context, index) {
                                              final template = templates[index];
                                              return Padding(
                                                padding: const EdgeInsets.only(
                                                    bottom: 12.0),
                                                child: _buildTemplateCard(
                                                    template),
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
                                          final result =
                                              await Navigator.pushNamed(context,
                                                  '/create_game_template');
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
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                        ),
                                        icon: const Icon(Icons.add,
                                            color: efficialsBlack),
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
        if (template.includeScheduleName &&
            template.scheduleName?.isNotEmpty == true)
          _buildDetailRow('Schedule', template.scheduleName!),

        if (template.includeDate && template.date != null)
          _buildDetailRow(
              'Date', DateFormat('EEEE, MMMM d, y').format(template.date!)),

        if (template.includeTime && template.time != null)
          _buildDetailRow('Time', template.time!.format(context)),

        if (template.includeLocation && template.location?.isNotEmpty == true)
          _buildDetailRow('Location', template.location!),

        if (template.includeOpponent && template.opponent?.isNotEmpty == true)
          _buildDetailRow('Opponent', template.opponent!),

        if (template.includeIsAwayGame)
          _buildDetailRow(
              'Game Type', template.isAwayGame ? 'Away Game' : 'Home Game'),

        if (template.includeLevelOfCompetition &&
            template.levelOfCompetition?.isNotEmpty == true)
          _buildDetailRow('Level', template.levelOfCompetition!),

        if (template.includeGender && template.gender?.isNotEmpty == true)
          _buildDetailRow('Gender', template.gender!),

        if (template.includeOfficialsRequired &&
            template.officialsRequired != null)
          _buildDetailRow(
              'Officials Required', '${template.officialsRequired}'),

        if (template.includeGameFee && template.gameFee?.isNotEmpty == true)
          _buildDetailRow('Game Fee', '\$${template.gameFee}'),

        if (template.includeHireAutomatically &&
            template.hireAutomatically != null)
          _buildDetailRow(
              'Auto Hire', template.hireAutomatically! ? 'Yes' : 'No'),

        // Officials Information
        if (template.includeSelectedOfficials ||
            template.includeOfficialsList) ...[
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
          if (template.method == 'use_list' &&
              template.officialsListName?.isNotEmpty == true)
            _buildDetailRow(
                'Method', 'Use Saved List: ${template.officialsListName}')
          else if (template.method == 'hire_crew' &&
              template.selectedCrewListName?.isNotEmpty == true)
            _buildDetailRow(
                'Method', 'Hire a Crew (${template.selectedCrewListName})')
          else if (template.method == 'hire_crew')
            _buildDetailRow('Method', 'Hire a Crew (List name missing)')
          else
            _buildDetailRow('Method', _getMethodDisplayName(template.method)),

          // Show advanced method details
          if (template.method == 'advanced' &&
              template.selectedLists?.isNotEmpty == true) ...[
            const SizedBox(height: 8),
            _buildDetailRow(
                'Lists Configured', '${template.selectedLists!.length}'),
            const SizedBox(height: 4),
            ...template.selectedLists!.map((list) {
              final listName = list['name'] as String? ?? 'Unknown List';
              final minOfficials = list['minOfficials'] as int? ?? 0;
              final maxOfficials = list['maxOfficials'] as int? ?? 0;
              final officialsCount = (list['officials'] as List?)?.length ?? 0;
              return Padding(
                padding: const EdgeInsets.only(left: 16, bottom: 2),
                child: Text(
                  '• $listName: $minOfficials-$maxOfficials officials ($officialsCount available)',
                  style: const TextStyle(
                    fontSize: 14,
                    color: secondaryTextColor,
                  ),
                ),
              );
            }).toList(),
          ]
          // Show crew method details
          else if (template.method == 'hire_crew' &&
              template.selectedCrews?.isNotEmpty == true) ...[
            const SizedBox(height: 8),
            _buildDetailRow('Selected Crews', '${template.selectedCrews!.length}'),
            const SizedBox(height: 4),
            ...template.selectedCrews!.map((crew) {
              final crewName = crew['name'] as String? ?? 'Unknown Crew';
              return Padding(
                padding: const EdgeInsets.only(left: 16, bottom: 2),
                child: Text(
                  '• $crewName',
                  style: const TextStyle(
                    fontSize: 14,
                    color: secondaryTextColor,
                  ),
                ),
              );
            }).toList(),
          ]
          // Show standard method selected officials
          else if ((template.method == 'standard') &&
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
      case 'hire_crew':
        return 'Hire a Crew';
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

  Widget _buildDialogTemplateCard(
      GameTemplate template, StateSetter setDialogState) {
    final templateName = template.name;
    final sport = template.sport ?? 'Unknown';
    final isExpanded = expandedDialogTemplateId == template.id;

    return Container(
      decoration: BoxDecoration(
        color: darkSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[700]!, width: 1),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () {
              setDialogState(() {
                expandedDialogTemplateId = isExpanded ? null : template.id;
              });
            },
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Template title row
                  Row(
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
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            templateName,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: primaryTextColor,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      Icon(
                        isExpanded ? Icons.expand_less : Icons.expand_more,
                        color: secondaryTextColor,
                        size: 24,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Action buttons row
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () async {
                            Navigator.pop(context);
                            final result = await Navigator.pushNamed(
                              context,
                              '/create_game_template',
                              arguments: {
                                'template': template,
                              },
                            );
                            if (result != null) {
                              await _fetchTemplates();
                            }
                          },
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            minimumSize: const Size(0, 40),
                            backgroundColor: efficialsYellow.withOpacity(0.1),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                            'Edit',
                            style: TextStyle(
                              color: efficialsYellow,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                            _showDeleteConfirmationDialog(
                                template.name, template);
                          },
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            minimumSize: const Size(0, 40),
                            backgroundColor: Colors.red.withOpacity(0.1),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(
                            'Delete',
                            style: TextStyle(
                              color: Colors.red.shade600,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                            _useTemplate(template);
                          },
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            minimumSize: const Size(0, 40),
                            backgroundColor: Colors.green.withOpacity(0.1),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                            'Use',
                            style: TextStyle(
                              color: Colors.green,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
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
    );
  }

  Widget _buildTemplateCard(GameTemplate template, {bool isInDialog = false}) {
    final templateName = template.name;
    final sport = template.sport ?? 'Unknown';
    final isExpanded = expandedTemplateId == template.id;

    return Container(
      decoration: BoxDecoration(
        color: darkSurface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: isInDialog
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  spreadRadius: 1,
                  blurRadius: 3,
                  offset: const Offset(0, 1),
                ),
              ],
        border:
            isInDialog ? Border.all(color: Colors.grey[700]!, width: 1) : null,
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () {
              if (isInDialog) {
                // In dialog, don't expand - just handle tap differently
                return;
              }
              setState(() {
                expandedTemplateId = isExpanded ? null : template.id;
              });
            },
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
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
                      if (!isInDialog) ...[
                        Icon(
                          isExpanded ? Icons.expand_less : Icons.expand_more,
                          color: secondaryTextColor,
                          size: 24,
                        ),
                        const SizedBox(width: 8),
                        _buildTemplateActions(template),
                      ],
                    ],
                  ),
                  if (isInDialog) ...[
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        IconButton(
                          onPressed: () async {
                            Navigator.pop(context);
                            final result = await Navigator.pushNamed(
                              context,
                              '/create_game_template',
                              arguments: {
                                'template': template,
                              },
                            );
                            if (result != null) {
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
                            Navigator.pop(context);
                            _showDeleteConfirmationDialog(
                                template.name, template);
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
                            Navigator.pop(context);
                            _useTemplate(template);
                          },
                          icon: const Icon(
                            Icons.arrow_forward,
                            color: Colors.green,
                            size: 20,
                          ),
                          tooltip: 'Use Template',
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (isExpanded && !isInDialog) ...[
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
    );
  }

  Widget _buildActionButton({
    required VoidCallback onPressed,
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return TextButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, color: color, size: 20),
      label: Text(
        label,
        style: TextStyle(color: color),
      ),
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    );
  }

  Widget _buildTemplateActions(GameTemplate template,
      {bool isInDialog = false}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          onPressed: () async {
            if (isInDialog) {
              Navigator.pop(context); // Close dialog first
            }
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
            if (isInDialog) {
              Navigator.pop(context); // Close dialog first
            }
            _showDeleteConfirmationDialog(template.name, template);
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
            if (isInDialog) {
              Navigator.pop(context); // Close dialog first
            }
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
    );
  }
}
