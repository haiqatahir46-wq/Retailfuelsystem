import '../models/sales.dart';

const demoSalesByStation = <String, StationSalesData>{
  'station-1': StationSalesData(
    today: [
      PeriodSales(label: 'Today', petrolL: 18000, dieselL: 9000, octaneL: 3000),
    ],
    weekly: [
      PeriodSales(label: 'Day 1', petrolL: 18000, dieselL: 9000, octaneL: 3000),
      PeriodSales(label: 'Day 2', petrolL: 18000, dieselL: 9000, octaneL: 3000),
      PeriodSales(label: 'Day 3', petrolL: 17200, dieselL: 8600, octaneL: 2800),
      PeriodSales(label: 'Day 4', petrolL: 19500, dieselL: 9400, octaneL: 3100),
      PeriodSales(label: 'Day 5', petrolL: 19000, dieselL: 9200, octaneL: 3050),
      PeriodSales(label: 'Day 6', petrolL: 21000, dieselL: 9800, octaneL: 3300),
      PeriodSales(label: 'Day 7', petrolL: 22500, dieselL: 10200, octaneL: 3600),
    ],
    monthly: [
      PeriodSales(label: 'Week 1', petrolL: 126000, dieselL: 63000, octaneL: 21000),
      PeriodSales(label: 'Week 2', petrolL: 131000, dieselL: 65000, octaneL: 21800),
      PeriodSales(label: 'Week 3', petrolL: 128500, dieselL: 64200, octaneL: 21500),
      PeriodSales(label: 'Week 4', petrolL: 138000, dieselL: 67800, octaneL: 22900),
    ],
    yearly: [
      PeriodSales(label: 'Month 1', petrolL: 523500, dieselL: 260000, octaneL: 87200),
      PeriodSales(label: 'Month 2', petrolL: 498000, dieselL: 247500, octaneL: 83400),
      PeriodSales(label: 'Month 3', petrolL: 541000, dieselL: 268800, octaneL: 90600),
      PeriodSales(label: 'Month 4', petrolL: 556200, dieselL: 276000, octaneL: 93100),
      PeriodSales(label: 'Month 5', petrolL: 562000, dieselL: 279500, octaneL: 94200),
      PeriodSales(label: 'Month 6', petrolL: 578000, dieselL: 287800, octaneL: 97000),
      PeriodSales(label: 'Month 7', petrolL: 591500, dieselL: 294200, octaneL: 99200),
      PeriodSales(label: 'Month 8', petrolL: 585000, dieselL: 291000, octaneL: 98100),
      PeriodSales(label: 'Month 9', petrolL: 602000, dieselL: 299500, octaneL: 101000),
      PeriodSales(label: 'Month 10', petrolL: 615500, dieselL: 306200, octaneL: 103400),
      PeriodSales(label: 'Month 11', petrolL: 609000, dieselL: 303000, octaneL: 102300),
      PeriodSales(label: 'Month 12', petrolL: 628000, dieselL: 312500, octaneL: 105600),
    ],
  ),
  // A second station under the same owner (or a different owner entirely)
  // with its own, completely separate figures - proof that the numbers
  // really do change per station rather than being one shared global set.
  'station-2': StationSalesData(
    today: [
      PeriodSales(label: 'Today', petrolL: 9000, dieselL: 4500, octaneL: 1500),
    ],
    weekly: [
      PeriodSales(label: 'Day 1', petrolL: 9000, dieselL: 4500, octaneL: 1500),
      PeriodSales(label: 'Day 2', petrolL: 9200, dieselL: 4600, octaneL: 1550),
      PeriodSales(label: 'Day 3', petrolL: 8600, dieselL: 4300, octaneL: 1400),
      PeriodSales(label: 'Day 4', petrolL: 9700, dieselL: 4700, octaneL: 1550),
      PeriodSales(label: 'Day 5', petrolL: 9500, dieselL: 4600, octaneL: 1525),
      PeriodSales(label: 'Day 6', petrolL: 10500, dieselL: 4900, octaneL: 1650),
      PeriodSales(label: 'Day 7', petrolL: 11200, dieselL: 5100, octaneL: 1800),
    ],
    monthly: [
      PeriodSales(label: 'Week 1', petrolL: 63000, dieselL: 31500, octaneL: 10500),
      PeriodSales(label: 'Week 2', petrolL: 65500, dieselL: 32500, octaneL: 10900),
      PeriodSales(label: 'Week 3', petrolL: 64000, dieselL: 32000, octaneL: 10750),
      PeriodSales(label: 'Week 4', petrolL: 69000, dieselL: 34000, octaneL: 11450),
    ],
    yearly: [
      PeriodSales(label: 'Month 1', petrolL: 261500, dieselL: 130000, octaneL: 43600),
      PeriodSales(label: 'Month 2', petrolL: 249000, dieselL: 123500, octaneL: 41700),
      PeriodSales(label: 'Month 3', petrolL: 270500, dieselL: 134400, octaneL: 45300),
      PeriodSales(label: 'Month 4', petrolL: 278000, dieselL: 138000, octaneL: 46550),
      PeriodSales(label: 'Month 5', petrolL: 281000, dieselL: 139500, octaneL: 47100),
      PeriodSales(label: 'Month 6', petrolL: 289000, dieselL: 143900, octaneL: 48500),
      PeriodSales(label: 'Month 7', petrolL: 295500, dieselL: 147000, octaneL: 49600),
      PeriodSales(label: 'Month 8', petrolL: 292500, dieselL: 145500, octaneL: 49050),
      PeriodSales(label: 'Month 9', petrolL: 301000, dieselL: 149500, octaneL: 50500),
      PeriodSales(label: 'Month 10', petrolL: 307500, dieselL: 153000, octaneL: 51700),
      PeriodSales(label: 'Month 11', petrolL: 304500, dieselL: 151500, octaneL: 51150),
      PeriodSales(label: 'Month 12', petrolL: 314000, dieselL: 156500, octaneL: 52800),
    ],
  ),
};

/// Looks up ONE station's data for a period. Returns an empty list (never
/// another station's numbers) for an unrecognized id - e.g. a station
/// that was just added and has no sales history yet.
List<PeriodSales> salesFor(String stationId, SalesReportPeriod period) =>
    demoSalesByStation[stationId]?.forPeriod(period) ?? const [];
