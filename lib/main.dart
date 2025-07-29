import 'package:flutter/material.dart';

// Database and services
import 'dart:io';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'shared/services/migration_service.dart';

// Auth screens
import 'features/auth/welcome_screen.dart';
import 'features/auth/role_selection_screen.dart';
import 'features/auth/scheduler_signup_step1.dart';
import 'features/auth/scheduler_signup_step2.dart';
import 'features/auth/official_signup_step1.dart';
import 'features/auth/official_signup_step2.dart';
import 'features/auth/official_signup_step3.dart';
import 'features/auth/official_signup_step4.dart';
import 'features/auth/add_photo_screen.dart';
import 'features/auth/athletic_director_setup_screen.dart';

// Home screens
import 'features/home/athletic_director_home_screen.dart';
import 'features/home/assigner_home_screen.dart';
import 'features/home/coach_home_screen.dart';
import 'features/home/official_home_screen.dart';
import 'features/home/assigner_sport_selection_screen.dart';
import 'features/home/settings_screen.dart';
import 'features/settings/assigner_sport_defaults_screen.dart';

// Officials screens
import 'features/officials/lists_of_officials_screen.dart';
import 'features/officials/create_new_list_screen.dart';
import 'features/officials/name_list_screen.dart';
import 'features/officials/populate_roster_screen.dart';
import 'features/officials/review_list_screen.dart';
import 'features/officials/filter_settings_screen.dart';
import 'features/officials/edit_list_screen.dart';
import 'features/officials/advanced_officials_selection_screen.dart';
import 'features/officials/select_officials_screen.dart';
import 'features/officials/official_game_details_screen.dart';
import 'features/officials/available_game_details_screen.dart';
import 'features/officials/official_profile_screen.dart';
import 'features/officials/official_notifications_screen.dart';

// Games screens
import 'features/games/additional_game_info_screen.dart';
import 'features/games/additional_game_info_condensed_screen.dart';
import 'features/games/date_time_screen.dart';
import 'features/games/review_game_info_screen.dart';
import 'features/games/edit_game_info_screen.dart';
import 'features/games/unpublished_games_screen.dart';
import 'features/games/game_information_screen.dart';
import 'features/games/game_templates_screen.dart';
import 'features/games/sport_templates_screen.dart';
import 'features/games/select_game_template_screen.dart';
import 'features/games/create_game_template_screen.dart';
import 'features/games/new_game_template_screen.dart';
import 'features/games/select_sport_screen.dart';
import 'features/games/select_team_screen.dart';

// Schedule screens
import 'features/schedules/name_schedule_screen.dart';
import 'features/schedules/select_schedule_screen.dart';
import 'features/schedules/schedules_screen.dart';
import 'features/schedules/schedule_details_screen.dart';
import 'features/schedules/team_schedule_screen.dart';
import 'features/schedules/assigner_manage_schedules_screen.dart';

// Location screens
import 'features/locations/locations_screen.dart';
import 'features/locations/add_new_location_screen.dart';
import 'features/locations/choose_location_screen.dart';
import 'features/locations/edit_location_screen.dart';

// Debug screens
import 'features/debug/database_test_screen.dart';

// Crew screens
import 'features/crews/select_crew_screen.dart';
import 'features/crews/filter_crews_screen.dart';

// Scheduler screens
import 'features/schedulers/backout_notifications_screen.dart';
import 'features/settings/notification_settings_screen.dart';

