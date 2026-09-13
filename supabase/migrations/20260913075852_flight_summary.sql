-- Migration unit 1: schema_changes
-- Transaction mode: transactional
-- Boundary reason: default

DROP VIEW dws.flights_summary;

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
    (dep.country = arr.country) AS is_domestic,
    round((dim.haversine_distance_km(dep.lat, dep.lng, arr.lat, arr.lng))::numeric, 0) AS distance_km,
    concat(floor((EXTRACT(epoch FROM (f.arrival_time - f.departure_time)) / (3600)::numeric)), 'h ', floor(((EXTRACT(epoch FROM (f.arrival_time - f.departure_time)) % (3600)::numeric) / (60)::numeric)), 'm') AS duration
   FROM ((((dwd.flights f
     LEFT JOIN dim.airline al ON ((al.icao_code = f.airline_code)))
     LEFT JOIN dim.aircraft ac ON ((ac.icao_code = f.aircraft_type)))
     LEFT JOIN dim.airport dep ON ((dep.iata_code = f.dept_airport_iata)))
     LEFT JOIN dim.airport arr ON ((arr.iata_code = f.arr_airport_iata)))
  ORDER BY f.departure_time DESC;

GRANT ALL ON dws.flights_summary TO anon;

GRANT ALL ON dws.flights_summary TO authenticated;

GRANT ALL ON dws.flights_summary TO service_role;