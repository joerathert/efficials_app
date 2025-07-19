# RULES.md

Rules for Claude Code in the **Efficials** Flutter project to ensure consistency and alignment with project goals.

## User Flow Context
When a message starts with these prefixes, interpret the context from that user's perspective:
- **AD** - Athletic Director user flow (administrative oversight, game management, templates)
- **AS** - Assigner user flow (official assignment, scheduling, availability management)  
- **CO** - Coach user flow (team management, game participation, roster management)
- **OF** - Officials user flow (game officiating, availability, assignment acceptance)

Format: `[PREFIX] - [Description of action/observation]`

- Use `setState` with `StatefulWidget` for state management unless explicitly specified otherwise.
- Add new routes to `lib/main.dart` routes map using `Navigator.pushNamed`.
- Do not assume file contents; request specific files (e.g., `lib/main.dart`, `lib/features/auth/welcome_screen.dart`) before referencing or modifying.
- No API integration exists; design REST endpoints explicitly for Officials features (e.g., authentication, assignments) when required.
- Prioritize implementation over testing for new features; add integration tests for critical flows (e.g., login, assignment acceptance) and widget tests for reusable components later.
- Follow `flutter_lints` and `analysis_options.yaml`; run `dart format .` before commits.
- Use SuperClaude flags: `--evidence` for suggestions backed by documentation, `--uc` for minimal explanations.
- Name new screens as `[feature]_screen.dart` (e.g., `official_signup_screen.dart`, `available_assignments_screen.dart`).
- Place Officials-side screens in `lib/features/officials_user/` to distinguish from Scheduler tools in `lib/features/officials/`.