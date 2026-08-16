import StatusLabel from '@/components/status-label'
import {
  Card,
  CardContent,
  CardDescription,
  CardFooter,
  CardHeader,
  CardTitle,
} from '@/components/ui/card'
import { cn, pctNum } from '@/lib/utils'
import { useBenchmark } from '../../hooks/use-performance-data'
import { Badge } from '@/components/ui/badge'

export function ReturnCard() {
  const currentYear = new Date().getFullYear()
  const { data, error, isLoading } = useBenchmark(currentYear)

  if (isLoading) return <StatusLabel type="loading"/>
  if (error) return <StatusLabel type="error"/>
  if (!data) return null

  return (
    <Card className="w-2/10 justify-between">
      <CardHeader>
        <CardDescription>Return</CardDescription>
      </CardHeader>
      <CardContent>
        <CardTitle className="text-3xl font-semibold">
          {pctNum(data.equity_ret)}
        </CardTitle>
        <Badge
          variant="ghost"
          className={cn(
            data.equity_ret > data.vn_ret ? 'text-positive' : 'text-negative',
            '-ml-2',
          )}
        >
          vs VN-Index {pctNum(data.vn_ret)}
        </Badge>
      </CardContent>
      <CardFooter>
        <CardDescription className="text-xs">
          Portfolio performance YTD
        </CardDescription>
      </CardFooter>
    </Card>
  )
}