// Shared
import 'shared/theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize sqflite for desktop platforms
  if (Platform.isLinux || Platform.isWindows || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }
  
  // Initialize database and run migration
  try {
    await MigrationService().initializeDatabase();
  } catch (e) {
    // Continue without database - app should still work with SharedPreferences
  }
  
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
          iconTheme: IconThemeData(color: Colors.white),
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
        timePickerTheme: TimePickerThemeData(
          backgroundColor: Colors.white,
          hourMinuteColor: Colors.grey[200],
          hourMinuteTextColor: Colors.black,
          dialBackgroundColor: Colors.grey[300],
          dialHandColor: efficialsBlue,
          dialTextColor: Colors.black,
          entryModeIconColor: efficialsBlue,
          helpTextStyle: const TextStyle(
              color: efficialsBlue, fontWeight: FontWeight.bold),
          dayPeriodColor: Colors.grey[200],
          dayPeriodTextColor: efficialsBlue,
          dayPeriodBorderSide: const BorderSide(color: efficialsBlue),
          confirmButtonStyle: TextButton.styleFrom(
            foregroundColor: efficialsBlue,
          ),
          cancelButtonStyle: TextButton.styleFrom(
            foregroundColor: efficialsBlue,
          ),
        ),
      ),
      initialRoute: '/welcome',
      routes: {
        '/welcome': (context) => const WelcomeScreen(),
        '/role_selection': (context) => const RoleSelectionScreen(),
        '/scheduler_signup_step1': (context) => const SchedulerSignUpStep1(),
        '/scheduler_signup_step2': (context) => const SchedulerSignUpStep2(),
        '/official_signup_step1': (context) => const OfficialSignUpStep1(),
        '/official_signup_step2': (context) => const OfficialSignUpStep2(),
        '/official_signup_step3': (context) => const OfficialSignUpStep3(),
        '/official_signup_step4': (context) => const OfficialSignUpStep4(),
        '/add_photo': (context) => const AddPhotoScreen(),
        '/athletic_director_setup': (context) =>
            const AthleticDirectorSetupScreen(),
        '/athletic_director_home': (context) =>
            const AthleticDirectorHomeScreen(),
        '/assigner_home': (context) => const AssignerHomeScreen(),
        '/coach_home': (context) => const CoachHomeScreen(),
        '/official_home': (context) => const OfficialHomeScreen(),
        '/select_team': (context) => const SelectTeamScreen(),
        '/assigner_sport_selection': (context) =>
            const AssignerSportSelectionScreen(),
        '/assigner_manage_schedules': (context) =>
            const AssignerManageSchedulesScreen(),
        '/lists_of_officials': (context) => const ListsOfOfficialsScreen(),
        '/create_new_list': (context) => const CreateNewListScreen(),
        '/name_list': (context) => const NameListScreen(),
        '/populate_roster': (context) => const PopulateRosterScreen(),
        '/review_list': (context) => const ReviewListScreen(),
        '/filter_settings': (context) => const FilterSettingsScreen(),
        '/edit_list': (context) => const EditListScreen(),
        '/locations': (context) => const LocationsScreen(),
        '/add_new_location': (context) => const AddNewLocationScreen(),
        '/select_sport': (context) => const SelectSportScreen(),
        '/name_schedule': (context) => const NameScheduleScreen(),
        '/choose_location': (context) => const ChooseLocationScreen(),
        '/date_time': (context) => const DateTimeScreen(),
        '/additional_game_info': (context) => const AdditionalGameInfoScreen(),
        '/select_officials': (context) => const SelectOfficialsScreen(),
        '/review_game_info': (context) => const ReviewGameInfoScreen(),
        '/edit_game_info': (context) => const EditGameInfoScreen(),
        '/edit_location': (context) => const EditLocationScreen(),
        '/advanced_officials_selection': (context) =>
            const AdvancedOfficialsSelectionScreen(),
        '/unpublished_games': (context) => const UnpublishedGamesScreen(),
        '/game_information': (context) => const GameInformationScreen(),
        '/select_schedule': (context) => const SelectScheduleScreen(),
        '/schedules': (context) => const SchedulesScreen(),
        '/schedule_details': (context) => const ScheduleDetailsScreen(),
        '/team_schedule': (context) => const TeamScheduleScreen(),
        '/new_game_template': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
          return NewGameTemplateScreen(gameData: args);
        },
        '/game_templates': (context) => const GameTemplatesScreen(),
        '/sport_templates': (context) => const SportTemplatesScreen(),
        '/select_game_template': (context) => const SelectGameTemplateScreen(),
        '/create_game_template': (context) => const CreateGameTemplateScreen(),
        '/additional_game_info_condensed': (context) =>
            const AdditionalGameInfoCondensedScreen(),
        '/settings': (context) => const SettingsScreen(),
        '/assigner_sport_defaults': (context) => const AssignerSportDefaultsScreen(),
        '/database_test': (context) => const DatabaseTestScreen(),
        '/official_game_details': (context) => const OfficialGameDetailsScreen(),
        '/available_game_details': (context) => const AvailableGameDetailsScreen(),
        '/official_profile': (context) => const OfficialProfileScreen(),
        '/official_notifications': (context) => const OfficialNotificationsScreen(),
        '/select_crew': (context) => const SelectCrewScreen(),
        '/filter_crews_settings': (context) => const FilterCrewsScreen(),
        '/backout_notifications': (context) => const BackoutNotificationsScreen(),
        '/notification_settings': (context) => const NotificationSettingsScreen(),
      },
    );
  }
}// Test line-ending fix