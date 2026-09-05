-- Migration unit 1: schema_changes
-- Transaction mode: transactional
-- Boundary reason: default

SET check_function_bodies = false;

DROP TRIGGER after_new_tx_borrow ON dwd.tx_borrow;

DROP FUNCTION dwd.trg_process_tx_borrow();

DROP TRIGGER after_new_tx_cashflow ON dwd.tx_cashflow;

DROP FUNCTION dwd.trg_process_tx_cashflow();

DROP TRIGGER after_new_tx_repay ON dwd.tx_repay;

DROP FUNCTION dwd.trg_process_tx_repay();

DROP TRIGGER after_new_tx_stock ON dwd.tx_stock;

DROP FUNCTION dwd.trg_process_tx_stock();

DROP VIEW dws.balance_sheet;

CREATE TYPE dim.seat_position AS ENUM (
  'window',
  'middle',
  'aisle'
);

CREATE TYPE dim.ticket_class AS ENUM (
  'eco',
  'biz'
);

CREATE FUNCTION dim.haversine_distance_km (
  lat1 double precision,
  lng1 double precision,
  lat2 double precision,
  lng2 double precision
)
  RETURNS double precision
  LANGUAGE sql
  IMMUTABLE
  PARALLEL SAFE
  AS $function$
  select
    6371.0 * 2.0 * asin(
      sqrt(
        power(
          sin(radians(lat2 - lat1) / 2.0),
          2.0
        )
        +
        cos(radians(lat1))
        * cos(radians(lat2))
        * power(
          sin(radians(lng2 - lng1) / 2.0),
          2.0
        )
      )
    )
$function$;

GRANT ALL ON FUNCTION dim.haversine_distance_km(double precision, double precision, double precision, double precision) TO anon;

GRANT ALL ON FUNCTION dim.haversine_distance_km(double precision, double precision, double precision, double precision) TO authenticated;

GRANT ALL ON FUNCTION dim.haversine_distance_km(double precision, double precision, double precision, double precision) TO service_role;

CREATE TABLE dim.aircraft (
  icao_code text NOT NULL,
  model     text NOT NULL
);

ALTER TABLE dim.aircraft
  ADD CONSTRAINT aircrafts_pkey PRIMARY KEY (icao_code);

GRANT ALL ON dim.aircraft TO anon;

GRANT ALL ON dim.aircraft TO authenticated;

GRANT ALL ON dim.aircraft TO service_role;

CREATE TABLE dim.airline (
  name      text NOT NULL,
  logo      text NOT NULL,
  icao_code text NOT NULL
);

ALTER TABLE dim.airline
  ADD CONSTRAINT airlines_name_key UNIQUE (name);

ALTER TABLE dim.airline
  ADD CONSTRAINT airlines_pkey PRIMARY KEY (icao_code);

GRANT ALL ON dim.airline TO anon;

GRANT ALL ON dim.airline TO authenticated;

GRANT ALL ON dim.airline TO service_role;

CREATE TABLE dim.airport (
  icao_code text             NOT NULL,
  iata_code text             NOT NULL,
  name      text             NOT NULL,
  city      text             NOT NULL,
  country   text             NOT NULL,
  lat       double precision NOT NULL,
  lng       double precision NOT NULL,
  timezone  text             NOT NULL
);

ALTER TABLE dim.airport
  ADD CONSTRAINT airports_iata_code_key UNIQUE (iata_code);

ALTER TABLE dim.airport
  ADD CONSTRAINT airports_pkey PRIMARY KEY (icao_code);

ALTER TABLE dim.airport
  ADD CONSTRAINT timezone_format_check CHECK (timezone ~ '^[A-Za-z_]+/[A-Za-z_]+$'::text);

GRANT ALL ON dim.airport TO anon;

GRANT ALL ON dim.airport TO authenticated;

GRANT ALL ON dim.airport TO service_role;

CREATE OR REPLACE FUNCTION dwd.add_borrow_event (
  p_principal  numeric,
  p_lender     text,
  p_rate       numeric,
  p_created_at timestamp with time zone DEFAULT now()
)
  RETURNS void
  LANGUAGE plpgsql
  SET search_path TO 'dim', 'dwd'
  AS $function$
declare
  v_tx_id integer;
