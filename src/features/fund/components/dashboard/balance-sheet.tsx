import type { BSheetView } from '@/features/fund/types'
import {
  Card,
  CardAction,
  CardContent,
  CardHeader,
  CardTitle,
} from '@/components/ui/card'
import { formatNum } from '@/lib/utils'
import {
  Item,
  ItemContent,
  ItemDescription,
  ItemGroup,
  ItemSeparator,
  ItemTitle,
} from '@/components/ui/item'
import { Separator } from '@/components/ui/separator'

interface Props {
  bsData: BSheetView[]
  asset: number
  liability: number
  equity: number
}

export default function BalanceSheet({
  bsData,
  asset,
  liability,
  equity,
}: Props) {
  const { liabilities, equities, groupedAssets } = bsData.reduce(
    (acc, item) => {
      if (item.asset_class === 'equity') {
        acc.equities.push(item)
      } else if (item.asset_class === 'liability') {
        acc.liabilities.push(item)
      } else {
        const key = item.asset_class
        if (!acc.groupedAssets[key]) acc.groupedAssets[key] = []
        acc.groupedAssets[key].push(item)
      }

      return acc
    },
    {
      liabilities: [] as BSheetView[],
      equities: [] as BSheetView[],
      groupedAssets: {} as Record<string, BSheetView[]>,
    },
  )

  const liabilityAssets = [
    {
      label: 'Liabilities',
      value: liability,
      items: liabilities,
    },
    {
      label: 'Equity',
      value: equity,
      items: equities,
    },
  ] as const

  return (
    <div className="flex flex-col gap-2">
      <Card className="flex gap-3 bg-0 ring-0 shadow-none">
        <CardHeader>
          <CardTitle>Assets</CardTitle>
          <CardAction>{formatNum(asset)}</CardAction>
        </CardHeader>
        <CardContent className="px-4 flex flex-col gap-2">
          {Object.entries(groupedAssets).map(([assetClass, items]) => {
            const totalValue = items.reduce(
              (sum, i) => sum + Math.max(i.total_value ?? 0, 0),
              0,
            )
            return (
              <Item
                key={assetClass}
                size="xs"
                variant="muted"
                className="gap-0"
              >
                <ItemContent>
                  <ItemTitle className="capitalize">{assetClass}</ItemTitle>
                </ItemContent>
                <ItemContent>
                  <ItemDescription>{formatNum(totalValue)}</ItemDescription>
                </ItemContent>
                <ItemSeparator />
                <ItemGroup>
                  {items.map((item) => (
                    <Item size="xs" className="px-0 py-1">
                      <ItemContent>
                        <ItemTitle>{item.name}</ItemTitle>
                        {item.ticker !== 'FX.VND' && (
                          <ItemDescription>
                            {`${formatNum(item.quantity)} ${item.asset_class == 'stock' ? ' shares' : `${item.currency_code}`}`}
                          </ItemDescription>
                        )}
                      </ItemContent>
                      <ItemContent className="items-end">
                        <ItemDescription>
                          {formatNum(Math.max(item.total_value, 0))}
                        </ItemDescription>
                      </ItemContent>
                    </Item>
                  ))}
                </ItemGroup>
              </Item>
            )
          })}
        </CardContent>
      </Card>

      <div className="px-4">
        <Separator />
      </div>

      <div className="flex flex-col">
        {liabilityAssets.map((s) => (
          <Card
            key={s.label}
            className="flex gap-3 py-4 bg-0 ring-0 shadow-none"
          >
            <CardHeader>
              <CardTitle>{s.label}</CardTitle>
              <CardAction>{formatNum(s.value)}</CardAction>
            </CardHeader>
            <CardContent className="px-4 flex flex-col gap-1">
              {s.items.map((item) => (
                <Item key={item.ticker} size="xs" variant="muted">
                  <ItemContent>
                    <ItemTitle>{item.name}</ItemTitle>
                  </ItemContent>
                  <ItemContent>
                    <ItemDescription>
                      {formatNum(item.total_value)}
                    </ItemDescription>
                  </ItemContent>
                </Item>
              ))}
            </CardContent>
          </Card>
        ))}
      </div>
    </div>
  )
}
