import 'dart:async';

import 'package:flutter/widgets.dart';
import '../data/demo_logs.dart' as demo;
import '../data/demo_nozzles.dart' as demo;
import '../data/demo_owner.dart';
import '../data/demo_sales.dart' as demo;
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
import '../services/api_client.dart';
import '../utils/validators.dart';
import 'ids.dart';

/// Everything the signed-in owner sees and changes: who they are, their
/// stations and which one is current, their staff, and each station's
/// tanks, nozzles, sales, purchase orders and vehicle log.
///
/// It runs in one of two modes, fixed when it's created:
///
/// - **Server** (the app): given an [ApiClient], it signs in against the
///   PostgreSQL-backed API, loads the owner's data from it and sends every
///   change to it, so the data lives in the database. Whatever the server
///   last sent is kept here, so the getters below answer straight away;
///   the current station is reloaded on switching to it, after each change
///   and every [refreshInterval]. A failed request throws [ApiException],
///   whose message is safe to show.
/// - **Demo** (tests, and `--dart-define=DEMO_DATA=true`): no server. It
///   runs on the built-in demo data in lib/data, and changes live for the
///   app run only.
///
/// Flows read it through [AppSessionScope] and pass plain data into the
/// screens, which never see the session. Every change calls
/// notifyListeners, so whatever is on screen (including routes pushed on
/// top of the main tabs) redraws with it.
///
/// Every per-station lookup returns an empty list for a station the owner
/// doesn't have, never another station's data.
class AppSession extends ChangeNotifier {
  AppSession({ApiClient? api}) : _api = api;

  final ApiClient? _api;

  /// Whether this session talks to the server (see the class comment).
  bool get usesServer => _api != null;

  /// How often the current station is reloaded from the server, so live
  /// nozzle readings and today's sales keep up while the app is open.
  static const refreshInterval = Duration(seconds: 60);

  Owner? _owner;
  List<Station> _stations = const [];
  String? _currentStationId;
  List<StaffMember> _staff = const [];

  // Demo mode: what was changed this app run.
  Map<String, double> _thresholdOverrides = const {};
  Map<String, List<PurchaseOrder>> _placedOrders = const {};

  // Server mode: what the server last sent for each station.
  final Map<String, _StationData> _server = {};
  final Set<String> _loading = {};
  final Map<String, String> _loadErrors = {};
  Timer? _refreshTimer;

  /// Bumped whenever the signed-in session ends, so a reply that arrives
  /// for an earlier session is dropped instead of filling in this one.
  int _generation = 0;

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

  /// Whether everything the tabs show for [stationId] has arrived. Always
  /// true on demo data, which needs no loading.
  bool hasDataFor(String stationId) => !usesServer || (_server[stationId]?.complete ?? false);

  /// Whether [stationId]'s data is being loaded from the server right now.
  bool isLoading(String stationId) => _loading.contains(stationId);

  /// Why loading [stationId] from the server last failed, or null.
  String? loadErrorFor(String stationId) => _loadErrors[stationId];

  // ---- Signing in and out ----

  /// Signs in. With the server, [email] and [password] are checked against
  /// the users table, then the owner's stations, staff and the first
  /// station's data are loaded; a wrong password, a locked account or an
  /// unreachable server throws [ApiException]. On demo data, any login is
  /// the demo account (see [signInDemo]).
  Future<void> signIn({required String email, required String password}) async {
    final api = _api;
    if (api == null) {
      signInDemo(email: email);
      return;
    }
    final owner = await api.login(email: email.trim(), password: password);
    await _startServerSession(api, owner);
  }

  /// Signs in as the demo owner with the demo stations (station-1 current)
  /// and demo staff, without any server.
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

