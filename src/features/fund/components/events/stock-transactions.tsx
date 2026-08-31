import { ItemGroup, ItemTitle } from '@/components/ui/item'
import StatusLabel from '@/components/status-label'
import { StockTxItem } from './stock-tx-item'
import type { EventStock } from '@/features/fund/fund.types'

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
    <div className="flex flex-col">
      <ItemGroup className="gap-2">
        <ItemTitle className="pb-2">
          Found {data.length} transactions
        </ItemTitle>
        {data.map((tx) => (
          <StockTxItem key={tx.tx_id} tx={tx} />
        ))}
      </ItemGroup>
    </div>
  )
}
