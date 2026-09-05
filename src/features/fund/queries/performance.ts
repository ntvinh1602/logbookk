import { queryOptions } from '@tanstack/react-query'
import {
  endOfYear,
  format,
  startOfYear,
} from 'date-fns'

import {
  getCashflow,
  getTopStocks,
  getBenchmarkChart,
  getMonthlyPnlChart,
  getTwr,
  getVniReturn,
} from '@/lib/supabase/api/fund.supabase'

const formatDate = (date: Date) => format(date, 'yyyy-MM-dd')

function yearDateRange(year: string) {
  const yearDate = new Date(Number(year), 0, 1)
  return {
    startDate: formatDate(startOfYear(yearDate)),
    endDate: formatDate(endOfYear(yearDate)),
  }
}

export const performanceKeys = {
  all: ['performance'] as const,

  cashflowSummary: (year: string) =>
    [...performanceKeys.all, 'cashflow-summary', year] as const,

  topStocks: (year: string) =>
    [...performanceKeys.all, 'top-stocks', year] as const,

  benchmarkChart: (year: string) =>
    [...performanceKeys.all, 'benchmark-chart', year] as const,

  monthlyPnlChart: (year: string) =>
    [...performanceKeys.all, 'monthly-pnl-chart', year] as const,
  
  twrYear: (year: string) => [...performanceKeys.all, 'year', year] as const,
  
  vniYear: (year: string) => [...performanceKeys.all, 'vni-year', year] as const,
}

export const performance = {
  topStocks: (year: string) => {
    const { startDate, endDate } = yearDateRange(year)

    return queryOptions({
      queryKey: performanceKeys.topStocks(year),
      queryFn: () => getTopStocks(startDate, endDate),
    })
  },

  cashflowSummary: (year: string) => {
    const { startDate, endDate } = yearDateRange(year)

    return queryOptions({
      queryKey: performanceKeys.cashflowSummary(year),
      queryFn: () => getCashflow(startDate, endDate),
    })
  },

  benchmarkChart: (year: string) => {
    const { startDate, endDate } = yearDateRange(year)

    return queryOptions({
      queryKey: performanceKeys.benchmarkChart(year),
      queryFn: () => getBenchmarkChart(startDate, endDate),
    })
  },

  monthlyPnlChart: (year: string) => {
    const { startDate, endDate } = yearDateRange(year)

    return queryOptions({
      queryKey: performanceKeys.monthlyPnlChart(year),
      queryFn: () => getMonthlyPnlChart(startDate, endDate),
    })
  },

  twrYear: (year: string) => {
    const { startDate, endDate } = yearDateRange(year)

    return queryOptions({
      queryKey: performanceKeys.twrYear(year),
      queryFn: () => getTwr(startDate, endDate),
    })
  },

  vniYear: (year: string) => {
    const { startDate, endDate } = yearDateRange(year)

    return queryOptions({
      queryKey: performanceKeys.vniYear(year),
      queryFn: () => getVniReturn(startDate, endDate),
    })
  },
}
