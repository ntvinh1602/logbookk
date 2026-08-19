import { useBalanceSheet } from '@/features/fund/hooks/use-dashboard-data'
import {
  Card,
  CardAction,
  CardContent,
  CardHeader,
  CardTitle,
} from '@/components/ui/card'
import StatusLabel from '@/components/status-label'
import { ButtonGroup } from '@/components/ui/button-group'
import { ItemGroup } from '@/components/ui/item'
import { Progress } from '@/components/ui/progress'
import {
  Item,
  ItemMedia,
  ItemContent,
  ItemTitle,
  ItemDescription,
} from '@/components/ui/item'
import { cn, compactNum, formatNum, pctNum } from '@/lib/utils'
import { usePortfolioMetrics } from '../../hooks/use-portfolio-metrics'

export function PortfolioCard() {
  const { data, error, isLoading } = useBalanceSheet()
  const metrics = usePortfolioMetrics(data)

  if (isLoading) return <StatusLabel type="loading" />
  if (error) return <StatusLabel type="error" />
  if (!data || !metrics) return <StatusLabel type="error" />

  const sortedStocks = [...data]
    .filter((a) => a.asset_class == 'stock' || a.asset_class == 'fund')
    .sort((a, b) => b.total_value - a.total_value)

  return (
    <Card>
      <CardHeader>
        <CardTitle>Portfolio</CardTitle>
        <CardAction>
          <ButtonGroup></ButtonGroup>
        </CardAction>
      </CardHeader>
      <CardContent>
        {sortedStocks.length > 0 ? (
          <ItemGroup className="gap-0">
            {sortedStocks.map((bs) => (
              <div className="flex flex-col w-full">
                <Item className="px-0">
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
                    value={(bs.total_value / metrics.totalAsset) * 100}
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
