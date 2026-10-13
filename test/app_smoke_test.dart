import 'package:flutter_test/flutter_test.dart';
import 'package:petrolpump_flutter/main.dart';

void main() {
  testWidgets('app starts on the splash and moves on to login by itself', (tester) async {
    await tester.pumpWidget(const MyApp());
    expect(find.text('Welcome to PARCO'), findsOneWidget);

    // SplashFlow auto-advances after 3 s. Running the clock past it (rather
    // than tearing the tree down) also proves its Timer doesn't outlive the
    // test.
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();

    expect(find.text('Welcome to PARCO'), findsNothing);
    expect(find.text('Access your station operations account'), findsOneWidget);
  });
}
