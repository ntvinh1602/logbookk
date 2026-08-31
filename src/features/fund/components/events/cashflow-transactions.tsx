import { ItemGroup, ItemTitle } from '@/components/ui/item'
import StatusLabel from '@/components/status-label'
import { CashflowTxItem } from './cashflow-tx-item'
import type { EventCashflow } from '@/features/fund/fund.types'

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
    <div className="flex flex-col">
      <ItemGroup className="gap-2">
        <ItemTitle className="pb-2">
          Found {data.length} transactions
        </ItemTitle>
        {data.map((tx) => (
          <CashflowTxItem key={tx.tx_id} tx={tx} />
        ))}
      </ItemGroup>
    </div>
  )
}
