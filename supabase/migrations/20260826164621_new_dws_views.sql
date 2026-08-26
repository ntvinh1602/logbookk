-- Migration unit 1: schema_changes
-- Transaction mode: transactional
-- Boundary reason: default

CREATE VIEW dws.outstanding_debts WITH (security_invoker=true) AS SELECT b.tx_id,
    b.lender,
    b.principal,
    b.rate,
    round(((b.principal * power(((1)::numeric + ((b.rate / 100.0) / 365.0)), EXTRACT(day FROM ((CURRENT_DATE)::timestamp with time zone - e.created_at)))) - b.principal), 0) AS accrued_interest,
    e.created_at
   FROM (dwd.tx_borrow b
     JOIN dwd.tx_entries e ON (((e.id = b.tx_id) AND (e.user_id = auth.uid()))))
  WHERE (NOT (EXISTS ( SELECT 1
           FROM dwd.tx_repay r
          WHERE (r.borrow_tx = b.tx_id))));

CREATE VIEW dws.balance_sheet WITH (security_invoker=true) AS WITH user_legs AS (
         SELECT tl.tx_id,
            tl.asset_id,
            tl.quantity,
            tl.debit,
            tl.credit
           FROM (dwd.tx_legs tl
             JOIN dwd.tx_entries e ON ((e.id = tl.tx_id)))
          WHERE (e.user_id = auth.uid())
        ), debt_interest AS (
         SELECT sum(outstanding_debts.accrued_interest) AS sum
           FROM dws.outstanding_debts
        )
 SELECT a.ticker,
    a.name,
    a.asset_class,
    a.logo_url,
    a.currency_id,
    COALESCE(sum(ul.quantity), (0)::numeric) AS quantity,
    COALESCE((sum(ul.debit) - sum(ul.credit)), (0)::numeric) AS cost_basis,
        CASE
            WHEN (a.asset_class = ANY (ARRAY['stock'::dim.asset_class, 'fund'::dim.asset_class])) THEN round(sum((ul.quantity * COALESCE(sp.price, er.rate))), 0)
            WHEN (a.ticker = 'INTERESTS'::text) THEN ( SELECT sum(outstanding_debts.accrued_interest) AS sum
               FROM dws.outstanding_debts)
            ELSE sum(ul.quantity)
        END AS total_value,
    COALESCE(COALESCE(sp.price, er.rate), (0)::numeric) AS mkt_price,
    COALESCE(
        CASE
            WHEN (a.ticker = 'INTERESTS'::text) THEN (- ( SELECT sum(outstanding_debts.accrued_interest) AS sum
               FROM dws.outstanding_debts))
            ELSE round((sum((ul.quantity * COALESCE(sp.price, er.rate))) - (sum(ul.debit) - sum(ul.credit))), 0)
        END, (0)::numeric) AS net_profit
   FROM (((dim.asset a
     LEFT JOIN user_legs ul ON ((a.id = ul.asset_id)))
     LEFT JOIN LATERAL ( SELECT (dac.close * (1000)::numeric) AS price
           FROM dwd.daily_asset_close dac
          WHERE (dac.asset_id = a.id)
          ORDER BY dac.date DESC
         LIMIT 1) sp ON (true))
     LEFT JOIN LATERAL ( SELECT dfx.close AS rate
           FROM dwd.daily_fxrate_close dfx
          WHERE (dfx.currency_id = a.currency_id)
          ORDER BY dfx.date DESC
         LIMIT 1) er ON (true))
  GROUP BY a.ticker, a.name, a.logo_url, a.currency_id, a.asset_class, sp.price, er.rate
 HAVING ((abs(sum(ul.quantity)) > (0)::numeric) OR (a.ticker = 'INTERESTS'::text))
  ORDER BY a.asset_class;

GRANT ALL ON dws.balance_sheet TO anon;

GRANT ALL ON dws.balance_sheet TO authenticated;

GRANT ALL ON dws.balance_sheet TO service_role;

GRANT ALL ON dws.outstanding_debts TO anon;

GRANT ALL ON dws.outstanding_debts TO authenticated;

GRANT ALL ON dws.outstanding_debts TO service_role;