import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

// Database and services
import 'dart:io' show Platform;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'shared/services/migration_service.dart';
import 'shared/services/repositories/official_repository.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

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
import 'features/home/officials_crews_choice_screen.dart';
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
import 'features/debug/create_officials_screen.dart';

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
import 'features/games/bulk_import_preflight_screen.dart';
import 'features/games/bulk_import_wizard_screen.dart';
import 'features/games/bulk_import_generate_screen.dart';
import 'features/games/bulk_import_upload_screen.dart';
import 'features/games/advanced_method_setup_screen.dart';

// Schedule screens
import 'features/schedules/dynamic_name_schedule_screen.dart';
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
import 'features/debug/update_addresses_screen.dart';
import 'features/debug/count_officials_test.dart';
import 'features/debug/official_stats_screen.dart';

// Crew screens
import 'features/crews/select_crew_screen.dart';
import 'features/crews/filter_crews_screen.dart';
import 'features/crews/crew_dashboard_screen.dart';
import 'features/crews/create_crew_screen.dart';
import 'features/crews/select_crew_members_screen.dart';
import 'features/crews/add_crew_members_screen.dart';
import 'features/crews/crew_invitations_screen.dart';
import 'features/crews/crew_details_screen.dart';
import 'features/crews/lists_of_crews_screen.dart';
import 'features/crews/create_new_crew_list_screen.dart';
import 'features/crews/edit_crew_list_screen.dart';
import 'features/crews/name_crew_list_screen.dart';

// Scheduler screens
import 'features/schedulers/backout_notifications_screen.dart';
import 'features/settings/notification_settings_screen.dart';

// Shared
import 'shared/theme.dart';
import 'shared/models/database_models.dart';

// Debug console
import 'features/debug/debug_console_screen.dart';

// Services
import 'shared/services/logging_service.dart';
import 'shared/services/user_flow_tracking_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Initialize unified data service and repositories
  print('DEBUG: Initializing unified data service...');
  final officialRepository = OfficialRepository();
  await officialRepository.initialize();
  print('DEBUG: Unified data service initialized successfully');

  // Initialize sqflite for desktop platforms (skip on web)
  if (!kIsWeb) {
    try {
      if (Platform.isLinux || Platform.isWindows || Platform.isMacOS) {
        print('DEBUG: Initializing sqflite for desktop platform...');
        sqfliteFfiInit();
        databaseFactory = databaseFactoryFfi;
        print('DEBUG: Database factory set successfully');
      }
    } catch (e) {
      print('Platform check failed: $e');
    }
  }

  // Initialize database and run migration (skip on web)
  if (!kIsWeb) {
    try {
      print('DEBUG: Starting database initialization...');
      await MigrationService().initializeDatabase();
      print('DEBUG: Database initialization completed successfully');
    } catch (e) {
      print('Database initialization failed: $e');
      // Continue without database - app should still work with SharedPreferences
    }
  }

  // Initialize debugging services
  try {
    final loggingService = LoggingService();
    await loggingService.initialize();
    
    final flowTracking = UserFlowTrackingService();
    await flowTracking.initialize();
  } catch (e) {
    print('Failed to initialize debugging services: $e');
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
        '/officials_crews_choice': (context) => const OfficialsCrewsChoiceScreen(),
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
        '/name_schedule': (context) => const DynamicNameScheduleScreen(),
        '/choose_location': (context) => const ChooseLocationScreen(),
        '/date_time': (context) => const DateTimeScreen(),
        '/additional_game_info': (context) => const AdditionalGameInfoScreen(),
        '/select_officials': (context) => const SelectOfficialsScreen(),
        '/review_game_info': (context) => const ReviewGameInfoScreen(),
        '/edit_game_info': (context) => const EditGameInfoScreen(),
        '/edit_location': (context) => const EditLocationScreen(),
        '/advanced_officials_selection': (context) =>
            const AdvancedOfficialsSelectionScreen(),
        '/advanced_method_setup': (context) => const AdvancedMethodSetupScreen(),
        '/create_officials': (context) => const CreateOfficialsScreen(),
        '/unpublished_games': (context) => const UnpublishedGamesScreen(),
        '/game_information': (context) => const GameInformationScreen(),
        '/select_schedule': (context) => const SelectScheduleScreen(),
        '/schedules': (context) => const SchedulesScreen(),
        '/schedule_details': (context) => const ScheduleDetailsScreen(),
        '/team_schedule': (context) => const TeamScheduleScreen(),
        '/new_game_template': (context) {
          final args = ModalRoute.of(context)!.settings.arguments
              as Map<String, dynamic>;
          return NewGameTemplateScreen(gameData: args);
        },
        '/game_templates': (context) => const GameTemplatesScreen(),
        '/sport_templates': (context) => const SportTemplatesScreen(),
        '/select_game_template': (context) => const SelectGameTemplateScreen(),
        '/create_game_template': (context) => const CreateGameTemplateScreen(),
        '/bulk_import_preflight': (context) => const BulkImportPreflightScreen(),
        '/bulk_import_wizard': (context) => const BulkImportWizardScreen(),
        '/bulk_import_generate': (context) => const BulkImportGenerateScreen(),
        '/bulk_import_upload': (context) => const BulkImportUploadScreen(),
        '/additional_game_info_condensed': (context) =>
            const AdditionalGameInfoCondensedScreen(),
        '/settings': (context) => const SettingsScreen(),
        '/assigner_sport_defaults': (context) =>
            const AssignerSportDefaultsScreen(),
        '/database_test': (context) => const DatabaseTestScreen(),
        '/update_addresses': (context) => const UpdateAddressesScreen(),
        '/count_officials_test': (context) => const CountOfficialsTest(),
        '/official_stats': (context) => const OfficialStatsScreen(),
        '/official_game_details': (context) =>
            const OfficialGameDetailsScreen(),
        '/available_game_details': (context) =>
            const AvailableGameDetailsScreen(),
        '/official_profile': (context) => const OfficialProfileScreen(),
        '/official_notifications': (context) =>
            const OfficialNotificationsScreen(),
        '/select_crew': (context) => const SelectCrewScreen(),
        '/filter_crews_settings': (context) => const FilterCrewsScreen(),
        '/crew_dashboard': (context) => const CrewDashboardScreen(),
        '/create_crew': (context) => const CreateCrewScreen(),
        '/lists_of_crews': (context) => const ListsOfCrewsScreen(),
        '/create_new_crew_list': (context) => const CreateNewCrewListScreen(),
        '/edit_crew_list': (context) => const EditCrewListScreen(),
        '/name_crew_list': (context) => const NameCrewListScreen(),
        '/select_crew_members': (context) {
          final args = ModalRoute.of(context)!.settings.arguments
              as Map<String, dynamic>;
          return SelectCrewMembersScreen(
            crewName: args['crewName'],
            crewType: args['crewType'],
            competitionLevels: args['competitionLevels'],
            currentUserId: args['currentUserId'],
          );
        },
        '/crew_invitations': (context) => const CrewInvitationsScreen(),
        '/crew_details': (context) {
          final crew = ModalRoute.of(context)!.settings.arguments as Crew;
          return CrewDetailsScreen(crew: crew);
        },
        '/add_crew_member': (context) {
          final crew = ModalRoute.of(context)!.settings.arguments as Crew;
          return AddCrewMembersScreen(crew: crew);
        },
        '/backout_notifications': (context) =>
            const BackoutNotificationsScreen(),
        '/notification_settings': (context) =>
            const NotificationSettingsScreen(),
        '/debug_console': (context) => const DebugConsoleScreen(),
      },
    );
  }
}// Test line-ending fix