


SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;


CREATE EXTENSION IF NOT EXISTS "pg_cron" WITH SCHEMA "pg_catalog";






CREATE SCHEMA IF NOT EXISTS "dim";


ALTER SCHEMA "dim" OWNER TO "postgres";


CREATE SCHEMA IF NOT EXISTS "dwd";


ALTER SCHEMA "dwd" OWNER TO "postgres";


CREATE SCHEMA IF NOT EXISTS "dws";


ALTER SCHEMA "dws" OWNER TO "postgres";


CREATE EXTENSION IF NOT EXISTS "pg_net" WITH SCHEMA "extensions";






CREATE SCHEMA IF NOT EXISTS "ods";


ALTER SCHEMA "ods" OWNER TO "postgres";


COMMENT ON SCHEMA "public" IS 'standard public schema';



CREATE EXTENSION IF NOT EXISTS "hypopg" WITH SCHEMA "extensions";






CREATE EXTENSION IF NOT EXISTS "index_advisor" WITH SCHEMA "extensions";






CREATE EXTENSION IF NOT EXISTS "pg_stat_statements" WITH SCHEMA "extensions";






CREATE EXTENSION IF NOT EXISTS "pgcrypto" WITH SCHEMA "extensions";






CREATE EXTENSION IF NOT EXISTS "supabase_vault" WITH SCHEMA "vault";






CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA "extensions";






CREATE TYPE "dim"."asset_class" AS ENUM (
    'cash',
    'stock',
    'fund',
    'equity',
    'liability',
    'index'
);


ALTER TYPE "dim"."asset_class" OWNER TO "postgres";


CREATE TYPE "dim"."benchmark_point" AS (
	"snapshot_date" "date",
	"portfolio_value" numeric,
	"vni_value" numeric
);


ALTER TYPE "dim"."benchmark_point" OWNER TO "postgres";


CREATE TYPE "dim"."cashflow_ops" AS ENUM (
    'deposit',
    'withdraw',
    'income',
    'expense'
);


ALTER TYPE "dim"."cashflow_ops" OWNER TO "postgres";


COMMENT ON TYPE "dim"."cashflow_ops" IS 'Operation types of cashflow transactions';



CREATE TYPE "dim"."dnse_order_status" AS ENUM (
    'Pending',
    'PendingNew',
    'New',
    'PartiallyFilled',
    'Filled',
    'PendingReplace',
    'PendingCancel',
    'Canceled',
    'Rejected',
    'Expired',
    'DoneForDay'
);


ALTER TYPE "dim"."dnse_order_status" OWNER TO "postgres";


COMMENT ON TYPE "dim"."dnse_order_status" IS 'Status of trading order from DNSE API';



CREATE TYPE "dim"."equity_point" AS (
	"snapshot_date" "date",
	"total_cashflow" numeric,
	"total_equity" numeric
);


ALTER TYPE "dim"."equity_point" OWNER TO "postgres";


CREATE TYPE "dim"."seat_position" AS ENUM (
    'window',
    'middle',
    'aisle'
);


ALTER TYPE "dim"."seat_position" OWNER TO "postgres";


CREATE TYPE "dim"."stock_ops" AS ENUM (
    'buy',
    'sell'
);


ALTER TYPE "dim"."stock_ops" OWNER TO "postgres";


COMMENT ON TYPE "dim"."stock_ops" IS 'Operation types for stock transactions';



CREATE TYPE "dim"."ticket_class" AS ENUM (
    'eco',
    'biz'
);


ALTER TYPE "dim"."ticket_class" OWNER TO "postgres";


CREATE TYPE "dim"."tx_category" AS ENUM (
    'stock',
    'cashflow',
    'borrow',
    'repay'
);


ALTER TYPE "dim"."tx_category" OWNER TO "postgres";


COMMENT ON TYPE "dim"."tx_category" IS 'Categories of transaction events';



CREATE TYPE "public"."benchmark_point" AS (
	"snapshot_date" "date",
	"portfolio_value" numeric,
	"vni_value" numeric
);


ALTER TYPE "public"."benchmark_point" OWNER TO "postgres";


CREATE TYPE "public"."equity_point" AS (
	"snapshot_date" "date",
	"total_cashflow" numeric,
	"total_equity" numeric
);


ALTER TYPE "public"."equity_point" OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "dim"."haversine_distance_km"("lat1" double precision, "lng1" double precision, "lat2" double precision, "lng2" double precision) RETURNS double precision
    LANGUAGE "sql" IMMUTABLE PARALLEL SAFE
    SET "search_path" TO 'dim'
    AS $$
  select
    6371.0 * 2.0 * asin(
      sqrt(
        power(
          sin(radians(lat2 - lat1) / 2.0),
          2.0
        )
        +
        cos(radians(lat1))
        * cos(radians(lat2))
        * power(
          sin(radians(lng2 - lng1) / 2.0),
          2.0
        )
      )
    )
$$;


ALTER FUNCTION "dim"."haversine_distance_km"("lat1" double precision, "lng1" double precision, "lat2" double precision, "lng2" double precision) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "dwd"."add_borrow_event"("p_principal" numeric, "p_lender" "text", "p_rate" numeric, "p_created_at" timestamp with time zone DEFAULT "now"()) RETURNS "void"
    LANGUAGE "plpgsql"
    SET "search_path" TO 'dim', 'dwd'
    AS $$
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

  PERFORM dwd.process_tx_borrow(v_tx_id);
end;
$$;


ALTER FUNCTION "dwd"."add_borrow_event"("p_principal" numeric, "p_lender" "text", "p_rate" numeric, "p_created_at" timestamp with time zone) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "dwd"."add_cashflow_event"("p_operation" "text", "p_asset_id" smallint, "p_quantity" numeric, "p_fx_rate" numeric, "p_memo" "text", "p_created_at" timestamp with time zone DEFAULT "now"(), "p_user_id" "uuid" DEFAULT "auth"."uid"()) RETURNS "void"
    LANGUAGE "plpgsql"
    SET "search_path" TO 'dim', 'dwd'
    AS $$
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

  PERFORM dwd.process_tx_cashflow(v_tx_id);
end;
$$;


