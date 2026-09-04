import type { TopStocks } from '@/features/fund/types'
import {
  Item,
  ItemMedia,
  ItemContent,
  ItemTitle,
  ItemDescription,
  ItemSeparator,
  ItemGroup,
} from '@/components/ui/item'
import StatusLabel from '@/components/status-label'
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

interface TopStocksSectionProps {
  data: TopStocks[] | undefined
  isLoading: boolean
}

export function TopStocksSection({ data, isLoading }: TopStocksSectionProps) {
  if (isLoading) return <StatusLabel type="loading" />
  if (!data) return <StatusLabel type="empty" />

  const sortedStocks = [...data]
    .sort((a, b) => b.total_pnl - a.total_pnl)
    .slice(0, 10)

  return (
    <Card className="pb-4">
      <CardHeader>
        <CardTitle>Top Performers</CardTitle>
        <CardDescription>Based on total realized P/L</CardDescription>
        <CardAction>
          <Trophy className="stroke-1" />
        </CardAction>
      </CardHeader>
      <CardContent>
        <ItemGroup className="gap-0">
          {sortedStocks.map((stock) => (
            <div>
              <ItemSeparator />
              <Item size="xs" className="px-0">
                <ItemMedia variant="image">
                  <img
                    src={`${import.meta.env.VITE_PUBLIC_SUPABASE_URL}/storage/v1/object/public/logo/stock/${stock.logo_url}`}
                    loading="eager"
                  />
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
