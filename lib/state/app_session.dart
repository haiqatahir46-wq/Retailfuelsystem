import 'package:flutter/widgets.dart';
import '../data/demo_logs.dart' as demo;
import '../data/demo_nozzles.dart' as demo;
import '../data/demo_owner.dart';
import '../data/demo_sales.dart';
import '../data/demo_staff.dart';
import '../data/demo_stations.dart';
import '../data/demo_tanks.dart' as demo;
import '../models/delivery_vehicle.dart';
import '../models/log_entry.dart';
import '../models/nozzle.dart';
import '../models/owner.dart';
import '../models/sales.dart';
import '../models/staff.dart';
import '../models/station.dart';
import '../models/tank_stock.dart';
import '../utils/validators.dart';
import 'ids.dart';

/// Everything the signed-in owner has set up or changed: who they are,
/// their stations and which one is current, their staff, the tank
/// thresholds they set and the purchase orders they placed.
///
/// It lives for one app run only. Nothing is saved, so a restart starts
/// from the splash screen with no one signed in. It is also the single
/// seam where Supabase plugs in later: these methods become backend calls
/// and the demo lookups behind them become queries, while the screens and
/// flows keep reading the same getters.
///
/// Flows read it through [AppSessionScope] and pass plain data into the
/// screens, which never see the session. Every change calls
/// notifyListeners, so whatever is on screen (including routes pushed on
/// top of the main tabs) redraws with it.
///
/// Every per-station lookup returns an empty list for a station the owner
/// doesn't have, never another station's data.
class AppSession extends ChangeNotifier {
  Owner? _owner;
  List<Station> _stations = const [];
  String? _currentStationId;
  List<StaffMember> _staff = const [];
  Map<String, double> _thresholdOverrides = const {};
  Map<String, List<PurchaseOrder>> _placedOrders = const {};

  /// Null when no one is signed in.
  Owner? get owner => _owner;
  bool get isSignedIn => _owner != null;
  List<Station> get stations => _stations;
  String? get currentStationId => _currentStationId;
  Station? get currentStation => _currentStationId == null ? null : stationById(_currentStationId!);
  List<StaffMember> get staff => _staff;

  /// One of the owner's stations, or null if they have no station [id].
  Station? stationById(String id) {
    for (final s in _stations) {
      if (s.id == id) return s;
    }
    return null;
  }

  // ---- Signing in and out ----

  /// Signs in as the demo owner with the demo stations (station-1 current)
  /// and demo staff. There is no backend to check credentials against, so
  /// every login is the demo account.
  ///
  /// [email] is whatever was typed in Login's "Email / Username" field. It
  /// becomes the owner's email only when it IS a valid email address
  /// (isValidEmail); a username, or anything else, keeps the demo owner's
  /// email. Owner.email is shown and used as an email address, so it must
  /// never hold a username; and a username can't stand in for the name
  /// either, because the demo account's name is fixed.
  void signInDemo({required String email}) {
    final typed = email.trim();
    _clear();
    _owner = Owner(name: demoOwner.name, email: isValidEmail(typed) ? typed : demoOwner.email);
    _stations = demoStations;
    _currentStationId = demoStations.first.id;
    _staff = List.unmodifiable(demoStaffMembers);
    notifyListeners();
  }

  /// Creates a new account from the signup form: the owner comes from
  /// [usernameOrEmail] (see Owner.fromSignup), and the stations from
  /// Station.fromSignup, each with a fresh id so a new owner never sees a
  /// demo station's data. The first station is current. Staff starts empty.
  void signUp({
    required String usernameOrEmail,
    required String stationName,
    required int stationCount,
  }) {
    _clear();
    _owner = Owner.fromSignup(usernameOrEmail);
    _stations = List.unmodifiable(Station.fromSignup(
      stationName: stationName,
      stationCount: stationCount,
      newId: () => newId('station'),
    ));
    _currentStationId = _stations.first.id;
    notifyListeners();
  }