ALTER FUNCTION "dwd"."add_cashflow_event"("p_operation" "text", "p_asset_id" smallint, "p_quantity" numeric, "p_fx_rate" numeric, "p_memo" "text", "p_created_at" timestamp with time zone, "p_user_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "dwd"."add_repay_event"("p_repay_tx" integer, "p_interest" numeric, "p_created_at" timestamp with time zone DEFAULT "now"()) RETURNS "void"
    LANGUAGE "plpgsql"
    SET "search_path" TO 'dim', 'dwd'
    AS $$
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

  PERFORM dwd.process_tx_repay(v_tx_id);
end;
$$;


ALTER FUNCTION "dwd"."add_repay_event"("p_repay_tx" integer, "p_interest" numeric, "p_created_at" timestamp with time zone) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "dwd"."add_stock_event"("p_side" "text", "p_stock_id" smallint, "p_price" numeric, "p_quantity" numeric, "p_fee" numeric, "p_tax" numeric DEFAULT 0, "p_user_id" "uuid" DEFAULT "auth"."uid"(), "p_created_at" timestamp with time zone DEFAULT "now"()) RETURNS "void"
    LANGUAGE "plpgsql"
    SET "search_path" TO 'dim', 'dwd'
    AS $$
DECLARE
  v_tx_id integer;
  v_ticker text;
BEGIN
  select a.ticker into v_ticker
  from dim.asset a
  where a.id = p_stock_id;

  INSERT INTO dwd.tx_entries (
    category,
    memo,
    user_id,
    created_at
  )
  VALUES (
    'stock',
    initcap(p_side) || ' ' || p_quantity::text || ' ' || v_ticker || ' at ' || p_price::text,
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
    p_stock_id,
    p_price,
    p_quantity,
    p_fee,
    COALESCE(p_tax, 0)
  );

  PERFORM dwd.process_tx_stock(v_tx_id);
END;
$$;


ALTER FUNCTION "dwd"."add_stock_event"("p_side" "text", "p_stock_id" smallint, "p_price" numeric, "p_quantity" numeric, "p_fee" numeric, "p_tax" numeric, "p_user_id" "uuid", "p_created_at" timestamp with time zone) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "dwd"."process_dnse_order"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    SET "search_path" TO 'ods', 'dim', 'dwd'
    AS $$
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
$$;


ALTER FUNCTION "dwd"."process_dnse_order"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "dwd"."process_tx_borrow"("p_tx_id" integer) RETURNS "void"
    LANGUAGE "plpgsql"
    SET "search_path" TO 'dim', 'dwd'
    AS $$
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
$$;


ALTER FUNCTION "dwd"."process_tx_borrow"("p_tx_id" integer) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "dwd"."process_tx_cashflow"("p_tx_id" integer) RETURNS "void"
    LANGUAGE "plpgsql"
    SET "search_path" TO 'dim', 'dwd'
    AS $$
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
$$;


ALTER FUNCTION "dwd"."process_tx_cashflow"("p_tx_id" integer) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "dwd"."process_tx_repay"("p_tx_id" integer) RETURNS "void"
    LANGUAGE "plpgsql"
    SET "search_path" TO 'dim', 'dwd'
    AS $$
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
$$;


ALTER FUNCTION "dwd"."process_tx_repay"("p_tx_id" integer) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "dwd"."process_tx_stock"("p_tx_id" integer) RETURNS "void"
    LANGUAGE "plpgsql"
    SET "search_path" TO 'dim', 'dwd'
    AS $$declare
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
$$;


ALTER FUNCTION "dwd"."process_tx_stock"("p_tx_id" integer) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "dwd"."rebuild_ledger"() RETURNS "void"
    LANGUAGE "plpgsql"
    SET "search_path" TO 'dim', 'dwd'
    AS $$
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
$$;


ALTER FUNCTION "dwd"."rebuild_ledger"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "dwd"."upsert_daily_asset_close"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    SET "search_path" TO 'dim', 'dwd'
    AS $$
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
$$;


ALTER FUNCTION "dwd"."upsert_daily_asset_close"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "dws"."active_stock_tickers"() RETURNS "jsonb"
    LANGUAGE "sql" STABLE
    SET "search_path" TO 'dim', 'dwd'
    AS $$
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
$$;


ALTER FUNCTION "dws"."active_stock_tickers"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "dws"."calculate_pnl"("p_start_date" "date", "p_end_date" "date") RETURNS numeric
    LANGUAGE "plpgsql"
    SET "search_path" TO 'dws'
    AS $$
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
$$;


ALTER FUNCTION "dws"."calculate_pnl"("p_start_date" "date", "p_end_date" "date") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "dws"."calculate_twr"("p_start_date" "date", "p_end_date" "date") RETURNS numeric
    LANGUAGE "plpgsql"
    SET "search_path" TO 'dws'
    AS $$
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
$$;


ALTER FUNCTION "dws"."calculate_twr"("p_start_date" "date", "p_end_date" "date") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "dws"."calculate_vnindex_return"("p_start_date" "date", "p_end_date" "date") RETURNS numeric
    LANGUAGE "sql" STABLE
    SET "search_path" TO 'dim', 'dwd'
    AS $$
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
$$;


ALTER FUNCTION "dws"."calculate_vnindex_return"("p_start_date" "date", "p_end_date" "date") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "dws"."get_cashflow_summary"("p_start_date" "date", "p_end_date" "date") RETURNS TABLE("deposits" numeric, "withdrawals" numeric)
    LANGUAGE "sql" STABLE
    SET "search_path" TO 'dws'
    AS $$
  SELECT
    COALESCE(SUM(GREATEST(intraday_cashflow, 0::numeric)), 0) AS deposits,
    COALESCE(SUM(LEAST(intraday_cashflow, 0::numeric)), 0) AS withdrawals
  FROM dws.daily_snapshots
  WHERE user_id = auth.uid()
    AND snapshot_date BETWEEN p_start_date AND p_end_date;
$$;


ALTER FUNCTION "dws"."get_cashflow_summary"("p_start_date" "date", "p_end_date" "date") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "dws"."get_equity_chart"("p_start_date" "date", "p_end_date" "date", "p_threshold" integer DEFAULT 150) RETURNS "jsonb"
    LANGUAGE "plpgsql"
    SET "search_path" TO 'dim', 'dwd', 'dws'
    AS $$
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
$$;


ALTER FUNCTION "dws"."get_equity_chart"("p_start_date" "date", "p_end_date" "date", "p_threshold" integer) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "dws"."get_event_borrow"() RETURNS TABLE("tx_id" integer, "created_at" timestamp with time zone, "lender" "text", "principal" numeric, "rate" numeric)
    LANGUAGE "sql" STABLE
    SET "search_path" TO 'dwd'
    AS $$
  select
    b.tx_id,
    e.created_at,
    b.lender,
    b.principal,
    b.rate
  from dwd.tx_entries e
    join dwd.tx_borrow b on e.id = b.tx_id
  order by e.created_at desc;
$$;


ALTER FUNCTION "dws"."get_event_borrow"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "dws"."get_event_cashflow"("p_start_date" "date" DEFAULT NULL::"date", "p_end_date" "date" DEFAULT NULL::"date", "p_operation" "text" DEFAULT NULL::"text") RETURNS TABLE("tx_id" integer, "created_at" timestamp with time zone, "operation" "text", "memo" "text", "ticker" "text", "currency" "text", "quantity" numeric, "net_proceed" numeric)
    LANGUAGE "sql" STABLE
    SET "search_path" TO 'dim', 'dwd'
    AS $$
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
$$;


ALTER FUNCTION "dws"."get_event_cashflow"("p_start_date" "date", "p_end_date" "date", "p_operation" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "dws"."get_event_repay"() RETURNS TABLE("tx_id" integer, "created_at" timestamp with time zone, "borrow_tx" integer, "lender" "text", "principal" numeric, "interest" numeric)
    LANGUAGE "sql" STABLE
    SET "search_path" TO 'dwd'
    AS $$
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
$$;


ALTER FUNCTION "dws"."get_event_repay"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "dws"."get_event_stock"("p_ticker" "text" DEFAULT NULL::"text", "p_operation" "text" DEFAULT NULL::"text", "p_start_date" "date" DEFAULT NULL::"date", "p_end_date" "date" DEFAULT NULL::"date") RETURNS TABLE("tx_id" integer, "created_at" timestamp with time zone, "operation" "text", "ticker" "text", "price" numeric, "quantity" numeric, "fee" numeric, "tax" numeric, "net_proceed" numeric, "logo_url" "text", "name" "text")
    LANGUAGE "sql" STABLE
    SET "search_path" TO 'dim', 'dwd'
    AS $$
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
$$;


ALTER FUNCTION "dws"."get_event_stock"("p_ticker" "text", "p_operation" "text", "p_start_date" "date", "p_end_date" "date") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "dws"."get_flights_by_month"() RETURNS TABLE("month_number" integer, "month" "text", "flights" integer)
    LANGUAGE "sql" STABLE
    SET "search_path" TO 'dwd'
    AS $$
  SELECT
    EXTRACT(MONTH FROM departure_time)::int AS month_number,
    TO_CHAR(departure_time, 'Mon') AS month,
    COUNT(*)::int AS flights
  FROM dwd.flights
  GROUP BY 1, 2
  ORDER BY 1;
$$;


ALTER FUNCTION "dws"."get_flights_by_month"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "dws"."get_flights_by_weekday"() RETURNS TABLE("weekday_number" integer, "weekday" "text", "flights" integer)
    LANGUAGE "sql" STABLE
    SET "search_path" TO 'dwd'
    AS $$
SELECT
  EXTRACT(ISODOW FROM departure_time)::int AS weekday_number,
  TO_CHAR(departure_time, 'Dy') AS weekday,
  COUNT(*)::int AS flights
FROM dwd.flights
GROUP BY 1, 2
ORDER BY 1;
$$;


ALTER FUNCTION "dws"."get_flights_by_weekday"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "dws"."get_flights_by_year"() RETURNS TABLE("year" integer, "flights" integer)
    LANGUAGE "sql" STABLE
    SET "search_path" TO 'dwd'
    AS $$
  SELECT
    EXTRACT(YEAR FROM years.year)::int AS year,
    COUNT(f.id)::int AS flights
  FROM generate_series(
    DATE_TRUNC(
      'year',
      (SELECT MIN(departure_time)
      FROM dwd.flights)
    ),
    DATE_TRUNC('year', CURRENT_DATE),
    '1 year'
  ) AS years(year)
  LEFT JOIN dwd.flights f
    ON f.departure_time >= years.year
    AND f.departure_time < years.year + INTERVAL '1 year'
    AND f.user_id = auth.uid()
  GROUP BY years.year
  ORDER BY years.year;
$$;


ALTER FUNCTION "dws"."get_flights_by_year"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "dws"."get_monthly_pnl_chart"("p_start_date" "date", "p_end_date" "date") RETURNS "jsonb"
    LANGUAGE "sql" STABLE
    SET "search_path" TO 'dws'
    AS $$
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
$$;


ALTER FUNCTION "dws"."get_monthly_pnl_chart"("p_start_date" "date", "p_end_date" "date") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "dws"."get_return_chart"("p_start_date" "date", "p_end_date" "date", "p_threshold" integer DEFAULT 150) RETURNS "jsonb"
    LANGUAGE "plpgsql"
    SET "search_path" TO 'dim', 'dwd', 'dws'
    AS $$
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
END;$$;


ALTER FUNCTION "dws"."get_return_chart"("p_start_date" "date", "p_end_date" "date", "p_threshold" integer) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "dws"."get_top_aircrafts"() RETURNS TABLE("aircraft_model" "text", "count" integer)
    LANGUAGE "sql" STABLE
    SET "search_path" TO 'dim', 'dwd'
    AS $$
  select
    a.model as aircraft_model,
    count(f.id)
  from dwd.flights f
    join dim.aircraft a on f.aircraft_type = a.icao_code
  group by a.model
  order by count(f.id) desc
  limit 5;
$$;


ALTER FUNCTION "dws"."get_top_aircrafts"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "dws"."get_top_airlines"() RETURNS TABLE("airlines_logo" "text", "airlines_name" "text", "count" integer)
    LANGUAGE "sql" STABLE
    SET "search_path" TO 'dim', 'dwd'
    AS $$
  select
    a.logo as airlines_logo,
    a.name as airlines_name,
    count(f.id)
  from dwd.flights f
    join dim.airline a on f.airline_code = a.icao_code
  group by a.logo, a.name
  order by count(f.id) desc
  limit 5;
$$;


ALTER FUNCTION "dws"."get_top_airlines"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "dws"."get_top_airports"() RETURNS TABLE("airport_code" "text", "airport_name" "text", "count" integer)
    LANGUAGE "sql" STABLE
    SET "search_path" TO 'dim', 'dwd'
    AS $$
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
$$;


ALTER FUNCTION "dws"."get_top_airports"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "dws"."get_top_routes"() RETURNS TABLE("airport_a_code" "text", "airport_b_code" "text", "frequency" integer)
    LANGUAGE "sql" STABLE
    SET "search_path" TO 'dim', 'dwd'
    AS $$
  select
    LEAST(f.dept_airport_iata, f.arr_airport_iata) as airport_a_code,
    GREATEST(f.dept_airport_iata, f.arr_airport_iata) as airport_b_code,
    count(*) as frequency
  from dwd.flights f
  group by airport_a_code, airport_b_code
  order by frequency desc
  limit 5;
$$;


ALTER FUNCTION "dws"."get_top_routes"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "dws"."get_top_stocks"("p_start_date" "date", "p_end_date" "date") RETURNS TABLE("ticker" "text", "name" "text", "logo_url" "text", "total_pnl" numeric)
    LANGUAGE "sql" STABLE
    SET "search_path" TO 'dim', 'dwd', 'dws'
    AS $$

  WITH capital_legs AS (
    SELECT
      tl.tx_id,
      tl.credit - tl.debit AS realized_pnl
    FROM dwd.tx_legs tl
    JOIN dwd.tx_entries t
      ON t.id = tl.tx_id
    JOIN dim.asset a
      ON a.id = tl.asset_id
    WHERE a.ticker = 'CAPITAL'
      AND t.user_id = auth.uid()
      AND t.created_at >= p_start_date
      AND t.created_at < p_end_date + 1
  ),

  stock_legs AS (
    SELECT
      tl.tx_id,
      tl.asset_id AS stock_id
    FROM dwd.tx_legs tl
    JOIN dwd.tx_entries e
      ON e.id = tl.tx_id
    JOIN dim.asset a
      ON a.id = tl.asset_id
    WHERE a.asset_class = 'stock'
      AND e.user_id = auth.uid()
  )

  SELECT
    a.ticker,
    a.name,
    a.logo_url,
    SUM(c.realized_pnl) AS total_pnl
  FROM capital_legs c
  JOIN stock_legs s
    ON s.tx_id = c.tx_id
  JOIN dim.asset a
    ON a.id = s.stock_id
  GROUP BY
    a.id,
    a.ticker,
    a.name,
    a.logo_url
  ORDER BY
    total_pnl DESC;

$$;


ALTER FUNCTION "dws"."get_top_stocks"("p_start_date" "date", "p_end_date" "date") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "dws"."recompute_daily_snapshots"("p_user_id" "uuid" DEFAULT NULL::"uuid", "p_from_date" "date" DEFAULT NULL::"date") RETURNS "void"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'dim', 'dwd', 'dws'
    AS $$
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
$$;


ALTER FUNCTION "dws"."recompute_daily_snapshots"("p_user_id" "uuid", "p_from_date" "date") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "dws"."trg_snapshots_fxrate"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'dim', 'dwd', 'dws'
    AS $$
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
$$;


ALTER FUNCTION "dws"."trg_snapshots_fxrate"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "dws"."trg_snapshots_prices"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'dim', 'dwd', 'dws'
    AS $$
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
$$;


ALTER FUNCTION "dws"."trg_snapshots_prices"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "dws"."trg_snapshots_tx_legs"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'dwd', 'dws'
    AS $$
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
$$;


ALTER FUNCTION "dws"."trg_snapshots_tx_legs"() OWNER TO "postgres";

SET default_tablespace = '';

SET default_table_access_method = "heap";


CREATE TABLE IF NOT EXISTS "dim"."aircraft" (
    "icao_code" "text" NOT NULL,
    "model" "text" NOT NULL
);


ALTER TABLE "dim"."aircraft" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "dim"."airline" (
    "name" "text" NOT NULL,
    "logo" "text" NOT NULL,
    "icao_code" "text" NOT NULL
);


ALTER TABLE "dim"."airline" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "dim"."airport" (
    "icao_code" "text" NOT NULL,
    "iata_code" "text" NOT NULL,
    "name" "text" NOT NULL,
    "city" "text" NOT NULL,
    "country" "text" NOT NULL,
    "lat" double precision NOT NULL,
    "lng" double precision NOT NULL,
    "timezone" "text" NOT NULL,
    CONSTRAINT "timezone_format_check" CHECK (("timezone" ~ '^[A-Za-z_]+/[A-Za-z_]+$'::"text"))
);


ALTER TABLE "dim"."airport" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "dim"."asset" (
    "id" smallint NOT NULL,
    "asset_class" "dim"."asset_class" NOT NULL,
    "ticker" "text" NOT NULL,
    "name" "text" NOT NULL,
    "currency_id" smallint NOT NULL,
    "logo_url" "text"
);


ALTER TABLE "dim"."asset" OWNER TO "postgres";


ALTER TABLE "dim"."asset" ALTER COLUMN "id" ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME "dim"."asset_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);



CREATE TABLE IF NOT EXISTS "dim"."currency" (
    "id" smallint NOT NULL,
    "iso_code" "text" NOT NULL
);


ALTER TABLE "dim"."currency" OWNER TO "postgres";


ALTER TABLE "dim"."currency" ALTER COLUMN "id" ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME "dim"."currency_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);



CREATE TABLE IF NOT EXISTS "dim"."user_settings" (
    "user_id" "uuid" NOT NULL,
    "dnse_account_id" "text",
    "inception_date" "date" DEFAULT '2020-01-01'::"date" NOT NULL,
    "display_name" "text",
    "avatar" "text"
);


ALTER TABLE "dim"."user_settings" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "dwd"."daily_asset_close" (
    "asset_id" smallint NOT NULL,
    "date" "date" NOT NULL,
    "close" numeric(14,2) NOT NULL
);


ALTER TABLE "dwd"."daily_asset_close" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "dwd"."daily_fxrate_close" (
    "currency_id" smallint NOT NULL,
    "date" "date" NOT NULL,
    "close" numeric(14,2) NOT NULL
);


ALTER TABLE "dwd"."daily_fxrate_close" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "dwd"."flights" (
    "id" integer NOT NULL,
    "flight_number" "text" NOT NULL,
    "departure_time" timestamp with time zone NOT NULL,
    "arrival_time" timestamp with time zone NOT NULL,
    "seat_number" "text",
    "ticket_class" "dim"."ticket_class" NOT NULL,
    "seat_position" "dim"."seat_position",
    "tail_number" "text",
    "user_id" "uuid" NOT NULL,
    "airline_code" "text" NOT NULL,
    "dept_airport_iata" "text" NOT NULL,
    "arr_airport_iata" "text" NOT NULL,
    "aircraft_type" "text"
);


ALTER TABLE "dwd"."flights" OWNER TO "postgres";


ALTER TABLE "dwd"."flights" ALTER COLUMN "id" ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME "dwd"."flights_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);



CREATE TABLE IF NOT EXISTS "dwd"."tx_borrow" (
    "tx_id" integer NOT NULL,
    "lender" "text" NOT NULL,
    "principal" numeric(16,0) NOT NULL,
    "rate" numeric(6,2) NOT NULL
);


ALTER TABLE "dwd"."tx_borrow" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "dwd"."tx_cashflow" (
    "tx_id" integer NOT NULL,
    "asset_id" smallint NOT NULL,
    "operation" "dim"."cashflow_ops" NOT NULL,
    "quantity" numeric(18,2) NOT NULL,
    "fx_rate" numeric(10,2) DEFAULT 1 NOT NULL,
    "net_proceed" numeric(16,0) GENERATED ALWAYS AS (("quantity" * "fx_rate")) STORED NOT NULL
);


ALTER TABLE "dwd"."tx_cashflow" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "dwd"."tx_entries" (
    "id" integer NOT NULL,
    "user_id" "uuid" NOT NULL,
    "category" "dim"."tx_category" NOT NULL,
    "memo" "text" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "dwd"."tx_entries" OWNER TO "postgres";


ALTER TABLE "dwd"."tx_entries" ALTER COLUMN "id" ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME "dwd"."tx_entries_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);



CREATE TABLE IF NOT EXISTS "dwd"."tx_legs" (
    "tx_id" integer NOT NULL,
    "asset_id" smallint NOT NULL,
    "quantity" numeric(18,2) NOT NULL,
    "debit" numeric(16,0) NOT NULL,
    "credit" numeric(16,0) NOT NULL
);


ALTER TABLE "dwd"."tx_legs" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "dwd"."tx_repay" (
    "tx_id" integer NOT NULL,
    "borrow_tx" integer NOT NULL,
    "principal" numeric(16,0) NOT NULL,
    "interest" numeric(16,0) NOT NULL,
    "net_proceed" numeric(16,0) GENERATED ALWAYS AS (("principal" + "interest")) STORED NOT NULL
);


ALTER TABLE "dwd"."tx_repay" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "dwd"."tx_stock" (
    "tx_id" integer NOT NULL,
    "stock_id" smallint NOT NULL,
    "price" numeric(9,0) DEFAULT 0 NOT NULL,
    "quantity" numeric(9,0) NOT NULL,
    "fee" numeric(16,0) NOT NULL,
    "tax" numeric(16,0) DEFAULT 0 NOT NULL,
    "operation" "dim"."stock_ops" NOT NULL,
    "net_proceed" numeric(16,0) GENERATED ALWAYS AS (
CASE
    WHEN ("operation" = 'buy'::"dim"."stock_ops") THEN ((("price" * "quantity") + "fee") + "tax")
    WHEN ("operation" = 'sell'::"dim"."stock_ops") THEN ((("price" * "quantity") - "fee") - "tax")
    ELSE (0)::numeric
END) STORED NOT NULL
);


ALTER TABLE "dwd"."tx_stock" OWNER TO "postgres";


CREATE OR REPLACE VIEW "dws"."outstanding_debts" WITH ("security_invoker"='true') AS
 SELECT "b"."tx_id",
    "b"."lender",
    "b"."principal",
    "b"."rate",
    "round"((("b"."principal" * "power"(((1)::numeric + (("b"."rate" / 100.0) / 365.0)), EXTRACT(day FROM ((CURRENT_DATE)::timestamp with time zone - "e"."created_at")))) - "b"."principal"), 0) AS "accrued_interest",
    "e"."created_at"
   FROM ("dwd"."tx_borrow" "b"
     JOIN "dwd"."tx_entries" "e" ON ((("e"."id" = "b"."tx_id") AND ("e"."user_id" = "auth"."uid"()))))
  WHERE (NOT (EXISTS ( SELECT 1
           FROM "dwd"."tx_repay" "r"
          WHERE ("r"."borrow_tx" = "b"."tx_id"))));


ALTER VIEW "dws"."outstanding_debts" OWNER TO "postgres";


CREATE OR REPLACE VIEW "dws"."balance_sheet" WITH ("security_invoker"='true') AS
 WITH "user_legs" AS (
         SELECT "tl"."tx_id",
            "tl"."asset_id",
            "tl"."quantity",
            "tl"."debit",
            "tl"."credit"
           FROM ("dwd"."tx_legs" "tl"
             JOIN "dwd"."tx_entries" "e" ON (("e"."id" = "tl"."tx_id")))
          WHERE ("e"."user_id" = "auth"."uid"())
        ), "debt_interest" AS (
         SELECT "sum"("outstanding_debts"."accrued_interest") AS "sum"
           FROM "dws"."outstanding_debts"
        )
 SELECT "a"."ticker",
    "a"."name",
    "a"."asset_class",
    "a"."logo_url",
    "c"."iso_code" AS "currency",
    COALESCE("sum"("ul"."quantity"), (0)::numeric) AS "quantity",
    COALESCE(("sum"("ul"."debit") - "sum"("ul"."credit")), (0)::numeric) AS "cost_basis",
        CASE
            WHEN ("a"."asset_class" = ANY (ARRAY['stock'::"dim"."asset_class", 'fund'::"dim"."asset_class"])) THEN "round"("sum"(("ul"."quantity" * COALESCE("sp"."price", "er"."rate"))), 0)
            WHEN ("a"."ticker" = 'INTERESTS'::"text") THEN ( SELECT "sum"("outstanding_debts"."accrued_interest") AS "sum"
               FROM "dws"."outstanding_debts")
            ELSE "sum"("ul"."quantity")
        END AS "total_value",
    COALESCE(COALESCE("sp"."price", "er"."rate"), (0)::numeric) AS "mkt_price",
    COALESCE(
        CASE
            WHEN ("a"."ticker" = 'INTERESTS'::"text") THEN (- ( SELECT "sum"("outstanding_debts"."accrued_interest") AS "sum"
               FROM "dws"."outstanding_debts"))
            ELSE "round"(("sum"(("ul"."quantity" * COALESCE("sp"."price", "er"."rate"))) - ("sum"("ul"."debit") - "sum"("ul"."credit"))), 0)
        END, (0)::numeric) AS "net_profit"
   FROM (((("dim"."asset" "a"
     JOIN "dim"."currency" "c" ON (("a"."currency_id" = "c"."id")))
     LEFT JOIN "user_legs" "ul" ON (("a"."id" = "ul"."asset_id")))
     LEFT JOIN LATERAL ( SELECT ("dac"."close" * (1000)::numeric) AS "price"
           FROM "dwd"."daily_asset_close" "dac"
          WHERE ("dac"."asset_id" = "a"."id")
          ORDER BY "dac"."date" DESC
         LIMIT 1) "sp" ON (true))
     LEFT JOIN LATERAL ( SELECT "dfx"."close" AS "rate"
           FROM "dwd"."daily_fxrate_close" "dfx"
          WHERE ("dfx"."currency_id" = "a"."currency_id")
          ORDER BY "dfx"."date" DESC
         LIMIT 1) "er" ON (true))
  GROUP BY "a"."ticker", "a"."name", "a"."logo_url", "c"."iso_code", "a"."asset_class", "sp"."price", "er"."rate"
 HAVING (("abs"("sum"("ul"."quantity")) > (0)::numeric) OR ("a"."ticker" = 'INTERESTS'::"text"))
  ORDER BY "a"."asset_class";


ALTER VIEW "dws"."balance_sheet" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "dws"."daily_snapshots" (
    "snapshot_date" "date" NOT NULL,
    "user_id" "uuid" NOT NULL,
    "total_equity" numeric,
    "intraday_cashflow" numeric,
    "intraday_fee" numeric,
    "intraday_tax" numeric,
    "intraday_interest" numeric,
    "total_cashflow" numeric,
    "intraday_pnl" numeric,
    "intraday_return" numeric
);


ALTER TABLE "dws"."daily_snapshots" OWNER TO "postgres";


CREATE OR REPLACE VIEW "dws"."flights_summary" WITH ("security_invoker"='on') AS
 SELECT "f"."user_id",
    "f"."id",
    "f"."flight_number",
    "f"."tail_number",
    "f"."departure_time",
    "f"."arrival_time",
    "f"."seat_number",
    "f"."ticket_class",
    "f"."seat_position",
    "dep"."iata_code" AS "departure_code",
    "dep"."name" AS "departure_name",
    "dep"."timezone" AS "departure_tz",
    "arr"."iata_code" AS "arrival_code",
    "arr"."name" AS "arrival_name",
    "arr"."timezone" AS "arrival_tz",
    "al"."name" AS "airline_name",
    "al"."logo" AS "airline_logo",
    "ac"."model" AS "aircraft_type",
    ("dep"."country" = "arr"."country") AS "is_domestic",
    "round"(("dim"."haversine_distance_km"("dep"."lat", "dep"."lng", "arr"."lat", "arr"."lng"))::numeric, 0) AS "distance_km",
    "concat"("floor"((EXTRACT(epoch FROM ("f"."arrival_time" - "f"."departure_time")) / (3600)::numeric)), 'h ', "floor"(((EXTRACT(epoch FROM ("f"."arrival_time" - "f"."departure_time")) % (3600)::numeric) / (60)::numeric)), 'm') AS "duration"
   FROM (((("dwd"."flights" "f"
     LEFT JOIN "dim"."airline" "al" ON (("al"."icao_code" = "f"."airline_code")))
     LEFT JOIN "dim"."aircraft" "ac" ON (("ac"."icao_code" = "f"."aircraft_type")))
     LEFT JOIN "dim"."airport" "dep" ON (("dep"."iata_code" = "f"."dept_airport_iata")))
     LEFT JOIN "dim"."airport" "arr" ON (("arr"."iata_code" = "f"."arr_airport_iata")))
  ORDER BY "f"."departure_time" DESC;


ALTER VIEW "dws"."flights_summary" OWNER TO "postgres";


CREATE OR REPLACE VIEW "dws"."lifetime_stats" WITH ("security_invoker"='on') AS
 SELECT "count"(*) AS "flights",
    "sum"(
        CASE
            WHEN ("dep"."country" = "arr"."country") THEN 1
            ELSE 0
        END) AS "domestic",
    "sum"(
        CASE
            WHEN ("dep"."country" = "arr"."country") THEN 0
            ELSE 1
        END) AS "intl",
    "sum"(
        CASE
            WHEN ("fs"."seat_position" = 'window'::"dim"."seat_position") THEN 1
            ELSE 0
        END) AS "windows",
    "sum"(
        CASE
            WHEN ("fs"."seat_position" = 'middle'::"dim"."seat_position") THEN 1
            ELSE 0
        END) AS "middle",
    "sum"(
        CASE
            WHEN ("fs"."seat_position" = 'aisle'::"dim"."seat_position") THEN 1
            ELSE 0
        END) AS "aisle",
    "round"("sum"(("dim"."haversine_distance_km"("dep"."lat", "dep"."lng", "arr"."lat", "arr"."lng"))::numeric), 0) AS "distance",
    "round"((EXTRACT(epoch FROM "sum"(("fs"."arrival_time" - "fs"."departure_time"))) / (3600)::numeric)) AS "duration"
   FROM (("dwd"."flights" "fs"
     JOIN "dim"."airport" "dep" ON (("fs"."dept_airport_iata" = "dep"."iata_code")))
     JOIN "dim"."airport" "arr" ON (("fs"."arr_airport_iata" = "arr"."iata_code")));


ALTER VIEW "dws"."lifetime_stats" OWNER TO "postgres";


CREATE OR REPLACE VIEW "dws"."unique_routes" WITH ("security_invoker"='on') AS
 WITH "normalized" AS (
         SELECT LEAST("f"."dept_airport_iata", "f"."arr_airport_iata") AS "airport_a_code",
            GREATEST("f"."dept_airport_iata", "f"."arr_airport_iata") AS "airport_b_code",
            "f"."dept_airport_iata",
            "f"."arr_airport_iata",
            "f"."flight_number",
            "al"."name" AS "airline_name"
           FROM ("dwd"."flights" "f"
             LEFT JOIN "dim"."airline" "al" ON (("al"."icao_code" = "f"."airline_code")))
        ), "route_frequency_cte" AS (
         SELECT "normalized"."airport_a_code",
            "normalized"."airport_b_code",
            "count"(*) AS "route_frequency"
           FROM "normalized"
          GROUP BY "normalized"."airport_a_code", "normalized"."airport_b_code"
        )
 SELECT "a"."iata_code" AS "airport_a_code",
    "b"."iata_code" AS "airport_b_code",
    "a"."lat" AS "airport_a_lat",
    "b"."lat" AS "airport_b_lat",
    "a"."lng" AS "airport_a_lng",
    "b"."lng" AS "airport_b_lng",
    "rf"."route_frequency"
   FROM (("route_frequency_cte" "rf"
     JOIN "dim"."airport" "a" ON (("a"."iata_code" = "rf"."airport_a_code")))
     JOIN "dim"."airport" "b" ON (("b"."iata_code" = "rf"."airport_b_code")));


ALTER VIEW "dws"."unique_routes" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "ods"."dnse_m1_close" (
    "symbol" "text" NOT NULL,
    "close" numeric NOT NULL,
    "volume" bigint NOT NULL,
    "last_updated" timestamp with time zone NOT NULL,
    "received_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "ods"."dnse_m1_close" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "ods"."dnse_order_events" (
    "id" integer NOT NULL,
    "side" "text" NOT NULL,
    "account_no" "text" NOT NULL,
    "symbol" "text" NOT NULL,
    "order_type" "text" NOT NULL,
    "price" numeric NOT NULL,
    "quantity" integer NOT NULL,
    "fill_quantity" integer DEFAULT 0 NOT NULL,
    "canceled_quantity" integer DEFAULT 0 NOT NULL,
    "leave_quantity" integer DEFAULT 0 NOT NULL,
    "order_status" "text" NOT NULL,
    "loan_package_id" integer,
    "modified_date" timestamp with time zone NOT NULL,
    "received_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "avg_price" numeric,
    "tax" numeric,
    "fee" numeric
);


ALTER TABLE "ods"."dnse_order_events" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "ods"."news_articles" (
    "id" integer NOT NULL,
    "title" "text" NOT NULL,
    "url" "text" NOT NULL,
    "source" "text" NOT NULL,
    "published_at" timestamp with time zone NOT NULL,
    "excerpt" "text" NOT NULL,
    "related_stocks" "text"[] DEFAULT '{}'::"text"[] NOT NULL
);


ALTER TABLE "ods"."news_articles" OWNER TO "postgres";


ALTER TABLE "ods"."news_articles" ALTER COLUMN "id" ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME "ods"."news_articles_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);



ALTER TABLE ONLY "dim"."aircraft"
    ADD CONSTRAINT "aircrafts_pkey" PRIMARY KEY ("icao_code");



ALTER TABLE ONLY "dim"."airline"
    ADD CONSTRAINT "airlines_name_key" UNIQUE ("name");



ALTER TABLE ONLY "dim"."airline"
    ADD CONSTRAINT "airlines_pkey" PRIMARY KEY ("icao_code");



ALTER TABLE ONLY "dim"."airport"
    ADD CONSTRAINT "airports_iata_code_key" UNIQUE ("iata_code");



ALTER TABLE ONLY "dim"."airport"
    ADD CONSTRAINT "airports_pkey" PRIMARY KEY ("icao_code");



ALTER TABLE ONLY "dim"."asset"
    ADD CONSTRAINT "assets_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "dim"."asset"
    ADD CONSTRAINT "assets_ticker_key" UNIQUE ("ticker");



ALTER TABLE ONLY "dim"."currency"
    ADD CONSTRAINT "currency_iso_code_key" UNIQUE ("iso_code");



ALTER TABLE ONLY "dim"."currency"
    ADD CONSTRAINT "currency_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "dim"."user_settings"
    ADD CONSTRAINT "user_settings_dnse_account_id_key" UNIQUE ("dnse_account_id");



ALTER TABLE ONLY "dim"."user_settings"
    ADD CONSTRAINT "user_settings_pkey" PRIMARY KEY ("user_id");



ALTER TABLE ONLY "dwd"."daily_asset_close"
    ADD CONSTRAINT "asset_close_pkey" PRIMARY KEY ("asset_id", "date") INCLUDE ("close");



ALTER TABLE ONLY "dwd"."daily_fxrate_close"
    ADD CONSTRAINT "exchange_rates_pkey" PRIMARY KEY ("currency_id", "date") INCLUDE ("close");



ALTER TABLE ONLY "dwd"."flights"
    ADD CONSTRAINT "flights_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "dwd"."tx_borrow"
    ADD CONSTRAINT "tx_borrow_pkey" PRIMARY KEY ("tx_id");



ALTER TABLE ONLY "dwd"."tx_cashflow"
    ADD CONSTRAINT "tx_cashflow_pkey" PRIMARY KEY ("tx_id", "asset_id");



ALTER TABLE ONLY "dwd"."tx_entries"
    ADD CONSTRAINT "tx_entries_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "dwd"."tx_legs"
    ADD CONSTRAINT "tx_legs_pkey" PRIMARY KEY ("tx_id", "asset_id");



ALTER TABLE ONLY "dwd"."tx_repay"
    ADD CONSTRAINT "tx_repay_pkey" PRIMARY KEY ("tx_id");



ALTER TABLE ONLY "dwd"."tx_stock"
    ADD CONSTRAINT "tx_stock_pkey" PRIMARY KEY ("tx_id");



ALTER TABLE ONLY "dws"."daily_snapshots"
    ADD CONSTRAINT "daily_snapshots_pkey" PRIMARY KEY ("user_id", "snapshot_date");



ALTER TABLE ONLY "ods"."dnse_m1_close"
    ADD CONSTRAINT "dnse_m1_close_pkey" PRIMARY KEY ("symbol", "last_updated");



ALTER TABLE ONLY "ods"."dnse_order_events"
    ADD CONSTRAINT "dnse_order_events_pkey" PRIMARY KEY ("received_at");



ALTER TABLE ONLY "ods"."news_articles"
    ADD CONSTRAINT "news_articles_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "ods"."news_articles"
    ADD CONSTRAINT "news_articles_url_key" UNIQUE ("url");



CREATE INDEX "idx_news_articles_related_stocks" ON "ods"."news_articles" USING "gin" ("related_stocks");



CREATE OR REPLACE TRIGGER "after_new_fxrate_ins" AFTER INSERT ON "dwd"."daily_fxrate_close" REFERENCING NEW TABLE AS "new_rows" FOR EACH STATEMENT EXECUTE FUNCTION "dws"."trg_snapshots_fxrate"();



CREATE OR REPLACE TRIGGER "after_new_fxrate_upd" AFTER UPDATE ON "dwd"."daily_fxrate_close" REFERENCING OLD TABLE AS "old_rows" NEW TABLE AS "new_rows" FOR EACH STATEMENT EXECUTE FUNCTION "dws"."trg_snapshots_fxrate"();



CREATE OR REPLACE TRIGGER "after_new_prices_ins" AFTER INSERT ON "dwd"."daily_asset_close" REFERENCING NEW TABLE AS "new_rows" FOR EACH STATEMENT EXECUTE FUNCTION "dws"."trg_snapshots_prices"();



CREATE OR REPLACE TRIGGER "after_new_prices_upd" AFTER UPDATE ON "dwd"."daily_asset_close" REFERENCING OLD TABLE AS "old_rows" NEW TABLE AS "new_rows" FOR EACH STATEMENT EXECUTE FUNCTION "dws"."trg_snapshots_prices"();



CREATE OR REPLACE TRIGGER "after_new_tx_legs" AFTER INSERT ON "dwd"."tx_legs" REFERENCING NEW TABLE AS "new_rows" FOR EACH STATEMENT EXECUTE FUNCTION "dws"."trg_snapshots_tx_legs"();



CREATE OR REPLACE TRIGGER "after_filled_dnse_orders" AFTER INSERT ON "ods"."dnse_order_events" FOR EACH ROW EXECUTE FUNCTION "dwd"."process_dnse_order"();



CREATE OR REPLACE TRIGGER "after_new_m1_close" AFTER INSERT ON "ods"."dnse_m1_close" FOR EACH ROW EXECUTE FUNCTION "dwd"."upsert_daily_asset_close"();



ALTER TABLE ONLY "dim"."asset"
    ADD CONSTRAINT "assets_currency_fkey" FOREIGN KEY ("currency_id") REFERENCES "dim"."currency"("id") ON UPDATE CASCADE ON DELETE RESTRICT;



ALTER TABLE ONLY "dim"."user_settings"
    ADD CONSTRAINT "user_settings_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id") ON UPDATE CASCADE ON DELETE CASCADE;



ALTER TABLE ONLY "dwd"."daily_asset_close"
    ADD CONSTRAINT "asset_close_asset_id_fkey" FOREIGN KEY ("asset_id") REFERENCES "dim"."asset"("id") ON UPDATE CASCADE ON DELETE CASCADE;



ALTER TABLE ONLY "dwd"."daily_fxrate_close"
    ADD CONSTRAINT "exchange_rates_currency_code_fkey" FOREIGN KEY ("currency_id") REFERENCES "dim"."currency"("id") ON UPDATE CASCADE ON DELETE CASCADE;



ALTER TABLE ONLY "dwd"."flights"
    ADD CONSTRAINT "flights_aircraft_type_fkey" FOREIGN KEY ("aircraft_type") REFERENCES "dim"."aircraft"("icao_code") ON UPDATE CASCADE;



ALTER TABLE ONLY "dwd"."flights"
    ADD CONSTRAINT "flights_airline_code_fkey" FOREIGN KEY ("airline_code") REFERENCES "dim"."airline"("icao_code") ON UPDATE CASCADE;



ALTER TABLE ONLY "dwd"."flights"
    ADD CONSTRAINT "flights_arr_airport_iata_fkey" FOREIGN KEY ("arr_airport_iata") REFERENCES "dim"."airport"("iata_code") ON UPDATE CASCADE;



ALTER TABLE ONLY "dwd"."flights"
    ADD CONSTRAINT "flights_dept_airport_iata_fkey" FOREIGN KEY ("dept_airport_iata") REFERENCES "dim"."airport"("iata_code") ON UPDATE CASCADE;



ALTER TABLE ONLY "dwd"."flights"
    ADD CONSTRAINT "flights_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id") ON UPDATE CASCADE ON DELETE CASCADE;



ALTER TABLE ONLY "dwd"."tx_borrow"
    ADD CONSTRAINT "tx_borrow_tx_id_fkey" FOREIGN KEY ("tx_id") REFERENCES "dwd"."tx_entries"("id") ON UPDATE CASCADE ON DELETE CASCADE;



ALTER TABLE ONLY "dwd"."tx_cashflow"
    ADD CONSTRAINT "tx_cashflow_asset_id_fkey" FOREIGN KEY ("asset_id") REFERENCES "dim"."asset"("id") ON UPDATE CASCADE;



ALTER TABLE ONLY "dwd"."tx_cashflow"
    ADD CONSTRAINT "tx_cashflow_tx_id_fkey" FOREIGN KEY ("tx_id") REFERENCES "dwd"."tx_entries"("id") ON UPDATE CASCADE ON DELETE CASCADE;



ALTER TABLE ONLY "dwd"."tx_entries"
    ADD CONSTRAINT "tx_entries_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id") ON UPDATE CASCADE ON DELETE CASCADE;