begin
  -- Insert into tx_entries
  insert into dwd.tx_entries (
    category,
    memo,
    user_id,
    created_a
  )
  values (
    'borrow',
    'Borrow ' || p_principal::text || ' from ' || p_lender || ' at ' || to_char(p_rate, 'FM90.##%'),
    auth.uid(),
    COALESCE(p_created_at, now())
  )
  returning id into v_tx_id;

  -- Insert into tx_debt
  insert into dwd.tx_borrow (
    tx_id,
    lender,
    principal,
    rate
  )
  values (
    v_tx_id,
    p_lender,
    p_principal,
    p_rate
  );

  PERFORM dwd.process_tx_borrow(v_tx_id);
end;
$function$;

CREATE OR REPLACE FUNCTION dwd.add_cashflow_event (
  p_operation  text,
  p_asset_id   smallint,
  p_quantity   numeric,
  p_fx_rate    numeric,
  p_memo       text,
  p_created_at timestamp with time zone DEFAULT now(),
  p_user_id    uuid                     DEFAULT auth.uid()
)
  RETURNS void
  LANGUAGE plpgsql
  SET search_path TO 'dim', 'dwd'
  AS $function$
declare
  v_tx_id integer;
  v_asset_currency_id smallint;
  v_fx_rate numeric;
begin
  -- Find asset currency
  select a.currency_id into v_asset_currency_id
  from dim.asset a
  where a.id = p_asset_id;

  -- Determine FX rate
  if v_asset_currency_id = 1 then v_fx_rate := 1;
  else v_fx_rate := coalesce(p_fx_rate, 1);
  end if;

  -- Insert into tx_entries
  insert into dwd.tx_entries (
    category,
    memo,
    user_id,
    created_at
  )
  values (
    'cashflow',
    p_memo,
    p_user_id,
    COALESCE(p_created_at, now())
  )
  returning id into v_tx_id;

  -- Insert into tx_cashflow
  insert into dwd.tx_cashflow (
    tx_id,
    asset_id,
    operation,
    quantity,
    fx_rate
  )
  values (
    v_tx_id,
    p_asset_id,
    p_operation::dim.cashflow_ops,
    p_quantity,
    v_fx_rate
  );

  PERFORM dwd.process_tx_cashflow(v_tx_id);
end;
$function$;

CREATE OR REPLACE FUNCTION dwd.add_repay_event (
  p_repay_tx   integer,
  p_interest   numeric,
  p_created_at timestamp with time zone DEFAULT now()
)
  RETURNS void
  LANGUAGE plpgsql
  SET search_path TO 'dim', 'dwd'
  AS $function$
declare
  v_tx_id integer;
  v_lender text;
  v_principal numeric;
begin
  -- Find lender name
  select b.lender into v_lender
  from dwd.tx_borrow b where b.tx_id = p_repay_tx;

  -- Find principal amount
  select b.principal into v_principal
  from dwd.tx_borrow b where b.tx_id = p_repay_tx;

  -- Insert into tx_entries
  insert into dwd.tx_entries (
    category,
    memo,
    user_id,
    created_a
  )
  values (
    'repay',
    'Repay to ' || v_lender,
    auth.uid(),
    COALESCE(p_created_at, now())
  ) returning id into v_tx_id;

  -- Insert into tx_repay
  insert into dwd.tx_repay (
    tx_id,
    borrow_tx,
    principal,
    interest
  )
  values (
    v_tx_id,
    p_repay_tx,
    v_principal,
    p_interest
  );

  PERFORM dwd.process_tx_repay(v_tx_id);
end;
$function$;

CREATE OR REPLACE FUNCTION dwd.add_stock_event (
  p_side       text,
  p_stock_id   smallint,
  p_price      numeric,
  p_quantity   numeric,
  p_fee        numeric,
  p_tax        numeric                  DEFAULT 0,
  p_user_id    uuid                     DEFAULT auth.uid(),
  p_created_at timestamp with time zone DEFAULT now()
)
  RETURNS void
  LANGUAGE plpgsql
  SET search_path TO 'dim', 'dwd'
  AS $function$
DECLARE
  v_tx_id integer;
  v_ticker text;
BEGIN
  select a.ticker into v_ticker
  from dim.asset a
  where a.id = p_stock_id;

  INSERT INTO dwd.tx_entries (
    category,
    memo,
    user_id,
    created_at
  )
  VALUES (
    'stock',
    initcap(p_side) || ' ' || p_quantity::text || ' ' || v_ticker || ' at ' || p_price::text,
    p_user_id,
    COALESCE(p_created_at, now())
  )
  RETURNING id INTO v_tx_id;

  INSERT INTO dwd.tx_stock (
    tx_id,
    operation,
    stock_id,
    price,
    quantity,
    fee,
    tax
  )
  VALUES (
    v_tx_id,
    p_side::dim.stock_ops,
    p_stock_id,
    p_price,
    p_quantity,
    p_fee,
    COALESCE(p_tax, 0)
  );

  PERFORM dwd.process_tx_stock(v_tx_id);
