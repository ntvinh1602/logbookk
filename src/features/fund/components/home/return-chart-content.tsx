import { useMemo } from 'react'
import { useDashboardDateRange } from './chart-range-context'
import {
  Card,
  CardHeader,
  CardTitle,
  CardDescription,
} from '@/components/ui/card'
import { useBenchmarkRolling } from '@/features/fund/hooks/use-dashboard-data'
import type { BenchmarkRollingView } from '@/features/fund/fund.types'
import StatusLabel from '@/components/status-label'
import { BenchmarkChartConvert } from '@/features/fund/utils'
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
import { compactNum } from '@/lib/utils'

function useReturnChartData(
  data: BenchmarkRollingView | null | undefined,
  dateRange: string,
) {
  return useMemo(() => {
    if (!data) return null
    const chartData = data.returnchart
    const cols =
      chartData[dateRange as keyof typeof chartData] ?? chartData.last_1y
    if (!cols?.d) return null
    return {
      chartTimeframe: BenchmarkChartConvert(cols),
      twrYtd: data.twr_ytd,
      twrAll: data.twr_all,
      cagr: data.cagr,
    }
  }, [data, dateRange])
}

export function ReturnChartSection() {
  const { dateRange } = useDashboardDateRange()
  const { data, error, isLoading } = useBenchmarkRolling()
  const chartData = useReturnChartData(data, dateRange)

  const chartConfig = {
    portfolio_value: { label: 'Equity', color: 'var(--chart-1)' },
    vni_value: { label: 'VN-Index', color: 'var(--chart-2)' },
  }

  const dataKeys = Object.keys(chartConfig)
  const isMobile = useIsMobile()

  if (isLoading) return <StatusLabel type="loading" />
  if (error) return <StatusLabel type="error" />
  if (!data || !chartData) return <StatusLabel type="empty" />

  return (
    <Card>
      <CardHeader>
        <CardDescription>Return</CardDescription>
        <CardTitle className="text-xl sm:text-2xl flex gap-1 items-baseline">
          {data.twr_ytd}
          <span className="text-sm text-muted-foreground">this year</span>
        </CardTitle>
      </CardHeader>
      <ChartContainer config={chartConfig}>
        <AreaChart data={chartData.chartTimeframe} margin={{}}>
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
          <CartesianGrid vertical={false} />
          <XAxis
            dataKey={'t'}
            {...{
              type: 'number',
              scale: 'time',
              domain: ['dataMin', 'dataMax'],
            }}
            tickLine={true}
            axisLine={false}
            tickMargin={8}
            tickFormatter={(ms: number) =>
              ['last_1y', 'all'].includes(dateRange)
                ? format(new Date(ms), 'MMM yyyy')
                : format(new Date(ms), 'dd MMM')
            }
            interval="preserveEnd"
            minTickGap={60}
          />
          <YAxis
            orientation="left"
            tickLine={false}
            axisLine={false}
            tickMargin={0}
            tickFormatter={(v) => compactNum(v)}
            domain={[
              (dataMin: number) => Number(dataMin) * 1,
              (dataMax: number) => Number(dataMax) * 1.05,
            ]}
            allowDataOverflow={false}
            scale="linear"
            mirror={true}
            tick={{
              fill: 'var(--muted-foreground)',
              className: 'opacity-80',
            }}
          />

          {!isMobile && (
            <ChartTooltip
              cursor={true}
              content={
                <ChartTooltipContent
                  indicator="line"
                  labelFormatter={(_label, payload) => {
                    const ms = payload?.[0]?.payload?.t as number | undefined
                    if (ms == null) return ''
                    return format(new Date(ms), 'yyyy-MM-dd')
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
          <ChartLegend content={<ChartLegendContent />} />
        </AreaChart>
      </ChartContainer>
    </Card>
  )
}
