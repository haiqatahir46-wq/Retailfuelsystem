import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petrolpump_flutter/navigation/login_flow.dart';
import 'package:petrolpump_flutter/navigation/main_tabs_flow.dart';
import 'package:petrolpump_flutter/navigation/signup_flow.dart';
import 'package:petrolpump_flutter/screens/create_reorder_screen.dart';
import 'package:petrolpump_flutter/screens/help_center_screen.dart';
import 'package:petrolpump_flutter/screens/login_screen.dart';
import 'package:petrolpump_flutter/screens/profile_screen.dart';
import 'package:petrolpump_flutter/screens/settings_screen.dart';
import 'package:petrolpump_flutter/screens/staff_form_screen.dart';
import 'package:petrolpump_flutter/screens/staff_management_screen.dart';
import 'package:petrolpump_flutter/screens/threshold_screen.dart';
import 'package:petrolpump_flutter/state/app_session.dart';
import 'package:petrolpump_flutter/widgets/app_text_field.dart';

/// The main tabs for a signed-in demo session, pushed on top of a plain
/// home page so a test can tell "back went to Dashboard" from "back left
/// the tabs".
Widget _app(AppSession session) {
  return AppSessionScope(
    session: session,
    child: MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: TextButton(
              onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const MainTabsFlow())),
              child: const Text('Open tabs'),
            ),
          ),
        ),
      ),
    ),
  );
}

/// A phone-shaped surface tall enough that the screens lay out without
/// scrolling past what a test taps.
void _useTallSurface(WidgetTester tester) {
  tester.view.physicalSize = const Size(1200, 2400);
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.reset);
}

/// Pumps the app and opens the main tabs.
Future<void> _openTabs(WidgetTester tester, AppSession session) async {
  _useTallSurface(tester);
  await tester.pumpWidget(_app(session));
  await tester.tap(find.text('Open tabs'));
  await tester.pumpAndSettle();
}

Future<void> _goToTab(WidgetTester tester, String label) async {
  await tester.tap(find.text(label));
  await tester.pumpAndSettle();
}

/// The text field under an AppTextField with this [label].
Finder _field(String label) =>
    find.descendant(of: find.widgetWithText(AppTextField, label), matching: find.byType(EditableText));