ALTER TABLE ONLY "dwd"."tx_legs"
    ADD CONSTRAINT "tx_legs_asset_id_fkey" FOREIGN KEY ("asset_id") REFERENCES "dim"."asset"("id") ON UPDATE CASCADE;



ALTER TABLE ONLY "dwd"."tx_legs"
    ADD CONSTRAINT "tx_legs_tx_id_fkey" FOREIGN KEY ("tx_id") REFERENCES "dwd"."tx_entries"("id") ON UPDATE CASCADE ON DELETE CASCADE;



ALTER TABLE ONLY "dwd"."tx_repay"
    ADD CONSTRAINT "tx_repay_borrow_tx_fkey" FOREIGN KEY ("borrow_tx") REFERENCES "dwd"."tx_borrow"("tx_id") ON UPDATE CASCADE;



ALTER TABLE ONLY "dwd"."tx_repay"
    ADD CONSTRAINT "tx_repay_tx_id_fkey" FOREIGN KEY ("tx_id") REFERENCES "dwd"."tx_entries"("id") ON UPDATE CASCADE ON DELETE CASCADE;



ALTER TABLE ONLY "dwd"."tx_stock"
    ADD CONSTRAINT "tx_stock_stock_id_fkey" FOREIGN KEY ("stock_id") REFERENCES "dim"."asset"("id") ON UPDATE CASCADE;



