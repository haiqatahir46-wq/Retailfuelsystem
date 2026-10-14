import '../models/station.dart';
import 'demo_nozzles.dart';
import 'demo_tanks.dart';

/// The demo owner's stations. Their ids are the keys of every other demo
/// source (sales, tanks, orders, logs, nozzles), so each one shows its own
/// figures. The nozzle lists hold DateTimes and can't be const, so this
/// list is built once at first use and frozen.
///
/// Each station's `nozzles` is its setup (which nozzles exist), stamped
/// when this list was built. The screens don't show those stamps:
/// AppSession.nozzlesFor reads a demo station's nozzles afresh from
/// nozzlesFor on every call, so "x min ago" stays measured from now.
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
