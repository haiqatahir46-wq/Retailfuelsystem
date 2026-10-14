import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petrolpump_flutter/models/nozzle.dart';
import 'package:petrolpump_flutter/models/tank_stock.dart';
import 'package:petrolpump_flutter/screens/account_details_screen.dart';
import 'package:petrolpump_flutter/screens/add_station_screen.dart';
import 'package:petrolpump_flutter/screens/create_reorder_screen.dart';
import 'package:petrolpump_flutter/screens/login_screen.dart';
import 'package:petrolpump_flutter/screens/logs_screen.dart';
import 'package:petrolpump_flutter/screens/signup_screen.dart';
import 'package:petrolpump_flutter/screens/staff_form_screen.dart';
import 'package:petrolpump_flutter/screens/threshold_screen.dart';
import 'package:petrolpump_flutter/widgets/app_text_field.dart';

/// The text field under an AppTextField with this [label].
Finder _field(String label) =>
    find.descendant(of: find.widgetWithText(AppTextField, label), matching: find.byType(EditableText));

String _text(WidgetTester tester, String label) => tester.widget<EditableText>(_field(label)).controller.text;

/// The error under the AppTextField with this [label], or null. For fields
/// whose hint reads the same as their error.
String? _errorOf(WidgetTester tester, String label) => tester
    .widget<InputDecorator>(
      find.descendant(of: find.widgetWithText(AppTextField, label), matching: find.byType(InputDecorator)),
    )
    .decoration
    .errorText;

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

    testWidgets('rejects 0, under 1 L, negatives and anything over the capacity, inline', (tester) async {
      await open(tester);

      await _enterAndTap(tester, 'Threshold (L)', '0', 'Confirm');
      expect(find.text('Must be more than 0'), findsOneWidget);

      // 0.4 L would be accepted, then shown as "0 L" on the card.
      await _enterAndTap(tester, 'Threshold (L)', '0.4', 'Confirm');
      expect(find.text('Must be at least 1'), findsOneWidget);

      await _enterAndTap(tester, 'Threshold (L)', '-5', 'Confirm');
      expect(find.text("Can't be negative"), findsOneWidget);

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

    testWidgets('reads Urdu digits', (tester) async {
      await open(tester);

      await _enterAndTap(tester, 'Threshold (L)', '۵,۰۰۰', 'Confirm'); // ۵,۰۰۰
      expect(confirmed, [5000]);
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
      expect(find.text("Can't be negative"), findsOneWidget);

      await tester.enterText(_field('Reorder Quantity (L)').first, '0.4');
      await tester.tap(find.text('Submit').first);
      await tester.pumpAndSettle();
      expect(find.text('Must be at least 1'), findsOneWidget);
      expect(ordered, isEmpty);

      await tester.enterText(_field('Reorder Quantity (L)').first, '18,000');
      await tester.tap(find.text('Submit').first);
      await tester.pumpAndSettle();
      expect(ordered, [('petrol', 18000.0)]);
      expect(tester.widget<EditableText>(_field('Reorder Quantity (L)').first).controller.text, isEmpty);
    });

    testWidgets('a fractional room is shown rounded down, so the figure it names is accepted', (tester) async {
      // 25,000 - 7,000.4 = 17,999.6 L of room: "18,000" would be too much.
      await _pump(
        tester,
        CreateReorderScreen(
          stationName: 'Test',
          tanks: [_petrol.copyWith(currentVolume: 7000.4)],
          onSubmitReorder: (tank, litres) => ordered.add((tank.id, litres)),
        ),
      );
      expect(find.text('Up to 17,999 L'), findsOneWidget);

      await tester.enterText(_field('Reorder Quantity (L)'), '18,000');
      await tester.tap(find.text('Submit'));
      await tester.pumpAndSettle();
      expect(find.text('Only 17,999 L of space left in this tank'), findsOneWidget);
      expect(ordered, isEmpty);

      await tester.enterText(_field('Reorder Quantity (L)'), '17,999');
      await tester.tap(find.text('Submit'));
      await tester.pumpAndSettle();
      expect(ordered, [('petrol', 17999.0)]);
    });

    testWidgets('less than 1 L of room counts as full', (tester) async {
      await _pump(
        tester,
        CreateReorderScreen(stationName: 'Test', tanks: [_petrol.copyWith(currentVolume: 24999.5)]),
      );
      expect(find.text('Tank is full'), findsOneWidget);
      expect(tester.widget<TextField>(find.byType(TextField)).enabled, isFalse);
    });

    testWidgets('a full tank says so, with its field and Submit disabled', (tester) async {
      await open(tester);

      expect(find.text('Tank is full'), findsOneWidget);
      final fields = tester.widgetList<TextField>(find.byType(TextField)).toList();
      expect(fields.map((f) => f.enabled), [true, false]);
      final buttons = tester.widgetList<ElevatedButton>(find.widgetWithText(ElevatedButton, 'Submit')).toList();
      expect(buttons.map((b) => b.onPressed != null), [true, false]);
    });

    testWidgets('litres already on order shrink the limit, and the message says so', (tester) async {
      await _pump(
        tester,
        CreateReorderScreen(
          stationName: 'Test',
          tanks: const [_petrol],
          // 18,000 L of space, 15,000 of it already coming.
          pendingLitres: const {'petrol': 15000},
          onSubmitReorder: (tank, litres) => ordered.add((tank.id, litres)),
        ),
      );

      await tester.enterText(_field('Reorder Quantity (L)'), '3,001');
      await tester.tap(find.text('Submit'));
      await tester.pumpAndSettle();
      expect(find.text('Only 3,000 L of space left (15,000 L already on order)'), findsOneWidget);
      expect(ordered, isEmpty);

      await tester.enterText(_field('Reorder Quantity (L)'), '3,000');
      await tester.tap(find.text('Submit'));
      await tester.pumpAndSettle();
      expect(ordered, [('petrol', 3000.0)]);
    });

    testWidgets('a tank whose space is all on order says so, with its field and Submit disabled', (tester) async {
      await _pump(
        tester,
        const CreateReorderScreen(
          stationName: 'Test',
          tanks: [_petrol, _fullDiesel],
          pendingLitres: {'petrol': 18000, 'diesel': 5000},
        ),
      );

      expect(find.text('Already fully on order'), findsOneWidget);
      expect(find.text('Tank is full'), findsOneWidget); // the full Diesel tank, pending or not
      final fields = tester.widgetList<TextField>(find.byType(TextField)).toList();
      expect(fields.map((f) => f.enabled), [false, false]);
      final buttons = tester.widgetList<ElevatedButton>(find.widgetWithText(ElevatedButton, 'Submit')).toList();
      expect(buttons.map((b) => b.onPressed != null), [false, false]);
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
      await submitCount(tester, '0');
      expect(find.text('Enter a number from 1 to 20'), findsOneWidget);
      for (final big in ['21', '999999999', '99999999999999999999999']) {
        await submitCount(tester, big);
        expect(find.text('Too large (max 20)'), findsOneWidget, reason: big);
      }
      await submitCount(tester, '-2');
      expect(find.text("Can't be negative"), findsOneWidget);
      await submitCount(tester, '2.5');
      expect(find.text('Enter a whole number'), findsOneWidget);
      expect(counts, isEmpty);

      await submitCount(tester, '20');
      expect(counts, [20]);
    });

    testWidgets("with an '@' the username must be a valid email", (tester) async {
      await fillAllButCount(tester);
      await tester.enterText(_field('Username or Gmail'), 'amir@gmail');
      await submitCount(tester, '1');
      expect(find.text('Enter a valid email address'), findsOneWidget);
      expect(counts, isEmpty);

      await tester.enterText(_field('Username or Gmail'), 'amir');
      await submitCount(tester, '1');
      expect(counts, [1]);
    });

    testWidgets('a short password is rejected', (tester) async {
      await fillAllButCount(tester);
      await tester.enterText(_field('Password'), '12345');
      await submitCount(tester, '1');
      expect(find.text('Use at least 6 characters'), findsOneWidget);
      expect(counts, isEmpty);
    });
  });

  group('Staff form', () {
    late List<StaffFormValues> saved;
    setUp(() => saved = []);

    Future<void> save(WidgetTester tester) async {
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
    }

    testWidgets('an empty form saves nothing: the name and contact number are required', (tester) async {
      await _pump(tester, StaffFormScreen(stationName: 'Test', onSave: saved.add));
      await save(tester);
      expect(find.text('Enter their full name'), findsOneWidget);
      expect(find.text('This field is required'), findsOneWidget); // contact number
      expect(saved, isEmpty);
    });

    testWidgets('a bad CNIC is flagged', (tester) async {
      await _pump(tester, StaffFormScreen(stationName: 'Test', onSave: saved.add));
      await tester.enterText(_field('Full Name'), 'Ali Raza');
      await tester.enterText(_field('Contact Number'), '0300-1234567');
      for (final bad in ['12345', '35202-1234567-12', '3520A-1234567-1']) {
        await tester.enterText(_field('CNIC'), bad);
        await save(tester);
        expect(find.text('Enter the 13-digit CNIC'), findsOneWidget, reason: bad);
      }
      expect(saved, isEmpty);

      await tester.enterText(_field('CNIC'), '35202 1234567 1');
      await save(tester);
      expect(saved.single.fullName, 'Ali Raza');
    });

    testWidgets('a bad phone number is flagged; spaces, brackets and 0092 are fine', (tester) async {
      await _pump(tester, StaffFormScreen(stationName: 'Test', onSave: saved.add));
      await tester.enterText(_field('Full Name'), 'Ali Raza');
      for (final bad in ['12345', '0300-12345ab', '+92', '123456789012345']) {
        await tester.enterText(_field('Contact Number'), bad);
        await save(tester);
        expect(find.text('Enter a valid phone number'), findsOneWidget, reason: bad);
      }
      expect(saved, isEmpty);

      for (final good in ['0092 300 1234567', '(042) 3576 1234']) {
        await tester.enterText(_field('Contact Number'), good);
        await save(tester);
        expect(find.text('Enter a valid phone number'), findsNothing, reason: good);
      }
      expect(saved.map((v) => v.contactNumber), ['0092 300 1234567', '(042) 3576 1234']);
    });
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
    expect(find.text('Too large (max 40)'), findsOneWidget);

    await tester.enterText(_field('Petrol').first, '2');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Add Station'));
    await tester.pumpAndSettle();
    expect(find.text('Enter a capacity above 0 for these nozzles'), findsOneWidget);
    expect(added, isEmpty);

    // Each capacity says what's wrong with it, whether or not its grade
    // has nozzles: Petrol has two, Diesel none.
    await tester.enterText(_field('Petrol').last, '-5');
    await tester.enterText(_field('Diesel').last, '-5');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Add Station'));
    await tester.pumpAndSettle();
    expect(find.text("Can't be negative"), findsNWidgets(2));

    await tester.enterText(_field('Petrol').last, '2,000,000');
    await tester.enterText(_field('Diesel').last, '');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Add Station'));
    await tester.pumpAndSettle();
    expect(find.text('Too large (max 1,000,000)'), findsOneWidget);
    expect(added, isEmpty);

    await tester.enterText(_field('Petrol').last, '20,000');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Add Station'));
    await tester.pumpAndSettle();
    expect(added, [20000]);
  });

  testWidgets('Logs: Save Log checks the form, then says saving is not available yet', (tester) async {
    final nozzle = _nozzle(1, 'Petrol');
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

  group('Logs', () {
    // A Petrol nozzle on pump 1 and a Diesel one on pump 2; no Hi-Octane.
    final petrol = _nozzle(1, 'Petrol');
    final diesel = _nozzle(2, 'Diesel');

    Future<void> open(WidgetTester tester, List<Nozzle> nozzles) =>
        _pump(tester, LogsScreen(stationName: 'Test', entries: const [], nozzles: nozzles, onNavTap: (_) {}));

    Finder dropdowns() => find.byWidgetPredicate((w) => w is DropdownButtonFormField);

    Future<void> choose(WidgetTester tester, int dropdown, String option) async {
      await tester.tap(dropdowns().at(dropdown));
      await tester.pumpAndSettle();
      await tester.tap(find.text(option).last);
      await tester.pumpAndSettle();
    }

    Future<void> saveLog(WidgetTester tester) async {
      await tester.tap(find.text('Save Log'));
      await tester.pumpAndSettle();
    }

    testWidgets('Pump / Nozzle offers only the chosen fuel\'s nozzles, and a fuel change clears it', (tester) async {
      await open(tester, [petrol, diesel]);
      // Disabled until a fuel is chosen.
      expect(find.text('Choose the fuel type first'), findsOneWidget);

      await choose(tester, 1, 'Petrol');
      await tester.tap(dropdowns().at(2));
      await tester.pumpAndSettle();
      expect(find.text(petrol.name), findsWidgets);
      expect(find.text(diesel.name), findsNothing);
      await tester.tap(find.text(petrol.name).last);
      await tester.pumpAndSettle();

      // A Petrol nozzle can't dispense Diesel, so it goes.
      await choose(tester, 1, 'Diesel');
      expect(find.text(petrol.name), findsNothing);
      await choose(tester, 0, 'Self');
      await tester.enterText(_field('Litres Dispensed (L)'), '100');
      await saveLog(tester);
      expect(find.text('Choose the pump and nozzle'), findsOneWidget);
      expect(find.text("Saving logs isn't available yet."), findsNothing);

      await choose(tester, 2, diesel.name);
      await saveLog(tester);
      expect(find.text("Saving logs isn't available yet."), findsOneWidget);
      expect(find.text('PKR 4,800'), findsOneWidget); // 100 L × the Diesel price
    });

    testWidgets('a fuel with no nozzles here says so, and the log can\'t be saved', (tester) async {
      await open(tester, [petrol, diesel]);
      await choose(tester, 0, 'Self');
      await choose(tester, 1, 'Hi-Octane');
      expect(find.text('No Hi-Octane nozzles at this station. Choose another fuel type.'), findsOneWidget);
      await tester.enterText(_field('Litres Dispensed (L)'), '100');
      await saveLog(tester);
      expect(find.text("Saving logs isn't available yet."), findsNothing);
    });

    testWidgets('a station with no nozzles says so in place of the dropdown', (tester) async {
      await open(tester, const []);
      expect(find.text('No nozzles set up for this station yet, so there is nothing to log.'), findsOneWidget);
      await choose(tester, 0, 'Self');
      await choose(tester, 1, 'Petrol');
      await tester.enterText(_field('Litres Dispensed (L)'), '100');
      await saveLog(tester);
      expect(find.text("Saving logs isn't available yet."), findsNothing);
    });

    testWidgets('litres are capped at the most one log may record', (tester) async {
      await open(tester, [petrol]);
      await tester.enterText(_field('Litres Dispensed (L)'), '50,001');
      await saveLog(tester);
      expect(find.text('Too large (max 50,000 L in one log)'), findsOneWidget);

      await tester.enterText(_field('Litres Dispensed (L)'), '50,000');
      await tester.pumpAndSettle();
      expect(find.text('Too large (max 50,000 L in one log)'), findsNothing);
    });
  });

  testWidgets('Login: both fields are required; Sign In then hands over the trimmed email', (tester) async {
    final signIns = <(String, String)>[];
    await _pump(tester, LoginScreen(onSignIn: (email, password) => signIns.add((email, password))));

    await tester.enterText(_field('Email / Username'), '   ');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Sign In'));
    await tester.pumpAndSettle();
    // The hints read the same as the errors, so the errors are read off
    // the fields.
    expect(_errorOf(tester, 'Email / Username'), 'Enter your email or username');
    expect(_errorOf(tester, 'Password'), 'Enter your password');
    expect(signIns, isEmpty);

    await tester.enterText(_field('Email / Username'), '  amir@gmail.com ');
    await tester.enterText(_field('Password'), 'secret123');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Sign In'));
    await tester.pumpAndSettle();
    expect(signIns, [('amir@gmail.com', 'secret123')]);
    expect(_errorOf(tester, 'Email / Username'), isNull);
    expect(_errorOf(tester, 'Password'), isNull);
  });

  testWidgets('Account Details: nothing is required, but what is typed is checked', (tester) async {
    final submitted = <AccountDetails>[];
    await _pump(tester, AccountDetailsScreen(stationName: 'Test', onSubmit: submitted.add));

    Future<void> submit() async {
      await tester.tap(find.text('Submit'));
      await tester.pumpAndSettle();
    }

    await submit();
    expect(submitted, hasLength(1)); // an empty form is fine

    await tester.enterText(_field('CNIC'), '35202-123');
    await tester.enterText(_field('Email Address'), 'owner@example');
    await tester.enterText(_field('No. Of Stations'), '-1');
    await tester.enterText(_field('No. Of Nozzles'), '99999999999999999999');
    await tester.enterText(_field('No. Of Managers'), '2.5');
    await submit();
    expect(find.text('Enter the 13-digit CNIC'), findsOneWidget);
    expect(find.text('Enter a valid email address'), findsOneWidget);
    expect(find.text("Can't be negative"), findsOneWidget);
    expect(find.text('Too large'), findsOneWidget);
    expect(find.text('Enter a whole number'), findsOneWidget);
    expect(submitted, hasLength(1));

    await tester.enterText(_field('CNIC'), '35202 1234567 1');
    await tester.enterText(_field('Email Address'), 'owner@example.com');
    await tester.enterText(_field('No. Of Stations'), '2');
    await tester.enterText(_field('No. Of Nozzles'), '۱۲'); // ۱۲
    await tester.enterText(_field('No. Of Managers'), '');
    await submit();
    expect(submitted, hasLength(2));
    expect(submitted.last.email, 'owner@example.com');
  });
}

/// An idle nozzle, number 1 on [pump], dispensing [fuel].
Nozzle _nozzle(int pump, String fuel) => Nozzle(
      id: 'p${pump}n1',
      pumpNumber: pump,
      nozzleNumber: 1,
      fuelName: fuel,
      litres: 0,
      flowRate: 0,
      lastUpdated: DateTime(2026),
      status: NozzleStatus.idle,
    );
