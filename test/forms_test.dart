import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petrolpump_flutter/models/nozzle.dart';
import 'package:petrolpump_flutter/models/tank_stock.dart';
import 'package:petrolpump_flutter/screens/add_station_screen.dart';
import 'package:petrolpump_flutter/screens/create_reorder_screen.dart';
import 'package:petrolpump_flutter/screens/logs_screen.dart';
import 'package:petrolpump_flutter/screens/signup_screen.dart';
import 'package:petrolpump_flutter/screens/staff_form_screen.dart';
import 'package:petrolpump_flutter/screens/threshold_screen.dart';
import 'package:petrolpump_flutter/widgets/app_text_field.dart';

/// The text field under an AppTextField with this [label].
Finder _field(String label) =>
    find.descendant(of: find.widgetWithText(AppTextField, label), matching: find.byType(EditableText));

String _text(WidgetTester tester, String label) => tester.widget<EditableText>(_field(label)).controller.text;

/// Station-1's Petrol tank: 7,000 L in a 25,000 L tank, so 18,000 L of space.
const _petrol = TankStock(id: 'petrol', fuelName: 'Petrol', currentVolume: 7000, capacity: 25000, threshold: 18000);
const _fullDiesel = TankStock(id: 'diesel', fuelName: 'Diesel', currentVolume: 25000, capacity: 25000, threshold: 18000);

Future<void> _pump(WidgetTester tester, Widget screen) async {
  tester.view.physicalSize = const Size(1200, 2400);
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MaterialApp(home: screen));
}

Future<void> _enterAndTap(WidgetTester tester, String field, String text, String button) async {
  await tester.enterText(_field(field), text);
  await tester.tap(find.text(button));
  await tester.pumpAndSettle();
}