ALTER TABLE ONLY "dwd"."tx_stock"
    ADD CONSTRAINT "tx_stock_tx_id_fkey" FOREIGN KEY ("tx_id") REFERENCES "dwd"."tx_entries"("id") ON UPDATE CASCADE ON DELETE CASCADE;



ALTER TABLE ONLY "dws"."daily_snapshots"
    ADD CONSTRAINT "daily_snapshots_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id") ON UPDATE CASCADE ON DELETE CASCADE;



CREATE POLICY "Enable read access for all users" ON "dim"."aircraft" FOR SELECT TO "authenticated" USING (true);



CREATE POLICY "Enable read access for all users" ON "dim"."airline" FOR SELECT TO "authenticated" USING (true);



CREATE POLICY "Enable read access for all users" ON "dim"."airport" FOR SELECT TO "authenticated" USING (true);



CREATE POLICY "Enable read access for all users" ON "dim"."asset" FOR SELECT TO "authenticated" USING (true);



CREATE POLICY "Enable read access for all users" ON "dim"."currency" FOR SELECT TO "authenticated" USING (true);



CREATE POLICY "Enable users to view their own data only" ON "dim"."user_settings" FOR SELECT TO "authenticated" USING ((( SELECT "auth"."uid"() AS "uid") = "user_id"));



