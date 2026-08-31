import { ShoppingBag, Coins, Calendar, Clock } from 'lucide-react'
import { format } from 'date-fns'
import { cn, formatNum } from '@/lib/utils'
import {
  Item,
  ItemMedia,
  ItemContent,
  ItemTitle,
  ItemDescription,
} from '@/components/ui/item'
import { Badge } from '@/components/ui/badge'
import type { EventStock } from '@/features/fund/fund.types'

const operationConfig = {
  buy: {
    label: 'Buy',
    icon: ShoppingBag,
    color: 'bg-secondary text-primary',
  },
  sell: {
    label: 'Sell',
    icon: Coins,
    color: 'bg-secondary text-destructive',
  },
} as const

interface StockTxItemProps {
  tx: EventStock
}

export function StockTxItem({ tx }: StockTxItemProps) {
  const op = operationConfig[tx.operation as keyof typeof operationConfig]

  return (
    <Item variant="outline" size="sm">
      <ItemMedia variant="image">
        <div
          className={cn(
            op.color,
            'flex size-8 items-center justify-center rounded-xl',
          )}
        >
          <op.icon className="size-4" />
        </div>
      </ItemMedia>

      <ItemContent>
        <ItemTitle>{tx.ticker}</ItemTitle>
        <ItemDescription className="-ml-2">
          <Badge variant="ghost" className="pointer-events-none">
            <Calendar />
            {format(new Date(tx.created_at), 'yyyy-MM-dd')}
          </Badge>
          <Badge variant="ghost" className="pointer-events-none">
            <Clock />
            {format(new Date(tx.created_at), 'HH:mm')}
          </Badge>
        </ItemDescription>
      </ItemContent>

      <ItemContent className="items-end">
        <ItemTitle>{formatNum(tx.net_proceed)}</ItemTitle>
        <ItemDescription className="text-xs">
          {op.label} {formatNum(tx.quantity, 2)} @ {formatNum(tx.price, 2)}
          {tx.fee > 0 && <> · Fee {formatNum(tx.fee, 2)}</>}
          {tx.tax != null && tx.tax > 0 && <> · Tax {formatNum(tx.tax, 2)}</>}
        </ItemDescription>
      </ItemContent>
    </Item>
  )
}
