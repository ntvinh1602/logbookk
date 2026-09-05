import { cn, compactNum } from '@/lib/utils'
import { Badge } from '@/components/ui/badge'
import { MoveDownLeft, MoveUpRight } from 'lucide-react'
import StatusLabel from '@/components/status-label'
import { EquityChartConvert } from '../../utils'
import type { BSheetView, EquityChartCols } from '@/lib/supabase/api/types'
import {
  Card,
  CardContent,
  CardDescription,
  CardFooter,
  CardHeader,
} from '@/components/ui/card'
import { YAxis, Area, AreaChart, XAxis } from 'recharts'
import {
  type ChartConfig,
  ChartContainer,
  ChartTooltip,
  ChartTooltipContent,
} from '@/components/ui/chart'
import { useIsMobile } from '@/hooks/use-mobile'
import { format } from 'date-fns'

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
        'pointer-events-none px-0',
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
  const isMobile = useIsMobile()

  if (isLoading) return <StatusLabel type="loading" />
  if (!balanceSheet) return null

  const equityChartConfig = {
    net_equity: {
      label: 'Equity',
      color: 'var(--chart-1)',
    },
    cumulative_cashflow: {
      label: 'Deposit',
      color: 'var(--chart-2)',
    },
  } as ChartConfig

  const dataKeys = Object.keys(equityChartConfig)

  return (
    <div className="h-50 w-full flex rounded-xl border bg-card items-center">
      <Card className="h-full min-w-50 border-0 ring-0 shadow-none">
        <CardHeader>
          <CardDescription>Equity</CardDescription>
        </CardHeader>
        <CardContent>
          <p className="text-3xl font-semibold">{compactNum(equity ?? 0, 4)}</p>
        </CardContent>
        <CardFooter className="flex flex-col items-start">
          <PnlBadge value={pnlMtd ?? 0} period="month" />
          <PnlBadge value={pnlYtd ?? 0} period="year" />
        </CardFooter>
      </Card>

      <div className="relative min-w-0 flex-1">
        <div className="absolute inset-y-0 left-0 z-10 w-6 bg-gradient-to-r from-card to-transparent" />

        <ChartContainer config={equityChartConfig} className="py-4">
          <AreaChart
            data={equityChart ? EquityChartConvert(equityChart) : []}
            margin={{}}
          >
            <XAxis dataKey="t" hide />
            <YAxis
              domain={[
                (dataMin: number) => Number(dataMin),
                (dataMax: number) => Number(dataMax),
              ]}
              hide
            />
            {dataKeys.map((key) => (
              <div key={key}>
                <Area
                  dataKey={key}
                  type="natural"
                  connectNulls={true}
                  stroke={`var(--color-${key})`}
                  strokeWidth={1.5}
                  fill={`url(#fill-${key})`}
                  dot={false}
                />
                <linearGradient
                  id={`fill-${key}`}
                  x1="0"
                  y1="0"
                  x2="0"
                  y2="1"
                >
                  <stop
                    offset="0%"
                    stopColor={`var(--color-${key})`}
                    stopOpacity={0.5}
                  />
                  <stop
                    offset="100%"
                    stopColor={`var(--color-${key})`}
                    stopOpacity={0}
                  />
                </linearGradient>
              </div>
            ))}
            {!isMobile && (
              <ChartTooltip
                cursor={true}
                content={
                  <ChartTooltipContent
                    labelKey="t"
                    labelFormatter={(_label, payload) => {
                      const timestamp = payload?.[0]?.payload?.t as number | undefined
                      return timestamp ? format(new Date(timestamp), 'dd MMM yyyy') : ''
                    }}
                  />
                }
              />
            )}
          </AreaChart>
        </ChartContainer>
      </div>
    </div>
  )
}
