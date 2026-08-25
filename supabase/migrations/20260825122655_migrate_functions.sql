-- Migration unit 1: schema_changes
-- Transaction mode: transactional
-- Boundary reason: default

SET check_function_bodies = false;

CREATE TYPE dim.benchmark_point AS (
  snapshot_date   date,
  portfolio_value numeric,
  vni_value       numeric
);

CREATE TYPE dim.equity_point AS (
  snapshot_date  date,
  total_cashflow numeric,
  total_equity   numeric
);

CREATE FUNCTION dwd.add_borrow_event (
  p_principal  numeric,
  p_lender     text,
  p_rate       numeric,
  p_created_at timestamp with time zone DEFAULT now()
)
  RETURNS void
  LANGUAGE plpgsql
  SET search_path TO 'dim', 'dwd'
  AS $function$
declare
  v_tx_id integer;
begin
  -- Insert into tx_entries
  insert into dwd.tx_entries (
    category,
    memo,
    user_id,
    created_a
  )
  values (
    'borrow',
    'Borrow ' || p_principal::text || ' from ' || p_lender || ' at ' || to_char(p_rate, 'FM90.##%'),
    auth.uid(),
    COALESCE(p_created_at, now())
  )
  returning id into v_tx_id;

  -- Insert into tx_debt
  insert into dwd.tx_borrow (
    tx_id,
    lender,
    principal,
    rate
  )
  values (
    v_tx_id,
    p_lender,
    p_principal,
    p_rate
  );
end;
$function$;

CREATE FUNCTION dwd.add_cashflow_event (
  p_operation  text,
  p_asset_id   smallint,
  p_quantity   numeric,
  p_fx_rate    numeric,
  p_memo       text,
  p_created_at timestamp with time zone DEFAULT now(),
  p_user_id    uuid                     DEFAULT auth.uid()
)
  RETURNS void
  LANGUAGE plpgsql
  SET search_path TO 'dim', 'dwd'
  AS $function$
declare
  v_tx_id integer;
  v_asset_currency_id smallint;
  v_fx_rate numeric;
begin
  -- Find asset currency
  select a.currency_id into v_asset_currency_id
  from dim.asset a
  where a.id = p_asset_id;

  -- Determine FX rate
  if v_asset_currency_id = 1 then v_fx_rate := 1;
  else v_fx_rate := coalesce(p_fx_rate, 1);
  end if;

  -- Insert into tx_entries
  insert into dwd.tx_entries (
    category,
    memo,
    user_id,
    created_at
  )
  values (
    'cashflow',
    p_memo,
    p_user_id,
    COALESCE(p_created_at, now())
  )
  returning id into v_tx_id;

  -- Insert into tx_cashflow
  insert into dwd.tx_cashflow (
    tx_id,
    asset_id,
    operation,
    quantity,
    fx_rate
  )
  values (
    v_tx_id,
    p_asset_id,
    p_operation::dim.cashflow_ops,
    p_quantity,
    v_fx_rate
  );
end;
$function$;

CREATE FUNCTION dwd.add_repay_event (
  p_repay_tx   integer,
  p_interest   numeric,
  p_created_at timestamp with time zone DEFAULT now()
)
  RETURNS void
  LANGUAGE plpgsql
  SET search_path TO 'dim', 'dwd'
  AS $function$
declare
  v_tx_id integer;
  v_lender text;
  v_principal numeric;
begin
  -- Find lender name
  select b.lender into v_lender
  from dwd.tx_borrow b where b.tx_id = p_repay_tx;

  -- Find principal amount
  select b.principal into v_principal
  from dwd.tx_borrow b where b.tx_id = p_repay_tx;

  -- Insert into tx_entries
  insert into dwd.tx_entries (
    category,
    memo,
    user_id,
    created_a
  )
  values (
    'repay',
    'Repay to ' || v_lender,
    auth.uid(),
    COALESCE(p_created_at, now())
  ) returning id into v_tx_id;

  -- Insert into tx_repay
  insert into dwd.tx_repay (
    tx_id,
    borrow_tx,
    principal,
    interest
  )
  values (
    v_tx_id,
    p_repay_tx,
    v_principal,
    p_interest
  );
end;
$function$;

