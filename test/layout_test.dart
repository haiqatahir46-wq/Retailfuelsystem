import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petrolpump_flutter/navigation/main_tabs_flow.dart';
import 'package:petrolpump_flutter/state/app_session.dart';

/// Pumps the main tabs on a [width] x [height] phone with the system text
/// size at [textScale]. The test font draws every glyph about 1em wide,
/// wider than real fonts, so a screen that fits here has room to spare on
/// a device.
Future<AppSession> _pumpTabs(WidgetTester tester, {double width = 360, double height = 800, double textScale = 1}) async {
  tester.view.physicalSize = Size(width, height);
  tester.view.devicePixelRatio = 1;
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

  final session = AppSession()..signInDemo(email: 'owner@example.com');
  addTearDown(session.dispose);
  await tester.pumpWidget(AppSessionScope(session: session, child: const MaterialApp(home: MainTabsFlow())));
  await tester.pumpAndSettle();
  return session;
}

/// Fails the test if laying out what is on screen threw, e.g. a RenderFlex
/// overflow (the yellow-and-black stripes).
void _expectNoOverflow(WidgetTester tester, String where) {
  expect(tester.takeException(), isNull, reason: where);
}

Future<void> _goToTab(WidgetTester tester, String label) async {
  await tester.tap(find.text(label));
  await tester.pumpAndSettle();
}

/// Visits every tab, each Dashboard report period and the open drawer,
/// checking for overflow at each step.
Future<void> _visitEverything(WidgetTester tester) async {
  _expectNoOverflow(tester, 'Dashboard (Today)');

  for (final period in ['Weekly', 'Monthly', 'Yearly']) {
    await tester.tap(find.byIcon(Icons.keyboard_arrow_down).last);
    await tester.pumpAndSettle();
    await tester.tap(find.text(period).last);
    await tester.pumpAndSettle();
    _expectNoOverflow(tester, 'Dashboard ($period)');
  }

  await tester.tap(find.byIcon(Icons.menu));
  await tester.pumpAndSettle();
  expect(find.byType(Drawer), findsOneWidget);
  _expectNoOverflow(tester, 'drawer');
  // Close it by tapping the scrim at the right edge, beside the drawer.
  final screen = tester.view.physicalSize / tester.view.devicePixelRatio;
  await tester.tapAt(Offset(screen.width - 4, screen.height / 2));
  await tester.pumpAndSettle();
  expect(find.byType(Drawer), findsNothing);

  for (final tab in ['Nozzles', 'Tanks', 'Stock', 'Logs']) {
    await _goToTab(tester, tab);
    _expectNoOverflow(tester, tab);
  }

  // Every grade on Nozzles.
  await _goToTab(tester, 'Nozzles');
  for (final fuel in ['Diesel', 'Hi-Octane']) {
    await tester.tap(find.text(fuel).first);
    await tester.pumpAndSettle();
    _expectNoOverflow(tester, 'Nozzles ($fuel)');
  }
}

void main() {
  testWidgets('no overflow at 360 x 800, normal text', (tester) async {
    await _pumpTabs(tester);
    await _visitEverything(tester);
  });

  testWidgets('no overflow at 360 x 800, text at 130%', (tester) async {
    await _pumpTabs(tester, textScale: 1.3);
    await _visitEverything(tester);
  });

  testWidgets('no overflow at 320 x 800, normal text', (tester) async {
    await _pumpTabs(tester, width: 320);
    await _visitEverything(tester);
  });

  testWidgets('no overflow at 320 x 800, text at 130%', (tester) async {
    await _pumpTabs(tester, width: 320, textScale: 1.3);
    await _visitEverything(tester);
  });

  testWidgets('a very long station name is cut short, not overflowing', (tester) async {
    final session = await _pumpTabs(tester, textScale: 1.3);
    final station = session.addStation(
      name: 'Al-Madina Petroleum Service and Filling Station, Main GT Road, Pattoki',
      location: 'Pattoki',
      nozzleCounts: const {'Petrol': 2, 'Diesel': 2, 'Hi-Octane': 2},
      capacities: const {'Petrol': 25000, 'Diesel': 25000, 'Hi-Octane': 25000},
    );
    session.selectStation(station.id);
    await tester.pumpAndSettle();
    await _visitEverything(tester);
  });

  testWidgets('the drawer scrolls instead of overflowing in landscape', (tester) async {
    await _pumpTabs(tester, width: 800, height: 360, textScale: 1.3);
    await tester.tap(find.byIcon(Icons.menu));
    await tester.pumpAndSettle();
    _expectNoOverflow(tester, 'landscape drawer');
    await tester.dragUntilVisible(find.text('Log Out'), find.byType(CustomScrollView), const Offset(0, -100));
    expect(find.text('Log Out'), findsOneWidget);
  });
}
