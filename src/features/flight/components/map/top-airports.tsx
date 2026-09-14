import StatusLabel from '@/components/status-label'
import {
  Card,
  CardAction,
  CardContent,
  CardHeader,
  CardTitle,
} from '@/components/ui/card'
import { Progress, ProgressLabel } from '@/components/ui/progress'
import type { StatsRow, TopAirports } from '@/features/flight/types'
import { PlaneTakeoff } from 'lucide-react'

interface Props {
  airportData: TopAirports[] | undefined
  lifetimeStats: StatsRow | undefined
  isLoading: boolean
}

export function TopAirportsCard({
  airportData,
  lifetimeStats,
  isLoading,
}: Props) {
  if (isLoading) return <StatusLabel type="loading" />
  if (!airportData || !lifetimeStats) return null

  return (
    <Card>
      <CardHeader>
        <CardTitle>Top 5 Visited Airports</CardTitle>
        <CardAction>
          <PlaneTakeoff className="size-5" />
        </CardAction>
      </CardHeader>
      <CardContent className="flex flex-col gap-4">
        {airportData.map((airport, i) => (
          <div key={airport.airport_code} className="flex items-center gap-4">
            <span className="text-muted-foreground tabular-nums">{i + 1}</span>
            <span className="font-medium font-mono">
              {airport.airport_code}
            </span>
            <Progress
              value={(airport.count / lifetimeStats.flights / 2) * 100}
              className="w-full max-w-sm gap-1"
            >
              <ProgressLabel>{airport.airport_name}</ProgressLabel>
            </Progress>
            <span className="min-w-5 text-right">{airport.count}</span>
          </div>
        ))}
      </CardContent>
    </Card>
  )
}
