-- Completes the fuelmanagementsystemdb schema so the PARCO Fuel System app
-- can run on it, keeping the existing tables and their naming. Written when
-- every table was still empty, so NOT NULL columns are added without
-- back-filling. bin/migrate.dart runs it as one transaction: either all of
-- it applies or none of it does.

CREATE EXTENSION IF NOT EXISTS pgcrypto;  -- crypt()/gen_salt() for password hashes

-- 1. Drop the empty duplicates. The app uses users, employees and tanks,
--    which the other tables already reference. profiles also kept
--    passwords in a plain "password" column.
DROP TABLE IF EXISTS profiles CASCADE;  -- CASCADE drops maintenance_tickets' link to it; re-pointed in 2
DROP TABLE IF EXISTS staff;
DROP TABLE IF EXISTS fuel_stock;

-- 2. users: owners sign in with their email (also kept as username), and
--    every account has a display name. "owner" joins the existing roles.
ALTER TABLE users ALTER COLUMN username TYPE varchar(254);
ALTER TABLE users ADD COLUMN full_name varchar(100) NOT NULL CHECK (length(trim(full_name)) > 0);
ALTER TABLE users ADD COLUMN email varchar(254) NOT NULL;
CREATE UNIQUE INDEX users_email_lower_key ON users (lower(email));
ALTER TABLE users DROP CONSTRAINT users_role_check;
ALTER TABLE users ADD CONSTRAINT users_role_check
  CHECK (role IN ('owner', 'admin', 'manager', 'cashier', 'attendant'));

ALTER TABLE maintenance_tickets ADD CONSTRAINT maintenance_tickets_reported_by_fkey
  FOREIGN KEY (reported_by) REFERENCES users (user_id) ON DELETE SET NULL;

-- 3. stations belong to an owner. "pending" = named at signup ("No. of
--    Stations") but not set up yet.
ALTER TABLE stations ADD COLUMN owner_id integer NOT NULL REFERENCES users (user_id) ON DELETE CASCADE;
ALTER TABLE stations ADD COLUMN status varchar(10) NOT NULL DEFAULT 'active'
  CHECK (status IN ('active', 'pending'));
CREATE INDEX stations_owner_id_idx ON stations (owner_id);

-- 4. pumps belong to a station, and every station numbers its own pumps
--    from 1 (pump_number was unique across the whole database).
ALTER TABLE pumps ADD COLUMN station_id integer NOT NULL REFERENCES stations (id) ON DELETE CASCADE;
ALTER TABLE pumps DROP CONSTRAINT pumps_pump_number_key;
ALTER TABLE pumps ADD CONSTRAINT pumps_station_id_pump_number_key UNIQUE (station_id, pump_number);
ALTER TABLE pumps ADD CONSTRAINT pumps_pump_number_check CHECK (pump_number > 0);

-- 5. tanks belong to a station and have a low-stock (reorder) threshold.
ALTER TABLE tanks ADD COLUMN station_id integer NOT NULL REFERENCES stations (id) ON DELETE CASCADE;
ALTER TABLE tanks ADD COLUMN low_stock_threshold numeric(10, 2) NOT NULL CHECK (low_stock_threshold >= 0);
ALTER TABLE tanks ADD CONSTRAINT tanks_threshold_within_capacity CHECK (low_stock_threshold <= capacity_liters);
CREATE INDEX tanks_station_id_idx ON tanks (station_id);

-- 6. nozzles report what they're doing (the Nozzles tab).
ALTER TABLE nozzles ADD COLUMN status varchar(12) NOT NULL DEFAULT 'idle'
  CHECK (status IN ('dispensing', 'idle', 'fault'));
ALTER TABLE nozzles ADD COLUMN status_updated_at timestamp NOT NULL DEFAULT now();

-- 7. employees belong to an owner (and optionally work at one station),
--    and can be on leave.
ALTER TABLE employees ADD COLUMN owner_id integer NOT NULL REFERENCES users (user_id) ON DELETE CASCADE;
ALTER TABLE employees ADD COLUMN station_id integer REFERENCES stations (id) ON DELETE SET NULL;
ALTER TABLE employees ADD COLUMN email varchar(254);
ALTER TABLE employees ALTER COLUMN hire_date SET DEFAULT CURRENT_DATE;
ALTER TABLE employees DROP CONSTRAINT employees_status_check;
ALTER TABLE employees ADD CONSTRAINT employees_status_check
  CHECK (status IN ('active', 'on_leave', 'terminated'));
CREATE INDEX employees_owner_id_idx ON employees (owner_id);

-- 8. shifts belong to a station and count the cash (milestone 3: "opening
--    readings, opening cash"). At most one open shift per station.
ALTER TABLE shifts ADD COLUMN station_id integer NOT NULL REFERENCES stations (id) ON DELETE CASCADE;
ALTER TABLE shifts ADD COLUMN opening_cash numeric(10, 2) NOT NULL DEFAULT 0 CHECK (opening_cash >= 0);
ALTER TABLE shifts ADD COLUMN closing_cash numeric(10, 2) CHECK (closing_cash >= 0);
CREATE UNIQUE INDEX shifts_one_open_per_station ON shifts (station_id) WHERE status = 'open';

-- 9. NEW: each nozzle's meter reading at shift open and close.
CREATE TABLE nozzle_readings (
  reading_id      serial PRIMARY KEY,
  shift_id        integer NOT NULL REFERENCES shifts (shift_id) ON DELETE CASCADE,
  nozzle_id       integer NOT NULL REFERENCES nozzles (nozzle_id) ON DELETE CASCADE,
  opening_reading numeric(12, 2) NOT NULL CHECK (opening_reading >= 0),
  closing_reading numeric(12, 2) CHECK (closing_reading >= opening_reading),
  UNIQUE (shift_id, nozzle_id)
);

-- 10. sales belong to a station (a per-station dashboard needs it), and the
--     stored total can never disagree with litres x unit price.
ALTER TABLE sales ADD COLUMN station_id integer NOT NULL REFERENCES stations (id) ON DELETE CASCADE;
ALTER TABLE sales ADD CONSTRAINT sales_total_matches_liters
  CHECK (total_amount = round(liters * unit_price, 2));
CREATE INDEX sales_station_id_sale_time_idx ON sales (station_id, sale_time);
CREATE INDEX sales_nozzle_id_sale_time_idx ON sales (nozzle_id, sale_time);

-- 11. NEW: reorders placed from the app's Create Reorder screen. PO numbers
--     read PO-<year>-<4-digit sequence>.
CREATE SEQUENCE purchase_order_number_seq;
CREATE TABLE purchase_orders (
  purchase_order_id serial PRIMARY KEY,
  station_id        integer NOT NULL REFERENCES stations (id) ON DELETE CASCADE,
  tank_id           integer NOT NULL REFERENCES tanks (tank_id) ON DELETE CASCADE,
  po_number         varchar(20) NOT NULL UNIQUE
                    DEFAULT ('PO-' || to_char(now(), 'YYYY') || '-' || lpad(nextval('purchase_order_number_seq')::text, 4, '0')),
  liters_ordered    numeric(10, 2) NOT NULL CHECK (liters_ordered > 0),
  vehicle           varchar(10) NOT NULL DEFAULT 'carriage' CHECK (vehicle IN ('self', 'carriage')),
  status            varchar(10) NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'delivered', 'cancelled')),
  ordered_by        integer REFERENCES users (user_id) ON DELETE SET NULL,
  ordered_at        timestamp NOT NULL DEFAULT now()
);
CREATE INDEX purchase_orders_tank_id_status_idx ON purchase_orders (tank_id, status);
CREATE INDEX purchase_orders_station_id_ordered_at_idx ON purchase_orders (station_id, ordered_at);