void main() {
  late AppSession session;
  setUp(() => session = AppSession()..signInDemo(email: 'owner@example.com'));
  tearDown(() => session.dispose());

  testWidgets('signing in on Login opens the demo station\'s Dashboard', (tester) async {
    _useTallSurface(tester);
    final fresh = AppSession();
    addTearDown(fresh.dispose);
    await tester.pumpWidget(AppSessionScope(session: fresh, child: const MaterialApp(home: LoginFlow())));

    await tester.enterText(_field('Email / Username'), 'amir@gmail.com');
    await tester.enterText(_field('Password'), 'secret123');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Sign In'));
    await tester.pumpAndSettle();

    expect(find.byType(LoginScreen), findsNothing);
    expect(find.byType(MainTabsFlow), findsOneWidget);
    expect(find.text('Overview'), findsOneWidget);
    expect(find.text('Amir Filling, Pattoki'), findsOneWidget);
    expect(find.text('Revenue Today (PKR)'), findsOneWidget);
    expect(find.text('1,512,000'), findsOneWidget);
    expect(fresh.owner!.email, 'amir@gmail.com');
  });

  testWidgets('text typed on Logs survives switching to Dashboard and back', (tester) async {
    await _openTabs(tester, session);
    await _goToTab(tester, 'Logs');
    await tester.enterText(_field('Litres Dispensed (L)'), '1234');
    await tester.pump();

    await _goToTab(tester, 'Dashboard');
    expect(find.text('Overview'), findsOneWidget);
    await _goToTab(tester, 'Logs');
    expect(find.text('1234'), findsOneWidget);
  });

  testWidgets('switching station shows that station and starts its tabs afresh', (tester) async {
    await _openTabs(tester, session);
    await _goToTab(tester, 'Logs');
    await tester.enterText(_field('Litres Dispensed (L)'), '1234');
    await tester.pump();

    session.selectStation('station-2');
    await tester.pumpAndSettle();
    expect(find.text('Demo Station 2'), findsOneWidget);
    expect(find.text('1234'), findsNothing);
  });

  testWidgets('back on the Stock tab goes to Dashboard; back on Dashboard leaves the tabs', (tester) async {
    await _openTabs(tester, session);
    await _goToTab(tester, 'Stock');
    expect(find.text('Recent Purchased Orders'), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byType(MainTabsFlow), findsOneWidget);
    expect(find.text('Overview'), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byType(MainTabsFlow), findsNothing);
    expect(find.text('Open tabs'), findsOneWidget);
  });

  testWidgets('back with the drawer open on Stock closes the drawer, then goes to Dashboard', (tester) async {
    await _openTabs(tester, session);
    await _goToTab(tester, 'Stock');
    // Stock has no menu icon; the drawer opens by swiping, like this.
    tester.state<ScaffoldState>(find.byType(Scaffold)).openDrawer();
    await tester.pumpAndSettle();
    expect(find.byType(Drawer), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byType(Drawer), findsNothing);
    expect(find.text('Recent Purchased Orders'), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('Overview'), findsOneWidget);
  });

  testWidgets('the drawer shows the session owner and is closed after Settings -> back', (tester) async {
    await _openTabs(tester, session);
    await tester.tap(find.byIcon(Icons.menu));
    await tester.pumpAndSettle();
    expect(find.byType(Drawer), findsOneWidget);
    expect(find.text('Haiqa Tahir'), findsOneWidget);
    expect(find.text('owner@example.com'), findsOneWidget);

    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
    expect(find.byType(SettingsScreen), findsOneWidget);

    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();
    expect(find.byType(SettingsScreen), findsNothing);
    expect(find.byType(Drawer), findsNothing);
    expect(find.text('Overview'), findsOneWidget);
  });

  testWidgets('a drawer item activated while the drawer is closing still works, and the tabs stay', (tester) async {
    final semantics = tester.ensureSemantics();
    await _openTabs(tester, session);
    await tester.tap(find.byIcon(Icons.menu));
    await tester.pumpAndSettle();

    // Back starts closing the drawer, which drops its history entry at
    // once. A screen reader (like a keyboard) can still activate an item
    // while it slides away; popping then would have removed the tabs' own
    // route instead of the drawer.
    await tester.binding.handlePopRoute();
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.byType(Drawer), findsOneWidget);
    tester.semantics.tap(find.semantics.byLabel('Help Center'));
    await tester.pumpAndSettle();
    expect(find.byType(HelpCenterScreen), findsOneWidget);

    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();
    expect(find.byType(MainTabsFlow), findsOneWidget);
    expect(find.text('Overview'), findsOneWidget);
    expect(find.byType(Drawer), findsNothing);
    semantics.dispose();
  });

  testWidgets('Threshold Confirm stays open and updates Stock; its Reorder places an order', (tester) async {
    await _openTabs(tester, session);
    await _goToTab(tester, 'Stock');
    await tester.tap(find.text('Set Threshold').first);
    await tester.pumpAndSettle();
    expect(find.byType(ThresholdScreen), findsOneWidget);

    // The first tank is Petrol.
    await tester.enterText(_field('Threshold (L)').first, '5000');
    await tester.tap(find.text('Confirm').first);
    await tester.pumpAndSettle();
    expect(find.text('Petrol threshold set to 5,000 L'), findsOneWidget);
    expect(find.byType(ThresholdScreen), findsOneWidget);
    expect(session.tanksFor('station-1').first.threshold, 5000);

    await tester.tap(find.text('Reorder').first);
    await tester.pumpAndSettle();
    expect(find.byType(CreateReorderScreen), findsOneWidget);
    await tester.enterText(_field('Reorder Quantity (L)').first, '2000');
    await tester.tap(find.text('Submit').first);
    // Settle: this SnackBar waits for the threshold one to slide away.
    await tester.pumpAndSettle();
    final order = session.purchaseOrdersFor('station-1').first;
    expect(find.text('${order.poNumber} placed: 2,000 L of Petrol'), findsOneWidget);
    expect(find.byType(CreateReorderScreen), findsOneWidget);

    // Back to Stock: the new threshold and the new pending order are there.
    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();
    expect(find.text('Recent Purchased Orders'), findsOneWidget);
    expect(find.text('5,000 L'), findsOneWidget);
    expect(find.text(order.poNumber), findsOneWidget);
    expect(find.text('Petrol · 2,000 L'), findsOneWidget);
  });

  /// Sets Petrol's threshold on Stock -> Set Threshold, so its SnackBar is
  /// showing, then goes back to Stock.
  Future<void> showThresholdSnackBar(WidgetTester tester) async {
    await _goToTab(tester, 'Stock');
    await tester.tap(find.text('Set Threshold').first);
    await tester.pumpAndSettle();
    await tester.enterText(_field('Threshold (L)').first, '5000');
    await tester.tap(find.text('Confirm').first);
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();
    expect(find.text('Petrol threshold set to 5,000 L'), findsOneWidget);
  }

  testWidgets("a SnackBar doesn't follow the owner onto Login after logging out", (tester) async {
    await _openTabs(tester, session);
    await showThresholdSnackBar(tester);

    await _goToTab(tester, 'Dashboard');
    await tester.tap(find.byIcon(Icons.menu));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Log Out'));
    await tester.pumpAndSettle();
    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.text('Petrol threshold set to 5,000 L'), findsNothing);
  });

  testWidgets("a SnackBar doesn't follow onto another station's tabs", (tester) async {
    await _openTabs(tester, session);
    await showThresholdSnackBar(tester);

    await tester.tap(find.text('Amir Filling, Pattoki')); // Stock's station row
    await tester.pumpAndSettle();
    await tester.tap(find.text('Demo Station 2'));
    await tester.pumpAndSettle();
    expect(session.currentStationId, 'station-2');
    expect(find.text('Petrol threshold set to 5,000 L'), findsNothing);
  });

  testWidgets('a tab tapped on Profile lands the main tabs on that tab', (tester) async {
    await _openTabs(tester, session);
    // From Nozzles' avatar: Profile's bar shows the tab it came from.
    await _goToTab(tester, 'Nozzles');
    await tester.tap(find.byTooltip('Profile'));
    await tester.pumpAndSettle();
    expect(find.byType(ProfileScreen), findsOneWidget);
    expect(tester.getSemantics(find.bySemanticsLabel('Nozzles')), containsSemantics(isSelected: true));

    await tester.tap(find.text('Stock'));
    await tester.pumpAndSettle();
    expect(find.byType(ProfileScreen), findsNothing);
    expect(find.byType(MainTabsFlow), findsOneWidget);
    expect(find.text('Recent Purchased Orders'), findsOneWidget);
  });

  testWidgets('a double tap on Add Staff opens one form, not two', (tester) async {
    await _openTabs(tester, session);
    await tester.tap(find.byTooltip('Profile'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Staff Management'));
    await tester.pumpAndSettle();
    expect(find.byType(StaffManagementScreen), findsOneWidget);

    // Both taps land before a frame: the second finds Staff no longer the
    // top route (isTopRoute) and does nothing.
    await tester.tap(find.text('+ Add Staff'));
    await tester.tap(find.text('+ Add Staff'));
    await tester.pumpAndSettle();
    expect(find.byType(StaffFormScreen, skipOffstage: false), findsOneWidget);

    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();
    expect(find.byType(StaffManagementScreen), findsOneWidget);
  });

  testWidgets('logging out from the drawer clears the session and lands on Login', (tester) async {
    await _openTabs(tester, session);
    await tester.tap(find.byIcon(Icons.menu));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Log Out'));
    await tester.pumpAndSettle();

    expect(session.isSignedIn, isFalse);
    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.byType(MainTabsFlow), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('signup stations, plus one added, all reach the main tabs with none of the demo data', (tester) async {
    _useTallSurface(tester);
    final fresh = AppSession();
    addTearDown(fresh.dispose);
    await tester.pumpWidget(AppSessionScope(session: fresh, child: const MaterialApp(home: SignupFlow())));

    await tester.enterText(_field('Username or Gmail'), 'amir@gmail.com');
    await tester.enterText(_field('Password'), 'secret123');
    await tester.enterText(_field('Name of Station'), '   ');
    await tester.enterText(_field('No. of Stations'), '2');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Create Account'));
    await tester.pumpAndSettle();

    // A blank station name and no date of birth keep the form open.
    expect(find.text('Enter the station name'), findsOneWidget);
    expect(find.text('Pick your date of birth'), findsOneWidget);
    expect(fresh.isSignedIn, isFalse);

    await tester.enterText(_field('Name of Station'), 'Amir Filling');
    await tester.tap(_field('Date of Birth'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ElevatedButton, 'Create Account'));
    await tester.pumpAndSettle();

    expect(find.text('YOUR STATIONS (2)'), findsOneWidget);
    expect(find.text('Amir Filling'), findsOneWidget);
    expect(find.text('Setup pending'), findsOneWidget);

    await tester.tap(find.text('+ Add Another Station'));
    await tester.pumpAndSettle();
    await tester.enterText(_field('Station Name'), 'Lahore Fuels');
    await tester.enterText(_field('Station Location'), 'Lahore');
    await tester.enterText(_field('Petrol').first, '2'); // nozzles
    await tester.enterText(_field('Petrol').last, '20000'); // capacity
    await tester.tap(find.widgetWithText(ElevatedButton, 'Add Station'));
    await tester.pumpAndSettle();
    expect(find.text('YOUR STATIONS (3)'), findsOneWidget);
    expect(find.text('Lahore Fuels'), findsOneWidget);

    await tester.tap(find.text('Continue to Dashboard'));
    await tester.pumpAndSettle();
    expect(find.byType(MainTabsFlow), findsOneWidget);
    expect(find.text('Amir Filling'), findsOneWidget);
    expect(find.text('0 / 0'), findsOneWidget); // no nozzles, not station-1's 8 / 12
    expect(fresh.owner!.name, 'amir');
    expect(fresh.stations.map((s) => s.id), isNot(contains('station-1')));

    await _goToTab(tester, 'Stock');
    expect(find.text('No tanks set up for this station yet.'), findsOneWidget);
    expect(find.text('No purchase orders for this station yet.'), findsOneWidget);

    // Every station, the added one included, is on the switcher.
    await tester.tap(find.text('Amir Filling'));
    await tester.pumpAndSettle();
    expect(find.text('Station 2'), findsOneWidget);
    await tester.tap(find.text('Lahore Fuels'));
    await tester.pumpAndSettle();
    expect(find.text('Lahore Fuels'), findsOneWidget);
    // Its Petrol tank: full (current volume = capacity), with the default
    // threshold of a quarter of it.
    expect(find.text('20,000 L'), findsNWidgets(2));
    expect(find.text('5,000 L'), findsOneWidget);
  });
}
