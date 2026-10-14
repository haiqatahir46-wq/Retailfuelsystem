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
//
// Every period list runs OLDEST -> NEWEST, so its last row is the most
// recent one. The Dashboard's 7-day trend relies on that: it highlights the
// last point as the latest and measures its change badge from the first
// row to the last. The periods also nest, newest inside newest: the last
// weekly row is today, the last monthly row is the sum of the weekly rows
// (the last 7 days) and the last yearly row is the sum of the monthly rows
// (the last 4 weeks), so a figure never disagrees with the period around
// it (test/demo_data_test.dart checks this for every demo station).
class StationSalesData {
  /// Today's rows (one per shift once shifts exist), combined with
  /// PeriodSales.sum by everything that reads "today".
  final List<PeriodSales> today;

  /// The last 7 days, one row per day, oldest first; the last row is today.
  final List<PeriodSales> weekly;

  /// The last 4 weeks, one row per week, oldest first; the last row is the
  /// last 7 days.
  final List<PeriodSales> monthly;

  /// The last 12 months, one row per month, oldest first; the last row is
  /// the last 4 weeks.
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
/// whole number first (half away from zero). The one number formatter for
/// the whole app - screens call this rather than keeping their own copy.
///
/// The digits come from a BigInt, because toStringAsFixed switches to
/// exponent notation from 1e21 up ("1e+21"), which no screen should show.
/// Rounding first also means a small negative such as -0.4 reads "0", not
/// "-0". A value that isn't finite comes back as Dart prints it ("NaN",
/// "Infinity").
String formatThousands(double v) {
  if (!v.isFinite) return v.toString();
  final whole = BigInt.from(v.roundToDouble());
  final digits = whole.abs().toString().replaceAllMapped(_thousandsGap, (m) => ',');
  return whole.isNegative ? '-$digits' : digits;
}

/// Every place inside a run of digits that has a multiple of three digits
/// after it, i.e. where a thousands separator goes.
final _thousandsGap = RegExp(r'\B(?=(\d{3})+(?!\d))');

/// A short number for a chart axis: 950 -> "950", 1500 -> "1.5k",
/// 20000 -> "20k", 2400000 -> "2.4M". Use [formatThousands] anywhere the
/// exact figure matters.
///
/// The value is rounded to what will be shown BEFORE the unit is settled,
/// so a value that rounds up across a unit boundary moves to the next unit:
/// 999,999 reads "1M" rather than "1000k", and 999.6 reads "1k" rather than
/// "1000". B is the largest unit; beyond it the digits simply grow.
String formatCompact(double v) {
  if (!v.isFinite) return v.toString();
  const suffixes = ['', 'k', 'M', 'B'];
  var unit = 0;
  var scaled = v;
  while (unit < suffixes.length - 1 && scaled.abs() >= 1000) {
    scaled /= 1000;
    unit++;
  }
  var shown = _roundCompact(scaled);
  if (unit < suffixes.length - 1 && shown.abs() >= 1000) {
    scaled /= 1000;
    unit++;
    shown = _roundCompact(scaled);
  }
  return '${_compactDigits(shown)}${suffixes[unit]}';
}

/// [x] rounded the way [formatCompact] shows it: one decimal place below
/// 10, none from 10 up.
double _roundCompact(double x) => x.abs() >= 10 ? x.roundToDouble() : (x * 10).roundToDouble() / 10;

/// An already-rounded compact value as text, never with a trailing ".0",
/// exponent notation or a "-0".
String _compactDigits(double x) {
  if (x == 0) return '0'; // -0.0 == 0 too
  if (x.abs() >= 10) return BigInt.from(x).toString();
  final text = x.toStringAsFixed(1);
  return text.endsWith('.0') ? text.substring(0, text.length - 2) : text;
}

const _monthAbbr = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

/// Formats a date the way the app shows it, e.g. "15 May 2026". Models keep
/// a real DateTime; only the screen turns it into text.
String formatDate(DateTime d) => '${d.day} ${_monthAbbr[d.month - 1]} ${d.year}';
