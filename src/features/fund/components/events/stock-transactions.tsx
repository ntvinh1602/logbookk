import { Calendar, Clock } from 'lucide-react'
import { format } from 'date-fns'
import { cn, formatNum } from '@/lib/utils'
import {
  Item,
  ItemMedia,
  ItemContent,
  ItemTitle,
  ItemDescription,
  ItemGroup,
  ItemSeparator,
} from '@/components/ui/item'
import { Badge } from '@/components/ui/badge'
import StatusLabel from '@/components/status-label'
import type { EventStock } from '@/lib/supabase/api/types'
import {
  Card,
  CardContent,
  CardDescription,
  CardHeader,
  CardTitle,
} from '@/components/ui/card'

interface StockTransactionsProps {
  data: EventStock[]
  isLoading: boolean
  error: Error | null
}

export function StockTransactions({
  data,
  isLoading,
  error,
}: StockTransactionsProps) {
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
            <div>
              <ItemSeparator />
              <Item key={tx.tx_id} className="py-2">
                <ItemMedia variant="image">
                  <img
                    src={`${import.meta.env.VITE_PUBLIC_SUPABASE_URL}/storage/v1/object/public/logo/stock/${tx.logo_url}`}
                    loading="eager"
                  />
                </ItemMedia>
                <ItemSeparator orientation="vertical" />

                <ItemContent>
                  <ItemTitle>
                    <Badge
                      className={cn(
                        tx.operation == 'buy'
                          ? 'bg-positive/10 text-positive'
                          : 'bg-negative/10 text-negative',
                        'capitalize rounded-sm',
                      )}
                    >
                      {tx.operation}
                    </Badge>
                    {tx.name}
                  </ItemTitle>
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
          ))}
        </ItemGroup>
      </CardContent>
    </Card>
  )
}
