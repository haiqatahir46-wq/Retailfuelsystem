enum SalesReportPeriod { today, weekly, monthly, yearly }

// ---- The pricing model. Revenue is ALWAYS derived from litres - never
// stored as a separate number - so it can never drift out of sync with
// the litres it's supposed to represent. Swap these for real per-station
// prices (e.g. from FMS-06's price_history) when wiring up live data. ----
const kPetrolPricePerLitre = 50.0; // PKR/L
const kDieselPricePerLitre = 48.0; // PKR/L
const kHiOctanePricePerLitre = 60.0; // PKR/L

/// The three fuel grades the app tracks, by the exact names used on tanks,
/// nozzles, purchase orders and logs. Matching on these strings is how a
/// tank or a log entry finds its price and its share of a day's sales.
const kFuelGrades = ['Petrol', 'Diesel', 'Hi-Octane'];

/// Selling price (PKR/L) for one of [kFuelGrades]. Returns 0 for any other
/// name, so an unrecognised grade shows "PKR 0" instead of crashing the
/// screen that asked.
double pricePerLitre(String fuelName) {
  switch (fuelName) {
    case 'Petrol':
      return kPetrolPricePerLitre;
    case 'Diesel':
      return kDieselPricePerLitre;
    case 'Hi-Octane':
      return kHiOctanePricePerLitre;
    default:
      return 0;
  }
}

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

  /// Combines several rows of one period into a single row, e.g. every
  /// "today" row for a station (one per shift once shifts exist) into the
  /// day's total. Everything that reads "today" goes through this - the
  /// Dashboard, the tank levels and the sales report - so they always add
  /// up the same rows and can't disagree. An empty list gives all zeros.
  static PeriodSales sum(List<PeriodSales> rows, {String label = ''}) {
    var petrol = 0.0;
    var diesel = 0.0;
    var octane = 0.0;
    for (final r in rows) {
      petrol += r.petrolL;
      diesel += r.dieselL;
      octane += r.octaneL;
    }
    return PeriodSales(label: label, petrolL: petrol, dieselL: diesel, octaneL: octane);
  }

  double get totalLitres => petrolL + dieselL + octaneL;

  /// Litres sold of one grade (see [kFuelGrades]); 0 for any other name.
  double litresOf(String fuelName) {
    switch (fuelName) {
      case 'Petrol':
        return petrolL;
      case 'Diesel':
        return dieselL;
      case 'Hi-Octane':
        return octaneL;
      default:
        return 0;
    }
  }

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

  const StationSalesData({
    required this.today,
    required this.weekly,
    required this.monthly,
    required this.yearly,
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

/// 'Today', 'Weekly', 'Monthly' or 'Yearly' - the Dashboard's period
/// dropdown and its report cards (lib/widgets/sales_report_widgets.dart).
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

/// Adds thousands separators, e.g. 1512000 -> "1,512,000". Rounds to a
/// whole number first. The one number formatter for the whole app - screens
/// call this rather than keeping their own copy.
String formatThousands(double v) => v.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (m) => ',',
    );

/// A short number for a chart axis: 950 -> "950", 1500 -> "1.5k",
/// 20000 -> "20k", 2400000 -> "2.4M". Use [formatThousands] anywhere the
/// exact figure matters.
String formatCompact(double v) {
  const units = [(1e9, 'B'), (1e6, 'M'), (1e3, 'k')];
  for (final (size, suffix) in units) {
    if (v.abs() >= size) return '${_oneDecimal(v / size)}$suffix';
  }
  return _oneDecimal(v);
}

/// One decimal place below 10 and none from 10 up, never a trailing ".0".
String _oneDecimal(double x) {
  final text = x.abs() >= 10 ? x.toStringAsFixed(0) : x.toStringAsFixed(1);
  return text.endsWith('.0') ? text.substring(0, text.length - 2) : text;
}

const _monthAbbr = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

/// Formats a date the way the app shows it, e.g. "15 May 2026". Models keep
/// a real DateTime; only the screen turns it into text.
String formatDate(DateTime d) => '${d.day} ${_monthAbbr[d.month - 1]} ${d.year}';
