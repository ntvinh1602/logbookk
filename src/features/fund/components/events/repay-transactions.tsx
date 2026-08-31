import { Handshake, Calendar, Clock } from 'lucide-react'
import { format } from 'date-fns'
import { formatNum } from '@/lib/utils'
import {
  Item,
  ItemContent,
  ItemTitle,
  ItemDescription,
  ItemGroup,
  ItemSeparator,
} from '@/components/ui/item'
import { Badge } from '@/components/ui/badge'
import StatusLabel from '@/components/status-label'
import type { EventRepay } from '@/features/fund/fund.types'
import { Button } from '@/components/ui/button'
import {
  Card,
  CardContent,
  CardDescription,
  CardHeader,
  CardTitle,
} from '@/components/ui/card'

interface RepayTransactionsProps {
  data: EventRepay[]
  isLoading: boolean
  error: Error | null
}

export function RepayTransactions({
  data,
  isLoading,
  error,
}: RepayTransactionsProps) {
  if (isLoading) return <StatusLabel type="loading" />
  if (error) return <StatusLabel type="error" />
  if (data.length === 0) return <StatusLabel type="empty" />

  return (
    <Card className="gap-4">
      <CardHeader>
        <CardTitle>Event List</CardTitle>
        <CardDescription>{data.length} transactions</CardDescription>
      </CardHeader>
      <CardContent className="px-0">
        <ItemGroup className="gap-0">
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
        </ItemGroup>
      </CardContent>
    </Card>
  )
}
