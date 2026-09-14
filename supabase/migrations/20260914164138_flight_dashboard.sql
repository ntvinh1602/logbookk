-- Migration unit 1: schema_changes
-- Transaction mode: transactional
-- Boundary reason: default

SET check_function_bodies = false;

DROP VIEW dws.lifetime_stats;

CREATE FUNCTION dws.get_flights_by_month()
  RETURNS TABLE (
    month_number integer,
    month        text,
    flights      integer
  )
  LANGUAGE sql
  STABLE
  AS $function$
  SELECT
    EXTRACT(MONTH FROM departure_time)::int AS month_number,
    TO_CHAR(departure_time, 'Mon') AS month,
    COUNT(*)::int AS flights
  FROM dwd.flights
  GROUP BY 1, 2
  ORDER BY 1;
$function$;

GRANT ALL ON FUNCTION dws.get_flights_by_month() TO anon;

GRANT ALL ON FUNCTION dws.get_flights_by_month() TO authenticated;

GRANT ALL ON FUNCTION dws.get_flights_by_month() TO service_role;

CREATE FUNCTION dws.get_flights_by_weekday()
  RETURNS TABLE (
    weekday_number integer,
    weekday        text,
    flights        integer
  )
  LANGUAGE sql
  STABLE
  AS $function$
SELECT
  EXTRACT(ISODOW FROM departure_time)::int AS weekday_number,
  TO_CHAR(departure_time, 'Dy') AS weekday,
  COUNT(*)::int AS flights
FROM dwd.flights
GROUP BY 1, 2
ORDER BY 1;
$function$;

GRANT ALL ON FUNCTION dws.get_flights_by_weekday() TO anon;

GRANT ALL ON FUNCTION dws.get_flights_by_weekday() TO authenticated;

GRANT ALL ON FUNCTION dws.get_flights_by_weekday() TO service_role;

CREATE FUNCTION dws.get_flights_by_year()
  RETURNS TABLE (
    year    integer,
    flights integer
  )
  LANGUAGE sql
  STABLE
  AS $function$
  SELECT
    EXTRACT(YEAR FROM years.year)::int AS year,
    COUNT(f.id)::int AS flights
  FROM generate_series(
    DATE_TRUNC(
      'year',
      (SELECT MIN(departure_time)
      FROM dwd.flights)
    ),
    DATE_TRUNC('year', CURRENT_DATE),
    '1 year'
  ) AS years(year)
  LEFT JOIN dwd.flights f
    ON f.departure_time >= years.year
    AND f.departure_time < years.year + INTERVAL '1 year'
    AND f.user_id = auth.uid()
  GROUP BY years.year
  ORDER BY years.year;
$function$;

GRANT ALL ON FUNCTION dws.get_flights_by_year() TO anon;

GRANT ALL ON FUNCTION dws.get_flights_by_year() TO authenticated;

GRANT ALL ON FUNCTION dws.get_flights_by_year() TO service_role;

CREATE VIEW dws.lifetime_stats WITH (security_invoker=on) AS SELECT count(*) AS flights,
    sum(
        CASE
            WHEN (dep.country = arr.country) THEN 1
            ELSE 0
        END) AS domestic,
    sum(
        CASE
            WHEN (dep.country = arr.country) THEN 0
            ELSE 1
        END) AS intl,
    sum(
        CASE
            WHEN (fs.seat_position = 'window'::dim.seat_position) THEN 1
            ELSE 0
        END) AS windows,
    sum(
        CASE
            WHEN (fs.seat_position = 'middle'::dim.seat_position) THEN 1
            ELSE 0
        END) AS middle,
    sum(
        CASE
            WHEN (fs.seat_position = 'aisle'::dim.seat_position) THEN 1
            ELSE 0
        END) AS aisle,
    round(sum((dim.haversine_distance_km(dep.lat, dep.lng, arr.lat, arr.lng))::numeric), 0) AS distance,
    round((EXTRACT(epoch FROM sum((fs.arrival_time - fs.departure_time))) / (3600)::numeric)) AS duration
   FROM ((dwd.flights fs
     JOIN dim.airport dep ON ((fs.dept_airport_iata = dep.iata_code)))
     JOIN dim.airport arr ON ((fs.arr_airport_iata = arr.iata_code)));

GRANT ALL ON dws.lifetime_stats TO anon;

GRANT ALL ON dws.lifetime_stats TO authenticated;

GRANT ALL ON dws.lifetime_stats TO service_role;