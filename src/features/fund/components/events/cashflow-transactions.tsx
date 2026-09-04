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
  ItemContent,
  ItemTitle,
  ItemDescription,
  ItemGroup,
  ItemSeparator,
} from '@/components/ui/item'
import { Badge } from '@/components/ui/badge'
import StatusLabel from '@/components/status-label'
import type { EventCashflow } from '@/features/fund/types'
import {
  Card,
  CardContent,
  CardDescription,
  CardHeader,
  CardTitle,
} from '@/components/ui/card'
import { Button } from '@/components/ui/button'

const operationConfig = {
  deposit: {
    label: 'Deposit',
    icon: PiggyBank,
    color: 'bg-positive/10 text-positive',
  },
  withdraw: {
    label: 'Withdraw',
    icon: Upload,
    color: 'bg-negative/10 text-negative',
  },
  income: {
    label: 'Income',
    icon: TrendingUp,
    color: 'bg-positive/10 text-positive',
  },
  expense: {
    label: 'Expense',
    icon: TrendingDown,
    color: 'bg-negative/10 text-negative',
  },
} as const

interface CashflowTransactionsProps {
  data: EventCashflow[]
  isLoading: boolean
  error: Error | null
}

export function CashflowTransactions({
  data,
  isLoading,
  error,
}: CashflowTransactionsProps) {
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
          {data.map((tx) => {
            const op =
              operationConfig[tx.operation as keyof typeof operationConfig]

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
                      <Badge
                        className={cn(
                          tx.operation == 'deposit' || tx.operation == 'income'
                            ? 'bg-positive/10 text-positive'
                            : 'bg-negative/10 text-negative',
                          'capitalize rounded-sm',
                        )}
                      >
                        {tx.operation}
                      </Badge>
                      {tx.memo}
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
        </ItemGroup>
      </CardContent>
    </Card>
  )
}
