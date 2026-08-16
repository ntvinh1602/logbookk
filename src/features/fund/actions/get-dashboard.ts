import { createClient } from "@/lib/supabase/client"
import type {
  EquityRollingView,
  BenchmarkRollingView,
  NewsArticle,
  BSheetView,
  ProfitView,
} from '@/features/fund/fund.types'

// Pnl & Expenses

export async function get1yProfit() {
  const { data, error } = await createClient().from('pnl_expense_last1y').select()

  if (error) throw new Error(error.message)
  return (data?.[0] ?? null) as ProfitView
}

// Balance Sheet & Portfolio

export async function getBalanceSheet() {
  const { data, error } = await createClient().from('balance_sheet').select()

  if (error) throw new Error(error.message)

  const bsData = (data ?? []) as BSheetView[]
  const fxVnd = bsData.find((r) => r.ticker === 'FX.VND')?.total_value || 0

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

// News

export async function getNews() {
  const { data, error } = await createClient()
    .from('news_articles')
    .select('id, title, url, source, excerpt, published_at, related_stocks')
    .order('published_at', { ascending: false })

  if (error) {
    console.error('NEWS FETCH ERROR:', error)
    throw new Error(error.message)
  }

  return (data?.map((article) => ({
    ...article,
    tickers: article.related_stocks ?? [],
  })) ?? []) as NewsArticle[]
}

// Equity & Benchmark

export async function getEquityRolling() {
  const { data, error } = await createClient().from('equity_rollings').select()

  if (error) throw new Error(error.message)
  return (data?.[0] ?? null) as EquityRollingView
}

export async function getBenchmarkRolling() {
  const { data, error } = await createClient().from('benchmark_rollings').select()

  if (error) throw new Error(error.message)
  return (data?.[0] ?? null) as BenchmarkRollingView
}
