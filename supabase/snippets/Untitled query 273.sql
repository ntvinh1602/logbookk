
  select
    s.tx_id,
    e.created_at,
    s.operation::text,
    a.ticker,
    s.price,
    s.quantity,
    s.fee,
    s.tax,
    s.net_proceed
  from dwd.tx_entries e
  join dwd.tx_cashflow s
    on e.id = s.tx_id
  join dim.asset a
    on s.stock_id = a.id
  order by e.created_at desc;
