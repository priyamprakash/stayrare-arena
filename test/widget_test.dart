import 'package:flutter_test/flutter_test.dart';
import 'package:stayrare/main.dart';

void main() {
  testWidgets('Cricket League App renders dashboard and navigation bar', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const CricketLeagueApp());

    // Verify that the title and bottom navigation bar destinations exist.
    expect(find.text('Cricket League'), findsWidgets);
    expect(find.text('Dashboard'), findsWidgets);
    expect(find.text('Auction'), findsOneWidget);
    expect(find.text('Players'), findsOneWidget);
    expect(find.text('Match Day'), findsOneWidget);
    expect(find.text('Admin'), findsOneWidget);
    expect(find.text('Rules'), findsOneWidget);
  });
}
