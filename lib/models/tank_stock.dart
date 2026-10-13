/// Healthy/Low/Critical is ALWAYS derived from currentVolume vs threshold
/// on TankStock (see the `health` getter below) - never stored separately,
/// same rule as revenue-from-litres elsewhere in this app, so the badge
/// can never drift out of sync with the numbers next to it.
enum TankHealth { healthy, low, critical }

class TankStock {
  final String fuelName;
  final double currentVolume;
  final double capacity;
  final double threshold;

  const TankStock({
    required this.fuelName,
    required this.currentVolume,
    required this.capacity,
    required this.threshold,
  });

  double get percentFull => (currentVolume / capacity).clamp(0, 1);

  TankHealth get health {
    if (currentVolume >= threshold) return TankHealth.healthy;
    if (currentVolume >= threshold * 0.5) return TankHealth.low;
    return TankHealth.critical;
  }
}

enum DeliveryVehicle { self, carriage }

class PurchaseOrder {
  final String poNumber;
  final String date;
  final String fuelName;
  final double litres;
  final DeliveryVehicle vehicle;

  const PurchaseOrder({
    required this.poNumber,
    required this.date,
    required this.fuelName,
    required this.litres,
    required this.vehicle,
  });
}
