import { useMemo } from 'react'
import { usePerformanceYear } from './year-context'
import { useBenchmark } from '@/features/fund/hooks/use-performance-data'
import type {
  BenchmarkView,
  BenchmarkChartCols,
} from '@/features/fund/fund.types'
import { BenchmarkChartConvert } from '@/features/fund/utils'
import {
  Card,
  CardHeader,
  CardTitle,
  CardDescription,
  CardAction,
} from '@/components/ui/card'
import StatusLabel from '@/components/status-label'
import { CartesianGrid, XAxis, YAxis, Area, AreaChart } from 'recharts'
import {
  ChartContainer,
  ChartLegend,
  ChartLegendContent,
  ChartTooltip,
  ChartTooltipContent,
} from '@/components/ui/chart'
import { format } from 'date-fns'
import { useIsMobile } from '@/hooks/use-mobile'
import { cn, formatNum, pctNum } from '@/lib/utils'
import { Badge } from '@/components/ui/badge'

function useBenchmarkChartData(data: BenchmarkView | undefined) {
  return useMemo(() => {
    if (!data) return null
    const returnChart = data.return_chart as BenchmarkChartCols | null
    if (!returnChart?.d) return null
    return {
      equityReturn: data.equity_ret,
      vnIndexReturn: data.vn_ret,
      chartRows: BenchmarkChartConvert(returnChart),
    }
  }, [data])
}

export function BenchmarkSection() {
  const isMobile = useIsMobile()

  const chartConfig = {
    portfolio_value: { label: 'Equity', color: 'var(--chart-1)' },
    vni_value: { label: 'VN-Index', color: 'var(--chart-2)' },
  }

  const dataKeys = Object.keys(chartConfig)

  const { year } = usePerformanceYear()
  const { data, error, isLoading } = useBenchmark(year)
  const chartData = useBenchmarkChartData(data)

  if (isLoading) return <StatusLabel type="loading" />
  if (error) return <StatusLabel type="error" />
  if (!data || !chartData) return null

  const alpha = chartData.equityReturn - chartData.vnIndexReturn

  return (
    <Card className="gap-3 pb-0">
      <CardHeader>
        <CardDescription>Return</CardDescription>
        <CardTitle className="text-2xl flex gap-1 items-baseline">
          {pctNum(chartData.equityReturn ?? 0)}
          <Badge
            variant="ghost"
            className={cn(
              (chartData.equityReturn ?? 0) > (chartData.vnIndexReturn ?? 0)
                ? 'text-positive'
                : 'text-negative',
              '-ml-2 pointer-events-none',
            )}
          >
            vs VN-Index {pctNum(chartData.vnIndexReturn ?? 0)}
          </Badge>
        </CardTitle>
        <CardAction className="flex flex-col justify-end items-end">
          <p className="text-xs text-muted-foreground">Alpha</p>
          <Badge
            variant="ghost"
            className={cn(
              alpha > 0 ? 'text-positive' : 'text-negative',
              'px-0 pointer-events-none',
            )}
          >
            {pctNum(alpha)}
          </Badge>
        </CardAction>
      </CardHeader>
      <ChartContainer config={chartConfig}>
        <AreaChart data={chartData.chartRows} margin={{}}>
          <defs>
            {dataKeys.map((key) => (
              <linearGradient
                key={key}
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
            ))}
          </defs>
          <CartesianGrid vertical={false} horizontal={false} />
          <XAxis
            dataKey={'t'}
            {...{
              type: 'number',
              scale: 'time',
              domain: ['dataMin', 'dataMax'],
            }}
            tickLine={false}
            axisLine={false}
            tickMargin={0}
            tickFormatter={(ms: number) => format(new Date(ms), 'MMM')}
            interval="preserveEnd"
            minTickGap={60}
          />
          <YAxis
            orientation="left"
            tickLine={false}
            axisLine={false}
            tickMargin={0}
            tickFormatter={(v) => formatNum(v)}
            domain={[
              (dataMin: number) => Number(dataMin),
              (dataMax: number) => Number(dataMax) * 1.02,
            ]}
            allowDataOverflow={false}
            scale="linear"
            mirror={true}
            tick={{
              fontSize: 10,
            }}
          />

          {!isMobile && (
            <ChartTooltip
              cursor={true}
              content={
                <ChartTooltipContent
                  indicator="line"
                  labelKey="t"
                  labelFormatter={(_label, payload) => {
                    const date = payload?.[0]?.payload?.t as string | undefined
                    return date ? format(new Date(date), 'dd MMM yyyy') : ''
                  }}
                />
              }
            />
          )}
          {dataKeys.map((key) => (
            <Area
              key={key}
              dataKey={key}
              type="natural"
              connectNulls={true}
              stroke={`var(--color-${key})`}
              strokeWidth={1.5}
              fill={`url(#fill-${key})`}
              dot={false}
            />
          ))}
          <ChartLegend
            content={<ChartLegendContent className="p-2" />}
            position="insideBottomLeft"
          />
        </AreaChart>
      </ChartContainer>
    </Card>
  )
}
