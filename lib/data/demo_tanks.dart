import '../models/sales.dart';
import '../models/tank_stock.dart';
import 'demo_sales.dart';

// Capacity and threshold match the Figma reference (25,000 L / 18,000 L
// for every tank) - wire these to real per-tank readings later (see the
// Logs screen discussion on fetching from the station's ATG system).
const _tankCapacity = 25000.0;
const _tankThreshold = 18000.0;

/// Builds this station's tank list with Current Volume ACTUALLY computed
/// from today's real sales - capacity minus whatever's been sold today for
/// that fuel, sourced from the exact same per-station daily sales data
/// Dashboard and Sales Reports already use (never a separate, hand-picked
/// number that could show a tank level unrelated to real sales). This
/// assumes the tank is topped up to capacity each day, consistent with the
/// Create Reorder / Recent Purchased Orders workflow on this same screen -
/// wire it to the real ATG reading (minus a running depletion feed) once
/// that's available, instead of the capacity-minus-today's-sales estimate.
List<TankStock> tanksForStation(String stationId) {
  final todayData = salesFor(stationId, SalesReportPeriod.today);
  final today = todayData.isNotEmpty ? todayData.first : null;

  double remaining(double soldToday) => (_tankCapacity - soldToday).clamp(0, _tankCapacity);

  return [
    TankStock(
      fuelName: 'Petrol',
      currentVolume: remaining(today?.petrolL ?? 0),
      capacity: _tankCapacity,
      threshold: _tankThreshold,
    ),
    TankStock(
      fuelName: 'Diesel',
      currentVolume: remaining(today?.dieselL ?? 0),
      capacity: _tankCapacity,
      threshold: _tankThreshold,
    ),
    TankStock(
      fuelName: 'Hi-Octane',
      currentVolume: remaining(today?.octaneL ?? 0),
      capacity: _tankCapacity,
      threshold: _tankThreshold,
    ),
  ];
}

const demoPurchaseOrders = [
  PurchaseOrder(poNumber: 'PO-2026-0058', date: '15 May 2026', fuelName: 'Diesel', litres: 20000, vehicle: DeliveryVehicle.carriage),
  PurchaseOrder(poNumber: 'PO-2026-0058', date: '15 May 2026', fuelName: 'Petrol', litres: 20000, vehicle: DeliveryVehicle.self),
  PurchaseOrder(poNumber: 'PO-2026-0058', date: '15 May 2026', fuelName: 'Hi-Octane', litres: 20000, vehicle: DeliveryVehicle.carriage),
];
