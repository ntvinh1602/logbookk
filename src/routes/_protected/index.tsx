import { EquityCard } from '@/features/fund/components/home/equity-card'
import { ChartPeriodToggle } from '@/features/fund/ui/chart-period-toggle'
import {
  DashboardDateRangeProvider,
  useDashboardDateRange,
} from '@/features/fund/components/home/chart-range-context'
import { createFileRoute } from '@tanstack/react-router'
import { ReturnChartSection } from '@/features/fund/components/home/return-chart-content'
import { PortfolioSection } from '@/features/fund/components/home/portfolio-section'
import { NewsSection } from '@/features/fund/components/home/news-section'
import { NetProfitChartSection } from '@/features/fund/components/home/netprofit-chart-content'
import { ReturnCard } from '@/features/fund/components/home/return-card'
import { NetProfitCard } from '@/features/fund/components/home/net-profit-card'
import { TotalAUMCard } from '@/features/fund/components/home/total-aum-card'
import { TradingViewMiniChart } from '@/features/fund/ui/trading-view-minichart'

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
    <div className="flex flex-col max-w-screen-2xl mx-auto py-15 gap-8">
      <div className="flex justify-between">
        <h1 className="text-2xl font-bold">Dashboard</h1>
      </div>
      <div className="flex flex-col gap-4">
        <ChartPeriodToggle
          value={dateRange}
          onChange={setDateRange}
          options={PERIOD_OPTIONS}
        />
        <div className="flex gap-4 items-stretch">
          <div className="flex gap-4 w-8/10 ">
            <div className="flex w-1/2">
              <EquityCard />
            </div>
            <div className="flex gap-4 w-1/2 ">
              <ReturnCard />
              <NetProfitCard />
            </div>
          </div>
          <div className="w-2/10">
            <TotalAUMCard />
          </div>
        </div>

        <div className="flex gap-4">
          <div className="flex gap-4 w-8/10">
            <div className="flex flex-col gap-4 w-1/2 ">
              <ReturnChartSection />
              <NetProfitChartSection />
            </div>
            <div className="flex flex-col gap-4 w-1/2">
              <NewsSection />
              <PortfolioSection />
            </div>
          </div>
          <div className="flex flex-col gap-4 w-2/10">
            <div className="bg-card border h-60 rounded-xl overflow-hidden">
              <TradingViewMiniChart
                symbol="CAPITALCOM:XAUUSD"
                timeFrame="7D"
                className="h-65"
              />
            </div>
            <div className="bg-card border h-60 rounded-xl overflow-hidden">
              <TradingViewMiniChart
                symbol="BINANCE:BTCUSDT"
                timeFrame="7D"
                className="h-65"
              />
            </div>
            <div className="bg-card border h-60 rounded-xl overflow-hidden">
              <TradingViewMiniChart
                symbol="TVC:UKOIL"
                timeFrame="7D"
                className="h-65"
              />
            </div>
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
