import { EquityCard } from '@/features/fund/components/dashboard/equity-card'
import { createFileRoute } from '@tanstack/react-router'
import { ReturnChartSection } from '@/features/fund/components/dashboard/return-chart-content'
import { PortfolioCard } from '@/features/fund/components/dashboard/portfolio-card'
import { NewsSection } from '@/features/fund/components/dashboard/news-section'
import { NetProfitChartSection } from '@/features/fund/components/dashboard/netprofit-chart-content'
import { TotalAUMCard } from '@/features/fund/components/dashboard/total-aum-card'
import { TradingViewMiniChart } from '@/features/fund/components/dashboard/trading-view-minichart'
import { Button } from '@/components/ui/button'
import { RefreshCw } from 'lucide-react'
import { toast } from 'sonner'
import { fetchPrices } from '@/features/fund/actions/fetch-price'
import { useState } from 'react'
import { useQueries } from '@tanstack/react-query'
import { dashboard } from '@/features/fund/queries/dashboard'

export const Route = createFileRoute('/_protected/')({ component: Home })

function Home() {
  const [isRefreshing, setIsRefreshing] = useState(false)

  const results = useQueries({
    queries: [
      dashboard.balanceSheet(),
      dashboard.pnlMtd(),
      dashboard.pnlYtd(),
      dashboard.equityChart(),
      dashboard.benchmarkChart(),
      dashboard.twrYtd(),
      dashboard.vniYtd(),
      dashboard.monthlyPnlChart(),
      dashboard.news(),
    ],
  })

  const [
    balanceSheetQuery,
    pnlMtdQuery,
    pnlYtdQuery,
    equityChartQuery,
    benchmarkChartQuery,
    twrYtdQuery,
    vniYtdQuery,
    monthlyPnlChartQuery,
    newsQuery,
  ] = results

  if (!balanceSheetQuery.data) return null

  const bsData = balanceSheetQuery.data

  const equity = bsData
    .filter((r) => r.asset_class === 'equity')
    .reduce((sum, r) => sum + r.total_value, 0)

  const cash = bsData
    .filter((r) => r.asset_class == 'cash')
    .reduce((sum, r) => sum + r.total_value, 0)

  const stock = bsData
    .filter((r) => r.asset_class == 'stock')
    .reduce((sum, r) => sum + r.total_value, 0)

  const fund = bsData
    .filter((r) => r.asset_class == 'fund')
    .reduce((sum, r) => sum + r.total_value, 0)

  const asset = Math.max(cash, 0) + stock + fund
  const leverage = (asset - equity) / equity

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

  const miniChartSymbols = ['CAPITALCOM:XAUUSD', 'BINANCE:BTCUSDT', 'TVC:UKOIL']

  return (
    <div className="flex flex-col max-w-screen-xl mx-auto py-15 gap-8">
      <div className="flex justify-between">
        <h1 className="text-2xl font-bold">Dashboard</h1>
        <Button
          variant="outline"
          onClick={handleRefresh}
          disabled={isRefreshing}
        >
          <RefreshCw className={`${isRefreshing && 'animate-spin'}`} />
          Update Prices
        </Button>
      </div>

      <div className="flex gap-4">
        <div className="flex gap-4 w-8/10">
          <div className="flex flex-col gap-4 w-1/2">
            <PortfolioCard
              balanceSheet={balanceSheetQuery.data}
              totalAsset={asset}
              isLoading={balanceSheetQuery.isPending}
            />
            <NewsSection
              balanceSheet={balanceSheetQuery.data}
              news={newsQuery.data}
              isLoading={newsQuery.isPending}
            />
          </div>

          <div className="flex flex-col gap-4 w-1/2 ">
            <EquityCard
              balanceSheet={balanceSheetQuery.data}
              equity={equity}
              pnlMtd={pnlMtdQuery.data}
              pnlYtd={pnlYtdQuery.data}
              equityChart={equityChartQuery.data}
              isLoading={balanceSheetQuery.isPending}
            />
            <ReturnChartSection
              benchmarkChart={benchmarkChartQuery.data}
              twrYtd={twrYtdQuery.data}
              vniYtd={vniYtdQuery.data}
              isLoading={results.some((q) => q.isPending)}
            />
            <NetProfitChartSection
              monthlyPnlChart={monthlyPnlChartQuery.data}
              isLoading={monthlyPnlChartQuery.isPending}
            />
          </div>
        </div>

        <div className="flex flex-col gap-4 w-2/10">
          <TotalAUMCard
            totalAsset={asset}
            leverage={leverage}
            isLoading={balanceSheetQuery.isPending}
          />
          {miniChartSymbols.map((symbol) => (
            <div
              key={symbol}
              className="bg-card border h-50 rounded-xl overflow-hidden"
            >
              <TradingViewMiniChart
                symbol={symbol}
                timeFrame="7D"
                className="h-55"
              />
            </div>
          ))}
        </div>
      </div>
    </div>
  )
}