ALTER TABLE "dim"."aircraft" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "dim"."airline" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "dim"."airport" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "dim"."asset" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "dim"."currency" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "dim"."user_settings" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "Enable delete for users based on user_id" ON "dwd"."flights" FOR DELETE TO "authenticated" USING ((( SELECT "auth"."uid"() AS "uid") = "user_id"));



CREATE POLICY "Enable delete for users based on user_id" ON "dwd"."tx_borrow" FOR DELETE TO "authenticated" USING ((EXISTS ( SELECT 1
   FROM "dwd"."tx_entries" "e"
  WHERE (("e"."id" = "tx_borrow"."tx_id") AND ("e"."user_id" = ( SELECT "auth"."uid"() AS "uid"))))));



CREATE POLICY "Enable delete for users based on user_id" ON "dwd"."tx_cashflow" FOR DELETE TO "authenticated" USING ((EXISTS ( SELECT 1
   FROM "dwd"."tx_entries" "e"
  WHERE (("e"."id" = "tx_cashflow"."tx_id") AND ("e"."user_id" = ( SELECT "auth"."uid"() AS "uid"))))));



CREATE POLICY "Enable delete for users based on user_id" ON "dwd"."tx_entries" FOR DELETE TO "authenticated" USING ((( SELECT "auth"."uid"() AS "uid") = "user_id"));



