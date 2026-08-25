import { cn, compactNum, formatNum } from '@/lib/utils'
import { Badge } from '@/components/ui/badge'
import { TinyAreaChart } from '@/components/charts/tiny-area-chart'
import { MoveDownLeft, MoveUpRight } from 'lucide-react'
import { useQueries } from '@tanstack/react-query'
import { dashboard } from '../../queries/dashboard'
import StatusLabel from '@/components/status-label'
import { EquityChartConvert } from '../../utils'

function PnlBadge({
  value,
  period,
}: {
  value: number
  period: 'month' | 'year'
}) {
  return (
    <Badge
      variant="ghost"
      className={cn(
        value > 0 ? 'text-positive' : 'text-negative',
        'pointer-events-none',
      )}
    >
      {value > 0 ? <MoveUpRight /> : <MoveDownLeft />}
      {compactNum(value)} this {period}
    </Badge>
  )
}

export function EquityCard() {
  const results = useQueries({
    queries: [
      dashboard.totalEquity(),
      dashboard.pnlMtd(),
      dashboard.pnlYtd(),
      dashboard.equityChart(),
    ],
  })

  const [equityQuery, pnlMtdQuery, pnlYtdQuery, equityChartQuery] = results

  const isLoading = results.some((query) => query.isPending)
  const isError = results.some((query) => query.isError)

  if (isLoading) return <StatusLabel type="loading" />
  if (isError) return <StatusLabel type="error" />

  const equity = equityQuery.data || 0
  const pnlMtd = pnlMtdQuery.data || 0
  const pnlYtd = pnlYtdQuery.data || 0
  const equityChart = equityChartQuery.data || {}

  return (
    <div className="h-full w-full flex rounded-xl border bg-card items-center">
      <div className="flex flex-col h-full justify-between py-6 pl-6">
        <p className="text-muted-foreground text-sm">Equity</p>
        <p className="text-3xl font-semibold">{formatNum(equity)}</p>

        <div className="-ml-2 flex flex-col">
          <PnlBadge value={pnlMtd} period="month" />
          <PnlBadge value={pnlYtd} period="year" />
        </div>
      </div>

      <div className="relative min-w-0 flex-1">
        <div className="absolute inset-y-0 left-0 z-10 w-6 bg-gradient-to-r from-card to-transparent" />

        <TinyAreaChart
          data={EquityChartConvert(equityChart)}
          config={{
            net_equity: {
              label: 'Equity',
              color: 'var(--chart-1)',
            },
            cumulative_cashflow: {
              label: 'Deposit',
              color: 'var(--chart-2)',
            },
          }}
        />
      </div>
    </div>
  )
}
