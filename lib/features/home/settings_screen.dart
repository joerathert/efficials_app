import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../shared/theme.dart';

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

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      schedulerType = prefs.getString('schedulerType');
      showAwayGames = prefs.getBool('showAwayGames') ?? true;
      showFullyCoveredGames = prefs.getBool('showFullyCoveredGames') ?? true;
      dontAskCreateTemplate =
          prefs.getBool('dont_ask_create_template') ?? false;
      defaultDarkMode = prefs.getBool('default_dark_mode') ?? false;
      defaultMethod = prefs.getString('defaultMethod');
      defaultChoice = prefs.getBool('defaultChoice') ?? false;
      isLoading = false;
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('showAwayGames', showAwayGames);
    await prefs.setBool('showFullyCoveredGames', showFullyCoveredGames);
    await prefs.setBool('dont_ask_create_template', dontAskCreateTemplate);
    await prefs.setBool('default_dark_mode', defaultDarkMode);
    await prefs.setBool('defaultChoice', defaultChoice);
    if (defaultChoice) {
      await prefs.setString('defaultMethod', defaultMethod ?? '');
    } else {
      await prefs.remove('defaultMethod');
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
                            value: 'use_list',
                            child: Text('Use List'),
                          ),
                          DropdownMenuItem(
                            value: 'manual',
                            child: Text('Manual Selection'),
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
