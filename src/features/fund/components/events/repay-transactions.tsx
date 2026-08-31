import { ItemGroup, ItemTitle } from '@/components/ui/item'
import StatusLabel from '@/components/status-label'
import { RepayTxItem } from './repay-tx-item'
import type { EventRepay } from '@/features/fund/fund.types'

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
    <div className="flex flex-col">
      <ItemGroup className="gap-2">
        <ItemTitle className="pb-2">
          Found {data.length} transactions
        </ItemTitle>
        {data.map((tx) => (
          <RepayTxItem key={tx.tx_id} tx={tx} />
        ))}
      </ItemGroup>
    </div>
  )
}
