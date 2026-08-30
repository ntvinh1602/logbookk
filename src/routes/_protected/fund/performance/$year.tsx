import { SingleOptionSelect } from '@/components/filter/select-options'
import { BenchmarkSection } from '@/features/fund/components/performance/benchmark-section'
import { CashflowSection } from '@/features/fund/components/performance/cashflow-section'
import { ExpenseChartSection } from '@/features/fund/components/performance/expense-chart-section'
import { NetProfitSection } from '@/features/fund/components/performance/netprofit-section'
import { TopStocksSection } from '@/features/fund/components/performance/top-stocks-section'
import { performance } from '@/features/fund/queries/performance'
import { useQueries } from '@tanstack/react-query'
import { createFileRoute, useNavigate } from '@tanstack/react-router'
import { Calendar } from 'lucide-react'

const START_YEAR = 2021

export const Route = createFileRoute('/_protected/fund/performance/$year')({
  component: Performance,
})

function Performance() {
  const { year } = Route.useParams()
  const navigate = useNavigate()

  const years = Array.from(
    { length: new Date().getFullYear() - START_YEAR + 1 },
    (_, i) => START_YEAR + i,
  ).reverse()

  const yearOptions = years.map((y) => ({
    key: y.toString(),
    label: y.toString(),
  }))

  const results = useQueries({
    queries: [
      performance.topStocks(year),
      performance.cashflowSummary(year),
      performance.benchmarkChart(year),
      performance.twrYear(year),
      performance.vniYear(year),
      performance.monthlyPnlChart(year),
    ],
  })

  const [
    topStocksQuery,
    cashflowSummaryQuery,
    benchmarkChartQuery,
    twrYearQuery,
    vniYearQuery,
    monthlyPnlChartQuery,
  ] = results

  return (
    <div className="flex flex-col max-w-screen-2xl mx-auto py-15 gap-8">
      <div className="flex justify-between">
        <h1 className="text-2xl font-bold">Annual Performance</h1>
        <div className="w-50">
          <SingleOptionSelect
            icon={Calendar}
            placeholder="Select year"
            value={year}
            onValueChange={(v) =>
              navigate({ to: '/fund/performance/$year', params: { year: v } })
            }
            options={yearOptions}
          />
        </div>
      </div>

      <div className="flex gap-4">
        <div className="flex flex-col w-1/3 gap-4">
          <CashflowSection
            data={cashflowSummaryQuery.data}
            isLoading={results.some((q) => q.isPending)}
          />
          <ExpenseChartSection
            monthlyPnlChart={monthlyPnlChartQuery.data}
            isLoading={results.some((q) => q.isPending)}
          />
        </div>

        <div className="flex flex-col w-1/3 gap-4">
          <BenchmarkSection
            benchmarkChart={benchmarkChartQuery.data}
            twrYear={twrYearQuery.data}
            vniYear={vniYearQuery.data}
            isLoading={results.some((q) => q.isPending)}
          />
          <NetProfitSection
            monthlyPnlChart={monthlyPnlChartQuery.data}
            isLoading={results.some((q) => q.isPending)}
          />
        </div>

        <div className="flex flex-col w-1/3 gap-4">
          <TopStocksSection
            data={topStocksQuery.data}
            isLoading={results.some((q) => q.isPending)}
          />
        </div>
      </div>
    </div>
  )
}
