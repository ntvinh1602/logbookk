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
import { useQuery } from '@tanstack/react-query'
import { dashboard } from '../../queries/dashboard'

export function TotalAUMCard() {
  const { data, error, isLoading } = useQuery(dashboard.balanceSheet())

  if (isLoading) return <StatusLabel type="loading" />
  if (error) return <StatusLabel type="error" />
  if (!data) return null

  const equity = data
    .filter((r) => r.asset_class === 'equity')
    .reduce((sum, r) => sum + r.total_value, 0)

  const cash = data
    .filter((r) => r.asset_class == 'cash')
    .reduce((sum, r) => sum + r.total_value, 0)

  const stock = data
    .filter((r) => r.asset_class == 'stock')
    .reduce((sum, r) => sum + r.total_value, 0)

  const fund = data
    .filter((r) => r.asset_class == 'fund')
    .reduce((sum, r) => sum + r.total_value, 0)

  const normalizedCash = Math.max(cash, 0)
  const totalAsset = normalizedCash + stock + fund
  const leverage = (totalAsset - equity) / equity

  return (
    <Card className="w-full h-full justify-between bg-foreground">
      <CardHeader>
        <CardDescription className="text-muted">Total AUM</CardDescription>
      </CardHeader>
      <CardContent>
        <CardTitle className="text-3xl font-semibold text-background">
          {formatNum(totalAsset)}
        </CardTitle>
        <Badge
          variant="ghost"
          className={cn(
            leverage < 1 ? 'text-green-500' : 'text-red-500',
            '-ml-2 pointer-events-none',
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
