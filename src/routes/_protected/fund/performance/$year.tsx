import { SingleOptionSelect } from '@/components/filter/select-options'
import { BenchmarkSection } from '@/features/fund/components/performance/benchmark-section'
import { CashflowSection } from '@/features/fund/components/performance/cashflow-section'
import { ExpenseChartSection } from '@/features/fund/components/performance/expense-chart-section'
import { NetProfitSection } from '@/features/fund/components/performance/netprofit-section'
import { TopStocksSection } from '@/features/fund/components/performance/top-stocks-section'
import {
  PerformanceYearProvider,
  usePerformanceYear,
} from '@/features/fund/components/performance/year-context'
import { createFileRoute } from '@tanstack/react-router'
import { Calendar } from 'lucide-react'

export const Route = createFileRoute('/_protected/fund/performance/$year')({
  component: RouteComponent,
})

function PerformanceContent() {
  const { year, setYear, startYear } = usePerformanceYear()

  const years = Array.from(
    { length: new Date().getFullYear() - startYear + 1 },
    (_, i) => startYear + i,
  ).reverse()

  const yearOptions = years.map((y) => ({
    key: y.toString(),
    label: y.toString(),
  }))

  return (
    <div className="flex flex-col max-w-screen-2xl mx-auto py-15 gap-8">
      <div className="flex justify-between">
        <h1 className="text-2xl font-bold">Annual Performance</h1>
        <div className="w-50">
          <SingleOptionSelect
            icon={Calendar}
            placeholder="Select year"
            value={year.toString()}
            onValueChange={(v) => setYear(Number(v))}
            options={yearOptions}
          />
        </div>
      </div>

      <div className="flex gap-4">
        <div className="flex flex-col w-1/3 gap-4">
          <CashflowSection />
          <ExpenseChartSection />
        </div>

        <div className="flex flex-col w-1/3 gap-4">
          <BenchmarkSection />
          <NetProfitSection />
        </div>

        <div className="flex flex-col w-1/3 gap-4">
          <TopStocksSection />
        </div>
      </div>
    </div>
  )
}

function RouteComponent() {
  const { year } = Route.useParams()

  return (
    <PerformanceYearProvider startYear={2021} initialYear={Number(year)}>
      <PerformanceContent />
    </PerformanceYearProvider>
  )
}
