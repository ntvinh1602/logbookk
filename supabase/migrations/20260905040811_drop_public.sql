-- Migration unit 1: schema_changes
-- Transaction mode: transactional
-- Boundary reason: default

SET check_function_bodies = false;

DROP FUNCTION public.active_stock_tickers();

DROP FUNCTION public.add_borrow_event(p_principal numeric, p_lender text, p_rate numeric, p_created_at timestamp WITH time zone);

DROP FUNCTION public.add_cashflow_event(p_operation text, p_asset_id uuid, p_quantity numeric, p_fx_rate numeric, p_memo text, p_created_at timestamp
  WITH time zone, p_user_id uuid);

DROP FUNCTION public.add_repay_event(p_repay_tx uuid, p_interest numeric, p_created_at timestamp WITH time zone);

DROP FUNCTION public.add_stock_event(p_side text, p_ticker text, p_price numeric, p_quantity numeric, p_fee numeric, p_tax numeric, p_user_id uuid, p_created_at timestamp
  WITH time zone);

DROP FUNCTION public.process_tx_borrow(p_tx_id uuid);

DROP FUNCTION public.process_tx_cashflow(p_tx_id uuid);

DROP FUNCTION public.process_tx_repay(p_tx_id uuid);

DROP FUNCTION public.process_tx_stock(p_tx_id uuid);

DROP FUNCTION public.rebuild_ledger();

DROP FUNCTION public.recompute_daily_snapshots(p_user_id uuid, p_from_date date);

DROP VIEW public.balance_sheet;

DROP VIEW public.benchmark_all;

DROP VIEW public.benchmark_rollings;

DROP VIEW public.benchmark_yearly;

DROP FUNCTION public.calculate_twr(p_start_date date, p_end_date date);

DROP FUNCTION public.get_return_chart(p_start_date date, p_end_date date, p_threshold integer);

DROP VIEW public.cashflow_all;

DROP VIEW public.cashflow_yearly;

DROP VIEW public.equity_rollings;

DROP FUNCTION public.calculate_pnl(p_start_date date, p_end_date date);

DROP FUNCTION public.get_equity_chart(p_start_date date, p_end_date date, p_threshold integer);

DROP VIEW public.outstanding_debts;

DROP VIEW public.pnl_expense_all;

DROP VIEW public.pnl_expense_last1y;

DROP VIEW public.pnl_expense_yearly;

DROP VIEW public.stock_pnl_all;

DROP VIEW public.stock_pnl_yearly;

DROP VIEW public.tx_summary;

DROP TRIGGER after_new_m1_close ON public.dnse_m1_close;

DROP FUNCTION public.upsert_historical_prices();

DROP TABLE public.dnse_m1_close;

DROP TRIGGER after_filled_dnse_orders ON public.dnse_order_events;

DROP FUNCTION public.process_dnse_order();

DROP TABLE public.dnse_order_events;

DROP TYPE public.dnse_order_status;

DROP TRIGGER after_new_fxrate_ins ON public.historical_fxrate;

DROP TRIGGER after_new_fxrate_upd ON public.historical_fxrate;

DROP FUNCTION public.trg_snapshots_fxrate();

DROP TRIGGER after_new_prices_ins ON public.historical_prices;

DROP TRIGGER after_new_prices_upd ON public.historical_prices;

DROP FUNCTION public.trg_snapshots_prices();

DROP TRIGGER after_new_tx_borrow ON public.tx_borrow;

DROP FUNCTION public.trg_process_tx_borrow();

DROP TRIGGER after_new_tx_cashflow ON public.tx_cashflow;

DROP FUNCTION public.trg_process_tx_cashflow();

DROP TRIGGER after_new_tx_legs ON public.tx_legs;

DROP FUNCTION public.trg_snapshots_tx_legs();

DROP TRIGGER after_new_tx_repay ON public.tx_repay;

DROP FUNCTION public.trg_process_tx_repay();

DROP TRIGGER after_new_tx_stock ON public.tx_stock;

DROP FUNCTION public.trg_process_tx_stock();

DROP POLICY "Auth users can read assets" ON public.assets;

DROP POLICY "Auth users can read currencies" ON public.currencies;

DROP POLICY "Enable users to view their own data only" ON public.daily_snapshots;

DROP TABLE public.daily_snapshots;

DROP POLICY "Enable read access for authenticated users only" ON public.historical_fxrate;

DROP TABLE public.historical_fxrate;

DROP POLICY "Enable read access for authenticated users only" ON public.historical_prices;

DROP TABLE public.historical_prices;

DROP POLICY "Enable read access for all users" ON public.news_articles;

DROP TABLE public.news_articles;

DROP POLICY "Enable users to insert their own borrow txs" ON public.tx_borrow;

DROP POLICY "Users can read their own borrow txs" ON public.tx_borrow;

DROP POLICY "Users can update their own borrow txs" ON public.tx_borrow;

DROP POLICY "Enable users to insert their own cashflow txs" ON public.tx_cashflow;

DROP POLICY "Users can read own cashflow txs" ON public.tx_cashflow;

DROP TABLE public.tx_cashflow;

DROP TYPE public.cashflow_ops;

DROP POLICY "Enable insert for users based on user_id" ON public.tx_entries;

DROP POLICY "Enable users to view their own data only" ON public.tx_entries;

DROP POLICY "Enable users to insert their own tx legs" ON public.tx_legs;

DROP POLICY "Users can read own legs" ON public.tx_legs;

DROP TABLE public.tx_legs;

DROP POLICY "Enable users to insert their own repay txs" ON public.tx_repay;

DROP POLICY "Users can read their own repay txs" ON public.tx_repay;

DROP TABLE public.tx_repay;

DROP TABLE public.tx_borrow;

DROP POLICY "Enable users to insert their own stock txs" ON public.tx_stock;

DROP POLICY "Users can read own stock txs" ON public.tx_stock;

DROP TABLE public.tx_stock;

DROP TYPE public.stock_ops;

DROP TABLE public.assets;

DROP TYPE public.asset_class;

DROP TABLE public.currencies;

DROP TABLE public.tx_entries;

DROP TYPE public.tx_category;

DROP POLICY "Enable users to view their own data only" ON public.user_settings;

DROP POLICY "Users can update their own settings" ON public.user_settings;

DROP TABLE public.user_settings;