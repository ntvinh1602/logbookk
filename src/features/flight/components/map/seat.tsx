import StatusLabel from '@/components/status-label'
import {
  Item,
  ItemContent,
  ItemDescription,
  ItemMedia,
} from '@/components/ui/item'
import { ChartContainer } from '@/components/ui/chart'
import type { ChartConfig } from '@/components/ui/chart'
import type { StatsRow } from '@/features/flight/types'
import { Armchair } from 'lucide-react'
import { Bar, BarChart, XAxis, YAxis } from 'recharts'

interface Props {
  data: StatsRow | undefined
  isLoading: boolean
}

// Categorical slots snapped from the app's own hue families (43 / 290 / 93) and
// validated per mode against the card surface — window and middle are the two
// warm hues, so aisle sits between them in the stack to keep every adjacent
// pair separable under CVD. `--chart-3/4/5` can't be reused here: their light
// steps fall under the chroma floor (they read as gray, not as identity).
const chartConfig = {
  window: {
    label: 'Window',
    color: 'var(--chart-1)',
  },
  aisle: {
    label: 'Aisle',
    color: 'var(--chart-2)',
  },
  middle: {
    label: 'Middle',
    color: 'var(--chart-3)',
  },
} satisfies ChartConfig

const SERIES = ['window', 'aisle', 'middle'] as const

function share(value: number, total: number) {
  const percent = (value / total) * 100
  if (percent > 0 && percent < 1) return '<1%'
  return `${Math.round(percent)}%`
}

export function SeatCard({ data, isLoading }: Props) {
  if (isLoading) return <StatusLabel type="loading" />
  if (!data) return null

  const counts = {
    window: data.windows,
    aisle: data.aisle,
    middle: data.middle,
  }
  const total = counts.window + counts.aisle + counts.middle
  if (!total) return null

  return (
    <Item variant="outline" className="bg-card">
      <ItemMedia variant="image">
        <div className="flex size-10 items-center justify-center rounded-full bg-secondary">
          <Armchair className="text-secondary-foreground" />
        </div>
      </ItemMedia>
      <ItemContent>
        <ItemDescription>Seat Position</ItemDescription>

        <div className="flex basis-full flex-col gap-2">
          <ChartContainer
            config={chartConfig}
            className="aspect-auto h-6 w-full"
          >
            <BarChart
              accessibilityLayer
              data={[counts]}
              layout="vertical"
              margin={{ top: 0, right: 0, bottom: 0, left: 0 }}
              barSize={24}
            >
              <XAxis type="number" dataKey="window" hide domain={[0, total]} />
              <YAxis type="category" hide />
              {SERIES.map((key, index) => (
                <Bar
                  key={key}
                  dataKey={key}
                  stackId="seats"
                  fill={`var(--color-${key})`}
                  // a 2px card-colored ring around each segment buys the surface
                  // gap between neighbours
                  stroke="var(--card)"
                  strokeWidth={2}
                  radius={
                    index === 0
                      ? [4, 0, 0, 4]
                      : index === SERIES.length - 1
                        ? [0, 4, 4, 0]
                        : 0
                  }
                />
              ))}
            </BarChart>
          </ChartContainer>

          {/* Legend doubles as the direct labels: identity is never colour-alone. */}
          <div className="flex flex-wrap items-center justify-between gap-x-3 gap-y-1 text-xs">
            {SERIES.map((key) => (
              <div key={key} className="flex items-center gap-1.5">
                <span
                  className="size-2 shrink-0 rounded-[2px]"
                  style={{ backgroundColor: chartConfig[key].color }}
                />
                <span className="text-muted-foreground">
                  {chartConfig[key].label}
                </span>
                <span className="font-medium text-foreground tabular-nums">
                  {share(counts[key], total)}
                </span>
              </div>
            ))}
          </div>
        </div>
      </ItemContent>
    </Item>
  )
}
