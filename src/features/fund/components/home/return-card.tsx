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
import { Badge } from '@/components/ui/badge'
import { useQueries } from '@tanstack/react-query'
import { dashboard } from '../../queries/dashboard'

export function ReturnCard() {
  const results = useQueries({
    queries: [dashboard.twrYtd(), dashboard.vniYtd()],
  })

  const [twrYtdQuery, vniYtdQuery] = results

  const isLoading = results.some((query) => query.isPending)
  const isError = results.some((query) => query.isError)

  if (isLoading) return <StatusLabel type="loading" />
  if (isError) return <StatusLabel type="error" />

  const twrYtd = twrYtdQuery.data || 0
  const vniYtd = vniYtdQuery.data || 0

  return (
    <Card className="w-full h-full justify-between">
      <CardHeader>
        <CardDescription>Return</CardDescription>
      </CardHeader>
      <CardContent>
        <CardTitle className="text-3xl font-semibold">
          {pctNum(twrYtd)}
        </CardTitle>
        <Badge
          variant="ghost"
          className={cn(
            twrYtd > vniYtd ? 'text-positive' : 'text-negative',
            '-ml-2 pointer-events-none',
          )}
        >
          vs VN-Index {pctNum(vniYtd)}
        </Badge>
      </CardContent>
      <CardFooter>
        <CardDescription className="text-xs">This year</CardDescription>
      </CardFooter>
    </Card>
  )
}
