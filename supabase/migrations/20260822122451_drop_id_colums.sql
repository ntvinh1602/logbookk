-- Migration unit 1: schema_changes
-- Transaction mode: transactional
-- Boundary reason: default

ALTER TABLE flight.flights
  DROP CONSTRAINT flights_aircrafts_id_fkey;

ALTER TABLE flight.flights
  DROP COLUMN aircraft_id;

ALTER TABLE flight.flights
  DROP CONSTRAINT flights_airlines_id_fkey;

ALTER TABLE flight.flights
  DROP COLUMN airline_id;

ALTER TABLE flight.flights
  DROP CONSTRAINT flights_arrival_airport_id_fkey;

ALTER TABLE flight.flights
  DROP COLUMN arrival_airport_id;

ALTER TABLE flight.flights
  DROP CONSTRAINT flights_departure_airport_id_fkey;

ALTER TABLE flight.flights
  DROP COLUMN departure_airport_id;

DROP VIEW flight.lifetime_stats;
DROP VIEW flight.flights_summary;

DROP VIEW flight.routes_geojson;

CREATE VIEW flight.routes_geojson WITH (security_invoker=on) AS WITH normalized AS (
         SELECT LEAST(f.dept_airport_iata, f.arr_airport_iata) AS airport_a_code,
            GREATEST(f.dept_airport_iata, f.arr_airport_iata) AS airport_b_code,
            f.dept_airport_iata,
            f.arr_airport_iata,
            f.flight_number,
            al.name AS airline_name
           FROM (flight.flights f
             LEFT JOIN flight.airlines al ON ((al.icao_code = f.airline_code)))
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
 SELECT gen_random_uuid() AS id,
    a.iata_code AS airport_a_code,
    b.iata_code AS airport_b_code,
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
     JOIN flights_json fj ON (((fj.airport_a_code = rf.airport_a_code) AND (fj.airport_b_code = rf.airport_b_code))))
     JOIN flight.airports a ON ((a.iata_code = rf.airport_a_code)))
     JOIN flight.airports b ON ((b.iata_code = rf.airport_b_code)));

CREATE VIEW flight.flights_summary WITH (security_invoker=on) AS SELECT f.user_id,
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
   FROM (((((flight.flights f
     LEFT JOIN flight.airlines al ON ((al.icao_code = f.airline_code)))
     LEFT JOIN flight.aircrafts ac ON ((ac.icao_code = f.aircraft_type)))
     LEFT JOIN flight.airports dep ON ((dep.iata_code = f.dept_airport_iata)))
     LEFT JOIN flight.airports arr ON ((arr.iata_code = f.arr_airport_iata)))
     LEFT JOIN flight.routes_geojson r ON (((r.airport_a_code = LEAST(f.dept_airport_iata, f.arr_airport_iata)) AND (r.airport_b_code = GREATEST(f.dept_airport_iata, f.arr_airport_iata)))))
  ORDER BY f.departure_time DESC;

create view flight.lifetime_stats
with
  (security_invoker = on) as
with
  visited_airports as (
    select
      flights.user_id,
      flights.dept_airport_iata as airport_code
    from
      flight.flights
    union
    select
      flights.user_id,
      flights.arr_airport_iata
    from
      flight.flights
  )
select
  f.user_id,
  f.flights_count,
  count(distinct va.airport_code) as airports_count,
  count(distinct a.country) as country_count,
  f.type_count,
  f.total_distance,
  f.total_duration
from
  (
    select
      fs.user_id,
      count(*) as flights_count,
      count(distinct fs.aircraft_type) as type_count,
      sum(fs.distance_km) as total_distance,
      round(
        EXTRACT(
          epoch
          from
            sum(fs.arrival_time - fs.departure_time)
        ) / 3600::numeric
      ) as total_duration
    from
      flight.flights_summary fs
    group by
      fs.user_id
  ) f
  left join visited_airports va on va.user_id = f.user_id
  left join flight.airports a on a.iata_code = va.airport_code
group by
  f.user_id,
  f.flights_count,
  f.type_count,
  f.total_distance,
  f.total_duration;

GRANT ALL ON flight.flights_summary TO anon;

GRANT ALL ON flight.flights_summary TO authenticated;

GRANT ALL ON flight.flights_summary TO service_role;

GRANT ALL ON flight.routes_geojson TO anon;

GRANT ALL ON flight.routes_geojson TO authenticated;

GRANT ALL ON flight.routes_geojson TO service_role;