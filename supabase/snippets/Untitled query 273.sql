with
  normalized as (
    select
      LEAST(f.dept_airport_iata, f.arr_airport_iata) as airport_a_code,
      GREATEST(f.dept_airport_iata, f.arr_airport_iata) as airport_b_code,
      f.dept_airport_iata,
      f.arr_airport_iata,
      f.flight_number,
      al.name as airline_name
    from
      dwd.flights f
      left join dim.airline al on al.icao_code = f.airline_code
  ),
  route_frequency_cte as (
    select
      normalized.airport_a_code,
      normalized.airport_b_code,
      count(*) as route_frequency
    from
      normalized
    group by
      normalized.airport_a_code,
      normalized.airport_b_code
  )
select
  a.iata_code as airport_a_code,
  b.iata_code as airport_b_code,
  a.lat as airport_a_lat,
  b.lat as airport_b_lat,
  a.lng as airport_a_lng,
  b.lng as airport_b_lng,
  rf.route_frequency
from
  route_frequency_cte rf
  join dim.airport a on a.iata_code = rf.airport_a_code
  join dim.airport b on b.iata_code = rf.airport_b_code;