CREATE FUNCTION dwd.add_stock_event (
  p_side       text,
  p_ticker     text,
  p_price      numeric,
  p_quantity   numeric,
  p_fee        numeric,
  p_tax        numeric                  DEFAULT 0,
  p_user_id    uuid                     DEFAULT auth.uid(),
  p_created_at timestamp with time zone DEFAULT now()
)
  RETURNS void
  LANGUAGE plpgsql
  SET search_path TO 'dim', 'dwd'
  AS $function$
DECLARE
  v_tx_id integer;
  v_stock_id smallint;
BEGIN
  SELECT id INTO v_stock_id
  FROM dwd.asset
  WHERE ticker = p_ticker;

  INSERT INTO dwd.tx_entries (
    category,
    memo,
    user_id,
    created_at
  )
  VALUES (
    'stock',
    initcap(p_side) || ' ' || p_quantity::text || ' ' || p_ticker || ' at ' || p_price::text,
    p_user_id,
    COALESCE(p_created_at, now())
  )
  RETURNING id INTO v_tx_id;

  INSERT INTO dwd.tx_stock (
    tx_id,
    operation,
    stock_id,
    price,
    quantity,
    fee,
    tax
  )
  VALUES (
    v_tx_id,
    p_side::dim.stock_ops,
    v_stock_id,
    p_price,
    p_quantity,
    p_fee,
    COALESCE(p_tax, 0)
  );
END;
$function$;

CREATE FUNCTION dwd.process_dnse_order()
  RETURNS TRIGGER
  LANGUAGE plpgsql
  SET search_path TO 'ods', 'dim', 'dwd'
  AS $function$
BEGIN
  DECLARE
    v_user_id uuid;

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

    -- Only process relevant statuses
    IF NEW.order_status = 'Filled'
      AND COALESCE(NEW.fill_quantity, 0) > 0 THEN
      PERFORM dwd.add_stock_event(
        NEW.side::text,
        NEW.symbol,
        NEW.avg_price,
        NEW.fill_quantity,
        NEW.fee,
        NEW.tax,
        v_user_id
      );
    END IF;
    RETURN NULL;
  END;
END;
$function$;

CREATE FUNCTION dwd.process_tx_borrow (
  p_tx_id integer
)
  RETURNS void
  LANGUAGE plpgsql
  SET search_path TO 'dim', 'dwd'
  AS $function$
declare
  r dwd.tx_borrow%rowtype;
  v_cash_asset smallint;
  v_debt_asset smallint;
begin
  select * into r
  from dwd.tx_borrow
  where tx_id = p_tx_id;

  select id into v_cash_asset
  from dim.asset
  where ticker = 'FX.VND';

  select id into v_debt_asset
  from dim.asset
  where ticker = 'DEBTS';

  -- Clear any prior legs for this transaction
  delete from dwd.tx_legs where tx_id = p_tx_id;

  -- Debit cash (proceeds received)
  insert into dwd.tx_legs (
    tx_id,
    asset_id,
    quantity,
    debit,
    credit
  )
  values (
    r.tx_id,
    v_cash_asset,
    r.principal,
    r.principal,
    0
  );

  -- Credit debt (liability created)
  insert into dwd.tx_legs (
    tx_id,
    asset_id,
    quantity,
    debit,
    credit
  )
  values (
    r.tx_id,
    v_debt_asset, 
    r.principal,
    0,
    r.principal
  );
end;
$function$;

CREATE FUNCTION dwd.process_tx_cashflow (
  p_tx_id integer
)
  RETURNS void
  LANGUAGE plpgsql
  SET search_path TO 'dim', 'dwd'
  AS $function$
DECLARE
  r dwd.tx_cashflow%rowtype;
  v_equity_asset smallint;
  v_user_id uuid;
  v_current_qty numeric;
  v_cost_change numeric;
  v_realized_pnl numeric;
  v_current_cost numeric;
