import type { Database } from '@/types/database.types'

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

export type EventStock =
  Database['dws']['Functions']['get_event_stock']['Returns'][number]

export type EventCashflow =
  Database['dws']['Functions']['get_event_cashflow']['Returns'][number]

export type EventBorrow =
  Database['dws']['Functions']['get_event_borrow']['Returns'][number]

export type EventRepay =
  Database['dws']['Functions']['get_event_repay']['Returns'][number]

export type CashflowSummary =
  Database['dws']['Functions']['get_cashflow_summary']['Returns'][number]

export type TopStocks =
  Database['dws']['Functions']['get_top_stocks']['Returns'][number]

export type AssetSearchResult = {
  id: number
  ticker: string
  name: string
  currency: string
}

export type PriceRefreshResult = {
  message: string
  updated: number
  failed: number
}
