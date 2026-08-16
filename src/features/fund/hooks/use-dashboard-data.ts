import { useQuery } from '@tanstack/react-query'
import {
  getEquityRolling,
  getBenchmarkRolling,
  getBalanceSheet,
  getNews,
  get1yProfit,
} from '@/features/fund/actions/get-dashboard'
import { getStockHoldings } from '@/features/fund/actions/get-stock-holdings'
import type {
  EquityRollingView,
  BenchmarkRollingView,
  BSheetView,
  NewsArticle,
  ProfitView,
} from '@/features/fund/fund.types'

export function useEquityRolling() {
  return useQuery<EquityRollingView | null, Error>({
    queryKey: ['equity-rolling'],
    queryFn: () => getEquityRolling(),
    staleTime: Infinity,
  })
}

export function useBenchmarkRolling() {
  return useQuery<BenchmarkRollingView | null, Error>({
    queryKey: ['benchmark-rolling'],
    queryFn: () => getBenchmarkRolling(),
    staleTime: Infinity,
  })
}

export function useBalanceSheet() {
  return useQuery<BSheetView[], Error>({
    queryKey: ['balance-sheet'],
    queryFn: () => getBalanceSheet(),
    staleTime: Infinity,
  })
}

export function useDashboardNews() {
  return useQuery<{ news: NewsArticle[]; stocks: { ticker: string }[] }, Error>(
    {
      queryKey: ['dashboard-news'],
      queryFn: async () => {
        const [news, stocks] = await Promise.all([
          getNews(),
          getStockHoldings(),
        ])
        return { news, stocks }
      },
      staleTime: Infinity,
    },
  )
}

export function use1yProfit() {
  return useQuery<ProfitView | null, Error>({
    queryKey: ['1y-profit'],
    queryFn: () => get1yProfit(),
    staleTime: Infinity,
  })
}