  /// Forgets everything, ready for the next sign-in.
  void signOut() {
    _clear();
    notifyListeners();
  }

  void _clear() {
    _owner = null;
    _stations = const [];
    _currentStationId = null;
    _staff = const [];
    _thresholdOverrides = const {};
    _placedOrders = const {};
  }

  // ---- Stations ----

  /// Adds a station from the Add Station form (see Station.fromSetup for
  /// how the counts and capacities become nozzles and tanks) and returns
  /// it. It isn't made current; the owner switches to it on Select Station.
  /// A blank name becomes 'Station N', N being its place in the list.
  Station addStation({
    required String name,
    required String location,
    required Map<String, int> nozzleCounts,
    required Map<String, double> capacities,
  }) {
    final station = Station.fromSetup(
      id: newId('station'),
      name: Station.normaliseName(name, fallback: 'Station ${_stations.length + 1}'),
      location: location,
      nozzleCounts: nozzleCounts,
      capacities: capacities,
      now: DateTime.now(),
    );
    _stations = List.unmodifiable([..._stations, station]);
    notifyListeners();
    return station;
  }

  /// Sets a station's location, e.g. from the Places search. Only the
  /// location changes: the name the owner gave the station stays.
  void updateStationLocation(String stationId, String formattedAddress) {
    if (stationById(stationId) == null) return;
    _stations = List.unmodifiable([
      for (final s in _stations)
        if (s.id == stationId) s.copyWith(location: formattedAddress.trim()) else s,
    ]);
    notifyListeners();
  }

  /// Makes [stationId] the station the main tabs show. Ignored for a
  /// station the owner doesn't have.
  void selectStation(String stationId) {
    if (stationById(stationId) == null || stationId == _currentStationId) return;
    _currentStationId = stationId;
    notifyListeners();
  }

  // ---- Staff ----

  StaffMember addStaff({required String name, required String role, required String phone}) {
    final member = StaffMember(id: newId('staff'), name: name.trim(), role: role, phone: phone.trim());
    _staff = List.unmodifiable([..._staff, member]);
    notifyListeners();
    return member;
  }

  // ---- Tanks and orders ----

  /// Sets one tank's reorder threshold (tank ids are unique across
  /// stations). Returns false, changing nothing, for a value that isn't a
  /// finite number of litres from 0 up.
  bool setThreshold(String tankId, double litres) {
    if (!litres.isFinite || litres < 0) return false;
    _thresholdOverrides = Map.unmodifiable({..._thresholdOverrides, tankId: litres});
    notifyListeners();
    return true;
  }

  /// Litres already on order for the tank [tankId] and not yet delivered:
  /// the pending orders placed this session plus the pending demo orders
  /// for it, across the owner's stations (tank ids are unique across
  /// stations). 0 for a tank with none, or one the owner doesn't have.
  double pendingLitresFor(String tankId) {
    var total = 0.0;
    for (final station in _stations) {
      for (final order in purchaseOrdersFor(station.id)) {
        if (order.tankId == tankId && order.status == PurchaseOrderStatus.pending) total += order.litres;
      }
    }
    return total;
  }