  /// Creates a new account from the signup form and signs in to it. The
  /// first station is named [stationName] and is current; the rest of
  /// [stationCount] (clamped to 1..Station.maxSignupStations) are pending
  /// "Station N"s. Staff starts empty.
  ///
  /// With the server, [usernameOrEmail] must be an email address (the
  /// account signs in with it) and the server creates the owner and the
  /// stations; a taken email throws [ApiException]. On demo data, the owner
  /// comes from what was typed (see Owner.fromSignup), and each station gets
  /// a fresh id, so a new owner never sees a demo station's data.
  Future<void> signUp({
    required String usernameOrEmail,
    String password = '',
    required String stationName,
    required int stationCount,
  }) async {
    final api = _api;
    if (api == null) {
      _clear();
      _owner = Owner.fromSignup(usernameOrEmail);
      _stations = List.unmodifiable(Station.fromSignup(
        stationName: stationName,
        stationCount: stationCount,
        newId: () => newId('station'),
      ));
      _currentStationId = _stations.first.id;
      notifyListeners();
      return;
    }
    final owner = await api.signUp(
      email: usernameOrEmail.trim(),
      password: password,
      stationName: Station.normaliseName(stationName, fallback: 'Station 1'),
      stationCount: stationCount.clamp(1, Station.maxSignupStations),
    );
    await _startServerSession(api, owner);
  }

  /// Loads a freshly signed-in owner's stations and staff, then the first
  /// station's data. If anything fails the session is signed out again and
  /// the error is passed on, so no half-loaded account is left behind.
  Future<void> _startServerSession(ApiClient api, Owner owner) async {
    _clear();
    final generation = _generation;
    try {
      // eagerError: the first failure is passed on as it is (an ApiException
      // with its message), not wrapped.
      final results = await Future.wait<Object>([api.stations(), api.staff()], eagerError: true);
      final stations = results[0] as List<ApiStation>;
      final staff = results[1] as List<StaffMember>;
      if (generation != _generation) return;
      _owner = owner;
      _stations = List.unmodifiable([for (final s in stations) s.station]);
      _staff = List.unmodifiable(staff);
      for (final s in stations) {
        _server[s.station.id] = _StationData(tanks: s.tanks, pending: s.pendingLitres, nozzles: s.station.nozzles);
      }
      _currentStationId = _stations.isEmpty ? null : _stations.first.id;
      notifyListeners();
      _refreshTimer = Timer.periodic(refreshInterval, (_) => refresh());
      if (_currentStationId != null) await _loadStation(_currentStationId!);
    } catch (_) {
      _abandon(api, generation);
      rethrow;
    }
  }

  void _abandon(ApiClient api, int generation) {
    if (generation != _generation) return;
    _clear();
    notifyListeners();
    unawaited(api.logout());
  }

  /// Forgets everything, ready for the next sign-in. With the server, the
  /// session there is ended too (in the background: signing out never waits
  /// on the network).
  void signOut() {
    final api = _api;
    _clear();
    notifyListeners();
    if (api != null) unawaited(api.logout());
  }

  void _clear() {
    _generation++;
    _refreshTimer?.cancel();
    _refreshTimer = null;
    _owner = null;
    _stations = const [];
    _currentStationId = null;
    _staff = const [];
    _thresholdOverrides = const {};
    _placedOrders = const {};
    _server.clear();
    _loading.clear();
    _loadErrors.clear();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _api?.close();
    super.dispose();
  }

  // ---- Loading from the server ----

  /// Reloads the current station from the server: Retry, and the regular
  /// refresh. Once a station has data, a reload keeps showing it and a
  /// failed one is silent (the next refresh tries again). Nothing to do on
  /// demo data.
  Future<void> refresh() async {
    final id = _currentStationId;
    if (usesServer && id != null) await _loadStation(id, quiet: hasDataFor(id));
  }

