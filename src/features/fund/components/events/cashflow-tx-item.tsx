import {
  PiggyBank,
  Upload,
  TrendingUp,
  TrendingDown,
  Calendar,
  Clock,
} from 'lucide-react'
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
import type { EventCashflow } from '@/features/fund/fund.types'

const operationConfig = {
  deposit: {
    label: 'Deposit',
    icon: PiggyBank,
    color: 'bg-secondary text-primary',
  },
  withdraw: {
    label: 'Withdraw',
    icon: Upload,
    color: 'bg-secondary text-destructive',
  },
  income: {
    label: 'Income',
    icon: TrendingUp,
    color: 'bg-secondary text-primary',
  },
  expense: {
    label: 'Expense',
    icon: TrendingDown,
    color: 'bg-secondary text-destructive',
  },
} as const

interface CashflowTxItemProps {
  tx: EventCashflow
}

export function CashflowTxItem({ tx }: CashflowTxItemProps) {
  const op = operationConfig[tx.operation as keyof typeof operationConfig]

  return (
    <Item variant="outline" size="sm">
      <ItemMedia variant="image">
        <div
          className={cn(
            op?.color ?? 'bg-secondary',
            'flex size-8 items-center justify-center rounded-xl',
          )}
        >
          {op && <op.icon className="size-4" />}
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
          {op?.label ?? tx.operation} · {tx.memo}
          {tx.quantity > 0 && <> · Qty {formatNum(tx.quantity, 2)}</>}
        </ItemDescription>
      </ItemContent>
    </Item>
  )
}
