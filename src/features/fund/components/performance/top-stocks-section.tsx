import { useMemo } from 'react'
import { usePerformanceYear } from './year-context'
import { useStockPnl } from '@/features/fund/hooks/use-performance-data'
import {
  Item,
  ItemMedia,
  ItemContent,
  ItemTitle,
  ItemDescription,
  ItemSeparator,
} from '@/components/ui/item'
import StatusLabel from '@/components/status-label'
import type { StockPnl } from '@/features/fund/fund.types'
import { ItemGroup } from '@/components/ui/item'
import { formatNum } from '@/lib/utils'
import {
  Card,
  CardDescription,
  CardHeader,
  CardTitle,
  CardAction,
  CardContent,
} from '@/components/ui/card'
import { Trophy } from 'lucide-react'

function useTopPerformers(data: StockPnl[] | undefined) {
  return useMemo(() => {
    if (!data) return null
    return [...data].sort((a, b) => b.total_pnl - a.total_pnl).slice(0, 10)
  }, [data])
}

export function TopStocksSection() {
  const { year } = usePerformanceYear()
  const { data, error, isLoading } = useStockPnl(year)
  const topPerformers = useTopPerformers(data)

  if (isLoading) return <StatusLabel type="loading" />
  if (error) return <StatusLabel type="error" description={error.message} />
  if (!data || !topPerformers) return <StatusLabel type="empty" />

  return (
    <Card className='pb-4'>
      <CardHeader>
        <CardTitle>Top Performers</CardTitle>
        <CardDescription>Based on total realized P/L</CardDescription>
        <CardAction>
          <Trophy className="stroke-1" />
        </CardAction>
      </CardHeader>
      <CardContent>
        <ItemGroup className="gap-0">
          {topPerformers.map((stock) => (
            <div>
              <ItemSeparator />
              <Item size="xs" className='px-0'>
                <ItemMedia variant="image">
                  {stock.logo_url && (
                    <img
                      src={`${import.meta.env.VITE_PUBLIC_SUPABASE_URL}/storage/v1/object/public/logo/stock/${stock.logo_url}`}
                      loading="eager"
                    />
                  )}
                </ItemMedia>
                <ItemContent>
                  <ItemTitle>{stock.name}</ItemTitle>
                  <ItemDescription>{stock.ticker}</ItemDescription>
                </ItemContent>
                <ItemContent className="items-end">
                  <ItemTitle>{formatNum(stock.total_pnl)}</ItemTitle>
                </ItemContent>
              </Item>
            </div>
          ))}
        </ItemGroup>
      </CardContent>
    </Card>
  )
}
