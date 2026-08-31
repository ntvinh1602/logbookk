// Columnar equity series: keys stored once, not per-point.
export type ProfitChartCols = {
  snapshot_date: string[]
  revenue: number[]
  fee: number[]
  interest: number[]
  tax: number[]
}

export type EquityChartCols = {
  d: number[] // d = epoch-days (int)
  e: number[] // e = net_equity (rounded)
  c: number[] // c = cumulative_cashflow (rounded)
}

export type BenchmarkChartCols = {
  d: number[] // epoch-days
  p: number[] // portfolio_value (normalized, 2dp)
  v: number[] // vni_value (normalized, 2dp)
}

export interface BSheetView {
  ticker: string
  name: string
  asset_class: string
  logo_url: string | null
  currency_code: string
  quantity: number
  total_value: number
  mkt_price: number
  net_profit: number
}

export type NewsArticle = {
  id: string
  title: string
  url: string
  source: string
  excerpt: string
  published_at: string
  tickers?: string[]
}

export interface EventStock {
  tx_id: number
  created_at: string
  operation: string
  ticker: string
  price: number
  quantity: number
  fee: number
  tax: number
  net_proceed: number
  logo_url: string
  name: string
}

export interface EventCashflow {
  tx_id: number
  created_at: string
  operation: string
  memo: string
  ticker: string
  currency: string
  quantity: number
  net_proceed: number
}

export interface EventBorrow {
  tx_id: number
  created_at: string
  lender: string
  principal: number
  rate: number
}

export interface EventRepay {
  tx_id: number
  created_at: string
  borrow_tx: number
  lender: string
  principal: number
  interest: number
}

export interface CashflowSummary {
  deposits: number
  withdrawals: number
}

export interface TopStocks {
  ticker: string
  name: string
  logo_url: string
  total_pnl: number
}
