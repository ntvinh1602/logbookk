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

interface TotalAUMCardProps {
  totalAsset: number
  leverage: number
  isLoading: boolean
}

export function TotalAUMCard({
  totalAsset,
  leverage,
  isLoading,
}: TotalAUMCardProps) {
  if (isLoading) return <StatusLabel type="loading" />

  return (
    <Card className="w-full h-50 justify-between bg-foreground">
      <CardHeader>
        <CardDescription className="text-muted">Total AUM</CardDescription>
      </CardHeader>
      <CardContent>
        <CardTitle className="text-3xl font-semibold text-background">
          {formatNum(totalAsset)}
        </CardTitle>
      </CardContent>
      <CardFooter>
        <Badge
          variant="ghost"
          className={cn(
            leverage < 1 ? 'text-green-500' : 'text-red-500',
            '-ml-2 pointer-events-none',
          )}
        >
          {formatNum(leverage, 2)} leverage
        </Badge>
      </CardFooter>
    </Card>
  )
}
