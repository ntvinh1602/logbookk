import { useMemo } from 'react'
import { usePerformanceYear } from './year-context'
import { useProfit } from '@/features/fund/hooks/use-performance-data'
import type { ProfitView, ProfitChartCols } from '@/features/fund/fund.types'
import StatusLabel from '@/components/status-label'
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
import { cn, compactNum, formatNum } from '@/lib/utils'

type ProfitChartRow = {
  snapshot_date: string
  revenue: number
  fee: number
  interest: number
  tax: number
}

function columnsToRows(cols: ProfitChartCols): ProfitChartRow[] {
  return cols.snapshot_date.map((snapshot_date, i) => ({
    snapshot_date,
    revenue: cols.revenue[i],
    fee: cols.fee[i],
    interest: cols.interest[i],
    tax: cols.tax[i],
  }))
}

function useNetProfitChartData(data: ProfitView | undefined) {
  return useMemo(() => {
    if (!data) return null
    const profitChart = data.profit_chart as ProfitChartCols | null
    if (!profitChart?.snapshot_date) return null
    return {
      totalPnl: data.total_pnl,
      avgProfit: data.avg_profit,
      avgExpense: data.avg_expense,
      chartRows: columnsToRows(profitChart),
    }
  }, [data])
}

export function NetProfitSection() {
  const isMobile = useIsMobile()
  const { year } = usePerformanceYear()
  const { data, error, isLoading } = useProfit(year)
  const chartData = useNetProfitChartData(data as ProfitView | undefined)

  const chartConfig = {
    tax: { label: 'Tax', color: 'var(--chart-4)' },
    fee: { label: 'Fee', color: 'var(--chart-3)' },
    interest: { label: 'Interest', color: 'var(--chart-2)' },
    revenue: { label: 'Revenue', color: 'var(--chart-1)' },
  }
  const dataKeys = Object.keys(chartConfig)

  if (isLoading) return <StatusLabel type="loading" />
  if (error) return <StatusLabel type="error" />
  if (!data || !chartData) return null

  return (
    <Card className="gap-3 pb-0">
      <CardHeader>
        <CardDescription>Net Profit</CardDescription>
        <CardTitle className="text-2xl flex gap-1 items-baseline">
          {formatNum(chartData.totalPnl)}
        </CardTitle>
        <CardAction className="flex flex-col gap-1">
          <p className="text-xs text-muted-foreground">Monthly Avg.</p>
          <div className="flex flex-col gap-0 justify-end items-end text-xs">
            <p
              className={cn(
                chartData.avgProfit > 0 ? 'text-positive' : 'text-negative',
                'p-0 pointer-events-none',
              )}
            >
              {compactNum(chartData.avgProfit)}
            </p>
          </div>
        </CardAction>
      </CardHeader>
      <ChartContainer config={chartConfig} className="w-full">
        <BarChart
          accessibilityLayer
          data={chartData.chartRows}
          layout="horizontal"
          margin={{}}
        >
          <CartesianGrid vertical={false} horizontal={false} />
          <XAxis
            dataKey="snapshot_date"
            type="category"
            tickLine={false}
            tickMargin={0}
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
              fontSize: 10,
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
