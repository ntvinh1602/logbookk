import { Calendar, Clock } from 'lucide-react'
import { format } from 'date-fns'
import { cn, formatNum } from '@/lib/utils'
import {
  Item,
  ItemMedia,
  ItemContent,
  ItemTitle,
  ItemDescription,
  ItemSeparator,
} from '@/components/ui/item'
import { Badge } from '@/components/ui/badge'
import { EVENT_CATEGORY } from '@/features/fund/config'
import type { StockEvents } from '@/features/fund/types'
import { EventListCard } from './event-list-card'

const OpsConfig = EVENT_CATEGORY.stock.operations
type Ops = keyof typeof OpsConfig

interface StockTransactionsProps {
  data: StockEvents[]
  isLoading: boolean
  error: Error | null
}

export function StockTransactions({
  data,
  isLoading,
  error,
}: StockTransactionsProps) {
  return (
    <EventListCard count={data.length} isLoading={isLoading} error={error}>
      {data.map((tx) => {
        const op = OpsConfig[tx.operation as Ops]

        return (
          <div key={tx.tx_id}>
            <ItemSeparator />
            <Item className="py-2">
              <ItemMedia variant="image">
                <img
                  src={`${import.meta.env.VITE_PUBLIC_SUPABASE_URL}/storage/v1/object/public/logo/stock/${tx.logo_url}`}
                  loading="eager"
                />
              </ItemMedia>
              <ItemSeparator orientation="vertical" />

              <ItemContent>
                <ItemTitle>
                  <Badge className={cn(op.color, 'capitalize rounded-sm')}>
                    {tx.operation}
                  </Badge>
                  {tx.name}
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
                <ItemTitle>{formatNum(tx.net_proceed)}</ItemTitle>
                <ItemDescription className="flex gap-1">
                  {tx.fee > 0 && (
                    <Badge variant="secondary" className="rounded-sm">
                      Fee: {formatNum(tx.fee)}
                    </Badge>
                  )}
                  {tx.tax > 0 && (
                    <Badge variant="secondary" className="rounded-sm">
                      Tax: {formatNum(tx.tax)}
                    </Badge>
                  )}
                </ItemDescription>
              </ItemContent>
            </Item>
          </div>
        )
      })}
    </EventListCard>
  )
}
