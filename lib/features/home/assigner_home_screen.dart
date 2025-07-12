import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../shared/theme.dart';
import '../../shared/utils/utils.dart';

class AssignerHomeScreen extends StatefulWidget {
  const AssignerHomeScreen({super.key});

  @override
  State<AssignerHomeScreen> createState() => _AssignerHomeScreenState();
}

class _AssignerHomeScreenState extends State<AssignerHomeScreen> {
  String? sport;
  String? leagueName;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkAssignerSetup();
  }

  Future<void> _checkAssignerSetup() async {
    final prefs = await SharedPreferences.getInstance();
    final setupCompleted = prefs.getBool('assigner_setup_completed') ?? false;
    final savedSport = prefs.getString('assigner_sport');
    final savedLeagueName = prefs.getString('league_name');

    setState(() {
      sport = savedSport;
      leagueName = savedLeagueName ?? 'League';
      isLoading = false;
    });

    if (!setupCompleted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacementNamed(context, '/assigner_sport_selection');
      });
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
              title: const Text('Settings', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/settings');
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
                      icon: Icons.analytics,
                      title: 'Reports',
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Reports not implemented yet')),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
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
}
