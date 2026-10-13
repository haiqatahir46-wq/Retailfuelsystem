enum SalesReportPeriod { today, weekly, monthly, yearly }

// ---- The pricing model. Revenue is ALWAYS derived from litres - never
// stored as a separate number - so it can never drift out of sync with
// the litres it's supposed to represent. Swap these for real per-station
// prices (e.g. from FMS-06's price_history) when wiring up live data. ----
const kPetrolPricePerLitre = 50.0; // PKR/L
const kDieselPricePerLitre = 48.0; // PKR/L
const kHiOctanePricePerLitre = 60.0; // PKR/L

/// One row of sales data for a period (a day, a week, or a month) - litres
/// only. Revenue is computed on demand via the getters below:
/// revenue = litres × price per litre, the same formula as the FYP
/// proposal's business rules ("Sale amount = liters sold × selling price
/// per liter").
class PeriodSales {
  final String label;
  final double petrolL;
  final double dieselL;
  final double octaneL;

  const PeriodSales({
    required this.label,
    required this.petrolL,
    required this.dieselL,
    required this.octaneL,
  });

  double get petrolRevenue => petrolL * kPetrolPricePerLitre;
  double get dieselRevenue => dieselL * kDieselPricePerLitre;
  double get octaneRevenue => octaneL * kHiOctanePricePerLitre;
  double get totalRevenue => petrolRevenue + dieselRevenue + octaneRevenue;
}

// ---- Per-station demo data. This is the core rule of the whole sales
// module: an owner must ONLY ever see the figures for the station(s) they
// own - never another owner's station, never a company-wide total unless
// they explicitly own every station in it. This map simulates that
// scoping on the client by keying every period's data on stationId. In
// production the authoritative filter MUST live in the backend query
// (e.g. `WHERE station_id = :id AND owner_id = :currentUser`) and be
// enforced server-side - a client that only *displays* the right data
// but queries an API that returns everyone's data is not actually
// secure, since the raw response could still be read from the network. ----
class StationSalesData {
  final List<PeriodSales> today;
  final List<PeriodSales> weekly;
  final List<PeriodSales> monthly;
  final List<PeriodSales> yearly;
  final List<double> weekTrend; // for the Dashboard's 7-day trend chart
  final String activePumps; // e.g. '8 / 12'

  const StationSalesData({
    required this.today,
    required this.weekly,
    required this.monthly,
    required this.yearly,
    required this.weekTrend,
    required this.activePumps,
  });

  List<PeriodSales> forPeriod(SalesReportPeriod period) {
    switch (period) {
      case SalesReportPeriod.today:
        return today;
      case SalesReportPeriod.weekly:
        return weekly;
      case SalesReportPeriod.monthly:
        return monthly;
      case SalesReportPeriod.yearly:
        return yearly;
    }
  }
}

/// 'Today', 'Weekly', 'Monthly' or 'Yearly' - shared by the sales report
/// screens and the Dashboard's own period dropdown.
String periodLabel(SalesReportPeriod p) {
  switch (p) {
    case SalesReportPeriod.today:
      return 'Today';
    case SalesReportPeriod.weekly:
      return 'Weekly';
    case SalesReportPeriod.monthly:
      return 'Monthly';
    case SalesReportPeriod.yearly:
      return 'Yearly';
  }
}

/// Adds thousands separators, e.g. 1512000 -> "1,512,000".
String formatThousands(double v) => v.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (m) => ',',
    );
