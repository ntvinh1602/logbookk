
select
  f.user_id,
  f.id,
  f.flight_number,
  f.tail_number,
  f.departure_time,
  f.arrival_time,
  f.seat_number,
  f.ticket_class,
  f.seat_position,
  dep.iata_code as departure_code,
  dep.name as departure_name,
  dep.timezone as departure_tz,
  arr.iata_code as arrival_code,
  arr.name as arrival_name,
  arr.timezone as arrival_tz,
  al.name as airline_name,
  al.logo as airline_logo,
  ac.model as aircraft_type,
  dep.country = arr.country as is_domestic,
  round(
    dim.haversine_distance_km (dep.lat, dep.lng, arr.lat, arr.lng)::numeric,
    0
  ) as distance_km,
  concat(
    floor(
      EXTRACT(
        epoch
        from
          f.arrival_time - f.departure_time
      ) / 3600::numeric
    ),
    'h ',
    floor(
      EXTRACT(
        epoch
        from
          f.arrival_time - f.departure_time
      ) % 3600::numeric / 60::numeric
    ),
    'm'
  ) as duration
from
  dwd.flights f
  left join dim.airline al on al.icao_code = f.airline_code
  left join dim.aircraft ac on ac.icao_code = f.aircraft_type
  left join dim.airport dep on dep.iata_code = f.dept_airport_iata
  left join dim.airport arr on arr.iata_code = f.arr_airport_iata
order by
  f.departure_time desc;