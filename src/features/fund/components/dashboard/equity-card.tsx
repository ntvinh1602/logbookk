import { cn, compactNum, formatNum } from '@/lib/utils'
import { Badge } from '@/components/ui/badge'
import { TinyAreaChart } from '@/components/charts/tiny-area-chart'
import { MoveDownLeft, MoveUpRight } from 'lucide-react'
import StatusLabel from '@/components/status-label'
import { EquityChartConvert } from '../../utils'
import type { BSheetView, EquityChartCols } from '@/features/fund/fund.types'

interface EquityCardProps {
  balanceSheet: BSheetView[] | undefined
  equity: number | undefined
  pnlMtd: number | undefined
  pnlYtd: number | undefined
  equityChart: EquityChartCols | undefined
  isLoading: boolean
}

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

export function EquityCard({
  balanceSheet,
  equity,
  pnlMtd,
  pnlYtd,
  equityChart,
  isLoading,
}: EquityCardProps) {
  if (isLoading) return <StatusLabel type="loading" />
  if (!balanceSheet) return null

  return (
    <div className="h-50 w-full flex rounded-xl border bg-card items-center">
      <div className="flex flex-col h-full justify-between py-6 pl-6">
        <p className="text-muted-foreground text-sm">Equity</p>
        <p className="text-3xl font-semibold">{formatNum(equity ?? 0)}</p>

        <div className="-ml-2 flex flex-col">
          <PnlBadge value={pnlMtd ?? 0} period="month" />
          <PnlBadge value={pnlYtd ?? 0} period="year" />
        </div>
      </div>

      <div className="relative min-w-0 flex-1">
        <div className="absolute inset-y-0 left-0 z-10 w-6 bg-gradient-to-r from-card to-transparent" />

        <TinyAreaChart
          data={EquityChartConvert(equityChart ?? ({} as EquityChartCols))}
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
