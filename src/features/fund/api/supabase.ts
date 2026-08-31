import { createClient } from '@/lib/supabase/client'
import type {
  BenchmarkChartCols,
  BSheetView,
  CashflowSummary,
  EquityChartCols,
  EventBorrow,
  EventCashflow,
  EventRepay,
  NewsArticle,
  ProfitChartCols,
  EventStock,
  TopStocks,
} from '../fund.types'

export async function getCurrentEquity() {
  const supabase = createClient()

  const { data, error } = await supabase
    .schema('dws')
    .from('daily_snapshots')
    .select('total_equity')
    .order('snapshot_date', {
      ascending: false,
    })
    .limit(1)

  if (error) throw new Error(error.message)

  return Number(data?.[0]?.total_equity ?? 0)
}

export async function getPnl(startDate: string, endDate: string) {
  const supabase = createClient()

  const { data, error } = await supabase.schema('dws').rpc('calculate_pnl', {
    p_start_date: startDate,
    p_end_date: endDate,
  })

  if (error) throw new Error(error.message)

  return Number(data ?? 0)
}

export async function getTwr(startDate: string, endDate: string) {
  const supabase = createClient()

  const { data, error } = await supabase.schema('dws').rpc('calculate_twr', {
    p_start_date: startDate,
    p_end_date: endDate,
  })

  if (error) throw new Error(error.message)

  return Number(data ?? 0)
}

export async function getVniReturn(startDate: string, endDate: string) {
  const supabase = createClient()

  const { data, error } = await supabase
    .schema('dws')
    .rpc('calculate_vnindex_return', {
      p_start_date: startDate,
      p_end_date: endDate,
    })

  if (error) throw new Error(error.message)

  return Number(data ?? 0)
}

export async function getEquityChart(startDate: string, endDate: string) {
  const supabase = createClient()

  const { data, error } = await supabase.schema('dws').rpc('get_equity_chart', {
    p_start_date: startDate,
    p_end_date: endDate,
  })

  if (error) throw new Error(error.message)

  return data ?? ({} as EquityChartCols)
}

export async function getBenchmarkChart(startDate: string, endDate: string) {
  const supabase = createClient()

  const { data, error } = await supabase.schema('dws').rpc('get_return_chart', {
    p_start_date: startDate,
    p_end_date: endDate,
  })

  if (error) throw new Error(error.message)

  return data ?? ({} as BenchmarkChartCols)
}

export async function getMonthlyPnlChart(startDate: string, endDate: string) {
  const supabase = createClient()

  const { data, error } = await supabase
    .schema('dws')
    .rpc('get_monthly_pnl_chart', {
      p_start_date: startDate,
      p_end_date: endDate,
    })

  if (error) throw new Error(error.message)

  return data ?? ({} as ProfitChartCols)
}

export async function getBalanceSheet() {
  const supabase = createClient()

  const { data, error } = await supabase
    .schema('dws')
    .from('balance_sheet')
    .select()

  if (error) throw new Error(error.message)

  const bsData = (data ?? []) as BSheetView[]
  const fxVnd = bsData
    .filter((r) => r.ticker === 'FX.VND')
    .reduce((sum, r) => sum + r.total_value, 0)

  bsData.push({
    ticker: 'MARGIN',
    name: 'Margin',
    asset_class: 'liability',
    logo_url: null,
    currency_code: 'VND',
    quantity: 0,
    total_value: Math.max(-fxVnd, 0),
    mkt_price: 0,
    net_profit: 0,
  })

  const unrealized = bsData.reduce((sum, r) => sum + r.net_profit, 0)

  bsData.push({
    ticker: 'UNREALIZED',
    name: 'Unrealized PnL',
    asset_class: 'equity',
    logo_url: null,
    currency_code: 'VND',
    quantity: 0,
    total_value: unrealized,
    mkt_price: 0,
    net_profit: 0,
  })

  return bsData
}

export async function getNews() {
  const supabase = createClient()

  const { data, error } = await supabase
    .schema('ods')
    .from('news_articles')
    .select('id, title, url, source, excerpt, published_at, related_stocks')
    .order('published_at', { ascending: false })

  if (error) throw new Error(error.message)

  return (data?.map((article) => ({
    ...article,
    tickers: article.related_stocks ?? [],
  })) ?? []) as NewsArticle[]
}

export async function getCashflow(
  startDate: string,
  endDate: string,
): Promise<CashflowSummary> {
  const supabase = createClient()

  const { data, error } = await supabase
    .schema('dws')
    .rpc('get_cashflow_summary', {
      p_start_date: startDate,
      p_end_date: endDate,
    })

  if (error) throw new Error(error.message)

  const row = data?.[0]

  return {
    deposits: Number(row?.deposits ?? 0),
    withdrawals: Number(row?.withdrawals ?? 0),
  }
}

export async function getTopStocks(
  startDate: string,
  endDate: string,
): Promise<TopStocks[]> {
  const supabase = createClient()

  const { data, error } = await supabase.schema('dws').rpc('get_top_stocks', {
    p_start_date: startDate,
    p_end_date: endDate,
  })

  if (error) throw new Error(error.message)

  return (data ?? []) as TopStocks[]
}

export async function getStockEvents(
  startDate?: string,
  endDate?: string,
  ticker?: string,
  operation?: string,
): Promise<EventStock[]> {
  const supabase = createClient()

  const { data, error } = await supabase.schema('dws').rpc('get_event_stock', {
    p_start_date: startDate ?? null,
    p_end_date: endDate ?? null,
    p_ticker: ticker ?? null,
    p_operation: operation ?? null,
  })

  if (error) throw new Error(error.message)

  return (data ?? []) as EventStock[]
}

export async function getCashflowEvents(
  startDate?: string,
  endDate?: string,
  operation?: string,
): Promise<EventCashflow[]> {
  const supabase = createClient()

  const { data, error } = await supabase
    .schema('dws')
    .rpc('get_event_cashflow', {
      p_start_date: startDate ?? null,
      p_end_date: endDate ?? null,
      p_operation: operation ?? null,
    })

  if (error) throw new Error(error.message)

  return (data ?? []) as EventCashflow[]
}

export async function getBorrowEvents(): Promise<EventBorrow[]> {
  const supabase = createClient()

  const { data, error } = await supabase.schema('dws').rpc('get_event_borrow')

  if (error) throw new Error(error.message)

  return (data ?? []) as EventBorrow[]
}

export async function getRepayEvents(): Promise<EventRepay[]> {
  const supabase = createClient()

  const { data, error } = await supabase.schema('dws').rpc('get_event_repay')

  if (error) throw new Error(error.message)

  return (data ?? []) as EventRepay[]
}
