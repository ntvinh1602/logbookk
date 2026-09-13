-- Migration unit 1: schema_changes
-- Transaction mode: transactional
-- Boundary reason: default

SET check_function_bodies = false;

CREATE FUNCTION dws.get_top_aircrafts()
  RETURNS TABLE (
    aircraft_model text,
    count          integer
  )
  LANGUAGE sql
  STABLE
  AS $function$
  select
    a.model as aircraft_model,
    count(f.id)
  from dwd.flights f
    join dim.aircraft a on f.aircraft_type = a.icao_code
  group by a.model
  order by count(f.id) desc
  limit 5;
$function$;

GRANT ALL ON FUNCTION dws.get_top_aircrafts() TO anon;

GRANT ALL ON FUNCTION dws.get_top_aircrafts() TO authenticated;

GRANT ALL ON FUNCTION dws.get_top_aircrafts() TO service_role;

CREATE FUNCTION dws.get_top_airlines()
  RETURNS TABLE (
    airlines_logo text,
    airlines_name text,
    count         integer
  )
  LANGUAGE sql
  STABLE
  AS $function$
  select
    a.logo as airlines_logo,
    a.name as airlines_name,
    count(f.id)
  from dwd.flights f
    join dim.airline a on f.airline_code = a.icao_code
  group by a.logo, a.name
  order by count(f.id) desc
  limit 5;
$function$;

GRANT ALL ON FUNCTION dws.get_top_airlines() TO anon;

GRANT ALL ON FUNCTION dws.get_top_airlines() TO authenticated;

GRANT ALL ON FUNCTION dws.get_top_airlines() TO service_role;

CREATE FUNCTION dws.get_top_airports()
  RETURNS TABLE (
    airport_code text,
    airport_name text,
    count        integer
  )
  LANGUAGE sql
  STABLE
  AS $function$
  select
    combine.airport_code,
    a.name as airport_name,
    count(combine.airport_code)
  from (
    select
      dep.id as flight_id,
      dep.dept_airport_iata as airport_code
    from dwd.flights dep
    union
    select
      arr.id,
      arr.arr_airport_iata
    from dwd.flights arr
  ) combine
  join dim.airport a on combine.airport_code = a.iata_code
  group by combine.airport_code, a.name
  order by count(airport_code) desc
  limit 5;
$function$;

GRANT ALL ON FUNCTION dws.get_top_airports() TO anon;

GRANT ALL ON FUNCTION dws.get_top_airports() TO authenticated;

GRANT ALL ON FUNCTION dws.get_top_airports() TO service_role;

CREATE FUNCTION dws.get_top_routes()
  RETURNS TABLE (
    airport_a_code text,
    airport_b_code text,
    frequency      integer
  )
  LANGUAGE sql
  STABLE
  AS $function$
  select
    LEAST(f.dept_airport_iata, f.arr_airport_iata) as airport_a_code,
    GREATEST(f.dept_airport_iata, f.arr_airport_iata) as airport_b_code,
    count(*) as frequency
  from dwd.flights f
  group by airport_a_code, airport_b_code
  order by frequency desc
  limit 5;
$function$;

GRANT ALL ON FUNCTION dws.get_top_routes() TO anon;

GRANT ALL ON FUNCTION dws.get_top_routes() TO authenticated;

GRANT ALL ON FUNCTION dws.get_top_routes() TO service_role;