void main() {
  group('Threshold', () {
    late List<double> confirmed;
    setUp(() => confirmed = []);

    Future<void> open(WidgetTester tester) => _pump(
          tester,
          ThresholdScreen(
            stationName: 'Test',
            tanks: const [_petrol],
            onConfirmThreshold: (tank, litres) => confirmed.add(litres),
          ),
        );

    testWidgets('rejects 0 and anything over the capacity, inline', (tester) async {
      await open(tester);

      await _enterAndTap(tester, 'Threshold (L)', '0', 'Confirm');
      expect(find.text('Must be more than 0'), findsOneWidget);

      await _enterAndTap(tester, 'Threshold (L)', '25,001', 'Confirm');
      expect(find.text("Can't be more than the tank holds (25,000 L)"), findsOneWidget);

      await _enterAndTap(tester, 'Threshold (L)', '1e4', 'Confirm');
      expect(find.text('Enter a number, e.g. 5,000'), findsOneWidget);
      expect(confirmed, isEmpty);
    });

    testWidgets('accepts commas up to the capacity, then clears the field', (tester) async {
      await open(tester);

      await _enterAndTap(tester, 'Threshold (L)', '25,000', 'Confirm');
      expect(confirmed, [25000]);
      expect(_text(tester, 'Threshold (L)'), isEmpty);
      expect(find.text('Enter an amount'), findsNothing);
    });

    testWidgets('after a rejected value, a valid one clears the field and its error', (tester) async {
      await open(tester);

      await _enterAndTap(tester, 'Threshold (L)', '0', 'Confirm');
      await _enterAndTap(tester, 'Threshold (L)', '5,000', 'Confirm');
      expect(confirmed, [5000]);
      expect(_text(tester, 'Threshold (L)'), isEmpty);
      expect(find.text('Must be more than 0'), findsNothing);
      expect(find.text('Enter an amount'), findsNothing);

      // The emptied field really is empty: Confirm now asks for a value.
      await tester.tap(find.text('Confirm'));
      await tester.pumpAndSettle();
      expect(find.text('Enter an amount'), findsOneWidget);
      expect(confirmed, [5000]);
    });
  });

  group('Create Reorder', () {
    late List<(String, double)> ordered;
    setUp(() => ordered = []);

    Future<void> open(WidgetTester tester) => _pump(
          tester,
          CreateReorderScreen(
            stationName: 'Test',
            tanks: const [_petrol, _fullDiesel],
            onSubmitReorder: (tank, litres) => ordered.add((tank.id, litres)),
          ),
        );

    testWidgets('limits the quantity to the space left in the tank', (tester) async {
      await open(tester);

      await tester.enterText(_field('Reorder Quantity (L)').first, '18,001');
      await tester.tap(find.text('Submit').first);
      await tester.pumpAndSettle();
      expect(find.text('Only 18,000 L of space left in this tank'), findsOneWidget);

      await tester.enterText(_field('Reorder Quantity (L)').first, '-5');
      await tester.tap(find.text('Submit').first);
      await tester.pumpAndSettle();
      expect(find.text('Must be more than 0'), findsOneWidget);
      expect(ordered, isEmpty);

      await tester.enterText(_field('Reorder Quantity (L)').first, '18,000');
      await tester.tap(find.text('Submit').first);
      await tester.pumpAndSettle();
      expect(ordered, [('petrol', 18000.0)]);
      expect(tester.widget<EditableText>(_field('Reorder Quantity (L)').first).controller.text, isEmpty);
    });

    testWidgets('a full tank says so, with its field and Submit disabled', (tester) async {
      await open(tester);

      expect(find.text('Tank is full'), findsOneWidget);
      final fields = tester.widgetList<TextField>(find.byType(TextField)).toList();
      expect(fields.map((f) => f.enabled), [true, false]);
      final buttons = tester.widgetList<ElevatedButton>(find.widgetWithText(ElevatedButton, 'Submit')).toList();
      expect(buttons.map((b) => b.onPressed != null), [true, false]);
    });
  });

  group('Signup', () {
    late List<int> counts;
    setUp(() => counts = []);

    Future<void> fillAllButCount(WidgetTester tester) async {
      await _pump(
        tester,
        SignupScreen(
          onCreateAccount: ({
            required usernameOrGmail,
            required password,
            required dateOfBirth,
            required stationName,
            required stationCount,
          }) =>
              counts.add(stationCount),
        ),
      );
      await tester.enterText(_field('Username or Gmail'), 'amir@gmail.com');
      await tester.enterText(_field('Password'), 'secret123');
      await tester.enterText(_field('Name of Station'), 'Amir Filling');
      await tester.tap(_field('Date of Birth'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
    }

    Future<void> submitCount(WidgetTester tester, String count) async {
      await tester.enterText(_field('No. of Stations'), count);
      await tester.tap(find.widgetWithText(ElevatedButton, 'Create Account'));
      await tester.pumpAndSettle();
    }

    testWidgets('No. of Stations must be a whole number from 1 to 20', (tester) async {
      await fillAllButCount(tester);
      for (final bad in ['0', '21', '999999999', '-2']) {
        await submitCount(tester, bad);
        expect(find.text('Enter a number from 1 to 20'), findsOneWidget, reason: bad);
      }
      await submitCount(tester, '2.5');
      expect(find.text('Enter a whole number'), findsOneWidget);
      expect(counts, isEmpty);

      await submitCount(tester, '20');
      expect(counts, [20]);
    });

    testWidgets('a short password is rejected', (tester) async {
      await fillAllButCount(tester);
      await tester.enterText(_field('Password'), '12345');
      await submitCount(tester, '1');
      expect(find.text('Use at least 6 characters'), findsOneWidget);
      expect(counts, isEmpty);
    });
  });

  testWidgets('Staff form: an empty form saves nothing; a bad CNIC or phone is flagged', (tester) async {
    final saved = <StaffFormValues>[];
    await _pump(tester, StaffFormScreen(stationName: 'Test', onSave: saved.add));

    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.text('Enter their full name'), findsOneWidget);
    expect(find.text('This field is required'), findsOneWidget); // contact number
    expect(saved, isEmpty);

    await tester.enterText(_field('Full Name'), 'Ali Raza');
    await tester.enterText(_field('CNIC'), '12345');
    await tester.enterText(_field('Contact Number'), '0300-1234567');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.text('Enter the 13-digit CNIC'), findsOneWidget);
    expect(saved, isEmpty);

    await tester.enterText(_field('CNIC'), '35202-1234567-1');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(saved.single.fullName, 'Ali Raza');
  });

  testWidgets('Add Station needs a nozzle, and a capacity for each grade with nozzles', (tester) async {
    final added = <double>[];
    await _pump(
      tester,
      AddStationScreen(
        onAddStation: ({
          required name,
          required location,
          required petrolNozzles,
          required dieselNozzles,
          required hiOctaneNozzles,
          required petrolCapacityL,
          required dieselCapacityL,
          required hiOctaneCapacityL,
        }) =>
            added.add(petrolCapacityL),
      ),
    );
    await tester.enterText(_field('Station Name'), 'Lahore Fuels');
    await tester.enterText(_field('Station Location'), 'Lahore');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Add Station'));
    await tester.pumpAndSettle();
    expect(find.text('Add at least one nozzle'), findsOneWidget);

    await tester.enterText(_field('Petrol').first, '41');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Add Station'));
    await tester.pumpAndSettle();
    expect(find.text('Enter a number from 0 to 40'), findsOneWidget);

    await tester.enterText(_field('Petrol').first, '2');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Add Station'));
    await tester.pumpAndSettle();
    expect(find.text('Enter a capacity above 0 for these nozzles'), findsOneWidget);
    expect(added, isEmpty);

    await tester.enterText(_field('Petrol').last, '20,000');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Add Station'));
    await tester.pumpAndSettle();
    expect(added, [20000]);
  });

  testWidgets('Logs: Save Log checks the form, then says saving is not available yet', (tester) async {
    final nozzle = Nozzle(
      id: 'n1',
      pumpNumber: 1,
      nozzleNumber: 1,
      fuelName: 'Petrol',
      litres: 0,
      flowRate: 0,
      lastUpdated: DateTime(2026),
      status: NozzleStatus.idle,
    );
    await _pump(tester, LogsScreen(stationName: 'Test', entries: const [], nozzles: [nozzle], onNavTap: (_) {}));

    await tester.tap(find.text('Save Log'));
    await tester.pumpAndSettle();
    expect(find.text('Choose the vehicle'), findsOneWidget);
    expect(find.text('Choose the fuel type'), findsOneWidget);
    expect(find.text('Choose the pump and nozzle'), findsOneWidget);
    expect(find.text('Enter an amount'), findsOneWidget);
    expect(find.text("Saving logs isn't available yet."), findsNothing);

    // The dropdowns in form order: Vehicle, Fuel Type, Pump / Nozzle, Status.
    final dropdowns = find.byWidgetPredicate((w) => w is DropdownButtonFormField);
    Future<void> choose(int dropdown, String option) async {
      await tester.tap(dropdowns.at(dropdown));
      await tester.pumpAndSettle();
      await tester.tap(find.text(option).last);
      await tester.pumpAndSettle();
    }

    await choose(0, 'Self');
    await choose(1, 'Petrol');
    await choose(2, nozzle.name);
    await tester.enterText(_field('Litres Dispensed (L)'), '1,500');
    await tester.tap(find.text('Save Log'));
    await tester.pumpAndSettle();
    expect(find.text("Saving logs isn't available yet."), findsOneWidget);
    expect(find.text('PKR 75,000'), findsOneWidget); // 1,500 L × PKR 50

    // Clear empties the whole form, so saving again asks for everything.
    await tester.tap(find.text('Clear'));
    await tester.pumpAndSettle();
    expect(_text(tester, 'Litres Dispensed (L)'), isEmpty);
    expect(find.text('Enter an amount'), findsNothing);
    await tester.tap(find.text('Save Log'));
    await tester.pumpAndSettle();
    expect(find.text('Enter an amount'), findsOneWidget);
    expect(find.text('Choose the vehicle'), findsOneWidget);
  });
}
