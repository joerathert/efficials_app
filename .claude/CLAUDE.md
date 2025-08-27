# CLAUDE.md

This file provides guidance for Claude Code (claude.ai/code) when working with the **Efficials** Flutter project, integrated with a customized SuperClaude configuration. It defines development commands, project architecture, SuperClaude commands/personas, and rules to ensure consistent, efficient development.

## Project Overview

**Efficials** is a Flutter app for sports officials management, connecting:
- **Schedulers** (Athletic Directors, Assigners, Coaches): Create/manage game assignments, locations, and schedules (30+ screens, substantially complete).
- **Officials**: View/accept game assignments, manage schedules, and communicate (not yet implemented).

The app supports Android, iOS, web, Linux, macOS, and Windows, using a feature-based structure with 50 screens across 6 areas: `auth`, `games`, `home`, `locations`, `officials` (Scheduler tools), and `schedules`.

## Rules

- **State Management**: Use `setState` with `StatefulWidget` for consistency unless specified otherwise.
- **Navigation**: Add new routes to `lib/main.dart` routes map using `Navigator.pushNamed`.
- **File Contents**: Do not assume file contents; explicitly request files (e.g., `lib/main.dart`) before referencing or modifying.
- **API**: No API integration exists; design endpoints from scratch for Officials features.
- **Testing**: Prioritize implementation over testing for new features; add tests later for critical flows (e.g., login, assignment acceptance).
- **Code Style**: Follow `flutter_lints` and `analysis_options.yaml`. Run `dart format .` before commits.
- **SuperClaude**: Use evidence-based suggestions (`--evidence`) and minimal explanations (`--uc` for UltraCompressed mode).

## Development Commands

### Flutter Basics
- **Run**: `flutter run` (debug), `flutter run --release` (release)
- **Build**: `flutter build apk` (Android), `flutter build ios` (iOS), `flutter build web` (web)
- **Test**: `flutter test` (all), `flutter test test/widget_test.dart` (specific)
- **Analyze**: `flutter analyze` (static analysis), `dart format .` (formatting)
- **Dependencies**: `flutter pub get` (install), `flutter pub upgrade` (update)
- **Clean**: `flutter clean` (build artifacts)

### Android-Specific
- **Build APK**: `cd android && ./gradlew assembleDebug` or `./gradlew assembleRelease`
- **Clean**: `cd android && ./gradlew clean`

### SuperClaude Commands
- `/build --feature --persona-flutter_frontend`: Implement new screens/widgets (e.g., Officials dashboard).
- `/design --api --persona-flutter_api`: Design API endpoints/models for Officials features.
- `/test --tdd --persona-qa`: Write widget/integration tests for critical flows.
- `/review --code --persona-refactorer`: Review code for `flutter_lints` compliance and optimizations.
- `/document --persona-qa`: Generate documentation for new screens/models.
- `/debug --persona-analyzer --seq`: Debug issues with sequential reasoning.
- `/optimize --performance --persona-performance`: Optimize widgets or queries.

### Custom Personas
- `flutter_frontend`: Focus on Flutter UI/screens (e.g., Officials Sign Up).
- `flutter_api`: Design API endpoints/models (e.g., assignment endpoints).
- `flutter_backend`: Implement business logic and persistence.
- `qa`: Ensure test coverage and documentation quality.
- `refactorer`: Optimize code for readability and performance.
- `analyzer`: Debug and analyze issues.
- `performance`: Optimize for multi-platform performance.

## Architecture

### Core Structure
- **Entry Point**: `lib/main.dart` (app config, theming, 50+ named routes).
- **Navigation**: `Navigator.pushNamed` with routes defined in `lib/main.dart` (lines 115–165).
- **Theming**: `lib/theme.dart` (consistent styling).
- **Utilities**: `lib/utils/utils.dart` (sport icons, helpers).
- **Features**: 50 screens in `lib/features/` across `auth`, `games`, `home`, `locations`, `officials`, `schedules`.
- **Shared**: Empty `models/` and `services/`; `widgets/` for future reusable components.

### File Structure
- `lib/features/auth/` (6 screens): Sign-up, role selection, photo upload.
- `lib/features/games/` (15 screens): Game templates, scheduling, info entry.
- `lib/features/home/` (5 screens): Role-specific dashboards, settings.
- `lib/features/locations/` (4 screens): Venue management.
- `lib/features/officials/` (9 screens): Scheduler tools for Official rosters.
- `lib/features/schedules/` (6 screens): Schedule creation/filtering.
- `lib/shared/models/` (empty): Future data models.
- `lib/shared/services/` (empty): Future API services.
- `lib/shared/widgets/` (empty): Future reusable widgets.

### State Management
- **Current**: `setState` with `StatefulWidget` for all screens.
- **Persistence**: `shared_preferences` for key-value storage.
- **Future**: Consider `provider` or `flutter_bloc` for Officials features if complex state sharing is needed (e.g., notifications).

### API
- **Status**: No implementation; `http: ^1.2.1` available but unused.
- **Future**: Design REST endpoints for Officials features (e.g., authentication, assignments, profiles, notifications).

### Dependencies
- `table_calendar: ^3.2.0`: Calendar UI.
- `http: ^1.2.1`: API requests (future).
- `shared_preferences: ^2.3.3`: Local storage.
- `intl: ^0.20.2`: Internationalization.
- `font_awesome_flutter: ^10.7.0`: Icons.
- `flutter_lints: ^4.0.0`: Code analysis.

### Testing
- **Current**: Minimal (`test/widget_test.dart` for welcome screen).
- **Strategy**: Implement first, test later. Plan for:
  - Integration tests: Login, assignment acceptance, schedule sync.
  - Widget tests: Reusable Officials components.
  - Unit tests: Business logic post-API implementation.

### Code Style
- Follow `flutter_lints` and `analysis_options.yaml`.
- Use `dart format .` for formatting.
- Name screens as `[feature]_screen.dart` (e.g., `official_dashboard_screen.dart`).

## Officials Features (Planned)
- **Sign Up**: Official registration workflow.
- **Crew Formation**: Group Officials into Crews for bulk hiring.
- **Assignments**: View/accept/reject game opportunities.
- **Communication**: Messaging with Schedulers/Officials.
- **Preferences**: Filter games by criteria (e.g., minimum fee).
- **Directory**: Create `lib/features/officials_user/` for Officials-side screens.

## SuperClaude Configuration
- **Global**: `/home/efficials/.claude/CLAUDE.md` (token economy, custom personas, MCP integration).
- **Project**: `.claude/CLAUDE.md` (this file) for Flutter-specific rules.
- **Preferences**:
  - Code economy: Minimal explanations (`--uc`).
  - Task tracking: Proactive TODOs (`--task`).
  - Performance: Batched operations (`--batch`).
  - Evidence: Use `--evidence` for suggestions.
- **MCP Flags**: Use `--c7` (Context7 for docs), `--seq` (sequential reasoning), `--uc` (compressed output).

  # EFFICIALS APP MIGRATION STATUS
  CRITICAL: The Efficials app is currently migrating from SQLite to Firebase.
  - Prioritize Firebase implementations over SQLite
  - When you see SQLite code, proactively suggest Firebase alternatives
  - Always consider Firebase patterns when making changes
  - Look for opportunities to advance the migration effort

  ## Project-Specific Business Rules
  See `/mnt/c/Users/Efficials/efficials_app/RULES.md` for critical business logic and
  workflow understanding.

  