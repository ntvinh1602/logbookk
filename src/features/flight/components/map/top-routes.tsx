import StatusLabel from '@/components/status-label'
import { Card, CardAction, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Progress, ProgressLabel } from '@/components/ui/progress'
import type { StatsRow, TopRoutes } from '@/features/flight/types'
import { Route } from 'lucide-react'

interface Props {
  routesData: TopRoutes[] | undefined
  lifetimeStats: StatsRow | undefined
  isLoading: boolean
}

export function TopRoutesCard({
  routesData,
  lifetimeStats,
  isLoading,
}: Props) {
  if (isLoading) return <StatusLabel type="loading" />
  if (!routesData || !lifetimeStats) return null

  return (
    <Card>
      <CardHeader>
        <CardTitle>Top 5 Routes</CardTitle>
        <CardAction>
          <Route className='size-5'/>
        </CardAction>
      </CardHeader>
      <CardContent className="flex flex-col gap-4">
        {routesData.map((route, i) => (
          <div
            key={`${route.airport_a_code}-${route.airport_b_code}`}
            className="flex items-center gap-4"
          >
            <span className="text-muted-foreground tabular-nums">{i + 1}</span>
            <Progress
              value={(route.frequency / lifetimeStats.flights) * 100}
              className="w-full max-w-sm gap-1"
            >
              <ProgressLabel className="font-mono">
                {route.airport_a_code} ↔ {route.airport_b_code}
              </ProgressLabel>
            </Progress>
            <span className="min-w-5 text-right">{route.frequency}</span>
          </div>
        ))}
      </CardContent>
    </Card>
  )
}
