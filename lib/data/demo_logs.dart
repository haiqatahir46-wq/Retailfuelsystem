import '../models/delivery_vehicle.dart';
import '../models/log_entry.dart';

/// Each demo station's vehicle log for today, keyed by stationId like every
/// other demo source.
///
/// The entries are part of today's sales, so the completed litres of each
/// grade stay within what that station sold of it today (demo_sales.dart):
/// station-1 logs 13,000 of its 18,000 L of Petrol and 8,500 of its
/// 9,000 L of Diesel; station-2 logs 8,000 of its 9,000 L of Petrol and
/// 1,200 of its 1,500 L of Hi-Octane. test/demo_data_test.dart checks it.
const _demoLogsByStation = <String, List<VehicleLogEntry>>{
  'station-1': [
    VehicleLogEntry(vehicle: DeliveryVehicle.self, fuelType: 'Petrol', litres: 13000, status: LogStatus.completed),
    VehicleLogEntry(vehicle: DeliveryVehicle.carriage, fuelType: 'Diesel', litres: 4000, status: LogStatus.completed),
    VehicleLogEntry(vehicle: DeliveryVehicle.self, fuelType: 'Hi-Octane', litres: null, status: LogStatus.pending),
    VehicleLogEntry(vehicle: DeliveryVehicle.carriage, fuelType: 'Diesel', litres: 3000, status: LogStatus.completed),
    VehicleLogEntry(vehicle: DeliveryVehicle.carriage, fuelType: 'Diesel', litres: 1500, status: LogStatus.completed),
  ],
  'station-2': [
    VehicleLogEntry(vehicle: DeliveryVehicle.carriage, fuelType: 'Petrol', litres: 8000, status: LogStatus.completed),
    VehicleLogEntry(vehicle: DeliveryVehicle.self, fuelType: 'Diesel', litres: null, status: LogStatus.pending),
    VehicleLogEntry(vehicle: DeliveryVehicle.self, fuelType: 'Hi-Octane', litres: 1200, status: LogStatus.completed),
  ],
};

/// This station's recent vehicle log entries. An unknown id gives an empty
/// list, never another station's entries.
List<VehicleLogEntry> logsFor(String stationId) => _demoLogsByStation[stationId] ?? const [];
