-- Removes the demo owner (owner@parco.example) and everything that belongs
-- to them, children first, because the original tables' foreign keys don't
-- cascade. Run with `dart run bin/migrate.dart --remove-demo`. Nothing else
-- in the database is touched.
--
-- trg_prevent_sales_delete refuses to delete any sale (real sales are
-- voided, never deleted). Demo sales aren't real, so the trigger is
-- switched off for this script only: migrate.dart runs it in one
-- transaction, so the trigger is back on when it ends, even if it fails.
ALTER TABLE sales DISABLE TRIGGER trg_prevent_sales_delete;

DO $$
DECLARE
  v_owner integer;
BEGIN
  SELECT user_id INTO v_owner FROM users WHERE lower(email) = 'owner@parco.example';
  IF v_owner IS NULL THEN
    RAISE NOTICE 'No demo data found - nothing to remove.';
    RETURN;
  END IF;

  CREATE TEMP TABLE demo_stations ON COMMIT DROP AS
    SELECT id FROM stations WHERE owner_id = v_owner;
  CREATE TEMP TABLE demo_tanks ON COMMIT DROP AS
    SELECT tank_id FROM tanks WHERE station_id IN (SELECT id FROM demo_stations);
  CREATE TEMP TABLE demo_employees ON COMMIT DROP AS
    SELECT employee_id FROM employees WHERE owner_id = v_owner;

  DELETE FROM payments WHERE sale_id IN (SELECT sale_id FROM sales WHERE station_id IN (SELECT id FROM demo_stations));
  DELETE FROM sales WHERE station_id IN (SELECT id FROM demo_stations);
  DELETE FROM vehicle_transactions WHERE station_id IN (SELECT id FROM demo_stations);
  DELETE FROM nozzle_readings WHERE shift_id IN (SELECT shift_id FROM shifts WHERE station_id IN (SELECT id FROM demo_stations));
  DELETE FROM shifts WHERE station_id IN (SELECT id FROM demo_stations) OR employee_id IN (SELECT employee_id FROM demo_employees);
  DELETE FROM stock_ledger WHERE tank_id IN (SELECT tank_id FROM demo_tanks);
  DELETE FROM tank_readings WHERE tank_id IN (SELECT tank_id FROM demo_tanks);
  DELETE FROM stock_adjustments WHERE tank_id IN (SELECT tank_id FROM demo_tanks);
  DELETE FROM deliveries WHERE tank_id IN (SELECT tank_id FROM demo_tanks);
  DELETE FROM purchase_orders WHERE station_id IN (SELECT id FROM demo_stations);
  DELETE FROM nozzles WHERE tank_id IN (SELECT tank_id FROM demo_tanks);
  DELETE FROM pumps WHERE station_id IN (SELECT id FROM demo_stations);
  DELETE FROM tanks WHERE tank_id IN (SELECT tank_id FROM demo_tanks);
  DELETE FROM maintenance_tickets WHERE station_id IN (SELECT id FROM demo_stations);
  DELETE FROM employees WHERE employee_id IN (SELECT employee_id FROM demo_employees);
  DELETE FROM stations WHERE id IN (SELECT id FROM demo_stations);
  DELETE FROM audit_log WHERE user_id = v_owner;
  DELETE FROM users WHERE user_id = v_owner;

  RAISE NOTICE 'Demo data removed.';
END $$;

-- The accounts the Postman collection's sign-up test creates
-- (postman-<time>@example.com). They only ever have empty stations.
DELETE FROM audit_log WHERE user_id IN (SELECT user_id FROM users WHERE email LIKE 'postman-%@example.com');
DELETE FROM stations WHERE owner_id IN (SELECT user_id FROM users WHERE email LIKE 'postman-%@example.com');
DELETE FROM users WHERE email LIKE 'postman-%@example.com';

ALTER TABLE sales ENABLE TRIGGER trg_prevent_sales_delete;
