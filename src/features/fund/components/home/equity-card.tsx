import { useMemo } from 'react'
import { useDashboardDateRange } from './chart-range-context'
import { useEquityRolling } from '@/features/fund/hooks/use-dashboard-data'
import type {
  EquityChartCols,
  EquityRollingView,
} from '@/features/fund/fund.types'
import StatusLabel from '@/components/status-label'
import {
  Card,
  CardContent,
  CardDescription,
  CardHeader,
  CardTitle,
} from '@/components/ui/card'
import { cn, compactNum, formatNum } from '@/lib/utils'
import { Badge } from '@/components/ui/badge'
import { TinyAreaChart } from '@/components/charts/tiny-area-chart'
import { MoveDownLeft, MoveUpRight } from 'lucide-react'

function ResolvedIcon({ value }: { value: number }) {
  return value > 0 ? <MoveUpRight /> : <MoveDownLeft />
}
function colsToRows({ d, e, c }: EquityChartCols) {
  const out = new Array(d.length)
  for (let i = 0; i < d.length; i++) {
    out[i] = {
      t: d[i] * 86_400_000,
      net_equity: e[i],
      cumulative_cashflow: c[i],
    }
  }
  return out
}

function useEquityChartData(
  data: EquityRollingView | null | undefined,
  dateRange: string,
) {
  return useMemo(() => {
    if (!data) return null
    const chartData = data.equitychart
    const cols =
      chartData[dateRange as keyof typeof chartData] ?? chartData.last_1y
    if (!cols?.d) return null
    return {
      chartTimeframe: colsToRows(cols),
      totalEquity: data.total_equity,
      pnlMtd: data.pnl_mtd,
      pnlYtd: data.pnl_ytd,
    }
  }, [data, dateRange])
}

export function EquityCard() {
  const { dateRange } = useDashboardDateRange()
  const { data, error, isLoading } = useEquityRolling()
  const chartData = useEquityChartData(data, dateRange)

  if (isLoading) return <StatusLabel type="loading" />
  if (error) return <StatusLabel type="error" />
  if (!chartData) return null

  return (
    <div className="grid grid-cols-2 bg-card rounded-xl border items-center w-4/10">
      <Card className="shadow-none ring-0 gap-1 h-full">
        <CardHeader>
          <CardDescription>Equity</CardDescription>
          <CardTitle className="text-4xl font-semibold">
            {formatNum(chartData.totalEquity)}
          </CardTitle>
        </CardHeader>
        <CardContent className="-ml-2">
          <Badge
            variant="ghost"
            className={cn(
              chartData.pnlMtd > 0 ? 'text-positive' : 'text-negative',
              'pointer-events-none',
            )}
          >
            <ResolvedIcon value={chartData.pnlMtd} />
            {compactNum(chartData.pnlMtd)} this month
          </Badge>
          <Badge
            variant="ghost"
            className={cn(
              chartData.pnlYtd > 0 ? 'text-positive' : 'text-negative',
              'pointer-events-none',
            )}
          >
            <ResolvedIcon value={chartData.pnlYtd} />
            <p className="">{compactNum(chartData.pnlYtd)} this year</p>
          </Badge>
        </CardContent>
      </Card>
      <TinyAreaChart
        data={chartData.chartTimeframe}
        config={{
          net_equity: { label: 'Equity', color: 'var(--chart-1)' },
          cumulative_cashflow: { label: 'Deposit', color: 'var(--chart-2)' },
        }}
      />
    </div>
  )
}
