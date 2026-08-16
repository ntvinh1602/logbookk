import { YAxis, Area, AreaChart } from 'recharts'
import { type ChartConfig, ChartContainer } from '@/components/ui/chart'

type Props = {
  data: Record<string, string | number>[]
  config: ChartConfig
}

export function TinyAreaChart({ data, config }: Props) {
  const dataKeys = Object.keys(config)

  return (
    <ChartContainer config={config}>
      <AreaChart
        data={data}
        margin={{ top: 20, right: 0, bottom: 10, left: 0 }}
      >
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
        <YAxis
          domain={[
            (dataMin: number) => Number(dataMin),
            (dataMax: number) => Number(dataMax),
          ]}
          hide
        />
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
      </AreaChart>
    </ChartContainer>
  )
}
