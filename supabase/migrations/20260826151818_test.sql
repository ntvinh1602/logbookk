-- Migration unit 1: schema_changes
-- Transaction mode: transactional
-- Boundary reason: default

SET check_function_bodies = false;

CREATE FUNCTION dws.get_monthly_pnl_chart (
  p_start_date date,
  p_end_date   date
)
  RETURNS jsonb
  LANGUAGE sql
  STABLE
  SET search_path TO 'dws'
  AS $function$
  with months as (
    select
      generate_series(
        date_trunc('month', p_start_date)::date,
        date_trunc('month', p_end_date)::date,
        interval '1 month'
      )::date as snapshot_date
  ),

  monthly_snapshots as (
    select
      date_trunc('month', ds.snapshot_date)::date as snapshot_date,
      sum(ds.intraday_pnl) as pnl,
      sum(ds.intraday_interest) as interest,
      sum(ds.intraday_tax) as tax,
      sum(ds.intraday_fee) as fee
    from dws.daily_snapshots ds
    where
      ds.user_id = auth.uid()
      and ds.snapshot_date >= date_trunc('month', p_start_date)::date
      and ds.snapshot_date < (
        date_trunc('month', p_end_date)
        + interval '1 month'
      )::date
    group by
      date_trunc('month', ds.snapshot_date)::date
  )

  select jsonb_build_object(
    'snapshot_date',
    jsonb_agg(
      m.snapshot_date::text
      order by m.snapshot_date
    ),

    'revenue',
    jsonb_agg(
      coalesce(
        ms.pnl
        + ms.fee
        + ms.interest
        + ms.tax,
        0
      )
      order by m.snapshot_date
    ),

    'fee',
    jsonb_agg(
      coalesce(-ms.fee, 0)
      order by m.snapshot_date
    ),

    'interest',
    jsonb_agg(
      coalesce(-ms.interest, 0)
      order by m.snapshot_date
    ),

    'tax',
    jsonb_agg(
      coalesce(-ms.tax, 0)
      order by m.snapshot_date
    )
  )
  from months m
  left join monthly_snapshots ms
    using (snapshot_date);
$function$;

GRANT ALL ON FUNCTION dws.get_monthly_pnl_chart(date, date) TO anon;

GRANT ALL ON FUNCTION dws.get_monthly_pnl_chart(date, date) TO authenticated;

GRANT ALL ON FUNCTION dws.get_monthly_pnl_chart(date, date) TO service_role;