-- 12. deliveries: what the fuel cost (for weighted-average cost), the
--     supplier's invoice, and which reorder it fulfils.
ALTER TABLE deliveries ADD COLUMN cost_per_liter numeric(10, 2) NOT NULL CHECK (cost_per_liter > 0);
ALTER TABLE deliveries ADD COLUMN invoice_ref varchar(60);
ALTER TABLE deliveries ADD COLUMN purchase_order_id integer
  REFERENCES purchase_orders (purchase_order_id) ON DELETE SET NULL;

-- 13. vehicle_transactions is the app's Logs tab: an entry can be pending
--     (no litres yet), and it can name the nozzle used.
ALTER TABLE vehicle_transactions ALTER COLUMN station_id SET NOT NULL;
ALTER TABLE vehicle_transactions ALTER COLUMN liters DROP NOT NULL;
ALTER TABLE vehicle_transactions ALTER COLUMN amount DROP NOT NULL;
ALTER TABLE vehicle_transactions ADD COLUMN nozzle_id integer REFERENCES nozzles (nozzle_id) ON DELETE SET NULL;
ALTER TABLE vehicle_transactions ADD COLUMN status varchar(10) NOT NULL DEFAULT 'completed'
  CHECK (status IN ('completed', 'pending'));
ALTER TABLE vehicle_transactions ADD CONSTRAINT vehicle_transactions_completed_has_liters
  CHECK (status = 'pending' OR (liters > 0 AND amount >= 0));
CREATE INDEX vehicle_transactions_station_id_created_at_idx ON vehicle_transactions (station_id, created_at);

-- 14. The three grades the app sells, at today's prices (PKR per litre),
--     with the opening entry in price_history.
INSERT INTO fuel_products (name, current_price)
VALUES ('Petrol', 50.00), ('Diesel', 48.00), ('Hi-Octane', 60.00)
ON CONFLICT (name) DO NOTHING;
INSERT INTO price_history (product_id, price, effective_from)
SELECT fp.product_id, fp.current_price, now()
FROM fuel_products fp
WHERE NOT EXISTS (SELECT 1 FROM price_history ph WHERE ph.product_id = fp.product_id);
