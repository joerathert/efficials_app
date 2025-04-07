import 'package:flutter/material.dart';
import 'welcome_screen.dart';
import 'role_selection_screen.dart';
import 'scheduler_signup_step1.dart';
import 'scheduler_signup_step2.dart';
import 'add_photo_screen.dart';
import 'home_screen.dart';
import 'lists_of_officials_screen.dart';
import 'create_new_list_screen.dart';
import 'name_list_screen.dart';
import 'populate_roster_screen.dart';
import 'review_list_screen.dart';
import 'filter_settings_screen.dart';
import 'edit_list_screen.dart';
import 'theme.dart';
import 'locations_screen.dart';
import 'add_new_location_screen.dart';
import 'select_sport_screen.dart';
import 'name_schedule_screen.dart';
import 'choose_location_screen.dart';
import 'date_time_screen.dart';
import 'additional_game_info_screen.dart';
import 'select_officials_screen.dart';
import 'review_game_info_screen.dart';
import 'edit_game_info_screen.dart';
import 'edit_location_screen.dart';
import 'advanced_officials_selection_screen.dart';
import 'unpublished_games_screen.dart';
import 'game_information_screen.dart';
import 'select_schedule_screen.dart';
import 'schedules_screen.dart';
import 'schedule_details_screen.dart';
import 'new_game_template_screen.dart';
import 'game_templates_screen.dart';
import 'sport_templates_screen.dart';
import 'select_game_template_screen.dart';
import 'create_game_template_screen.dart';

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
        '/advanced_officials_selection': (context) => const AdvancedOfficialsSelectionScreen(),
        '/unpublished_games': (context) => const UnpublishedGamesScreen(),
        '/game_information': (context) => const GameInformationScreen(),
        '/select_schedule': (context) => const SelectScheduleScreen(),
        '/schedules': (context) => const SchedulesScreen(),
        '/schedule_details': (context) => const ScheduleDetailsScreen(),
        '/new_game_template': (context) => CreateGameTemplateScreen(), // Updated to use CreateGameTemplateScreen
        '/game_templates': (context) => const GameTemplatesScreen(),
        '/sport_templates': (context) => const SportTemplatesScreen(),
        '/select_game_template': (context) => const SelectGameTemplateScreen(),
        '/create_game_template': (context) => const CreateGameTemplateScreen(),
      },
    );
  }
}