  /// Places a reorder for [tank] at [stationId]: a pending order dated
  /// today, numbered by nextPoNumber after every order the owner already
  /// has (so 'PO-2026-0064' follows the demo 'PO-2026-0063'). The Create
  /// Reorder form doesn't ask how the fuel comes, so it defaults to a hired
  /// carriage, the usual way a supplier delivers.
  ///
  /// The order must fit: [litres] can't be more than the tank's room, its
  /// space left minus what is already on order (TankStock.roomToOrder with
  /// [pendingLitresFor]). Otherwise an 18,000 L space would take two
  /// 18,000 L orders. The tank is looked up afresh by its id, so the check
  /// uses today's level rather than whatever copy the caller held.
  ///
  /// Returns the order, or null (placing nothing) for a station the owner
  /// doesn't have, a tank that isn't that station's, litres that aren't a
  /// finite amount above 0, or more litres than the tank has room for.
  PurchaseOrder? placeReorder({required String stationId, required TankStock tank, required double litres}) {
    if (stationById(stationId) == null || !litres.isFinite || litres <= 0) return null;
    TankStock? current;
    for (final t in tanksFor(stationId)) {
      if (t.id == tank.id) current = t;
    }
    if (current == null || litres > current.roomToOrder(pendingLitresFor(current.id))) return null;

    final now = DateTime.now();
    final order = PurchaseOrder(
      poNumber: nextPoNumber([
        for (final s in _stations)
          for (final o in purchaseOrdersFor(s.id)) o.poNumber,
      ], now),
      date: DateTime(now.year, now.month, now.day),
      tankId: current.id,
      fuelName: current.fuelName,
      litres: litres,
      vehicle: DeliveryVehicle.carriage,
      status: PurchaseOrderStatus.pending,
    );
    _placedOrders = Map.unmodifiable({
      ..._placedOrders,
      stationId: List<PurchaseOrder>.unmodifiable([order, ...?_placedOrders[stationId]]),
    });
    notifyListeners();
    return order;
  }

  // ---- Per-station lookups ----

  /// This station's tanks: its tank setup, today's sales (every "today" row
  /// combined, as the Dashboard and the Today report add them) and any
  /// threshold set this session. Stock, the Tanks tab, Threshold and
  /// Create Reorder all read this, so their numbers agree.
  List<TankStock> tanksFor(String stationId) {
    final station = stationById(stationId);
    if (station == null || station.tanks.isEmpty) return const [];
    return demo.buildTanks(
      configs: station.tanks,
      today: PeriodSales.sum(salesFor(stationId, SalesReportPeriod.today), label: 'Today'),
      thresholdOverrides: _thresholdOverrides,
    );
  }

  /// Orders placed this session (newest first), then the station's earlier
  /// orders.
  List<PurchaseOrder> purchaseOrdersFor(String stationId) {
    if (stationById(stationId) == null) return const [];
    return [...?_placedOrders[stationId], ...demo.purchaseOrdersFor(stationId)];
  }

  /// This station's nozzles with their latest readings. A demo station's
  /// come from the demo feed (demo_nozzles.dart) afresh on every call,
  /// never from a copy kept at sign-in, so their "x min ago" is measured
  /// from now instead of growing the longer the app runs. A station added
  /// this session has no feed: it shows the idle, zero-litre nozzles built
  /// from its Add Station counts, stamped when it was set up.
  List<Nozzle> nozzlesFor(String stationId) {
    final station = stationById(stationId);
    if (station == null) return const [];
    final readings = demo.nozzlesFor(stationId);
    return readings.isNotEmpty ? readings : station.nozzles;
  }

  List<VehicleLogEntry> logsFor(String stationId) {
    if (stationById(stationId) == null) return const [];
    return demo.logsFor(stationId);
  }
}

/// Puts an [AppSession] above the whole app. MyApp places it ABOVE
/// MaterialApp, so routes pushed through the Navigator (Profile, Staff,
/// Threshold, Select Station...) can reach it too: they are not
/// descendants of MainTabsFlow.
class AppSessionScope extends InheritedNotifier<AppSession> {
  const AppSessionScope({super.key, required AppSession session, required super.child}) : super(notifier: session);

  /// The session, rebuilding [context] whenever it changes. For build
  /// methods (including a pushed route's builder).
  static AppSession of(BuildContext context) => _session(context.dependOnInheritedWidgetOfExactType<AppSessionScope>());

  /// The session without listening to it. For callbacks such as onPressed,
  /// where a rebuild dependency would be pointless.
  static AppSession read(BuildContext context) => _session(context.getInheritedWidgetOfExactType<AppSessionScope>());

  static AppSession _session(AppSessionScope? scope) {
    assert(scope != null, 'No AppSessionScope above this widget. MyApp puts one above MaterialApp.');
    return scope!.notifier!;
  }
}
