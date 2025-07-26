import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../shared/theme.dart';
import '../../shared/services/repositories/user_repository.dart';
import '../../shared/services/user_session_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool isLoading = true;
  String? schedulerType;
  bool showAwayGames = true;
  bool showFullyCoveredGames = true;
  bool dontAskCreateTemplate = false;
  bool defaultDarkMode = false;
  String? defaultMethod;
  bool defaultChoice = false;
  
  // Notification Settings
  bool emailNotifications = true;
  bool pushNotifications = true;
  bool textNotifications = false;
  bool gameReminders = true;
  bool scheduleUpdates = true;
  bool assignmentAlerts = true;
  bool emergencyNotifications = true;
  
  // Privacy Settings
  bool shareProfile = true;
  bool showAvailability = true;
  bool allowContactFromOfficials = true;
  
  // App Preferences
  String notificationSound = 'default';
  bool vibrationEnabled = true;
  String dateFormat = 'MM/dd/yyyy';
  String timeFormat = '12';
  bool autoRefresh = true;
  int refreshInterval = 30;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final sessionService = UserSessionService.instance;
      
      // Load UI preferences from SharedPreferences
      showAwayGames = prefs.getBool('showAwayGames') ?? true;
      showFullyCoveredGames = prefs.getBool('showFullyCoveredGames') ?? true;
      dontAskCreateTemplate = prefs.getBool('dont_ask_create_template') ?? false;
      defaultDarkMode = prefs.getBool('default_dark_mode') ?? false;
      defaultMethod = prefs.getString('defaultMethod');
      defaultChoice = prefs.getBool('defaultChoice') ?? false;
      
      // Load notification preferences
      emailNotifications = prefs.getBool('emailNotifications') ?? true;
      pushNotifications = prefs.getBool('pushNotifications') ?? true;
      textNotifications = prefs.getBool('textNotifications') ?? false;
      gameReminders = prefs.getBool('gameReminders') ?? true;
      scheduleUpdates = prefs.getBool('scheduleUpdates') ?? true;
      assignmentAlerts = prefs.getBool('assignmentAlerts') ?? true;
      emergencyNotifications = prefs.getBool('emergencyNotifications') ?? true;
      
      // Load privacy settings
      shareProfile = prefs.getBool('shareProfile') ?? true;
      showAvailability = prefs.getBool('showAvailability') ?? true;
      allowContactFromOfficials = prefs.getBool('allowContactFromOfficials') ?? true;
      
      // Load app preferences
      notificationSound = prefs.getString('notificationSound') ?? 'default';
      vibrationEnabled = prefs.getBool('vibrationEnabled') ?? true;
      dateFormat = prefs.getString('dateFormat') ?? 'MM/dd/yyyy';
      timeFormat = prefs.getString('timeFormat') ?? '12';
      autoRefresh = prefs.getBool('autoRefresh') ?? true;
      refreshInterval = prefs.getInt('refreshInterval') ?? 30;
      
      // Load user profile data from database
      final userId = await sessionService.getCurrentUserId();
      if (userId != null) {
        final userRepo = UserRepository();
        final user = await userRepo.getUserById(userId);
        if (user != null) {
          schedulerType = user.schedulerType;
        }
      }
    } catch (e) {
      debugPrint('Error loading settings: $e');
    }
    
    setState(() {
      isLoading = false;
    });
  }

  Future<void> _saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Save UI preferences to SharedPreferences
      await prefs.setBool('showAwayGames', showAwayGames);
      await prefs.setBool('showFullyCoveredGames', showFullyCoveredGames);
      await prefs.setBool('dont_ask_create_template', dontAskCreateTemplate);
      await prefs.setBool('default_dark_mode', defaultDarkMode);
      await prefs.setBool('defaultChoice', defaultChoice);
      
      // Save notification preferences
      await prefs.setBool('emailNotifications', emailNotifications);
      await prefs.setBool('pushNotifications', pushNotifications);
      await prefs.setBool('textNotifications', textNotifications);
      await prefs.setBool('gameReminders', gameReminders);
      await prefs.setBool('scheduleUpdates', scheduleUpdates);
      await prefs.setBool('assignmentAlerts', assignmentAlerts);
      await prefs.setBool('emergencyNotifications', emergencyNotifications);
      
      // Save privacy settings
      await prefs.setBool('shareProfile', shareProfile);
      await prefs.setBool('showAvailability', showAvailability);
      await prefs.setBool('allowContactFromOfficials', allowContactFromOfficials);
      
      // Save app preferences
      await prefs.setString('notificationSound', notificationSound);
      await prefs.setBool('vibrationEnabled', vibrationEnabled);
      await prefs.setString('dateFormat', dateFormat);
      await prefs.setString('timeFormat', timeFormat);
      await prefs.setBool('autoRefresh', autoRefresh);
      await prefs.setInt('refreshInterval', refreshInterval);
      
      if (defaultChoice && defaultMethod != null && defaultMethod!.isNotEmpty) {
        await prefs.setString('defaultMethod', defaultMethod!);
      } else {
        await prefs.remove('defaultMethod');
      }
    } catch (e) {
      debugPrint('Error saving settings: $e');
    }
  }

  Widget _buildSettingSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: primaryTextColor,
            ),
          ),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: darkSurface,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildSwitchTile(
      String title, String subtitle, bool value, Function(bool) onChanged) {
    return SwitchListTile(
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(
          fontSize: 14,
          color: secondaryTextColor,
        ),
      ),
      value: value,
      onChanged: (newValue) {
        setState(() {
          onChanged(newValue);
        });
        _saveSettings();
      },
      activeColor: efficialsBlue,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: efficialsBlue)),
      );
    }

    return Scaffold(
      backgroundColor: darkBackground,
      appBar: AppBar(
        backgroundColor: efficialsBlack,
        title: const Text(
          'Settings',
          style: TextStyle(color: Colors.white),
        ),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: ListView(
          children: [
            const SizedBox(height: 16),

            // Display Settings
            _buildSettingSection(
              'Display',
              [
                _buildSwitchTile(
                  'Dark Mode',
                  'Use dark theme throughout the app',
                  defaultDarkMode,
                  (value) => defaultDarkMode = value,
                ),
              ],
            ),

            // Game View Settings
            if (schedulerType == 'Athletic Director' ||
                schedulerType == 'Coach')
              _buildSettingSection(
                'Game View',
                [
                  _buildSwitchTile(
                    'Show Away Games',
                    'Display games played at opponent venues',
                    showAwayGames,
                    (value) => showAwayGames = value,
                  ),
                  const Divider(height: 1),
                  _buildSwitchTile(
                    'Show Fully Covered Games',
                    'Display games that have all officials assigned',
                    showFullyCoveredGames,
                    (value) => showFullyCoveredGames = value,
                  ),
                ],
              ),

            // Template Settings
            if (schedulerType == 'Athletic Director' ||
                schedulerType == 'Assigner')
              _buildSettingSection(
                'Templates',
                [
                  _buildSwitchTile(
                    'Template Creation Prompt',
                    'Ask to create a template after creating a game',
                    !dontAskCreateTemplate,
                    (value) => dontAskCreateTemplate = !value,
                  ),
                ],
              ),

            // Officials Selection Settings
            if (schedulerType == 'Athletic Director' ||
                schedulerType == 'Assigner')
              _buildSettingSection(
                'Officials Selection',
                [
                  _buildSwitchTile(
                    'Remember Selection Method',
                    'Use the last selected method as default',
                    defaultChoice,
                    (value) => defaultChoice = value,
                  ),
                  if (defaultChoice) ...[
                    const Divider(height: 1),
                    ListTile(
                      title: const Text(
                        'Default Selection Method',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      subtitle: const Text(
                        'Choose your preferred method for selecting officials',
                        style: TextStyle(
                          fontSize: 14,
                          color: secondaryTextColor,
                        ),
                      ),
                      trailing: DropdownButton<String>(
                        value: defaultMethod,
                        items: const [
                          DropdownMenuItem(
                            value: 'standard',
                            child: Text('Manual Selection'),
                          ),
                          DropdownMenuItem(
                            value: 'advanced',
                            child: Text('Multiple Lists'),
                          ),
                          DropdownMenuItem(
                            value: 'use_list',
                            child: Text('Single List'),
                          ),
                          DropdownMenuItem(
                            value: 'hire_crew',
                            child: Text('Hire a Crew'),
                          ),
                        ],
                        onChanged: (value) {
                          setState(() {
                            defaultMethod = value;
                          });
                          _saveSettings();
                        },
                      ),
                    ),
                  ],
                ],
              ),

            // Developer Settings
            _buildSettingSection(
              'Developer',
              [
                ListTile(
                  leading: const Icon(Icons.bug_report),
                  title: const Text(
                    'Database Test',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  subtitle: const Text(
                    'Test database migration and functionality',
                    style: TextStyle(
                      fontSize: 14,
                      color: secondaryTextColor,
                    ),
                  ),
                  onTap: () {
                    Navigator.pushNamed(context, '/database_test');
                  },
                ),
              ],
            ),

            // Privacy Settings
            _buildSettingSection(
              'Privacy',
              [
                _buildSwitchTile(
                  'Share Profile',
                  'Allow other users to view your profile',
                  shareProfile,
                  (value) => shareProfile = value,
                ),
                const Divider(height: 1),
                _buildSwitchTile(
                  'Show Availability',
                  'Display your availability to schedulers',
                  showAvailability,
                  (value) => showAvailability = value,
                ),
                const Divider(height: 1),
                _buildSwitchTile(
                  'Allow Contact from Officials',
                  'Let other officials contact you directly',
                  allowContactFromOfficials,
                  (value) => allowContactFromOfficials = value,
                ),
              ],
            ),

            // App Preferences
            _buildSettingSection(
              'App Preferences',
              [
                ListTile(
                  title: const Text(
                    'Notification Sound',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  subtitle: const Text(
                    'Choose your notification sound',
                    style: TextStyle(
                      fontSize: 14,
                      color: secondaryTextColor,
                    ),
                  ),
                  trailing: DropdownButton<String>(
                    value: notificationSound,
                    items: const [
                      DropdownMenuItem(
                        value: 'default',
                        child: Text('Default'),
                      ),
                      DropdownMenuItem(
                        value: 'chime',
                        child: Text('Chime'),
                      ),
                      DropdownMenuItem(
                        value: 'bell',
                        child: Text('Bell'),
                      ),
                      DropdownMenuItem(
                        value: 'none',
                        child: Text('Silent'),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() {
                        notificationSound = value!;
                      });
                      _saveSettings();
                    },
                  ),
                ),
                const Divider(height: 1),
                _buildSwitchTile(
                  'Vibration',
                  'Enable vibration for notifications',
                  vibrationEnabled,
                  (value) => vibrationEnabled = value,
                ),
                const Divider(height: 1),
                _buildSwitchTile(
                  'Auto Refresh',
                  'Automatically refresh data in the background',
                  autoRefresh,
                  (value) => autoRefresh = value,
                ),
                if (autoRefresh) ...[
                  const Divider(height: 1),
                  ListTile(
                    title: const Text(
                      'Refresh Interval',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    subtitle: const Text(
                      'How often to refresh data (seconds)',
                      style: TextStyle(
                        fontSize: 14,
                        color: secondaryTextColor,
                      ),
                    ),
                    trailing: DropdownButton<int>(
                      value: refreshInterval,
                      items: const [
                        DropdownMenuItem(
                          value: 15,
                          child: Text('15s'),
                        ),
                        DropdownMenuItem(
                          value: 30,
                          child: Text('30s'),
                        ),
                        DropdownMenuItem(
                          value: 60,
                          child: Text('1m'),
                        ),
                        DropdownMenuItem(
                          value: 300,
                          child: Text('5m'),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() {
                          refreshInterval = value!;
                        });
                        _saveSettings();
                      },
                    ),
                  ),
                ],
              ],
            ),

            // Support Settings
            _buildSettingSection(
              'Support',
              [
                ListTile(
                  leading: const Icon(Icons.help_outline),
                  title: const Text(
                    'Help & FAQ',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  subtitle: const Text(
                    'Get help and view frequently asked questions',
                    style: TextStyle(
                      fontSize: 14,
                      color: secondaryTextColor,
                    ),
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    // TODO: Navigate to help screen
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.feedback_outlined),
                  title: const Text(
                    'Send Feedback',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  subtitle: const Text(
                    'Report issues or suggest improvements',
                    style: TextStyle(
                      fontSize: 14,
                      color: secondaryTextColor,
                    ),
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    // TODO: Navigate to feedback screen
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.info_outline),
                  title: const Text(
                    'About',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  subtitle: const Text(
                    'App version and legal information',
                    style: TextStyle(
                      fontSize: 14,
                      color: secondaryTextColor,
                    ),
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    // TODO: Navigate to about screen
                  },
                ),
              ],
            ),

            // Account Settings
            _buildSettingSection(
              'Account',
              [
                ListTile(
                  leading: const Icon(Icons.person_outline),
                  title: Text(
                    'Role: ${schedulerType ?? 'Unknown'}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.edit_outlined),
                  title: const Text(
                    'Edit Profile',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  subtitle: const Text(
                    'Update your personal information',
                    style: TextStyle(
                      fontSize: 14,
                      color: secondaryTextColor,
                    ),
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    // TODO: Navigate to profile edit screen
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.security_outlined),
                  title: const Text(
                    'Change Password',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  subtitle: const Text(
                    'Update your account password',
                    style: TextStyle(
                      fontSize: 14,
                      color: secondaryTextColor,
                    ),
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    // TODO: Navigate to change password screen
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.logout),
                  title: const Text(
                    'Sign Out',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.red,
                    ),
                  ),
                  onTap: () async {
                    try {
                      final sessionService = UserSessionService.instance;
                      await sessionService.clearSession();
                      
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.clear();
                      
                      if (mounted) {
                        // ignore: use_build_context_synchronously
                        Navigator.pushNamedAndRemoveUntil(
                          context,
                          '/welcome',
                          (route) => false,
                        );
                      }
                    } catch (e) {
                      debugPrint('Error during logout: $e');
                    }
                  },
                ),
              ],
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
