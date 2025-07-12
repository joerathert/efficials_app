import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:efficials_app/features/officials/lists_of_officials_screen.dart';

void main() {
  testWidgets('ListsOfOfficialsScreen smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: const ListsOfOfficialsScreen(),
        routes: {
          '/create_new_list': (context) => const Scaffold(body: Text('Create New List')),
          '/edit_list': (context) => const Scaffold(body: Text('Edit List')),
        },
      ),
    );

    expect(find.text('Lists of Officials'), findsOneWidget);
    expect(find.text('Manage your saved lists of officials'), findsOneWidget);
    expect(find.byType(ListsOfOfficialsScreen), findsOneWidget);
  });
}