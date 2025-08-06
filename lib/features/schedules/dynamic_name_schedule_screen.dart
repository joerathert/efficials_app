import 'package:flutter/material.dart';
import '../../shared/services/repositories/user_repository.dart';
import 'ad_name_schedule_screen.dart';
import 'assigner_name_schedule_screen.dart';

class DynamicNameScheduleScreen extends StatelessWidget {
  const DynamicNameScheduleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Widget>(
      future: _determineScreen(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Color(0xFF1A1A1A),
            body: Center(
              child: CircularProgressIndicator(color: Color(0xFFF5D920)),
            ),
          );
        }
        
        if (snapshot.hasError) {
          debugPrint('Error determining screen: ${snapshot.error}');
          // Default to AD screen on error
          return const ADNameScheduleScreen();
        }
        
        return snapshot.data ?? const ADNameScheduleScreen();
      },
    );
  }

  Future<Widget> _determineScreen() async {
    try {
      final userRepository = UserRepository();
      final currentUser = await userRepository.getCurrentUser();
      
      debugPrint('Current user scheduler type: ${currentUser?.schedulerType}');
      
      if (currentUser != null && currentUser.schedulerType.toLowerCase() == 'assigner') {
        debugPrint('Returning AssignerNameScheduleScreen');
        return const AssignerNameScheduleScreen();
      } else {
        debugPrint('Returning ADNameScheduleScreen (schedulerType: ${currentUser?.schedulerType})');
        return const ADNameScheduleScreen();
      }
    } catch (e) {
      debugPrint('Error determining screen type: $e');
      // Default to AD screen if there's an error
      return const ADNameScheduleScreen();
    }
  }
}