BEGIN
  -- Derive user_id from tx_entries (works for both trigger and rebuild_ledger paths)
  SELECT e.user_id INTO v_user_id
  FROM dwd.tx_entries e
  WHERE e.id = p_tx_id;

  -- Load transaction
  SELECT * INTO r
  FROM dwd.tx_cashflow
  WHERE tx_id = p_tx_id;

  -- Identify assets
  SELECT id INTO v_equity_asset
  FROM dim.asset
  WHERE ticker = 'CAPITAL';

  -- Clear existing legs
  DELETE FROM dwd.tx_legs WHERE tx_id = p_tx_id;

  -- Handle by operation type
  IF r.operation IN ('deposit', 'income') THEN
    -- Debit cash asset
    INSERT INTO dwd.tx_legs (
      tx_id,
      asset_id,
      quantity,
      debit,
      credit
    )
    VALUES (
      r.tx_id,
      r.asset_id,
      r.quantity,
      r.net_proceed,
      0
    );

    -- Credit equity (capital in)
    INSERT INTO dwd.tx_legs (
      tx_id,
      asset_id, 
      quantity,
      debit,
      credit
    )
    VALUES (
      r.tx_id,
      v_equity_asset,
      r.net_proceed,
      0,
      r.net_proceed
    );

  ELSE -- Withdraw and expense operation

    -- Calculate current total cost & quantity
    SELECT SUM(l.debit) - SUM(l.credit), SUM(l.quantity)
    INTO v_current_cost, v_current_qty
    FROM dwd.tx_legs l
      JOIN dwd.tx_entries e ON l.tx_id = e.id
    WHERE l.asset_id = r.asset_id AND e.user_id = v_user_id;

    v_cost_change := r.quantity * v_current_cost / v_current_qty;
    v_realized_pnl := r.net_proceed - v_cost_change;

    -- Credit cash asset (reduce balance)
    INSERT INTO dwd.tx_legs (tx_id, asset_id, quantity, debit, credit)
    VALUES (r.tx_id, r.asset_id, -r.quantity, 0, v_cost_change);

    -- Debit equity (capital out & possible gain/loss to equity)
    INSERT INTO dwd.tx_legs (tx_id, asset_id, quantity, debit, credit)
    VALUES (
      r.tx_id,
      v_equity_asset,
      -v_cost_change,
      r.net_proceed + GREATEST(-v_realized_pnl, 0),
      0 + GREATEST(v_realized_pnl, 0)
    );
  END IF;
END;
$function$;

CREATE FUNCTION dwd.process_tx_repay (
  p_tx_id integer
)
  RETURNS void
  LANGUAGE plpgsql
  SET search_path TO 'dim', 'dwd'
  AS $function$
declare
  r dwd.tx_repay%rowtype;
  v_cash_asset smallint;
  v_debt_asset smallint;
  v_equity_asset smallint;
begin
  select * into r from dwd.tx_repay where tx_id = p_tx_id;

  select id into v_cash_asset
  from dim.asset
  where ticker = 'FX.VND';

  select id into v_debt_asset
  from dim.asset
  where ticker = 'DEBTS';

  select id into v_equity_asset
  from dim.asset
  where ticker = 'CAPITAL';

  -- Clear any prior legs for this transaction
  delete from dwd.tx_legs where tx_id = p_tx_id;

  -- Credit cash (payment made)
  insert into dwd.tx_legs (tx_id, asset_id, quantity, debit, credit)
  values (r.tx_id, v_cash_asset, -r.net_proceed, 0, r.net_proceed);

  -- Debit debt (liability reduced by principal)
  insert into dwd.tx_legs (tx_id, asset_id, quantity, debit, credit)
  values (r.tx_id, v_debt_asset, -r.principal, r.principal, 0);

  -- Debit equity (interest expense)
  insert into dwd.tx_legs (tx_id, asset_id, quantity, debit, credit)
  values (r.tx_id, v_equity_asset, -r.interest, r.interest, 0);
end;
$function$;

CREATE FUNCTION dwd.process_tx_stock (
  p_tx_id integer
)
  RETURNS void
  LANGUAGE plpgsql
  SET search_path TO 'dim', 'dwd'
  AS $function$declare
  r dwd.tx_stock%rowtype;
  v_cash_asset smallint;
  v_equity_asset smallint;
  v_realized_pnl numeric;
  v_cost_change numeric;
  v_user_id uuid;
  v_current_cost numeric;
  v_current_qty numeric;
