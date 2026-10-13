import 'delivery_vehicle.dart';

/// Healthy/Low/Critical is ALWAYS derived from currentVolume vs threshold
/// on TankStock (see the `health` getter below) - never stored separately,
/// same rule as revenue-from-litres elsewhere in this app, so the badge
/// can never drift out of sync with the numbers next to it.
enum TankHealth { healthy, low, critical }

/// The fixed setup of one physical tank: which grade it holds, how much it
/// can take and the level at which it should be reordered. It deliberately
/// has no current volume - that is derived from sales by `buildTanks` in
/// lib/data/demo_tanks.dart, so a config can never carry a stale reading.
class TankConfig {
  /// Unique across every station (e.g. 'station-1-petrol'), so a station
  /// can have two tanks of the same grade and per-tank settings such as a
  /// threshold override still land on the right one.
  final String id;
  final String fuelName;
  final double capacity;
  final double threshold;

  const TankConfig({
    required this.id,
    required this.fuelName,
    required this.capacity,
    required this.threshold,
  });
}

/// One tank as the screens show it: its config plus the derived current
/// volume.
class TankStock {
  final String id;
  final String fuelName;
  final double currentVolume;
  final double capacity;
  final double threshold;

  const TankStock({
    required this.id,
    required this.fuelName,
    required this.currentVolume,
    required this.capacity,
    required this.threshold,
  });

  /// 0.0-1.0 for the fill bar. A tank with no usable capacity (0 or less,
  /// e.g. a capacity typed in wrong) reads as empty rather than dividing by
  /// zero and handing NaN to the progress bar.
  double get percentFull => capacity > 0 ? (currentVolume / capacity).clamp(0.0, 1.0) : 0.0;

  /// Healthy at or above the threshold, Low down to half of it, Critical
  /// below that. A tank with no usable capacity can't hold any fuel, so it
  /// is always Critical - the badge then flags the bad setup instead of
  /// calling an impossible tank healthy.
  TankHealth get health {
    if (capacity <= 0) return TankHealth.critical;
    if (currentVolume >= threshold) return TankHealth.healthy;
    if (currentVolume >= threshold * 0.5) return TankHealth.low;
    return TankHealth.critical;
  }

  TankStock copyWith({
    String? id,
    String? fuelName,
    double? currentVolume,
    double? capacity,
    double? threshold,
  }) {
    return TankStock(
      id: id ?? this.id,
      fuelName: fuelName ?? this.fuelName,
      currentVolume: currentVolume ?? this.currentVolume,
      capacity: capacity ?? this.capacity,
      threshold: threshold ?? this.threshold,
    );
  }
}

/// Where a purchase order is in its life: placed but not yet received, or
/// received into the tank.
enum PurchaseOrderStatus { pending, delivered }

class PurchaseOrder {
  final String poNumber;
  final DateTime date;
  final String fuelName;
  final double litres;
  final DeliveryVehicle vehicle;
  final PurchaseOrderStatus status;

  const PurchaseOrder({
    required this.poNumber,
    required this.date,
    required this.fuelName,
    required this.litres,
    required this.vehicle,
    required this.status,
  });
}
