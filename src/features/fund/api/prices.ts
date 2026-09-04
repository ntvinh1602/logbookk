import { fetchDnseClosePrices } from '@/features/fund/actions/fetch-dnse-prices'
import {
  getAssetIdsByTicker,
  getHeldStockTickers,
  upsertDailyAssetClose,
} from '@/features/fund/api/supabase'
import type { PriceRefreshResult } from '../types'

const VNINDEX_TICKER = 'VNINDEX'

export async function refreshPrices(): Promise<PriceRefreshResult> {
  const heldTickers = await getHeldStockTickers()

  // VNINDEX is a benchmark index (not a holding), but its close still needs
  // refreshing for the return / benchmark charts.
  const tickers = heldTickers.includes(VNINDEX_TICKER)
    ? heldTickers
    : [...heldTickers, VNINDEX_TICKER]

  if (!tickers.length) {
    return {
      message: 'No stock assets to price',
      updated: 0,
      failed: 0,
    }
  }

  const assets = await getAssetIdsByTicker(tickers)

  const assetIdByTicker = new Map(
    assets.map((asset) => [asset.ticker, asset.id]),
  )

  const failedTickers = tickers.filter((ticker) => !assetIdByTicker.has(ticker))
  const mappedTickers = tickers.filter((ticker) => assetIdByTicker.has(ticker))

  if (!mappedTickers.length) {
    return {
      message: 'No mapped stock assets found for tickers',
      updated: 0,
      failed: failedTickers.length,
    }
  }

  const { rows, errors } = await fetchDnseClosePrices({ data: mappedTickers })

  if (errors.length) {
    for (const { ticker } of errors) {
      failedTickers.push(ticker)
    }
  }

  if (!rows.length) {
    const detail = errors
      .slice(0, 3)
      .map((e) => `${e.ticker}: ${e.reason}`)
      .join('; ')
    const suffix = errors.length > 3 ? ` (+${errors.length - 3} more)` : ''
    throw new Error(
      `Failed to fetch DNSE close prices for all ${errors.length} ticker(s): ${detail}${suffix}`,
    )
  }

  const inserts = rows.map((row) => ({
    asset_id: assetIdByTicker.get(row.ticker)!,
    close: row.close,
    date: row.date,
  }))

  await upsertDailyAssetClose(inserts)

  const updated = inserts.length
  const failed = failedTickers.length
  const message =
    failed > 0
      ? `Updated ${updated} price(s); failed ${failed} ticker(s)`
      : `Updated ${updated} price(s)`

  return {
    message,
    updated,
    failed,
  }
}
