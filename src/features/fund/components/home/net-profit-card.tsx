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
import { use1yProfit } from '../../hooks/use-dashboard-data'

export function NetProfitCard() {
  const { data, error, isLoading } = use1yProfit()

  if (isLoading) return <StatusLabel type="loading"/>
  if (error) return <StatusLabel type="error"/>
  if (!data) return null

  return (
    <Card className="w-full h-full justify-between">
      <CardHeader>
        <CardDescription>Net Profit</CardDescription>
      </CardHeader>
      <CardContent>
        <CardTitle className="text-3xl font-semibold">
          {compactNum(data.total_pnl)}
        </CardTitle>
        <Badge
          variant="ghost"
          className={cn(
            data.avg_profit > 0 ? 'text-positive' : 'text-negative',
            '-ml-2',
          )}
        >
          avg. monthly profit {compactNum(data.avg_profit)}
        </Badge>
      </CardContent>
      <CardFooter>
        <CardDescription className="text-xs">
          Last 12 months
        </CardDescription>
      </CardFooter>
    </Card>
  )
}
