import { queryOptions } from '@tanstack/react-query'
import {
  format,
  startOfMonth,
  startOfYear,
  subMonths,
  subYears,
} from 'date-fns'

import {
  getBalanceSheet,
  getBenchmarkChart,
  getCurrentEquity,
  getEquityChart,
  getMonthlyPnlChart,
  getNews,
  getPnl,
  getTwr,
  getVniReturn,
} from '@/features/fund/api/dashboard'

export const dashboardKeys = {
  all: ['dashboard'] as const,

  totalEquity: () => [...dashboardKeys.all, 'total-equity'] as const,
  balanceSheet: () => [...dashboardKeys.all, 'balance-sheet'] as const,
  equityChart: () => [...dashboardKeys.all, 'equity-chart'] as const,
  benchmarkChart: () => [...dashboardKeys.all, 'benchmark-chart'] as const,
  monthlyPnlChart: () => [...dashboardKeys.all, 'monthly-pnl-chart'] as const,
  news: () => [...dashboardKeys.all, 'news'] as const,

  pnl: () => [...dashboardKeys.all, 'pnl'] as const,
  pnlMtd: () => [...dashboardKeys.pnl(), 'mtd'] as const,
  pnlYtd: () => [...dashboardKeys.pnl(), 'ytd'] as const,
  pnlLast12m: () => [...dashboardKeys.pnl(), 'last12m'] as const,

  twr: () => [...dashboardKeys.all, 'twr'] as const,
  twrYtd: () => [...dashboardKeys.twr(), 'ytd'] as const,
  twrLast1y: () => [...dashboardKeys.twr(), 'last1y'] as const,

  vni: () => [...dashboardKeys.all, 'vni'] as const,
  vniYtd: () => [...dashboardKeys.vni(), 'ytd'] as const,
}

const today = () => new Date()

const formatDate = (date: Date) => format(date, 'yyyy-MM-dd')

export const dashboard = {
  totalEquity: () =>
    queryOptions({
      queryKey: dashboardKeys.totalEquity(),
      queryFn: getCurrentEquity,
    }),

  balanceSheet: () =>
    queryOptions({
      queryKey: dashboardKeys.balanceSheet(),
      queryFn: getBalanceSheet,
    }),

  equityChart: () =>
    queryOptions({
      queryKey: dashboardKeys.equityChart(),
      queryFn: () =>
        getEquityChart(formatDate(subYears(today(), 1)), formatDate(today())),
    }),

  benchmarkChart: () =>
    queryOptions({
      queryKey: dashboardKeys.benchmarkChart(),
      queryFn: () =>
        getBenchmarkChart(
          formatDate(subYears(today(), 1)),
          formatDate(today()),
        ),
    }),

  monthlyPnlChart: () =>
    queryOptions({
      queryKey: dashboardKeys.monthlyPnlChart(),
      queryFn: () =>
        getMonthlyPnlChart(
          formatDate(startOfMonth(subMonths(today(), 11))),
          formatDate(today()),
        ),
    }),

  news: () =>
    queryOptions({
      queryKey: dashboardKeys.news(),
      queryFn: getNews,
    }),

  pnlMtd: () =>
    queryOptions({
      queryKey: dashboardKeys.pnlMtd(),
      queryFn: () =>
        getPnl(formatDate(startOfMonth(today())), formatDate(today())),
    }),

  pnlYtd: () =>
    queryOptions({
      queryKey: dashboardKeys.pnlYtd(),
      queryFn: () =>
        getPnl(formatDate(startOfYear(today())), formatDate(today())),
    }),

  pnlLast12m: () =>
    queryOptions({
      queryKey: dashboardKeys.pnlLast12m(),
      queryFn: () =>
        getPnl(
          formatDate(startOfMonth(subMonths(today(), 11))),
          formatDate(today()),
        ),
    }),

  twrYtd: () =>
    queryOptions({
      queryKey: dashboardKeys.twrYtd(),
      queryFn: () =>
        getTwr(formatDate(startOfYear(today())), formatDate(today())),
    }),

  twrLast1y: () =>
    queryOptions({
      queryKey: dashboardKeys.twrLast1y(),
      queryFn: () =>
        getTwr(formatDate(subYears(today(), 1)), formatDate(today())),
    }),

  vniYtd: () =>
    queryOptions({
      queryKey: dashboardKeys.vniYtd(),
      queryFn: () =>
        getVniReturn(formatDate(startOfYear(today())), formatDate(today())),
    }),
}
