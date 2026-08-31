-- Migration unit 1: schema_changes
-- Transaction mode: transactional
-- Boundary reason: default

SET check_function_bodies = false;

ALTER TABLE dwd.tx_cashflow
  ALTER COLUMN net_proceed TYPE numeric(16,0);

DROP EXTENSION if exists pg_graphql;

CREATE FUNCTION dws.get_event_borrow()
  RETURNS TABLE (
    tx_id      integer,
    created_at timestamp with time zone,
    lender     text,
    principal  numeric,
    rate       numeric
  )
  LANGUAGE sql
  STABLE
  AS $function$
  select
    b.tx_id,
    e.created_at,
    b.lender,
    b.principal,
    b.rate
  from dwd.tx_entries e
    join dwd.tx_borrow b on e.id = b.tx_id
  order by e.created_at desc;
$function$;

GRANT ALL ON FUNCTION dws.get_event_borrow() TO anon;

GRANT ALL ON FUNCTION dws.get_event_borrow() TO authenticated;

GRANT ALL ON FUNCTION dws.get_event_borrow() TO service_role;

CREATE FUNCTION dws.get_event_cashflow (
  p_start_date date DEFAULT NULL::date,
  p_end_date   date DEFAULT NULL::date,
  p_operation  text DEFAULT NULL::text
)
  RETURNS TABLE (
    tx_id       integer,
    created_at  timestamp with time zone,
    operation   text,
    memo        text,
    ticker      text,
    currency    text,
    quantity    numeric,
    net_proceed numeric
  )
  LANGUAGE sql
  STABLE
  AS $function$
  select
    cf.tx_id,
    e.created_at,
    cf.operation::text,
    e.memo,
    a.ticker,
    c.iso_code as currency,
    cf.quantity,
    cf.net_proceed
  from
    dwd.tx_entries e
    join dwd.tx_cashflow cf on e.id = cf.tx_id
    join dim.asset a on cf.asset_id = a.id
    left join dim.currency c on a.currency_id = c.id
  where
    (p_operation is null or cf.operation::text = p_operation)
    and (
      p_start_date is null
      or e.created_at >= p_start_date
    )
    and (
      p_end_date is null
      or e.created_at < p_end_date + interval '1 day'
    )
  order by e.created_at desc;
$function$;

GRANT ALL ON FUNCTION dws.get_event_cashflow(date, date, text) TO anon;

GRANT ALL ON FUNCTION dws.get_event_cashflow(date, date, text) TO authenticated;

GRANT ALL ON FUNCTION dws.get_event_cashflow(date, date, text) TO service_role;

CREATE FUNCTION dws.get_event_repay()
  RETURNS TABLE (
    tx_id      integer,
    created_at timestamp with time zone,
    borrow_tx  integer,
    lender     text,
    principal  numeric,
    interest   numeric
  )
  LANGUAGE sql
  STABLE
  AS $function$
  select
    r.tx_id,
    e.created_at,
    r.borrow_tx,
    b.lender,
    r.principal,
    r.interest
  from dwd.tx_entries e
    join dwd.tx_repay r on e.id = r.tx_id
    join dwd.tx_borrow b on r.borrow_tx = b.tx_id
  order by e.created_at desc;
$function$;

GRANT ALL ON FUNCTION dws.get_event_repay() TO anon;

GRANT ALL ON FUNCTION dws.get_event_repay() TO authenticated;

GRANT ALL ON FUNCTION dws.get_event_repay() TO service_role;

CREATE FUNCTION dws.get_event_stock (
  p_ticker     text DEFAULT NULL::text,
  p_operation  text DEFAULT NULL::text,
  p_start_date date DEFAULT NULL::date,
  p_end_date   date DEFAULT NULL::date
)
  RETURNS TABLE (
    tx_id       integer,
    created_at  timestamp with time zone,
    operation   text,
    ticker      text,
    price       numeric,
    quantity    numeric,
    fee         numeric,
    tax         numeric,
    net_proceed numeric,
    logo_url    text,
    name        text
  )
  LANGUAGE sql
  STABLE
  AS $function$
  select
    s.tx_id,
    e.created_at,
    s.operation::text,
    a.ticker,
    s.price,
    s.quantity,
    s.fee,
    s.tax,
    s.net_proceed,
    a.logo_url,
    a.name
  from dwd.tx_entries e
  join dwd.tx_stock s
    on e.id = s.tx_id
  join dim.asset a
    on s.stock_id = a.id
  where
    (p_ticker is null or a.ticker = p_ticker)
    and (p_operation is null or s.operation::text = p_operation)
    and (
      p_start_date is null
      or e.created_at >= p_start_date
    )
    and (
      p_end_date is null
      or e.created_at < p_end_date + interval '1 day'
    )
  order by e.created_at desc;
$function$;

GRANT ALL ON FUNCTION dws.get_event_stock(text, text, date, date) TO anon;

GRANT ALL ON FUNCTION dws.get_event_stock(text, text, date, date) TO authenticated;

GRANT ALL ON FUNCTION dws.get_event_stock(text, text, date, date) TO service_role;