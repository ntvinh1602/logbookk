import StatusLabel from '@/components/status-label'
import {
  Card,
  CardContent,
  CardDescription,
  CardFooter,
  CardHeader,
  CardTitle,
} from '@/components/ui/card'
import { cn, compactNum } from '@/lib/utils'
import { Badge } from '@/components/ui/badge'
import { useQuery } from '@tanstack/react-query'
import { dashboard } from '../../queries/dashboard'

export function NetProfitCard() {
  const { data, isLoading, error } = useQuery(dashboard.pnlLast12m())

  if (isLoading) return <StatusLabel type="loading" />
  if (error) return <StatusLabel type="error" />
  if (!data) return null

  const avgPnl = data / 12

  return (
    <Card className="w-full h-full justify-between">
      <CardHeader>
        <CardDescription>Net Profit</CardDescription>
      </CardHeader>
      <CardContent>
        <CardTitle className="text-3xl font-semibold">
          {compactNum(data)}
        </CardTitle>
        <Badge
          variant="ghost"
          className={cn(
            avgPnl > 0 ? 'text-positive' : 'text-negative',
            '-ml-2 pointer-events-none',
          )}
        >
          avg. monthly profit {compactNum(avgPnl)}
        </Badge>
      </CardContent>
      <CardFooter>
        <CardDescription className="text-xs">Last 12 months</CardDescription>
      </CardFooter>
    </Card>
  )
}
