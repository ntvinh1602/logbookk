import { keepPreviousData, queryOptions } from '@tanstack/react-query'
import {
  getStockEvents,
  getCashflowEvents,
  getBorrowEvents,
  getRepayEvents,
  getAssets,
  getOutstandingDebts,
  getCashAssets,
} from '@/lib/supabase/api/fund.supabase'

export const eventKeys = {
  all: ['events'] as const,

  stockTx: (
    startDate?: string,
    endDate?: string,
    ticker?: string,
    operation?: string,
  ) =>
    [
      ...eventKeys.all,
      'stock-tx',
      { startDate, endDate, ticker, operation },
    ] as const,

  cashflowTx: (startDate?: string, endDate?: string, operation?: string) =>
    [
      ...eventKeys.all,
      'cashflow-tx',
      { startDate, endDate, operation },
    ] as const,

  borrowTx: () => [...eventKeys.all, 'borrow-tx'] as const,

  repayTx: () => [...eventKeys.all, 'repay-tx'] as const,

  assetSearch: (query: string) =>
    [...eventKeys.all, 'asset-search', 'stock', query] as const,

  outstandingDebts: () => [...eventKeys.all, 'outstanding-debts'] as const,

  cashAssets: () => [...eventKeys.all, 'cash-assets'] as const,
}

export const events = {
  stockTx: (
    startDate?: string,
    endDate?: string,
    ticker?: string,
    operation?: string,
  ) => {
    return queryOptions({
      queryKey: eventKeys.stockTx(startDate, endDate, ticker, operation),
      queryFn: () => getStockEvents(startDate, endDate, ticker, operation),
    })
  },

  cashflowTx: (startDate?: string, endDate?: string, operation?: string) => {
    return queryOptions({
      queryKey: eventKeys.cashflowTx(startDate, endDate, operation),
      queryFn: () => getCashflowEvents(startDate, endDate, operation),
    })
  },

  borrowTx: () => {
    return queryOptions({
      queryKey: eventKeys.borrowTx(),
      queryFn: () => getBorrowEvents(),
    })
  },

  repayTx: () => {
    return queryOptions({
      queryKey: eventKeys.repayTx(),
      queryFn: () => getRepayEvents(),
    })
  },

  assetSearch: (query: string) => {
    return queryOptions({
      queryKey: eventKeys.assetSearch(query),
      queryFn: () => getAssets(query, 'stock'),
      enabled: query.length >= 2,
      placeholderData: keepPreviousData,
    })
  },

  outstandingDebts: () => {
    return queryOptions({
      queryKey: eventKeys.outstandingDebts(),
      queryFn: () => getOutstandingDebts(),
      staleTime: Infinity,
    })
  },

  cashAssets: () => {
    return queryOptions({
      queryKey: eventKeys.cashAssets(),
      queryFn: () => getCashAssets(),
      staleTime: Infinity,
    })
  },
}
