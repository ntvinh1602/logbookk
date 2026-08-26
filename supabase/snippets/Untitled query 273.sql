select
  date_trunc(
    'month'::text,
    ds.snapshot_date::timestamp with time zone
  )::date as snapshot_date,
  sum(ds.intraday_pnl) as pnl,
  sum(ds.intraday_interest) as interest,
  sum(ds.intraday_tax) as tax,
  sum(ds.intraday_fee) as fee
from
  daily_snapshots ds
group by
  (
    date_trunc(
      'month'::text,
      ds.snapshot_date::timestamp with time zone
    )::date
  )
order by
  (
    date_trunc(
      'month'::text,
      ds.snapshot_date::timestamp with time zone
    )::date
  ) desc
limit
  12