begin
  -- Derive user_id from tx_entries (works for both trigger and rebuild_ledger paths)
  SELECT e.user_id INTO v_user_id
  FROM dwd.tx_entries e
  WHERE e.id = p_tx_id;

  -- Load the transaction
  select * into r from dwd.tx_stock where tx_id = p_tx_id;

  -- Resolve asset IDs
  select id into v_cash_asset
  from dim.asset
  where ticker ='FX.VND';

  select id into v_equity_asset
  from dim.asset
  where ticker = 'CAPITAL';

  -- Process transaction
  if r.operation = 'buy' then

    -- Debit stock (increase holdings)
    insert into dwd.tx_legs (tx_id, asset_id, quantity, debit, credit)
    values (r.tx_id, r.stock_id, r.quantity, r.net_proceed, 0);

    -- Credit VND cash
    insert into dwd.tx_legs (tx_id, asset_id, quantity, debit, credit)
    values (r.tx_id, v_cash_asset, -r.net_proceed, 0, r.net_proceed);

  else -- Sell side

    -- Calculate current total cost & quantity
    SELECT SUM(l.debit) - SUM(l.credit), SUM(l.quantity)
    INTO v_current_cost, v_current_qty
    FROM dwd.tx_legs l
      JOIN dwd.tx_entries e ON l.tx_id = e.id
    WHERE l.asset_id = r.stock_id AND e.user_id = v_user_id;

    v_cost_change := r.quantity * v_current_cost / v_current_qty;
    v_realized_pnl := r.net_proceed - v_cost_change;

    -- Debit cash
    insert into dwd.tx_legs (tx_id, asset_id, quantity, debit, credit)
    values (r.tx_id, v_cash_asset, r.net_proceed, r.net_proceed, 0);

    -- Credit stock (reduce holdings)
    insert into dwd.tx_legs (tx_id, asset_id, quantity, debit, credit)
    values (r.tx_id, r.stock_id, -r.quantity, 0, v_cost_change);

    -- Post gain/loss to equity
    insert into dwd.tx_legs (tx_id, asset_id, quantity, debit, credit)
    values (
      r.tx_id,
      v_equity_asset,
      v_realized_pnl,
      GREATEST(-v_realized_pnl, 0),
      GREATEST(v_realized_pnl, 0)
    );
  end if;
end;
$function$;

CREATE FUNCTION dwd.rebuild_ledger()
  RETURNS void
  LANGUAGE plpgsql
  SET search_path TO 'dim', 'dwd'
  AS $function$
declare
  tx record;
begin
  raise notice 'Rebuilding ledger (positions + legs)...';

  -- Step 1: clear all derived data
  truncate table dwd.tx_legs cascade;

  -- Step 2: replay all transactions in chronological order
  for tx in
    select id, category, created_at
    from dwd.tx_entries
    order by created_at asc
  loop
    case tx.category
      when 'stock'::dim.tx_category then
        perform dwd.process_tx_stock(tx.id);

      when 'cashflow'::dim.tx_category then
        perform dwd.process_tx_cashflow(tx.id);

      when 'borrow'::dim.tx_category then
        perform dwd.process_tx_borrow(tx.id);

      when 'repay'::dim.tx_category then
        perform dwd.process_tx_repay(tx.id);

      else
        raise exception 'Unhandled tx category: %', tx.category;
    end case;
  end loop;

  raise notice 'Ledger rebuild completed.';
end;
$function$;

CREATE FUNCTION dwd.trg_process_tx_borrow()
  RETURNS TRIGGER
  LANGUAGE plpgsql
  SET search_path TO 'dwd'
  AS $function$
begin
  perform dwd.process_tx_borrow(new.tx_id);
  return new;
end;
$function$;

CREATE FUNCTION dwd.trg_process_tx_cashflow()
  RETURNS TRIGGER
  LANGUAGE plpgsql
  SET search_path TO 'dwd'
  AS $function$begin
  perform dwd.process_tx_cashflow(new.tx_id);
  return new;
end;$function$;

CREATE FUNCTION dwd.trg_process_tx_repay()
  RETURNS TRIGGER
  LANGUAGE plpgsql
  SET search_path TO 'dwd'
  AS $function$
begin
  perform dwd.process_tx_repay(new.tx_id);
  return new;
end;
$function$;

CREATE FUNCTION dwd.trg_process_tx_stock()
  RETURNS TRIGGER
  LANGUAGE plpgsql
  SET search_path TO 'dwd'
  AS $function$begin
  perform dwd.process_tx_stock(new.tx_id);
  return new;
end;$function$;

