-- Migration unit 1: schema_changes
-- Transaction mode: transactional
-- Boundary reason: default

DROP VIEW dws.lifetime_stats;
DROP VIEW dws.flights_summary;
DROP VIEW dws.routes_geojson;

CREATE OR REPLACE VIEW dws.flights_summary WITH (security_invoker=on) AS SELECT f.user_id,
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
    round((dim.haversine_distance_km(dep.lat, dep.lng, arr.lat, arr.lng))::numeric, 0) AS distance_km,
    concat(floor((EXTRACT(epoch FROM (f.arrival_time - f.departure_time)) / (3600)::numeric)), 'h ', floor(((EXTRACT(epoch FROM (f.arrival_time - f.departure_time)) % (3600)::numeric) / (60)::numeric)), 'm') AS duration
   FROM ((((dwd.flights f
     LEFT JOIN dim.airline al ON ((al.icao_code = f.airline_code)))
     LEFT JOIN dim.aircraft ac ON ((ac.icao_code = f.aircraft_type)))
     LEFT JOIN dim.airport dep ON ((dep.iata_code = f.dept_airport_iata)))
     LEFT JOIN dim.airport arr ON ((arr.iata_code = f.arr_airport_iata)))
  ORDER BY f.departure_time DESC;

CREATE VIEW dws.unique_routes WITH (security_invoker=on) AS WITH normalized AS (
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
        )
 SELECT a.iata_code AS airport_a_code,
    b.iata_code AS airport_b_code,
    a.lat AS airport_a_lat,
    b.lat AS airport_b_lat,
    a.lng AS airport_a_lng,
    b.lng AS airport_b_lng,
    rf.route_frequency
   FROM ((route_frequency_cte rf
     JOIN dim.airport a ON ((a.iata_code = rf.airport_a_code)))
     JOIN dim.airport b ON ((b.iata_code = rf.airport_b_code)));

GRANT ALL ON dws.unique_routes TO anon;

GRANT ALL ON dws.unique_routes TO authenticated;

GRANT ALL ON dws.unique_routes TO service_role;

create view dws.lifetime_stats
with
  (security_invoker = on) as
with
  visited_airports as (
    select
      fd.user_id,
      fd.dept_airport_iata as airport_code
    from
      dwd.flights fd
    union
    select
      fa.user_id,
      fa.arr_airport_iata
    from
      dwd.flights fa
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
      dws.flights_summary fs
    group by
      fs.user_id
  ) f
  left join visited_airports va on va.user_id = f.user_id
  left join dim.airport a on a.iata_code = va.airport_code
group by
  f.user_id,
  f.flights_count,
  f.type_count,
  f.total_distance,
  f.total_duration;