import { createServerFn } from '@tanstack/react-start'
import { getDnseClosePrice } from '@/lib/dnse/api/market-data'
import {
  getAssetIdsByTicker,
  getHeldStockTickers,
  upsertDailyAssetClose,
} from '@/lib/supabase/api/fund.supabase'

export type DnsePriceRow = {
  ticker: string
  close: number
  date: string
}

export type DnsePriceError = {
  ticker: string
  reason: string
}

export type PriceRefreshResult = {
  message: string
  updated: number
  failed: number
}

const VNINDEX_TICKER = 'VNINDEX'

export const refreshPrices = createServerFn({
  method: 'POST',
}).handler(async (): Promise<PriceRefreshResult> => {
  const heldTickers = await getHeldStockTickers()

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

  const results = await Promise.allSettled(
    mappedTickers.map(async (ticker) => {
      const response = await getDnseClosePrice(ticker)

      const priceEntry = response.prices.find((p) => p.boardId === 'G1')

      const closePrice = priceEntry?.closePrice

      if (closePrice === undefined || !Number.isFinite(closePrice)) {
        throw new Error(`Missing close price for ${ticker}`)
      }

      if (!priceEntry?.time) {
        throw new Error(`Missing valid price date for ${ticker}`)
      }

      return {
        ticker,
        close: closePrice,
        date: priceEntry.time.slice(0, 10),
      }
    }),
  )
  const rows: DnsePriceRow[] = []
  const errors: DnsePriceError[] = []

  results.forEach((result, index) => {
    const ticker = mappedTickers[index]

    if (result.status === 'fulfilled') {
      rows.push(result.value)
    } else {
      errors.push({
        ticker,
        reason:
          result.reason instanceof Error
            ? result.reason.message
            : String(result.reason),
      })
    }
  })

  failedTickers.push(...errors.map((error) => error.ticker))

  if (!rows.length) {
    throw new Error('Failed to fetch DNSE prices')
  }

  await upsertDailyAssetClose(
    rows.map((row) => ({
      asset_id: assetIdByTicker.get(row.ticker)!,
      close: row.close,
      date: row.date,
    })),
  )

  return {
    message:
      failedTickers.length > 0
        ? `Updated ${rows.length} price(s); failed ${failedTickers.length} ticker(s)`
        : `Updated ${rows.length} price(s)`,

    updated: rows.length,
    failed: failedTickers.length,
  }
})
