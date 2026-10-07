import { EquityCard } from '@/features/fund/components/dashboard/equity-card'
import { createFileRoute } from '@tanstack/react-router'
import { ReturnCard } from '@/features/fund/components/dashboard/return-card'
import { AssetCard } from '@/features/fund/components/dashboard/assets-card'
import { NewsCard } from '@/features/fund/components/dashboard/news-card'
import { NetProfitCard } from '@/features/fund/components/dashboard/net-profit-card'
import { useQueries } from '@tanstack/react-query'
import { dashboard } from '@/features/fund/queries/dashboard'
import { TradingViewTickerTape } from '@/lib/trading-view/ticker-tape'

export const Route = createFileRoute('/_protected/fund/dashboard')({
  component: Home,
})

function Home() {
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

  const liability = bsData
    .filter((r) => r.asset_class === 'liability')
    .reduce((sum, r) => sum + r.total_value, 0)

  const miniChartSymbols = ['CAPITALCOM:XAUUSD', 'BINANCE:BTCUSDT', 'TVC:UKOIL']

  return (
    <div className="flex flex-col max-w-screen-sm lg:max-w-screen-lg px-2 md:px-0 mx-auto py-15 gap-8">
      <div className="flex justify-between">
        <h1 className="text-2xl font-bold">Dashboard</h1>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-4">
        <div className="flex flex-col gap-4 w-full ">
          <EquityCard
            balanceSheet={balanceSheetQuery.data}
            equity={equity}
            pnlMtd={pnlMtdQuery.data}
            pnlYtd={pnlYtdQuery.data}
            equityChart={equityChartQuery.data}
            isLoading={balanceSheetQuery.isPending}
          />
          <ReturnCard
            benchmarkChart={benchmarkChartQuery.data}
            twrYtd={twrYtdQuery.data}
            vniYtd={vniYtdQuery.data}
            isLoading={benchmarkChartQuery.isPending}
          />
          <AssetCard
            balanceSheet={balanceSheetQuery.data}
            equity={equity}
            liability={liability}
            isLoading={balanceSheetQuery.isPending}
          />
        </div>

        <div className="flex flex-col gap-4 w-full">
          <NetProfitCard
            monthlyPnlChart={monthlyPnlChartQuery.data}
            isLoading={monthlyPnlChartQuery.isPending}
          />
          <div className="w-full bg-card h-21 border rounded-xl overflow-hidden">
            <TradingViewTickerTape
              symbols={miniChartSymbols}
              hideChart={false}
              colorTheme='dark'
            />
          </div>
          <NewsCard
            balanceSheet={balanceSheetQuery.data}
            news={newsQuery.data}
            isLoading={newsQuery.isPending}
          />
        </div>
      </div>
    </div>
  )
}
