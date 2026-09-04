-- Migration unit 1: schema_changes
-- Transaction mode: transactional
-- Boundary reason: default

SET check_function_bodies = false;

DROP FUNCTION dwd.add_stock_event(p_side text, p_ticker text, p_price numeric, p_quantity numeric, p_fee numeric, p_tax numeric, p_user_id uuid, p_created_at timestamp
  WITH time zone);

CREATE POLICY "Enable read access for all users" ON dim.currency
  FOR SELECT
  TO authenticated
  USING (true);

CREATE FUNCTION dwd.add_stock_event (
  p_side       text,
  p_stock_id   smallint,
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
END;
$function$;

GRANT ALL ON FUNCTION dwd.add_stock_event(text, smallint, numeric, numeric, numeric, numeric, uuid, timestamp WITH time zone) TO anon;

GRANT ALL ON FUNCTION dwd.add_stock_event(text, smallint, numeric, numeric, numeric, numeric, uuid, timestamp WITH time zone) TO authenticated;

GRANT ALL ON FUNCTION dwd.add_stock_event(text, smallint, numeric, numeric, numeric, numeric, uuid, timestamp WITH time zone) TO service_role;