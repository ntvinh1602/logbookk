import StatusLabel from '@/components/status-label'
import {
  Card,
  CardAction,
  CardContent,
  CardHeader,
  CardTitle,
} from '@/components/ui/card'
import { Progress, ProgressLabel } from '@/components/ui/progress'
import type { StatsRow, TopAirlines } from '@/features/flight/types'
import { Users } from 'lucide-react'

interface Props {
  airlinesData: TopAirlines[] | undefined
  lifetimeStats: StatsRow | undefined
  isLoading: boolean
}

export function TopAirlinesCard({
  airlinesData,
  lifetimeStats,
  isLoading,
}: Props) {
  if (isLoading) return <StatusLabel type="loading" />
  if (!airlinesData || !lifetimeStats) return null

  return (
    <Card>
      <CardHeader>
        <CardTitle>Top 5 Airlines</CardTitle>
        <CardAction>
          <Users className="size-5" />
        </CardAction>
      </CardHeader>
      <CardContent className="flex flex-col gap-4">
        {airlinesData.map((a, i) => (
          <div key={a.airlines_logo} className="flex items-center gap-4">
            <span className="text-muted-foreground tabular-nums">{i + 1}</span>
            <img
              src={a.airlines_logo}
              width={28}
              height={28}
              className="rounded-sm"
            />
            <Progress
              value={(a.count / lifetimeStats.flights_count) * 100}
              className="w-full max-w-sm gap-1"
            >
              <ProgressLabel>{a.airlines_name}</ProgressLabel>
            </Progress>
            <span className="min-w-5 text-right">{a.count}</span>
          </div>
        ))}
      </CardContent>
    </Card>
  )
}