CREATE FUNCTION dwd.upsert_daily_asset_close()
  RETURNS TRIGGER
  LANGUAGE plpgsql
  SET search_path TO 'dim', 'dwd'
  AS $function$
BEGIN
  INSERT INTO dwd.daily_asset_close (asset_id, date, close)
  SELECT
    a.id,
    -- Use last_updated if available, fall back to bar_time
    (NEW.last_updated AT TIME ZONE 'UTC')::date,
    NEW.close
  FROM dim.asset a
  WHERE a.ticker = NEW.symbol
  ON CONFLICT (asset_id, date)
  DO UPDATE SET
    close = EXCLUDED.close;

  RETURN NULL;
END;
$function$;

CREATE OR REPLACE TRIGGER after_new_tx_borrow
  AFTER INSERT ON dwd.tx_borrow
  FOR EACH ROW
  EXECUTE FUNCTION dwd.trg_process_tx_borrow();

CREATE OR REPLACE TRIGGER after_new_tx_cashflow
  AFTER INSERT ON dwd.tx_cashflow
  FOR EACH ROW
  EXECUTE FUNCTION dwd.trg_process_tx_cashflow();

CREATE OR REPLACE TRIGGER after_new_tx_repay
  AFTER INSERT ON dwd.tx_repay
  FOR EACH ROW
  EXECUTE FUNCTION dwd.trg_process_tx_repay();

CREATE OR REPLACE TRIGGER after_new_tx_stock
  AFTER INSERT ON dwd.tx_stock
  FOR EACH ROW
  EXECUTE FUNCTION dwd.trg_process_tx_stock();

CREATE FUNCTION dws.active_stock_tickers()
  RETURNS jsonb
  LANGUAGE sql
  STABLE
  SET search_path TO 'dim', 'dwd'
  AS $function$
  select coalesce(
  jsonb_agg(ticker order by ticker),
  '[]'::jsonb
)
from (
  select a.ticker
  from dwd.tx_legs l
  join dim.asset a on a.id = l.asset_id
  where a.asset_class = 'stock'
  group by a.ticker
  having sum(l.quantity) > 0

  union

  select 'VNINDEX' as ticker
) t(ticker);
$function$;

CREATE FUNCTION dws.calculate_pnl (
  p_start_date date,
  p_end_date   date
)
  RETURNS numeric
  LANGUAGE plpgsql
  SET search_path TO 'dws'
  AS $function$
DECLARE
  v_pnl NUMERIC;
BEGIN
  SELECT COALESCE(sum(intraday_pnl), 0)
    INTO v_pnl
  FROM dws.daily_snapshots
  WHERE user_id = auth.uid()
    AND snapshot_date >= p_start_date
    AND snapshot_date <= p_end_date;

  RETURN v_pnl;
END;
$function$;

CREATE FUNCTION dws.calculate_twr (
  p_start_date date,
  p_end_date   date
)
  RETURNS numeric
  LANGUAGE plpgsql
  SET search_path TO 'dws'
  AS $function$
DECLARE
  v_twr NUMERIC;
BEGIN
  SELECT COALESCE(EXP(SUM(LN(1 + intraday_return))) - 1, 0)
    INTO v_twr
  FROM dws.daily_snapshots
  WHERE user_id = auth.uid()
    AND snapshot_date >= p_start_date
    AND snapshot_date <= p_end_date
    AND intraday_return IS NOT NULL
    AND intraday_return > -1;   -- guard against ln(0) / ln(negative)

  RETURN COALESCE(v_twr, 0);
END;
$function$;

CREATE FUNCTION dws.get_equity_chart (
  p_start_date date,
  p_end_date   date,
  p_threshold  integer DEFAULT 150
)
  RETURNS jsonb
  LANGUAGE plpgsql
  SET search_path TO 'dim', 'dwd', 'dws'
  AS $function$
DECLARE
  raw_data dim.equity_point[];
  result_data dim.equity_point[];
  data_count int;
  every numeric;
  i int;
  a int := 0;
  range_start int;
  range_end int;
  avg_x numeric;
  avg_y numeric;
  max_area numeric;
  point_area numeric;
  selected dim.equity_point;
  prev dim.equity_point;
  final_result jsonb;
