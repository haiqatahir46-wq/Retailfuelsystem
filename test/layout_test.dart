import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petrolpump_flutter/navigation/main_tabs_flow.dart';
import 'package:petrolpump_flutter/screens/create_reorder_screen.dart';
import 'package:petrolpump_flutter/screens/help_center_screen.dart';
import 'package:petrolpump_flutter/screens/threshold_screen.dart';
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

/// Scrolls the screen's list to the end, so every card has been laid out,
/// checking for overflow on the way.
Future<void> _scrollThrough(WidgetTester tester, String where) async {
  for (var i = 0; i < 6; i++) {
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -300));
    await tester.pumpAndSettle();
    _expectNoOverflow(tester, where);
  }
}

/// Opens the drill-downs pushed from the tabs (Threshold, Create Reorder
/// from it, and Help Center with every answer open), checking each for
/// overflow.
Future<void> _visitDrillDowns(WidgetTester tester) async {
  await _goToTab(tester, 'Stock');
  await tester.tap(find.text('Set Threshold').first);
  await tester.pumpAndSettle();
  expect(find.byType(ThresholdScreen), findsOneWidget);
  _expectNoOverflow(tester, 'Threshold');
  await tester.tap(find.text('Reorder').first);
  await tester.pumpAndSettle();
  expect(find.byType(CreateReorderScreen), findsOneWidget);
  await _scrollThrough(tester, 'Create Reorder');
  await tester.tap(find.byIcon(Icons.arrow_back));
  await tester.pumpAndSettle();
  await _scrollThrough(tester, 'Threshold');
  await tester.tap(find.byIcon(Icons.arrow_back));
  await tester.pumpAndSettle();

  await _goToTab(tester, 'Dashboard');
  await tester.tap(find.byTooltip('Help Center'));
  await tester.pumpAndSettle();
  expect(find.byType(HelpCenterScreen), findsOneWidget);
  for (final topic in kDefaultHelpTopics) {
    await tester.scrollUntilVisible(find.text(topic.question), 100, scrollable: find.byType(Scrollable).first);
    await tester.tap(find.text(topic.question));
    await tester.pumpAndSettle();
    _expectNoOverflow(tester, 'Help Center: ${topic.question}');
  }
  await _scrollThrough(tester, 'Help Center');
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

  testWidgets('no overflow on Threshold, Create Reorder and Help Center at 320 x 800, text at 130%', (tester) async {
    await _pumpTabs(tester, width: 320, textScale: 1.3);
    await _visitDrillDowns(tester);
  });

  testWidgets('below 360dp Revenue Today gets a row of its own, its figure no smaller than its caption', (tester) async {
    for (final textScale in [1.0, 1.3]) {
      await _pumpTabs(tester, width: 320, textScale: textScale);
      final figure = find.text('1,512,000');
      final caption = find.text('Revenue Today (PKR)');
      // Alone on its row: the next card starts below it, not beside it.
      expect(tester.getTopLeft(find.text('Litres Dispensed')).dy, greaterThan(tester.getBottomLeft(caption).dy));
      // The figure (16pt) may shrink to fit, but never below the caption's
      // 11pt: drawn width over laid-out width is its scale.
      final scale = tester.getRect(figure).width / tester.getSize(figure).width;
      expect(16 * scale, greaterThanOrEqualTo(11), reason: 'text at $textScale');
    }
  });

  testWidgets('a very long station name is cut short, not overflowing', (tester) async {
    final session = await _pumpTabs(tester, textScale: 1.3);
    final station = (await session.addStation(
      name: 'Al-Madina Petroleum Service and Filling Station, Main GT Road, Pattoki',
      location: 'Pattoki',
      nozzleCounts: const {'Petrol': 2, 'Diesel': 2, 'Hi-Octane': 2},
      capacities: const {'Petrol': 25000, 'Diesel': 25000, 'Hi-Octane': 25000},
    ))!;
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