  /// Loads everything the tabs show for [stationId]: tanks, nozzles,
  /// orders, the vehicle log and every sales period. Unless [quiet], the
  /// station shows as loading meanwhile and a failure is kept for
  /// [loadErrorFor].
  Future<void> _loadStation(String stationId, {bool quiet = false}) async {
    final api = _api!;
    final generation = _generation;
    if (!quiet) {
      _loading.add(stationId);
      _loadErrors.remove(stationId);
      notifyListeners();
    }
    try {
      const periods = SalesReportPeriod.values;
      final results = await Future.wait<Object>([
        api.tanks(stationId),
        api.nozzles(stationId),
        api.purchaseOrders(stationId),
        api.vehicleLogs(stationId),
        for (final p in periods) api.sales(stationId, p),
      ], eagerError: true);
      if (generation != _generation || stationById(stationId) == null) return;
      final tanks = results[0] as ApiTanks;
      _server[stationId] = _StationData(
        tanks: tanks.tanks,
        pending: tanks.pendingLitres,
        nozzles: List.unmodifiable(results[1] as List<Nozzle>),
        orders: List.unmodifiable(results[2] as List<PurchaseOrder>),
        logs: List.unmodifiable(results[3] as List<VehicleLogEntry>),
        sales: {
          for (var i = 0; i < periods.length; i++) periods[i]: List.unmodifiable(results[4 + i] as List<PeriodSales>),
        },
        complete: true,
      );
      _loadErrors.remove(stationId);
    } on ApiException catch (error) {
      if (generation != _generation || quiet) return;
      _loadErrors[stationId] = error.message;
    } finally {
      if (generation == _generation) {
        _loading.remove(stationId);
        notifyListeners();
      }
    }
  }

  /// Reloads [stationId]'s tanks and orders after a change to them.
  Future<void> _reloadStock(String stationId) async {
    final api = _api!;
    final generation = _generation;
    final results = await Future.wait<Object>([api.tanks(stationId), api.purchaseOrders(stationId)], eagerError: true);
    final data = _server[stationId];
    if (generation != _generation || data == null) return;
    final tanks = results[0] as ApiTanks;
    _server[stationId] = data.copyWith(
      tanks: tanks.tanks,
      pending: tanks.pendingLitres,
      orders: List.unmodifiable(results[1] as List<PurchaseOrder>),
    );
    notifyListeners();
  }

  // ---- Stations ----

  /// Adds a station from the Add Station form and returns it (null if the
  /// owner signed out meanwhile). It isn't made current; the owner switches
  /// to it on Select Station. A blank name becomes 'Station N', N being its
  /// place in the list. Its tanks and nozzles come from the counts and
  /// capacities (see Station.fromSetup); with the server, it's created
  /// there, and its tanks start empty until a delivery is recorded.
  Future<Station?> addStation({
    required String name,
    required String location,
    required Map<String, int> nozzleCounts,
    required Map<String, double> capacities,
  }) async {
    final normalised = Station.normaliseName(name, fallback: 'Station ${_stations.length + 1}');
    final api = _api;
    if (api == null) {
      final station = Station.fromSetup(
        id: newId('station'),
        name: normalised,
        location: location,
        nozzleCounts: nozzleCounts,
        capacities: capacities,
        now: DateTime.now(),
      );
      _stations = List.unmodifiable([..._stations, station]);
      notifyListeners();
      return station;
    }
    final generation = _generation;
    final added = await api.addStation(
      name: normalised,
      location: location.trim(),
      nozzleCounts: nozzleCounts,
      capacities: capacities,
    );
    if (generation != _generation) return null;
    _stations = List.unmodifiable([..._stations, added.station]);
    _server[added.station.id] = _StationData(tanks: added.tanks, pending: added.pendingLitres, nozzles: added.station.nozzles);
    notifyListeners();
    return added.station;
  }

  /// Sets a station's location, e.g. from the Places search. Only the
  /// location changes: the name the owner gave the station stays.
  Future<void> updateStationLocation(String stationId, String formattedAddress) async {
    if (stationById(stationId) == null) return;
    final location = formattedAddress.trim();
    final api = _api;
    if (api != null) {
      final generation = _generation;
      final updated = await api.updateStationLocation(stationId, location);
      if (generation != _generation) return;
      _stations = List.unmodifiable([
        for (final s in _stations)
          if (s.id == stationId) s.copyWith(location: updated.station.location) else s,
      ]);
      notifyListeners();
      return;
    }
    _stations = List.unmodifiable([
      for (final s in _stations)
        if (s.id == stationId) s.copyWith(location: location) else s,
    ]);
    notifyListeners();
  }

