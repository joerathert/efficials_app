import 'package:flutter/material.dart';
import '../../shared/theme.dart';
import '../../shared/services/user_session_service.dart';
import '../../shared/services/repositories/notification_repository.dart';
import '../../shared/models/database_models.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  final NotificationRepository _notificationRepo = NotificationRepository();
  bool _isLoading = true;
  bool _isSaving = false;
  int? _currentUserId;
  
  // Settings state
  bool _backoutNotificationsEnabled = true;
  bool _gameFillingNotificationsEnabled = true;
  bool _officialInterestNotificationsEnabled = false;
  bool _officialClaimNotificationsEnabled = false;
  List<int> _gameFillingReminderDays = [3, 1];

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final userSession = UserSessionService.instance;
      _currentUserId = await userSession.getCurrentUserId();
      
      if (_currentUserId != null) {
        // Initialize settings if they don't exist
        await _notificationRepo.initializeUserNotificationSettings(_currentUserId!);
        
        // Load existing settings
        final settings = await _notificationRepo.getNotificationSettings(_currentUserId!);
        
        if (settings != null && mounted) {
          setState(() {
            _backoutNotificationsEnabled = settings.backoutNotificationsEnabled;
            _gameFillingNotificationsEnabled = settings.gameFillingNotificationsEnabled;
            _officialInterestNotificationsEnabled = settings.officialInterestNotificationsEnabled;
            _officialClaimNotificationsEnabled = settings.officialClaimNotificationsEnabled;
            _gameFillingReminderDays = settings.gameFillingReminderDays;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      print('Error loading notification settings: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to load notification settings'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _saveSettings() async {
    if (_currentUserId == null) return;

    try {
      setState(() {
        _isSaving = true;
      });

      final settings = NotificationSettings(
        userId: _currentUserId!,
        backoutNotificationsEnabled: _backoutNotificationsEnabled,
        gameFillingNotificationsEnabled: _gameFillingNotificationsEnabled,
        officialInterestNotificationsEnabled: _officialInterestNotificationsEnabled,
        officialClaimNotificationsEnabled: _officialClaimNotificationsEnabled,
        gameFillingReminderDays: _gameFillingReminderDays,
      );

      await _notificationRepo.saveNotificationSettings(settings);

      if (mounted) {
        setState(() {
          _isSaving = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Settings saved successfully'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('Error saving notification settings: $e');
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to save settings. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: darkBackground,
      appBar: AppBar(
        backgroundColor: efficialsBlack,
        title: const Text(
          'Notification Settings',
          style: TextStyle(color: efficialsWhite),
        ),
        iconTheme: const IconThemeData(color: efficialsWhite),
        elevation: 0,
        actions: [
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: efficialsYellow,
                  strokeWidth: 2,
                ),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.save, color: efficialsYellow),
              onPressed: _saveSettings,
              tooltip: 'Save Settings',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: efficialsYellow),
                  SizedBox(height: 16),
                  Text(
                    'Loading settings...',
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader('Notification Types'),
                  const SizedBox(height: 16),
                  
                  // Backout Notifications
                  _buildSettingCard(
                    icon: Icons.person_remove,
                    iconColor: Colors.red,
                    title: 'Official Backout Notifications',
                    subtitle: 'Get notified when officials back out of games',
                    value: _backoutNotificationsEnabled,
                    onChanged: (value) {
                      setState(() {
                        _backoutNotificationsEnabled = value;
                      });
                    },
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Game Filling Notifications
                  _buildSettingCard(
                    icon: Icons.group_add,
                    iconColor: Colors.orange,
                    title: 'Game Filling Reminders',
                    subtitle: 'Get reminded when games still need officials',
                    value: _gameFillingNotificationsEnabled,
                    onChanged: (value) {
                      setState(() {
                        _gameFillingNotificationsEnabled = value;
                      });
                    },
                  ),
                  
                  if (_gameFillingNotificationsEnabled) ...[
                    const SizedBox(height: 8),
                    _buildReminderDaysSection(),
                  ],
                  
                  const SizedBox(height: 12),
                  
                  // Official Interest Notifications
                  _buildSettingCard(
                    icon: Icons.thumb_up,
                    iconColor: Colors.blue,
                    title: 'Official Interest Notifications',
                    subtitle: 'Get notified when officials express interest in games',
                    value: _officialInterestNotificationsEnabled,
                    onChanged: (value) {
                      setState(() {
                        _officialInterestNotificationsEnabled = value;
                      });
                    },
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Official Claim Notifications
                  _buildSettingCard(
                    icon: Icons.assignment_ind,
                    iconColor: Colors.green,
                    title: 'Official Claim Notifications',
                    subtitle: 'Get notified when officials request/claim games',
                    value: _officialClaimNotificationsEnabled,
                    onChanged: (value) {
                      setState(() {
                        _officialClaimNotificationsEnabled = value;
                      });
                    },
                  ),
                  
                  const SizedBox(height: 32),
                  
                  _buildInfoSection(),
                  
                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: efficialsYellow,
      ),
    );
  }

  Widget _buildSettingCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: darkSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: value ? iconColor.withOpacity(0.3) : Colors.grey.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                icon,
                color: iconColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[400],
                    ),
                  ),
                ],
              ),
            ),
            Switch(
              value: value,
              onChanged: onChanged,
              activeColor: iconColor,
              activeTrackColor: iconColor.withOpacity(0.3),
              inactiveThumbColor: Colors.grey[600],
              inactiveTrackColor: Colors.grey[800],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReminderDaysSection() {
    return Container(
      margin: const EdgeInsets.only(left: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Reminder Schedule',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey[300],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Send reminders this many days before the game:',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[400],
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (int day in [28, 21, 14, 7, 3, 2, 1])
                _buildDayChip(day),
            ],
          ),
        ],
      ),
    );
  }

  String _getDayLabel(int day) {
    switch (day) {
      case 28:
        return '4 weeks';
      case 21:
        return '3 weeks';
      case 14:
        return '2 weeks';
      case 7:
        return '1 week';
      case 1:
        return '1 day';
      default:
        return '$day days';
    }
  }

  Widget _buildDayChip(int day) {
    final isSelected = _gameFillingReminderDays.contains(day);
    return GestureDetector(
      onTap: () {
        setState(() {
          if (isSelected) {
            _gameFillingReminderDays.remove(day);
          } else {
            _gameFillingReminderDays.add(day);
            _gameFillingReminderDays.sort((a, b) => b.compareTo(a)); // Sort descending
          }
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? Colors.orange : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? Colors.orange : Colors.grey[600]!,
          ),
        ),
        child: Text(
          _getDayLabel(day),
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: isSelected ? Colors.white : Colors.grey[400],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: efficialsYellow.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: efficialsYellow.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline,
                color: efficialsYellow,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'About Notifications',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: efficialsYellow,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '• Settings are saved automatically when you make changes\n'
            '• Game filling reminders will only be sent for games that still need officials\n'
            '• You can select multiple reminder days to get notifications at different intervals\n'
            '• All notifications appear in your notification screen and as badge counts',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[300],
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}