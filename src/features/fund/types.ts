import type { Database } from '@/lib/supabase/supabase.types'
import type { NonNullableExcept } from '@/lib/utils'

// RPC Functions
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

export type CashflowSummary =
  Database['dws']['Functions']['get_cashflow_summary']['Returns'][number]
export type TopStocks =
  Database['dws']['Functions']['get_top_stocks']['Returns'][number]
export type StockEvents =
  Database['dws']['Functions']['get_event_stock']['Returns'][number]
export type BorrowEvents =
  Database['dws']['Functions']['get_event_borrow']['Returns'][number]
export type CashflowEvents =
  Database['dws']['Functions']['get_event_cashflow']['Returns'][number]
export type RepayEvents =
  Database['dws']['Functions']['get_event_repay']['Returns'][number]

// Views
export type BSheetView = NonNullableExcept<
  Database['dws']['Views']['balance_sheet']['Row'],
  'logo_url'
>

// Tables
export type NewsArticle = Database['ods']['Tables']['news_articles']['Row']
export type DailyAssetCloseInsert =
  Database['dwd']['Tables']['daily_asset_close']['Insert']

// Front-end
export type AssetSearchResult = {
  id: number
  ticker: string
  name: string
  currency: string
}
