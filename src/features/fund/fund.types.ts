import { type Tables } from "@/types/database.types"

export type CashflowView = {
  [K in keyof Tables<"cashflow_all">]: NonNullable<Tables<"cashflow_all">[K]>
}

export type StockPnl = {
  [K in keyof Tables<"stock_pnl_all">]: NonNullable<Tables<"stock_pnl_all">[K]>
}

export type ProfitView = {
  [K in keyof Tables<"pnl_expense_all">]: NonNullable<
    Tables<"pnl_expense_all">[K]
  >
}

export type BenchmarkView = {
  [K in keyof Tables<"benchmark_all">]: NonNullable<Tables<"benchmark_all">[K]>
}

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