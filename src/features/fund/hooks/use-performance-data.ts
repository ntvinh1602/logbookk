import { useQuery } from '@tanstack/react-query'
import {
  getCashflow,
  getCashflowAllTime,
  getStocks,
  getStocksAll,
  getProfit,
  getProfitAllTime,
  getReturn,
  getReturnAllTime,
} from '@/actions/get-performance'
import type {
  CashflowView,
  StockPnl,
  ProfitView,
  BenchmarkView,
} from '@/features/fund/fund.types'

export function useCashflow(year: number | null) {
  return useQuery<CashflowView, Error>({
    queryKey: ['cashflow', year],
    queryFn: () => (year === null ? getCashflowAllTime() : getCashflow(year)),
    staleTime: Infinity,
  })
}

export function useStockPnl(year: number | null) {
  return useQuery<StockPnl[], Error>({
    queryKey: ['stock-pnl', year],
    queryFn: () => (year === null ? getStocksAll() : getStocks(year)),
    staleTime: Infinity,
  })
}

export function useProfit(year: number | null) {
  return useQuery<ProfitView, Error>({
    queryKey: ['profit', year],
    queryFn: () => (year === null ? getProfitAllTime() : getProfit(year)),
    staleTime: Infinity,
  })
}

export function useBenchmark(year: number | null) {
  return useQuery<BenchmarkView, Error>({
    queryKey: ['benchmark', year],
    queryFn: () => (year === null ? getReturnAllTime() : getReturn(year)),
    staleTime: Infinity,
  })
}