END;
$function$;

CREATE TABLE dwd.flights (
  id                integer                  GENERATED BY DEFAULT AS IDENTITY NOT NULL,
  flight_number     text                     NOT NULL,
  departure_time    timestamp with time zone NOT NULL,
  arrival_time      timestamp with time zone NOT NULL,
  seat_number       text,
  ticket_class      dim.ticket_class         NOT NULL,
  seat_position     dim.seat_position,
  tail_number       text,
  user_id           uuid                     NOT NULL,
  airline_code      text                     NOT NULL,
  dept_airport_iata text                     NOT NULL,
  arr_airport_iata  text                     NOT NULL,
  aircraft_type     text
);

ALTER TABLE dwd.flights
  ENABLE ROW LEVEL SECURITY;

ALTER TABLE dwd.flights
  ADD CONSTRAINT flights_aircraft_type_fkey FOREIGN KEY (aircraft_type) REFERENCES dim.aircraft(icao_code) ON UPDATE CASCADE;

ALTER TABLE dwd.flights
  ADD CONSTRAINT flights_airline_code_fkey FOREIGN KEY (airline_code) REFERENCES dim.airline(icao_code) ON UPDATE CASCADE;

ALTER TABLE dwd.flights
  ADD CONSTRAINT flights_arr_airport_iata_fkey FOREIGN KEY (arr_airport_iata) REFERENCES dim.airport(iata_code) ON UPDATE CASCADE;

ALTER TABLE dwd.flights
  ADD CONSTRAINT flights_dept_airport_iata_fkey FOREIGN KEY (dept_airport_iata) REFERENCES dim.airport(iata_code) ON UPDATE CASCADE;

ALTER TABLE dwd.flights
  ADD CONSTRAINT flights_pkey PRIMARY KEY (id);

ALTER TABLE dwd.flights
  ADD CONSTRAINT flights_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON UPDATE CASCADE ON DELETE CASCADE;

GRANT ALL ON dwd.flights TO anon;

GRANT ALL ON dwd.flights TO authenticated;

GRANT ALL ON dwd.flights TO service_role;

CREATE POLICY "Enable delete for users based on user_id" ON dwd.flights
  FOR DELETE
  USING ((( SELECT auth.uid() AS uid) = user_id));

CREATE POLICY "Enable insert for users based on user_id" ON dwd.flights
  FOR INSERT
  WITH CHECK ((( SELECT auth.uid() AS uid) = user_id));

CREATE POLICY "Enable update for users based on user_id" ON dwd.flights
  FOR UPDATE
  TO authenticated
  USING ((( SELECT auth.uid() AS uid) = user_id))
  WITH CHECK ((( SELECT auth.uid() AS uid) = user_id));

CREATE POLICY "Enable users to view their own data only" ON dwd.flights
  FOR SELECT
  TO authenticated
  USING ((( SELECT auth.uid() AS uid) = user_id));

CREATE VIEW dws.balance_sheet WITH (security_invoker=true) AS WITH user_legs AS (
         SELECT tl.tx_id,
            tl.asset_id,
            tl.quantity,
            tl.debit,
            tl.credit
           FROM (dwd.tx_legs tl
             JOIN dwd.tx_entries e ON ((e.id = tl.tx_id)))
          WHERE (e.user_id = auth.uid())
        ), debt_interest AS (
         SELECT sum(outstanding_debts.accrued_interest) AS sum
           FROM dws.outstanding_debts
        )
 SELECT a.ticker,
    a.name,
    a.asset_class,
    a.logo_url,
    c.iso_code AS currency,
    COALESCE(sum(ul.quantity), (0)::numeric) AS quantity,
    COALESCE((sum(ul.debit) - sum(ul.credit)), (0)::numeric) AS cost_basis,
        CASE
            WHEN (a.asset_class = ANY (ARRAY['stock'::dim.asset_class, 'fund'::dim.asset_class])) THEN round(sum((ul.quantity * COALESCE(sp.price, er.rate))), 0)
            WHEN (a.ticker = 'INTERESTS'::text) THEN ( SELECT sum(outstanding_debts.accrued_interest) AS sum
               FROM dws.outstanding_debts)
            ELSE sum(ul.quantity)
        END AS total_value,
    COALESCE(COALESCE(sp.price, er.rate), (0)::numeric) AS mkt_price,
    COALESCE(
        CASE
            WHEN (a.ticker = 'INTERESTS'::text) THEN (- ( SELECT sum(outstanding_debts.accrued_interest) AS sum
               FROM dws.outstanding_debts))
            ELSE round((sum((ul.quantity * COALESCE(sp.price, er.rate))) - (sum(ul.debit) - sum(ul.credit))), 0)
        END, (0)::numeric) AS net_profit
   FROM ((((dim.asset a
     JOIN dim.currency c ON ((a.currency_id = c.id)))
     LEFT JOIN user_legs ul ON ((a.id = ul.asset_id)))
     LEFT JOIN LATERAL ( SELECT (dac.close * (1000)::numeric) AS price
           FROM dwd.daily_asset_close dac
          WHERE (dac.asset_id = a.id)
          ORDER BY dac.date DESC
         LIMIT 1) sp ON (true))
     LEFT JOIN LATERAL ( SELECT dfx.close AS rate
           FROM dwd.daily_fxrate_close dfx
          WHERE (dfx.currency_id = a.currency_id)
          ORDER BY dfx.date DESC
         LIMIT 1) er ON (true))
  GROUP BY a.ticker, a.name, a.logo_url, c.iso_code, a.asset_class, sp.price, er.rate
 HAVING ((abs(sum(ul.quantity)) > (0)::numeric) OR (a.ticker = 'INTERESTS'::text))
  ORDER BY a.asset_class;

