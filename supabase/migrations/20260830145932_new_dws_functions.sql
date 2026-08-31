


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


CREATE SCHEMA IF NOT EXISTS "flight";


ALTER SCHEMA "flight" OWNER TO "postgres";


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


CREATE TYPE "dim"."stock_ops" AS ENUM (
    'buy',
    'sell'
);


ALTER TYPE "dim"."stock_ops" OWNER TO "postgres";


COMMENT ON TYPE "dim"."stock_ops" IS 'Operation types for stock transactions';



CREATE TYPE "dim"."tx_category" AS ENUM (
    'stock',
    'cashflow',
    'borrow',
    'repay'
);


ALTER TYPE "dim"."tx_category" OWNER TO "postgres";


COMMENT ON TYPE "dim"."tx_category" IS 'Categories of transaction events';



CREATE TYPE "flight"."seat_position" AS ENUM (
    'window',
    'middle',
    'aisle'
);


ALTER TYPE "flight"."seat_position" OWNER TO "postgres";


CREATE TYPE "flight"."seat_type" AS ENUM (
    'eco',
    'biz'
);


ALTER TYPE "flight"."seat_type" OWNER TO "postgres";


CREATE TYPE "flight"."ticket_class" AS ENUM (
    'eco',
    'biz'
);


ALTER TYPE "flight"."ticket_class" OWNER TO "postgres";


CREATE TYPE "public"."asset_class" AS ENUM (
    'cash',
    'stock',
    'crypto',
    'fund',
    'equity',
    'liability',
    'index'
);


ALTER TYPE "public"."asset_class" OWNER TO "postgres";


CREATE TYPE "public"."benchmark_point" AS (
	"snapshot_date" "date",
	"portfolio_value" numeric,
	"vni_value" numeric
);


ALTER TYPE "public"."benchmark_point" OWNER TO "postgres";


CREATE TYPE "public"."cashflow_ops" AS ENUM (
    'deposit',
    'withdraw',
    'income',
    'expense'
);


ALTER TYPE "public"."cashflow_ops" OWNER TO "postgres";