BEGIN
  -- Load dataset into memory
  SELECT array_agg(
    ROW(snapshot_date, total_equity, total_cashflow)::dim.equity_point
    ORDER BY snapshot_date
  )
  INTO raw_data
  FROM dws.daily_snapshots
  WHERE user_id = auth.uid()
    AND snapshot_date BETWEEN p_start_date AND p_end_date;

  data_count := array_length(raw_data, 1);

  IF data_count IS NULL OR data_count = 0 THEN
    RETURN '[]'::jsonb;
  END IF;

  IF data_count <= p_threshold THEN
    RETURN (
      SELECT jsonb_build_object(
        'd', jsonb_agg((extract(epoch from x.snapshot_date)/86400)::int ORDER BY x.ord),
        'e', jsonb_agg(round(x.total_equity) ORDER BY x.ord),
        'c', jsonb_agg(round(x.total_cashflow) ORDER BY x.ord)
      )
      FROM unnest(raw_data) WITH ORDINALITY
          AS x(snapshot_date, total_equity, total_cashflow, ord)
    );
  END IF;

  result_data := ARRAY[ raw_data[1] ];
  every := (data_count - 2.0) / (p_threshold - 2.0);

  FOR i IN 0..p_threshold - 3 LOOP
    range_start := floor(a * every)::int + 2;
    range_end := floor((a + 1) * every)::int + 1;

    IF range_end > data_count THEN
      range_end := data_count;
    END IF;

    SELECT
      AVG(EXTRACT(EPOCH FROM r.snapshot_date)),
      AVG(r.total_equity)
    INTO avg_x, avg_y
    FROM unnest(raw_data[range_start:range_end]) r;

    max_area := -1;
    prev := result_data[array_length(result_data,1)];

    FOR selected IN
      SELECT * FROM unnest(raw_data[range_start:range_end])
    LOOP
      point_area := abs(
        (EXTRACT(EPOCH FROM prev.snapshot_date) - avg_x)
        * (selected.total_equity - prev.total_equity)
        -
        (EXTRACT(EPOCH FROM prev.snapshot_date)
         - EXTRACT(EPOCH FROM selected.snapshot_date))
        * (avg_y - prev.total_equity)
      ) * 0.5;

      IF point_area > max_area THEN
        max_area := point_area;
        raw_data[range_start] := selected;
      END IF;
    END LOOP;

    result_data := result_data || raw_data[range_start];
    a := a + 1;
  END LOOP;

  result_data := result_data || raw_data[data_count];

  SELECT jsonb_build_object(
    'd', jsonb_agg((extract(epoch from x.snapshot_date)/86400)::int ORDER BY x.ord),
    'e', jsonb_agg(round(x.total_equity) ORDER BY x.ord),
    'c', jsonb_agg(round(x.total_cashflow) ORDER BY x.ord)
  )
  INTO final_result
  FROM unnest(result_data) WITH ORDINALITY
      AS x(snapshot_date, total_equity, total_cashflow, ord);

  RETURN final_result;
END;
$function$;

CREATE FUNCTION dws.get_return_chart (
  p_start_date date,
  p_end_date   date,
  p_threshold  integer DEFAULT 150
)
  RETURNS jsonb
  LANGUAGE plpgsql
  SET search_path TO 'dim', 'dwd', 'dws'
  AS $function$
DECLARE
  v_first_vni_value numeric;
  raw_data dim.benchmark_point[];
  result_data dim.benchmark_point[];
  data_count int;
  every numeric;
  i int;
  a int := 0;
  range_start int;
  range_end int;
  avg_x numeric;
  avg_y numeric;
  max_area numeric;
  point_area numeric;
  selected RECORD;
  prev RECORD;
  final_result jsonb;