  /// Makes [stationId] the station the main tabs show. Ignored for a
  /// station the owner doesn't have. With the server, its data is
  /// (re)loaded; the tabs show it loading until it arrives.
  void selectStation(String stationId) {
    if (stationById(stationId) == null || stationId == _currentStationId) return;
    _currentStationId = stationId;
    notifyListeners();
    if (usesServer) unawaited(_loadStation(stationId, quiet: hasDataFor(stationId)));
  }

  // ---- Staff ----

  /// Adds a staff member and returns them (null if the owner signed out
  /// meanwhile).
  Future<StaffMember?> addStaff({required String name, required String role, required String phone}) async {
    final api = _api;
    final generation = _generation;
    final member = api == null
        ? StaffMember(id: newId('staff'), name: name.trim(), role: role, phone: phone.trim())
        : await api.addStaff(name: name.trim(), role: role, phone: phone.trim());
    if (generation != _generation) return null;
    _staff = List.unmodifiable([..._staff, member]);
    notifyListeners();
    return member;
  }

  // ---- Tanks and orders ----

  /// Sets one tank's reorder threshold (tank ids are unique across
  /// stations). Returns false, changing nothing, for a value that isn't a
  /// finite number of litres from 0 up. With the server, the server also
  /// refuses one above the tank's capacity (ApiException).
  Future<bool> setThreshold(String tankId, double litres) async {
    if (!litres.isFinite || litres < 0) return false;
    final api = _api;
    if (api == null) {
      _thresholdOverrides = Map.unmodifiable({..._thresholdOverrides, tankId: litres});
      notifyListeners();
      return true;
    }
    final stationId = _stationOfTank(tankId);
    if (stationId == null) return false;
    await api.setThreshold(tankId, litres);
    await _reloadStock(stationId);
    return true;
  }

  /// The owner's station that has the tank [tankId], per the server's data.
  String? _stationOfTank(String tankId) {
    for (final entry in _server.entries) {
      if (entry.value.tanks.any((t) => t.id == tankId)) return entry.key;
    }
    return null;
  }

  /// Litres already on order for the tank [tankId] and not yet delivered.
  /// On demo data: the pending orders placed this session plus the pending
  /// demo orders for it, across the owner's stations (tank ids are unique
  /// across stations). 0 for a tank with none, or one the owner doesn't have.
  double pendingLitresFor(String tankId) {
    if (usesServer) {
      for (final data in _server.values) {
        final pending = data.pending[tankId];
        if (pending != null) return pending;
      }
      return 0;
    }
    var total = 0.0;
    for (final station in _stations) {
      for (final order in purchaseOrdersFor(station.id)) {
        if (order.tankId == tankId && order.status == PurchaseOrderStatus.pending) total += order.litres;
      }
    }
    return total;
  }

