import '../models/nozzle.dart';

// The last-update times are relative to app start, so "x min ago" reads
// sensibly whenever the demo runs. DateTime has no const constructor, so
// the lists are built once at first use and frozen so no screen can edit
// the shared demo data.
final _appStart = DateTime.now();

Nozzle _nozzle(
  String stationId,
  int pump,
  int nozzle,
  String fuelName,
  NozzleStatus status, {
  double litres = 0,
  double flowRate = 0,
  int minutesAgo = 1,
}) {
  return Nozzle(
    id: '$stationId-p${pump}n$nozzle',
    pumpNumber: pump,
    nozzleNumber: nozzle,
    fuelName: fuelName,
    litres: litres,
    flowRate: flowRate,
    lastUpdated: _appStart.subtract(Duration(minutes: minutesAgo)),
    status: status,
  );
}

final _demoNozzlesByStation = <String, List<Nozzle>>{
  // 12 nozzles: 8 dispensing, 3 idle, 1 fault.
  'station-1': List.unmodifiable([
    _nozzle('station-1', 1, 1, 'Petrol', NozzleStatus.dispensing, litres: 12.76, flowRate: 32.4),
    _nozzle('station-1', 1, 2, 'Petrol', NozzleStatus.idle, minutesAgo: 5),
    _nozzle('station-1', 2, 1, 'Petrol', NozzleStatus.dispensing, litres: 24.10, flowRate: 30.8),
    _nozzle('station-1', 2, 2, 'Petrol', NozzleStatus.dispensing, litres: 8.35, flowRate: 28.9),
    _nozzle('station-1', 3, 1, 'Petrol', NozzleStatus.dispensing, litres: 40.02, flowRate: 33.1, minutesAgo: 2),
    _nozzle('station-1', 3, 2, 'Petrol', NozzleStatus.fault, minutesAgo: 42),
    _nozzle('station-1', 4, 1, 'Diesel', NozzleStatus.dispensing, litres: 55.60, flowRate: 38.5),
    _nozzle('station-1', 4, 2, 'Diesel', NozzleStatus.dispensing, litres: 18.20, flowRate: 36.0),
    _nozzle('station-1', 5, 1, 'Diesel', NozzleStatus.idle, minutesAgo: 12),
    _nozzle('station-1', 5, 2, 'Diesel', NozzleStatus.dispensing, litres: 9.75, flowRate: 35.2),
    _nozzle('station-1', 6, 1, 'Hi-Octane', NozzleStatus.dispensing, litres: 15.30, flowRate: 29.7, minutesAgo: 3),
    _nozzle('station-1', 6, 2, 'Hi-Octane', NozzleStatus.idle, minutesAgo: 8),
  ]),
  // 8 nozzles: 5 dispensing, 2 idle, 1 fault.
  'station-2': List.unmodifiable([
    _nozzle('station-2', 1, 1, 'Petrol', NozzleStatus.dispensing, litres: 10.40, flowRate: 31.0),
    _nozzle('station-2', 1, 2, 'Petrol', NozzleStatus.idle, minutesAgo: 7),
    _nozzle('station-2', 2, 1, 'Petrol', NozzleStatus.dispensing, litres: 22.85, flowRate: 32.2),
    _nozzle('station-2', 2, 2, 'Petrol', NozzleStatus.dispensing, litres: 6.10, flowRate: 27.5, minutesAgo: 2),
    _nozzle('station-2', 3, 1, 'Diesel', NozzleStatus.dispensing, litres: 30.00, flowRate: 37.4),
    _nozzle('station-2', 3, 2, 'Diesel', NozzleStatus.fault, minutesAgo: 25),
    _nozzle('station-2', 4, 1, 'Hi-Octane', NozzleStatus.dispensing, litres: 12.25, flowRate: 28.8),
    _nozzle('station-2', 4, 2, 'Hi-Octane', NozzleStatus.idle, minutesAgo: 15),
  ]),
};

/// This station's nozzles across every grade. The demo stations
/// (demo_stations.dart) carry these, so the Dashboard's "active / total"
/// count and the Nozzles tab, which both read AppSession.nozzlesFor, can't
/// disagree. An unknown id gives an empty list, never another station's
/// nozzles.
List<Nozzle> nozzlesFor(String stationId) => _demoNozzlesByStation[stationId] ?? const [];
