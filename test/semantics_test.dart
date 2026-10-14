import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petrolpump_flutter/data/demo_stations.dart';
import 'package:petrolpump_flutter/models/sales.dart';
import 'package:petrolpump_flutter/navigation/main_tabs_flow.dart';
import 'package:petrolpump_flutter/screens/help_center_screen.dart';
import 'package:petrolpump_flutter/screens/select_station_screen.dart';
import 'package:petrolpump_flutter/screens/signup_screen.dart';
import 'package:petrolpump_flutter/screens/stations_added_screen.dart';
import 'package:petrolpump_flutter/state/app_session.dart';
import 'package:petrolpump_flutter/widgets/app_top_bar.dart';
import 'package:petrolpump_flutter/widgets/sales_report_widgets.dart';

/// What a screen reader is told, and how big the tap targets are.

Future<void> _pump(WidgetTester tester, Widget home) async {
  tester.view.physicalSize = const Size(1200, 2400);
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(home);
  await tester.pumpAndSettle();
}

/// The button node a Semantics widget labelled [label] makes (a fuel chip,
/// not the grade's name on a nozzle card).
Finder _button(String label) =>
    find.byWidgetPredicate((w) => w is Semantics && w.properties.button == true && w.properties.label == label);

Future<void> _pumpTabs(WidgetTester tester) async {
  final session = AppSession()..signInDemo(email: 'owner@example.com');
  addTearDown(session.dispose);
  await _pump(tester, AppSessionScope(session: session, child: const MaterialApp(home: MainTabsFlow())));
}

void main() {
  testWidgets('the bottom nav says which tab is selected, and follows a tap', (tester) async {
    final semantics = tester.ensureSemantics();
    await _pumpTabs(tester);

    expect(
      tester.getSemantics(find.bySemanticsLabel('Dashboard')),
      containsSemantics(label: 'Dashboard', isButton: true, isSelected: true, hasTapAction: true),
    );
    expect(tester.getSemantics(find.bySemanticsLabel('Stock')), containsSemantics(isButton: true, isSelected: false));

    await tester.tap(find.text('Stock'));
    await tester.pumpAndSettle();
    expect(tester.getSemantics(find.bySemanticsLabel('Stock')), containsSemantics(isSelected: true));
    expect(tester.getSemantics(find.bySemanticsLabel('Dashboard')), containsSemantics(isSelected: false));
    semantics.dispose();
  });

  testWidgets('the Nozzles fuel chips are buttons that say which grade is selected', (tester) async {
    final semantics = tester.ensureSemantics();
    await _pumpTabs(tester);
    await tester.tap(find.text('Nozzles'));
    await tester.pumpAndSettle();

    expect(tester.getSemantics(_button('Petrol')), containsSemantics(label: 'Petrol', isButton: true, isSelected: true));
    await tester.tap(_button('Diesel'));
    await tester.pumpAndSettle();
    expect(tester.getSemantics(_button('Diesel')), containsSemantics(isButton: true, isSelected: true));
    expect(tester.getSemantics(_button('Petrol')), containsSemantics(isSelected: false));
    semantics.dispose();
  });

  testWidgets('a drill-down\'s back arrow is a "Back" button', (tester) async {
    final semantics = tester.ensureSemantics();
    var backs = 0;
    await _pump(tester, MaterialApp(home: HelpCenterScreen(onBack: () => backs++)));

    expect(find.byTooltip('Back'), findsOneWidget);
    expect(
      tester.getSemantics(find.byTooltip('Back')),
      containsSemantics(tooltip: 'Back', isButton: true, hasTapAction: true),
    );
    await tester.tap(find.byTooltip('Back'));
    expect(backs, 1);
    semantics.dispose();
  });

  testWidgets('Signup\'s round back button is a "Back" button', (tester) async {
    final semantics = tester.ensureSemantics();
    var backs = 0;
    await _pump(
      tester,
      MaterialApp(
        home: SignupScreen(
          onBack: () => backs++,
          onCreateAccount: ({
            required usernameOrGmail,
            required password,
            required dateOfBirth,
            required stationName,
            required stationCount,
          }) {},
        ),
      ),
    );

    expect(tester.getSemantics(find.bySemanticsLabel('Back')), containsSemantics(isButton: true, hasTapAction: true));
    tester.semantics.tap(find.semantics.byLabel('Back'));
    expect(backs, 1);
    semantics.dispose();
  });

  testWidgets('the pencils are named, with 48dp tap targets', (tester) async {
    await _pump(
      tester,
      MaterialApp(
        home: SelectStationScreen(
          stations: demoStations,
          selectedStationId: demoStations.first.id,
          onStationSelected: (_) {},
          onEditStation: (_) {},
          onAddStation: () {},
        ),
      ),
    );
    expect(find.byTooltip('Edit location'), findsNWidgets(demoStations.length));
    expect(tester.getSize(find.byTooltip('Edit location').first), const Size(48, 48));

    await _pump(tester, MaterialApp(home: StationsAddedScreen(stations: demoStations, onContinue: () {})));
    expect(find.byTooltip('Edit station'), findsNWidgets(demoStations.length));
    expect(tester.getSize(find.byTooltip('Edit station').first), const Size(48, 48));
  });

  testWidgets('the period dropdown and the tappable station row are at least 48dp tall', (tester) async {
    await _pump(
      tester,
      MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              PeriodDropdown(period: SalesReportPeriod.today, onChanged: (_) {}),
              StationRow(stationName: 'Test', onTap: () {}),
            ],
          ),
        ),
      ),
    );
    expect(tester.getSize(find.byType(PeriodDropdown)).height, greaterThanOrEqualTo(48));
    expect(tester.getSize(find.byType(StationRow)).height, greaterThanOrEqualTo(48));
  });
}
