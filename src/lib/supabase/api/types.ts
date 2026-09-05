import type { Database } from '@/lib/supabase/supabase.types'
import type { FeatureCollection, LineString } from 'geojson'

type NonNullableExcept<T, TKeys extends keyof T = never> = {
  [P in keyof T]: P extends TKeys ? T[P] : NonNullable<T[P]>
}

// Fund

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

export type AssetSearchResult = {
  id: number
  ticker: string
  name: string
  currency: string
}

export type BSheetView = NonNullableExcept<
  Database['dws']['Views']['balance_sheet']['Row'],
  'logo_url'
>

export type NewsArticle = Database['ods']['Tables']['news_articles']['Row']

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

export type DailyAssetCloseInsert =
  Database['dwd']['Tables']['daily_asset_close']['Insert']

// Flights

export type AircraftRow = Database['dim']['Tables']['aircraft']['Row']
export type AirlineRow = Database['dim']['Tables']['airline']['Row']
export type AirportRow = Database['dim']['Tables']['airport']['Row']

export type TicketClass = 'eco' | 'biz'
export type SeatPosition = 'window' | 'middle' | 'aisle'

export type FlightsSummaryRow =
  Database['dws']['Views']['flights_summary']['Row']
export type Flight = NonNullableExcept<FlightsSummaryRow>

export type StatsRow = NonNullableExcept<
  Database['dws']['Views']['lifetime_stats']['Row']
>
export type RoutesGeoJSON = NonNullableExcept<
  Database['dws']['Views']['routes_geojson']['Row']
>

export type RoutesFeatureCollection = FeatureCollection<
  LineString,
  RoutesGeoJSON
>
