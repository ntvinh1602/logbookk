SET local check_function_bodies = off;

CREATE OR REPLACE FUNCTION dwd.process_dnse_order()
  RETURNS TRIGGER
  LANGUAGE plpgsql
  SET search_path TO 'ods', 'dim', 'dwd'
  AS $function$
BEGIN
  DECLARE
    v_user_id uuid;
    v_asset_id smallint;

  BEGIN
    -- Map broker account → internal user_id
    SELECT us.user_id
      INTO v_user_id
    FROM dim.user_settings us
    WHERE us.dnse_account_id = NEW.account_no;

    -- Safety guard (important)
    IF v_user_id IS NULL THEN
      RAISE WARNING 'No user mapping found for account_no=%', NEW.account_no;
      RETURN NULL;
    END IF;

    -- Map symbol → asset_id
    SELECT a.id
      INTO v_asset_id
    FROM dim.asset a
    WHERE a.ticker = NEW.symbol;

    -- Only process relevant statuses
    IF NEW.order_status = 'Filled'
      AND COALESCE(NEW.fill_quantity, 0) > 0 THEN
      PERFORM dwd.add_stock_event(
        NEW.side::text,
        v_asset_id,
        NEW.avg_price,
        NEW.fill_quantity,
        NEW.fee,
        NEW.tax,
        v_user_id,
        NEW.received_at
      );
    END IF;
    RETURN NULL;
  END;
END;
$function$;

CREATE OR REPLACE FUNCTION dws.recompute_daily_snapshots (
  p_user_id   uuid DEFAULT NULL::uuid,
  p_from_date date DEFAULT NULL::date
)
  RETURNS void
  LANGUAGE plpgsql
  SECURITY DEFINER
  SET search_path TO 'dim', 'dwd', 'dws'
  AS $function$
declare
  v_from date := coalesce(p_from_date, '-infinity'::date);
