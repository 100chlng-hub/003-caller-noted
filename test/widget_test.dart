import 'package:flutter_test/flutter_test.dart';
import 'package:caller_noted/main.dart';
import 'package:caller_noted/models/user_settings.dart';

void main() {
  testWidgets('App smoke test initializes without errors', (WidgetTester tester) async {
    final settings = UserSettings(isOnboardingCompleted: false);
    await tester.pumpWidget(CallerNotedApp(initialSettings: settings));
    expect(find.text('Benvenuto in Caller-Noted'), findsOneWidget);
  });
}