CREATE POLICY "Enable delete for users based on user_id" ON "dwd"."tx_legs" FOR DELETE TO "authenticated" USING ((EXISTS ( SELECT 1
   FROM "dwd"."tx_entries" "e"
  WHERE (("e"."id" = "tx_legs"."tx_id") AND ("e"."user_id" = ( SELECT "auth"."uid"() AS "uid"))))));



CREATE POLICY "Enable delete for users based on user_id" ON "dwd"."tx_repay" FOR DELETE TO "authenticated" USING ((EXISTS ( SELECT 1
   FROM "dwd"."tx_entries" "e"
  WHERE (("e"."id" = "tx_repay"."tx_id") AND ("e"."user_id" = ( SELECT "auth"."uid"() AS "uid"))))));



CREATE POLICY "Enable delete for users based on user_id" ON "dwd"."tx_stock" FOR DELETE TO "authenticated" USING ((EXISTS ( SELECT 1
   FROM "dwd"."tx_entries" "e"
  WHERE (("e"."id" = "tx_stock"."tx_id") AND ("e"."user_id" = ( SELECT "auth"."uid"() AS "uid"))))));



CREATE POLICY "Enable insert for authenticated users only" ON "dwd"."daily_asset_close" FOR INSERT TO "authenticated" WITH CHECK (true);



CREATE POLICY "Enable insert for authenticated users only" ON "dwd"."daily_fxrate_close" FOR INSERT TO "authenticated" WITH CHECK (true);



CREATE POLICY "Enable insert for authenticated users only" ON "dwd"."tx_borrow" FOR INSERT TO "authenticated" WITH CHECK (true);



CREATE POLICY "Enable insert for authenticated users only" ON "dwd"."tx_cashflow" FOR INSERT TO "authenticated" WITH CHECK (true);



CREATE POLICY "Enable insert for authenticated users only" ON "dwd"."tx_entries" FOR INSERT TO "authenticated" WITH CHECK (true);



CREATE POLICY "Enable insert for authenticated users only" ON "dwd"."tx_legs" FOR INSERT TO "authenticated" WITH CHECK (true);



CREATE POLICY "Enable insert for authenticated users only" ON "dwd"."tx_repay" FOR INSERT TO "authenticated" WITH CHECK (true);



CREATE POLICY "Enable insert for authenticated users only" ON "dwd"."tx_stock" FOR INSERT TO "authenticated" WITH CHECK ((EXISTS ( SELECT 1
   FROM "dwd"."tx_entries" "e"
  WHERE (("e"."id" = "tx_stock"."tx_id") AND ("e"."user_id" = ( SELECT "auth"."uid"() AS "uid"))))));



CREATE POLICY "Enable insert for users based on user_id" ON "dwd"."flights" FOR INSERT TO "authenticated" WITH CHECK ((( SELECT "auth"."uid"() AS "uid") = "user_id"));



CREATE POLICY "Enable read access for all users" ON "dwd"."daily_asset_close" FOR SELECT TO "authenticated" USING (true);



CREATE POLICY "Enable read access for all users" ON "dwd"."daily_fxrate_close" FOR SELECT TO "authenticated" USING (true);



CREATE POLICY "Enable update for authenticated users only" ON "dwd"."daily_asset_close" FOR UPDATE TO "authenticated" USING (true);



CREATE POLICY "Enable update for authenticated users only" ON "dwd"."daily_fxrate_close" FOR UPDATE TO "authenticated" USING (true);



CREATE POLICY "Enable update for authenticated users only" ON "dwd"."tx_borrow" FOR UPDATE TO "authenticated" USING (true);



CREATE POLICY "Enable update for authenticated users only" ON "dwd"."tx_cashflow" FOR UPDATE TO "authenticated" USING (true);



CREATE POLICY "Enable update for authenticated users only" ON "dwd"."tx_legs" FOR UPDATE TO "authenticated" USING (true);



CREATE POLICY "Enable update for authenticated users only" ON "dwd"."tx_repay" FOR UPDATE TO "authenticated" USING (true);



CREATE POLICY "Enable update for authenticated users only" ON "dwd"."tx_stock" FOR UPDATE TO "authenticated" USING ((EXISTS ( SELECT 1
   FROM "dwd"."tx_entries" "e"
  WHERE (("e"."id" = "tx_stock"."tx_id") AND ("e"."user_id" = ( SELECT "auth"."uid"() AS "uid"))))));



CREATE POLICY "Enable update for users based on user_id" ON "dwd"."flights" FOR UPDATE TO "authenticated" USING ((( SELECT "auth"."uid"() AS "uid") = "user_id")) WITH CHECK ((( SELECT "auth"."uid"() AS "uid") = "user_id"));



CREATE POLICY "Enable users to update their own data only" ON "dwd"."tx_entries" FOR UPDATE TO "authenticated" USING (true) WITH CHECK ((( SELECT "auth"."uid"() AS "uid") = "user_id"));



CREATE POLICY "Enable users to view their own data only" ON "dwd"."flights" FOR SELECT TO "authenticated" USING ((( SELECT "auth"."uid"() AS "uid") = "user_id"));



CREATE POLICY "Enable users to view their own data only" ON "dwd"."tx_borrow" FOR SELECT TO "authenticated" USING ((EXISTS ( SELECT 1
   FROM "dwd"."tx_entries" "e"
  WHERE (("e"."id" = "tx_borrow"."tx_id") AND ("e"."user_id" = ( SELECT "auth"."uid"() AS "uid"))))));



CREATE POLICY "Enable users to view their own data only" ON "dwd"."tx_cashflow" FOR SELECT TO "authenticated" USING ((EXISTS ( SELECT 1
   FROM "dwd"."tx_entries" "e"
  WHERE (("e"."id" = "tx_cashflow"."tx_id") AND ("e"."user_id" = ( SELECT "auth"."uid"() AS "uid"))))));



CREATE POLICY "Enable users to view their own data only" ON "dwd"."tx_entries" FOR SELECT TO "authenticated" USING ((( SELECT "auth"."uid"() AS "uid") = "user_id"));



CREATE POLICY "Enable users to view their own data only" ON "dwd"."tx_legs" FOR SELECT TO "authenticated" USING ((EXISTS ( SELECT 1
   FROM "dwd"."tx_entries" "e"
  WHERE (("e"."id" = "tx_legs"."tx_id") AND ("e"."user_id" = ( SELECT "auth"."uid"() AS "uid"))))));



CREATE POLICY "Enable users to view their own data only" ON "dwd"."tx_repay" FOR SELECT TO "authenticated" USING ((EXISTS ( SELECT 1
   FROM "dwd"."tx_entries" "e"
  WHERE (("e"."id" = "tx_repay"."tx_id") AND ("e"."user_id" = ( SELECT "auth"."uid"() AS "uid"))))));



CREATE POLICY "Enable users to view their own data only" ON "dwd"."tx_stock" FOR SELECT TO "authenticated" USING ((EXISTS ( SELECT 1
   FROM "dwd"."tx_entries" "e"
  WHERE (("e"."id" = "tx_stock"."tx_id") AND ("e"."user_id" = ( SELECT "auth"."uid"() AS "uid"))))));



ALTER TABLE "dwd"."daily_asset_close" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "dwd"."daily_fxrate_close" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "dwd"."flights" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "dwd"."tx_borrow" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "dwd"."tx_cashflow" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "dwd"."tx_entries" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "dwd"."tx_legs" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "dwd"."tx_repay" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "dwd"."tx_stock" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "Enable users to view their own data only" ON "dws"."daily_snapshots" TO "authenticated" USING ((( SELECT "auth"."uid"() AS "uid") = "user_id"));



ALTER TABLE "dws"."daily_snapshots" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "Enable read access for all users" ON "ods"."dnse_m1_close" FOR SELECT TO "authenticated" USING (true);



CREATE POLICY "Enable read access for all users" ON "ods"."dnse_order_events" FOR SELECT TO "authenticated" USING (true);



CREATE POLICY "Enable read access for all users" ON "ods"."news_articles" FOR SELECT TO "authenticated" USING (true);



ALTER TABLE "ods"."dnse_m1_close" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "ods"."dnse_order_events" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "ods"."news_articles" ENABLE ROW LEVEL SECURITY;




ALTER PUBLICATION "supabase_realtime" OWNER TO "postgres";





GRANT USAGE ON SCHEMA "dim" TO "anon";
GRANT USAGE ON SCHEMA "dim" TO "authenticated";
GRANT USAGE ON SCHEMA "dim" TO "service_role";



GRANT USAGE ON SCHEMA "dwd" TO "anon";
GRANT USAGE ON SCHEMA "dwd" TO "authenticated";
GRANT USAGE ON SCHEMA "dwd" TO "service_role";



