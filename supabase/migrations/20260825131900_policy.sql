-- Migration unit 1: schema_changes
-- Transaction mode: transactional
-- Boundary reason: default

SET check_function_bodies = false;

DROP EXTENSION pg_graphql;

GRANT DELETE, INSERT, SELECT, UPDATE ON dim.asset TO anon;

GRANT DELETE, INSERT, SELECT, UPDATE ON dim.asset TO authenticated;

GRANT DELETE, INSERT, SELECT, UPDATE ON dim.asset TO service_role;

GRANT DELETE, INSERT, SELECT, UPDATE ON dim.currency TO anon;

GRANT DELETE, INSERT, SELECT, UPDATE ON dim.currency TO authenticated;

GRANT DELETE, INSERT, SELECT, UPDATE ON dim.currency TO service_role;

GRANT DELETE, INSERT, SELECT, UPDATE ON dim.user_settings TO anon;

GRANT DELETE, INSERT, SELECT, UPDATE ON dim.user_settings TO authenticated;

GRANT DELETE, INSERT, SELECT, UPDATE ON dim.user_settings TO service_role;

GRANT ALL ON FUNCTION dwd.add_borrow_event(numeric, text, numeric, timestamp WITH time zone) TO anon;

GRANT ALL ON FUNCTION dwd.add_borrow_event(numeric, text, numeric, timestamp WITH time zone) TO authenticated;

GRANT ALL ON FUNCTION dwd.add_borrow_event(numeric, text, numeric, timestamp WITH time zone) TO service_role;

GRANT ALL ON FUNCTION dwd.add_cashflow_event(text, smallint, numeric, numeric, text, timestamp WITH time zone, uuid) TO anon;

GRANT ALL ON FUNCTION dwd.add_cashflow_event(text, smallint, numeric, numeric, text, timestamp WITH time zone, uuid) TO authenticated;

GRANT ALL ON FUNCTION dwd.add_cashflow_event(text, smallint, numeric, numeric, text, timestamp WITH time zone, uuid) TO service_role;

GRANT ALL ON FUNCTION dwd.add_repay_event(integer, numeric, timestamp WITH time zone) TO anon;

GRANT ALL ON FUNCTION dwd.add_repay_event(integer, numeric, timestamp WITH time zone) TO authenticated;

GRANT ALL ON FUNCTION dwd.add_repay_event(integer, numeric, timestamp WITH time zone) TO service_role;

GRANT ALL ON FUNCTION dwd.add_stock_event(text, text, numeric, numeric, numeric, numeric, uuid, timestamp WITH time zone) TO anon;

GRANT ALL ON FUNCTION dwd.add_stock_event(text, text, numeric, numeric, numeric, numeric, uuid, timestamp WITH time zone) TO authenticated;

GRANT ALL ON FUNCTION dwd.add_stock_event(text, text, numeric, numeric, numeric, numeric, uuid, timestamp WITH time zone) TO service_role;

GRANT ALL ON FUNCTION dwd.process_dnse_order() TO anon;

GRANT ALL ON FUNCTION dwd.process_dnse_order() TO authenticated;

GRANT ALL ON FUNCTION dwd.process_dnse_order() TO service_role;

GRANT ALL ON FUNCTION dwd.process_tx_borrow(integer) TO anon;

GRANT ALL ON FUNCTION dwd.process_tx_borrow(integer) TO authenticated;

GRANT ALL ON FUNCTION dwd.process_tx_borrow(integer) TO service_role;

GRANT ALL ON FUNCTION dwd.process_tx_cashflow(integer) TO anon;

GRANT ALL ON FUNCTION dwd.process_tx_cashflow(integer) TO authenticated;

GRANT ALL ON FUNCTION dwd.process_tx_cashflow(integer) TO service_role;

GRANT ALL ON FUNCTION dwd.process_tx_repay(integer) TO anon;

GRANT ALL ON FUNCTION dwd.process_tx_repay(integer) TO authenticated;

GRANT ALL ON FUNCTION dwd.process_tx_repay(integer) TO service_role;

GRANT ALL ON FUNCTION dwd.process_tx_stock(integer) TO anon;

GRANT ALL ON FUNCTION dwd.process_tx_stock(integer) TO authenticated;

GRANT ALL ON FUNCTION dwd.process_tx_stock(integer) TO service_role;

GRANT ALL ON FUNCTION dwd.rebuild_ledger() TO anon;