BEGIN
  -- VNI normalization anchor (first close in range)
  SELECT dac.close
  INTO v_first_vni_value
  FROM dwd.daily_asset_close dac
    JOIN dim.asset a ON a.id = dac.asset_id
  WHERE a.ticker = 'VNINDEX'
    AND dac.date >= p_start_date
  ORDER BY dac.date
  LIMIT 1;

  -- Load dataset into memory array.
  -- Portfolio value is chain-linked from daily returns and rebased to 100.
  SELECT array_agg(t ORDER BY snapshot_date)
  INTO raw_data
  FROM (
    SELECT
      pd.snapshot_date,
      100 * EXP(
        SUM(LN(1 + GREATEST(pd.intraday_return, -0.999999)))
          OVER (ORDER BY pd.snapshot_date
                ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)
      ) AS portfolio_value,
      (dac.close / NULLIF(v_first_vni_value, 0)) * 100 AS vni_value
    FROM dws.daily_snapshots pd
      JOIN dwd.daily_asset_close dac ON pd.snapshot_date = dac.date
      JOIN dim.asset a ON a.id = dac.asset_id
    WHERE pd.user_id = auth.uid()
      AND pd.snapshot_date BETWEEN p_start_date AND p_end_date
      AND a.ticker = 'VNINDEX'
      AND pd.intraday_return IS NOT NULL
  ) t;

  data_count := array_length(raw_data, 1);

  IF data_count IS NULL OR data_count = 0 THEN
    RETURN '[]'::jsonb;
  END IF;

  IF data_count <= p_threshold THEN
    RETURN (
      SELECT jsonb_build_object(
        'd', jsonb_agg((extract(epoch from x.snapshot_date)/86400)::int ORDER BY x.ord),
        'p', jsonb_agg(round(x.portfolio_value, 2)                      ORDER BY x.ord),
        'v', jsonb_agg(round(x.vni_value, 2)                            ORDER BY x.ord)
      )
      FROM unnest(raw_data) WITH ORDINALITY
          AS x(snapshot_date, portfolio_value, vni_value, ord)
    );
  END IF;

  -- LTTB sampling (unchanged)
  result_data := ARRAY[ raw_data[1] ];
  every := (data_count - 2.0) / (p_threshold - 2.0);

  FOR i IN 0..p_threshold - 3 LOOP
    range_start := floor(a * every)::int + 2;
    range_end := floor((a + 1) * every)::int + 1;

    IF range_end > data_count THEN
      range_end := data_count;
    END IF;

    SELECT
      AVG(EXTRACT(EPOCH FROM r.snapshot_date)),
      AVG(r.portfolio_value)
    INTO avg_x, avg_y
    FROM unnest(raw_data[range_start:range_end]) r;

    max_area := -1;
    prev := result_data[array_length(result_data,1)];

    FOR selected IN
      SELECT * FROM unnest(raw_data[range_start:range_end])
    LOOP
      point_area := abs(
        (EXTRACT(EPOCH FROM prev.snapshot_date) - avg_x)
        * (selected.portfolio_value - prev.portfolio_value)
        -
        (EXTRACT(EPOCH FROM prev.snapshot_date)
         - EXTRACT(EPOCH FROM selected.snapshot_date))
        * (avg_y - prev.portfolio_value)
      ) * 0.5;

      IF point_area > max_area THEN
        max_area := point_area;
        raw_data[range_start] := selected;
      END IF;
    END LOOP;

    result_data := result_data || raw_data[range_start];
    a := a + 1;
  END LOOP;

  result_data := result_data || raw_data[data_count];

  SELECT jsonb_build_object(
    'd', jsonb_agg((extract(epoch from x.snapshot_date)/86400)::int ORDER BY x.ord),
    'p', jsonb_agg(round(x.portfolio_value, 2)                      ORDER BY x.ord),
    'v', jsonb_agg(round(x.vni_value, 2)                            ORDER BY x.ord)
  )
  INTO final_result
  FROM unnest(result_data) WITH ORDINALITY
      AS x(snapshot_date, portfolio_value, vni_value, ord);

  RETURN final_result;
END;$function$;

