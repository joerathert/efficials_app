# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Development Commands

### Core Flutter Commands
- **Run app**: `flutter run` (debug mode), `flutter run --release` (release mode)
- **Build**: `flutter build apk` (Android), `flutter build ios` (iOS), `flutter build web` (web)
- **Test**: `flutter test` (all tests), `flutter test test/widget_test.dart` (specific test)
- **Analyze**: `flutter analyze` (static analysis), `dart format .` (code formatting)
- **Dependencies**: `flutter pub get` (install), `flutter pub upgrade` (update)
- **Clean**: `flutter clean` (clean build artifacts)

### Android-specific
- **Build APK**: `cd android && ./gradlew assembleDebug` or `./gradlew assembleRelease`
- **Clean Android**: `cd android && ./gradlew clean`

## Architecture Overview

This is a Flutter mobile application for sports officials management called "Efficials". The app supports multiple user roles and workflows.

### Core Structure
- **Entry point**: `lib/main.dart` - Contains app configuration, theming, and route definitions
- **Navigation**: Route-based navigation with 30+ screens defined in main.dart routes
- **Theming**: Centralized theme configuration in `lib/theme.dart` with consistent styling
- **Utilities**: Basic sport icon mapping in `lib/utils.dart`

### User Roles & Workflows
The app supports three main user roles with distinct navigation flows:
1. **Athletic Director** → `athletic_director_home_screen.dart`
2. **Assigner** → `assigner_home_screen.dart` 
3. **Coach** → `coach_home_screen.dart`

### Key Feature Areas
- **User Management**: Welcome, role selection, scheduler signup (step 1-2), photo upload
- **Officials Management**: Lists, roster population, filtering, advanced selection
- **Location Management**: Location selection, creation, and editing
- **Game Management**: Game templates, scheduling, info entry, review workflows
- **Schedule Management**: Schedule creation, selection, filtering, and details

### State Management
- Uses standard Flutter StatefulWidget pattern
- Local data persistence via `shared_preferences` package
- HTTP requests handled through `http` package

### Dependencies
Key packages include:
- `table_calendar: ^3.0.0` - Calendar functionality
- `http: ^1.2.1` - Network requests
- `shared_preferences: ^2.2.3` - Local storage
- `intl: ^0.18.0` - Internationalization
- `flutter_lints: ^2.0.0` - Code analysis

### Screen Organization
All screens are individual Dart files in the lib/ directory following the pattern `[feature_name]_screen.dart`. The app uses a flat file structure without subdirectories.

### Testing
- Widget tests are located in `test/widget_test.dart`
- Uses standard Flutter testing framework
- Run tests with `flutter test`

### Code Style
- Uses `flutter_lints` package for consistent code analysis
- Configuration in `analysis_options.yaml`
- Follow Dart/Flutter naming conventions
- Format code with `dart format .`