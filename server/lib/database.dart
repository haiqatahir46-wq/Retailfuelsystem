import 'package:postgres/postgres.dart';

import 'config.dart';

/// The API works on the tables in the database's `public` schema: the
/// original fuelmanagementsystemdb tables, completed by
/// migrations/001_complete_fuel_management_schema.sql.
const appSchema = 'public';

/// Every table the schema should have, and the columns the API reads or
/// writes in each. `bin/check.dart` reports any that are missing, which
/// means a migration hasn't been run.
const requiredColumns = <String, List<String>>{
  'users': ['user_id', 'username', 'password_hash', 'role', 'is_active', 'full_name', 'email'],
  'stations': ['id', 'owner_id', 'name', 'address', 'status', 'no_of_nozzles'],
  'fuel_products': ['product_id', 'name', 'current_price'],
  'price_history': ['price_history_id', 'product_id', 'price', 'effective_from', 'effective_to'],
  'tanks': ['tank_id', 'station_id', 'product_id', 'capacity_liters', 'current_volume', 'low_stock_threshold'],
  'pumps': ['pump_id', 'station_id', 'pump_number'],
  'nozzles': ['nozzle_id', 'pump_id', 'tank_id', 'nozzle_number', 'status', 'status_updated_at'],
  'employees': ['employee_id', 'owner_id', 'station_id', 'full_name', 'position', 'phone', 'cnic', 'email', 'status'],
  'shifts': ['shift_id', 'station_id', 'employee_id', 'start_time', 'end_time', 'opening_cash', 'closing_cash', 'status'],
  'nozzle_readings': ['reading_id', 'shift_id', 'nozzle_id', 'opening_reading', 'closing_reading'],
  'sales': ['sale_id', 'station_id', 'nozzle_id', 'employee_id', 'liters', 'unit_price', 'total_amount', 'sale_time', 'status'],
  'payments': ['payment_id', 'sale_id', 'payment_method', 'amount'],
  'purchase_orders': ['purchase_order_id', 'station_id', 'tank_id', 'po_number', 'liters_ordered', 'vehicle', 'status', 'ordered_at'],
  'deliveries': ['delivery_id', 'tank_id', 'liters_delivered', 'cost_per_liter', 'invoice_ref', 'purchase_order_id'],
  'stock_ledger': ['ledger_id', 'tank_id', 'change_liters', 'reference_type', 'reference_id'],
  'tank_readings': ['reading_id', 'tank_id', 'reading_liters', 'reading_time'],
  'stock_adjustments': ['adjustment_id', 'tank_id', 'adjustment_liters', 'reason'],
  'vehicle_transactions': ['id', 'station_id', 'nozzle_id', 'fuel_type', 'liters', 'amount', 'vehicle_type', 'status', 'created_at'],
  'audit_log': ['audit_id', 'user_id', 'action', 'table_name', 'record_id'],
  'maintenance_tickets': ['id', 'station_id', 'reported_by', 'issue_description', 'status'],
};

Endpoint endpointFor(AppConfig config) => Endpoint(
      host: config.dbHost,
      port: config.dbPort,
      database: config.dbName,
      username: config.dbUser,
      password: config.dbPassword,
    );

SslMode sslModeFor(AppConfig config) => config.dbSsl ? SslMode.require : SslMode.disable;

/// The API server's connection pool. Every connection uses [AppConfig.timeZone],
/// so `date_trunc('day', now())` in the sales queries means midnight at the
/// station, and the tables' `timestamp` (without time zone) columns are read
/// and written as station-local time.
Pool openPool(AppConfig config) => Pool.withEndpoints(
      [endpointFor(config)],
      settings: PoolSettings(
        maxConnectionCount: 10,
        sslMode: sslModeFor(config),
        timeZone: config.timeZone,
      ),
    );

/// A single connection for the command-line tools (check, migrate).
Future<Connection> openConnection(AppConfig config) => Connection.open(
      endpointFor(config),
      settings: ConnectionSettings(sslMode: sslModeFor(config), timeZone: config.timeZone),
    );
