import {
  Card,
  CardAction,
  CardContent,
  CardDescription,
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
} from '@/components/ui/item'
import { Progress } from '@/components/ui/progress'
import { cn, compactNum, formatNum, pctNum } from '@/lib/utils'
import type { BSheetView } from '@/lib/supabase/api/types'
import { Button } from '@/components/ui/button'
import { ListOrdered } from 'lucide-react'
import {
  Sheet,
  SheetContent,
  SheetDescription,
  SheetHeader,
  SheetTitle,
  SheetTrigger,
} from '@/components/ui/sheet'
import { useState } from 'react'
import BalanceSheet from '@/features/fund/components/dashboard/balance-sheet'
import { Badge } from '@/components/ui/badge'

interface PortfolioCardProps {
  balanceSheet: BSheetView[]
  equity: number
  liability: number
  isLoading: boolean
}

export function AssetCard({
  balanceSheet,
  equity,
  liability,
  isLoading,
}: PortfolioCardProps) {
  const [open, setOpen] = useState(false)

  if (isLoading) return <StatusLabel type="loading" />
  if (!balanceSheet) return null

  const sortedStocks = [...balanceSheet]
    .filter((a) => a.asset_class == 'stock' || a.asset_class == 'fund')
    .sort((a, b) => b.total_value - a.total_value)

  const asset = equity + liability
  const leverage = (asset - equity) / equity

  return (
    <Card className="pb-3 gap-3">
      <CardHeader>
        <CardDescription>Assets</CardDescription>
        <CardTitle className="text-2xl gap-2 flex items-baseline">
          {compactNum(asset, 4)}
          <Badge
            variant="ghost"
            className={cn(
              leverage < 1 ? 'text-positive' : 'text-negative',
              '-ml-2 pointer-events-none',
            )}
          >
            {formatNum(leverage, 2)} leverage
          </Badge>
        </CardTitle>
        <CardAction>
          <Sheet open={open} onOpenChange={setOpen}>
            <SheetTrigger
              render={
                <Button variant="outline" size="sm">
                  <ListOrdered />
                  Balance
                </Button>
              }
            />
            <SheetContent side="right" showCloseButton={false}>
              <SheetHeader>
                <SheetTitle>Balance Sheet</SheetTitle>
                <SheetDescription>
                  A breakdown of your assets, liabilities, and equity.
                </SheetDescription>
              </SheetHeader>
              <BalanceSheet
                bsData={balanceSheet}
                asset={asset}
                liability={liability}
                equity={equity}
              />
            </SheetContent>
          </Sheet>
        </CardAction>
      </CardHeader>
      <CardContent>
        {sortedStocks.length > 0 ? (
          <ItemGroup className="gap-0">
            {sortedStocks.map((bs) => (
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
                  value={(bs.total_value / asset) * 100}
                  className="w-full"
                />
              </Item>
            ))}
          </ItemGroup>
        ) : (
          <StatusLabel type="empty" />
        )}
      </CardContent>
    </Card>
  )
}
