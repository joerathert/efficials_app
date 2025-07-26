import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../shared/theme.dart';
import '../../shared/utils/utils.dart';
import '../../shared/services/user_session_service.dart';
import '../../shared/services/repositories/user_repository.dart';
import '../../shared/services/repositories/notification_repository.dart';
import '../../shared/widgets/scheduler_bottom_navigation.dart';

class AssignerHomeScreen extends StatefulWidget {
  const AssignerHomeScreen({super.key});

  @override
  State<AssignerHomeScreen> createState() => _AssignerHomeScreenState();
}

class _AssignerHomeScreenState extends State<AssignerHomeScreen> {
  String? sport;
  String? leagueName;
  bool isLoading = true;
  int _currentIndex = 0;
  int _unreadNotificationCount = 0;
  final NotificationRepository _notificationRepo = NotificationRepository();

  @override
  void initState() {
    super.initState();
    _checkAssignerSetup();
    _loadUnreadNotificationCount();
  }

  Future<void> _checkAssignerSetup() async {
    try {
      // Get current user from database instead of SharedPreferences
      final currentUser = await UserSessionService.instance.getCurrentSchedulerUser();
      
      if (currentUser == null) {
        // No user logged in, redirect to login
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Navigator.pushReplacementNamed(context, '/welcome');
        });
        return;
      }

      // Check if user setup is completed in database
      final setupCompleted = currentUser.setupCompleted;

      setState(() {
        sport = currentUser.sport;
        leagueName = currentUser.leagueName ?? 'League';
        isLoading = false;
      });

      if (!setupCompleted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Navigator.pushReplacementNamed(context, '/assigner_sport_selection');
        });
      }
    } catch (e) {
      // Handle error
      setState(() {
        isLoading = false;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacementNamed(context, '/welcome');
      });
    }
  }

  Future<void> _loadUnreadNotificationCount() async {
    try {
      final currentUser = await UserSessionService.instance.getCurrentSchedulerUser();
      if (currentUser != null) {
        final count = await _notificationRepo.getUnreadNotificationCount(currentUser.id!);
        if (mounted) {
          setState(() {
            _unreadNotificationCount = count;
          });
        }
      }
    } catch (e) {
      // Handle error silently, badge will show 0
      print('Error loading unread notification count: $e');
    }
  }

  void _onBottomNavTap(int index) {
    if (index == _currentIndex) return;

    setState(() {
      _currentIndex = index;
    });

    switch (index) {
      case 0: // Schedules
        Navigator.pushNamed(context, '/assigner_manage_schedules');
        // Reset to home after navigation
        setState(() {
          _currentIndex = 0;
        });
        break;
      case 1: // Teams (Lists of Officials)
        Navigator.pushNamed(context, '/lists_of_officials');
        // Reset to home after navigation
        setState(() {
          _currentIndex = 0;
        });
        break;
      case 2: // Templates (Game Templates)
        Navigator.pushNamed(context, '/game_templates');
        // Reset to home after navigation
        setState(() {
          _currentIndex = 0;
        });
        break;
      case 3: // Notifications
        Navigator.pushNamed(context, '/backout_notifications').then((_) {
          // Refresh notification count when returning from notifications screen
          _loadUnreadNotificationCount();
        });
        // Reset to home after navigation
        setState(() {
          _currentIndex = 0;
        });
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        backgroundColor: darkBackground,
        body: Center(child: CircularProgressIndicator(color: efficialsYellow)),
      );
    }

    final double statusBarHeight = MediaQuery.of(context).padding.top;
    const double appBarHeight = kToolbarHeight;
    final double totalBannerHeight = statusBarHeight + appBarHeight;

    return Scaffold(
      backgroundColor: darkBackground,
      appBar: AppBar(
        backgroundColor: efficialsBlack,
        title: const Text('', style: appBarTextStyle),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, color: efficialsYellow),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
      ),
      drawer: Drawer(
        backgroundColor: Colors.grey[800],
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            Container(
              height: totalBannerHeight,
              decoration: const BoxDecoration(color: efficialsBlue),
              child: Padding(
                padding: EdgeInsets.only(
                  top: statusBarHeight + 8.0,
                  bottom: 8.0,
                  left: 16.0,
                  right: 16.0,
                ),
                child: const Text(
                  'Menu',
                  style: TextStyle(
                      color: darkSurface,
                      fontSize: 20,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.sports, color: efficialsYellow),
              title: const Text('Officials Assignment', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content:
                          Text('Officials Assignment not implemented yet')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.people, color: efficialsYellow),
              title: const Text('Officials Lists', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/lists_of_officials');
              },
            ),
            ListTile(
              leading: const Icon(Icons.copy, color: efficialsYellow),
              title: const Text('Game Templates', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/game_templates');
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings, color: efficialsYellow),
              title: const Text('Game Defaults', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/assigner_sport_defaults');
              },
            ),
            const Divider(color: Colors.grey),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Logout',
                  style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _handleLogout();
              },
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // League Info Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          getSportIcon(sport ?? ''),
                          color: getSportIconColor(sport ?? ''),
                          size: 32,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                leagueName ?? 'League',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: primaryTextColor,
                                ),
                              ),
                              Text(
                                '${sport ?? 'Unknown'} Assigner',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: secondaryTextColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              const Text(
                'Quick Actions',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              // Quick Action Cards
              Row(
                children: [
                  Expanded(
                    child: _buildActionCard(
                      icon: Icons.calendar_today,
                      title: 'Manage Schedules',
                      onTap: () {
                        Navigator.pushNamed(
                            context, '/assigner_manage_schedules');
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildActionCard(
                      icon: Icons.people,
                      title: 'Manage Officials',
                      onTap: () {
                        Navigator.pushNamed(context, '/lists_of_officials');
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildActionCard(
                      icon: Icons.copy,
                      title: 'Game Templates',
                      onTap: () {
                        Navigator.pushNamed(context, '/game_templates');
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildActionCard(
                      icon: Icons.settings,
                      title: 'Game Defaults',
                      onTap: () {
                        Navigator.pushNamed(context, '/assigner_sport_defaults');
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SchedulerBottomNavigation(
        currentIndex: _currentIndex,
        onTap: _onBottomNavTap,
        schedulerType: SchedulerType.assigner,
        unreadNotificationCount: _unreadNotificationCount,
      ),
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              icon,
              color: efficialsYellow,
              size: 28,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: primaryTextColor,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 12,
                  color: secondaryTextColor,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _handleLogout() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: darkSurface,
          title: const Text(
            'Logout',
            style: TextStyle(color: primaryTextColor),
          ),
          content: const Text(
            'Are you sure you want to logout?',
            style: TextStyle(color: primaryTextColor),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: secondaryTextColor)),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context); // Close dialog
                
                // Clear user session
                await UserSessionService.instance.clearSession();
                
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/welcome',
                  (route) => false,
                ); // Go to welcome screen and clear navigation stack
              },
              child: const Text('Logout', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }
}