GRANT ALL ON FUNCTION dwd.rebuild_ledger() TO authenticated;

GRANT ALL ON FUNCTION dwd.rebuild_ledger() TO service_role;

GRANT ALL ON FUNCTION dwd.trg_process_tx_borrow() TO anon;

GRANT ALL ON FUNCTION dwd.trg_process_tx_borrow() TO authenticated;

GRANT ALL ON FUNCTION dwd.trg_process_tx_borrow() TO service_role;

GRANT ALL ON FUNCTION dwd.trg_process_tx_cashflow() TO anon;

GRANT ALL ON FUNCTION dwd.trg_process_tx_cashflow() TO authenticated;

GRANT ALL ON FUNCTION dwd.trg_process_tx_cashflow() TO service_role;

GRANT ALL ON FUNCTION dwd.trg_process_tx_repay() TO anon;

GRANT ALL ON FUNCTION dwd.trg_process_tx_repay() TO authenticated;

GRANT ALL ON FUNCTION dwd.trg_process_tx_repay() TO service_role;

GRANT ALL ON FUNCTION dwd.trg_process_tx_stock() TO anon;

GRANT ALL ON FUNCTION dwd.trg_process_tx_stock() TO authenticated;

GRANT ALL ON FUNCTION dwd.trg_process_tx_stock() TO service_role;

GRANT ALL ON FUNCTION dwd.upsert_daily_asset_close() TO anon;

GRANT ALL ON FUNCTION dwd.upsert_daily_asset_close() TO authenticated;

GRANT ALL ON FUNCTION dwd.upsert_daily_asset_close() TO service_role;

GRANT DELETE, INSERT, SELECT, UPDATE ON dwd.daily_asset_close TO anon;

GRANT DELETE, INSERT, SELECT, UPDATE ON dwd.daily_asset_close TO authenticated;

GRANT DELETE, INSERT, SELECT, UPDATE ON dwd.daily_asset_close TO service_role;

GRANT DELETE, INSERT, SELECT, UPDATE ON dwd.daily_fxrate_close TO anon;

GRANT DELETE, INSERT, SELECT, UPDATE ON dwd.daily_fxrate_close TO authenticated;

GRANT DELETE, INSERT, SELECT, UPDATE ON dwd.daily_fxrate_close TO service_role;

GRANT DELETE, INSERT, SELECT, UPDATE ON dwd.tx_borrow TO anon;

GRANT DELETE, INSERT, SELECT, UPDATE ON dwd.tx_borrow TO authenticated;

GRANT DELETE, INSERT, SELECT, UPDATE ON dwd.tx_borrow TO service_role;

GRANT DELETE, INSERT, SELECT, UPDATE ON dwd.tx_cashflow TO anon;

GRANT DELETE, INSERT, SELECT, UPDATE ON dwd.tx_cashflow TO authenticated;

GRANT DELETE, INSERT, SELECT, UPDATE ON dwd.tx_cashflow TO service_role;

GRANT DELETE, INSERT, SELECT, UPDATE ON dwd.tx_entries TO anon;

GRANT DELETE, INSERT, SELECT, UPDATE ON dwd.tx_entries TO authenticated;

GRANT DELETE, INSERT, SELECT, UPDATE ON dwd.tx_entries TO service_role;

GRANT DELETE, INSERT, SELECT, UPDATE ON dwd.tx_legs TO anon;

GRANT DELETE, INSERT, SELECT, UPDATE ON dwd.tx_legs TO authenticated;

GRANT DELETE, INSERT, SELECT, UPDATE ON dwd.tx_legs TO service_role;

GRANT DELETE, INSERT, SELECT, UPDATE ON dwd.tx_repay TO anon;

GRANT DELETE, INSERT, SELECT, UPDATE ON dwd.tx_repay TO authenticated;

GRANT DELETE, INSERT, SELECT, UPDATE ON dwd.tx_repay TO service_role;

GRANT DELETE, INSERT, SELECT, UPDATE ON dwd.tx_stock TO anon;

GRANT DELETE, INSERT, SELECT, UPDATE ON dwd.tx_stock TO authenticated;

GRANT DELETE, INSERT, SELECT, UPDATE ON dwd.tx_stock TO service_role;

GRANT ALL ON FUNCTION dws.active_stock_tickers() TO anon;

GRANT ALL ON FUNCTION dws.active_stock_tickers() TO authenticated;