begin
  -- Remove the slice we are about to rebuild (rows before v_from are the
  -- cumulative seed and are left untouched).
  delete from dws.daily_snapshots
  where snapshot_date >= v_from
    and (p_user_id is null or user_id = p_user_id);

  insert into dws.daily_snapshots (
    snapshot_date, 
    user_id, 
    total_equity,
    intraday_cashflow,
    intraday_fee,
    intraday_tax,
    intraday_interest,
    total_cashflow,
    intraday_pnl,
    intraday_return
  )
  with users as (
    select
      user_id,
      (min(created_at))::date as start_date
    from dwd.tx_entries
    where user_id is not null
      and (p_user_id is null or user_id = p_user_id)
    group by user_id
  ),
  user_days as (
    select
      u.user_id,
      (gs.d)::date as snapshot_date
    from users u
    cross join lateral generate_series(
      (greatest(u.start_date, v_from))::timestamptz,
      (current_date)::timestamptz,
      '1 day'::interval) gs(d)
    where extract(isodow from gs.d) not in (6, 7)
  ),
  daily_deltas as (
    select
      e.user_id,
      (e.created_at)::date as activity_date,
      tl.asset_id,
      a.currency_id,
      sum(tl.quantity) as dq
    from dwd.tx_legs tl
    join dwd.tx_entries e on e.id = tl.tx_id
    join dim.asset a on a.id = tl.asset_id
    where a.asset_class NOT IN ('equity', 'liability')
      and (p_user_id is null or e.user_id = p_user_id)
    group by e.user_id, (e.created_at)::date, tl.asset_id, a.currency_id
  ),
  asset_intervals as (
    select
    dd.user_id,
    dd.asset_id,
    dd.currency_id,
    sum(dd.dq) over (
      partition by dd.user_id, dd.asset_id, dd.currency_id
      order by dd.activity_date
      rows between unbounded preceding and current row) as cum_qty,
    dd.activity_date as valid_from,
    coalesce(lead(dd.activity_date) over (
      partition by dd.user_id, dd.asset_id, dd.currency_id
      order by dd.activity_date), 'infinity'::date) as valid_to
    from daily_deltas dd
  ),
  positions as (
    -- generate_series clipped to v_from forward: this is the main saving,
    -- the expensive per-day price/fx lookups run only for days >= v_from.
    select
      (gs.d)::date as snapshot_date,
      ai.user_id,
      ai.asset_id,
      ai.currency_id,
      ai.cum_qty as quantity
    from asset_intervals ai
    cross join lateral generate_series(
      (greatest(ai.valid_from, v_from))::timestamp,
      (least((ai.valid_to - 1), current_date))::timestamp,
      '1 day'::interval) gs(d)
    where extract(isodow from gs.d) not in (6, 7)
  ),
  total_assets_per_day as (
    select
      pos.user_id,
      pos.snapshot_date,
      coalesce(sum(pos.quantity * coalesce(pr.price, 1::numeric) * coalesce(fx.rate, 1::numeric)), 0::numeric) as total_assets
    from positions pos
    left join lateral (
      select (dac.close * 1000::numeric) as price
      from dwd.daily_asset_close dac
      where dac.asset_id = pos.asset_id and dac.date <= pos.snapshot_date
      order by dac.date desc
      limit 1) pr on true
    left join lateral (
      select dfc.close as rate
      from dwd.daily_fxrate_close dfc
      where dfc.currency_id = pos.currency_id and dfc.date <= pos.snapshot_date
      order by dfc.date desc
      limit 1) fx on true
    group by pos.user_id, pos.snapshot_date
  ),
  debt_events as (
    select
      e_b.user_id,
      b_1.tx_id as borrow_tx_id,
      b_1.principal,
      b_1.rate,
      (e_b.created_at)::date as borrow_date,
      (e_r.created_at)::date as repay_date
    from dwd.tx_borrow b_1
    join dwd.tx_entries e_b on e_b.id = b_1.tx_id
    left join dwd.tx_repay r on r.borrow_tx = b_1.tx_id
    left join dwd.tx_entries e_r on e_r.id = r.tx_id
    where (p_user_id is null or e_b.user_id = p_user_id)
  ),
  debt_balances_by_day as (
    select
      d.snapshot_date,
      de.user_id,
      de.borrow_tx_id,
      de.principal,
      de.rate,
      de.borrow_date,
      de.repay_date,
      case
        when de.repay_date is not null and de.repay_date <= d.snapshot_date then 0::numeric
        else de.principal * power(1::numeric + (de.rate / 100.0) / 365.0, (greatest(d.snapshot_date - de.borrow_date, 0))::numeric)
      end as balance_at_date
    from debt_events de
    join user_days d on d.user_id = de.user_id
    where de.borrow_date <= d.snapshot_date
  ),
  total_liabilities_per_day as (
    select
      debt_balances_by_day.user_id,
      debt_balances_by_day.snapshot_date,
      coalesce(sum(debt_balances_by_day.balance_at_date), 0::numeric) as total_liabilities
    from debt_balances_by_day
    group by debt_balances_by_day.user_id, debt_balances_by_day.snapshot_date
  ),
  cashflow_per_day as (
    select
      e.user_id,
      (e.created_at)::date as snapshot_date,
      coalesce(sum(tl.credit) - sum(tl.debit), 0::numeric) as intraday_cashflow
    from dwd.tx_entries e
    join dwd.tx_legs tl on tl.tx_id = e.id
    join dim.asset a on a.id = tl.asset_id
    join dwd.tx_cashflow cf on cf.tx_id = e.id
    where cf.operation IN ('deposit', 'withdraw')
      and a.asset_class = 'equity'::dim.asset_class
      and (p_user_id is null or e.user_id = p_user_id)
    group by e.user_id, (e.created_at)::date
  ),
  tax_fee_per_day as (
      select
        e.user_id,
        (e.created_at)::date as snapshot_date,
        (coalesce(sum(s.fee), 0::numeric) + coalesce(sum(cf.net_proceed) filter (where e.memo = 'Operational fees'), 0::numeric)) as total_fees,
        coalesce(sum(s.tax), 0::numeric) as total_taxes,
        coalesce(sum(r.interest), 0::numeric) as loan_interest,
        coalesce(sum(cf.net_proceed) filter (where e.memo in ('Margin interest', 'Cash advance interest')), 0::numeric) as margin_interest
      from dwd.tx_entries e
      left join dwd.tx_repay r on r.tx_id = e.id
      left join dwd.tx_stock s on s.tx_id = e.id
      left join dwd.tx_cashflow cf on cf.tx_id = e.id
      where (p_user_id is null or e.user_id = p_user_id)
      group by e.user_id, (e.created_at)::date
  ),
  base as (
    select
      d.snapshot_date,
      d.user_id,
      coalesce(nc.intraday_cashflow, 0::numeric) as intraday_cashflow,
      round(coalesce(tad.total_assets, 0::numeric) - coalesce(tld.total_liabilities, 0::numeric)) as total_equity,
      coalesce(tf.total_fees, 0::numeric) as intraday_fee,
      coalesce(tf.total_taxes, 0::numeric) as intraday_tax,
      coalesce(tf.loan_interest + tf.margin_interest, 0::numeric) as intraday_interest
    from user_days d
      left join total_assets_per_day tad on tad.snapshot_date = d.snapshot_date
        and tad.user_id = d.user_id
      left join total_liabilities_per_day tld on tld.snapshot_date = d.snapshot_date 
        and tld.user_id = d.user_id
      left join cashflow_per_day nc on nc.snapshot_date  = d.snapshot_date
        and nc.user_id  = d.user_id
      left join tax_fee_per_day tf on tf.snapshot_date  = d.snapshot_date
        and tf.user_id  = d.user_id
  ),
  seeds as (
    -- last stored row strictly before v_from = cumulative seed per user
    select
      distinct on (user_id)
      user_id,
      total_cashflow as seed_cashflow,
      total_equity as seed_equity
    from dws.daily_snapshots
    where snapshot_date < v_from
      and (p_user_id is null or user_id = p_user_id)
    order by user_id, snapshot_date desc
  )
  select
    b.snapshot_date,
    b.user_id,
    b.total_equity,
    b.intraday_cashflow,
    b.intraday_fee,
    b.intraday_tax,
    b.intraday_interest,
    round(coalesce(s.seed_cashflow, 0::numeric) + sum(b.intraday_cashflow) over w_running) as total_cashflow,
    case
      when coalesce(lag(b.total_equity) over w_ord, s.seed_equity) is null then 0::numeric
      when coalesce(lag(b.total_equity) over w_ord, s.seed_equity) = 0::numeric then 0::numeric
      else (b.total_equity - b.intraday_cashflow) - coalesce(lag(b.total_equity) over w_ord, s.seed_equity)
    end as intraday_pnl,
    case
      when coalesce(lag(b.total_equity) over w_ord, s.seed_equity) is null then 0::numeric
      when coalesce(lag(b.total_equity) over w_ord, s.seed_equity) = 0::numeric then 0::numeric
      else ((b.total_equity - b.intraday_cashflow) - coalesce(lag(b.total_equity) over w_ord, s.seed_equity)) / nullif(coalesce(lag(b.total_equity) over w_ord, s.seed_equity), 0::numeric)
    end as intraday_return
  from base b
  left join seeds s on s.user_id = b.user_id
  window
    w_ord as (partition by b.user_id order by b.snapshot_date),
    w_running as (partition by b.user_id order by b.snapshot_date rows between unbounded preceding and current row)
    on conflict (user_id, snapshot_date) do update set
    total_equity      = excluded.total_equity,
    intraday_cashflow = excluded.intraday_cashflow,
    intraday_fee      = excluded.intraday_fee,
    intraday_tax      = excluded.intraday_tax,
    intraday_interest = excluded.intraday_interest,
    total_cashflow    = excluded.total_cashflow,
    intraday_pnl      = excluded.intraday_pnl,
    intraday_return   = excluded.intraday_return;
end;
$function$;
