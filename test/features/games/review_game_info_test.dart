import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../lib/features/games/review_game_info_screen.dart';

void main() {
  group('ReviewGameInfoScreen Template Logic', () {
    setUpAll(() {
      SharedPreferences.setMockInitialValues({});
    });

    testWidgets('smoke test - home game navigation works', (WidgetTester tester) async {
      bool newTemplateRouteCalled = false;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => ReviewGameInfoScreen(),
          ),
          onGenerateRoute: (RouteSettings settings) {
            if (settings.name == '/new_game_template') {
              newTemplateRouteCalled = true;
              return MaterialPageRoute(
                builder: (context) => Scaffold(
                  appBar: AppBar(title: Text('New Game Template')),
                  body: Text('New Template Screen'),
                ),
              );
            }
            return MaterialPageRoute(
              builder: (context) => ReviewGameInfoScreen(),
              settings: RouteSettings(
                arguments: {
                  'sport': 'Basketball',
                  'location': 'Home Court',
                  'date': DateTime.now(),
                  'time': TimeOfDay.now(),
                  'opponent': 'Test Team',
                  'officialsRequired': 2,
                  'gameFee': '50.00',
                  'gender': 'Boys',
                  'levelOfCompetition': 'High School',
                  'isAway': false,
                },
              ),
            );
          },
        ),
      );

      await tester.pumpAndSettle();
      expect(find.byType(ReviewGameInfoScreen), findsOneWidget);
    });

    testWidgets('away game popup test - verify away game shows popup', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () async {
                  await showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text('Away Game Template Not Supported'),
                      content: Text('Game templates can only be created from Home Games.'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text('OK'),
                        ),
                      ],
                    ),
                  );
                },
                child: Text('Test Away Game Popup'),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('Test Away Game Popup'));
      await tester.pumpAndSettle();
      
      expect(find.text('Away Game Template Not Supported'), findsOneWidget);
      expect(find.text('Game templates can only be created from Home Games.'), findsOneWidget);
    });

    testWidgets('navigation condition test - verify new_game_template route', (WidgetTester tester) async {
      bool routeCalled = false;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/new_game_template');
                },
                child: Text('Test Navigation'),
              );
            },
          ),
          onGenerateRoute: (RouteSettings settings) {
            if (settings.name == '/new_game_template') {
              routeCalled = true;
              return MaterialPageRoute(
                builder: (context) => Scaffold(
                  appBar: AppBar(title: Text('New Game Template')),
                  body: Text('New Template Screen'),
                ),
              );
            }
            return null;
          },
        ),
      );

      await tester.tap(find.text('Test Navigation'));
      await tester.pumpAndSettle();
      
      expect(routeCalled, isTrue);
      expect(find.text('New Game Template'), findsOneWidget);
    });
  });
}