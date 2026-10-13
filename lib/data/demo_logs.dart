import '../models/log_entry.dart';

const demoLogEntries = [
  VehicleLogEntry(vehicleType: 'Self', fuelType: 'Petrol', litres: '13,000L', status: LogStatus.completed),
  VehicleLogEntry(vehicleType: 'Carriage', fuelType: 'Diesel', litres: '5,000L', status: LogStatus.completed),
  VehicleLogEntry(vehicleType: 'Self', fuelType: 'Hi-Octane', litres: '-', status: LogStatus.pending),
  VehicleLogEntry(vehicleType: 'Carriage', fuelType: 'Diesel', litres: '5,000L', status: LogStatus.completed),
  VehicleLogEntry(vehicleType: 'Carriage', fuelType: 'Diesel', litres: '5,000L', status: LogStatus.completed),
];
