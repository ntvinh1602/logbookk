import {
  Card,
  CardAction,
  CardContent,
  CardHeader,
  CardTitle,
} from '@/components/ui/card'
import StatusLabel from '@/components/status-label'
import {
  ItemGroup,
  Item,
  ItemMedia,
  ItemContent,
  ItemTitle,
  ItemDescription,
  ItemSeparator,
} from '@/components/ui/item'
import { Progress } from '@/components/ui/progress'
import { cn, compactNum, formatNum, pctNum } from '@/lib/utils'
import type { BSheetView } from '@/features/fund/fund.types'
import { Button } from '@/components/ui/button'
import { ListOrdered } from 'lucide-react'

interface PortfolioCardProps {
  balanceSheet: BSheetView[]
  totalAsset: number
  isLoading: boolean
}

export function PortfolioCard({
  balanceSheet,
  totalAsset,
  isLoading,
}: PortfolioCardProps) {
  if (isLoading) return <StatusLabel type="loading" />
  if (!balanceSheet) return null

  const sortedStocks = [...balanceSheet]
    .filter((a) => a.asset_class == 'stock' || a.asset_class == 'fund')
    .sort((a, b) => b.total_value - a.total_value)

  return (
    <Card className='gap-0 pb-3'>
      <CardHeader className="border-b">
        <CardTitle>Portfolio</CardTitle>
        <CardAction>
          <Button variant="outline" size="icon-sm">
            <ListOrdered/>
          </Button>
        </CardAction>
      </CardHeader>
      <CardContent className='px-0'>
        {sortedStocks.length > 0 ? (
          <ItemGroup className="gap-0 pt-2">
            {sortedStocks.map((bs, index) => (
              <div className="flex flex-col w-full">
                {index > 0 && <ItemSeparator />}
                <Item className="py-2">
                  <ItemMedia variant="image">
                    {bs.logo_url && (
                      <img
                        src={`${import.meta.env.VITE_PUBLIC_SUPABASE_URL}/storage/v1/object/public/logo/stock/${bs.logo_url}`}
                        loading="eager"
                      />
                    )}
                  </ItemMedia>
                  <ItemContent>
                    <ItemTitle>{bs.name}</ItemTitle>
                    <ItemDescription className="text-xs">
                      {`${formatNum(bs.quantity)} ${bs.currency_code == 'VND' ? 'units' : bs.currency_code} @ ${formatNum(bs.mkt_price)} `}
                    </ItemDescription>
                  </ItemContent>
                  <ItemContent className="items-end">
                    <ItemDescription>
                      {formatNum(Math.max(bs.total_value, 0))}
                    </ItemDescription>
                    <ItemDescription
                      className={cn(
                        bs.net_profit > 0 ? 'text-positive' : 'text-negative',
                        'text-xs',
                      )}
                    >
                      {`${compactNum(bs.net_profit)} (${pctNum(bs.net_profit / bs.total_value)})`}
                    </ItemDescription>
                  </ItemContent>
                  <Progress
                    value={(bs.total_value / totalAsset) * 100}
                    className="w-full"
                  />
                </Item>
              </div>
            ))}
          </ItemGroup>
        ) : (
          <StatusLabel type="empty" />
        )}
      </CardContent>
    </Card>
  )
}
