import '../models/sales.dart';

/// Each demo station's sales, keyed by stationId.
///
/// Every list runs oldest -> newest (see StationSalesData). Only the older
/// rows are typed here; the newest row of each wider period is DERIVED by
/// [_stationSales] from the period inside it, so the periods can't drift
/// apart:
///   today         = the last weekly row ('Day 7')
///   'Week 4'      = the sum of the 7 weekly rows
///   'Month 12'    = the sum of the 4 monthly rows
/// That is what keeps "Revenue Today" on the Dashboard equal to the end
/// point of its 7-day trend, and the Weekly, Monthly and Yearly reports
/// consistent with one another.
final demoSalesByStation = <String, StationSalesData>{
  'station-1': _stationSales(
    weekly: const [
      PeriodSales(label: 'Day 1', petrolL: 16800, dieselL: 8400, octaneL: 2750),
      PeriodSales(label: 'Day 2', petrolL: 17200, dieselL: 8600, octaneL: 2800),
      PeriodSales(label: 'Day 3', petrolL: 19500, dieselL: 9400, octaneL: 3100),
      PeriodSales(label: 'Day 4', petrolL: 19000, dieselL: 9200, octaneL: 3050),
      PeriodSales(label: 'Day 5', petrolL: 21000, dieselL: 9800, octaneL: 3300),
      PeriodSales(label: 'Day 6', petrolL: 22500, dieselL: 10200, octaneL: 3600),
      // Today. The tanks, the Nozzles tab and the tests read these figures:
      // Petrol 7,000 L left of 25,000 (critical), Diesel 16,000 (low) and
      // Hi-Octane 22,000 (healthy).
      PeriodSales(label: 'Day 7', petrolL: 18000, dieselL: 9000, octaneL: 3000),
    ],
    earlierWeeks: const [
      PeriodSales(label: 'Week 1', petrolL: 126000, dieselL: 63000, octaneL: 21000),
      PeriodSales(label: 'Week 2', petrolL: 131000, dieselL: 65000, octaneL: 21800),
      PeriodSales(label: 'Week 3', petrolL: 128500, dieselL: 64200, octaneL: 21500),
    ],
    earlierMonths: const [
      PeriodSales(label: 'Month 1', petrolL: 468000, dieselL: 232500, octaneL: 77800),
      PeriodSales(label: 'Month 2', petrolL: 455500, dieselL: 226000, octaneL: 75600),
      PeriodSales(label: 'Month 3', petrolL: 482000, dieselL: 239500, octaneL: 80300),
      PeriodSales(label: 'Month 4', petrolL: 491500, dieselL: 244000, octaneL: 81900),
      PeriodSales(label: 'Month 5', petrolL: 503000, dieselL: 249800, octaneL: 83700),
      PeriodSales(label: 'Month 6', petrolL: 515500, dieselL: 256000, octaneL: 85800),
      PeriodSales(label: 'Month 7', petrolL: 528000, dieselL: 262300, octaneL: 87900),
      PeriodSales(label: 'Month 8', petrolL: 521000, dieselL: 258800, octaneL: 86700),
      PeriodSales(label: 'Month 9', petrolL: 509500, dieselL: 253100, octaneL: 84800),
      PeriodSales(label: 'Month 10', petrolL: 524500, dieselL: 260600, octaneL: 87300),
      PeriodSales(label: 'Month 11', petrolL: 532000, dieselL: 264400, octaneL: 88600),
    ],
  ),
  // A second station under the same owner (or a different owner entirely)
  // with its own, completely separate figures - proof that the numbers
  // really do change per station rather than being one shared global set.
  'station-2': _stationSales(
    weekly: const [
      PeriodSales(label: 'Day 1', petrolL: 8400, dieselL: 4200, octaneL: 1380),
      PeriodSales(label: 'Day 2', petrolL: 8600, dieselL: 4300, octaneL: 1400),
      PeriodSales(label: 'Day 3', petrolL: 9700, dieselL: 4700, octaneL: 1550),
      PeriodSales(label: 'Day 4', petrolL: 9500, dieselL: 4600, octaneL: 1525),
      PeriodSales(label: 'Day 5', petrolL: 10500, dieselL: 4900, octaneL: 1650),
      PeriodSales(label: 'Day 6', petrolL: 11200, dieselL: 5100, octaneL: 1800),
      // Today.
      PeriodSales(label: 'Day 7', petrolL: 9000, dieselL: 4500, octaneL: 1500),
    ],
    earlierWeeks: const [
      PeriodSales(label: 'Week 1', petrolL: 63000, dieselL: 31500, octaneL: 10500),
      PeriodSales(label: 'Week 2', petrolL: 65500, dieselL: 32500, octaneL: 10900),
      PeriodSales(label: 'Week 3', petrolL: 64000, dieselL: 32000, octaneL: 10750),
    ],
    earlierMonths: const [
      PeriodSales(label: 'Month 1', petrolL: 233500, dieselL: 116000, octaneL: 38800),
      PeriodSales(label: 'Month 2', petrolL: 227000, dieselL: 112800, octaneL: 37700),
      PeriodSales(label: 'Month 3', petrolL: 241000, dieselL: 119600, octaneL: 40100),
      PeriodSales(label: 'Month 4', petrolL: 245500, dieselL: 121900, octaneL: 40900),
      PeriodSales(label: 'Month 5', petrolL: 251000, dieselL: 124700, octaneL: 41800),
      PeriodSales(label: 'Month 6', petrolL: 257500, dieselL: 127800, octaneL: 42800),
      PeriodSales(label: 'Month 7', petrolL: 263500, dieselL: 130900, octaneL: 43900),
      PeriodSales(label: 'Month 8', petrolL: 260000, dieselL: 129100, octaneL: 43300),
      PeriodSales(label: 'Month 9', petrolL: 254500, dieselL: 126300, octaneL: 42400),
      PeriodSales(label: 'Month 10', petrolL: 262000, dieselL: 130100, octaneL: 43600),
      PeriodSales(label: 'Month 11', petrolL: 265500, dieselL: 131800, octaneL: 44200),
    ],
  ),
};

/// One station's sales from its 7 days ([weekly], oldest first, today
/// last) and the older weeks and months. The newest week is the sum of
/// [weekly] and the newest month the sum of every week, so only the older
/// rows are ever typed. Today is the last day, relabelled 'Today'. Every
/// list is frozen so no screen can edit the shared demo data.
StationSalesData _stationSales({
  required List<PeriodSales> weekly,
  required List<PeriodSales> earlierWeeks,
  required List<PeriodSales> earlierMonths,
}) {
  final monthly = [
    ...earlierWeeks,
    PeriodSales.sum(weekly, label: 'Week ${earlierWeeks.length + 1}'),
  ];
  final yearly = [
    ...earlierMonths,
    PeriodSales.sum(monthly, label: 'Month ${earlierMonths.length + 1}'),
  ];
  return StationSalesData(
    today: List.unmodifiable([PeriodSales.sum([weekly.last], label: 'Today')]),
    weekly: List.unmodifiable(weekly),
    monthly: List.unmodifiable(monthly),
    yearly: List.unmodifiable(yearly),
  );
}

/// Looks up ONE station's data for a period, oldest row first. Returns an
/// empty list (never another station's numbers) for an unrecognized id -
/// e.g. a station that was just added and has no sales history yet.
List<PeriodSales> salesFor(String stationId, SalesReportPeriod period) =>
    demoSalesByStation[stationId]?.forPeriod(period) ?? const [];
