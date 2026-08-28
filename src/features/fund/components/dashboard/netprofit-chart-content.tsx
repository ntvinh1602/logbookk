import {
  Card,
  CardHeader,
  CardTitle,
  CardDescription,
  CardAction,
} from '@/components/ui/card'
import { Bar, BarChart, CartesianGrid, XAxis, YAxis } from 'recharts'
import {
  ChartContainer,
  ChartLegend,
  ChartLegendContent,
  ChartTooltip,
  ChartTooltipContent,
} from '@/components/ui/chart'
import { format } from 'date-fns'
import { useIsMobile } from '@/hooks/use-mobile'
import { cn, compactNum } from '@/lib/utils'
import type { ProfitChartCols } from '@/features/fund/fund.types'
import StatusLabel from '@/components/status-label'
import { Badge } from '@/components/ui/badge'

interface NetProfitChartSectionProps {
  monthlyPnlChart: ProfitChartCols | undefined
  isLoading: boolean
}

export function NetProfitChartSection({
  monthlyPnlChart,
  isLoading,
}: NetProfitChartSectionProps) {
  const isMobile = useIsMobile()

  if (isLoading) return <StatusLabel type="loading" />
  if (!monthlyPnlChart) return null

  const chartRows = monthlyPnlChart.snapshot_date.map((snapshot_date, i) => ({
    snapshot_date,
    revenue: monthlyPnlChart.revenue[i],
    fee: monthlyPnlChart.fee[i],
    interest: monthlyPnlChart.interest[i],
    tax: monthlyPnlChart.tax[i],
  }))

  const totalPnl = chartRows.reduce(
    (acc, row) => acc + row.revenue + row.fee + row.tax + row.interest,
    0,
  )
  const avgPnl = totalPnl / 12

  const chartConfig = {
    tax: { label: 'Tax', color: 'var(--chart-4)' },
    fee: { label: 'Fee', color: 'var(--chart-3)' },
    interest: { label: 'Interest', color: 'var(--chart-2)' },
    revenue: { label: 'Revenue', color: 'var(--chart-1)' },
  }
  const dataKeys = Object.keys(chartConfig)

  return (
    <Card className='gap-3 pb-0'>
      <CardHeader>
        <CardDescription>Net Profit</CardDescription>
        <CardTitle className="text-xl sm:text-2xl flex gap-1 items-baseline">
          {compactNum(totalPnl)}
          <Badge
            variant="ghost"
            className={cn(
              avgPnl > 0 ? 'text-positive' : 'text-negative',
              '-ml-2 pointer-events-none',
            )}
          >
            {compactNum(avgPnl)} monthly avg.
          </Badge>
        </CardTitle>
        <CardAction className="flex flex-col">
          <span className="text-xs text-muted-foreground">Last 12 months</span>
        </CardAction>
      </CardHeader>
      <ChartContainer config={chartConfig} className="w-full">
        <BarChart
          accessibilityLayer
          data={chartRows}
          layout="horizontal"
          margin={{}}
        >
          <CartesianGrid vertical={false} />
          <XAxis
            dataKey="snapshot_date"
            type="category"
            tickLine={false}
            tickMargin={4}
            axisLine={false}
            tickFormatter={(v: string) => format(new Date(v), 'MMM')}
            interval="preserveEnd"
            minTickGap={60}
          />
          <YAxis
            orientation="left"
            type="number"
            axisLine={false}
            tickLine={false}
            tickMargin={0}
            mirror={true}
            tickFormatter={(v) => compactNum(v)}
            tick={{
              fill: 'var(--muted-foreground)',
              className: 'opacity-80',
            }}
          />
          {!isMobile && (
            <ChartTooltip cursor={true} content={<ChartTooltipContent />} />
          )}
          <ChartLegend
            content={<ChartLegendContent className="p-2" />}
            position="insideBottomLeft"
          />
          {dataKeys.map((key) => (
            <Bar
              key={key}
              dataKey={key}
              stackId={key === 'revenue' ? undefined : 'a'}
              fill={`var(--color-${key})`}
            />
          ))}
        </BarChart>
      </ChartContainer>
    </Card>
  )
}
