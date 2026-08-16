import { EquityCard } from '@/features/fund/components/home/equity-card'
import { ChartPeriodToggle } from '@/features/fund/ui/chart-period-toggle'
import {
  DashboardDateRangeProvider,
  useDashboardDateRange,
} from '@/features/fund/components/home/chart-range-context'
import { createFileRoute } from '@tanstack/react-router'
import { ReturnChartSection } from '@/features/fund/components/home/return-chart-content'
import { TradingViewWidget } from '@/features/fund/components/home/trading-view'
import { PortfolioSection } from '@/features/fund/components/home/portfolio-section'
import { NewsSection } from '@/features/fund/components/home/news-section'
import { NetProfitChartSection } from '@/features/fund/components/home/netprofit-chart-content'
import { ReturnCard } from '@/features/fund/components/home/return-card'
import { NetProfitCard } from '@/features/fund/components/home/net-profit-card'
import { TotalAUMCard } from '@/features/fund/components/home/total-aum-card'

export const Route = createFileRoute('/_protected/')({ component: Home })

const PERIOD_OPTIONS = [
  { value: 'last_3m', label: '3M' },
  { value: 'last_6m', label: '6M' },
  { value: 'last_1y', label: '1Y' },
  { value: 'all', label: 'All' },
]

function DashboardContent() {
  const { dateRange, setDateRange } = useDashboardDateRange()

  return (
    <div className="flex flex-col max-w-screen-xl mx-auto py-15 gap-8">
      <div className="flex justify-between">
        <h1 className="text-2xl font-bold">Dashboard</h1>
      </div>
      <div className="flex flex-col gap-4">
        <ChartPeriodToggle
          value={dateRange}
          onChange={setDateRange}
          options={PERIOD_OPTIONS}
        />
        <div className="flex w-full gap-4">
          <EquityCard />
          <ReturnCard />
          <NetProfitCard />
          <TotalAUMCard />
        </div>
        <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
          <div className="flex flex-col gap-6">
            <ReturnChartSection />
          </div>
          <div className="flex flex-col gap-6">
            <PortfolioSection />
            <NetProfitChartSection />
          </div>
          <div className="flex flex-col gap-6">
            <NewsSection />
            <TradingViewWidget />
          </div>
        </div>
      </div>
    </div>
  )
}

function Home() {
  return (
    <DashboardDateRangeProvider>
      <DashboardContent />
    </DashboardDateRangeProvider>
  )
}
