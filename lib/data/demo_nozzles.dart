import '../models/nozzle.dart';

/// One demo nozzle as typed below: everything but its update time, which is
/// kept as [minutesAgo] and only turned into a DateTime when the nozzle is
/// read (see [nozzlesFor]).
class _DemoNozzle {
  final int pump;
  final int nozzle;
  final String fuelName;
  final NozzleStatus status;
  final double litres;
  final double flowRate;
  final int minutesAgo;

  const _DemoNozzle(
    this.pump,
    this.nozzle,
    this.fuelName,
    this.status, {
    this.litres = 0,
    this.flowRate = 0,
    this.minutesAgo = 1,
  });

  Nozzle at(String stationId, DateTime now) => Nozzle(
        id: '$stationId-p${pump}n$nozzle',
        pumpNumber: pump,
        nozzleNumber: nozzle,
        fuelName: fuelName,
        litres: litres,
        flowRate: flowRate,
        lastUpdated: now.subtract(Duration(minutes: minutesAgo)),
        status: status,
      );
}

const _demoNozzlesByStation = <String, List<_DemoNozzle>>{
  // 12 nozzles: 8 dispensing, 3 idle, 1 fault.
  'station-1': [
    _DemoNozzle(1, 1, 'Petrol', NozzleStatus.dispensing, litres: 12.76, flowRate: 32.4),
    _DemoNozzle(1, 2, 'Petrol', NozzleStatus.idle, minutesAgo: 5),
    _DemoNozzle(2, 1, 'Petrol', NozzleStatus.dispensing, litres: 24.10, flowRate: 30.8),
    _DemoNozzle(2, 2, 'Petrol', NozzleStatus.dispensing, litres: 8.35, flowRate: 28.9),
    _DemoNozzle(3, 1, 'Petrol', NozzleStatus.dispensing, litres: 40.02, flowRate: 33.1, minutesAgo: 2),
    _DemoNozzle(3, 2, 'Petrol', NozzleStatus.fault, minutesAgo: 42),
    _DemoNozzle(4, 1, 'Diesel', NozzleStatus.dispensing, litres: 55.60, flowRate: 38.5),
    _DemoNozzle(4, 2, 'Diesel', NozzleStatus.dispensing, litres: 18.20, flowRate: 36.0),
    _DemoNozzle(5, 1, 'Diesel', NozzleStatus.idle, minutesAgo: 12),
    _DemoNozzle(5, 2, 'Diesel', NozzleStatus.dispensing, litres: 9.75, flowRate: 35.2),
    _DemoNozzle(6, 1, 'Hi-Octane', NozzleStatus.dispensing, litres: 15.30, flowRate: 29.7, minutesAgo: 3),
    _DemoNozzle(6, 2, 'Hi-Octane', NozzleStatus.idle, minutesAgo: 8),
  ],
  // 8 nozzles: 5 dispensing, 2 idle, 1 fault.
  'station-2': [
    _DemoNozzle(1, 1, 'Petrol', NozzleStatus.dispensing, litres: 10.40, flowRate: 31.0),
    _DemoNozzle(1, 2, 'Petrol', NozzleStatus.idle, minutesAgo: 7),
    _DemoNozzle(2, 1, 'Petrol', NozzleStatus.dispensing, litres: 22.85, flowRate: 32.2),
    _DemoNozzle(2, 2, 'Petrol', NozzleStatus.dispensing, litres: 6.10, flowRate: 27.5, minutesAgo: 2),
    _DemoNozzle(3, 1, 'Diesel', NozzleStatus.dispensing, litres: 30.00, flowRate: 37.4),
    _DemoNozzle(3, 2, 'Diesel', NozzleStatus.fault, minutesAgo: 25),
    _DemoNozzle(4, 1, 'Hi-Octane', NozzleStatus.dispensing, litres: 12.25, flowRate: 28.8),
    _DemoNozzle(4, 2, 'Hi-Octane', NozzleStatus.idle, minutesAgo: 15),
  ],
};

/// This station's nozzles across every grade, as the latest pump readings.
///
/// Each call builds a fresh, frozen list stamped from DateTime.now(), so a
/// nozzle typed as "1 min ago" still reads "1 min ago" however long the app
/// has been running, the way a live pump feed would. (Stamping them once,
/// at first use, made them drift to "31 min ago" over half an hour.)
/// AppSession.nozzlesFor reads this on every call for the same reason,
/// so the Dashboard's "active / total" count and the Nozzles tab, which
/// both read it, can't disagree. An unknown id gives an empty list, never
/// another station's nozzles.
List<Nozzle> nozzlesFor(String stationId) {
  final nozzles = _demoNozzlesByStation[stationId];
  if (nozzles == null) return const [];
  final now = DateTime.now();
  return List.unmodifiable([for (final n in nozzles) n.at(stationId, now)]);
}
