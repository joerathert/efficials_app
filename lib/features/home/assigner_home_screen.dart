import 'package:flutter/material.dart';
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

class _AssignerHomeScreenState extends State<AssignerHomeScreen>
    with TickerProviderStateMixin {
  String? sport;
  String? leagueName;
  bool isLoading = true;
  int _currentIndex = 0;
  int _unreadNotificationCount = 0;
  
  // Animation controllers
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;
  bool _isExpanded = false;
  
  final NotificationRepository _notificationRepo = NotificationRepository();
  final UserRepository _userRepository = UserRepository();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _slideAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    _fadeAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    _initializeAssignerHome();
  }

  Future<void> _initializeAssignerHome() async {
    await Future.wait([
      _checkAssignerSetup(),
      _loadUnreadNotificationCount(),
    ]);
  }

  Future<void> _checkAssignerSetup() async {
    debugPrint('Checking assigner setup from database');
    try {
      // Get current user directly from UserRepository
      final currentUser = await _userRepository.getCurrentUser();
      
      if (currentUser == null) {
        debugPrint('No current user found, redirecting to welcome');
        if (mounted) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.pushReplacementNamed(context, '/welcome');
          });
        }
        return;
      }

      debugPrint('Current user: ${currentUser.email}, setupCompleted: ${currentUser.setupCompleted}');
      
      // Load sport and league from user record
      if (mounted) {
        setState(() {
          sport = currentUser.sport;
          leagueName = currentUser.leagueName ?? 'League';
          isLoading = false;
        });
      }

      // Redirect if setup not completed
      if (!currentUser.setupCompleted) {
        debugPrint('Setup not completed, redirecting to sport selection');
        if (mounted) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.pushReplacementNamed(context, '/assigner_sport_selection');
          });
        }
      }
    } catch (e) {
      debugPrint('Error checking assigner setup: $e');
      if (mounted) {
        setState(() {
          isLoading = false;
        });
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Navigator.pushReplacementNamed(context, '/welcome');
        });
      }
    }
  }

  Future<void> _loadUnreadNotificationCount() async {
    try {
      final currentUser = await _userRepository.getCurrentUser();
      if (currentUser != null) {
        final count = await _notificationRepo.getUnreadNotificationCount(currentUser.id!);
        if (mounted) {
          setState(() {
            _unreadNotificationCount = count;
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading unread notification count: $e');
    }
  }

  void _toggleExpandedView() {
    setState(() {
      _isExpanded = !_isExpanded;
    });
    if (_isExpanded) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }
  }

  void _navigateToFullScheduleView() {
    Navigator.pushNamed(context, '/assigner_manage_schedules');
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
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
      case 1: // Officials (Lists of Officials)
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
              leading: const Icon(Icons.schedule, color: efficialsYellow),
              title: const Text('Manage Schedules', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/assigner_manage_schedules');
              },
            ),
            ListTile(
              leading: const Icon(Icons.people, color: efficialsYellow),
              title: const Text('Manage Officials', style: TextStyle(color: Colors.white)),
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
        child: GestureDetector(
          onPanUpdate: (details) {
            // Detect upward swipe
            if (details.delta.dy < -2 && !_isExpanded) {
              _toggleExpandedView();
            }
            // Detect downward swipe when expanded
            else if (details.delta.dy > 2 && _isExpanded) {
              _toggleExpandedView();
            }
          },
          onTap: () {
            if (_isExpanded) {
              _navigateToFullScheduleView();
            }
          },
          child: AnimatedBuilder(
            animation: _slideAnimation,
            builder: (context, child) {
              return Stack(
                children: [
                  // Main home content
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: Transform.translate(
                      offset: Offset(0, -MediaQuery.of(context).size.height * 0.4 * _slideAnimation.value),
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // League Info Card
                            FadeTransition(
                              opacity: _fadeAnimation,
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: efficialsYellow,
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
                                          color: efficialsBlack,
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
                                                  color: efficialsBlack,
                                                ),
                                              ),
                                              Text(
                                                '${sport ?? 'Unknown'} Assigner',
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                  color: efficialsBlack,
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
                            ),
                            const SizedBox(height: 30),
              
                            // Quick Actions Section
                            FadeTransition(
                              opacity: _fadeAnimation,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Quick Actions',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
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
                                          icon: Icons.notifications,
                                          title: 'Notifications',
                                          onTap: () {
                                            Navigator.pushNamed(context, '/backout_notifications');
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  
                  // Overlay hint for expanded state
                  if (_isExpanded)
                    Positioned(
                      bottom: 50,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: efficialsYellow.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            'Tap to open full schedule view',
                            style: TextStyle(
                              color: efficialsBlack,
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
                
                if (mounted) {
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    '/welcome',
                    (route) => false,
                  ); // Go to welcome screen and clear navigation stack
                }
              },
              child: const Text('Logout', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }
}