CREATE TYPE "public"."dnse_order_status" AS ENUM (
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


ALTER TYPE "public"."dnse_order_status" OWNER TO "postgres";


CREATE TYPE "public"."equity_point" AS (
	"snapshot_date" "date",
	"total_cashflow" numeric,
	"total_equity" numeric
);


ALTER TYPE "public"."equity_point" OWNER TO "postgres";


CREATE TYPE "public"."stock_ops" AS ENUM (
    'buy',
    'sell'
);


ALTER TYPE "public"."stock_ops" OWNER TO "postgres";


CREATE TYPE "public"."tx_category" AS ENUM (
    'stock',
    'cashflow',
    'borrow',
    'repay'
);


ALTER TYPE "public"."tx_category" OWNER TO "postgres";


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
end;
$$;


ALTER FUNCTION "dwd"."add_repay_event"("p_repay_tx" integer, "p_interest" numeric, "p_created_at" timestamp with time zone) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "dwd"."add_stock_event"("p_side" "text", "p_ticker" "text", "p_price" numeric, "p_quantity" numeric, "p_fee" numeric, "p_tax" numeric DEFAULT 0, "p_user_id" "uuid" DEFAULT "auth"."uid"(), "p_created_at" timestamp with time zone DEFAULT "now"()) RETURNS "void"
    LANGUAGE "plpgsql"
    SET "search_path" TO 'dim', 'dwd'
    AS $$
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
$$;


ALTER FUNCTION "dwd"."add_stock_event"("p_side" "text", "p_ticker" "text", "p_price" numeric, "p_quantity" numeric, "p_fee" numeric, "p_tax" numeric, "p_user_id" "uuid", "p_created_at" timestamp with time zone) OWNER TO "postgres";


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


CREATE OR REPLACE FUNCTION "dwd"."trg_process_tx_borrow"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    SET "search_path" TO 'dwd'
    AS $$
begin
  perform dwd.process_tx_borrow(new.tx_id);
  return new;
end;
$$;


ALTER FUNCTION "dwd"."trg_process_tx_borrow"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "dwd"."trg_process_tx_cashflow"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    SET "search_path" TO 'dwd'
    AS $$begin
  perform dwd.process_tx_cashflow(new.tx_id);
  return new;
end;$$;


ALTER FUNCTION "dwd"."trg_process_tx_cashflow"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "dwd"."trg_process_tx_repay"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    SET "search_path" TO 'dwd'
    AS $$
begin
  perform dwd.process_tx_repay(new.tx_id);
  return new;
end;
$$;


ALTER FUNCTION "dwd"."trg_process_tx_repay"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "dwd"."trg_process_tx_stock"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    SET "search_path" TO 'dwd'
    AS $$begin
  perform dwd.process_tx_stock(new.tx_id);
  return new;
end;$$;


ALTER FUNCTION "dwd"."trg_process_tx_stock"() OWNER TO "postgres";


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


CREATE OR REPLACE FUNCTION "flight"."haversine_distance_km"("lat1" double precision, "lng1" double precision, "lat2" double precision, "lng2" double precision) RETURNS double precision
    LANGUAGE "sql" IMMUTABLE PARALLEL SAFE
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


ALTER FUNCTION "flight"."haversine_distance_km"("lat1" double precision, "lng1" double precision, "lat2" double precision, "lng2" double precision) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "flight"."insert_flight_with_timezone"("p_departure_airport_id" "uuid", "p_departure_local" "text", "p_arrival_airport_id" "uuid", "p_arrival_local" "text", "p_flight_number" "text", "p_airline_id" "uuid", "p_ticket_class" "flight"."ticket_class", "p_seat_no" "text" DEFAULT NULL::"text", "p_seat_pos" "flight"."seat_position" DEFAULT NULL::"flight"."seat_position", "p_aircraft_id" "uuid" DEFAULT NULL::"uuid", "p_tail_no" "text" DEFAULT NULL::"text", "p_notes" "text" DEFAULT NULL::"text") RETURNS "void"
    LANGUAGE "plpgsql"
    SET "search_path" TO 'flight'
    AS $$
declare
  dep_tz text;
  arr_tz text;
  dep_utc timestamptz;
  arr_utc timestamptz;
begin
  select timezone into dep_tz
  from airports
  where id = p_departure_airport_id;

  select timezone into arr_tz
  from airports
  where id = p_arrival_airport_id;

  -- Convert local timestamp (without tz) into UTC
  dep_utc := (p_departure_local::timestamp at time zone dep_tz);
  arr_utc := (p_arrival_local::timestamp at time zone arr_tz);

  insert into flights (
    user_id,
    departure_airport_id,
    departure_time,
    arrival_airport_id,
    arrival_time,
    flight_number,
    airline_id,
    ticket_class,
    seat_number,
    seat_position,
    aircraft_id,
    tail_number,
    notes
  )
  values (
    auth.uid(),
    p_departure_airport_id,
    dep_utc,
    p_arrival_airport_id,
    arr_utc,
    p_flight_number,
    p_airline_id,
    p_ticket_class,
    p_seat_no,
    p_seat_pos,
    p_aircraft_id,
    p_tail_no,
    p_notes
  );
end;
$$;


ALTER FUNCTION "flight"."insert_flight_with_timezone"("p_departure_airport_id" "uuid", "p_departure_local" "text", "p_arrival_airport_id" "uuid", "p_arrival_local" "text", "p_flight_number" "text", "p_airline_id" "uuid", "p_ticket_class" "flight"."ticket_class", "p_seat_no" "text", "p_seat_pos" "flight"."seat_position", "p_aircraft_id" "uuid", "p_tail_no" "text", "p_notes" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "flight"."update_flight_with_timezone"("p_flight_id" "uuid", "p_departure_airport_id" "uuid", "p_departure_local" "text", "p_arrival_airport_id" "uuid", "p_arrival_local" "text", "p_flight_number" "text", "p_airline_id" "uuid", "p_ticket_class" "flight"."ticket_class", "p_seat_no" "text" DEFAULT NULL::"text", "p_seat_pos" "flight"."seat_position" DEFAULT NULL::"flight"."seat_position", "p_aircraft_id" "uuid" DEFAULT NULL::"uuid", "p_tail_no" "text" DEFAULT NULL::"text", "p_notes" "text" DEFAULT NULL::"text") RETURNS "void"
    LANGUAGE "plpgsql"
    SET "search_path" TO 'flight'
    AS $$
declare
  dep_tz text;
  arr_tz text;
  dep_utc timestamptz;
  arr_utc timestamptz;
begin
  select timezone into dep_tz
  from airports
  where id = p_departure_airport_id;

  select timezone into arr_tz
  from airports
  where id = p_arrival_airport_id;

  dep_utc := (p_departure_local::timestamp at time zone dep_tz);
  arr_utc := (p_arrival_local::timestamp at time zone arr_tz);

  update flights set
    departure_airport_id = p_departure_airport_id,
    departure_time = dep_utc,
    arrival_airport_id = p_arrival_airport_id,
    arrival_time = arr_utc,
    flight_number = p_flight_number,
    airline_id = p_airline_id,
    ticket_class = p_ticket_class,
    seat_number = p_seat_no,
    seat_position = p_seat_pos,
    aircraft_id = p_aircraft_id,
    tail_number = p_tail_no,
    notes = p_notes
  where id = p_flight_id
    and user_id = auth.uid();
end;
$$;


ALTER FUNCTION "flight"."update_flight_with_timezone"("p_flight_id" "uuid", "p_departure_airport_id" "uuid", "p_departure_local" "text", "p_arrival_airport_id" "uuid", "p_arrival_local" "text", "p_flight_number" "text", "p_airline_id" "uuid", "p_ticket_class" "flight"."ticket_class", "p_seat_no" "text", "p_seat_pos" "flight"."seat_position", "p_aircraft_id" "uuid", "p_tail_no" "text", "p_notes" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."active_stock_tickers"() RETURNS "jsonb"
    LANGUAGE "sql" STABLE
    SET "search_path" TO 'public'
    AS $$select coalesce(
  jsonb_agg(ticker order by ticker),
  '[]'::jsonb
)
from (
  select a.ticker
  from public.tx_legs l
  join public.assets a on a.id = l.asset_id
  where a.asset_class = 'stock'
  group by a.ticker
  having sum(l.quantity) > 0

  union

  select 'VNINDEX' as ticker
) t(ticker);$$;


ALTER FUNCTION "public"."active_stock_tickers"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."add_borrow_event"("p_principal" numeric, "p_lender" "text", "p_rate" numeric, "p_created_at" timestamp with time zone DEFAULT "now"()) RETURNS "void"
    LANGUAGE "plpgsql"
    SET "search_path" TO 'public'
    AS $$declare
  v_tx_id uuid;
begin
  -- Insert into tx_entries
  insert into public.tx_entries (category, memo, user_id, created_at)
  values (
    'borrow',
    'Borrow ' || p_principal::text || ' from ' || p_lender || ' at ' || to_char(p_rate, 'FM90.##%'),
    auth.uid(),
    COALESCE(p_created_at, now())
  )
  returning id into v_tx_id;

  -- Insert into tx_debt
  insert into public.tx_borrow (
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
end;$$;


ALTER FUNCTION "public"."add_borrow_event"("p_principal" numeric, "p_lender" "text", "p_rate" numeric, "p_created_at" timestamp with time zone) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."add_cashflow_event"("p_operation" "text", "p_asset_id" "uuid", "p_quantity" numeric, "p_fx_rate" numeric, "p_memo" "text", "p_created_at" timestamp with time zone DEFAULT "now"(), "p_user_id" "uuid" DEFAULT "auth"."uid"()) RETURNS "void"
    LANGUAGE "plpgsql"
    SET "search_path" TO 'public'
    AS $$declare
  v_tx_id uuid;
  v_asset_currency text;
  v_fx_rate numeric;
begin
  -- Find asset currency
  select a.currency_code into v_asset_currency
  from public.assets a
  where a.id = p_asset_id;

  -- Determine FX rate
  if v_asset_currency = 'VND' then v_fx_rate := 1;
  else v_fx_rate := coalesce(p_fx_rate, 1);
  end if;

  -- Insert into tx_entries
  insert into public.tx_entries (
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
  insert into public.tx_cashflow (
    tx_id,
    asset_id,
    operation,
    quantity,
    fx_rate
  )
  values (
    v_tx_id,
    p_asset_id,
    p_operation::cashflow_ops,
    p_quantity,
    v_fx_rate
  );
end;$$;


ALTER FUNCTION "public"."add_cashflow_event"("p_operation" "text", "p_asset_id" "uuid", "p_quantity" numeric, "p_fx_rate" numeric, "p_memo" "text", "p_created_at" timestamp with time zone, "p_user_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."add_repay_event"("p_repay_tx" "uuid", "p_interest" numeric, "p_created_at" timestamp with time zone DEFAULT "now"()) RETURNS "void"
    LANGUAGE "plpgsql"
    SET "search_path" TO 'public'
    AS $$declare
  v_tx_id uuid;
  v_lender text;
  v_principal numeric;
begin
  -- Find lender name
  select b.lender into v_lender
  from public.tx_borrow b where b.tx_id = p_repay_tx;

  -- Find principal amount
  select b.principal into v_principal
  from public.tx_borrow b where b.tx_id = p_repay_tx;

  -- Insert into tx_entries
  insert into public.tx_entries (category, memo, user_id, created_at)
  values (
    'repay',
    'Repay to ' || v_lender,
    auth.uid(),
    COALESCE(p_created_at, now())
  ) returning id into v_tx_id;

  -- Insert into tx_repay
  insert into public.tx_repay (
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
end;$$;


ALTER FUNCTION "public"."add_repay_event"("p_repay_tx" "uuid", "p_interest" numeric, "p_created_at" timestamp with time zone) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."add_stock_event"("p_side" "text", "p_ticker" "text", "p_price" numeric, "p_quantity" numeric, "p_fee" numeric, "p_tax" numeric DEFAULT 0, "p_user_id" "uuid" DEFAULT "auth"."uid"(), "p_created_at" timestamp with time zone DEFAULT "now"()) RETURNS "void"
    LANGUAGE "plpgsql"
    SET "search_path" TO 'public'
    AS $$
DECLARE
  v_tx_id uuid;
  v_stock_id uuid;
BEGIN
  SELECT a.id INTO v_stock_id
  FROM public.assets a
  WHERE a.ticker = p_ticker;

  INSERT INTO public.tx_entries (category, memo, user_id, created_at)
  VALUES (
    'stock',
    initcap(p_side) || ' ' || p_quantity::text || ' ' || p_ticker || ' at ' || p_price::text,
    p_user_id,
    COALESCE(p_created_at, now())
  )
  RETURNING id INTO v_tx_id;

  INSERT INTO public.tx_stock (tx_id, operation, stock_id, price, quantity, fee, tax)
  VALUES (v_tx_id, p_side::stock_ops, v_stock_id, p_price, p_quantity, p_fee, COALESCE(p_tax, 0));
END;
$$;


ALTER FUNCTION "public"."add_stock_event"("p_side" "text", "p_ticker" "text", "p_price" numeric, "p_quantity" numeric, "p_fee" numeric, "p_tax" numeric, "p_user_id" "uuid", "p_created_at" timestamp with time zone) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."calculate_pnl"("p_start_date" "date", "p_end_date" "date") RETURNS numeric
    LANGUAGE "plpgsql"
    SET "search_path" TO 'public'
    AS $$DECLARE
  v_pnl NUMERIC;
BEGIN
  SELECT COALESCE(sum(intraday_pnl), 0)
    INTO v_pnl
  FROM public.daily_snapshots
  WHERE user_id = auth.uid()
    AND snapshot_date >= p_start_date
    AND snapshot_date <= p_end_date;

  RETURN v_pnl;
END;$$;


ALTER FUNCTION "public"."calculate_pnl"("p_start_date" "date", "p_end_date" "date") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."calculate_twr"("p_start_date" "date", "p_end_date" "date") RETURNS numeric
    LANGUAGE "plpgsql"
    SET "search_path" TO 'public'
    AS $$
DECLARE
  v_twr NUMERIC;
BEGIN
  SELECT COALESCE(EXP(SUM(LN(1 + intraday_return))) - 1, 0)
    INTO v_twr
  FROM public.daily_snapshots
  WHERE user_id = auth.uid()
    AND snapshot_date >= p_start_date
    AND snapshot_date <= p_end_date
    AND intraday_return IS NOT NULL
    AND intraday_return > -1;   -- guard against ln(0) / ln(negative)

  RETURN COALESCE(v_twr, 0);
END;
$$;


ALTER FUNCTION "public"."calculate_twr"("p_start_date" "date", "p_end_date" "date") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."get_equity_chart"("p_start_date" "date", "p_end_date" "date", "p_threshold" integer DEFAULT 150) RETURNS "jsonb"
    LANGUAGE "plpgsql"
    SET "search_path" TO 'public'
    AS $$DECLARE
  raw_data public.equity_point[];
  result_data public.equity_point[];
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
  selected public.equity_point;
  prev public.equity_point;
  final_result jsonb;
BEGIN
  -- Load dataset into memory
  SELECT array_agg(
           ROW(snapshot_date, total_equity, total_cashflow)::public.equity_point
           ORDER BY snapshot_date
         )
  INTO raw_data
  FROM public.daily_snapshots
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
END;$$;


ALTER FUNCTION "public"."get_equity_chart"("p_start_date" "date", "p_end_date" "date", "p_threshold" integer) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."get_return_chart"("p_start_date" "date", "p_end_date" "date", "p_threshold" integer DEFAULT 150) RETURNS "jsonb"
    LANGUAGE "plpgsql"
    SET "search_path" TO 'public'
    AS $$DECLARE
  v_first_vni_value numeric;
  raw_data public.benchmark_point[];
  result_data public.benchmark_point[];
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
  SELECT hp.close
  INTO v_first_vni_value
  FROM historical_prices hp
    JOIN assets a ON a.id = hp.asset_id
  WHERE a.ticker = 'VNINDEX'
    AND hp.date >= p_start_date
  ORDER BY hp.date
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
      (hp.close / NULLIF(v_first_vni_value, 0)) * 100 AS vni_value
    FROM daily_snapshots pd
      JOIN historical_prices hp ON pd.snapshot_date = hp.date
      JOIN assets a ON a.id = hp.asset_id
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


ALTER FUNCTION "public"."get_return_chart"("p_start_date" "date", "p_end_date" "date", "p_threshold" integer) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."process_dnse_order"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    SET "search_path" TO 'public'
    AS $$BEGIN
  DECLARE
    v_user_id uuid;

  BEGIN
    -- Map broker account → internal user_id
    SELECT us.user_id
      INTO v_user_id
    FROM public.user_settings us
    WHERE us.dnse_account_id = NEW.account_no;

    -- Safety guard (important)
    IF v_user_id IS NULL THEN
      RAISE WARNING 'No user mapping found for account_no=%', NEW.account_no;
      RETURN NULL;
    END IF;

    -- Only process relevant statuses
    IF NEW.order_status = 'Filled'
      AND COALESCE(NEW.fill_quantity, 0) > 0 THEN
      PERFORM public.add_stock_event(
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
END;$$;


ALTER FUNCTION "public"."process_dnse_order"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."process_tx_borrow"("p_tx_id" "uuid") RETURNS "void"
    LANGUAGE "plpgsql"
    SET "search_path" TO 'public'
    AS $$
declare
  r public.tx_borrow%rowtype;
  v_cash_asset uuid;
  v_debt_asset uuid;
begin
  select * into r from public.tx_borrow where tx_id = p_tx_id;

  select id into v_cash_asset from public.assets where ticker = 'FX.VND';
  select id into v_debt_asset from public.assets where ticker = 'DEBTS';

  -- Clear any prior legs for this transaction
  delete from public.tx_legs where tx_id = p_tx_id;

  -- Debit cash (proceeds received)
  insert into public.tx_legs (tx_id, asset_id, quantity, debit, credit)
  values (r.tx_id, v_cash_asset, r.principal, r.principal, 0);

  -- Credit debt (liability created)
  insert into public.tx_legs (tx_id, asset_id, quantity, debit, credit)
  values (r.tx_id, v_debt_asset, r.principal, 0, r.principal);
end;
$$;


ALTER FUNCTION "public"."process_tx_borrow"("p_tx_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."process_tx_cashflow"("p_tx_id" "uuid") RETURNS "void"
    LANGUAGE "plpgsql"
    SET "search_path" TO 'public'
    AS $$DECLARE
  r tx_cashflow%rowtype;
  v_equity_asset uuid;
  v_user_id uuid;
  v_current_qty numeric;
  v_cost_change numeric;
  v_realized_pnl numeric;
  v_current_cost numeric;
BEGIN
  -- Derive user_id from tx_entries (works for both trigger and rebuild_ledger paths)
  SELECT e.user_id INTO v_user_id
  FROM public.tx_entries e
  WHERE e.id = p_tx_id;

  -- Load transaction
  SELECT * INTO r FROM public.tx_cashflow WHERE tx_id = p_tx_id;

  -- Identify assets
  SELECT id INTO v_equity_asset FROM public.assets WHERE ticker = 'CAPITAL';

  -- Clear existing legs
  DELETE FROM public.tx_legs WHERE tx_id = p_tx_id;

  -- Handle by operation type
  IF r.operation IN ('deposit', 'income') THEN
    -- Debit cash asset
    INSERT INTO public.tx_legs (tx_id, asset_id, quantity, debit, credit)
    VALUES (r.tx_id, r.asset_id, r.quantity, r.net_proceed, 0);

    -- Credit equity (capital in)
    INSERT INTO public.tx_legs (tx_id, asset_id, quantity, debit, credit)
    VALUES (r.tx_id, v_equity_asset, r.net_proceed, 0, r.net_proceed);

  ELSE -- Withdraw and expense operation

    -- Calculate current total cost & quantity
    SELECT SUM(l.debit) - SUM(l.credit), SUM(l.quantity)
    INTO v_current_cost, v_current_qty
    FROM public.tx_legs l
      JOIN public.tx_entries e ON l.tx_id = e.id
    WHERE l.asset_id = r.asset_id AND e.user_id = v_user_id;

    v_cost_change := r.quantity * v_current_cost / v_current_qty;
    v_realized_pnl := r.net_proceed - v_cost_change;

    -- Credit cash asset (reduce balance)
    INSERT INTO public.tx_legs (tx_id, asset_id, quantity, debit, credit)
    VALUES (r.tx_id, r.asset_id, -r.quantity, 0, v_cost_change);

    -- Debit equity (capital out & possible gain/loss to equity)
    INSERT INTO public.tx_legs (tx_id, asset_id, quantity, debit, credit)
    VALUES (
      r.tx_id,
      v_equity_asset,
      -v_cost_change,
      r.net_proceed + GREATEST(-v_realized_pnl, 0),
      0 + GREATEST(v_realized_pnl, 0)
    );
  END IF;
END;$$;


ALTER FUNCTION "public"."process_tx_cashflow"("p_tx_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."process_tx_repay"("p_tx_id" "uuid") RETURNS "void"
    LANGUAGE "plpgsql"
    SET "search_path" TO 'public'
    AS $$
declare
  r public.tx_repay%rowtype;
  v_cash_asset uuid;
  v_debt_asset uuid;
  v_equity_asset uuid;
begin
  select * into r from public.tx_repay where tx_id = p_tx_id;

  select id into v_cash_asset   from public.assets where ticker = 'FX.VND';
  select id into v_debt_asset   from public.assets where ticker = 'DEBTS';
  select id into v_equity_asset from public.assets where ticker = 'CAPITAL';

  -- Clear any prior legs for this transaction
  delete from public.tx_legs where tx_id = p_tx_id;

  -- Credit cash (payment made)
  insert into public.tx_legs (tx_id, asset_id, quantity, debit, credit)
  values (r.tx_id, v_cash_asset, -r.net_proceed, 0, r.net_proceed);

  -- Debit debt (liability reduced by principal)
  insert into public.tx_legs (tx_id, asset_id, quantity, debit, credit)
  values (r.tx_id, v_debt_asset, -r.principal, r.principal, 0);

  -- Debit equity (interest expense)
  insert into public.tx_legs (tx_id, asset_id, quantity, debit, credit)
  values (r.tx_id, v_equity_asset, -r.interest, r.interest, 0);
end;
$$;


ALTER FUNCTION "public"."process_tx_repay"("p_tx_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."process_tx_stock"("p_tx_id" "uuid") RETURNS "void"
    LANGUAGE "plpgsql"
    SET "search_path" TO 'public'
    AS $$declare
  r tx_stock%rowtype;
  v_cash_asset uuid;
  v_equity_asset uuid;
  v_realized_pnl numeric;
  v_cost_change numeric;
  v_user_id uuid;
  v_current_cost numeric;
  v_current_qty numeric;
begin
  -- Derive user_id from tx_entries (works for both trigger and rebuild_ledger paths)
  SELECT e.user_id INTO v_user_id
  FROM public.tx_entries e
  WHERE e.id = p_tx_id;

  -- Load the transaction
  select * into r from public.tx_stock where tx_id = p_tx_id;

  -- Resolve asset IDs
  select id into v_cash_asset from public.assets where ticker ='FX.VND';
  select id into v_equity_asset from public.assets where ticker = 'CAPITAL';

  -- Process transaction
  if r.operation = 'buy' then

    -- Debit stock (increase holdings)
    insert into public.tx_legs (tx_id, asset_id, quantity, debit, credit)
    values (r.tx_id, r.stock_id, r.quantity, r.net_proceed, 0);

    -- Credit VND cash
    insert into public.tx_legs (tx_id, asset_id, quantity, debit, credit)
    values (r.tx_id, v_cash_asset, -r.net_proceed, 0, r.net_proceed);

  else -- Sell side

    -- Calculate current total cost & quantity
    SELECT SUM(l.debit) - SUM(l.credit), SUM(l.quantity)
    INTO v_current_cost, v_current_qty
    FROM public.tx_legs l
      JOIN public.tx_entries e ON l.tx_id = e.id
    WHERE l.asset_id = r.stock_id AND e.user_id = v_user_id;

    v_cost_change := r.quantity * v_current_cost / v_current_qty;
    v_realized_pnl := r.net_proceed - v_cost_change;

    -- Debit cash
    insert into public.tx_legs (tx_id, asset_id, quantity, debit, credit)
    values (r.tx_id, v_cash_asset, r.net_proceed, r.net_proceed, 0);

    -- Credit stock (reduce holdings)
    insert into public.tx_legs (tx_id, asset_id, quantity, debit, credit)
    values (r.tx_id, r.stock_id, -r.quantity, 0, v_cost_change);

    -- Post gain/loss to equity
    insert into public.tx_legs (tx_id, asset_id, quantity, debit, credit)
    values (
      r.tx_id,
      v_equity_asset,
      v_realized_pnl,
      GREATEST(-v_realized_pnl, 0),
      GREATEST(v_realized_pnl, 0)
    );
  end if;
end;$$;


ALTER FUNCTION "public"."process_tx_stock"("p_tx_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."rebuild_ledger"() RETURNS "void"
    LANGUAGE "plpgsql"
    SET "search_path" TO 'public'
    AS $$declare
    tx record;
begin
    raise notice 'Rebuilding ledger (positions + legs)...';

    -- Step 1: clear all derived data
    truncate table public.tx_legs cascade;

    -- Step 2: replay all transactions in chronological order
    for tx in
        select id, category, created_at
        from public.tx_entries
        order by created_at asc
    loop
        case tx.category
            when 'stock'::tx_category then
                perform public.process_tx_stock(tx.id);

            when 'cashflow'::tx_category then
                perform public.process_tx_cashflow(tx.id);

            when 'borrow'::tx_category then
                perform public.process_tx_borrow(tx.id);

            when 'repay'::tx_category then
                perform public.process_tx_repay(tx.id);

            else
                raise exception 'Unhandled tx category: %', tx.category;
        end case;
    end loop;

    raise notice 'Ledger rebuild completed.';
end;$$;


ALTER FUNCTION "public"."rebuild_ledger"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."recompute_daily_snapshots"("p_user_id" "uuid" DEFAULT NULL::"uuid", "p_from_date" "date" DEFAULT NULL::"date") RETURNS "void"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
declare
    v_from date := coalesce(p_from_date, '-infinity'::date);
begin
    -- Remove the slice we are about to rebuild (rows before v_from are the
    -- cumulative seed and are left untouched).
    delete from public.daily_snapshots
    where snapshot_date >= v_from
      and (p_user_id is null or user_id = p_user_id);

    insert into public.daily_snapshots (
        snapshot_date, user_id, total_equity, intraday_cashflow,
        intraday_fee, intraday_tax, intraday_interest,
        total_cashflow, intraday_pnl, intraday_return
    )
    with users as (
        select tx_entries.user_id,
               (min(tx_entries.created_at))::date as start_date
        from public.tx_entries
        where tx_entries.user_id is not null
          and (p_user_id is null or tx_entries.user_id = p_user_id)
        group by tx_entries.user_id
    ),
    user_days as (
        select u.user_id,
               (gs.d)::date as snapshot_date
        from users u
        cross join lateral generate_series(
                 (greatest(u.start_date, v_from))::timestamptz,
                 (current_date)::timestamptz,
                 '1 day'::interval) gs(d)
        where extract(isodow from gs.d) <> all (array[6::numeric, 7::numeric])
    ),
    daily_deltas as (
        select e.user_id,
               (e.created_at)::date as activity_date,
               tl.asset_id,
               a.currency_code,
               sum(tl.quantity) as dq
        from public.tx_legs tl
        join public.tx_entries e on e.id = tl.tx_id
        join public.assets a     on a.id = tl.asset_id
        where a.asset_class <> all (array['equity'::public.asset_class,
                                          'liability'::public.asset_class])
          and (p_user_id is null or e.user_id = p_user_id)
        group by e.user_id, (e.created_at)::date, tl.asset_id, a.currency_code
    ),
    asset_intervals as (
        select dd.user_id,
               dd.asset_id,
               dd.currency_code,
               sum(dd.dq) over (partition by dd.user_id, dd.asset_id, dd.currency_code
                                order by dd.activity_date
                                rows between unbounded preceding and current row) as cum_qty,
               dd.activity_date as valid_from,
               coalesce(lead(dd.activity_date) over (partition by dd.user_id, dd.asset_id, dd.currency_code
                                                     order by dd.activity_date),
                        'infinity'::date) as valid_to
        from daily_deltas dd
    ),
    positions as (
        -- generate_series clipped to v_from forward: this is the main saving,
        -- the expensive per-day price/fx lookups run only for days >= v_from.
        select (gs.d)::date as snapshot_date,
               ai.user_id,
               ai.asset_id,
               ai.currency_code,
               ai.cum_qty as quantity
        from asset_intervals ai
        cross join lateral generate_series(
                 (greatest(ai.valid_from, v_from))::timestamp,
                 (least((ai.valid_to - 1), current_date))::timestamp,
                 '1 day'::interval) gs(d)
        where extract(isodow from gs.d) <> all (array[6::numeric, 7::numeric])
    ),
    total_assets_per_day as (
        select pos.user_id,
               pos.snapshot_date,
               coalesce(sum(pos.quantity * coalesce(pr.price, 1::numeric)
                                          * coalesce(fx.rate, 1::numeric)), 0::numeric) as total_assets
        from positions pos
        left join lateral (
            select (hp.close * 1000::numeric) as price
            from public.historical_prices hp
            where hp.asset_id = pos.asset_id and hp.date <= pos.snapshot_date
            order by hp.date desc
            limit 1) pr on true
        left join lateral (
            select hf.rate
            from public.historical_fxrate hf
            where hf.currency_code = pos.currency_code and hf.date <= pos.snapshot_date
            order by hf.date desc
            limit 1) fx on true
        group by pos.user_id, pos.snapshot_date
    ),
    debt_events as (
        select e_b.user_id,
               b_1.tx_id as borrow_tx_id,
               b_1.principal,
               b_1.rate,
               (e_b.created_at)::date as borrow_date,
               (e_r.created_at)::date as repay_date
        from public.tx_borrow b_1
        join public.tx_entries e_b on e_b.id = b_1.tx_id
        left join public.tx_repay r on r.borrow_tx = b_1.tx_id
        left join public.tx_entries e_r on e_r.id = r.tx_id
        where (p_user_id is null or e_b.user_id = p_user_id)
    ),
    debt_balances_by_day as (
        select d.snapshot_date,
               de.user_id,
               de.borrow_tx_id,
               de.principal,
               de.rate,
               de.borrow_date,
               de.repay_date,
               case
                 when de.repay_date is not null and de.repay_date <= d.snapshot_date then 0::numeric
                 else de.principal * power(1::numeric + (de.rate / 100.0) / 365.0,
                                           (greatest(d.snapshot_date - de.borrow_date, 0))::numeric)
               end as balance_at_date
        from debt_events de
        join user_days d on d.user_id = de.user_id
        where de.borrow_date <= d.snapshot_date
    ),
    total_liabilities_per_day as (
        select debt_balances_by_day.user_id,
               debt_balances_by_day.snapshot_date,
               coalesce(sum(debt_balances_by_day.balance_at_date), 0::numeric) as total_liabilities
        from debt_balances_by_day
        group by debt_balances_by_day.user_id, debt_balances_by_day.snapshot_date
    ),
    cashflow_per_day as (
        select e.user_id,
               (e.created_at)::date as snapshot_date,
               coalesce(sum(tl.credit) - sum(tl.debit), 0::numeric) as intraday_cashflow
        from public.tx_entries e
        join public.tx_legs tl     on tl.tx_id = e.id
        join public.assets a       on a.id = tl.asset_id
        join public.tx_cashflow cf on cf.tx_id = e.id
        where cf.operation = any (array['deposit'::public.cashflow_ops, 'withdraw'::public.cashflow_ops])
          and a.asset_class = 'equity'::public.asset_class
          and (p_user_id is null or e.user_id = p_user_id)
        group by e.user_id, (e.created_at)::date
    ),
    tax_fee_per_day as (
        select e.user_id,
               (e.created_at)::date as snapshot_date,
               (coalesce(sum(s.fee), 0::numeric)
                 + coalesce(sum(cf.net_proceed) filter (where e.memo = 'Operational fees'), 0::numeric)) as total_fees,
               coalesce(sum(s.tax), 0::numeric) as total_taxes,
               coalesce(sum(r.interest), 0::numeric) as loan_interest,
               coalesce(sum(cf.net_proceed) filter (where e.memo = any (array['Margin interest','Cash advance interest'])), 0::numeric) as margin_interest
        from public.tx_entries e
        left join public.tx_repay r    on r.tx_id = e.id
        left join public.tx_stock s    on s.tx_id = e.id
        left join public.tx_cashflow cf on cf.tx_id = e.id
        where (p_user_id is null or e.user_id = p_user_id)
        group by e.user_id, (e.created_at)::date
    ),
    base as (
        select d.snapshot_date,
               d.user_id,
               coalesce(nc.intraday_cashflow, 0::numeric) as intraday_cashflow,
               round(coalesce(tad.total_assets, 0::numeric) - coalesce(tld.total_liabilities, 0::numeric)) as total_equity,
               coalesce(tf.total_fees, 0::numeric) as intraday_fee,
               coalesce(tf.total_taxes, 0::numeric) as intraday_tax,
               coalesce(tf.loan_interest + tf.margin_interest, 0::numeric) as intraday_interest
        from user_days d
        left join total_assets_per_day      tad on tad.snapshot_date = d.snapshot_date and tad.user_id = d.user_id
        left join total_liabilities_per_day tld on tld.snapshot_date = d.snapshot_date and tld.user_id = d.user_id
        left join cashflow_per_day          nc  on nc.snapshot_date  = d.snapshot_date and nc.user_id  = d.user_id
        left join tax_fee_per_day           tf  on tf.snapshot_date  = d.snapshot_date and tf.user_id  = d.user_id
    ),
    seeds as (
        -- last stored row strictly before v_from = cumulative seed per user
        select distinct on (user_id)
               user_id,
               total_cashflow as seed_cashflow,
               total_equity   as seed_equity
        from public.daily_snapshots
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
        round(coalesce(s.seed_cashflow, 0::numeric)
              + sum(b.intraday_cashflow) over w_running) as total_cashflow,
        case
            when coalesce(lag(b.total_equity) over w_ord, s.seed_equity) is null then 0::numeric
            when coalesce(lag(b.total_equity) over w_ord, s.seed_equity) = 0::numeric then 0::numeric
            else (b.total_equity - b.intraday_cashflow) - coalesce(lag(b.total_equity) over w_ord, s.seed_equity)
        end as intraday_pnl,
        case
            when coalesce(lag(b.total_equity) over w_ord, s.seed_equity) is null then 0::numeric
            when coalesce(lag(b.total_equity) over w_ord, s.seed_equity) = 0::numeric then 0::numeric
            else ((b.total_equity - b.intraday_cashflow) - coalesce(lag(b.total_equity) over w_ord, s.seed_equity))
                 / nullif(coalesce(lag(b.total_equity) over w_ord, s.seed_equity), 0::numeric)
        end as intraday_return
    from base b
    left join seeds s on s.user_id = b.user_id
    window
        w_ord     as (partition by b.user_id order by b.snapshot_date),
        w_running as (partition by b.user_id order by b.snapshot_date
                      rows between unbounded preceding and current row);
end;
$$;


ALTER FUNCTION "public"."recompute_daily_snapshots"("p_user_id" "uuid", "p_from_date" "date") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."trg_process_tx_borrow"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    SET "search_path" TO 'public'
    AS $$
begin
  perform public.process_tx_borrow(new.tx_id);
  return new;
end;
$$;


ALTER FUNCTION "public"."trg_process_tx_borrow"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."trg_process_tx_cashflow"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    SET "search_path" TO 'public'
    AS $$begin
    perform public.process_tx_cashflow(new.tx_id);
    return new;
end;$$;


ALTER FUNCTION "public"."trg_process_tx_cashflow"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."trg_process_tx_repay"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    SET "search_path" TO 'public'
    AS $$
begin
  perform public.process_tx_repay(new.tx_id);
  return new;
end;
$$;


ALTER FUNCTION "public"."trg_process_tx_repay"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."trg_process_tx_stock"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    SET "search_path" TO 'public'
    AS $$begin
    perform public.process_tx_stock(new.tx_id);
    return new;
end;$$;


ALTER FUNCTION "public"."trg_process_tx_stock"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."trg_snapshots_fxrate"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
declare r record;
begin
    if tg_op = 'INSERT' then
        for r in
            select e.user_id, min(c.date) as d
            from (select currency_code, date from new_rows) c
            join public.assets a      on a.currency_code = c.currency_code
            join public.tx_legs tl    on tl.asset_id = a.id
            join public.tx_entries e  on e.id = tl.tx_id
            group by e.user_id
        loop
            perform public.recompute_daily_snapshots(r.user_id, r.d);
        end loop;
    else  -- UPDATE
        for r in
            with changed as (
                select currency_code, date from new_rows
                union
                select currency_code, date from old_rows
            )
            select e.user_id, min(c.date) as d
            from changed c
            join public.assets a      on a.currency_code = c.currency_code
            join public.tx_legs tl    on tl.asset_id = a.id
            join public.tx_entries e  on e.id = tl.tx_id
            group by e.user_id
        loop
            perform public.recompute_daily_snapshots(r.user_id, r.d);
        end loop;
    end if;
    return null;
end;
$$;


ALTER FUNCTION "public"."trg_snapshots_fxrate"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."trg_snapshots_prices"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
declare r record;
begin
    if tg_op = 'INSERT' then
        for r in
            select e.user_id, min(c.date) as d
            from (select asset_id, date from new_rows) c
            join public.tx_legs tl    on tl.asset_id = c.asset_id
            join public.tx_entries e  on e.id = tl.tx_id
            group by e.user_id
        loop
            perform public.recompute_daily_snapshots(r.user_id, r.d);
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
            join public.tx_legs tl    on tl.asset_id = c.asset_id
            join public.tx_entries e  on e.id = tl.tx_id
            group by e.user_id
        loop
            perform public.recompute_daily_snapshots(r.user_id, r.d);
        end loop;
    end if;
    return null;
end;
$$;


ALTER FUNCTION "public"."trg_snapshots_prices"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."trg_snapshots_tx_legs"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
declare r record;
begin
    for r in
        select e.user_id, min((e.created_at)::date) as d
        from new_rows nl
        join public.tx_entries e on e.id = nl.tx_id
        group by e.user_id
    loop
        perform public.recompute_daily_snapshots(r.user_id, r.d);
    end loop;
    return null;
end;
$$;


ALTER FUNCTION "public"."trg_snapshots_tx_legs"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."upsert_historical_prices"() RETURNS "trigger"
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


ALTER FUNCTION "public"."upsert_historical_prices"() OWNER TO "postgres";

SET default_tablespace = '';

SET default_table_access_method = "heap";


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
    "net_proceed" numeric GENERATED ALWAYS AS (("quantity" * "fx_rate")) STORED NOT NULL
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
    "a"."currency_id",
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
   FROM ((("dim"."asset" "a"
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
  GROUP BY "a"."ticker", "a"."name", "a"."logo_url", "a"."currency_id", "a"."asset_class", "sp"."price", "er"."rate"
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


CREATE TABLE IF NOT EXISTS "flight"."aircrafts" (
    "icao_code" "text" NOT NULL,
    "model" "text"
);


ALTER TABLE "flight"."aircrafts" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "flight"."airlines" (
    "name" "text" NOT NULL,
    "logo" "text",
    "icao_code" "text" NOT NULL
);


ALTER TABLE "flight"."airlines" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "flight"."airports" (
    "iata_code" "text" NOT NULL,
    "icao_code" "text",
    "name" "text" NOT NULL,
    "city" "text" NOT NULL,
    "country" "text" NOT NULL,
    "lat" double precision NOT NULL,
    "lng" double precision NOT NULL,
    "timezone" "text" NOT NULL,
    CONSTRAINT "timezone_format_check" CHECK (("timezone" ~ '^[A-Za-z_]+/[A-Za-z_]+$'::"text"))
);


ALTER TABLE "flight"."airports" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "flight"."flights" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "flight_number" "text",
    "departure_time" timestamp with time zone,
    "arrival_time" timestamp with time zone,
    "seat_number" "text",
    "notes" "text",
    "ticket_class" "flight"."ticket_class",
    "seat_position" "flight"."seat_position",
    "tail_number" "text",
    "user_id" "uuid",
    "airline_code" "text",
    "dept_airport_iata" "text",
    "arr_airport_iata" "text",
    "aircraft_type" "text"
);


ALTER TABLE "flight"."flights" OWNER TO "postgres";


COMMENT ON COLUMN "flight"."flights"."dept_airport_iata" IS 'IATA code of departure airport';



COMMENT ON COLUMN "flight"."flights"."arr_airport_iata" IS 'IATA code of arrival airport';



COMMENT ON COLUMN "flight"."flights"."aircraft_type" IS 'ICAO code of aircraft type';



CREATE OR REPLACE VIEW "flight"."routes_geojson" WITH ("security_invoker"='on') AS
 WITH "normalized" AS (
         SELECT LEAST("f"."dept_airport_iata", "f"."arr_airport_iata") AS "airport_a_code",
            GREATEST("f"."dept_airport_iata", "f"."arr_airport_iata") AS "airport_b_code",
            "f"."dept_airport_iata",
            "f"."arr_airport_iata",
            "f"."flight_number",
            "al"."name" AS "airline_name"
           FROM ("flight"."flights" "f"
             LEFT JOIN "flight"."airlines" "al" ON (("al"."icao_code" = "f"."airline_code")))
        ), "route_frequency_cte" AS (
         SELECT "normalized"."airport_a_code",
            "normalized"."airport_b_code",
            "count"(*) AS "route_frequency"
           FROM "normalized"
          GROUP BY "normalized"."airport_a_code", "normalized"."airport_b_code"
        ), "direction_airline_grouped" AS (
         SELECT "n"."airport_a_code",
            "n"."airport_b_code",
                CASE
                    WHEN ("n"."dept_airport_iata" = "n"."airport_a_code") THEN (("n"."airport_a_code" || ' → '::"text") || "n"."airport_b_code")
                    ELSE (("n"."airport_b_code" || ' → '::"text") || "n"."airport_a_code")
                END AS "direction_label",
            "n"."airline_name",
            "array_agg"(DISTINCT "n"."flight_number" ORDER BY "n"."flight_number") FILTER (WHERE ("n"."flight_number" IS NOT NULL)) AS "flight_numbers"
           FROM "normalized" "n"
          GROUP BY "n"."airport_a_code", "n"."airport_b_code",
                CASE
                    WHEN ("n"."dept_airport_iata" = "n"."airport_a_code") THEN (("n"."airport_a_code" || ' → '::"text") || "n"."airport_b_code")
                    ELSE (("n"."airport_b_code" || ' → '::"text") || "n"."airport_a_code")
                END, "n"."airline_name"
        ), "direction_grouped" AS (
         SELECT "direction_airline_grouped"."airport_a_code",
            "direction_airline_grouped"."airport_b_code",
            "direction_airline_grouped"."direction_label",
            "jsonb_object_agg"("direction_airline_grouped"."airline_name", "direction_airline_grouped"."flight_numbers") AS "airlines"
           FROM "direction_airline_grouped"
          WHERE ("direction_airline_grouped"."airline_name" IS NOT NULL)
          GROUP BY "direction_airline_grouped"."airport_a_code", "direction_airline_grouped"."airport_b_code", "direction_airline_grouped"."direction_label"
        ), "flights_json" AS (
         SELECT "direction_grouped"."airport_a_code",
            "direction_grouped"."airport_b_code",
            "jsonb_object_agg"("direction_grouped"."direction_label", "direction_grouped"."airlines") AS "flights_by_direction"
           FROM "direction_grouped"
          GROUP BY "direction_grouped"."airport_a_code", "direction_grouped"."airport_b_code"
        )
 SELECT "gen_random_uuid"() AS "id",
    "a"."iata_code" AS "airport_a_code",
    "b"."iata_code" AS "airport_b_code",
    "a"."name" AS "airport_a_name",
    "b"."name" AS "airport_b_name",
    "a"."city" AS "airport_a_city",
    "b"."city" AS "airport_b_city",
    "a"."country" AS "airport_a_country",
    "b"."country" AS "airport_b_country",
    "rf"."route_frequency",
    "fj"."flights_by_direction",
    "round"(("flight"."haversine_distance_km"("a"."lat", "a"."lng", "b"."lat", "b"."lng"))::numeric, 1) AS "distance_km",
    "jsonb_build_object"('type', 'LineString', 'coordinates', "jsonb_build_array"("jsonb_build_array"("a"."lng", "a"."lat"), "jsonb_build_array"("b"."lng", "b"."lat"))) AS "geometry"
   FROM ((("route_frequency_cte" "rf"
     JOIN "flights_json" "fj" ON ((("fj"."airport_a_code" = "rf"."airport_a_code") AND ("fj"."airport_b_code" = "rf"."airport_b_code"))))
     JOIN "flight"."airports" "a" ON (("a"."iata_code" = "rf"."airport_a_code")))
     JOIN "flight"."airports" "b" ON (("b"."iata_code" = "rf"."airport_b_code")));


ALTER VIEW "flight"."routes_geojson" OWNER TO "postgres";


CREATE OR REPLACE VIEW "flight"."flights_summary" WITH ("security_invoker"='on') AS
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
    "r"."distance_km",
    "concat"("floor"((EXTRACT(epoch FROM ("f"."arrival_time" - "f"."departure_time")) / (3600)::numeric)), 'h ', "floor"(((EXTRACT(epoch FROM ("f"."arrival_time" - "f"."departure_time")) % (3600)::numeric) / (60)::numeric)), 'm') AS "duration"
   FROM ((((("flight"."flights" "f"
     LEFT JOIN "flight"."airlines" "al" ON (("al"."icao_code" = "f"."airline_code")))
     LEFT JOIN "flight"."aircrafts" "ac" ON (("ac"."icao_code" = "f"."aircraft_type")))
     LEFT JOIN "flight"."airports" "dep" ON (("dep"."iata_code" = "f"."dept_airport_iata")))
     LEFT JOIN "flight"."airports" "arr" ON (("arr"."iata_code" = "f"."arr_airport_iata")))
     LEFT JOIN "flight"."routes_geojson" "r" ON ((("r"."airport_a_code" = LEAST("f"."dept_airport_iata", "f"."arr_airport_iata")) AND ("r"."airport_b_code" = GREATEST("f"."dept_airport_iata", "f"."arr_airport_iata")))))
  ORDER BY "f"."departure_time" DESC;


ALTER VIEW "flight"."flights_summary" OWNER TO "postgres";


CREATE OR REPLACE VIEW "flight"."lifetime_stats" WITH ("security_invoker"='on') AS
 WITH "visited_airports" AS (
         SELECT "flights"."user_id",
            "flights"."dept_airport_iata" AS "airport_code"
           FROM "flight"."flights"
        UNION
         SELECT "flights"."user_id",
            "flights"."arr_airport_iata"
           FROM "flight"."flights"
        )
 SELECT "f"."user_id",
    "f"."flights_count",
    "count"(DISTINCT "va"."airport_code") AS "airports_count",
    "count"(DISTINCT "a"."country") AS "country_count",
    "f"."type_count",
    "f"."total_distance",
    "f"."total_duration"
   FROM ((( SELECT "fs"."user_id",
            "count"(*) AS "flights_count",
            "count"(DISTINCT "fs"."aircraft_type") AS "type_count",
            "sum"("fs"."distance_km") AS "total_distance",
            "round"((EXTRACT(epoch FROM "sum"(("fs"."arrival_time" - "fs"."departure_time"))) / (3600)::numeric)) AS "total_duration"
           FROM "flight"."flights_summary" "fs"
          GROUP BY "fs"."user_id") "f"
     LEFT JOIN "visited_airports" "va" ON (("va"."user_id" = "f"."user_id")))
     LEFT JOIN "flight"."airports" "a" ON (("a"."iata_code" = "va"."airport_code")))
  GROUP BY "f"."user_id", "f"."flights_count", "f"."type_count", "f"."total_distance", "f"."total_duration";


ALTER VIEW "flight"."lifetime_stats" OWNER TO "postgres";


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
    "published_at" timestamp with time zone,
    "excerpt" "text",
    "related_stocks" "text"[] DEFAULT '{}'::"text"[]
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



CREATE TABLE IF NOT EXISTS "public"."assets" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "asset_class" "public"."asset_class" NOT NULL,
    "ticker" "text" NOT NULL,
    "name" "text" NOT NULL,
    "currency_code" "text" NOT NULL,
    "logo_url" "text"
);


ALTER TABLE "public"."assets" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."historical_fxrate" (
    "currency_code" "text" NOT NULL,
    "date" "date" NOT NULL,
    "rate" numeric(14,2) NOT NULL
);


ALTER TABLE "public"."historical_fxrate" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."historical_prices" (
    "asset_id" "uuid" NOT NULL,
    "date" "date" NOT NULL,
    "close" numeric NOT NULL
);


ALTER TABLE "public"."historical_prices" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."tx_borrow" (
    "tx_id" "uuid" NOT NULL,
    "lender" "text" NOT NULL,
    "principal" numeric NOT NULL,
    "rate" numeric NOT NULL
);


ALTER TABLE "public"."tx_borrow" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."tx_entries" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "category" "public"."tx_category" NOT NULL,
    "memo" "text" NOT NULL,
    "user_id" "uuid" NOT NULL
);


ALTER TABLE "public"."tx_entries" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."tx_repay" (
    "tx_id" "uuid" NOT NULL,
    "borrow_tx" "uuid" NOT NULL,
    "principal" numeric NOT NULL,
    "interest" numeric NOT NULL,
    "net_proceed" numeric GENERATED ALWAYS AS (("principal" + "interest")) STORED NOT NULL
);


ALTER TABLE "public"."tx_repay" OWNER TO "postgres";


CREATE OR REPLACE VIEW "public"."outstanding_debts" WITH ("security_invoker"='true') AS
 SELECT "b"."tx_id",
    "b"."lender",
    "b"."principal",
    "b"."rate",
    "round"((("b"."principal" * "power"(((1)::numeric + (("b"."rate" / 100.0) / 365.0)), EXTRACT(day FROM ((CURRENT_DATE)::timestamp with time zone - "e"."created_at")))) - "b"."principal"), 0) AS "accrued_interest",
    "e"."created_at"
   FROM ("public"."tx_borrow" "b"
     JOIN "public"."tx_entries" "e" ON ((("e"."id" = "b"."tx_id") AND ("e"."user_id" = "auth"."uid"()))))
  WHERE (NOT (EXISTS ( SELECT 1
           FROM "public"."tx_repay" "r"
          WHERE ("r"."borrow_tx" = "b"."tx_id"))));


ALTER VIEW "public"."outstanding_debts" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."tx_legs" (
    "tx_id" "uuid" NOT NULL,
    "asset_id" "uuid" NOT NULL,
    "quantity" numeric(18,2) NOT NULL,
    "debit" numeric(16,0) NOT NULL,
    "credit" numeric(16,0) NOT NULL
);


ALTER TABLE "public"."tx_legs" OWNER TO "postgres";


CREATE OR REPLACE VIEW "public"."balance_sheet" WITH ("security_invoker"='true') AS
 WITH "user_legs" AS (
         SELECT "tl"."tx_id",
            "tl"."asset_id",
            "tl"."quantity",
            "tl"."debit",
            "tl"."credit"
           FROM ("public"."tx_legs" "tl"
             JOIN "public"."tx_entries" "e" ON (("e"."id" = "tl"."tx_id")))
          WHERE ("e"."user_id" = "auth"."uid"())
        ), "debt_interest" AS (
         SELECT "sum"("outstanding_debts"."accrued_interest") AS "sum"
           FROM "public"."outstanding_debts"
        )
 SELECT "a"."ticker",
    "a"."name",
    "a"."asset_class",
    "a"."logo_url",
    "a"."currency_code",
    COALESCE("sum"("ul"."quantity"), (0)::numeric) AS "quantity",
    COALESCE(("sum"("ul"."debit") - "sum"("ul"."credit")), (0)::numeric) AS "cost_basis",
        CASE
            WHEN ("a"."asset_class" = ANY (ARRAY['stock'::"public"."asset_class", 'fund'::"public"."asset_class"])) THEN "round"("sum"(("ul"."quantity" * COALESCE("sp"."price", "er"."rate"))), 0)
            WHEN ("a"."ticker" = 'INTERESTS'::"text") THEN ( SELECT "sum"("outstanding_debts"."accrued_interest") AS "sum"
               FROM "public"."outstanding_debts")
            ELSE "sum"("ul"."quantity")
        END AS "total_value",
    COALESCE(COALESCE("sp"."price", "er"."rate"), (0)::numeric) AS "mkt_price",
    COALESCE(
        CASE
            WHEN ("a"."ticker" = 'INTERESTS'::"text") THEN (- ( SELECT "sum"("outstanding_debts"."accrued_interest") AS "sum"
               FROM "public"."outstanding_debts"))
            ELSE "round"(("sum"(("ul"."quantity" * COALESCE("sp"."price", "er"."rate"))) - ("sum"("ul"."debit") - "sum"("ul"."credit"))), 0)
        END, (0)::numeric) AS "net_profit"
   FROM ((("public"."assets" "a"
     LEFT JOIN "user_legs" "ul" ON (("a"."id" = "ul"."asset_id")))
     LEFT JOIN LATERAL ( SELECT ("hp"."close" * (1000)::numeric) AS "price"
           FROM "public"."historical_prices" "hp"
          WHERE ("hp"."asset_id" = "a"."id")
          ORDER BY "hp"."date" DESC
         LIMIT 1) "sp" ON (true))
     LEFT JOIN LATERAL ( SELECT "hfx"."rate"
           FROM "public"."historical_fxrate" "hfx"
          WHERE ("hfx"."currency_code" = "a"."currency_code")
          ORDER BY "hfx"."date" DESC
         LIMIT 1) "er" ON (true))
  GROUP BY "a"."ticker", "a"."name", "a"."logo_url", "a"."currency_code", "a"."asset_class", "sp"."price", "er"."rate"
 HAVING (("abs"("sum"("ul"."quantity")) > (0)::numeric) OR ("a"."ticker" = 'INTERESTS'::"text"))
  ORDER BY "a"."asset_class";


ALTER VIEW "public"."balance_sheet" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."daily_snapshots" (
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


ALTER TABLE "public"."daily_snapshots" OWNER TO "postgres";


CREATE OR REPLACE VIEW "public"."benchmark_all" WITH ("security_invoker"='true') AS
 WITH "vnindex" AS (
         SELECT "assets"."id"
           FROM "public"."assets"
          WHERE ("assets"."ticker" = 'VNINDEX'::"text")
        ), "date_bound" AS (
         SELECT "min"("daily_snapshots"."snapshot_date") AS "first_date",
            "max"("daily_snapshots"."snapshot_date") AS "last_date"
           FROM "public"."daily_snapshots"
        )
 SELECT "public"."get_return_chart"("db"."first_date", "db"."last_date") AS "return_chart",
    "round"("public"."calculate_twr"("db"."first_date", "db"."last_date"), 3) AS "equity_ret",
    "round"((("hp_last"."close" / "hp_first"."close") - (1)::numeric), 3) AS "vn_ret"
   FROM ((("date_bound" "db"
     CROSS JOIN "vnindex" "v")
     LEFT JOIN LATERAL ( SELECT "hp"."date",
            "hp"."close"
           FROM "public"."historical_prices" "hp"
          WHERE ("hp"."asset_id" = "v"."id")
          ORDER BY ("hp"."date" < "db"."first_date") DESC,
                CASE
                    WHEN ("hp"."date" < "db"."first_date") THEN "hp"."date"
                    ELSE NULL::"date"
                END DESC, "hp"."date"
         LIMIT 1) "hp_first" ON (true))
     LEFT JOIN LATERAL ( SELECT "hp"."date",
            "hp"."close"
           FROM "public"."historical_prices" "hp"
          WHERE (("hp"."asset_id" = "v"."id") AND ("hp"."date" = "db"."last_date"))
         LIMIT 1) "hp_last" ON (true));


ALTER VIEW "public"."benchmark_all" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."user_settings" (
    "user_id" "uuid" NOT NULL,
    "dnse_account_id" "text",
    "inception_date" "date" DEFAULT '2020-01-01'::"date" NOT NULL,
    "display_name" "text",
    "avatar" "text"
);


ALTER TABLE "public"."user_settings" OWNER TO "postgres";


CREATE OR REPLACE VIEW "public"."benchmark_rollings" WITH ("security_invoker"='true') AS
 WITH "periods" AS (
         SELECT CURRENT_DATE AS "today",
            ("date_trunc"('year'::"text", (CURRENT_DATE)::timestamp with time zone))::"date" AS "ytd_date",
            ("date_trunc"('month'::"text", (CURRENT_DATE)::timestamp with time zone))::"date" AS "mtd_date",
            ( SELECT "us"."inception_date"
                   FROM "public"."user_settings" "us"
                  WHERE ("us"."user_id" = "auth"."uid"())) AS "inception_date",
            ((CURRENT_DATE - '3 mons'::interval))::"date" AS "last3m_date",
            ((CURRENT_DATE - '6 mons'::interval))::"date" AS "last6m_date",
            ((CURRENT_DATE - '1 year'::interval))::"date" AS "last1y_date"
        ), "metrics" AS (
         SELECT "round"("public"."calculate_twr"("periods"."ytd_date", "periods"."today"), 3) AS "twr_ytd",
            "round"("public"."calculate_twr"("periods"."inception_date", "periods"."today"), 3) AS "twr_all",
            "periods"."today",
            "periods"."inception_date"
           FROM "periods"
        )
 SELECT "m"."twr_ytd",
    "m"."twr_all",
        CASE
            WHEN (("m"."today" > "m"."inception_date") AND ("m"."inception_date" IS NOT NULL)) THEN "round"(("power"(((1)::numeric + "m"."twr_all"), (1.0 / ((("m"."today" - "m"."inception_date"))::numeric / 365.25))) - (1)::numeric), 3)
            ELSE NULL::numeric
        END AS "cagr",
    "rc"."returnchart"
   FROM ("metrics" "m"
     CROSS JOIN LATERAL ( SELECT "jsonb_build_object"('last_3m', "public"."get_return_chart"("p"."last3m_date", "p"."today"), 'last_6m', "public"."get_return_chart"("p"."last6m_date", "p"."today"), 'last_1y', "public"."get_return_chart"("p"."last1y_date", "p"."today"), 'all', "public"."get_return_chart"("p"."inception_date", "p"."today")) AS "returnchart"
           FROM "periods" "p") "rc");


ALTER VIEW "public"."benchmark_rollings" OWNER TO "postgres";


CREATE OR REPLACE VIEW "public"."benchmark_yearly" WITH ("security_invoker"='true') AS
 WITH "vnindex" AS (
         SELECT "assets"."id"
           FROM "public"."assets"
          WHERE ("assets"."ticker" = 'VNINDEX'::"text")
        ), "date_bound" AS (
         SELECT "ds"."year",
            "min"("ds"."snapshot_date") AS "first_date",
            "max"("ds"."snapshot_date") AS "last_date"
           FROM ( SELECT "daily_snapshots"."snapshot_date",
                    EXTRACT(year FROM "daily_snapshots"."snapshot_date") AS "year"
                   FROM "public"."daily_snapshots") "ds"
          GROUP BY "ds"."year"
        )
 SELECT "db"."year",
    "public"."get_return_chart"("db"."first_date", "db"."last_date") AS "return_chart",
    "round"("public"."calculate_twr"("db"."first_date", "db"."last_date"), 3) AS "equity_ret",
    "round"((("hp_last"."close" / "hp_first"."close") - (1)::numeric), 3) AS "vn_ret"
   FROM ((("date_bound" "db"
     CROSS JOIN "vnindex" "v")
     LEFT JOIN LATERAL ( SELECT "hp"."date",
            "hp"."close"
           FROM "public"."historical_prices" "hp"
          WHERE ("hp"."asset_id" = "v"."id")
          ORDER BY ("hp"."date" < "db"."first_date") DESC,
                CASE
                    WHEN ("hp"."date" < "db"."first_date") THEN "hp"."date"
                    ELSE NULL::"date"
                END DESC, "hp"."date"
         LIMIT 1) "hp_first" ON (true))
     LEFT JOIN LATERAL ( SELECT "hp"."date",
            "hp"."close"
           FROM "public"."historical_prices" "hp"
          WHERE (("hp"."asset_id" = "v"."id") AND ("hp"."date" = "db"."last_date"))
         LIMIT 1) "hp_last" ON (true))
  ORDER BY "db"."year";


ALTER VIEW "public"."benchmark_yearly" OWNER TO "postgres";


CREATE OR REPLACE VIEW "public"."cashflow_all" WITH ("security_invoker"='true') AS
 SELECT "sum"(GREATEST("intraday_cashflow", (0)::numeric)) AS "deposits",
    "sum"(LEAST("intraday_cashflow", (0)::numeric)) AS "withdrawals"
   FROM "public"."daily_snapshots"
  WHERE ("user_id" = "auth"."uid"());


ALTER VIEW "public"."cashflow_all" OWNER TO "postgres";


CREATE OR REPLACE VIEW "public"."cashflow_yearly" WITH ("security_invoker"='true') AS
 SELECT EXTRACT(year FROM "snapshot_date") AS "year",
    "sum"(GREATEST("intraday_cashflow", (0)::numeric)) AS "deposits",
    "sum"(LEAST("intraday_cashflow", (0)::numeric)) AS "withdrawals"
   FROM "public"."daily_snapshots"
  WHERE ("user_id" = "auth"."uid"())
  GROUP BY (EXTRACT(year FROM "snapshot_date"))
  ORDER BY (EXTRACT(year FROM "snapshot_date"));


ALTER VIEW "public"."cashflow_yearly" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."currencies" (
    "code" "text" NOT NULL,
    "name" "text" NOT NULL
);


ALTER TABLE "public"."currencies" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."dnse_m1_close" (
    "symbol" "text" NOT NULL,
    "close" numeric NOT NULL,
    "volume" bigint NOT NULL,
    "last_updated" timestamp with time zone NOT NULL,
    "received_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."dnse_m1_close" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."dnse_order_events" (
    "id" integer NOT NULL,
    "side" "public"."stock_ops" NOT NULL,
    "account_no" "text" NOT NULL,
    "symbol" "text" NOT NULL,
    "order_type" "text" NOT NULL,
    "price" numeric NOT NULL,
    "quantity" integer NOT NULL,
    "fill_quantity" integer DEFAULT 0 NOT NULL,
    "canceled_quantity" integer DEFAULT 0 NOT NULL,
    "leave_quantity" integer DEFAULT 0 NOT NULL,
    "order_status" "public"."dnse_order_status" NOT NULL,
    "loan_package_id" integer,
    "modified_date" timestamp with time zone NOT NULL,
    "received_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "avg_price" numeric,
    "tax" numeric,
    "fee" numeric
);


ALTER TABLE "public"."dnse_order_events" OWNER TO "postgres";


CREATE OR REPLACE VIEW "public"."equity_rollings" WITH ("security_invoker"='true') AS
 WITH "periods" AS (
         SELECT CURRENT_DATE AS "today",
            ("date_trunc"('year'::"text", (CURRENT_DATE)::timestamp with time zone))::"date" AS "ytd_date",
            ("date_trunc"('month'::"text", (CURRENT_DATE)::timestamp with time zone))::"date" AS "mtd_date",
            ( SELECT "us"."inception_date"
                   FROM "public"."user_settings" "us"
                  WHERE ("us"."user_id" = "auth"."uid"())) AS "inception_date",
            ((CURRENT_DATE - '3 mons'::interval))::"date" AS "last3m_date",
            ((CURRENT_DATE - '6 mons'::interval))::"date" AS "last6m_date",
            ((CURRENT_DATE - '1 year'::interval))::"date" AS "last1y_date"
        ), "metrics" AS (
         SELECT "public"."calculate_pnl"("periods"."ytd_date", "periods"."today") AS "pnl_ytd",
            "public"."calculate_pnl"("periods"."mtd_date", "periods"."today") AS "pnl_mtd",
            "periods"."today",
            "periods"."inception_date"
           FROM "periods"
        )
 SELECT "m"."pnl_ytd",
    "m"."pnl_mtd",
    "b"."total_equity",
    "ec"."equitychart"
   FROM (("metrics" "m"
     CROSS JOIN LATERAL ( SELECT "daily_snapshots"."total_equity"
           FROM "public"."daily_snapshots"
          WHERE ("daily_snapshots"."user_id" = "auth"."uid"())
          ORDER BY "daily_snapshots"."snapshot_date" DESC
         LIMIT 1) "b")
     CROSS JOIN LATERAL ( SELECT "jsonb_build_object"('last_3m', "public"."get_equity_chart"("p"."last3m_date", "p"."today"), 'last_6m', "public"."get_equity_chart"("p"."last6m_date", "p"."today"), 'last_1y', "public"."get_equity_chart"("p"."last1y_date", "p"."today"), 'all', "public"."get_equity_chart"("p"."inception_date", "p"."today")) AS "equitychart"
           FROM "periods" "p") "ec");


ALTER VIEW "public"."equity_rollings" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."news_articles" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "title" "text" NOT NULL,
    "url" "text" NOT NULL,
    "source" "text" NOT NULL,
    "published_at" timestamp with time zone,
    "excerpt" "text",
    "related_stocks" "text"[] DEFAULT '{}'::"text"[]
);


ALTER TABLE "public"."news_articles" OWNER TO "postgres";


CREATE OR REPLACE VIEW "public"."pnl_expense_all" WITH ("security_invoker"='true') AS
 SELECT "round"("sum"("pnl")) AS "total_pnl",
    "round"("avg"("pnl")) AS "avg_profit",
    (- "round"("avg"(((COALESCE("interest", (0)::numeric) + COALESCE("tax", (0)::numeric)) + COALESCE("fee", (0)::numeric))))) AS "avg_expense",
    "jsonb_build_object"('snapshot_date', "jsonb_agg"(("snapshot_date")::"text" ORDER BY "snapshot_date"), 'revenue', "jsonb_agg"((((COALESCE("pnl", (0)::numeric) + COALESCE("fee", (0)::numeric)) + COALESCE("interest", (0)::numeric)) + COALESCE("tax", (0)::numeric)) ORDER BY "snapshot_date"), 'fee', "jsonb_agg"(COALESCE((- "fee"), (0)::numeric) ORDER BY "snapshot_date"), 'interest', "jsonb_agg"(COALESCE((- "interest"), (0)::numeric) ORDER BY "snapshot_date"), 'tax', "jsonb_agg"(COALESCE((- "tax"), (0)::numeric) ORDER BY "snapshot_date")) AS "profit_chart"
   FROM ( SELECT ("date_trunc"('year'::"text", ("ds"."snapshot_date")::timestamp with time zone))::"date" AS "snapshot_date",
            "sum"("ds"."intraday_pnl") AS "pnl",
            "sum"("ds"."intraday_interest") AS "interest",
            "sum"("ds"."intraday_tax") AS "tax",
            "sum"("ds"."intraday_fee") AS "fee"
           FROM "public"."daily_snapshots" "ds"
          WHERE ("ds"."user_id" = "auth"."uid"())
          GROUP BY (("date_trunc"('year'::"text", ("ds"."snapshot_date")::timestamp with time zone))::"date")) "yearly";


ALTER VIEW "public"."pnl_expense_all" OWNER TO "postgres";


CREATE OR REPLACE VIEW "public"."pnl_expense_last1y" WITH ("security_invoker"='true') AS
 SELECT "round"("sum"("pnl")) AS "total_pnl",
    "round"("avg"("pnl")) AS "avg_profit",
    (- "round"("avg"(((COALESCE("interest", (0)::numeric) + COALESCE("tax", (0)::numeric)) + COALESCE("fee", (0)::numeric))))) AS "avg_expense",
    "jsonb_build_object"('snapshot_date', "jsonb_agg"(("snapshot_date")::"text" ORDER BY "snapshot_date"), 'revenue', "jsonb_agg"((((COALESCE("pnl", (0)::numeric) + COALESCE("fee", (0)::numeric)) + COALESCE("interest", (0)::numeric)) + COALESCE("tax", (0)::numeric)) ORDER BY "snapshot_date"), 'fee', "jsonb_agg"(COALESCE((- "fee"), (0)::numeric) ORDER BY "snapshot_date"), 'interest', "jsonb_agg"(COALESCE((- "interest"), (0)::numeric) ORDER BY "snapshot_date"), 'tax', "jsonb_agg"(COALESCE((- "tax"), (0)::numeric) ORDER BY "snapshot_date")) AS "profit_chart"
   FROM ( SELECT ("date_trunc"('month'::"text", ("ds"."snapshot_date")::timestamp with time zone))::"date" AS "snapshot_date",
            "sum"("ds"."intraday_pnl") AS "pnl",
            "sum"("ds"."intraday_interest") AS "interest",
            "sum"("ds"."intraday_tax") AS "tax",
            "sum"("ds"."intraday_fee") AS "fee"
           FROM "public"."daily_snapshots" "ds"
          WHERE ("ds"."user_id" = "auth"."uid"())
          GROUP BY (("date_trunc"('month'::"text", ("ds"."snapshot_date")::timestamp with time zone))::"date")
          ORDER BY (("date_trunc"('month'::"text", ("ds"."snapshot_date")::timestamp with time zone))::"date") DESC
         LIMIT 12) "ms";


ALTER VIEW "public"."pnl_expense_last1y" OWNER TO "postgres";


CREATE OR REPLACE VIEW "public"."pnl_expense_yearly" WITH ("security_invoker"='true') AS
 SELECT (EXTRACT(year FROM "snapshot_date"))::integer AS "year",
    "round"("sum"("pnl")) AS "total_pnl",
    "round"("avg"("pnl")) AS "avg_profit",
    (- "round"("avg"(((COALESCE("interest", (0)::numeric) + COALESCE("tax", (0)::numeric)) + COALESCE("fee", (0)::numeric))))) AS "avg_expense",
    "jsonb_build_object"('snapshot_date', "jsonb_agg"(("snapshot_date")::"text" ORDER BY "snapshot_date"), 'revenue', "jsonb_agg"((((COALESCE("pnl", (0)::numeric) + COALESCE("fee", (0)::numeric)) + COALESCE("interest", (0)::numeric)) + COALESCE("tax", (0)::numeric)) ORDER BY "snapshot_date"), 'fee', "jsonb_agg"(COALESCE((- "fee"), (0)::numeric) ORDER BY "snapshot_date"), 'interest', "jsonb_agg"(COALESCE((- "interest"), (0)::numeric) ORDER BY "snapshot_date"), 'tax', "jsonb_agg"(COALESCE((- "tax"), (0)::numeric) ORDER BY "snapshot_date")) AS "profit_chart"
   FROM ( SELECT ("date_trunc"('month'::"text", ("ds"."snapshot_date")::timestamp with time zone))::"date" AS "snapshot_date",
            "ds"."user_id",
            "sum"("ds"."intraday_pnl") AS "pnl",
            "sum"("ds"."intraday_interest") AS "interest",
            "sum"("ds"."intraday_tax") AS "tax",
            "sum"("ds"."intraday_fee") AS "fee"
           FROM "public"."daily_snapshots" "ds"
          GROUP BY (("date_trunc"('month'::"text", ("ds"."snapshot_date")::timestamp with time zone))::"date"), "ds"."user_id") "monthly"
  WHERE ("user_id" = "auth"."uid"())
  GROUP BY ((EXTRACT(year FROM "snapshot_date"))::integer);


ALTER VIEW "public"."pnl_expense_yearly" OWNER TO "postgres";


CREATE OR REPLACE VIEW "public"."stock_pnl_yearly" WITH ("security_invoker"='true') AS
 WITH "capital_legs" AS (
         SELECT "tl"."tx_id",
            ("tl"."credit" - "tl"."debit") AS "realized_pnl",
            "t"."created_at"
           FROM (("public"."tx_legs" "tl"
             JOIN "public"."tx_entries" "t" ON (("t"."id" = "tl"."tx_id")))
             JOIN "public"."assets" "a_1" ON (("tl"."asset_id" = "a_1"."id")))
          WHERE (("a_1"."ticker" = 'CAPITAL'::"text") AND ("t"."user_id" = "auth"."uid"()))
        ), "stock_legs" AS (
         SELECT "tl"."tx_id",
            "tl"."asset_id" AS "stock_id"
           FROM (("public"."tx_legs" "tl"
             JOIN "public"."tx_entries" "e" ON (("e"."id" = "tl"."tx_id")))
             JOIN "public"."assets" "a_1" ON (("a_1"."id" = "tl"."asset_id")))
          WHERE (("a_1"."asset_class" = 'stock'::"public"."asset_class") AND ("e"."user_id" = "auth"."uid"()))
        )
 SELECT (EXTRACT(year FROM "c"."created_at"))::integer AS "year",
    "a"."ticker",
    "a"."name",
    "a"."logo_url",
    "sum"("c"."realized_pnl") AS "total_pnl"
   FROM (("capital_legs" "c"
     JOIN "stock_legs" "s" ON (("s"."tx_id" = "c"."tx_id")))
     JOIN "public"."assets" "a" ON (("a"."id" = "s"."stock_id")))
  GROUP BY "a"."logo_url", "a"."name", "a"."ticker", (EXTRACT(year FROM "c"."created_at"));


ALTER VIEW "public"."stock_pnl_yearly" OWNER TO "postgres";


CREATE OR REPLACE VIEW "public"."stock_pnl_all" WITH ("security_invoker"='true') AS
 SELECT "ticker",
    "name",
    "logo_url",
    "sum"("total_pnl") AS "total_pnl"
   FROM "public"."stock_pnl_yearly" "s"
  GROUP BY "ticker", "name", "logo_url"
  ORDER BY ("sum"("total_pnl")) DESC;


ALTER VIEW "public"."stock_pnl_all" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."tx_cashflow" (
    "tx_id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "asset_id" "uuid" NOT NULL,
    "operation" "public"."cashflow_ops" NOT NULL,
    "quantity" numeric(18,2) NOT NULL,
    "fx_rate" numeric DEFAULT 1 NOT NULL,
    "net_proceed" numeric(16,0) GENERATED ALWAYS AS (("quantity" * "fx_rate")) STORED NOT NULL
);


ALTER TABLE "public"."tx_cashflow" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."tx_stock" (
    "tx_id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "stock_id" "uuid" NOT NULL,
    "price" numeric(16,0) DEFAULT 0 NOT NULL,
    "quantity" numeric(16,0) NOT NULL,
    "fee" numeric(16,0) NOT NULL,
    "tax" numeric(16,0) DEFAULT 0 NOT NULL,
    "operation" "public"."stock_ops" NOT NULL,
    "net_proceed" numeric GENERATED ALWAYS AS (
CASE
    WHEN ("operation" = 'buy'::"public"."stock_ops") THEN ((("price" * "quantity") + "fee") + "tax")
    WHEN ("operation" = 'sell'::"public"."stock_ops") THEN ((("price" * "quantity") - "fee") - "tax")
    ELSE (0)::numeric
END) STORED NOT NULL
);


ALTER TABLE "public"."tx_stock" OWNER TO "postgres";


CREATE OR REPLACE VIEW "public"."tx_summary" WITH ("security_invoker"='true') AS
 SELECT "t"."id",
    "t"."created_at",
    "t"."category",
        CASE
            WHEN ("t"."category" = 'stock'::"public"."tx_category") THEN ("s"."operation")::"text"
            WHEN ("t"."category" = 'cashflow'::"public"."tx_category") THEN ("cf"."operation")::"text"
            ELSE ("t"."category")::"text"
        END AS "operation",
        CASE
            WHEN ("t"."category" = 'stock'::"public"."tx_category") THEN "s"."net_proceed"
            WHEN ("t"."category" = 'cashflow'::"public"."tx_category") THEN "cf"."net_proceed"
            WHEN ("t"."category" = 'borrow'::"public"."tx_category") THEN "b"."principal"
            ELSE "r"."net_proceed"
        END AS "value",
    "t"."memo"
   FROM (((("public"."tx_entries" "t"
     LEFT JOIN "public"."tx_stock" "s" ON (("t"."id" = "s"."tx_id")))
     LEFT JOIN "public"."tx_cashflow" "cf" ON (("t"."id" = "cf"."tx_id")))
     LEFT JOIN "public"."tx_borrow" "b" ON (("t"."id" = "b"."tx_id")))
     LEFT JOIN "public"."tx_repay" "r" ON (("t"."id" = "r"."tx_id")))
  WHERE ("t"."user_id" = "auth"."uid"());


ALTER VIEW "public"."tx_summary" OWNER TO "postgres";


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



ALTER TABLE ONLY "flight"."aircrafts"
    ADD CONSTRAINT "aircrafts_icao_code_key" UNIQUE ("icao_code");



ALTER TABLE ONLY "flight"."aircrafts"
    ADD CONSTRAINT "aircrafts_pkey" PRIMARY KEY ("icao_code");



ALTER TABLE ONLY "flight"."airlines"
    ADD CONSTRAINT "airlines_icao_code_key" UNIQUE ("icao_code");



ALTER TABLE ONLY "flight"."airlines"
    ADD CONSTRAINT "airlines_name_key" UNIQUE ("name");



ALTER TABLE ONLY "flight"."airlines"
    ADD CONSTRAINT "airlines_pkey" PRIMARY KEY ("icao_code");



ALTER TABLE ONLY "flight"."airports"
    ADD CONSTRAINT "airports_iata_code_key" UNIQUE ("iata_code");



ALTER TABLE ONLY "flight"."airports"
    ADD CONSTRAINT "airports_pkey" PRIMARY KEY ("iata_code");



ALTER TABLE ONLY "flight"."flights"
    ADD CONSTRAINT "flights_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "ods"."dnse_m1_close"
    ADD CONSTRAINT "dnse_m1_close_pkey" PRIMARY KEY ("symbol", "last_updated");



ALTER TABLE ONLY "ods"."dnse_order_events"
    ADD CONSTRAINT "dnse_order_events_pkey" PRIMARY KEY ("received_at");



ALTER TABLE ONLY "ods"."news_articles"
    ADD CONSTRAINT "news_articles_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "ods"."news_articles"
    ADD CONSTRAINT "news_articles_url_key" UNIQUE ("url");



ALTER TABLE ONLY "public"."assets"
    ADD CONSTRAINT "assets_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."assets"
    ADD CONSTRAINT "assets_ticker_key" UNIQUE ("ticker");



ALTER TABLE ONLY "public"."currencies"
    ADD CONSTRAINT "currencies_pkey" PRIMARY KEY ("code");



ALTER TABLE ONLY "public"."historical_prices"
    ADD CONSTRAINT "daily_security_prices_pkey" PRIMARY KEY ("asset_id", "date") INCLUDE ("close");



ALTER TABLE ONLY "public"."daily_snapshots"
    ADD CONSTRAINT "daily_snapshots_pkey" PRIMARY KEY ("user_id", "snapshot_date");



ALTER TABLE ONLY "public"."dnse_order_events"
    ADD CONSTRAINT "dnse_order_events_pkey" PRIMARY KEY ("received_at");



ALTER TABLE ONLY "public"."historical_fxrate"
    ADD CONSTRAINT "exchange_rates_pkey" PRIMARY KEY ("currency_code", "date") INCLUDE ("rate");



ALTER TABLE ONLY "public"."dnse_m1_close"
    ADD CONSTRAINT "m1_intraday_close_pkey" PRIMARY KEY ("symbol", "last_updated");



ALTER TABLE ONLY "public"."news_articles"
    ADD CONSTRAINT "news_articles_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."news_articles"
    ADD CONSTRAINT "news_articles_url_key" UNIQUE ("url");



ALTER TABLE ONLY "public"."tx_borrow"
    ADD CONSTRAINT "tx_borrow_pkey" PRIMARY KEY ("tx_id");



ALTER TABLE ONLY "public"."tx_cashflow"
    ADD CONSTRAINT "tx_cashflow_pkey" PRIMARY KEY ("tx_id");



ALTER TABLE ONLY "public"."tx_entries"
    ADD CONSTRAINT "tx_entries_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."tx_legs"
    ADD CONSTRAINT "tx_legs_pkey" PRIMARY KEY ("tx_id", "asset_id");



ALTER TABLE ONLY "public"."tx_repay"
    ADD CONSTRAINT "tx_repay_pkey" PRIMARY KEY ("tx_id");



ALTER TABLE ONLY "public"."tx_stock"
    ADD CONSTRAINT "tx_stock_pkey" PRIMARY KEY ("tx_id");



ALTER TABLE ONLY "public"."user_settings"
    ADD CONSTRAINT "user_settings_dnse_account_id_key" UNIQUE ("dnse_account_id");



ALTER TABLE ONLY "public"."user_settings"
    ADD CONSTRAINT "user_settings_pkey" PRIMARY KEY ("user_id");



CREATE INDEX "idx_news_articles_related_stocks" ON "ods"."news_articles" USING "gin" ("related_stocks");



CREATE INDEX "assets_currency_code_idx" ON "public"."assets" USING "btree" ("currency_code");



CREATE INDEX "dnse_order_events_order_status_idx" ON "public"."dnse_order_events" USING "btree" ("order_status");



CREATE INDEX "dnse_order_events_symbol_idx" ON "public"."dnse_order_events" USING "btree" ("symbol");



CREATE INDEX "historical_prices_date_idx" ON "public"."historical_prices" USING "btree" ("date");



CREATE INDEX "idx_news_articles_related_stocks" ON "public"."news_articles" USING "gin" ("related_stocks");



CREATE INDEX "tx_cashflow_asset_id_idx" ON "public"."tx_cashflow" USING "btree" ("asset_id");



CREATE INDEX "tx_legs_asset_id_idx" ON "public"."tx_legs" USING "btree" ("asset_id");



CREATE INDEX "tx_stock_stock_id_idx" ON "public"."tx_stock" USING "btree" ("stock_id");



CREATE OR REPLACE TRIGGER "after_new_fxrate_ins" AFTER INSERT ON "dwd"."daily_fxrate_close" REFERENCING NEW TABLE AS "new_rows" FOR EACH STATEMENT EXECUTE FUNCTION "dws"."trg_snapshots_fxrate"();



CREATE OR REPLACE TRIGGER "after_new_fxrate_upd" AFTER UPDATE ON "dwd"."daily_fxrate_close" REFERENCING OLD TABLE AS "old_rows" NEW TABLE AS "new_rows" FOR EACH STATEMENT EXECUTE FUNCTION "dws"."trg_snapshots_fxrate"();



CREATE OR REPLACE TRIGGER "after_new_prices_ins" AFTER INSERT ON "dwd"."daily_asset_close" REFERENCING NEW TABLE AS "new_rows" FOR EACH STATEMENT EXECUTE FUNCTION "dws"."trg_snapshots_prices"();



CREATE OR REPLACE TRIGGER "after_new_prices_upd" AFTER UPDATE ON "dwd"."daily_asset_close" REFERENCING OLD TABLE AS "old_rows" NEW TABLE AS "new_rows" FOR EACH STATEMENT EXECUTE FUNCTION "dws"."trg_snapshots_prices"();



CREATE OR REPLACE TRIGGER "after_new_tx_borrow" AFTER INSERT ON "dwd"."tx_borrow" FOR EACH ROW EXECUTE FUNCTION "dwd"."trg_process_tx_borrow"();



CREATE OR REPLACE TRIGGER "after_new_tx_cashflow" AFTER INSERT ON "dwd"."tx_cashflow" FOR EACH ROW EXECUTE FUNCTION "dwd"."trg_process_tx_cashflow"();



CREATE OR REPLACE TRIGGER "after_new_tx_legs" AFTER INSERT ON "dwd"."tx_legs" REFERENCING NEW TABLE AS "new_rows" FOR EACH STATEMENT EXECUTE FUNCTION "dws"."trg_snapshots_tx_legs"();



CREATE OR REPLACE TRIGGER "after_new_tx_repay" AFTER INSERT ON "dwd"."tx_repay" FOR EACH ROW EXECUTE FUNCTION "dwd"."trg_process_tx_repay"();



CREATE OR REPLACE TRIGGER "after_new_tx_stock" AFTER INSERT ON "dwd"."tx_stock" FOR EACH ROW EXECUTE FUNCTION "dwd"."trg_process_tx_stock"();



CREATE OR REPLACE TRIGGER "after_filled_dnse_orders" AFTER INSERT ON "ods"."dnse_order_events" FOR EACH ROW EXECUTE FUNCTION "dwd"."process_dnse_order"();



CREATE OR REPLACE TRIGGER "after_new_m1_close" AFTER INSERT ON "ods"."dnse_m1_close" FOR EACH ROW EXECUTE FUNCTION "dwd"."upsert_daily_asset_close"();



CREATE OR REPLACE TRIGGER "after_filled_dnse_orders" AFTER INSERT ON "public"."dnse_order_events" FOR EACH ROW EXECUTE FUNCTION "public"."process_dnse_order"();



CREATE OR REPLACE TRIGGER "after_new_fxrate_ins" AFTER INSERT ON "public"."historical_fxrate" REFERENCING NEW TABLE AS "new_rows" FOR EACH STATEMENT EXECUTE FUNCTION "public"."trg_snapshots_fxrate"();



CREATE OR REPLACE TRIGGER "after_new_fxrate_upd" AFTER UPDATE ON "public"."historical_fxrate" REFERENCING OLD TABLE AS "old_rows" NEW TABLE AS "new_rows" FOR EACH STATEMENT EXECUTE FUNCTION "public"."trg_snapshots_fxrate"();



CREATE OR REPLACE TRIGGER "after_new_m1_close" AFTER INSERT ON "public"."dnse_m1_close" FOR EACH ROW EXECUTE FUNCTION "public"."upsert_historical_prices"();



CREATE OR REPLACE TRIGGER "after_new_prices_ins" AFTER INSERT ON "public"."historical_prices" REFERENCING NEW TABLE AS "new_rows" FOR EACH STATEMENT EXECUTE FUNCTION "public"."trg_snapshots_prices"();



CREATE OR REPLACE TRIGGER "after_new_prices_upd" AFTER UPDATE ON "public"."historical_prices" REFERENCING OLD TABLE AS "old_rows" NEW TABLE AS "new_rows" FOR EACH STATEMENT EXECUTE FUNCTION "public"."trg_snapshots_prices"();



CREATE OR REPLACE TRIGGER "after_new_tx_borrow" AFTER INSERT ON "public"."tx_borrow" FOR EACH ROW EXECUTE FUNCTION "public"."trg_process_tx_borrow"();



CREATE OR REPLACE TRIGGER "after_new_tx_cashflow" AFTER INSERT ON "public"."tx_cashflow" FOR EACH ROW EXECUTE FUNCTION "public"."trg_process_tx_cashflow"();



CREATE OR REPLACE TRIGGER "after_new_tx_legs" AFTER INSERT ON "public"."tx_legs" REFERENCING NEW TABLE AS "new_rows" FOR EACH STATEMENT EXECUTE FUNCTION "public"."trg_snapshots_tx_legs"();



CREATE OR REPLACE TRIGGER "after_new_tx_repay" AFTER INSERT ON "public"."tx_repay" FOR EACH ROW EXECUTE FUNCTION "public"."trg_process_tx_repay"();



CREATE OR REPLACE TRIGGER "after_new_tx_stock" AFTER INSERT ON "public"."tx_stock" FOR EACH ROW EXECUTE FUNCTION "public"."trg_process_tx_stock"();



ALTER TABLE ONLY "dim"."asset"
    ADD CONSTRAINT "assets_currency_fkey" FOREIGN KEY ("currency_id") REFERENCES "dim"."currency"("id") ON UPDATE CASCADE ON DELETE RESTRICT;



ALTER TABLE ONLY "dim"."user_settings"
    ADD CONSTRAINT "user_settings_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id") ON UPDATE CASCADE ON DELETE CASCADE;



ALTER TABLE ONLY "dwd"."daily_asset_close"
    ADD CONSTRAINT "asset_close_asset_id_fkey" FOREIGN KEY ("asset_id") REFERENCES "dim"."asset"("id") ON UPDATE CASCADE ON DELETE CASCADE;



ALTER TABLE ONLY "dwd"."daily_fxrate_close"
    ADD CONSTRAINT "exchange_rates_currency_code_fkey" FOREIGN KEY ("currency_id") REFERENCES "dim"."currency"("id") ON UPDATE CASCADE ON DELETE CASCADE;



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



ALTER TABLE ONLY "flight"."flights"
    ADD CONSTRAINT "flights_aircraft_type_fkey" FOREIGN KEY ("aircraft_type") REFERENCES "flight"."aircrafts"("icao_code") ON UPDATE CASCADE;



ALTER TABLE ONLY "flight"."flights"
    ADD CONSTRAINT "flights_airline_code_fkey" FOREIGN KEY ("airline_code") REFERENCES "flight"."airlines"("icao_code") ON UPDATE CASCADE;



ALTER TABLE ONLY "flight"."flights"
    ADD CONSTRAINT "flights_arr_airport_iata_fkey" FOREIGN KEY ("arr_airport_iata") REFERENCES "flight"."airports"("iata_code") ON UPDATE CASCADE;



ALTER TABLE ONLY "flight"."flights"
    ADD CONSTRAINT "flights_dept_airport_iata_fkey" FOREIGN KEY ("dept_airport_iata") REFERENCES "flight"."airports"("iata_code") ON UPDATE CASCADE;



ALTER TABLE ONLY "flight"."flights"
    ADD CONSTRAINT "flights_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id") ON UPDATE CASCADE ON DELETE CASCADE;



ALTER TABLE ONLY "public"."assets"
    ADD CONSTRAINT "assets_currency_fkey" FOREIGN KEY ("currency_code") REFERENCES "public"."currencies"("code") ON UPDATE CASCADE ON DELETE RESTRICT;



ALTER TABLE ONLY "public"."historical_prices"
    ADD CONSTRAINT "daily_security_prices_asset_id_fkey" FOREIGN KEY ("asset_id") REFERENCES "public"."assets"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."daily_snapshots"
    ADD CONSTRAINT "daily_snapshots_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id") ON UPDATE CASCADE ON DELETE CASCADE;



ALTER TABLE ONLY "public"."dnse_order_events"
    ADD CONSTRAINT "dnse_order_events_account_no_fkey" FOREIGN KEY ("account_no") REFERENCES "public"."user_settings"("dnse_account_id") ON UPDATE CASCADE ON DELETE CASCADE;



ALTER TABLE ONLY "public"."dnse_order_events"
    ADD CONSTRAINT "dnse_order_events_symbol_fkey" FOREIGN KEY ("symbol") REFERENCES "public"."assets"("ticker") ON UPDATE CASCADE ON DELETE CASCADE;



ALTER TABLE ONLY "public"."historical_fxrate"
    ADD CONSTRAINT "exchange_rates_currency_code_fkey" FOREIGN KEY ("currency_code") REFERENCES "public"."currencies"("code") ON UPDATE CASCADE ON DELETE CASCADE;



ALTER TABLE ONLY "public"."dnse_m1_close"
    ADD CONSTRAINT "m1_intraday_close_symbol_fkey" FOREIGN KEY ("symbol") REFERENCES "public"."assets"("ticker") ON UPDATE CASCADE ON DELETE CASCADE;



ALTER TABLE ONLY "public"."tx_borrow"
    ADD CONSTRAINT "tx_borrow_tx_id_fkey" FOREIGN KEY ("tx_id") REFERENCES "public"."tx_entries"("id") ON UPDATE CASCADE ON DELETE CASCADE;



ALTER TABLE ONLY "public"."tx_cashflow"
    ADD CONSTRAINT "tx_cashflow_asset_id_fkey" FOREIGN KEY ("asset_id") REFERENCES "public"."assets"("id");



ALTER TABLE ONLY "public"."tx_cashflow"
    ADD CONSTRAINT "tx_cashflow_tx_id_fkey" FOREIGN KEY ("tx_id") REFERENCES "public"."tx_entries"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."tx_entries"
    ADD CONSTRAINT "tx_entries_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id") ON UPDATE CASCADE ON DELETE CASCADE;



ALTER TABLE ONLY "public"."tx_legs"
    ADD CONSTRAINT "tx_legs_asset_id_fkey" FOREIGN KEY ("asset_id") REFERENCES "public"."assets"("id");



ALTER TABLE ONLY "public"."tx_legs"
    ADD CONSTRAINT "tx_legs_tx_id_fkey" FOREIGN KEY ("tx_id") REFERENCES "public"."tx_entries"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."tx_repay"
    ADD CONSTRAINT "tx_repay_borrow_tx_fkey" FOREIGN KEY ("borrow_tx") REFERENCES "public"."tx_borrow"("tx_id") ON UPDATE CASCADE ON DELETE CASCADE;



ALTER TABLE ONLY "public"."tx_repay"
    ADD CONSTRAINT "tx_repay_tx_id_fkey" FOREIGN KEY ("tx_id") REFERENCES "public"."tx_entries"("id") ON UPDATE CASCADE ON DELETE CASCADE;



ALTER TABLE ONLY "public"."tx_stock"
    ADD CONSTRAINT "tx_stock_stock_id_fkey" FOREIGN KEY ("stock_id") REFERENCES "public"."assets"("id");



ALTER TABLE ONLY "public"."tx_stock"
    ADD CONSTRAINT "tx_stock_tx_id_fkey" FOREIGN KEY ("tx_id") REFERENCES "public"."tx_entries"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."user_settings"
    ADD CONSTRAINT "user_settings_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id") ON UPDATE CASCADE ON DELETE CASCADE;



ALTER TABLE "dim"."currency" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "Enable users to view their own data only" ON "dws"."daily_snapshots" TO "authenticated" USING ((( SELECT "auth"."uid"() AS "uid") = "user_id"));



ALTER TABLE "dws"."daily_snapshots" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "Auth users can read aircrafts" ON "flight"."aircrafts" FOR SELECT TO "authenticated" USING (true);



CREATE POLICY "Auth users can read airlines" ON "flight"."airlines" FOR SELECT TO "authenticated" USING (true);



CREATE POLICY "Auth users can read airports" ON "flight"."airports" FOR SELECT TO "authenticated" USING (true);



CREATE POLICY "Enable insert for users based on user_id" ON "flight"."flights" FOR INSERT TO "authenticated" WITH CHECK ((( SELECT "auth"."uid"() AS "uid") = "user_id"));



CREATE POLICY "Enable update for users based on user_id" ON "flight"."flights" FOR UPDATE TO "authenticated" USING ((( SELECT "auth"."uid"() AS "uid") = "user_id")) WITH CHECK ((( SELECT "auth"."uid"() AS "uid") = "user_id"));



CREATE POLICY "Enable users to delete their own data only" ON "flight"."flights" FOR DELETE TO "authenticated" USING ((( SELECT "auth"."uid"() AS "uid") = "user_id"));



CREATE POLICY "Enable users to view their own data only" ON "flight"."flights" FOR SELECT TO "authenticated" USING ((( SELECT "auth"."uid"() AS "uid") = "user_id"));



ALTER TABLE "flight"."aircrafts" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "flight"."airlines" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "flight"."airports" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "flight"."flights" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "Auth users can read assets" ON "public"."assets" FOR SELECT TO "authenticated" USING (true);



CREATE POLICY "Auth users can read currencies" ON "public"."currencies" FOR SELECT TO "authenticated" USING (true);



CREATE POLICY "Enable insert for users based on user_id" ON "public"."tx_entries" FOR INSERT TO "authenticated" WITH CHECK ((( SELECT "auth"."uid"() AS "uid") = "user_id"));



CREATE POLICY "Enable read access for all users" ON "public"."news_articles" FOR SELECT USING (true);



CREATE POLICY "Enable read access for authenticated users only" ON "public"."historical_fxrate" FOR SELECT TO "authenticated" USING (true);



CREATE POLICY "Enable read access for authenticated users only" ON "public"."historical_prices" FOR SELECT TO "authenticated" USING (true);



CREATE POLICY "Enable users to insert their own borrow txs" ON "public"."tx_borrow" FOR INSERT TO "authenticated" WITH CHECK ((EXISTS ( SELECT 1
   FROM "public"."tx_entries" "e"
  WHERE (("e"."id" = "tx_borrow"."tx_id") AND ("e"."user_id" = "auth"."uid"())))));



CREATE POLICY "Enable users to insert their own cashflow txs" ON "public"."tx_cashflow" FOR INSERT TO "authenticated" WITH CHECK ((EXISTS ( SELECT 1
   FROM "public"."tx_entries" "e"
  WHERE (("e"."id" = "tx_cashflow"."tx_id") AND ("e"."user_id" = "auth"."uid"())))));



CREATE POLICY "Enable users to insert their own repay txs" ON "public"."tx_repay" FOR INSERT TO "authenticated" WITH CHECK ((EXISTS ( SELECT 1
   FROM "public"."tx_entries" "e"
  WHERE (("e"."id" = "tx_repay"."tx_id") AND ("e"."user_id" = "auth"."uid"())))));



CREATE POLICY "Enable users to insert their own stock txs" ON "public"."tx_stock" FOR INSERT TO "authenticated" WITH CHECK ((EXISTS ( SELECT 1
   FROM "public"."tx_entries" "e"
  WHERE (("e"."id" = "tx_stock"."tx_id") AND ("e"."user_id" = "auth"."uid"())))));



CREATE POLICY "Enable users to insert their own tx legs" ON "public"."tx_legs" FOR INSERT TO "authenticated" WITH CHECK ((EXISTS ( SELECT 1
   FROM "public"."tx_entries" "e"
  WHERE (("e"."id" = "tx_legs"."tx_id") AND ("e"."user_id" = "auth"."uid"())))));



CREATE POLICY "Enable users to view their own data only" ON "public"."daily_snapshots" FOR SELECT TO "authenticated" USING ((( SELECT "auth"."uid"() AS "uid") = "user_id"));



CREATE POLICY "Enable users to view their own data only" ON "public"."tx_entries" FOR SELECT TO "authenticated" USING ((( SELECT "auth"."uid"() AS "uid") = "user_id"));



CREATE POLICY "Enable users to view their own data only" ON "public"."user_settings" FOR SELECT TO "authenticated" USING ((( SELECT "auth"."uid"() AS "uid") = "user_id"));



CREATE POLICY "Users can read own cashflow txs" ON "public"."tx_cashflow" FOR SELECT TO "authenticated" USING ((EXISTS ( SELECT 1
   FROM "public"."tx_entries" "e"
  WHERE (("e"."id" = "tx_cashflow"."tx_id") AND ("e"."user_id" = "auth"."uid"())))));



CREATE POLICY "Users can read own legs" ON "public"."tx_legs" FOR SELECT TO "authenticated" USING ((EXISTS ( SELECT 1
   FROM "public"."tx_entries" "e"
  WHERE (("e"."id" = "tx_legs"."tx_id") AND ("e"."user_id" = "auth"."uid"())))));



CREATE POLICY "Users can read own stock txs" ON "public"."tx_stock" FOR SELECT TO "authenticated" USING ((EXISTS ( SELECT 1
   FROM "public"."tx_entries" "e"
  WHERE (("e"."id" = "tx_stock"."tx_id") AND ("e"."user_id" = "auth"."uid"())))));



CREATE POLICY "Users can read their own borrow txs" ON "public"."tx_borrow" FOR SELECT TO "authenticated" USING ((EXISTS ( SELECT 1
   FROM "public"."tx_entries" "e"
  WHERE (("e"."id" = "tx_borrow"."tx_id") AND ("e"."user_id" = "auth"."uid"())))));



CREATE POLICY "Users can read their own repay txs" ON "public"."tx_repay" FOR SELECT TO "authenticated" USING ((EXISTS ( SELECT 1
   FROM "public"."tx_entries" "e"
  WHERE (("e"."id" = "tx_repay"."tx_id") AND ("e"."user_id" = "auth"."uid"())))));



CREATE POLICY "Users can update their own borrow txs" ON "public"."tx_borrow" FOR UPDATE TO "authenticated" USING ((EXISTS ( SELECT 1
   FROM "public"."tx_entries" "e"
  WHERE (("e"."id" = "tx_borrow"."tx_id") AND ("e"."user_id" = "auth"."uid"()))))) WITH CHECK ((EXISTS ( SELECT 1
   FROM "public"."tx_entries" "e"
  WHERE (("e"."id" = "tx_borrow"."tx_id") AND ("e"."user_id" = "auth"."uid"())))));



CREATE POLICY "Users can update their own settings" ON "public"."user_settings" FOR UPDATE TO "authenticated" USING ((( SELECT "auth"."uid"() AS "uid") = "user_id")) WITH CHECK ((( SELECT "auth"."uid"() AS "uid") = "user_id"));



ALTER TABLE "public"."assets" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."currencies" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."daily_snapshots" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."dnse_m1_close" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."dnse_order_events" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."historical_fxrate" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."historical_prices" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."news_articles" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."tx_borrow" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."tx_cashflow" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."tx_entries" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."tx_legs" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."tx_repay" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."tx_stock" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."user_settings" ENABLE ROW LEVEL SECURITY;




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



GRANT USAGE ON SCHEMA "flight" TO "anon";
GRANT USAGE ON SCHEMA "flight" TO "authenticated";
GRANT USAGE ON SCHEMA "flight" TO "service_role";






GRANT USAGE ON SCHEMA "ods" TO "anon";
GRANT USAGE ON SCHEMA "ods" TO "authenticated";
GRANT USAGE ON SCHEMA "ods" TO "service_role";



GRANT USAGE ON SCHEMA "public" TO "postgres";
GRANT USAGE ON SCHEMA "public" TO "anon";
GRANT USAGE ON SCHEMA "public" TO "authenticated";
GRANT USAGE ON SCHEMA "public" TO "service_role";
























GRANT ALL ON FUNCTION "dwd"."add_borrow_event"("p_principal" numeric, "p_lender" "text", "p_rate" numeric, "p_created_at" timestamp with time zone) TO "anon";
GRANT ALL ON FUNCTION "dwd"."add_borrow_event"("p_principal" numeric, "p_lender" "text", "p_rate" numeric, "p_created_at" timestamp with time zone) TO "authenticated";
GRANT ALL ON FUNCTION "dwd"."add_borrow_event"("p_principal" numeric, "p_lender" "text", "p_rate" numeric, "p_created_at" timestamp with time zone) TO "service_role";



GRANT ALL ON FUNCTION "dwd"."add_cashflow_event"("p_operation" "text", "p_asset_id" smallint, "p_quantity" numeric, "p_fx_rate" numeric, "p_memo" "text", "p_created_at" timestamp with time zone, "p_user_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "dwd"."add_cashflow_event"("p_operation" "text", "p_asset_id" smallint, "p_quantity" numeric, "p_fx_rate" numeric, "p_memo" "text", "p_created_at" timestamp with time zone, "p_user_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "dwd"."add_cashflow_event"("p_operation" "text", "p_asset_id" smallint, "p_quantity" numeric, "p_fx_rate" numeric, "p_memo" "text", "p_created_at" timestamp with time zone, "p_user_id" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "dwd"."add_repay_event"("p_repay_tx" integer, "p_interest" numeric, "p_created_at" timestamp with time zone) TO "anon";
GRANT ALL ON FUNCTION "dwd"."add_repay_event"("p_repay_tx" integer, "p_interest" numeric, "p_created_at" timestamp with time zone) TO "authenticated";
GRANT ALL ON FUNCTION "dwd"."add_repay_event"("p_repay_tx" integer, "p_interest" numeric, "p_created_at" timestamp with time zone) TO "service_role";



GRANT ALL ON FUNCTION "dwd"."add_stock_event"("p_side" "text", "p_ticker" "text", "p_price" numeric, "p_quantity" numeric, "p_fee" numeric, "p_tax" numeric, "p_user_id" "uuid", "p_created_at" timestamp with time zone) TO "anon";
GRANT ALL ON FUNCTION "dwd"."add_stock_event"("p_side" "text", "p_ticker" "text", "p_price" numeric, "p_quantity" numeric, "p_fee" numeric, "p_tax" numeric, "p_user_id" "uuid", "p_created_at" timestamp with time zone) TO "authenticated";
GRANT ALL ON FUNCTION "dwd"."add_stock_event"("p_side" "text", "p_ticker" "text", "p_price" numeric, "p_quantity" numeric, "p_fee" numeric, "p_tax" numeric, "p_user_id" "uuid", "p_created_at" timestamp with time zone) TO "service_role";



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



GRANT ALL ON FUNCTION "dwd"."trg_process_tx_borrow"() TO "anon";
GRANT ALL ON FUNCTION "dwd"."trg_process_tx_borrow"() TO "authenticated";
GRANT ALL ON FUNCTION "dwd"."trg_process_tx_borrow"() TO "service_role";



GRANT ALL ON FUNCTION "dwd"."trg_process_tx_cashflow"() TO "anon";
GRANT ALL ON FUNCTION "dwd"."trg_process_tx_cashflow"() TO "authenticated";
GRANT ALL ON FUNCTION "dwd"."trg_process_tx_cashflow"() TO "service_role";



GRANT ALL ON FUNCTION "dwd"."trg_process_tx_repay"() TO "anon";
GRANT ALL ON FUNCTION "dwd"."trg_process_tx_repay"() TO "authenticated";
GRANT ALL ON FUNCTION "dwd"."trg_process_tx_repay"() TO "service_role";



GRANT ALL ON FUNCTION "dwd"."trg_process_tx_stock"() TO "anon";
GRANT ALL ON FUNCTION "dwd"."trg_process_tx_stock"() TO "authenticated";
GRANT ALL ON FUNCTION "dwd"."trg_process_tx_stock"() TO "service_role";



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



GRANT ALL ON FUNCTION "dws"."get_monthly_pnl_chart"("p_start_date" "date", "p_end_date" "date") TO "anon";
GRANT ALL ON FUNCTION "dws"."get_monthly_pnl_chart"("p_start_date" "date", "p_end_date" "date") TO "authenticated";
GRANT ALL ON FUNCTION "dws"."get_monthly_pnl_chart"("p_start_date" "date", "p_end_date" "date") TO "service_role";



GRANT ALL ON FUNCTION "dws"."get_return_chart"("p_start_date" "date", "p_end_date" "date", "p_threshold" integer) TO "anon";
GRANT ALL ON FUNCTION "dws"."get_return_chart"("p_start_date" "date", "p_end_date" "date", "p_threshold" integer) TO "authenticated";
GRANT ALL ON FUNCTION "dws"."get_return_chart"("p_start_date" "date", "p_end_date" "date", "p_threshold" integer) TO "service_role";



GRANT ALL ON FUNCTION "dws"."get_top_stocks"("p_start_date" "date", "p_end_date" "date") TO "anon";
GRANT ALL ON FUNCTION "dws"."get_top_stocks"("p_start_date" "date", "p_end_date" "date") TO "authenticated";
GRANT ALL ON FUNCTION "dws"."get_top_stocks"("p_start_date" "date", "p_end_date" "date") TO "service_role";



GRANT ALL ON FUNCTION "dws"."recompute_daily_snapshots"("p_user_id" "uuid", "p_from_date" "date") TO "anon";
GRANT ALL ON FUNCTION "dws"."recompute_daily_snapshots"("p_user_id" "uuid", "p_from_date" "date") TO "authenticated";
GRANT ALL ON FUNCTION "dws"."recompute_daily_snapshots"("p_user_id" "uuid", "p_from_date" "date") TO "service_role";



GRANT ALL ON FUNCTION "dws"."trg_snapshots_fxrate"() TO "anon";
GRANT ALL ON FUNCTION "dws"."trg_snapshots_fxrate"() TO "authenticated";
GRANT ALL ON FUNCTION "dws"."trg_snapshots_fxrate"() TO "service_role";



GRANT ALL ON FUNCTION "dws"."trg_snapshots_prices"() TO "anon";
GRANT ALL ON FUNCTION "dws"."trg_snapshots_prices"() TO "authenticated";
GRANT ALL ON FUNCTION "dws"."trg_snapshots_prices"() TO "service_role";



GRANT ALL ON FUNCTION "dws"."trg_snapshots_tx_legs"() TO "anon";
GRANT ALL ON FUNCTION "dws"."trg_snapshots_tx_legs"() TO "authenticated";
GRANT ALL ON FUNCTION "dws"."trg_snapshots_tx_legs"() TO "service_role";


























































































































































































GRANT ALL ON FUNCTION "flight"."haversine_distance_km"("lat1" double precision, "lng1" double precision, "lat2" double precision, "lng2" double precision) TO "anon";
GRANT ALL ON FUNCTION "flight"."haversine_distance_km"("lat1" double precision, "lng1" double precision, "lat2" double precision, "lng2" double precision) TO "authenticated";
GRANT ALL ON FUNCTION "flight"."haversine_distance_km"("lat1" double precision, "lng1" double precision, "lat2" double precision, "lng2" double precision) TO "service_role";



GRANT ALL ON FUNCTION "flight"."insert_flight_with_timezone"("p_departure_airport_id" "uuid", "p_departure_local" "text", "p_arrival_airport_id" "uuid", "p_arrival_local" "text", "p_flight_number" "text", "p_airline_id" "uuid", "p_ticket_class" "flight"."ticket_class", "p_seat_no" "text", "p_seat_pos" "flight"."seat_position", "p_aircraft_id" "uuid", "p_tail_no" "text", "p_notes" "text") TO "anon";
GRANT ALL ON FUNCTION "flight"."insert_flight_with_timezone"("p_departure_airport_id" "uuid", "p_departure_local" "text", "p_arrival_airport_id" "uuid", "p_arrival_local" "text", "p_flight_number" "text", "p_airline_id" "uuid", "p_ticket_class" "flight"."ticket_class", "p_seat_no" "text", "p_seat_pos" "flight"."seat_position", "p_aircraft_id" "uuid", "p_tail_no" "text", "p_notes" "text") TO "authenticated";
GRANT ALL ON FUNCTION "flight"."insert_flight_with_timezone"("p_departure_airport_id" "uuid", "p_departure_local" "text", "p_arrival_airport_id" "uuid", "p_arrival_local" "text", "p_flight_number" "text", "p_airline_id" "uuid", "p_ticket_class" "flight"."ticket_class", "p_seat_no" "text", "p_seat_pos" "flight"."seat_position", "p_aircraft_id" "uuid", "p_tail_no" "text", "p_notes" "text") TO "service_role";



GRANT ALL ON FUNCTION "flight"."update_flight_with_timezone"("p_flight_id" "uuid", "p_departure_airport_id" "uuid", "p_departure_local" "text", "p_arrival_airport_id" "uuid", "p_arrival_local" "text", "p_flight_number" "text", "p_airline_id" "uuid", "p_ticket_class" "flight"."ticket_class", "p_seat_no" "text", "p_seat_pos" "flight"."seat_position", "p_aircraft_id" "uuid", "p_tail_no" "text", "p_notes" "text") TO "anon";
GRANT ALL ON FUNCTION "flight"."update_flight_with_timezone"("p_flight_id" "uuid", "p_departure_airport_id" "uuid", "p_departure_local" "text", "p_arrival_airport_id" "uuid", "p_arrival_local" "text", "p_flight_number" "text", "p_airline_id" "uuid", "p_ticket_class" "flight"."ticket_class", "p_seat_no" "text", "p_seat_pos" "flight"."seat_position", "p_aircraft_id" "uuid", "p_tail_no" "text", "p_notes" "text") TO "authenticated";
GRANT ALL ON FUNCTION "flight"."update_flight_with_timezone"("p_flight_id" "uuid", "p_departure_airport_id" "uuid", "p_departure_local" "text", "p_arrival_airport_id" "uuid", "p_arrival_local" "text", "p_flight_number" "text", "p_airline_id" "uuid", "p_ticket_class" "flight"."ticket_class", "p_seat_no" "text", "p_seat_pos" "flight"."seat_position", "p_aircraft_id" "uuid", "p_tail_no" "text", "p_notes" "text") TO "service_role";









GRANT ALL ON FUNCTION "public"."active_stock_tickers"() TO "anon";
GRANT ALL ON FUNCTION "public"."active_stock_tickers"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."active_stock_tickers"() TO "service_role";



GRANT ALL ON FUNCTION "public"."add_borrow_event"("p_principal" numeric, "p_lender" "text", "p_rate" numeric, "p_created_at" timestamp with time zone) TO "anon";
GRANT ALL ON FUNCTION "public"."add_borrow_event"("p_principal" numeric, "p_lender" "text", "p_rate" numeric, "p_created_at" timestamp with time zone) TO "authenticated";
GRANT ALL ON FUNCTION "public"."add_borrow_event"("p_principal" numeric, "p_lender" "text", "p_rate" numeric, "p_created_at" timestamp with time zone) TO "service_role";



GRANT ALL ON FUNCTION "public"."add_cashflow_event"("p_operation" "text", "p_asset_id" "uuid", "p_quantity" numeric, "p_fx_rate" numeric, "p_memo" "text", "p_created_at" timestamp with time zone, "p_user_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."add_cashflow_event"("p_operation" "text", "p_asset_id" "uuid", "p_quantity" numeric, "p_fx_rate" numeric, "p_memo" "text", "p_created_at" timestamp with time zone, "p_user_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."add_cashflow_event"("p_operation" "text", "p_asset_id" "uuid", "p_quantity" numeric, "p_fx_rate" numeric, "p_memo" "text", "p_created_at" timestamp with time zone, "p_user_id" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "public"."add_repay_event"("p_repay_tx" "uuid", "p_interest" numeric, "p_created_at" timestamp with time zone) TO "anon";
GRANT ALL ON FUNCTION "public"."add_repay_event"("p_repay_tx" "uuid", "p_interest" numeric, "p_created_at" timestamp with time zone) TO "authenticated";
GRANT ALL ON FUNCTION "public"."add_repay_event"("p_repay_tx" "uuid", "p_interest" numeric, "p_created_at" timestamp with time zone) TO "service_role";



GRANT ALL ON FUNCTION "public"."add_stock_event"("p_side" "text", "p_ticker" "text", "p_price" numeric, "p_quantity" numeric, "p_fee" numeric, "p_tax" numeric, "p_user_id" "uuid", "p_created_at" timestamp with time zone) TO "anon";
GRANT ALL ON FUNCTION "public"."add_stock_event"("p_side" "text", "p_ticker" "text", "p_price" numeric, "p_quantity" numeric, "p_fee" numeric, "p_tax" numeric, "p_user_id" "uuid", "p_created_at" timestamp with time zone) TO "authenticated";
GRANT ALL ON FUNCTION "public"."add_stock_event"("p_side" "text", "p_ticker" "text", "p_price" numeric, "p_quantity" numeric, "p_fee" numeric, "p_tax" numeric, "p_user_id" "uuid", "p_created_at" timestamp with time zone) TO "service_role";



GRANT ALL ON FUNCTION "public"."calculate_pnl"("p_start_date" "date", "p_end_date" "date") TO "anon";
GRANT ALL ON FUNCTION "public"."calculate_pnl"("p_start_date" "date", "p_end_date" "date") TO "authenticated";
GRANT ALL ON FUNCTION "public"."calculate_pnl"("p_start_date" "date", "p_end_date" "date") TO "service_role";



GRANT ALL ON FUNCTION "public"."calculate_twr"("p_start_date" "date", "p_end_date" "date") TO "anon";
GRANT ALL ON FUNCTION "public"."calculate_twr"("p_start_date" "date", "p_end_date" "date") TO "authenticated";
GRANT ALL ON FUNCTION "public"."calculate_twr"("p_start_date" "date", "p_end_date" "date") TO "service_role";



GRANT ALL ON FUNCTION "public"."get_equity_chart"("p_start_date" "date", "p_end_date" "date", "p_threshold" integer) TO "anon";
GRANT ALL ON FUNCTION "public"."get_equity_chart"("p_start_date" "date", "p_end_date" "date", "p_threshold" integer) TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_equity_chart"("p_start_date" "date", "p_end_date" "date", "p_threshold" integer) TO "service_role";



GRANT ALL ON FUNCTION "public"."get_return_chart"("p_start_date" "date", "p_end_date" "date", "p_threshold" integer) TO "anon";
GRANT ALL ON FUNCTION "public"."get_return_chart"("p_start_date" "date", "p_end_date" "date", "p_threshold" integer) TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_return_chart"("p_start_date" "date", "p_end_date" "date", "p_threshold" integer) TO "service_role";



GRANT ALL ON FUNCTION "public"."process_dnse_order"() TO "anon";
GRANT ALL ON FUNCTION "public"."process_dnse_order"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."process_dnse_order"() TO "service_role";



GRANT ALL ON FUNCTION "public"."process_tx_borrow"("p_tx_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."process_tx_borrow"("p_tx_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."process_tx_borrow"("p_tx_id" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "public"."process_tx_cashflow"("p_tx_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."process_tx_cashflow"("p_tx_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."process_tx_cashflow"("p_tx_id" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "public"."process_tx_repay"("p_tx_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."process_tx_repay"("p_tx_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."process_tx_repay"("p_tx_id" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "public"."process_tx_stock"("p_tx_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."process_tx_stock"("p_tx_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."process_tx_stock"("p_tx_id" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "public"."rebuild_ledger"() TO "anon";
GRANT ALL ON FUNCTION "public"."rebuild_ledger"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."rebuild_ledger"() TO "service_role";



GRANT ALL ON FUNCTION "public"."recompute_daily_snapshots"("p_user_id" "uuid", "p_from_date" "date") TO "anon";
GRANT ALL ON FUNCTION "public"."recompute_daily_snapshots"("p_user_id" "uuid", "p_from_date" "date") TO "authenticated";
GRANT ALL ON FUNCTION "public"."recompute_daily_snapshots"("p_user_id" "uuid", "p_from_date" "date") TO "service_role";



GRANT ALL ON FUNCTION "public"."trg_process_tx_borrow"() TO "anon";
GRANT ALL ON FUNCTION "public"."trg_process_tx_borrow"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."trg_process_tx_borrow"() TO "service_role";



GRANT ALL ON FUNCTION "public"."trg_process_tx_cashflow"() TO "anon";
GRANT ALL ON FUNCTION "public"."trg_process_tx_cashflow"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."trg_process_tx_cashflow"() TO "service_role";



GRANT ALL ON FUNCTION "public"."trg_process_tx_repay"() TO "anon";
GRANT ALL ON FUNCTION "public"."trg_process_tx_repay"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."trg_process_tx_repay"() TO "service_role";



GRANT ALL ON FUNCTION "public"."trg_process_tx_stock"() TO "anon";
GRANT ALL ON FUNCTION "public"."trg_process_tx_stock"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."trg_process_tx_stock"() TO "service_role";



GRANT ALL ON FUNCTION "public"."trg_snapshots_fxrate"() TO "anon";
GRANT ALL ON FUNCTION "public"."trg_snapshots_fxrate"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."trg_snapshots_fxrate"() TO "service_role";



GRANT ALL ON FUNCTION "public"."trg_snapshots_prices"() TO "anon";
GRANT ALL ON FUNCTION "public"."trg_snapshots_prices"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."trg_snapshots_prices"() TO "service_role";



GRANT ALL ON FUNCTION "public"."trg_snapshots_tx_legs"() TO "anon";
GRANT ALL ON FUNCTION "public"."trg_snapshots_tx_legs"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."trg_snapshots_tx_legs"() TO "service_role";



GRANT ALL ON FUNCTION "public"."upsert_historical_prices"() TO "anon";
GRANT ALL ON FUNCTION "public"."upsert_historical_prices"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."upsert_historical_prices"() TO "service_role";


















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















GRANT ALL ON TABLE "flight"."aircrafts" TO "anon";
GRANT ALL ON TABLE "flight"."aircrafts" TO "authenticated";
GRANT ALL ON TABLE "flight"."aircrafts" TO "service_role";



GRANT ALL ON TABLE "flight"."airlines" TO "anon";
GRANT ALL ON TABLE "flight"."airlines" TO "authenticated";
GRANT ALL ON TABLE "flight"."airlines" TO "service_role";



GRANT ALL ON TABLE "flight"."airports" TO "anon";
GRANT ALL ON TABLE "flight"."airports" TO "authenticated";
GRANT ALL ON TABLE "flight"."airports" TO "service_role";



GRANT ALL ON TABLE "flight"."flights" TO "anon";
GRANT ALL ON TABLE "flight"."flights" TO "authenticated";
GRANT ALL ON TABLE "flight"."flights" TO "service_role";



GRANT ALL ON TABLE "flight"."routes_geojson" TO "anon";
GRANT ALL ON TABLE "flight"."routes_geojson" TO "authenticated";
GRANT ALL ON TABLE "flight"."routes_geojson" TO "service_role";



GRANT ALL ON TABLE "flight"."flights_summary" TO "anon";
GRANT ALL ON TABLE "flight"."flights_summary" TO "authenticated";
GRANT ALL ON TABLE "flight"."flights_summary" TO "service_role";



GRANT ALL ON TABLE "flight"."lifetime_stats" TO "anon";
GRANT ALL ON TABLE "flight"."lifetime_stats" TO "authenticated";
GRANT ALL ON TABLE "flight"."lifetime_stats" TO "service_role";



GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE "ods"."dnse_m1_close" TO "anon";
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE "ods"."dnse_m1_close" TO "authenticated";
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE "ods"."dnse_m1_close" TO "service_role";



GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE "ods"."dnse_order_events" TO "anon";
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE "ods"."dnse_order_events" TO "authenticated";
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE "ods"."dnse_order_events" TO "service_role";



GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE "ods"."news_articles" TO "anon";
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE "ods"."news_articles" TO "authenticated";
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE "ods"."news_articles" TO "service_role";



GRANT ALL ON TABLE "public"."assets" TO "anon";
GRANT ALL ON TABLE "public"."assets" TO "authenticated";
GRANT ALL ON TABLE "public"."assets" TO "service_role";



GRANT ALL ON TABLE "public"."historical_fxrate" TO "anon";
GRANT ALL ON TABLE "public"."historical_fxrate" TO "authenticated";
GRANT ALL ON TABLE "public"."historical_fxrate" TO "service_role";



GRANT ALL ON TABLE "public"."historical_prices" TO "anon";
GRANT ALL ON TABLE "public"."historical_prices" TO "authenticated";
GRANT ALL ON TABLE "public"."historical_prices" TO "service_role";



GRANT ALL ON TABLE "public"."tx_borrow" TO "anon";
GRANT ALL ON TABLE "public"."tx_borrow" TO "authenticated";
GRANT ALL ON TABLE "public"."tx_borrow" TO "service_role";



GRANT ALL ON TABLE "public"."tx_entries" TO "anon";
GRANT ALL ON TABLE "public"."tx_entries" TO "authenticated";
GRANT ALL ON TABLE "public"."tx_entries" TO "service_role";



GRANT ALL ON TABLE "public"."tx_repay" TO "anon";
GRANT ALL ON TABLE "public"."tx_repay" TO "authenticated";
GRANT ALL ON TABLE "public"."tx_repay" TO "service_role";



GRANT ALL ON TABLE "public"."outstanding_debts" TO "anon";
GRANT ALL ON TABLE "public"."outstanding_debts" TO "authenticated";
GRANT ALL ON TABLE "public"."outstanding_debts" TO "service_role";



GRANT ALL ON TABLE "public"."tx_legs" TO "anon";
GRANT ALL ON TABLE "public"."tx_legs" TO "authenticated";
GRANT ALL ON TABLE "public"."tx_legs" TO "service_role";



GRANT ALL ON TABLE "public"."balance_sheet" TO "anon";
GRANT ALL ON TABLE "public"."balance_sheet" TO "authenticated";
GRANT ALL ON TABLE "public"."balance_sheet" TO "service_role";



GRANT ALL ON TABLE "public"."daily_snapshots" TO "anon";
GRANT ALL ON TABLE "public"."daily_snapshots" TO "authenticated";
GRANT ALL ON TABLE "public"."daily_snapshots" TO "service_role";



GRANT ALL ON TABLE "public"."benchmark_all" TO "anon";
GRANT ALL ON TABLE "public"."benchmark_all" TO "authenticated";
GRANT ALL ON TABLE "public"."benchmark_all" TO "service_role";



GRANT ALL ON TABLE "public"."user_settings" TO "anon";
GRANT ALL ON TABLE "public"."user_settings" TO "authenticated";
GRANT ALL ON TABLE "public"."user_settings" TO "service_role";



GRANT ALL ON TABLE "public"."benchmark_rollings" TO "anon";
GRANT ALL ON TABLE "public"."benchmark_rollings" TO "authenticated";
GRANT ALL ON TABLE "public"."benchmark_rollings" TO "service_role";



GRANT ALL ON TABLE "public"."benchmark_yearly" TO "anon";
GRANT ALL ON TABLE "public"."benchmark_yearly" TO "authenticated";
GRANT ALL ON TABLE "public"."benchmark_yearly" TO "service_role";



GRANT ALL ON TABLE "public"."cashflow_all" TO "anon";
GRANT ALL ON TABLE "public"."cashflow_all" TO "authenticated";
GRANT ALL ON TABLE "public"."cashflow_all" TO "service_role";



GRANT ALL ON TABLE "public"."cashflow_yearly" TO "anon";
GRANT ALL ON TABLE "public"."cashflow_yearly" TO "authenticated";
GRANT ALL ON TABLE "public"."cashflow_yearly" TO "service_role";



GRANT ALL ON TABLE "public"."currencies" TO "anon";
GRANT ALL ON TABLE "public"."currencies" TO "authenticated";
GRANT ALL ON TABLE "public"."currencies" TO "service_role";



GRANT ALL ON TABLE "public"."dnse_m1_close" TO "anon";
GRANT ALL ON TABLE "public"."dnse_m1_close" TO "authenticated";
GRANT ALL ON TABLE "public"."dnse_m1_close" TO "service_role";



GRANT ALL ON TABLE "public"."dnse_order_events" TO "anon";
GRANT ALL ON TABLE "public"."dnse_order_events" TO "authenticated";
GRANT ALL ON TABLE "public"."dnse_order_events" TO "service_role";



GRANT ALL ON TABLE "public"."equity_rollings" TO "anon";
GRANT ALL ON TABLE "public"."equity_rollings" TO "authenticated";
GRANT ALL ON TABLE "public"."equity_rollings" TO "service_role";



GRANT ALL ON TABLE "public"."news_articles" TO "anon";
GRANT ALL ON TABLE "public"."news_articles" TO "authenticated";
GRANT ALL ON TABLE "public"."news_articles" TO "service_role";



GRANT ALL ON TABLE "public"."pnl_expense_all" TO "anon";
GRANT ALL ON TABLE "public"."pnl_expense_all" TO "authenticated";
GRANT ALL ON TABLE "public"."pnl_expense_all" TO "service_role";



GRANT ALL ON TABLE "public"."pnl_expense_last1y" TO "anon";
GRANT ALL ON TABLE "public"."pnl_expense_last1y" TO "authenticated";
GRANT ALL ON TABLE "public"."pnl_expense_last1y" TO "service_role";



GRANT ALL ON TABLE "public"."pnl_expense_yearly" TO "anon";
GRANT ALL ON TABLE "public"."pnl_expense_yearly" TO "authenticated";
GRANT ALL ON TABLE "public"."pnl_expense_yearly" TO "service_role";



GRANT ALL ON TABLE "public"."stock_pnl_yearly" TO "anon";
GRANT ALL ON TABLE "public"."stock_pnl_yearly" TO "authenticated";
GRANT ALL ON TABLE "public"."stock_pnl_yearly" TO "service_role";



GRANT ALL ON TABLE "public"."stock_pnl_all" TO "anon";
GRANT ALL ON TABLE "public"."stock_pnl_all" TO "authenticated";
GRANT ALL ON TABLE "public"."stock_pnl_all" TO "service_role";



GRANT ALL ON TABLE "public"."tx_cashflow" TO "anon";
GRANT ALL ON TABLE "public"."tx_cashflow" TO "authenticated";
GRANT ALL ON TABLE "public"."tx_cashflow" TO "service_role";



GRANT ALL ON TABLE "public"."tx_stock" TO "anon";
GRANT ALL ON TABLE "public"."tx_stock" TO "authenticated";
GRANT ALL ON TABLE "public"."tx_stock" TO "service_role";



GRANT ALL ON TABLE "public"."tx_summary" TO "anon";
GRANT ALL ON TABLE "public"."tx_summary" TO "authenticated";
GRANT ALL ON TABLE "public"."tx_summary" TO "service_role";









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



ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "flight" GRANT ALL ON SEQUENCES TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "flight" GRANT ALL ON SEQUENCES TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "flight" GRANT ALL ON SEQUENCES TO "service_role";



ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "flight" GRANT ALL ON FUNCTIONS TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "flight" GRANT ALL ON FUNCTIONS TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "flight" GRANT ALL ON FUNCTIONS TO "service_role";



ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "flight" GRANT ALL ON TABLES TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "flight" GRANT ALL ON TABLES TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "flight" GRANT ALL ON TABLES TO "service_role";



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

