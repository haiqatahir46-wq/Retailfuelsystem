import '../models/delivery_vehicle.dart';
import '../models/log_entry.dart';

/// Each demo station's vehicle log, keyed by stationId like every other
/// demo source.
const _demoLogsByStation = <String, List<VehicleLogEntry>>{
  'station-1': [
    VehicleLogEntry(vehicle: DeliveryVehicle.self, fuelType: 'Petrol', litres: 13000, status: LogStatus.completed),
    VehicleLogEntry(vehicle: DeliveryVehicle.carriage, fuelType: 'Diesel', litres: 5000, status: LogStatus.completed),
    VehicleLogEntry(vehicle: DeliveryVehicle.self, fuelType: 'Hi-Octane', litres: null, status: LogStatus.pending),
    VehicleLogEntry(vehicle: DeliveryVehicle.carriage, fuelType: 'Diesel', litres: 5000, status: LogStatus.completed),
    VehicleLogEntry(vehicle: DeliveryVehicle.carriage, fuelType: 'Diesel', litres: 5000, status: LogStatus.completed),
  ],
  'station-2': [
    VehicleLogEntry(vehicle: DeliveryVehicle.carriage, fuelType: 'Petrol', litres: 8000, status: LogStatus.completed),
    VehicleLogEntry(vehicle: DeliveryVehicle.self, fuelType: 'Diesel', litres: null, status: LogStatus.pending),
    VehicleLogEntry(vehicle: DeliveryVehicle.self, fuelType: 'Hi-Octane', litres: 2500, status: LogStatus.completed),
  ],
};

/// This station's recent vehicle log entries. An unknown id gives an empty
/// list, never another station's entries.
List<VehicleLogEntry> logsFor(String stationId) => _demoLogsByStation[stationId] ?? const [];