CREATE FUNCTION dws.recompute_daily_snapshots (
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
    w_running as (partition by b.user_id order by b.snapshot_date rows between unbounded preceding and current row);
end;
$function$;

CREATE FUNCTION dws.trg_snapshots_fxrate()
  RETURNS TRIGGER
  LANGUAGE plpgsql
  SECURITY DEFINER
  SET search_path TO 'dim', 'dwd', 'dws'
  AS $function$
declare r record;
begin
  if tg_op = 'INSERT' then
    for r in
      select e.user_id, min(c.date) as d
      from (select currency_id, date from new_rows) c
      join dim.asset a on a.currency_id = c.currency_id
      join dwd.tx_legs tl on tl.asset_id = a.id
      join dwd.tx_entries e on e.id = tl.tx_id
      group by e.user_id
    loop
      perform dws.recompute_daily_snapshots(r.user_id, r.d);
    end loop;
  else  -- UPDATE
    for r in
      with changed as (
        select currency_id, date from new_rows
        union
        select currency_id, date from old_rows
      )
      select e.user_id, min(c.date) as d
      from changed c
      join dim.asset a on a.currency_id = c.currency_id
      join dwd.tx_legs tl on tl.asset_id = a.id
      join dwd.tx_entries e on e.id = tl.tx_id
      group by e.user_id
    loop
      perform dws.recompute_daily_snapshots(r.user_id, r.d);
    end loop;
  end if;
  return null;
end;
$function$;

CREATE OR REPLACE TRIGGER after_new_fxrate_ins
  AFTER INSERT ON dwd.daily_fxrate_close
  FOR EACH STATEMENT
  EXECUTE FUNCTION dws.trg_snapshots_fxrate();

CREATE OR REPLACE TRIGGER after_new_fxrate_upd
  AFTER UPDATE ON dwd.daily_fxrate_close
  FOR EACH STATEMENT
  EXECUTE FUNCTION dws.trg_snapshots_fxrate();

CREATE FUNCTION dws.trg_snapshots_prices()
  RETURNS TRIGGER
  LANGUAGE plpgsql
  SECURITY DEFINER
  SET search_path TO 'dim', 'dwd', 'dws'
  AS $function$
declare r record;
begin
  if tg_op = 'INSERT' then
    for r in
      select e.user_id, min(c.date) as d
      from (select asset_id, date from new_rows) c
      join dwd.tx_legs tl on tl.asset_id = c.asset_id
      join dwd.tx_entries e on e.id = tl.tx_id
      group by e.user_id
    loop
      perform dws.recompute_daily_snapshots(r.user_id, r.d);
    end loop;
  else  -- UPDATE: consider both the new and the old date/asset
    for r in
      with changed as (
        select asset_id, date from new_rows
        union
        select asset_id, date from old_rows
      )
      select e.user_id, min(c.date) as d
      from changed c
      join dwd.tx_legs tl on tl.asset_id = c.asset_id
      join dwd.tx_entries e on e.id = tl.tx_id
      group by e.user_id
    loop
      perform dws.recompute_daily_snapshots(r.user_id, r.d);
    end loop;
  end if;
  return null;
end;
$function$;

CREATE OR REPLACE TRIGGER after_new_prices_ins
  AFTER INSERT ON dwd.daily_asset_close
  FOR EACH STATEMENT
  EXECUTE FUNCTION dws.trg_snapshots_prices();

CREATE OR REPLACE TRIGGER after_new_prices_upd
  AFTER UPDATE ON dwd.daily_asset_close
  FOR EACH STATEMENT
  EXECUTE FUNCTION dws.trg_snapshots_prices();

CREATE FUNCTION dws.trg_snapshots_tx_legs()
  RETURNS TRIGGER
  LANGUAGE plpgsql
  SECURITY DEFINER
  SET search_path TO 'dwd', 'dws'
  AS $function$
declare r record;
begin
  for r in
    select e.user_id, min((e.created_at)::date) as d
    from new_rows nl
    join dwd.tx_entries e on e.id = nl.tx_id
    group by e.user_id
  loop
    perform dws.recompute_daily_snapshots(r.user_id, r.d);
  end loop;
  return null;
end;
$function$;

CREATE OR REPLACE TRIGGER after_new_tx_legs
  AFTER INSERT ON dwd.tx_legs REFERENCING NEW TABLE AS new_rows
  FOR EACH STATEMENT
  EXECUTE FUNCTION dws.trg_snapshots_tx_legs();

CREATE OR REPLACE FUNCTION public.upsert_historical_prices()
  RETURNS TRIGGER
  LANGUAGE plpgsql
  SET search_path TO 'dim', 'dwd'
  AS $function$
BEGIN
  INSERT INTO dwd.daily_asset_close (asset_id, date, close)
  SELECT
    a.id,
    -- Use last_updated if available, fall back to bar_time
    (NEW.last_updated AT TIME ZONE 'UTC')::date,
    NEW.close
  FROM dim.asset a
  WHERE a.ticker = NEW.symbol
  ON CONFLICT (asset_id, date)
  DO UPDATE SET
    close = EXCLUDED.close;

  RETURN NULL;
END;
$function$;