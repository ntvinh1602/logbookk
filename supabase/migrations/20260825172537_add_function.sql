-- Migration unit 1: schema_changes
-- Transaction mode: transactional
-- Boundary reason: default

SET check_function_bodies = false;

CREATE FUNCTION dws.calculate_vnindex_return (
  p_start_date date,
  p_end_date   date
)
  RETURNS numeric
  LANGUAGE sql
  STABLE
  SET search_path TO 'dim', 'dwd'
  AS $function$
  with vnindex as (
    select id
    from dim.asset
    where ticker = 'VNINDEX'
    limit 1
  ),
  first_price as (
    select dac.close
    from dwd.daily_asset_close dac
    join vnindex v on v.id = dac.asset_id
    order by
      (dac.date < p_start_date) desc,
      case
        when dac.date < p_start_date then dac.date
      end desc,
      dac.date
    limit 1
  ),
  last_price as (
    select dac.close
    from dwd.daily_asset_close dac
    join vnindex v on v.id = dac.asset_id
    where dac.date <= p_end_date
    order by dac.date desc
    limit 1
  )
  select last_price.close / first_price.close - 1
  from first_price
  cross join last_price;
$function$;

GRANT ALL ON FUNCTION dws.calculate_vnindex_return(date, date) TO anon;

GRANT ALL ON FUNCTION dws.calculate_vnindex_return(date, date) TO authenticated;

GRANT ALL ON FUNCTION dws.calculate_vnindex_return(date, date) TO service_role;