GRANT ALL ON dws.balance_sheet TO anon;

GRANT ALL ON dws.balance_sheet TO authenticated;

GRANT ALL ON dws.balance_sheet TO service_role;

CREATE VIEW dws.routes_geojson WITH (security_invoker=on) AS WITH normalized AS (
         SELECT LEAST(f.dept_airport_iata, f.arr_airport_iata) AS airport_a_code,
            GREATEST(f.dept_airport_iata, f.arr_airport_iata) AS airport_b_code,
            f.dept_airport_iata,
            f.arr_airport_iata,
            f.flight_number,
            al.name AS airline_name
           FROM (dwd.flights f
             LEFT JOIN dim.airline al ON ((al.icao_code = f.airline_code)))
        ), route_frequency_cte AS (
         SELECT normalized.airport_a_code,
            normalized.airport_b_code,
            count(*) AS route_frequency
           FROM normalized
          GROUP BY normalized.airport_a_code, normalized.airport_b_code
        ), direction_airline_grouped AS (
         SELECT n.airport_a_code,
            n.airport_b_code,
                CASE
                    WHEN (n.dept_airport_iata = n.airport_a_code) THEN ((n.airport_a_code || ' → '::text) || n.airport_b_code)
                    ELSE ((n.airport_b_code || ' → '::text) || n.airport_a_code)
                END AS direction_label,
            n.airline_name,
            array_agg(DISTINCT n.flight_number ORDER BY n.flight_number) FILTER (WHERE (n.flight_number IS NOT NULL)) AS flight_numbers
           FROM normalized n
          GROUP BY n.airport_a_code, n.airport_b_code,
                CASE
                    WHEN (n.dept_airport_iata = n.airport_a_code) THEN ((n.airport_a_code || ' → '::text) || n.airport_b_code)
                    ELSE ((n.airport_b_code || ' → '::text) || n.airport_a_code)
                END, n.airline_name
        ), direction_grouped AS (
         SELECT direction_airline_grouped.airport_a_code,
            direction_airline_grouped.airport_b_code,
            direction_airline_grouped.direction_label,
            jsonb_object_agg(direction_airline_grouped.airline_name, direction_airline_grouped.flight_numbers) AS airlines
           FROM direction_airline_grouped
          WHERE (direction_airline_grouped.airline_name IS NOT NULL)
          GROUP BY direction_airline_grouped.airport_a_code, direction_airline_grouped.airport_b_code, direction_airline_grouped.direction_label
        ), flights_json AS (
         SELECT direction_grouped.airport_a_code,
            direction_grouped.airport_b_code,
            jsonb_object_agg(direction_grouped.direction_label, direction_grouped.airlines) AS flights_by_direction
           FROM direction_grouped
          GROUP BY direction_grouped.airport_a_code, direction_grouped.airport_b_code
        )
 SELECT a.iata_code AS airport_a_code,
    b.iata_code AS airport_b_code,
    a.name AS airport_a_name,
    b.name AS airport_b_name,
    a.city AS airport_a_city,
    b.city AS airport_b_city,
    a.country AS airport_a_country,
    b.country AS airport_b_country,
    rf.route_frequency,
    fj.flights_by_direction,
    round((dim.haversine_distance_km(a.lat, a.lng, b.lat, b.lng))::numeric, 1) AS distance_km,
    jsonb_build_object('type', 'LineString', 'coordinates', jsonb_build_array(jsonb_build_array(a.lng, a.lat), jsonb_build_array(b.lng, b.lat))) AS geometry
   FROM (((route_frequency_cte rf
     JOIN flights_json fj ON (((fj.airport_a_code = rf.airport_a_code) AND (fj.airport_b_code = rf.airport_b_code))))
     JOIN dim.airport a ON ((a.iata_code = rf.airport_a_code)))
     JOIN dim.airport b ON ((b.iata_code = rf.airport_b_code)));

