CREATE OR REPLACE FUNCTION dwd.process_dnse_order()
 RETURNS trigger
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
        v_user_id
      );
    END IF;
    RETURN NULL;
  END;
END;
$function$
