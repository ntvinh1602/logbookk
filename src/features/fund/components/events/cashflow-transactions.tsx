import { Calendar, Clock } from 'lucide-react'
import { format } from 'date-fns'
import { cn, formatNum } from '@/lib/utils'
import {
  Item,
  ItemContent,
  ItemTitle,
  ItemDescription,
  ItemSeparator,
} from '@/components/ui/item'
import { Badge } from '@/components/ui/badge'
import { Button } from '@/components/ui/button'
import { EVENT_CATEGORY } from '@/features/fund/config'
import type { CashflowOps } from '@/features/fund/config'
import type { CashflowEvents } from '@/features/fund/types'
import { EventListCard } from './event-list-card'

const OpsConfig = EVENT_CATEGORY.cashflow.operations

interface CashflowTransactionsProps {
  data: CashflowEvents[]
  isLoading: boolean
  error: Error | null
}

export function CashflowTransactions({
  data,
  isLoading,
  error,
}: CashflowTransactionsProps) {
  return (
    <EventListCard count={data.length} isLoading={isLoading} error={error}>
      {data.map((tx) => {
        const op = OpsConfig[tx.operation as CashflowOps]

        return (
          <div key={tx.tx_id}>
            <ItemSeparator />
            <Item className="py-2">
              <Button variant="secondary" className="pointer-events-none">
                <op.icon />
              </Button>

              <ItemSeparator orientation="vertical" />

              <ItemContent>
                <ItemTitle>
                  <Badge className={cn(op.color, 'capitalize rounded-sm')}>
                    {tx.operation}
                  </Badge>
                  {tx.memo}
                </ItemTitle>
                <ItemDescription className="flex gap-1">
                  <Badge
                    variant="ghost"
                    className="pointer-events-none px-0"
                  >
                    <Calendar />
                    {format(new Date(tx.created_at), 'yyyy-MM-dd')}
                  </Badge>
                  <Badge
                    variant="ghost"
                    className="pointer-events-none px-0"
                  >
                    <Clock />
                    {format(new Date(tx.created_at), 'HH:mm')}
                  </Badge>
                </ItemDescription>
              </ItemContent>

              <ItemContent className="items-end">
                <ItemTitle>{formatNum(tx.net_proceed)}</ItemTitle>{' '}
                {tx.ticker !== 'FX.VND' && (
                  <ItemDescription className="text-xs">
                    <Badge variant="secondary" className="rounded-sm">
                      {`${formatNum(tx.quantity, 2)} ${tx.currency}`}
                    </Badge>
                  </ItemDescription>
                )}
              </ItemContent>
            </Item>
          </div>
        )
      })}
    </EventListCard>
  )
}