CREATE VIEW dws.flights_summary WITH (security_invoker=on) AS SELECT f.user_id,
    f.id,
    f.flight_number,
    f.tail_number,
    f.departure_time,
    f.arrival_time,
    f.seat_number,
    f.ticket_class,
    f.seat_position,
    dep.iata_code AS departure_code,
    dep.name AS departure_name,
    dep.timezone AS departure_tz,
    arr.iata_code AS arrival_code,
    arr.name AS arrival_name,
    arr.timezone AS arrival_tz,
    al.name AS airline_name,
    al.logo AS airline_logo,
    ac.model AS aircraft_type,
    r.distance_km,
    concat(floor((EXTRACT(epoch FROM (f.arrival_time - f.departure_time)) / (3600)::numeric)), 'h ', floor(((EXTRACT(epoch FROM (f.arrival_time - f.departure_time)) % (3600)::numeric) / (60)::numeric)), 'm') AS duration
   FROM (((((dwd.flights f
     LEFT JOIN dim.airline al ON ((al.icao_code = f.airline_code)))
     LEFT JOIN dim.aircraft ac ON ((ac.icao_code = f.aircraft_type)))
     LEFT JOIN dim.airport dep ON ((dep.iata_code = f.dept_airport_iata)))
     LEFT JOIN dim.airport arr ON ((arr.iata_code = f.arr_airport_iata)))
     LEFT JOIN dws.routes_geojson r ON (((r.airport_a_code = LEAST(f.dept_airport_iata, f.arr_airport_iata)) AND (r.airport_b_code = GREATEST(f.dept_airport_iata, f.arr_airport_iata)))))
  ORDER BY f.departure_time DESC;

GRANT ALL ON dws.flights_summary TO anon;

GRANT ALL ON dws.flights_summary TO authenticated;

GRANT ALL ON dws.flights_summary TO service_role;

CREATE VIEW dws.lifetime_stats WITH (security_invoker=on) AS WITH visited_airports AS (
         SELECT fd.user_id,
            fd.dept_airport_iata AS airport_code
           FROM dwd.flights fd
        UNION
         SELECT fa.user_id,
            fa.arr_airport_iata
           FROM dwd.flights fa
        )
 SELECT f.user_id,
    f.flights_count,
    count(DISTINCT va.airport_code) AS airports_count,
    count(DISTINCT a.country) AS country_count,
    f.type_count,
    f.total_distance,
    f.total_duration
   FROM ((( SELECT fs.user_id,
            count(*) AS flights_count,
            count(DISTINCT fs.aircraft_type) AS type_count,
            sum(fs.distance_km) AS total_distance,
            round((EXTRACT(epoch FROM sum((fs.arrival_time - fs.departure_time))) / (3600)::numeric)) AS total_duration
           FROM dws.flights_summary fs
          GROUP BY fs.user_id) f
     LEFT JOIN visited_airports va ON ((va.user_id = f.user_id)))
     LEFT JOIN dim.airport a ON ((a.iata_code = va.airport_code)))
  GROUP BY f.user_id, f.flights_count, f.type_count, f.total_distance, f.total_duration;

GRANT ALL ON dws.lifetime_stats TO anon;

GRANT ALL ON dws.lifetime_stats TO authenticated;

GRANT ALL ON dws.lifetime_stats TO service_role;

GRANT ALL ON dws.routes_geojson TO anon;

GRANT ALL ON dws.routes_geojson TO authenticated;

GRANT ALL ON dws.routes_geojson TO service_role;

ALTER TABLE ods.news_articles
  ALTER COLUMN excerpt SET NOT NULL;

ALTER TABLE ods.news_articles
  ALTER COLUMN published_at SET NOT NULL;

ALTER TABLE ods.news_articles
  ALTER COLUMN related_stocks SET NOT NULL;