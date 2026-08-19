import { EquityCard } from '@/features/fund/components/home/equity-card'
import { ChartPeriodToggle } from '@/features/fund/ui/chart-period-toggle'
import {
  DashboardDateRangeProvider,
  useDashboardDateRange,
} from '@/features/fund/components/home/chart-range-context'
import { createFileRoute } from '@tanstack/react-router'
import { ReturnChartSection } from '@/features/fund/components/home/return-chart-content'
import { PortfolioCard } from '@/features/fund/components/home/portfolio-card'
import { NewsSection } from '@/features/fund/components/home/news-section'
import { NetProfitChartSection } from '@/features/fund/components/home/netprofit-chart-content'
import { ReturnCard } from '@/features/fund/components/home/return-card'
import { NetProfitCard } from '@/features/fund/components/home/net-profit-card'
import { TotalAUMCard } from '@/features/fund/components/home/total-aum-card'
import { TradingViewMiniChart } from '@/features/fund/ui/trading-view-minichart'
import { Button } from '@/components/ui/button'
import { RefreshCw } from 'lucide-react'
import { toast } from 'sonner'
import { fetchPrices } from '@/features/fund/actions/fetch-price'
import { useState } from 'react'

export const Route = createFileRoute('/_protected/')({ component: Home })

const PERIOD_OPTIONS = [
  { value: 'last_3m', label: '3M' },
  { value: 'last_6m', label: '6M' },
  { value: 'last_1y', label: '1Y' },
  { value: 'all', label: 'All' },
]

function DashboardContent() {
  const { dateRange, setDateRange } = useDashboardDateRange()
  const [isRefreshing, setIsRefreshing] = useState(false)

  const handleRefresh = async () => {
    setIsRefreshing(true)
    const toastId = toast.loading('Fetching latest prices...')

    try {
      const data = await fetchPrices()

      toast.success(data.message, {
        id: toastId,
        description: `Updated items: ${data.updated}`,
      })
    } catch (err) {
      const message =
        err instanceof Error ? err.message : 'Failed to update prices'
      toast.error(message, { id: toastId })
    } finally {
      setIsRefreshing(false)
    }
  }

  return (
    <div className="flex flex-col max-w-screen-xl mx-auto py-15 gap-8">
      <div className="flex justify-between">
        <h1 className="text-2xl font-bold">Dashboard</h1>
      </div>
      <div className="flex flex-col gap-4">
        <div className="flex justify-between">
          <ChartPeriodToggle
            value={dateRange}
            onChange={setDateRange}
            options={PERIOD_OPTIONS}
          />
          <Button
            variant="outline"
            onClick={handleRefresh}
            disabled={isRefreshing}
          >
            <RefreshCw className={`${isRefreshing && 'animate-spin'}`} />
            Update Prices
          </Button>
        </div>
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
              <PortfolioCard />
              <NewsSection />
            </div>
          </div>
          <div className="flex flex-col gap-4 w-2/10">
            <div className="bg-card border h-50 rounded-xl overflow-hidden">
              <TradingViewMiniChart
                symbol="CAPITALCOM:XAUUSD"
                timeFrame="7D"
                className="h-55"
              />
            </div>
            <div className="bg-card border h-50 rounded-xl overflow-hidden">
              <TradingViewMiniChart
                symbol="BINANCE:BTCUSDT"
                timeFrame="7D"
                className="h-55"
              />
            </div>
            <div className="bg-card border h-50 rounded-xl overflow-hidden">
              <TradingViewMiniChart
                symbol="TVC:UKOIL"
                timeFrame="7D"
                className="h-55"
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