  /// Places a reorder for [tank] at [stationId]: a pending order dated
  /// today. Create Reorder doesn't ask how the fuel comes, so it defaults to
  /// a hired carriage, the usual way a supplier delivers.
  ///
  /// The order must fit: [litres] can't be more than the tank's room, its
  /// space left minus what is already on order (TankStock.roomToOrder with
  /// [pendingLitresFor]). Otherwise an 18,000 L space would take two
  /// 18,000 L orders.
  ///
  /// With the server, the server checks the room again, numbers the order
  /// (`PO-<year>-<sequence>`) and stores it; a refusal throws [ApiException]
  /// with the reason. On demo data, the order is numbered by nextPoNumber
  /// after every order the owner already has, and checked against the tank
  /// looked up afresh by its id.
  ///
  /// Returns the order, or null (placing nothing) for a station the owner
  /// doesn't have, litres that aren't a finite amount above 0, or (on demo
  /// data) a tank that isn't that station's or more litres than it has room
  /// for.
  Future<PurchaseOrder?> placeReorder({required String stationId, required TankStock tank, required double litres}) async {
    if (stationById(stationId) == null || !litres.isFinite || litres <= 0) return null;
    final api = _api;
    if (api != null) {
      final order = await api.placeReorder(stationId: stationId, tankId: tank.id, litres: litres);
      await _reloadStock(stationId);
      return order;
    }

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

  /// This station's sales for [period], oldest row first. The Dashboard,
  /// its reports and the Nozzles tab all read this.
  List<PeriodSales> salesFor(String stationId, SalesReportPeriod period) {
    if (stationById(stationId) == null) return const [];
    if (usesServer) return _server[stationId]?.sales[period] ?? const [];
    return demo.salesFor(stationId, period);
  }

  /// This station's tanks. With the server: the levels in the tanks table.
  /// On demo data: its tank setup, today's sales (every "today" row
  /// combined, as the Dashboard and the Today report add them) and any
  /// threshold set this session. Stock, the Tanks tab, Threshold and Create
  /// Reorder all read this, so their numbers agree.
  List<TankStock> tanksFor(String stationId) {
    final station = stationById(stationId);
    if (station == null) return const [];
    if (usesServer) return _server[stationId]?.tanks ?? const [];
    if (station.tanks.isEmpty) return const [];
    return demo.buildTanks(
      configs: station.tanks,
      today: PeriodSales.sum(demo.salesFor(stationId, SalesReportPeriod.today), label: 'Today'),
      thresholdOverrides: _thresholdOverrides,
    );
  }

  /// The station's orders, newest first. On demo data: those placed this
  /// session, then the station's earlier demo orders.
  List<PurchaseOrder> purchaseOrdersFor(String stationId) {
    if (stationById(stationId) == null) return const [];
    if (usesServer) return _server[stationId]?.orders ?? const [];
    return [...?_placedOrders[stationId], ...demo.purchaseOrdersFor(stationId)];
  }

  /// This station's nozzles with their latest readings. With the server:
  /// as last loaded (live pump readings included). On demo data, a demo
  /// station's come from the demo feed (demo_nozzles.dart) afresh on every
  /// call, never from a copy kept at sign-in, so their "x min ago" is
  /// measured from now instead of growing the longer the app runs; a station
  /// added this session has no feed, so it shows the idle, zero-litre
  /// nozzles built from its Add Station counts.
  List<Nozzle> nozzlesFor(String stationId) {
    final station = stationById(stationId);
    if (station == null) return const [];
    if (usesServer) return _server[stationId]?.nozzles ?? station.nozzles;
    final readings = demo.nozzlesFor(stationId);
    return readings.isNotEmpty ? readings : station.nozzles;
  }

  /// Today's vehicle log entries for the station.
  List<VehicleLogEntry> logsFor(String stationId) {
    if (stationById(stationId) == null) return const [];
    if (usesServer) return _server[stationId]?.logs ?? const [];
    return demo.logsFor(stationId);
  }
}

/// What the server last sent for one station. [complete] once a full load
/// (sales, orders and logs too) has arrived; the station list alone only
/// brings tanks and nozzles.
class _StationData {
  final List<TankStock> tanks;
  final Map<String, double> pending;
  final List<Nozzle> nozzles;
  final List<PurchaseOrder> orders;
  final List<VehicleLogEntry> logs;
  final Map<SalesReportPeriod, List<PeriodSales>> sales;
  final bool complete;

  const _StationData({
    required this.tanks,
    required this.pending,
    required this.nozzles,
    this.orders = const [],
    this.logs = const [],
    this.sales = const {},
    this.complete = false,
  });

  _StationData copyWith({List<TankStock>? tanks, Map<String, double>? pending, List<PurchaseOrder>? orders}) =>
      _StationData(
        tanks: tanks ?? this.tanks,
        pending: pending ?? this.pending,
        nozzles: nozzles,
        orders: orders ?? this.orders,
        logs: logs,
        sales: sales,
        complete: complete,
      );
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
