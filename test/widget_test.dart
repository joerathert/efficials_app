import 'package:flutter_test/flutter_test.dart';
import 'package:efficials_app/main.dart'; // Matches pubspec.yaml name: efficials_app

void main() {
  testWidgets('Efficials app smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const EfficialsApp());

    // Verify that the Welcome Screen loads.
    expect(find.text('Welcome Back!'), findsOneWidget); // Updated to match actual text
    expect(find.text('Sign In'), findsOneWidget); // Updated to match actual button text
    expect(find.text("Don't have an account? "), findsOneWidget); // This text exists in the welcome screen
  });
}