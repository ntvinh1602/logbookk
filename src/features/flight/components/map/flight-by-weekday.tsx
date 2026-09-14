import StatusLabel from '@/components/status-label'
import {
  Card,
  CardAction,
  CardContent,
  CardHeader,
  CardTitle,
} from '@/components/ui/card'
import { ChartContainer } from '@/components/ui/chart'
import type { ChartConfig } from '@/components/ui/chart'
import type { FlightsByWeekday } from '@/features/flight/types'
import { CalendarCheck } from 'lucide-react'
import { Bar, BarChart, LabelList, XAxis } from 'recharts'

interface Props {
  data: FlightsByWeekday[] | undefined
  isLoading: boolean
}

const chartConfig = {
  flights: {
    label: 'Flights',
    color: 'var(--chart-1)',
  },
} satisfies ChartConfig

export function FlightByWeekday({ data, isLoading }: Props) {
  if (isLoading) return <StatusLabel type="loading" />
  if (!data) return null

  return (
    <Card>
      <CardHeader>
        <CardTitle>Flights by Weekday</CardTitle>
        <CardAction>
          <CalendarCheck className="size-5" />
        </CardAction>
      </CardHeader>
      <CardContent>
        <ChartContainer config={chartConfig}>
          <BarChart accessibilityLayer data={data}>
            <XAxis
              dataKey="weekday"
              tickLine={false}
              tickMargin={10}
              axisLine={false}
            />
            <Bar dataKey="flights" fill="var(--color-flights)" radius={4}>
              <LabelList
                position="top"
                offset={12}
                className="fill-foreground"
                fontSize={12}
              />
            </Bar>
          </BarChart>
        </ChartContainer>
      </CardContent>
    </Card>
  )
}
