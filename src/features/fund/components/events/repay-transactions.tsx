import { Handshake, Calendar, Clock } from 'lucide-react'
import { format } from 'date-fns'
import { formatNum } from '@/lib/utils'
import {
  Item,
  ItemContent,
  ItemTitle,
  ItemDescription,
  ItemSeparator,
} from '@/components/ui/item'
import { Badge } from '@/components/ui/badge'
import { Button } from '@/components/ui/button'
import type { RepayEvents } from '@/features/fund/types'
import { EventListCard } from './event-list-card'

interface RepayTransactionsProps {
  data: RepayEvents[]
  isLoading: boolean
  error: Error | null
}

export function RepayTransactions({
  data,
  isLoading,
  error,
}: RepayTransactionsProps) {
  return (
    <EventListCard count={data.length} isLoading={isLoading} error={error}>
      {data.map((tx) => (
        <div key={tx.tx_id}>
          <ItemSeparator />
          <Item className="py-2">
            <Button variant="secondary" className="pointer-events-none">
              <Handshake />
            </Button>

            <ItemSeparator orientation="vertical" />

            <ItemContent>
              <ItemTitle>{tx.lender}</ItemTitle>
              <ItemDescription className="flex gap-1">
                <Badge variant="ghost" className="pointer-events-none px-0">
                  <Calendar />
                  {format(new Date(tx.created_at), 'yyyy-MM-dd')}
                </Badge>
                <Badge variant="ghost" className="pointer-events-none px-0">
                  <Clock />
                  {format(new Date(tx.created_at), 'HH:mm')}
                </Badge>
              </ItemDescription>
            </ItemContent>

            <ItemContent className="items-end">
              <ItemTitle>{formatNum(tx.principal)}</ItemTitle>
              <ItemDescription className="text-xs">
                Repay · Interest {formatNum(tx.interest)}
              </ItemDescription>
            </ItemContent>
          </Item>
        </div>
      ))}
    </EventListCard>
  )
}
