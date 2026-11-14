-- Demo data that fills every table, consistently, matching the app's
-- built-in demo: one owner with two stations and three staff, and for each
-- station a year of sales ending today with their payments, the deliveries
-- that refill the tanks each morning, the stock ledger behind both, the last
-- 30 days of shifts (cash counted, nozzle meters read at open and close),
-- evening tank dips, a stock adjustment, purchase orders, today's vehicle
-- log, maintenance tickets and audit-log entries.
--
--   Sign in as: owner@parco.example / demo1234
--
-- Load it with `dart run bin/migrate.dart --seed`; replace it (so its year
-- ends today again) with `--remove-demo --seed`; remove it with
-- `--remove-demo`. Safe to run twice: it does nothing once the demo owner
-- exists. Nothing in it is ever later than the moment it is loaded.
DO $$
DECLARE
  v_owner     integer;
  v_manager   integer;
  v_attendant integer;
  v_station   integer;
  v_tank      integer;
  v_pump      integer;
  v_pump_no   integer;
  v_delivery  integer;
  v_liters    numeric;
  v_date      timestamp;
  v_order     integer;
  v_adjust    integer;
  st          record;
  g           record;
  i           integer;
BEGIN
  IF EXISTS (SELECT 1 FROM users WHERE lower(email) = 'owner@parco.example') THEN
    RAISE NOTICE 'Demo data is already loaded - nothing to do.';
    RETURN;
  END IF;

  INSERT INTO users (username, password_hash, role, full_name, email)
  VALUES ('owner@parco.example', crypt('demo1234', gen_salt('bf')), 'owner', 'Demo Owner', 'owner@parco.example')
  RETURNING user_id INTO v_owner;

  INSERT INTO employees (owner_id, full_name, position, phone, status, hire_date)
  VALUES (v_owner, 'Bilal Ahmed', 'Manager', '0300-1234567', 'active', current_date - 900)
  RETURNING employee_id INTO v_manager;    -- receives deliveries, records adjustments
  INSERT INTO employees (owner_id, full_name, position, phone, status, hire_date)
  VALUES (v_owner, 'Usman Tariq', 'Attendant', '0301-2345678', 'active', current_date - 400)
  RETURNING employee_id INTO v_attendant;  -- works the shifts, rings up sales, dips tanks
  INSERT INTO employees (owner_id, full_name, position, phone, status, hire_date)
  VALUES (v_owner, 'Imran Shah', 'Cashier', '0302-3456789', 'on_leave', current_date - 200);

  -- scale: the second station sells half as much.
  FOR st IN
    SELECT * FROM (VALUES
      ('Amir Filling, Pattoki', 'Pattoki, Punjab', 1.0::numeric, 6, 4, 2),
      ('Demo Station 2',        '',                0.5::numeric, 4, 2, 2)
    ) AS t (name, address, scale, petrol_nozzles, diesel_nozzles, octane_nozzles)
  LOOP
    INSERT INTO stations (owner_id, name, address, no_of_nozzles)
    VALUES (v_owner, st.name, st.address, st.petrol_nozzles + st.diesel_nozzles + st.octane_nozzles)
    RETURNING id INTO v_station;
    v_pump_no := 0;

    FOR g IN
      SELECT fp.product_id, fp.name, fp.current_price, v.base,
             CASE fp.name WHEN 'Petrol' THEN st.petrol_nozzles
                          WHEN 'Diesel' THEN st.diesel_nozzles
                          ELSE st.octane_nozzles END AS nozzle_count
      FROM fuel_products fp
      JOIN (VALUES ('Petrol', 18000.0, 1), ('Diesel', 9000.0, 2), ('Hi-Octane', 3000.0, 3))
           AS v (name, base, sort) ON v.name = fp.name
      ORDER BY v.sort
    LOOP
      -- current_volume is worked out from the stock ledger at the end.
      INSERT INTO tanks (station_id, product_id, capacity_liters, low_stock_threshold, current_volume)
      VALUES (v_station, g.product_id, 25000, 18000, 25000)
      RETURNING tank_id INTO v_tank;

      -- Two nozzles per pump, one grade per pump (as the app lays them out).
      -- The first Hi-Octane nozzle is faulty; every third nozzle is idle.
      FOR i IN 0 .. g.nozzle_count - 1 LOOP
        IF i % 2 = 0 THEN
          v_pump_no := v_pump_no + 1;
          INSERT INTO pumps (station_id, pump_number)
          VALUES (v_station, v_pump_no)
          RETURNING pump_id INTO v_pump;
        END IF;
        INSERT INTO nozzles (pump_id, tank_id, nozzle_number, status)
        VALUES (v_pump, v_tank, (i % 2) + 1,
                CASE WHEN i = 0 AND g.name = 'Hi-Octane' THEN 'fault'
                     WHEN i % 3 = 2 THEN 'idle'
                     ELSE 'dispensing' END);
      END LOOP;

      -- A year of sales, oldest first, ending today: each day the grade
      -- sells 85%-115% of its usual volume, split across its nozzles.
      -- MATERIALIZED makes each random litre figure a single value, so the
      -- total always equals litres x price (sales_total_matches_liters).
      -- Today's sales are capped at the current time.
      WITH sale AS MATERIALIZED (
        SELECT n.nozzle_id,
               round((g.base * st.scale * (0.85 + 0.3 * random()) / g.nozzle_count)::numeric, 2) AS liters,
               LEAST(d + interval '9 hours' + (n.nozzle_id % 40) * interval '7 minutes', localtimestamp) AS sale_time
        FROM generate_series(date_trunc('day', localtimestamp) - interval '364 days',
                             date_trunc('day', localtimestamp), interval '1 day') AS d
        CROSS JOIN nozzles n
        WHERE n.tank_id = v_tank
      )
      INSERT INTO sales (station_id, nozzle_id, employee_id, liters, unit_price, total_amount, sale_time)
      SELECT v_station, sale.nozzle_id, v_attendant, sale.liters, g.current_price,
             round(sale.liters * g.current_price, 2), sale.sale_time
      FROM sale;

      -- Each morning at 05:00 the depot refills what the tank sold the day
      -- before, at about 90% of the selling price. Loaded before 05:00,
      -- today's refill is dated now: today's sales (all of them, capped at
      -- the current time above) have already happened, and without it the
      -- tank would be drained by two days' sales at once.
      INSERT INTO deliveries (tank_id, received_by, supplier_name, liters_delivered, delivery_date,
                              cost_per_liter, invoice_ref)
      SELECT v_tank, v_manager, 'PARCO Depot, Mahmood Kot', day_sold.liters,
             LEAST(day_sold.sale_day + interval '1 day 5 hours', localtimestamp),
             round((g.current_price * (0.89 + 0.02 * random()))::numeric, 2),
             'INV-' || v_tank || '-' || to_char(day_sold.sale_day + interval '1 day', 'YYYYMMDD')
      FROM (SELECT date_trunc('day', s.sale_time) AS sale_day, sum(s.liters) AS liters
            FROM sales s JOIN nozzles n ON n.nozzle_id = s.nozzle_id
            WHERE n.tank_id = v_tank
            GROUP BY 1) AS day_sold
      WHERE day_sold.sale_day + interval '1 day' <= localtimestamp;

      -- The delivery about a week ago came from a purchase order placed the
      -- evening before; Petrol also has a pending order (well within the
      -- room today's sales leave).
      SELECT delivery_id, liters_delivered, delivery_date INTO v_delivery, v_liters, v_date
      FROM deliveries
      WHERE tank_id = v_tank AND delivery_date < localtimestamp - interval '7 days'
      ORDER BY delivery_date DESC
      LIMIT 1;
      IF v_delivery IS NOT NULL THEN
        INSERT INTO purchase_orders (station_id, tank_id, liters_ordered, vehicle, status, ordered_by, ordered_at)
        VALUES (v_station, v_tank, v_liters, CASE WHEN g.name = 'Petrol' THEN 'self' ELSE 'carriage' END,
                'delivered', v_owner, v_date - interval '10 hours')
        RETURNING purchase_order_id INTO v_order;
        UPDATE deliveries SET purchase_order_id = v_order WHERE delivery_id = v_delivery;
      END IF;
      IF g.name = 'Petrol' THEN
        INSERT INTO purchase_orders (station_id, tank_id, liters_ordered, vehicle, status, ordered_by, ordered_at)
        VALUES (v_station, v_tank, round(2000 * st.scale, 2), 'carriage', 'pending', v_owner,
                localtimestamp - interval '2 hours');
      END IF;

      -- The stock ledger: every delivery in, every sale out.
      INSERT INTO stock_ledger (tank_id, change_liters, reference_type, reference_id, recorded_at)
      SELECT v_tank, d.liters_delivered, 'delivery', d.delivery_id, d.delivery_date
      FROM deliveries d WHERE d.tank_id = v_tank;
      INSERT INTO stock_ledger (tank_id, change_liters, reference_type, reference_id, recorded_at)
      SELECT v_tank, -s.liters, 'sale', s.sale_id, s.sale_time
      FROM sales s JOIN nozzles n ON n.nozzle_id = s.nozzle_id
      WHERE n.tank_id = v_tank;

      -- Ten days ago the Diesel dip showed a small evaporation loss.
      IF g.name = 'Diesel' THEN
        INSERT INTO stock_adjustments (tank_id, adjusted_by, adjustment_liters, reason, adjusted_at)
        VALUES (v_tank, v_manager, -12.50, 'Evaporation loss found at the evening dip',
                date_trunc('day', localtimestamp) - interval '10 days' + interval '21 hours 30 minutes')
        RETURNING adjustment_id INTO v_adjust;
        INSERT INTO stock_ledger (tank_id, change_liters, reference_type, reference_id, recorded_at)
        VALUES (v_tank, -12.50, 'adjustment', v_adjust,
                date_trunc('day', localtimestamp) - interval '10 days' + interval '21 hours 30 minutes');
      END IF;

      -- The tank starts full a year ago; what's in it now is that plus
      -- everything the ledger recorded since.
      UPDATE tanks t
      SET current_volume = GREATEST(LEAST(
            t.capacity_liters + COALESCE((SELECT sum(l.change_liters) FROM stock_ledger l WHERE l.tank_id = t.tank_id), 0),
            t.capacity_liters), 0)
      WHERE t.tank_id = v_tank;

      -- Evening dips (21:00) for the last 30 days: what the ledger says the
      -- tank holds then, give or take 20 L of measuring error.
      INSERT INTO tank_readings (tank_id, recorded_by, reading_liters, reading_time)
      SELECT v_tank, v_attendant,
             GREATEST(round((25000 + COALESCE((SELECT sum(l.change_liters) FROM stock_ledger l
                                                WHERE l.tank_id = v_tank AND l.recorded_at <= dip_day + interval '21 hours'), 0)
                             + (random() * 40 - 20))::numeric, 2), 0),
             dip_day + interval '21 hours'
      FROM generate_series(date_trunc('day', localtimestamp) - interval '29 days',
                           date_trunc('day', localtimestamp), interval '1 day') AS dip_day
      WHERE dip_day + interval '21 hours' <= localtimestamp;
    END LOOP;

    -- Every sale is paid; one in five by card.
    INSERT INTO payments (sale_id, payment_method, amount, paid_at)
    SELECT s.sale_id, CASE WHEN s.sale_id % 5 = 0 THEN 'Card' ELSE 'Cash' END, s.total_amount, s.sale_time
    FROM sales s
    WHERE s.station_id = v_station;

    -- The last 30 days' shifts (06:00-22:00), worked by the attendant. Today's
    -- is still open; each closed shift's closing cash is its opening float
    -- plus the cash taken.
    INSERT INTO shifts (station_id, employee_id, shift_date, start_time, end_time, status, opening_cash)
    SELECT v_station, v_attendant, shift_day::date,
           LEAST(shift_day + interval '6 hours', localtimestamp),
           CASE WHEN shift_day < date_trunc('day', localtimestamp) THEN shift_day + interval '22 hours' END,
           CASE WHEN shift_day < date_trunc('day', localtimestamp) THEN 'closed' ELSE 'open' END,
           5000
    FROM generate_series(date_trunc('day', localtimestamp) - interval '29 days',
                         date_trunc('day', localtimestamp), interval '1 day') AS shift_day;
    UPDATE sales s
    SET shift_id = sh.shift_id
    FROM shifts sh
    WHERE sh.station_id = v_station AND s.station_id = v_station
      AND s.sale_time >= sh.start_time AND (sh.end_time IS NULL OR s.sale_time < sh.end_time);
    UPDATE shifts sh
    SET closing_cash = sh.opening_cash + COALESCE((
          SELECT sum(p.amount) FROM payments p JOIN sales s ON s.sale_id = p.sale_id
          WHERE s.shift_id = sh.shift_id AND p.payment_method = 'Cash'), 0)
    WHERE sh.station_id = v_station AND sh.status = 'closed';

    -- Each nozzle's meter at every shift's open and close (meters started
    -- at 100,000 L a year ago). The open shift has no closing reading yet.
    INSERT INTO nozzle_readings (shift_id, nozzle_id, opening_reading, closing_reading)
    SELECT sh.shift_id, n.nozzle_id,
           100000 + COALESCE((SELECT sum(s.liters) FROM sales s
                              WHERE s.nozzle_id = n.nozzle_id AND s.sale_time < sh.start_time), 0),
           CASE WHEN sh.status = 'closed' THEN
             100000 + COALESCE((SELECT sum(s.liters) FROM sales s
                                WHERE s.nozzle_id = n.nozzle_id AND s.sale_time < sh.end_time), 0)
           END
    FROM shifts sh
    JOIN pumps p ON p.station_id = sh.station_id
    JOIN nozzles n ON n.pump_id = p.pump_id
    WHERE sh.station_id = v_station;

    -- Today's vehicle log: one entry per pump, well within today's sales.
    INSERT INTO vehicle_transactions
      (station_id, nozzle_id, plate_number, fuel_type, liters, amount, nozzle_number,
       payment_method, vehicle_type, status, created_at)
    SELECT v_station, n.nozzle_id, 'LEA-' || (1000 + p.pump_number * 37), fp.name,
           CASE WHEN n.status = 'dispensing' THEN round(1500 * st.scale, 2) END,
           CASE WHEN n.status = 'dispensing' THEN round(1500 * st.scale * fp.current_price, 2) END,
           n.nozzle_number,
           CASE WHEN n.status = 'dispensing' THEN 'Cash' END,
           CASE WHEN p.pump_number % 2 = 0 THEN 'carriage' ELSE 'self' END,
           CASE WHEN n.status = 'dispensing' THEN 'completed' ELSE 'pending' END,
           LEAST(date_trunc('day', localtimestamp) + interval '8 hours' + p.pump_number * interval '20 minutes',
                 localtimestamp)
    FROM nozzles n
    JOIN pumps p ON p.pump_id = n.pump_id
    JOIN tanks t ON t.tank_id = n.tank_id
    JOIN fuel_products fp ON fp.product_id = t.product_id
    WHERE p.station_id = v_station AND n.nozzle_number = 1;

    -- Maintenance: the faulty nozzle is reported; an older issue was fixed.
    INSERT INTO maintenance_tickets (station_id, reported_by, issue_description, status, created_at)
    SELECT v_station, v_owner,
           'Pump ' || p.pump_number || ' nozzle ' || n.nozzle_number || ' shows a fault and is not dispensing.',
           'Open', localtimestamp - interval '3 hours'
    FROM nozzles n JOIN pumps p ON p.pump_id = n.pump_id
    WHERE p.station_id = v_station AND n.status = 'fault';
    INSERT INTO maintenance_tickets (station_id, reported_by, issue_description, status, created_at)
    VALUES (v_station, v_owner, 'Canopy light over pump 1 was flickering.', 'Resolved',
            localtimestamp - interval '20 days');
  END LOOP;

  -- The audit trail for what the owner set up: staff hired, orders placed.
  INSERT INTO audit_log (user_id, action, table_name, record_id, new_value, action_time)
  SELECT v_owner, 'INSERT', 'employees', e.employee_id,
         jsonb_build_object('full_name', e.full_name, 'position', e.position),
         e.hire_date::timestamp + interval '10 hours'
  FROM employees e WHERE e.owner_id = v_owner;
  INSERT INTO audit_log (user_id, action, table_name, record_id, new_value, action_time)
  SELECT v_owner, 'INSERT', 'purchase_orders', po.purchase_order_id,
         jsonb_build_object('po_number', po.po_number, 'liters_ordered', po.liters_ordered, 'status', po.status),
         po.ordered_at
  FROM purchase_orders po JOIN stations s ON s.id = po.station_id
  WHERE s.owner_id = v_owner;

  RAISE NOTICE 'Demo data loaded. Sign in as owner@parco.example / demo1234.';
END $$;
