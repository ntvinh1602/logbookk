import { SelectAllEnabled } from '@/components/filter/select-options'
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

export const Route = createFileRoute('/_protected/fund/performance')({
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
    <div className="flex flex-col max-w-screen-xl mx-auto py-15 gap-8">
      <div className="flex justify-between">
        <h1 className="text-2xl font-bold">Annual Performance</h1>
        <div className="w-50">
          <SelectAllEnabled
            icon={Calendar}
            placeholder="Select year"
            value={year?.toString() ?? null}
            onValueChange={(v) => setYear(v === null ? null : Number(v))}
            allLabel="All Years"
            options={yearOptions}
          />
        </div>
      </div>

      <div className="grid xl:grid-cols-2 gap-4 xl:gap-6">
        <div className="flex flex-col flex-1 gap-4">
          <NetProfitSection />
          <BenchmarkSection />
        </div>
        <div className="flex flex-col gap-4">
          <div className="grid sm:grid-cols-2 grid-cols-1 gap-4 h-fit">
            <CashflowSection />
            <ExpenseChartSection />
          </div>
          <TopStocksSection />
        </div>
      </div>
    </div>
  )
}

function RouteComponent() {
  return (
    <PerformanceYearProvider startYear={2021}>
      <PerformanceContent />
    </PerformanceYearProvider>
  )
}
