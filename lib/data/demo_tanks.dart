import '../models/delivery_vehicle.dart';
import '../models/sales.dart';
import '../models/tank_stock.dart';
import 'demo_sales.dart';

/// Each demo station's tanks. Capacity and threshold match the Figma
/// reference (25,000 L / 18,000 L for every tank) - wire these to the real
/// per-tank setup later. Keyed by stationId like every other demo source,
/// so a station that isn't listed has no tanks at all rather than borrowing
/// another station's.
const demoTankConfigs = <String, List<TankConfig>>{
  'station-1': [
    TankConfig(id: 'station-1-petrol', fuelName: 'Petrol', capacity: 25000, threshold: 18000),
    TankConfig(id: 'station-1-diesel', fuelName: 'Diesel', capacity: 25000, threshold: 18000),
    TankConfig(id: 'station-1-hi-octane', fuelName: 'Hi-Octane', capacity: 25000, threshold: 18000),
  ],
  'station-2': [
    TankConfig(id: 'station-2-petrol', fuelName: 'Petrol', capacity: 25000, threshold: 18000),
    TankConfig(id: 'station-2-diesel', fuelName: 'Diesel', capacity: 25000, threshold: 18000),
    TankConfig(id: 'station-2-hi-octane', fuelName: 'Hi-Octane', capacity: 25000, threshold: 18000),
  ],
};

/// Turns tank configs into the tanks the screens show, with Current Volume
/// ACTUALLY computed from sales: capacity minus the litres of that tank's
/// grade sold [today], clamped to 0..capacity. [today] is the day's
/// combined row (see PeriodSales.sum); null means nothing sold yet, so
/// every tank reads full. A threshold in [thresholdOverrides], keyed by
/// tank id, replaces that tank's configured threshold.
///
/// This assumes each tank is topped up to capacity every day, consistent
/// with the Create Reorder / Recent Purchased Orders workflow on Stock -
/// wire it to the real ATG reading (minus a running depletion feed) once
/// that's available, instead of the capacity-minus-today's-sales estimate.
///
/// Pure: same inputs, same tanks, nothing read from anywhere else - so the
/// demo lookup below and any in-memory store (with its own configs and
/// overrides) produce numbers the same way.
List<TankStock> buildTanks({
  required List<TankConfig> configs,
  required PeriodSales? today,
  Map<String, double> thresholdOverrides = const {},
}) {
  return [for (final c in configs) _tankFrom(c, today, thresholdOverrides)];
}

TankStock _tankFrom(TankConfig c, PeriodSales? today, Map<String, double> thresholdOverrides) {
  // A capacity of 0 or less can't hold anything; flooring it at 0 also
  // keeps clamp's bounds valid (clamp throws if lower > upper).
  final usable = c.capacity > 0 ? c.capacity : 0.0;
  final sold = today?.litresOf(c.fuelName) ?? 0.0;
  return TankStock(
    id: c.id,
    fuelName: c.fuelName,
    currentVolume: (usable - sold).clamp(0.0, usable),
    capacity: c.capacity,
    threshold: thresholdOverrides[c.id] ?? c.threshold,
  );
}

/// This station's tanks, from its demo configs and today's sales (every
/// "today" row combined, so this agrees with the Dashboard and the Today
/// report). The app's screens read AppSession.tanksFor instead, which runs
/// buildTanks the same way on the session's own station setup and
/// thresholds, so the two give the same numbers for a demo station. An
/// unknown id gives an empty list - never made-up full tanks.
List<TankStock> tanksForStation(
  String stationId, {
  Map<String, double> thresholdOverrides = const {},
}) {
  final configs = demoTankConfigs[stationId] ?? const <TankConfig>[];
  if (configs.isEmpty) return const [];
  return buildTanks(
    configs: configs,
    today: PeriodSales.sum(salesFor(stationId, SalesReportPeriod.today), label: 'Today'),
    thresholdOverrides: thresholdOverrides,
  );
}

// DateTime has no const constructor, so these lists are built once at
// first use and frozen so no screen can edit the shared demo data.
//
// A pending order is fuel on its way into a tank, so it must fit in the
// room that tank has today (capacity minus today's sales, demo_sales.dart):
// station-1's Petrol tank has 18,000 L of room and 15,000 L on order;
// station-2's Petrol tank has 9,000 L of room and 8,000 L on order. Each
// is the station's lowest tank, the one an owner would actually reorder.
// test/demo_data_test.dart checks every pending order fits.
final _demoPurchaseOrders = <String, List<PurchaseOrder>>{
  'station-1': List.unmodifiable([
    PurchaseOrder(
      poNumber: 'PO-2026-0063',
      date: DateTime(2026, 5, 22),
      tankId: 'station-1-petrol',
      fuelName: 'Petrol',
      litres: 15000,
      vehicle: DeliveryVehicle.carriage,
      status: PurchaseOrderStatus.pending,
    ),
    PurchaseOrder(
      poNumber: 'PO-2026-0061',
      date: DateTime(2026, 5, 18),
      tankId: 'station-1-petrol',
      fuelName: 'Petrol',
      litres: 20000,
      vehicle: DeliveryVehicle.self,
      status: PurchaseOrderStatus.delivered,
    ),
    PurchaseOrder(
      poNumber: 'PO-2026-0058',
      date: DateTime(2026, 5, 15),
      tankId: 'station-1-diesel',
      fuelName: 'Diesel',
      litres: 20000,
      vehicle: DeliveryVehicle.carriage,
      status: PurchaseOrderStatus.delivered,
    ),
  ]),
  'station-2': List.unmodifiable([
    PurchaseOrder(
      poNumber: 'PO-2026-0062',
      date: DateTime(2026, 5, 20),
      tankId: 'station-2-petrol',
      fuelName: 'Petrol',
      litres: 8000,
      vehicle: DeliveryVehicle.self,
      status: PurchaseOrderStatus.pending,
    ),
    PurchaseOrder(
      poNumber: 'PO-2026-0059',
      date: DateTime(2026, 5, 16),
      tankId: 'station-2-petrol',
      fuelName: 'Petrol',
      litres: 12000,
      vehicle: DeliveryVehicle.carriage,
      status: PurchaseOrderStatus.delivered,
    ),
  ]),
};

/// This station's recent purchase orders, newest first. An unknown id
/// gives an empty list, never another station's orders.
List<PurchaseOrder> purchaseOrdersFor(String stationId) => _demoPurchaseOrders[stationId] ?? const [];
