import 'package:flutter/material.dart';
import '../../shared/theme.dart';
import '../../shared/services/user_session_service.dart';

class OfficialsCrewsChoiceScreen extends StatefulWidget {
  const OfficialsCrewsChoiceScreen({super.key});

  @override
  State<OfficialsCrewsChoiceScreen> createState() => _OfficialsCrewsChoiceScreenState();
}

class _OfficialsCrewsChoiceScreenState extends State<OfficialsCrewsChoiceScreen> {
  String? userSport;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserSport();
  }

  Future<void> _loadUserSport() async {
    try {
      final userInfo = await UserSessionService.instance.getCurrentUserInfo();
      if (mounted) {
        setState(() {
          userSport = userInfo?['sport'] as String?;
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          userSport = null;
          isLoading = false;
        });
      }
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
    return Scaffold(
      backgroundColor: darkBackground,
      appBar: AppBar(
        backgroundColor: efficialsBlack,
        title: const Text('Manage', style: appBarTextStyle),
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
                'What would you like to manage?',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: primaryTextColor,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Choose between managing lists of officials or lists of crews',
                style: TextStyle(
                  fontSize: 16,
                  color: secondaryTextColor,
                ),
              ),
              const SizedBox(height: 40),
              Expanded(
                child: Column(
                  children: [
                    // Lists of Officials Option
                    GestureDetector(
                      onTap: () {
                        Navigator.pushNamed(context, '/lists_of_officials');
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: darkSurface,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              spreadRadius: 1,
                              blurRadius: 6,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: efficialsYellow.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(50),
                              ),
                              child: const Icon(
                                Icons.people,
                                color: efficialsYellow,
                                size: 48,
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Lists of Officials',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: primaryTextColor,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Create and manage your saved lists of officials for easy game assignment',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14,
                                color: secondaryTextColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Lists of Crews Option
                    GestureDetector(
                      onTap: () {
                        Navigator.pushNamed(
                          context, 
                          '/lists_of_crews',
                          arguments: {
                            'sport': userSport ?? 'Football',
                          },
                        );
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: darkSurface,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              spreadRadius: 1,
                              blurRadius: 6,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: efficialsBlue.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(50),
                              ),
                              child: const Icon(
                                Icons.group,
                                color: efficialsBlue,
                                size: 48,
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Lists of Crews',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: primaryTextColor,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Create and manage your saved lists of crews for streamlined officiating',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14,
                                color: secondaryTextColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}