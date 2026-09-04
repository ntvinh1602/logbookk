import { createServerFn } from '@tanstack/react-start'

import { getDnseClosePrice } from '@/lib/dnse/api/market-data'

export type DnsePriceRow = {
  ticker: string
  close: number
  date: string
}

type DnsePriceError = {
  ticker: string
  reason: string
}

export type FetchDnsePricesResult = {
  rows: DnsePriceRow[]
  errors: DnsePriceError[]
}

/**
 * Fetches the latest DNSE close price for each ticker. Runs server-side
 * because DNSE signing reads server-only secrets. Individual ticker failures
 * are collected and returned, never thrown.
 *
 * Note: `close` is the raw DNSE value. Consumers in the DW (`dws.balance_sheet`,
 * `dws.recompute_daily_snapshots`) multiply `dwd.daily_asset_close.close * 1000`
 * to get the VND price, so we must NOT scale here.
 */
export const fetchDnseClosePrices = createServerFn({ method: 'POST' })
  .validator((tickers: string[]) => tickers)
  .handler(async ({ data: tickers }) => {
    const results = await Promise.allSettled(
      tickers.map(async (ticker) => {
        const response = await getDnseClosePrice(ticker)
        const priceEntry = response.prices.find((p) => p.boardId === 'G1')
        const closePrice = priceEntry?.closePrice

        if (closePrice === undefined || !Number.isFinite(closePrice)) {
          throw new Error(`Missing close price for ${ticker}`)
        }

        if (!priceEntry?.time) {
          throw new Error(`Missing valid price date for ${ticker}`)
        }

        const row: DnsePriceRow = {
          ticker,
          close: closePrice,
          date: priceEntry.time.slice(0, 10),
        }
        return row
      }),
    )

    const rows: DnsePriceRow[] = []
    const errors: DnsePriceError[] = []

    results.forEach((result, index) => {
      if (result.status === 'fulfilled') {
        rows.push(result.value)
        return
      }

      const reason =
        result.reason instanceof Error
          ? result.reason.message
          : String(result.reason)
      errors.push({ ticker: tickers[index], reason })
    })

    return { rows, errors } satisfies FetchDnsePricesResult
  })
