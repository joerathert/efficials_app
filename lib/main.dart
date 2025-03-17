import 'package:flutter/material.dart';
import 'welcome_screen.dart'; // Import the Welcome Screen
import 'role_selection_screen.dart'; // Import the Role Selection Screen
import 'scheduler_signup_step1.dart'; // Import Scheduler Sign Up Step 1
import 'scheduler_signup_step2.dart'; // Import Scheduler Sign Up Step 2
import 'add_photo_screen.dart'; // Import Add Photo Screen
import 'home_screen.dart'; // Import the Home Screen
import 'lists_of_officials_screen.dart'; // Import ListsOfOfficialsScreen
import 'create_new_list_screen.dart'; // Import CreateNewListScreen
import 'name_list_screen.dart'; // Import NameListScreen
import 'populate_roster_screen.dart'; // Import PopulateRosterScreen
import 'review_list_screen.dart'; // Import ReviewListScreen
import 'filter_settings_screen.dart'; // Added: Import FilterSettingsScreen
import 'edit_list_screen.dart'; // Added: Import EditListScreen
import 'theme.dart'; // Import the custom theme

void main() {
  runApp(const EfficialsApp());
}

class EfficialsApp extends StatelessWidget {
  const EfficialsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Efficials',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        appBarTheme: const AppBarTheme(
          backgroundColor: efficialsBlue,
          titleTextStyle: appBarTextStyle,
          iconTheme: IconThemeData(color: Colors.white), // White back arrow
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: elevatedButtonStyle(),
        ),
        textTheme: const TextTheme(
          headlineLarge: headlineStyle,
          bodyMedium: secondaryTextStyle,
          labelLarge: buttonTextStyle,
          bodySmall: footerTextStyle,
        ),
        textSelectionTheme: const TextSelectionThemeData(
          cursorColor: efficialsBlue,
          selectionColor: Colors.blueAccent,
          selectionHandleColor: efficialsBlue,
        ),
      ),
      initialRoute: '/welcome',
      routes: {
        '/welcome': (context) => const WelcomeScreen(),
        '/role_selection': (context) => const RoleSelectionScreen(),
        '/scheduler_signup_step1': (context) => const SchedulerSignUpStep1(),
        '/scheduler_signup_step2': (context) => const SchedulerSignUpStep2(),
        '/add_photo': (context) => const AddPhotoScreen(),
        '/home': (context) => const HomeScreen(),
        '/lists_of_officials': (context) => const ListsOfOfficialsScreen(),
        '/create_new_list': (context) => const CreateNewListScreen(),
        '/name_list': (context) => const NameListScreen(),
        '/populate_roster': (context) => const PopulateRosterScreen(),
        '/review_list': (context) => const ReviewListScreen(),
        // Added: Routes for filter settings and edit list
        '/filter_settings': (context) => const FilterSettingsScreen(),
        '/edit_list': (context) => const EditListScreen(),
      },
    );
  }
}