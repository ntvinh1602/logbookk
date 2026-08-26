import { createClient } from '@/lib/supabase/client'
import type {
  BenchmarkChartCols,
  BSheetView,
  EquityChartCols,
  NewsArticle,
  ProfitChartCols,
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
