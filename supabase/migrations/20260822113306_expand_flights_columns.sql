-- Migration unit 1: schema_changes
-- Transaction mode: transactional
-- Boundary reason: default

SET check_function_bodies = false;

CREATE FUNCTION flight.haversine_distance_km (
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

GRANT ALL ON FUNCTION flight.haversine_distance_km(double precision, double precision, double precision, double precision) TO anon;

GRANT ALL ON FUNCTION flight.haversine_distance_km(double precision, double precision, double precision, double precision) TO authenticated;

GRANT ALL ON FUNCTION flight.haversine_distance_km(double precision, double precision, double precision, double precision) TO service_role;

ALTER TABLE flight.airlines
  ADD COLUMN icao_code text;

ALTER TABLE flight.airlines
  ADD CONSTRAINT airlines_icao_code_key UNIQUE (icao_code);

ALTER TABLE flight.airports
  ENABLE ROW LEVEL SECURITY;

ALTER TABLE flight.flights
  ENABLE ROW LEVEL SECURITY;

ALTER TABLE flight.flights
  ADD COLUMN airline_code text;

ALTER TABLE flight.flights
  ADD CONSTRAINT flights_airline_code_fkey FOREIGN KEY (airline_code) REFERENCES flight.airlines(icao_code) ON UPDATE CASCADE;

ALTER TABLE flight.flights
  ADD COLUMN dept_airport_iata text;

COMMENT ON COLUMN flight.flights.dept_airport_iata IS 'IATA code of departure airport';

ALTER TABLE flight.flights
  ADD CONSTRAINT flights_dept_airport_iata_fkey FOREIGN KEY (dept_airport_iata) REFERENCES flight.airports(iata_code) ON UPDATE CASCADE;

ALTER TABLE flight.flights
  ADD COLUMN arr_airport_iata text;

COMMENT ON COLUMN flight.flights.arr_airport_iata IS 'IATA code of arrival airport';

ALTER TABLE flight.flights
  ADD CONSTRAINT flights_arr_airport_iata_fkey FOREIGN KEY (arr_airport_iata) REFERENCES flight.airports(iata_code) ON UPDATE CASCADE;

ALTER TABLE flight.flights
  ADD COLUMN aircraft_type text;

COMMENT ON COLUMN flight.flights.aircraft_type IS 'ICAO code of aircraft type';

ALTER TABLE flight.flights
  ADD CONSTRAINT flights_aircraft_type_fkey FOREIGN KEY (aircraft_type) REFERENCES flight.aircrafts(icao_code) ON UPDATE CASCADE;

CREATE OR REPLACE VIEW flight.routes_geojson WITH (security_invoker=on) AS WITH normalized AS (
         SELECT LEAST(f.departure_airport_id, f.arrival_airport_id) AS airport_a_id,
            GREATEST(f.departure_airport_id, f.arrival_airport_id) AS airport_b_id,
            f.departure_airport_id,
            f.arrival_airport_id,
            f.flight_number,
            al.name AS airline_name
           FROM (flight.flights f
             LEFT JOIN flight.airlines al ON ((al.id = f.airline_id)))
        ), route_frequency_cte AS (
         SELECT normalized.airport_a_id,
            normalized.airport_b_id,
            count(*) AS route_frequency
           FROM normalized
          GROUP BY normalized.airport_a_id, normalized.airport_b_id
        ), direction_airline_grouped AS (
         SELECT n.airport_a_id,
            n.airport_b_id,
                CASE
                    WHEN (n.departure_airport_id = n.airport_a_id) THEN ((a_1.iata_code || ' → '::text) || b_1.iata_code)
                    ELSE ((b_1.iata_code || ' → '::text) || a_1.iata_code)
                END AS direction_label,
            n.airline_name,
            array_agg(DISTINCT n.flight_number ORDER BY n.flight_number) FILTER (WHERE (n.flight_number IS NOT NULL)) AS flight_numbers
           FROM ((normalized n
             JOIN flight.airports a_1 ON ((a_1.id = n.airport_a_id)))
             JOIN flight.airports b_1 ON ((b_1.id = n.airport_b_id)))
          GROUP BY n.airport_a_id, n.airport_b_id,
                CASE
                    WHEN (n.departure_airport_id = n.airport_a_id) THEN ((a_1.iata_code || ' → '::text) || b_1.iata_code)
                    ELSE ((b_1.iata_code || ' → '::text) || a_1.iata_code)
                END, n.airline_name
        ), direction_grouped AS (
         SELECT direction_airline_grouped.airport_a_id,
            direction_airline_grouped.airport_b_id,
            direction_airline_grouped.direction_label,
            jsonb_object_agg(direction_airline_grouped.airline_name, direction_airline_grouped.flight_numbers) AS airlines
           FROM direction_airline_grouped
          WHERE (direction_airline_grouped.airline_name IS NOT NULL)
          GROUP BY direction_airline_grouped.airport_a_id, direction_airline_grouped.airport_b_id, direction_airline_grouped.direction_label
        ), flights_json AS (
         SELECT direction_grouped.airport_a_id,
            direction_grouped.airport_b_id,
            jsonb_object_agg(direction_grouped.direction_label, direction_grouped.airlines) AS flights_by_direction
           FROM direction_grouped
          GROUP BY direction_grouped.airport_a_id, direction_grouped.airport_b_id
        )
 SELECT gen_random_uuid() AS id,
    a.id AS airport_a_id,
    b.id AS airport_b_id,
    a.iata_code AS airport_a_iata,
    b.iata_code AS airport_b_iata,
    a.name AS airport_a_name,
    b.name AS airport_b_name,
    a.city AS airport_a_city,
    b.city AS airport_b_city,
    a.country AS airport_a_country,
    b.country AS airport_b_country,
    rf.route_frequency,
    fj.flights_by_direction,
    round((flight.haversine_distance_km(a.lat, a.lng, b.lat, b.lng))::numeric, 1) AS distance_km,
    jsonb_build_object('type', 'LineString', 'coordinates', jsonb_build_array(jsonb_build_array(a.lng, a.lat), jsonb_build_array(b.lng, b.lat))) AS geometry
   FROM (((route_frequency_cte rf
     JOIN flights_json fj ON (((fj.airport_a_id = rf.airport_a_id) AND (fj.airport_b_id = rf.airport_b_id))))
     JOIN flight.airports a ON ((a.id = rf.airport_a_id)))
     JOIN flight.airports b ON ((b.id = rf.airport_b_id)));