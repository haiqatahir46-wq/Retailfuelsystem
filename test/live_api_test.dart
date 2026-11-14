import 'package:flutter_test/flutter_test.dart';
import 'package:petrolpump_flutter/models/sales.dart';
import 'package:petrolpump_flutter/services/api_client.dart';
import 'package:petrolpump_flutter/state/app_session.dart';

/// The running API server to test against, e.g.
///   flutter test test/live_api_test.dart --dart-define=LIVE_API=http://localhost:8080
/// with the backend running (`start_server.bat` in C:\Flutter\parco_fuel_backend)
/// and the demo data loaded (`.venv\Scripts\python.exe -m app.migrate --seed`
/// there). Skipped otherwise, so the normal
/// test run never needs the network.
const _liveApi = String.fromEnvironment('LIVE_API');

void main() {
  test(
    'signs in to the real server and loads what every tab shows',
    () async {
      final session = AppSession(api: ApiClient(baseUrl: _liveApi));
      addTearDown(session.dispose);
      await session.signIn(email: 'owner@parco.example', password: 'demo1234');

      expect(session.owner!.email, 'owner@parco.example');
      expect(session.stations.map((s) => s.name), contains('Amir Filling, Pattoki'));
      expect(session.staff, isNotEmpty);
      final id = session.currentStationId!;
      expect(session.hasDataFor(id), isTrue, reason: session.loadErrorFor(id));

      final tanks = session.tanksFor(id);
      expect(tanks.map((t) => t.fuelName), ['Petrol', 'Diesel', 'Hi-Octane']);
      expect(tanks.every((t) => t.currentVolume >= 0 && t.currentVolume <= t.capacity), isTrue);
      expect(session.nozzlesFor(id), isNotEmpty);
      expect(session.purchaseOrdersFor(id), isNotEmpty);
      final weekly = session.salesFor(id, SalesReportPeriod.weekly);
      expect(weekly, hasLength(7));
      // The last weekly row is today: the Dashboard's trend ends on Revenue Today.
      final today = PeriodSales.sum(session.salesFor(id, SalesReportPeriod.today));
      expect(weekly.last.totalLitres, closeTo(today.totalLitres, 0.01));

      // Switching station loads that station's own figures.
      final other = session.stations.firstWhere((s) => s.id != id);
      session.selectStation(other.id);
      while (session.isLoading(other.id)) {
        await Future<void>.delayed(const Duration(milliseconds: 50));
      }
      expect(session.hasDataFor(other.id), isTrue, reason: session.loadErrorFor(other.id));
      expect(session.tanksFor(other.id).map((t) => t.id).toSet().intersection(tanks.map((t) => t.id).toSet()), isEmpty);
    },
    skip: _liveApi.isEmpty ? 'Set --dart-define=LIVE_API=<server URL> with the server running' : false,
    timeout: const Timeout(Duration(minutes: 1)),
  );
}