GRANT USAGE ON SCHEMA "dws" TO "anon";
GRANT USAGE ON SCHEMA "dws" TO "authenticated";
GRANT USAGE ON SCHEMA "dws" TO "service_role";






GRANT USAGE ON SCHEMA "ods" TO "anon";
GRANT USAGE ON SCHEMA "ods" TO "authenticated";
GRANT USAGE ON SCHEMA "ods" TO "service_role";



GRANT USAGE ON SCHEMA "public" TO "postgres";
GRANT USAGE ON SCHEMA "public" TO "anon";
GRANT USAGE ON SCHEMA "public" TO "authenticated";
GRANT USAGE ON SCHEMA "public" TO "service_role";
























GRANT ALL ON FUNCTION "dim"."haversine_distance_km"("lat1" double precision, "lng1" double precision, "lat2" double precision, "lng2" double precision) TO "anon";
GRANT ALL ON FUNCTION "dim"."haversine_distance_km"("lat1" double precision, "lng1" double precision, "lat2" double precision, "lng2" double precision) TO "authenticated";
GRANT ALL ON FUNCTION "dim"."haversine_distance_km"("lat1" double precision, "lng1" double precision, "lat2" double precision, "lng2" double precision) TO "service_role";



GRANT ALL ON FUNCTION "dwd"."add_borrow_event"("p_principal" numeric, "p_lender" "text", "p_rate" numeric, "p_created_at" timestamp with time zone) TO "anon";
GRANT ALL ON FUNCTION "dwd"."add_borrow_event"("p_principal" numeric, "p_lender" "text", "p_rate" numeric, "p_created_at" timestamp with time zone) TO "authenticated";
GRANT ALL ON FUNCTION "dwd"."add_borrow_event"("p_principal" numeric, "p_lender" "text", "p_rate" numeric, "p_created_at" timestamp with time zone) TO "service_role";



