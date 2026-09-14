import StatusLabel from '@/components/status-label'
import { Card, CardAction, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Progress, ProgressLabel } from '@/components/ui/progress'
import type { StatsRow, TopAircrafts } from '@/features/flight/types'
import { Plane } from 'lucide-react'

interface Props {
  aircraftsData: TopAircrafts[] | undefined
  lifetimeStats: StatsRow | undefined
  isLoading: boolean
}

export function TopAircraftsCard({
  aircraftsData,
  lifetimeStats,
  isLoading,
}: Props) {
  if (isLoading) return <StatusLabel type="loading" />
  if (!aircraftsData || !lifetimeStats) return null

  return (
    <Card>
      <CardHeader>
        <CardTitle>Top 5 Aircraft Models</CardTitle>
        <CardAction>
          <Plane className='size-5'/>
        </CardAction>
      </CardHeader>
      <CardContent className="flex flex-col gap-4">
        {aircraftsData.map((aircraft, i) => (
          <div key={aircraft.aircraft_model} className="flex items-center gap-4">
            <span className="text-muted-foreground tabular-nums">{i + 1}</span>
            <Progress
              value={(aircraft.count / lifetimeStats.flights) * 100}
              className="w-full max-w-sm gap-1"
            >
              <ProgressLabel>{aircraft.aircraft_model}</ProgressLabel>
            </Progress>
            <span className="min-w-5 text-right">{aircraft.count}</span>
          </div>
        ))}
      </CardContent>
    </Card>
  )
}
