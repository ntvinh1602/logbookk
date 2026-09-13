-- Migration unit 1: schema_changes
-- Transaction mode: transactional
-- Boundary reason: default

DROP VIEW dws.lifetime_stats;

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
    f.domestic_count,
    count(DISTINCT va.airport_code) AS airports_count,
    count(DISTINCT a.country) AS country_count,
    f.type_count,
    f.total_distance,
    f.total_duration
   FROM ((( SELECT fs.user_id,
            count(*) AS flights_count,
            sum(
                CASE
                    WHEN (dep.country = arr.country) THEN 1
                    ELSE 0
                END) AS domestic_count,
            count(DISTINCT fs.aircraft_type) AS type_count,
            round(sum((dim.haversine_distance_km(dep.lat, dep.lng, arr.lat, arr.lng))::numeric), 0) AS total_distance,
            round((EXTRACT(epoch FROM sum((fs.arrival_time - fs.departure_time))) / (3600)::numeric)) AS total_duration
           FROM ((dwd.flights fs
             JOIN dim.airport dep ON ((fs.dept_airport_iata = dep.iata_code)))
             JOIN dim.airport arr ON ((fs.arr_airport_iata = arr.iata_code)))
          GROUP BY fs.user_id) f
     LEFT JOIN visited_airports va ON ((va.user_id = f.user_id)))
     LEFT JOIN dim.airport a ON ((a.iata_code = va.airport_code)))
  GROUP BY f.user_id, f.flights_count, f.domestic_count, f.type_count, f.total_distance, f.total_duration;

GRANT ALL ON dws.lifetime_stats TO anon;

GRANT ALL ON dws.lifetime_stats TO authenticated;

GRANT ALL ON dws.lifetime_stats TO service_role;