GRANT ALL ON FUNCTION "dwd"."add_cashflow_event"("p_operation" "text", "p_asset_id" smallint, "p_quantity" numeric, "p_fx_rate" numeric, "p_memo" "text", "p_created_at" timestamp with time zone, "p_user_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "dwd"."add_cashflow_event"("p_operation" "text", "p_asset_id" smallint, "p_quantity" numeric, "p_fx_rate" numeric, "p_memo" "text", "p_created_at" timestamp with time zone, "p_user_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "dwd"."add_cashflow_event"("p_operation" "text", "p_asset_id" smallint, "p_quantity" numeric, "p_fx_rate" numeric, "p_memo" "text", "p_created_at" timestamp with time zone, "p_user_id" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "dwd"."add_repay_event"("p_repay_tx" integer, "p_interest" numeric, "p_created_at" timestamp with time zone) TO "anon";
GRANT ALL ON FUNCTION "dwd"."add_repay_event"("p_repay_tx" integer, "p_interest" numeric, "p_created_at" timestamp with time zone) TO "authenticated";
GRANT ALL ON FUNCTION "dwd"."add_repay_event"("p_repay_tx" integer, "p_interest" numeric, "p_created_at" timestamp with time zone) TO "service_role";



GRANT ALL ON FUNCTION "dwd"."add_stock_event"("p_side" "text", "p_stock_id" smallint, "p_price" numeric, "p_quantity" numeric, "p_fee" numeric, "p_tax" numeric, "p_user_id" "uuid", "p_created_at" timestamp with time zone) TO "anon";
GRANT ALL ON FUNCTION "dwd"."add_stock_event"("p_side" "text", "p_stock_id" smallint, "p_price" numeric, "p_quantity" numeric, "p_fee" numeric, "p_tax" numeric, "p_user_id" "uuid", "p_created_at" timestamp with time zone) TO "authenticated";
GRANT ALL ON FUNCTION "dwd"."add_stock_event"("p_side" "text", "p_stock_id" smallint, "p_price" numeric, "p_quantity" numeric, "p_fee" numeric, "p_tax" numeric, "p_user_id" "uuid", "p_created_at" timestamp with time zone) TO "service_role";



GRANT ALL ON FUNCTION "dwd"."process_dnse_order"() TO "anon";
GRANT ALL ON FUNCTION "dwd"."process_dnse_order"() TO "authenticated";
GRANT ALL ON FUNCTION "dwd"."process_dnse_order"() TO "service_role";



GRANT ALL ON FUNCTION "dwd"."process_tx_borrow"("p_tx_id" integer) TO "anon";
GRANT ALL ON FUNCTION "dwd"."process_tx_borrow"("p_tx_id" integer) TO "authenticated";
GRANT ALL ON FUNCTION "dwd"."process_tx_borrow"("p_tx_id" integer) TO "service_role";



GRANT ALL ON FUNCTION "dwd"."process_tx_cashflow"("p_tx_id" integer) TO "anon";
GRANT ALL ON FUNCTION "dwd"."process_tx_cashflow"("p_tx_id" integer) TO "authenticated";
GRANT ALL ON FUNCTION "dwd"."process_tx_cashflow"("p_tx_id" integer) TO "service_role";



GRANT ALL ON FUNCTION "dwd"."process_tx_repay"("p_tx_id" integer) TO "anon";
GRANT ALL ON FUNCTION "dwd"."process_tx_repay"("p_tx_id" integer) TO "authenticated";
GRANT ALL ON FUNCTION "dwd"."process_tx_repay"("p_tx_id" integer) TO "service_role";



GRANT ALL ON FUNCTION "dwd"."process_tx_stock"("p_tx_id" integer) TO "anon";
GRANT ALL ON FUNCTION "dwd"."process_tx_stock"("p_tx_id" integer) TO "authenticated";
GRANT ALL ON FUNCTION "dwd"."process_tx_stock"("p_tx_id" integer) TO "service_role";



GRANT ALL ON FUNCTION "dwd"."rebuild_ledger"() TO "anon";
GRANT ALL ON FUNCTION "dwd"."rebuild_ledger"() TO "authenticated";
GRANT ALL ON FUNCTION "dwd"."rebuild_ledger"() TO "service_role";



GRANT ALL ON FUNCTION "dwd"."upsert_daily_asset_close"() TO "anon";
GRANT ALL ON FUNCTION "dwd"."upsert_daily_asset_close"() TO "authenticated";
GRANT ALL ON FUNCTION "dwd"."upsert_daily_asset_close"() TO "service_role";



GRANT ALL ON FUNCTION "dws"."active_stock_tickers"() TO "anon";
GRANT ALL ON FUNCTION "dws"."active_stock_tickers"() TO "authenticated";
GRANT ALL ON FUNCTION "dws"."active_stock_tickers"() TO "service_role";



GRANT ALL ON FUNCTION "dws"."calculate_pnl"("p_start_date" "date", "p_end_date" "date") TO "anon";
GRANT ALL ON FUNCTION "dws"."calculate_pnl"("p_start_date" "date", "p_end_date" "date") TO "authenticated";
GRANT ALL ON FUNCTION "dws"."calculate_pnl"("p_start_date" "date", "p_end_date" "date") TO "service_role";



GRANT ALL ON FUNCTION "dws"."calculate_twr"("p_start_date" "date", "p_end_date" "date") TO "anon";
GRANT ALL ON FUNCTION "dws"."calculate_twr"("p_start_date" "date", "p_end_date" "date") TO "authenticated";
GRANT ALL ON FUNCTION "dws"."calculate_twr"("p_start_date" "date", "p_end_date" "date") TO "service_role";



GRANT ALL ON FUNCTION "dws"."calculate_vnindex_return"("p_start_date" "date", "p_end_date" "date") TO "anon";
GRANT ALL ON FUNCTION "dws"."calculate_vnindex_return"("p_start_date" "date", "p_end_date" "date") TO "authenticated";
GRANT ALL ON FUNCTION "dws"."calculate_vnindex_return"("p_start_date" "date", "p_end_date" "date") TO "service_role";



GRANT ALL ON FUNCTION "dws"."get_cashflow_summary"("p_start_date" "date", "p_end_date" "date") TO "anon";
GRANT ALL ON FUNCTION "dws"."get_cashflow_summary"("p_start_date" "date", "p_end_date" "date") TO "authenticated";
GRANT ALL ON FUNCTION "dws"."get_cashflow_summary"("p_start_date" "date", "p_end_date" "date") TO "service_role";



GRANT ALL ON FUNCTION "dws"."get_equity_chart"("p_start_date" "date", "p_end_date" "date", "p_threshold" integer) TO "anon";
GRANT ALL ON FUNCTION "dws"."get_equity_chart"("p_start_date" "date", "p_end_date" "date", "p_threshold" integer) TO "authenticated";
GRANT ALL ON FUNCTION "dws"."get_equity_chart"("p_start_date" "date", "p_end_date" "date", "p_threshold" integer) TO "service_role";



GRANT ALL ON FUNCTION "dws"."get_event_borrow"() TO "anon";
GRANT ALL ON FUNCTION "dws"."get_event_borrow"() TO "authenticated";
GRANT ALL ON FUNCTION "dws"."get_event_borrow"() TO "service_role";



GRANT ALL ON FUNCTION "dws"."get_event_cashflow"("p_start_date" "date", "p_end_date" "date", "p_operation" "text") TO "anon";
GRANT ALL ON FUNCTION "dws"."get_event_cashflow"("p_start_date" "date", "p_end_date" "date", "p_operation" "text") TO "authenticated";
GRANT ALL ON FUNCTION "dws"."get_event_cashflow"("p_start_date" "date", "p_end_date" "date", "p_operation" "text") TO "service_role";



GRANT ALL ON FUNCTION "dws"."get_event_repay"() TO "anon";
GRANT ALL ON FUNCTION "dws"."get_event_repay"() TO "authenticated";
GRANT ALL ON FUNCTION "dws"."get_event_repay"() TO "service_role";



GRANT ALL ON FUNCTION "dws"."get_event_stock"("p_ticker" "text", "p_operation" "text", "p_start_date" "date", "p_end_date" "date") TO "anon";
GRANT ALL ON FUNCTION "dws"."get_event_stock"("p_ticker" "text", "p_operation" "text", "p_start_date" "date", "p_end_date" "date") TO "authenticated";
GRANT ALL ON FUNCTION "dws"."get_event_stock"("p_ticker" "text", "p_operation" "text", "p_start_date" "date", "p_end_date" "date") TO "service_role";



GRANT ALL ON FUNCTION "dws"."get_flights_by_month"() TO "anon";
GRANT ALL ON FUNCTION "dws"."get_flights_by_month"() TO "authenticated";
GRANT ALL ON FUNCTION "dws"."get_flights_by_month"() TO "service_role";



GRANT ALL ON FUNCTION "dws"."get_flights_by_weekday"() TO "anon";
GRANT ALL ON FUNCTION "dws"."get_flights_by_weekday"() TO "authenticated";
GRANT ALL ON FUNCTION "dws"."get_flights_by_weekday"() TO "service_role";



GRANT ALL ON FUNCTION "dws"."get_flights_by_year"() TO "anon";
GRANT ALL ON FUNCTION "dws"."get_flights_by_year"() TO "authenticated";
GRANT ALL ON FUNCTION "dws"."get_flights_by_year"() TO "service_role";



GRANT ALL ON FUNCTION "dws"."get_monthly_pnl_chart"("p_start_date" "date", "p_end_date" "date") TO "anon";
GRANT ALL ON FUNCTION "dws"."get_monthly_pnl_chart"("p_start_date" "date", "p_end_date" "date") TO "authenticated";
GRANT ALL ON FUNCTION "dws"."get_monthly_pnl_chart"("p_start_date" "date", "p_end_date" "date") TO "service_role";



GRANT ALL ON FUNCTION "dws"."get_return_chart"("p_start_date" "date", "p_end_date" "date", "p_threshold" integer) TO "anon";
GRANT ALL ON FUNCTION "dws"."get_return_chart"("p_start_date" "date", "p_end_date" "date", "p_threshold" integer) TO "authenticated";
GRANT ALL ON FUNCTION "dws"."get_return_chart"("p_start_date" "date", "p_end_date" "date", "p_threshold" integer) TO "service_role";



GRANT ALL ON FUNCTION "dws"."get_top_aircrafts"() TO "anon";
GRANT ALL ON FUNCTION "dws"."get_top_aircrafts"() TO "authenticated";
GRANT ALL ON FUNCTION "dws"."get_top_aircrafts"() TO "service_role";



GRANT ALL ON FUNCTION "dws"."get_top_airlines"() TO "anon";
GRANT ALL ON FUNCTION "dws"."get_top_airlines"() TO "authenticated";
GRANT ALL ON FUNCTION "dws"."get_top_airlines"() TO "service_role";



GRANT ALL ON FUNCTION "dws"."get_top_airports"() TO "anon";
GRANT ALL ON FUNCTION "dws"."get_top_airports"() TO "authenticated";
GRANT ALL ON FUNCTION "dws"."get_top_airports"() TO "service_role";



GRANT ALL ON FUNCTION "dws"."get_top_routes"() TO "anon";
GRANT ALL ON FUNCTION "dws"."get_top_routes"() TO "authenticated";
GRANT ALL ON FUNCTION "dws"."get_top_routes"() TO "service_role";



GRANT ALL ON FUNCTION "dws"."get_top_stocks"("p_start_date" "date", "p_end_date" "date") TO "anon";
GRANT ALL ON FUNCTION "dws"."get_top_stocks"("p_start_date" "date", "p_end_date" "date") TO "authenticated";
GRANT ALL ON FUNCTION "dws"."get_top_stocks"("p_start_date" "date", "p_end_date" "date") TO "service_role";















































































































































































































GRANT ALL ON TABLE "dim"."aircraft" TO "anon";
GRANT ALL ON TABLE "dim"."aircraft" TO "authenticated";
GRANT ALL ON TABLE "dim"."aircraft" TO "service_role";



GRANT ALL ON TABLE "dim"."airline" TO "anon";
GRANT ALL ON TABLE "dim"."airline" TO "authenticated";
GRANT ALL ON TABLE "dim"."airline" TO "service_role";



GRANT ALL ON TABLE "dim"."airport" TO "anon";
GRANT ALL ON TABLE "dim"."airport" TO "authenticated";
GRANT ALL ON TABLE "dim"."airport" TO "service_role";



GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE "dim"."asset" TO "anon";
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE "dim"."asset" TO "authenticated";
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE "dim"."asset" TO "service_role";



GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE "dim"."currency" TO "anon";
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE "dim"."currency" TO "authenticated";
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE "dim"."currency" TO "service_role";



GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE "dim"."user_settings" TO "anon";
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE "dim"."user_settings" TO "authenticated";
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE "dim"."user_settings" TO "service_role";



GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE "dwd"."daily_asset_close" TO "anon";
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE "dwd"."daily_asset_close" TO "authenticated";
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE "dwd"."daily_asset_close" TO "service_role";



GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE "dwd"."daily_fxrate_close" TO "anon";
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE "dwd"."daily_fxrate_close" TO "authenticated";
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE "dwd"."daily_fxrate_close" TO "service_role";



GRANT ALL ON TABLE "dwd"."flights" TO "anon";
GRANT ALL ON TABLE "dwd"."flights" TO "authenticated";
GRANT ALL ON TABLE "dwd"."flights" TO "service_role";



GRANT ALL ON SEQUENCE "dwd"."flights_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "dwd"."flights_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "dwd"."flights_id_seq" TO "service_role";



GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE "dwd"."tx_borrow" TO "anon";
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE "dwd"."tx_borrow" TO "authenticated";
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE "dwd"."tx_borrow" TO "service_role";



GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE "dwd"."tx_cashflow" TO "anon";
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE "dwd"."tx_cashflow" TO "authenticated";
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE "dwd"."tx_cashflow" TO "service_role";



GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE "dwd"."tx_entries" TO "anon";
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE "dwd"."tx_entries" TO "authenticated";
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE "dwd"."tx_entries" TO "service_role";



GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE "dwd"."tx_legs" TO "anon";
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE "dwd"."tx_legs" TO "authenticated";
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE "dwd"."tx_legs" TO "service_role";



GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE "dwd"."tx_repay" TO "anon";
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE "dwd"."tx_repay" TO "authenticated";
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE "dwd"."tx_repay" TO "service_role";



GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE "dwd"."tx_stock" TO "anon";
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE "dwd"."tx_stock" TO "authenticated";
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE "dwd"."tx_stock" TO "service_role";



GRANT ALL ON TABLE "dws"."outstanding_debts" TO "anon";
GRANT ALL ON TABLE "dws"."outstanding_debts" TO "authenticated";
GRANT ALL ON TABLE "dws"."outstanding_debts" TO "service_role";



GRANT ALL ON TABLE "dws"."balance_sheet" TO "anon";
GRANT ALL ON TABLE "dws"."balance_sheet" TO "authenticated";
GRANT ALL ON TABLE "dws"."balance_sheet" TO "service_role";



GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE "dws"."daily_snapshots" TO "anon";
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE "dws"."daily_snapshots" TO "authenticated";
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE "dws"."daily_snapshots" TO "service_role";



GRANT ALL ON TABLE "dws"."flights_summary" TO "anon";
GRANT ALL ON TABLE "dws"."flights_summary" TO "authenticated";
GRANT ALL ON TABLE "dws"."flights_summary" TO "service_role";



GRANT ALL ON TABLE "dws"."lifetime_stats" TO "anon";
GRANT ALL ON TABLE "dws"."lifetime_stats" TO "authenticated";
GRANT ALL ON TABLE "dws"."lifetime_stats" TO "service_role";



GRANT ALL ON TABLE "dws"."unique_routes" TO "anon";
GRANT ALL ON TABLE "dws"."unique_routes" TO "authenticated";
GRANT ALL ON TABLE "dws"."unique_routes" TO "service_role";















GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE "ods"."dnse_m1_close" TO "anon";
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE "ods"."dnse_m1_close" TO "authenticated";
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE "ods"."dnse_m1_close" TO "service_role";



GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE "ods"."dnse_order_events" TO "anon";
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE "ods"."dnse_order_events" TO "authenticated";
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE "ods"."dnse_order_events" TO "service_role";



GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE "ods"."news_articles" TO "anon";
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE "ods"."news_articles" TO "authenticated";
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE "ods"."news_articles" TO "service_role";









ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "dim" GRANT ALL ON SEQUENCES TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "dim" GRANT ALL ON SEQUENCES TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "dim" GRANT ALL ON SEQUENCES TO "service_role";



ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "dim" GRANT ALL ON FUNCTIONS TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "dim" GRANT ALL ON FUNCTIONS TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "dim" GRANT ALL ON FUNCTIONS TO "service_role";



ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "dim" GRANT ALL ON TABLES TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "dim" GRANT ALL ON TABLES TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "dim" GRANT ALL ON TABLES TO "service_role";



ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "dwd" GRANT ALL ON SEQUENCES TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "dwd" GRANT ALL ON SEQUENCES TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "dwd" GRANT ALL ON SEQUENCES TO "service_role";



ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "dwd" GRANT ALL ON FUNCTIONS TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "dwd" GRANT ALL ON FUNCTIONS TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "dwd" GRANT ALL ON FUNCTIONS TO "service_role";



ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "dwd" GRANT ALL ON TABLES TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "dwd" GRANT ALL ON TABLES TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "dwd" GRANT ALL ON TABLES TO "service_role";



ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "dws" GRANT ALL ON SEQUENCES TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "dws" GRANT ALL ON SEQUENCES TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "dws" GRANT ALL ON SEQUENCES TO "service_role";



ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "dws" GRANT ALL ON FUNCTIONS TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "dws" GRANT ALL ON FUNCTIONS TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "dws" GRANT ALL ON FUNCTIONS TO "service_role";



ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "dws" GRANT ALL ON TABLES TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "dws" GRANT ALL ON TABLES TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "dws" GRANT ALL ON TABLES TO "service_role";



ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "ods" GRANT ALL ON SEQUENCES TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "ods" GRANT ALL ON SEQUENCES TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "ods" GRANT ALL ON SEQUENCES TO "service_role";



ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "ods" GRANT ALL ON FUNCTIONS TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "ods" GRANT ALL ON FUNCTIONS TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "ods" GRANT ALL ON FUNCTIONS TO "service_role";



ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "ods" GRANT ALL ON TABLES TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "ods" GRANT ALL ON TABLES TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "ods" GRANT ALL ON TABLES TO "service_role";



ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "service_role";






ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "service_role";






ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "service_role";
































--
-- Dumped schema changes for auth and storage
--

