import 'delivery_vehicle.dart';

enum LogStatus { completed, pending }

/// One row of the Logs screen's vehicle log. Holds values, not display text:
/// the screen formats [litres] with formatThousands.
class VehicleLogEntry {
  final DeliveryVehicle vehicle;
  final String fuelType;

  /// Litres dispensed, or null when nothing has been dispensed yet (a
  /// pending entry). Null rather than 0 so "not yet" and "zero litres"
  /// stay distinguishable.
  final double? litres;
  final LogStatus status;

  /// The most litres one log entry may record. The largest road tankers
  /// carry around 50,000 L, so no single vehicle takes more in one go;
  /// anything bigger is a typing slip. For the Logs form's Litres
  /// Dispensed validator.
  static const maxLitres = 50000.0;

  const VehicleLogEntry({
    required this.vehicle,
    required this.fuelType,
    required this.litres,
    required this.status,
  });
}
