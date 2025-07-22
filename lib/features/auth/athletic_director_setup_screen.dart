import 'package:flutter/material.dart';
import '../../shared/theme.dart';
import '../../shared/services/repositories/user_repository.dart';
import '../../shared/services/user_session_service.dart';
import '../../shared/models/database_models.dart';

class AthleticDirectorSetupScreen extends StatefulWidget {
  const AthleticDirectorSetupScreen({super.key});

  @override
  State<AthleticDirectorSetupScreen> createState() =>
      _AthleticDirectorSetupScreenState();
}

class _AthleticDirectorSetupScreenState
    extends State<AthleticDirectorSetupScreen> {
  final TextEditingController _schoolNameController = TextEditingController();
  final TextEditingController _mascotController = TextEditingController();

  void _handleContinue() async {
    // Use default values if fields are empty to allow quick testing
    final schoolName = _schoolNameController.text.trim().isEmpty
        ? 'Edwardsville'
        : _schoolNameController.text.trim();
    final mascot = _mascotController.text.trim().isEmpty
        ? 'Tigers'
        : _mascotController.text.trim();

    try {
      // Get current user from session
      final userSession = UserSessionService.instance;
      final userId = await userSession.getCurrentUserId();
      
      if (userId != null) {
        // Update user in database with school information
        final userRepo = UserRepository();
        final currentUser = await userRepo.getUserById(userId);
        
        if (currentUser != null) {
          // Create updated user with school info
          final updatedUser = User(
            id: currentUser.id,
            schedulerType: currentUser.schedulerType,
            setupCompleted: true,
            schoolName: schoolName,
            mascot: mascot,
            teamName: currentUser.teamName,
            sport: currentUser.sport,
            grade: currentUser.grade,
            gender: currentUser.gender,
            leagueName: currentUser.leagueName,
            userType: currentUser.userType,
            email: currentUser.email,
            passwordHash: currentUser.passwordHash,
            firstName: currentUser.firstName,
            lastName: currentUser.lastName,
            phone: currentUser.phone,
            createdAt: currentUser.createdAt,
          );
          
          await userRepo.updateUser(updatedUser);
        }
      }

      // Navigate to Athletic Director Home
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/athletic_director_home');
      }
    } catch (e) {
      // Handle error
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving school information: $e'),
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
        title: const Icon(
          Icons.sports,
          color: efficialsYellow,
          size: 32,
        ),
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading:
            false, // Remove back button since this is required setup
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 40),
                const Text(
                  'School Information',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: efficialsYellow,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  'This information will be displayed to Officials when you create games',
                  style: TextStyle(
                    fontSize: 16,
                    color: secondaryTextColor,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),
                Container(
                  padding: const EdgeInsets.all(24),
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'School/City Name',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: primaryTextColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Enter your school name (e.g., "St. Mary\'s") or city name (e.g., "Edwardsville")',
                        style: TextStyle(
                          fontSize: 12,
                          color: secondaryTextColor,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _schoolNameController,
                        decoration:
                            textFieldDecoration('e.g., Edwardsville or St. Mary\'s'),
                        textCapitalization: TextCapitalization.words,
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'School Mascot',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: primaryTextColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _mascotController,
                        decoration:
                            textFieldDecoration('Enter your school mascot'),
                        textCapitalization: TextCapitalization.words,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
                ElevatedButton(
                  onPressed: _handleContinue,
                  style: elevatedButtonStyle(
                    padding: const EdgeInsets.symmetric(
                        vertical: 15, horizontal: 50),
                  ),
                  child: const Text('Continue', style: signInButtonTextStyle),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _schoolNameController.dispose();
    _mascotController.dispose();
    super.dispose();
  }
}
