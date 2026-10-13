enum NozzleStatus { dispensing, idle, fault }

/// One nozzle on one pump, as the Nozzles tab lists it. Holds values, not
/// display text: the screen formats litres, flow and the update time.
class Nozzle {
  /// Unique across every station, e.g. 'station-1-p1n1'.
  final String id;
  final int pumpNumber;
  final int nozzleNumber;

  /// One of kFuelGrades in lib/models/sales.dart.
  final String fuelName;

  /// Litres dispensed in the current (or most recent) transaction.
  final double litres;

  /// Current flow rate in litres per minute; 0 when not dispensing.
  final double flowRate;

  /// When the pump last reported this nozzle's reading.
  final DateTime lastUpdated;
  final NozzleStatus status;

  const Nozzle({
    required this.id,
    required this.pumpNumber,
    required this.nozzleNumber,
    required this.fuelName,
    required this.litres,
    required this.flowRate,
    required this.lastUpdated,
    required this.status,
  });

  /// Display name, e.g. "Pump 1 · Nozzle 2".
  String get name => 'Pump $pumpNumber · Nozzle $nozzleNumber';
}
