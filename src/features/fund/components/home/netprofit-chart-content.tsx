import { use1yProfit } from '@/features/fund/hooks/use-dashboard-data'
import type { ProfitChartCols } from '@/features/fund/fund.types'
import { NetProfitChart } from '@/features/fund/ui/netprofit-chart'
import { FullChartSkeleton } from '@/components/skeletons/chart-card'
import StatusLabel from '@/components/status-label'

export function NetProfitChartSection() {
  const { data, error, isLoading } = use1yProfit()

  if (isLoading)
    return (
      <FullChartSkeleton
        name="Net Profit"
        stat1="avg. profit"
        stat2="avg. cost"
      >
        <StatusLabel type="loading" />
      </FullChartSkeleton>
    )
  if (error || !data) return <StatusLabel type="error" />

  const profit = data.profit_chart as ProfitChartCols | null
  if (!profit?.snapshot_date) return null
  const chartRows = profit.snapshot_date.map((snapshot_date, i) => ({
    snapshot_date,
    revenue: profit.revenue[i],
    fee: profit.fee[i],
    interest: profit.interest[i],
    tax: profit.tax[i],
  }))
  const meta = { name: 'Net Profit', stat1: 'avg. profit', stat2: 'avg. cost' }
  return (
    <NetProfitChart
      meta={meta}
      totalPnl={data.total_pnl}
      avgProfit={data.avg_profit}
      avgExpense={data.avg_expense}
      chartRows={chartRows}
    />
  )
}
