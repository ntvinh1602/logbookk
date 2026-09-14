create view dws.lifetime_stats
with
  (security_invoker = on) as
select
  count(*) as flights,
  sum(
    case
      when dep.country = arr.country then 1
      else 0
    end
  ) as domestic,
  sum(
    case
      when dep.country = arr.country then 1
      else 0
    end
  ) as intl,
  sum(
    case
      when fs.seat_position = 'window' then 1
      else 0
    end
  ) as windows,
  sum(
    case
      when fs.seat_position = 'middle' then 1
      else 0
    end
  ) as middle,
  sum(
    case
      when fs.seat_position = 'aisle' then 1
      else 0
    end
  ) as aisle,
  round(
    sum(
      dim.haversine_distance_km (dep.lat, dep.lng, arr.lat, arr.lng)::numeric
    ),
    0
  ) as distance,
  round(
    EXTRACT(
      epoch
      from
        sum(fs.arrival_time - fs.departure_time)
    ) / 3600::numeric
  ) as duration
from
  dwd.flights fs
  join dim.airport dep on fs.dept_airport_iata = dep.iata_code
  join dim.airport arr on fs.arr_airport_iata = arr.iata_code