import { queryOptions } from '@tanstack/react-query'
import {
  getStockEvents,
  getCashflowEvents,
  getBorrowEvents,
  getRepayEvents,
} from '@/features/fund/api/supabase'

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
}
