import { Handshake, Calendar, Clock } from 'lucide-react'
import { format } from 'date-fns'
import { formatNum } from '@/lib/utils'
import {
  Item,
  ItemMedia,
  ItemContent,
  ItemTitle,
  ItemDescription,
} from '@/components/ui/item'
import { Badge } from '@/components/ui/badge'
import type { EventRepay } from '@/features/fund/fund.types'

interface RepayTxItemProps {
  tx: EventRepay
}

export function RepayTxItem({ tx }: RepayTxItemProps) {
  return (
    <Item variant="outline" size="sm">
      <ItemMedia variant="image">
        <div className="flex size-8 items-center justify-center rounded-xl bg-secondary text-destructive">
          <Handshake className="size-4" />
        </div>
      </ItemMedia>

      <ItemContent>
        <ItemTitle>{tx.lender}</ItemTitle>
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
        <ItemTitle>{formatNum(tx.principal)}</ItemTitle>
        <ItemDescription className="text-xs">
          Repay · Interest {formatNum(tx.interest)}
        </ItemDescription>
      </ItemContent>
    </Item>
  )
}
