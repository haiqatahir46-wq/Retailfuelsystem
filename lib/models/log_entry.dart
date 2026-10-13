enum LogStatus { completed, pending }

class VehicleLogEntry {
  final String vehicleType; // 'Self' or 'Carriage'
  final String fuelType;
  final String litres; // display value, e.g. '13,000L' - '-' if not dispensed yet
  final LogStatus status;

  const VehicleLogEntry({
    required this.vehicleType,
    required this.fuelType,
    required this.litres,
    required this.status,
  });
}
