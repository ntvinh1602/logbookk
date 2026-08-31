import { ItemGroup, ItemTitle } from '@/components/ui/item'
import StatusLabel from '@/components/status-label'
import { BorrowTxItem } from './borrow-tx-item'
import type { EventBorrow } from '@/features/fund/fund.types'

interface BorrowTransactionsProps {
  data: EventBorrow[]
  isLoading: boolean
  error: Error | null
}

export function BorrowTransactions({
  data,
  isLoading,
  error,
}: BorrowTransactionsProps) {
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
          <BorrowTxItem key={tx.tx_id} tx={tx} />
        ))}
      </ItemGroup>
    </div>
  )
}