GRANT ALL ON FUNCTION dws.active_stock_tickers() TO service_role;

GRANT ALL ON FUNCTION dws.calculate_pnl(date, date) TO anon;

GRANT ALL ON FUNCTION dws.calculate_pnl(date, date) TO authenticated;

GRANT ALL ON FUNCTION dws.calculate_pnl(date, date) TO service_role;

GRANT ALL ON FUNCTION dws.calculate_twr(date, date) TO anon;

GRANT ALL ON FUNCTION dws.calculate_twr(date, date) TO authenticated;

GRANT ALL ON FUNCTION dws.calculate_twr(date, date) TO service_role;

GRANT ALL ON FUNCTION dws.get_equity_chart(date, date, integer) TO anon;

GRANT ALL ON FUNCTION dws.get_equity_chart(date, date, integer) TO authenticated;

GRANT ALL ON FUNCTION dws.get_equity_chart(date, date, integer) TO service_role;

GRANT ALL ON FUNCTION dws.get_return_chart(date, date, integer) TO anon;

GRANT ALL ON FUNCTION dws.get_return_chart(date, date, integer) TO authenticated;

GRANT ALL ON FUNCTION dws.get_return_chart(date, date, integer) TO service_role;

GRANT ALL ON FUNCTION dws.recompute_daily_snapshots(uuid, date) TO anon;

GRANT ALL ON FUNCTION dws.recompute_daily_snapshots(uuid, date) TO authenticated;

GRANT ALL ON FUNCTION dws.recompute_daily_snapshots(uuid, date) TO service_role;

GRANT ALL ON FUNCTION dws.trg_snapshots_fxrate() TO anon;

GRANT ALL ON FUNCTION dws.trg_snapshots_fxrate() TO authenticated;

GRANT ALL ON FUNCTION dws.trg_snapshots_fxrate() TO service_role;

GRANT ALL ON FUNCTION dws.trg_snapshots_prices() TO anon;

GRANT ALL ON FUNCTION dws.trg_snapshots_prices() TO authenticated;

GRANT ALL ON FUNCTION dws.trg_snapshots_prices() TO service_role;

GRANT ALL ON FUNCTION dws.trg_snapshots_tx_legs() TO anon;

GRANT ALL ON FUNCTION dws.trg_snapshots_tx_legs() TO authenticated;

GRANT ALL ON FUNCTION dws.trg_snapshots_tx_legs() TO service_role;

ALTER TABLE dws.daily_snapshots
  ENABLE ROW LEVEL SECURITY;

GRANT DELETE, INSERT, SELECT, UPDATE ON dws.daily_snapshots TO anon;

GRANT DELETE, INSERT, SELECT, UPDATE ON dws.daily_snapshots TO authenticated;

GRANT DELETE, INSERT, SELECT, UPDATE ON dws.daily_snapshots TO service_role;

CREATE POLICY "Enable users to view their own data only" ON dws.daily_snapshots
  TO authenticated
  USING ((( SELECT auth.uid() AS uid) = user_id));

GRANT DELETE, INSERT, SELECT, UPDATE ON ods.dnse_m1_close TO anon;

GRANT DELETE, INSERT, SELECT, UPDATE ON ods.dnse_m1_close TO authenticated;

GRANT DELETE, INSERT, SELECT, UPDATE ON ods.dnse_m1_close TO service_role;

GRANT DELETE, INSERT, SELECT, UPDATE ON ods.dnse_order_events TO anon;

GRANT DELETE, INSERT, SELECT, UPDATE ON ods.dnse_order_events TO authenticated;

GRANT DELETE, INSERT, SELECT, UPDATE ON ods.dnse_order_events TO service_role;

GRANT DELETE, INSERT, SELECT, UPDATE ON ods.news_articles TO anon;

GRANT DELETE, INSERT, SELECT, UPDATE ON ods.news_articles TO authenticated;

GRANT DELETE, INSERT, SELECT, UPDATE ON ods.news_articles TO service_role;

CREATE OR REPLACE TRIGGER after_new_m1_close
  AFTER INSERT ON ods.dnse_m1_close
  FOR EACH ROW
  EXECUTE FUNCTION dwd.upsert_daily_asset_close();

CREATE OR REPLACE TRIGGER after_filled_dnse_orders
  AFTER INSERT ON ods.dnse_order_events
  FOR EACH ROW
  EXECUTE FUNCTION dwd.process_dnse_order();