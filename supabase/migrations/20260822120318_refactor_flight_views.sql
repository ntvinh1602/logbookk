-- Migration unit 1: schema_changes
-- Transaction mode: transactional
-- Boundary reason: default

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
                    WHEN (n.dept_airport_iata = n.airport_a_code) THEN ((a_1.iata_code || ' → '::text) || b_1.iata_code)
                    ELSE ((b_1.iata_code || ' → '::text) || a_1.iata_code)
                END AS direction_label,
            n.airline_name,
            array_agg(DISTINCT n.flight_number ORDER BY n.flight_number) FILTER (WHERE (n.flight_number IS NOT NULL)) AS flight_numbers
           FROM ((normalized n
             JOIN flight.airports a_1 ON ((a_1.iata_code = n.airport_a_code)))
             JOIN flight.airports b_1 ON ((b_1.iata_code = n.airport_b_code)))
          GROUP BY n.airport_a_code, n.airport_b_code,
                CASE
                    WHEN (n.dept_airport_iata = n.airport_a_code) THEN ((a_1.iata_code || ' → '::text) || b_1.iata_code)
                    ELSE ((b_1.iata_code || ' → '::text) || a_1.iata_code)
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
     JOIN flights_json fj ON (((fj.airport_a_code = rf.airport_a_code) AND (fj.airport_b_code = rf.airport_b_code))))
     JOIN flight.airports a ON ((a.iata_code = rf.airport_a_code)))
     JOIN flight.airports b ON ((b.iata_code = rf.airport_b_code)));

CREATE OR REPLACE VIEW flight.flights_summary WITH (security_invoker=on) AS SELECT f.user_id,
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

CREATE OR REPLACE VIEW flight.lifetime_stats WITH (security_invoker=on) AS WITH visited_airports AS (
         SELECT flights.user_id,
            flights.dept_airport_iata AS airport_code
           FROM flight.flights
        UNION
         SELECT flights.user_id,
            flights.arr_airport_iata
           FROM flight.flights
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
           FROM flight.flights_summary fs
          GROUP BY fs.user_id) f
     LEFT JOIN visited_airports va ON ((va.user_id = f.user_id)))
     LEFT JOIN flight.airports a ON ((a.iata_code = va.airport_code)))
  GROUP BY f.user_id, f.flights_count, f.type_count, f.total_distance, f.total_duration;

GRANT ALL ON flight.routes_geojson TO anon;

GRANT ALL ON flight.routes_geojson TO authenticated;

GRANT ALL ON flight.routes_geojson TO service_role;