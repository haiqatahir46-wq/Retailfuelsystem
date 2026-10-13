import '../models/station.dart';
import 'demo_nozzles.dart';
import 'demo_tanks.dart';

/// The demo owner's stations. Their ids are the keys of every other demo
/// source (sales, tanks, orders, logs, nozzles), so each one shows its own
/// figures. The nozzle lists hold DateTimes and can't be const, so this
/// list is built once at first use and frozen.
final demoStations = List<Station>.unmodifiable([
  Station(
    id: 'station-1',
    name: 'Amir Filling, Pattoki',
    location: 'Pattoki, Punjab',
    tanks: demoTankConfigs['station-1']!,
    nozzles: nozzlesFor('station-1'),
  ),
  Station(
    id: 'station-2',
    name: 'Demo Station 2',
    tanks: demoTankConfigs['station-2']!,
    nozzles: nozzlesFor('station-2'),
  ),
]);
