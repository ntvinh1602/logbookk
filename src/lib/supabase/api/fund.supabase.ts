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
  AssetSearchResult,
  DailyAssetCloseInsert,
} from './types'


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
    currency: 'VND',
    cost_basis: 0,
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
    currency: 'VND',
    cost_basis: 0,
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
    .select()
    .order('published_at', { ascending: false })

  if (error) throw new Error(error.message)

  return (data ?? []) as NewsArticle[]
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

export async function getAssets(query: string, assetClass: string) {
  const supabase = createClient()

  const { data, error } = await supabase
    .schema('dim')
    .from('asset')
    .select(
      `
      id,
      ticker,
      name,
      ...currency!inner(
        currency:iso_code
      )
      `,
    )
    .eq('asset_class', assetClass)
    .ilike('ticker', `%${query}%`)
    .limit(20)

  if (error) throw new Error(error.message)
  return (data ?? []) as AssetSearchResult[]
}

export async function getCashAssets() {
  const supabase = createClient()

  const { data, error } = await supabase
    .schema('dim')
    .from('asset')
    .select(
      `
      id,
      ticker,
      name,
      ...currency!inner(
        currency:iso_code
      )
      `,
    )
    .in('asset_class', ['cash', 'fund'])

  if (error) throw new Error(error.message)
  return (data ?? []) as AssetSearchResult[]
}

export async function addStockEvent(params: {
  side: string
  stockId: number
  price: number
  quantity: number
  fee: number
  tax: number
  createdAt?: string
}) {
  const supabase = createClient()

  const { error } = await supabase.schema('dwd').rpc('add_stock_event', {
    p_side: params.side,
    p_stock_id: params.stockId,
    p_price: params.price,
    p_quantity: params.quantity,
    p_fee: params.fee,
    p_tax: params.tax,
    p_created_at: params.createdAt ?? null,
  })

  if (error) throw new Error(error.message)
}

export async function addCashflowEvent(params: {
  operation: string
  assetId: number
  quantity: number
  fxRate: number
  memo?: string
  createdAt?: string
}) {
  const supabase = createClient()

  const { error } = await supabase.schema('dwd').rpc('add_cashflow_event', {
    p_operation: params.operation,
    p_asset_id: params.assetId,
    p_quantity: params.quantity,
    p_fx_rate: params.fxRate,
    p_memo: params.memo ?? null,
    p_created_at: params.createdAt ?? null,
  })

  if (error) throw new Error(error.message)
}

export async function addBorrowEvent(params: {
  principal: number
  lender: string
  rate: number
  createdAt?: string
}) {
  const supabase = createClient()

  const { error } = await supabase.schema('dwd').rpc('add_borrow_event', {
    p_principal: params.principal,
    p_lender: params.lender,
    p_rate: params.rate,
    p_created_at: params.createdAt ?? null,
  })

  if (error) throw new Error(error.message)
}

export async function addRepayEvent(params: {
  repayTx: number
  interest: number
  createdAt?: string
}) {
  const supabase = createClient()

  const { error } = await supabase.schema('dwd').rpc('add_repay_event', {
    p_repay_tx: params.repayTx,
    p_interest: params.interest,
    p_created_at: params.createdAt ?? null,
  })

  if (error) throw new Error(error.message)
}

export async function getOutstandingDebts() {
  const supabase = createClient()

  const { data, error } = await supabase
    .schema('dws')
    .from('outstanding_debts')
    .select('tx_id, lender, principal, rate')

  if (error) throw new Error(error.message)

  return data ?? []
}

export async function getHeldStockTickers(): Promise<string[]> {
  const supabase = createClient()

  const { data, error } = await supabase
    .schema('dws')
    .from('balance_sheet')
    .select('ticker')
    .eq('asset_class', 'stock')
    .gt('quantity', 0)

  if (error) throw new Error(error.message)

  return data.map((row) => row.ticker)
}

export async function getAssetIdsByTicker(
  tickers: string[],
): Promise<{ id: number; ticker: string }[]> {
  const supabase = createClient()

  const { data, error } = await supabase
    .schema('dim')
    .from('asset')
    .select('id, ticker')
    .in('ticker', tickers)

  if (error) throw new Error(error.message)

  return data
}

// Write
 
export async function upsertDailyAssetClose(rows: DailyAssetCloseInsert[]) {
  const supabase = createClient()

  const { error } = await supabase
    .schema('dwd')
    .from('daily_asset_close')
    .upsert(rows, { onConflict: 'asset_id,date' })

  if (error) throw new Error(error.message)
}
