import StatusLabel from '@/components/status-label'
import {
  Card,
  CardContent,
  CardDescription,
  CardFooter,
  CardHeader,
  CardTitle,
} from '@/components/ui/card'
import { cn, formatNum } from '@/lib/utils'
import { Badge } from '@/components/ui/badge'
import { usePortfolioMetrics } from './portfolio-section'
import { useBalanceSheet } from '../../hooks/use-dashboard-data'

export function TotalAUMCard() {
  const { data, error, isLoading } = useBalanceSheet()
  const metrics = usePortfolioMetrics(data)

  if (isLoading) return <StatusLabel type="loading" />
  if (error) return <StatusLabel type="error" />
  if (!data || !metrics) return null

  const leverage = (metrics.totalAsset - metrics.equity) / metrics.equity

  return (
    <Card className="w-full h-full justify-between bg-foreground">
      <CardHeader>
        <CardDescription className="text-muted">Total AUM</CardDescription>
      </CardHeader>
      <CardContent>
        <CardTitle className="text-3xl font-semibold text-background">
          {formatNum(metrics.totalAsset)}
        </CardTitle>
        <Badge
          variant="ghost"
          className={cn(
            leverage < 1 ? 'text-green-500' : 'text-red-500',
            '-ml-2',
          )}
        >
          {formatNum(leverage, 2)} leverage
        </Badge>
      </CardContent>
      <CardFooter>
        <CardDescription className="text-xs text-muted">
          Fund + Stock + Debt
        </CardDescription>
      </CardFooter>
    </Card>
  )
}
